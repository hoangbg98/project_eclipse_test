"""Vẽ placeholder cho màn kết quả chiêu mộ (owner 2026-11-15): thẻ dọc rỗng + icon tạm vũ khí / vết thánh / nguyên liệu.
Chạy: python -X utf8 -I tools/gen_recruit_card_placeholders.py
Ra: assets/placeholders/placeholder_recruit_card.png (thẻ rỗng, không có vật phẩm),
    assets/placeholders/placeholder_recruit_icon_{weapon,stigma,material,gold}.png
Hình vẽ bằng code (Pillow), thiết kế riêng của dự án; không ship (bản Release loại *placeholder_*).
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "placeholders")
W, H = 336, 1240   # 2× thẻ 168 × 620


def card():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    grad = Image.new("RGBA", (W, H))
    gd = ImageDraw.Draw(grad)
    for y in range(H):
        t = y / (H - 1)
        c = (int(46 + 30 * t), int(58 + 34 * t), int(82 + 24 * t), 255)
        gd.line([(0, y), (W, y)], fill=c)
    mask = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([0, 0, W - 1, H - 1], radius=28, fill=255)
    img.paste(grad, (0, 0), mask)
    d = ImageDraw.Draw(img)
    # Hoa văn: lưới chấm thoi mờ.
    for gy in range(60, H - 60, 44):
        for gx in range(28 + (22 if (gy // 44) % 2 else 0), W - 20, 44):
            d.polygon([(gx, gy - 5), (gx + 5, gy), (gx, gy + 5), (gx - 5, gy)], fill=(255, 255, 255, 22))
    # Khung trong: viền mảnh + vạch ngang trên / dưới.
    d.rounded_rectangle([14, 14, W - 15, H - 15], radius=20, outline=(220, 230, 255, 90), width=3)
    d.line([(40, 120), (W - 40, 120)], fill=(220, 230, 255, 60), width=2)
    d.line([(40, H - 170), (W - 40, H - 170)], fill=(220, 230, 255, 60), width=2)
    # Ngôi sao 4 cánh trang trí ở đỉnh.
    cx, cy = W // 2, 70
    pts = []
    for k in range(8):
        r = 30 if k % 2 == 0 else 8
        a = math.pi / 4 * k - math.pi / 2
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    d.polygon(pts, fill=(255, 255, 255, 170))
    img.save(os.path.join(OUT, "placeholder_recruit_card.png"))


def icon(name, draw_fn):
    s = 512
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    draw_fn(d, s)
    glow = img.filter(ImageFilter.GaussianBlur(10))
    out = Image.alpha_composite(glow, img)
    out.save(os.path.join(OUT, "placeholder_recruit_icon_%s.png" % name))


def weapon(d, s):
    # Thanh kiếm đứng chéo: lưỡi, chuôi, đốc.
    d.polygon([(250, 40), (275, 70), (275, 370), (250, 400), (225, 370), (225, 70)], fill=(214, 222, 240, 255),
              outline=(120, 132, 170, 255))
    d.line([(250, 60), (250, 380)], fill=(160, 172, 205, 255), width=4)
    d.rounded_rectangle([170, 395, 330, 420], radius=8, fill=(140, 120, 190, 255))
    d.rounded_rectangle([238, 420, 262, 480], radius=6, fill=(90, 80, 120, 255))
    d.ellipse([232, 474, 268, 506], fill=(140, 120, 190, 255))


def stigma(d, s):
    # Ấn tròn: vòng ngoài, vòng trong, viên đá giữa.
    d.ellipse([86, 86, 426, 426], outline=(214, 222, 240, 255), width=22)
    d.ellipse([156, 156, 356, 356], outline=(140, 120, 190, 255), width=12)
    d.polygon([(256, 196), (316, 256), (256, 316), (196, 256)], fill=(186, 200, 236, 255))


def material(d, s):
    # Sách / hộp nguyên liệu.
    d.rounded_rectangle([130, 110, 382, 420], radius=18, fill=(92, 104, 130, 255), outline=(200, 210, 235, 255),
                        width=8)
    d.rectangle([150, 130, 170, 400], fill=(150, 160, 190, 255))
    d.ellipse([216, 216, 316, 316], outline=(214, 222, 240, 255), width=8)
    d.line([(266, 226), (266, 306)], fill=(214, 222, 240, 255), width=6)


def gold(d, s):
    for i, (x, y) in enumerate([(180, 300), (290, 300), (235, 210)]):
        d.ellipse([x - 80, y - 80, x + 80, y + 80], fill=(236, 196, 92, 255), outline=(170, 128, 40, 255), width=8)
        d.ellipse([x - 44, y - 44, x + 44, y + 44], outline=(170, 128, 40, 255), width=6)


os.makedirs(OUT, exist_ok=True)
card()
icon("weapon", weapon)
icon("stigma", stigma)
icon("material", material)
icon("gold", gold)
print("ok")
