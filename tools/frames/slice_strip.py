"""Cắt ảnh dải frame do AI tạo thành từng frame chuẩn của dự án, đặt vào thư mục CHỜ DUYỆT.

  python -I tools/frames/slice_strip.py char_fire_01 idle strip_a.png [strip_b.png ...] [--chroma FF00FF]
         [--ref-frame 0] [--height 280] [--anchor feet|bbox]

- Mỗi dải là một lần gọi tạo ảnh (một hàng ngang, các pose cách nhau bằng nền trống). Các dải nối nhau theo thứ tự.
- Nền: trong suốt (alpha) hoặc một màu phẳng (--chroma, mặc định tự nhận màu góc ảnh nếu ảnh không có alpha).
- Tỉ lệ: frame số --ref-frame (mặc định 0) của DẢI ĐẦU được phóng sao cho cao --height px (mặc định lấy
  standing_height_px trong phiếu); cùng một hệ số cho mọi frame và mọi dải → không đổi kích thước giữa các frame.
  Nếu frame tham chiếu không đứng thẳng (vd nhảy), dùng --scale <số> lấy từ meta.json của animation đã duyệt (idle).
- Canvas 384×384, nhân vật quay phải, tâm x = 192. Animation đứng đất: điểm thấp nhất y = 336 cho từng frame.
  Animation trên không: frame thấp nhất của cả animation chạm 336, các frame khác giữ đúng độ cao tương đối.
- Ghi art_review/{id}/{anim}/{id}_{anim}_NNN.png (xóa frame cũ trong thư mục chờ duyệt, không đụng assets/).
Cần Pillow.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import frame_jobs as F  # noqa: E402

from PIL import Image  # noqa: E402

ALPHA_MIN = 16


def to_rgba(img, chroma, tol):
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    has_alpha = any(px[x, y][3] < 250 for x, y in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)])
    if has_alpha and chroma is None:
        return img
    key = chroma if chroma is not None else px[0, 0][:3]
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if abs(r - key[0]) <= tol and abs(g - key[1]) <= tol and abs(b - key[2]) <= tol:
                px[x, y] = (0, 0, 0, 0)
    return img


def column_runs(img):
    """Các khoảng cột có điểm không trong suốt: [(x0, x1)] (x1 không tính)."""
    a = img.getchannel("A").point(lambda v: 255 if v >= ALPHA_MIN else 0)
    w, h = img.size
    filled = [a.crop((x, 0, x + 1, h)).getbbox() is not None for x in range(w)]
    runs, start = [], None
    for x, f in enumerate(filled + [False]):
        if f and start is None:
            start = x
        elif not f and start is not None:
            runs.append([start, x])
            start = None
    return runs


def split(img, expected):
    runs = column_runs(img)
    # Gộp mẩu nhỏ (lọn tóc, tia) vào khoảng gần nhất cho tới khi đúng số frame.
    while len(runs) > expected:
        widths = [r[1] - r[0] for r in runs]
        i = widths.index(min(widths))
        if i == 0:
            j = 1
        elif i == len(runs) - 1:
            j = i - 1
        else:
            j = i - 1 if runs[i][0] - runs[i - 1][1] <= runs[i + 1][0] - runs[i][1] else i + 1
        a, b = sorted([i, j])
        runs[a] = [runs[a][0], runs[b][1]]
        del runs[b]
    if len(runs) < expected:
        raise SystemExit("Tách được %d frame, cần %d: các pose dính nhau. Tạo lại dải với khoảng trống rõ hơn." %
                         (len(runs), expected))
    out = []
    for x0, x1 in runs:
        part = img.crop((x0, 0, x1, img.size[1]))
        bb = part.getchannel("A").point(lambda v: 255 if v >= ALPHA_MIN else 0).getbbox()
        out.append((part.crop(bb), bb[3]))   # (frame cắt sát, đáy trong dải gốc)
    return out


def anchor_x(frame, mode):
    """Tọa độ x (trong frame đã cắt) dùng làm tâm 192: trọng tâm phần chân (35% dưới) hoặc tâm khung."""
    w, h = frame.size
    if mode == "bbox":
        return w / 2.0
    a = frame.getchannel("A")
    y0 = int(h * 0.65)
    total = sx = 0
    px = a.load()
    for y in range(y0, h):
        for x in range(w):
            if px[x, y] >= ALPHA_MIN:
                total += 1
                sx += x
    return sx / total if total else w / 2.0


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("character_id")
    ap.add_argument("anim")
    ap.add_argument("strips", nargs="+")
    ap.add_argument("--chroma", help="màu nền phẳng dạng RRGGBB (vd FF00FF)")
    ap.add_argument("--tol", type=int, default=40)
    ap.add_argument("--ref-frame", type=int, default=0)
    ap.add_argument("--height", type=float)
    ap.add_argument("--scale", type=float, help="hệ số phóng cố định (bỏ qua --height)")
    ap.add_argument("--anchor", choices=["feet", "bbox"], default="feet")
    ap.add_argument("--base", help="thư mục gốc dự án (test)")
    args = ap.parse_args(argv)

    p = F.plan(args.character_id, args.anim, args.base)
    jobs = F.load_jobs(args.character_id, args.base)
    chroma = tuple(int(args.chroma[i:i + 2], 16) for i in (0, 2, 4)) if args.chroma else None
    if len(args.strips) != len(p["calls"]):
        print("Cảnh báo: phiếu chia %d lần gọi, nhận %d dải." % (len(p["calls"]), len(args.strips)))
    frames = []
    for k, path in enumerate(args.strips):
        img = to_rgba(Image.open(path), chroma, args.tol)
        if len(args.strips) == len(p["calls"]):
            a, b = p["calls"][k]
            want = b - a + 1
        else:
            want = len(column_runs(img))
        frames += split(img, want)
    if len(frames) != p["frames"]:
        raise SystemExit("Có %d frame, phiếu cần %d." % (len(frames), p["frames"]))

    if args.scale:
        scale = args.scale
    else:
        height = args.height or float(jobs.get("standing_height_px", 280))
        scale = height / frames[args.ref_frame][0].size[1]
    scaled = [f.resize((max(1, round(f.size[0] * scale)), max(1, round(f.size[1] * scale))), Image.LANCZOS)
              for f, _ in frames]
    # Trên không: frame có đáy thấp nhất (trong dải gốc) chạm 336, frame khác nâng lên đúng độ chênh × hệ số.
    lowest = max(b for _, b in frames)
    lifts = [0 if p["grounded"] else round((lowest - b) * scale) for _, b in frames]
    out_dir = F.review_dir(args.character_id, args.anim, args.base)
    os.makedirs(out_dir, exist_ok=True)
    for f in os.listdir(out_dir):
        if f.endswith(".png"):
            os.remove(os.path.join(out_dir, f))
    clipped = []
    for i, f in enumerate(scaled):
        canvas = Image.new("RGBA", (F.CANVAS, F.CANVAS), (0, 0, 0, 0))
        x = int(round(F.PIVOT_X - anchor_x(f, args.anchor)))
        y = F.BASELINE_Y - f.size[1] - lifts[i]
        if x < 0 or y < 0 or x + f.size[0] > F.CANVAS:
            clipped.append(i)
        canvas.paste(f, (x, y), f)
        canvas.save(os.path.join(out_dir, F.frame_name(args.character_id, args.anim, i)))
    meta_path = os.path.join(out_dir, "meta.json")
    meta = {}
    if os.path.exists(meta_path):
        with open(meta_path, encoding="utf-8") as fh:
            meta = json.load(fh)
    meta.update({"scale": scale, "strips": [os.path.basename(s) for s in args.strips], "frames": len(scaled)})
    with open(meta_path, "w", encoding="utf-8") as fh:
        json.dump(meta, fh, ensure_ascii=False, indent=2)
    print("Đã ghi %d frame vào %s (hệ số phóng %.4f)." % (len(scaled), out_dir, scale))
    if clipped:
        print("Cảnh báo: frame %s bị cắt mép canvas 384×384 — giảm --height hoặc tạo lại pose gọn hơn." % clipped)
    print("Tiếp theo: python -I tools/frames/check_frames.py %s %s" % (args.character_id, args.anim))


if __name__ == "__main__":
    main()
