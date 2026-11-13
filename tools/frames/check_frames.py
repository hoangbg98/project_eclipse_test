"""Kiểm tra frame của một animation và tạo ảnh xem trước để owner duyệt.

  python -I tools/frames/check_frames.py char_fire_01 idle            # thư mục chờ duyệt art_review/
  python -I tools/frames/check_frames.py char_fire_01 idle --approved # thư mục trong game assets/.../frames/

Kiểm (lỗi = mã thoát 1):
- đủ số frame theo phiếu, tên {id}_{anim}_NNN.png liên tục từ 000;
- PNG 384×384 có kênh alpha, 4 góc trong suốt, không có điểm nào chạm mép canvas (bị cắt);
- animation đứng đất: điểm thấp nhất mỗi frame ở y = 336 (±3 px);
- tâm phần chân gần x = 192 (±48 px), chiều cao giữa các frame không lệch quá 45% (dấu hiệu sai tỉ lệ).
Ảnh xem trước (ghi vào _preview/ cạnh frame, không vào game):
- sheet.png: các frame xếp hàng trên nền tối, có số frame, đường chân 336 và tâm 192; frame trúng đòn viền đỏ;
- anim.gif: chạy đúng fps (lặp nếu là animation lặp); anim_flip.gif: lật ngang như khi quay trái.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import frame_jobs as F  # noqa: E402

from PIL import Image, ImageDraw, ImageOps  # noqa: E402

ALPHA_MIN = 16


def analyse(img):
    a = img.getchannel("A").point(lambda v: 255 if v >= ALPHA_MIN else 0)
    bb = a.getbbox()
    if bb is None:
        return None
    w, h = img.size
    y0 = bb[1] + int((bb[3] - bb[1]) * 0.65)
    px = a.load()
    total = sx = 0
    for y in range(y0, bb[3]):
        for x in range(bb[0], bb[2]):
            if px[x, y]:
                total += 1
                sx += x
    return {"bbox": bb, "feet_x": sx / total if total else (bb[0] + bb[2]) / 2.0, "height": bb[3] - bb[1]}


def check(character_id, anim, approved=False, base=None):
    p = F.plan(character_id, anim, base)
    d = F.frames_dir(character_id, anim, base) if approved else F.review_dir(character_id, anim, base)
    errors, warnings, frames = [], [], []
    if not os.path.isdir(d):
        return p, d, ["không có thư mục %s" % d], warnings, frames
    files = sorted(f for f in os.listdir(d) if f.endswith(".png"))
    want = [F.frame_name(character_id, anim, i) for i in range(p["frames"])]
    if files != want:
        errors.append("tên / số frame sai: có %d file, cần %d (%s … %s)" % (len(files), len(want), want[0], want[-1]))
    heights = []
    for name in files:
        img = Image.open(os.path.join(d, name))
        tag = name
        if img.size != (F.CANVAS, F.CANVAS):
            errors.append("%s: kích thước %s, cần 384×384" % (tag, img.size))
            continue
        if img.mode != "RGBA":
            errors.append("%s: không có kênh alpha (%s)" % (tag, img.mode))
            continue
        frames.append(img)
        if any(img.getpixel(c)[3] >= ALPHA_MIN for c in [(0, 0), (383, 0), (0, 383), (383, 383)]):
            errors.append("%s: góc ảnh không trong suốt (nền chưa xóa)" % tag)
        info = analyse(img)
        if info is None:
            errors.append("%s: ảnh trống" % tag)
            continue
        x0, y0, x1, y1 = info["bbox"]
        if x0 == 0 or y0 == 0 or x1 == F.CANVAS:
            errors.append("%s: nhân vật chạm mép canvas (bị cắt)" % tag)
        if p["grounded"] and abs(y1 - F.BASELINE_Y) > 3:
            errors.append("%s: chân ở y = %d, cần %d" % (tag, y1, F.BASELINE_Y))
        if not p["grounded"] and y1 > F.BASELINE_Y + 3:
            errors.append("%s: thấp hơn đường chân (y = %d)" % (tag, y1))
        if abs(info["feet_x"] - F.PIVOT_X) > 48:
            warnings.append("%s: tâm chân x = %.0f, lệch xa 192" % (tag, info["feet_x"]))
        heights.append(info["height"])
    if heights and max(heights) > min(heights) * 1.45 and p["grounded"] and anim in ("idle", "run"):
        errors.append("chiều cao giữa các frame lệch %d–%d px: tỉ lệ không đều" % (min(heights), max(heights)))
    return p, d, errors, warnings, frames


def preview(p, d, frames):
    out = os.path.join(d, "_preview")
    os.makedirs(out, exist_ok=True)
    if not frames:
        return out
    n = len(frames)
    cell = F.CANVAS
    sheet = Image.new("RGBA", (cell * n, cell + 40), (32, 34, 44, 255))
    draw = ImageDraw.Draw(sheet)
    for i, f in enumerate(frames):
        x = i * cell
        draw.line([(x, F.BASELINE_Y), (x + cell, F.BASELINE_Y)], fill=(90, 200, 120, 255), width=1)
        draw.line([(x + F.PIVOT_X, 0), (x + F.PIVOT_X, cell)], fill=(90, 120, 200, 255), width=1)
        sheet.alpha_composite(f, (x, 0))
        if i in p["active_frames"]:
            draw.rectangle([x + 1, 1, x + cell - 2, cell - 2], outline=(230, 60, 60, 255), width=3)
        draw.rectangle([x, cell, x + cell - 1, cell + 39], outline=(60, 62, 75, 255))
        draw.text((x + 8, cell + 12), "%03d%s" % (i, "  HIT" if i in p["active_frames"] else ""), fill=(230, 230, 230, 255))
    sheet.save(os.path.join(out, "sheet.png"))
    dur = int(round(1000.0 / p["fps"]))
    for name, seq in (("anim.gif", frames), ("anim_flip.gif", [ImageOps.mirror(f) for f in frames])):
        bg = [Image.alpha_composite(Image.new("RGBA", f.size, (32, 34, 44, 255)), f).convert("P", palette=Image.ADAPTIVE)
              for f in seq]
        durations = [dur] * len(bg)
        if not p["loop"]:
            durations[-1] = 800   # dừng ở frame cuối cho dễ nhìn
        bg[0].save(os.path.join(out, name), save_all=True, append_images=bg[1:], duration=durations, loop=0, disposal=2)
    return out


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("character_id")
    ap.add_argument("anim")
    ap.add_argument("--approved", action="store_true")
    ap.add_argument("--base")
    args = ap.parse_args(argv)
    p, d, errors, warnings, frames = check(args.character_id, args.anim, args.approved, args.base)
    # Ảnh xem trước luôn nằm trong art_review/ (không bao giờ trong assets/, để không bị nhập vào game).
    out = preview(p, F.review_dir(args.character_id, args.anim, args.base), frames)
    print("%s / %s: %d frame, %d fps, %s, frame trúng đòn %s" % (args.character_id, args.anim, p["frames"], p["fps"],
          "lặp" if p["loop"] else "không lặp", p["active_frames"] or "—"))
    for w in warnings:
        print("  CẢNH BÁO:", w)
    for e in errors:
        print("  LỖI:", e)
    print("Xem trước: %s (sheet.png, anim.gif, anim_flip.gif)" % out)
    print("ĐẠT" if not errors else "CHƯA ĐẠT (%d lỗi)" % len(errors))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
