"""Vẽ icon tạm cho các nút lục giác ở màn Hub (owner sẽ vẽ lại), cùng kiểu icon kỹ năng (gen_hud_icons.py).

  python -I tools/ui/gen_hub_icons.py           # chỉ ghi icon còn thiếu
  python -I tools/ui/gen_hub_icons.py --force   # ghi đè (mất bản owner đã sửa!)

Ghi PNG 256×256 nền trong suốt, hình trắng viền tối vào assets/ui/hub/icons/{tên}.png:
  bag (Trang bị / túi đồ), companion (Người cộng tác), character (Nhân vật), sortie (Xuất kích), supply (Tiếp tế),
  shop, gacha, topup (3 thẻ màn Tiếp tế), story, trial, material (3 thẻ màn Xuất kích).
"""
import math
import os
import sys

from PIL import ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_hud_icons as G  # noqa: E402

OUT = os.path.join(G.ROOT, "assets", "ui", "hub", "icons")
W = G.WHITE


def d(m):
    return ImageDraw.Draw(m)


def bag(m):
    # Rương / túi đồ: thân bo góc, nắp, khóa.
    d(m).rounded_rectangle([190, 380, 834, 840], 60, fill=W)
    d(m).rounded_rectangle([230, 240, 794, 420], 60, fill=W)
    d(m).rectangle([190, 400, 834, 440], fill=0)
    d(m).rounded_rectangle([452, 360, 572, 520], 24, fill=0)
    d(m).rounded_rectangle([478, 386, 546, 494], 14, fill=W)
    G.arc(m, [380, 140, 644, 330], 180, 360, 40)


def companion(m):
    # Tinh linh: quả cầu sáng, hai cánh, đuôi lửa nhỏ.
    d(m).ellipse([392, 330, 632, 570], fill=W)
    d(m).ellipse([452, 400, 492, 450], fill=0)
    d(m).ellipse([532, 400, 572, 450], fill=0)
    for sgn in (-1, 1):
        cx = 512 + sgn * 120
        pts = [(cx, 450), (cx + sgn * 250, 300), (cx + sgn * 230, 420), (cx + sgn * 290, 470), (cx + sgn * 180, 540)]
        G.poly(m, pts)
    G.poly(m, [(470, 560), (512, 820), (554, 560)])
    G.star4(m, (512, 230), 70, 18)


def character(m):
    # Tượng bán thân.
    d(m).ellipse([382, 170, 642, 430], fill=W)
    d(m).pieslice([222, 460, 802, 1040], 180, 360, fill=W)
    d(m).rectangle([222, 740, 802, 760], fill=W)


def sortie(m):
    # Mũi tên xuất phát + vệt tốc độ.
    G.poly(m, [(330, 250), (820, 512), (330, 774), (420, 512)])
    for y, x0 in ((360, 150), (512, 110), (664, 150)):
        G.thick_line(m, (x0, y), (x0 + 200, y), 40)


def supply(m):
    # Hộp quà: thân, nắp, ruy băng.
    d(m).rectangle([230, 470, 794, 850], fill=W)
    d(m).rectangle([190, 370, 834, 470], fill=W)
    d(m).rectangle([482, 370, 542, 850], fill=0)
    d(m).rectangle([190, 452, 834, 488], fill=0)
    for sgn in (-1, 1):
        G.arc(m, [512 + (sgn < 0) * -220, 210, 512 + (sgn > 0) * 220, 380], 0, 360, 34)


def shop(m):
    d(m).polygon([(170, 330), (854, 330), (790, 640), (250, 640)], fill=W)
    G.thick_line(m, (110, 250), (190, 260), 40)
    G.thick_line(m, (190, 260), (250, 640), 40)
    d(m).ellipse([290, 700, 400, 810], fill=W)
    d(m).ellipse([640, 700, 750, 810], fill=W)


def gacha(m):
    G.star4(m, (512, 470), 330, 90)
    G.star4(m, (790, 230), 110, 30)
    G.star4(m, (250, 790), 90, 24)


def topup(m):
    G.poly(m, [(512, 150), (800, 420), (512, 880), (224, 420)])
    d(m).polygon([(512, 210), (700, 420), (512, 420)], fill=0)
    G.thick_line(m, (224, 420), (800, 420), 26)


def story(m):
    # Sách mở.
    for sgn in (-1, 1):
        G.poly(m, [(512, 300), (512 + sgn * 340, 230), (512 + sgn * 340, 760), (512, 830)])
    G.thick_line(m, (512, 300), (512, 830), 30)
    for k in range(3):
        y = 380 + k * 110
        for sgn in (-1, 1):
            d(m).line([(512 + sgn * 60, y), (512 + sgn * 280, y - 25)], fill=0, width=22)


def trial(m):
    # Hai kiếm bắt chéo (thử đội hình).
    G.sword(m, 45, 0.85)
    G.sword(m, -45, 0.85)


def material(m):
    # Tinh thể nguyên liệu.
    G.poly(m, [(512, 140), (720, 360), (640, 860), (384, 860), (304, 360)])
    d(m).line([(512, 140), (512, 860)], fill=0, width=24)
    d(m).line([(304, 360), (720, 360)], fill=0, width=24)


ICONS = {"bag": bag, "companion": companion, "character": character, "sortie": sortie, "supply": supply,
         "shop": shop, "gacha": gacha, "topup": topup, "story": story, "trial": trial, "material": material}


def main(argv):
    force = "--force" in argv
    wrote = kept = 0
    for name, fn in ICONS.items():
        path = os.path.join(OUT, name + ".png")
        if os.path.exists(path) and not force:
            kept += 1
            continue
        G.finish(G.make(fn), path)
        wrote += 1
    print("Đã ghi %d icon, giữ nguyên %d, thư mục %s" % (wrote, kept, OUT))


if __name__ == "__main__":
    for _s in (sys.stdout, sys.stderr):
        if hasattr(_s, "reconfigure"):
            _s.reconfigure(encoding="utf-8", errors="replace")
    main(sys.argv[1:])
