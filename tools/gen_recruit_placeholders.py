"""Sinh ảnh placeholder cho màn Chiêu mộ vào assets/ui/recruit/ (owner 2026-11-13: để ảnh tạm, owner tự thay sau).

  python -X utf8 tools/gen_recruit_placeholders.py

Mỗi banner trong data/banners/ có hai ảnh tạm: placeholder_{id}_banner.png (1301×839, thay cho ảnh banner lớn) và
placeholder_{id}_thumb.png (390×226, thay cho ảnh nhỏ trong danh sách). Owner thay bằng ảnh thật bằng cách thêm file
{id}_banner.png / {id}_thumb.png cùng thư mục (màn ưu tiên file không có tiền tố placeholder_). Không ghi đè placeholder
đã có trừ khi chạy với --force. Cần Pillow. Nhãn trên ảnh chỉ dùng ASCII.
"""
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "ui", "recruit")
BANNER_SIZE = (1301, 839)
THUMB_SIZE = (390, 226)
TOP, BOTTOM = (42, 46, 62), (20, 22, 31)
FIGURE = (91, 97, 128)
TEXT = (216, 220, 235)


def banner_ids():
    d = os.path.join(ROOT, "data", "banners")
    out = []
    for f in sorted(os.listdir(d)):
        if f.endswith(".tres"):
            m = re.search(r'^id = "([^"]+)"', open(os.path.join(d, f), encoding="utf-8").read(), re.M)
            if m:
                out.append(m.group(1))
    return out


def font(size):
    try:
        return ImageFont.load_default(size)
    except TypeError:
        return ImageFont.load_default()


def draw(size, cx_ratio, label, label_size, figure_ratio, label_pos):
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        c = tuple(round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = c
    d = ImageDraw.Draw(img)
    fh = h * figure_ratio
    cx, cy = w * cx_ratio, h * 0.52
    head = fh * 0.16
    d.ellipse([cx - head, cy - fh / 2, cx + head, cy - fh / 2 + 2 * head], fill=FIGURE)
    top = cy - fh / 2 + head * 2.2
    d.polygon([(cx - fh * 0.16, top), (cx + fh * 0.16, top), (cx + fh * 0.26, cy + fh / 2), (cx - fh * 0.26, cy + fh / 2)], fill=FIGURE)
    d.rectangle([0, 0, w - 1, h - 1], outline=(255, 255, 255), width=2)
    f = font(label_size)
    d.text((int(w * label_pos[0]), int(h * label_pos[1])), label, font=f, fill=TEXT, anchor=label_pos[2])
    return img


def main(argv):
    force = "--force" in argv
    os.makedirs(OUT, exist_ok=True)
    for bid in banner_ids():
        short = bid[len("banner_"):] if bid.startswith("banner_") else bid
        # Nhãn banner nằm góc trên-phải (không đè chữ của màn); nhãn ảnh nhỏ nằm giữa, dưới, đủ ngắn để không bị cắt.
        for kind, size, cx, ls, fr, lp in (("banner", BANNER_SIZE, 0.72, 28, 0.78, (0.97, 0.03, "rt")),
                                           ("thumb", THUMB_SIZE, 0.5, 30, 0.58, (0.5, 0.95, "ms"))):
            path = os.path.join(OUT, "placeholder_%s_%s.png" % (bid, kind))
            if os.path.exists(path) and not force:
                print("giữ", os.path.basename(path))
                continue
            label = ("BANNER ART  %s  %dx%d  (placeholder)" % (bid, size[0], size[1])) if kind == "banner" else short
            draw(size, cx, label, ls, fr, lp).save(path)
            print("ghi", os.path.basename(path))


if __name__ == "__main__":
    main(sys.argv[1:])
