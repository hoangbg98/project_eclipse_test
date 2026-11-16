"""Vẽ biểu tượng Chat cho Hub: assets/ui/hub/icons/chat.png (256x256, trắng có viền bóng tối như biểu tượng bánh răng).
Tự vẽ bằng Pillow (hình học đơn giản), không dùng ảnh bên thứ ba. Chạy: python -X utf8 -I tools/gen_chat_icon.py
"""
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "ui", "hub", "icons", "chat.png")
S = 256


def bubble(draw, fill):
    # thân bong bóng + đuôi
    draw.rounded_rectangle((36, 52, 220, 172), radius=34, fill=fill)
    draw.polygon([(78, 166), (78, 214), (124, 168)], fill=fill)


def main():
    base = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bubble(ImageDraw.Draw(shadow), (30, 30, 40, 255))
    # viền tối: nở ra rồi làm mờ
    edge = shadow.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(3))
    base.alpha_composite(edge)
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(fg)
    bubble(d, (255, 255, 255, 255))
    # ba chấm "đang nhập" khoét tối
    for cx in (84, 128, 172):
        d.ellipse((cx - 11, 100, cx + 11, 122), fill=(70, 74, 92, 255))
    base.alpha_composite(fg)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    base.save(OUT)
    print("saved", OUT, base.size)


if __name__ == "__main__":
    main()
