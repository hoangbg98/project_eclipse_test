"""Vẽ icon tạm cho cụm nút kỹ năng của HUD trận đấu (owner sẽ vẽ lại).

  python -I tools/ui/gen_hud_icons.py            # ghi mọi icon còn thiếu
  python -I tools/ui/gen_hud_icons.py --force    # ghi đè cả icon đã có (mất bản owner đã sửa!)

Ghi PNG 256×256 nền trong suốt, hình trắng viền tối, vào:
  assets/ui/hud/skill_icons/default/{slot}.png         dùng cho mọi giáp
  assets/ui/hud/skill_icons/{data_id}/{slot}.png       riêng từng giáp (Data ID), ưu tiên hơn default
slot: attack, jump, dodge, skill, weapon, ultimate. Giáp thiếu slot nào thì game dùng default của slot đó,
nên muốn đổi icon cho một giáp chỉ cần đặt file vào thư mục của Data ID đó (thêm giáp mới: tạo thư mục mới).
Mặc định KHÔNG ghi đè file đã có, để không mất icon owner đã chỉnh.
Chỉ dùng Pillow.
"""
import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "ui", "hud", "skill_icons")
S = 1024          # vẽ ở 4× rồi thu về 256 cho mượt
FINAL = 256
WHITE = 255

# Giáp → (nguyên tố, loại vũ khí); khớp data/characters/*.tres.
SUITS = {
    "char_fire_01": ("fire", "sword"),
    "char_wind_01": ("wind", "bow"),
    "char_lightning_01": ("lightning", "dual_blades"),
    "char_light_01": ("light", "staff"),
    "char_dark_01": ("dark", "scythe"),
    "char_earth_01": ("earth", "greatsword"),
}


def canvas():
    return Image.new("L", (S, S), 0)


def rot(pts, deg, c=(S / 2, S / 2)):
    a = math.radians(deg)
    ca, sa = math.cos(a), math.sin(a)
    return [(c[0] + (x - c[0]) * ca - (y - c[1]) * sa, c[1] + (x - c[0]) * sa + (y - c[1]) * ca) for x, y in pts]


def poly(m, pts, deg=0):
    ImageDraw.Draw(m).polygon(rot(pts, deg) if deg else pts, fill=WHITE)


def thick_line(m, a, b, w):
    ImageDraw.Draw(m).line([a, b], fill=WHITE, width=int(w))
    r = w / 2
    for p in (a, b):
        ImageDraw.Draw(m).ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=WHITE)


def arc(m, box, start, end, w):
    ImageDraw.Draw(m).arc(box, start, end, fill=WHITE, width=int(w))


# ---------------- Vũ khí ----------------

def sword(m, deg=45, scale=1.0):
    L = 300 * scale
    blade = [(512 - 34 * scale, 512 + 60), (512 - 34 * scale, 512 - L), (512, 512 - L - 70 * scale),
             (512 + 34 * scale, 512 - L), (512 + 34 * scale, 512 + 60)]
    guard = [(512 - 120 * scale, 512 + 60), (512 + 120 * scale, 512 + 60), (512 + 120 * scale, 512 + 110),
             (512 - 120 * scale, 512 + 110)]
    grip = [(512 - 22, 512 + 110), (512 + 22, 512 + 110), (512 + 22, 512 + 250), (512 - 22, 512 + 250)]
    for p in (blade, guard, grip):
        poly(m, p, deg)
    c = rot([(512, 512 + 285)], deg)[0]
    ImageDraw.Draw(m).ellipse([c[0] - 42, c[1] - 42, c[0] + 42, c[1] + 42], fill=WHITE)


def greatsword(m, deg=0):
    blade = [(400, 600), (400, 210), (512, 120), (624, 210), (624, 600)]
    guard = [(300, 600), (724, 600), (724, 670), (300, 670)]
    grip = [(482, 670), (542, 670), (542, 860), (482, 860)]
    for p in (blade, guard, grip):
        poly(m, p, deg)
    # rãnh giữa lưỡi: khoét bằng vẽ đen
    ImageDraw.Draw(m).polygon(rot([(500, 560), (500, 260), (524, 240), (524, 560)], deg) if deg else
                              [(500, 560), (500, 260), (524, 240), (524, 560)], fill=0)


def bow(m):
    arc(m, [250, 150, 650, 874], 270, 90, 70)          # thân cung (nửa phải của hình elip)
    thick_line(m, (450, 175), (450, 849), 18)           # dây
    thick_line(m, (300, 512), (820, 512), 36)           # mũi tên
    poly(m, [(800, 452), (900, 512), (800, 572)])
    poly(m, [(300, 512), (240, 450), (210, 450), (260, 512), (210, 574), (240, 574)])


def dual_blades(m):
    for deg in (-38, 38):
        d = [(490, 640), (490, 330), (520, 220), (560, 160), (548, 300), (534, 640)]
        poly(m, d, deg)
        poly(m, [(440, 640), (584, 640), (584, 680), (440, 680)], deg)
        poly(m, [(494, 680), (530, 680), (530, 800), (494, 800)], deg)
        c = rot([(512, 830)], deg)[0]
        ImageDraw.Draw(m).ellipse([c[0] - 34, c[1] - 34, c[0] + 34, c[1] + 34], outline=WHITE, width=16)


def staff(m):
    thick_line(m, (420, 880), (600, 330), 46)
    c = (630, 250)
    ImageDraw.Draw(m).ellipse([c[0] - 120, c[1] - 120, c[0] + 120, c[1] + 120], outline=WHITE, width=34)
    star4(m, c, 90, 26)


def scythe(m):
    thick_line(m, (300, 880), (640, 160), 44)
    blade = []
    for i in range(0, 41):
        t = i / 40
        a = math.radians(200 - 150 * t)
        r = 330 - 60 * t
        blade.append((640 + r * math.cos(a) * 1.0 + 0, 160 - r * math.sin(a) * 0.55 + 40 * t))
    inner = []
    for i in range(40, -1, -1):
        t = i / 40
        a = math.radians(200 - 150 * t)
        r = 330 - 60 * t
        inner.append((640 + (r - 70 * (1 - t)) * math.cos(a), 160 - (r - 70 * (1 - t)) * math.sin(a) * 0.35 + 90 * t))
    poly(m, blade + inner)


WEAPONS = {"sword": lambda m: sword(m), "bow": bow, "dual_blades": dual_blades, "staff": staff, "scythe": scythe,
           "greatsword": lambda m: greatsword(m)}


# ---------------- Nguyên tố ----------------

def star4(m, c, r, w):
    pts = []
    for i in range(8):
        a = math.radians(-90 + i * 45)
        rr = r if i % 2 == 0 else w
        pts.append((c[0] + rr * math.cos(a), c[1] + rr * math.sin(a)))
    poly(m, pts)


def flame(m, c=(512, 512), k=1.0):
    def P(pts):
        return [(c[0] + x * k, c[1] + y * k) for x, y in pts]
    d = ImageDraw.Draw(m)
    d.ellipse([c[0] - 220 * k, c[1] - 30 * k, c[0] + 220 * k, c[1] + 340 * k], fill=WHITE)   # bầu lửa
    d.polygon(P([(-215, 170), (-10, -380), (215, 170)]), fill=WHITE)                          # lưỡi chính
    d.polygon(P([(-215, 200), (-250, -140), (-60, 120)]), fill=WHITE)                         # lưỡi trái
    d.polygon(P([(215, 200), (230, -90), (60, 120)]), fill=WHITE)                             # lưỡi phải
    # lõi khoét rỗng hình giọt lửa nhỏ
    d.ellipse([c[0] - 100 * k, c[1] + 130 * k, c[0] + 100 * k, c[1] + 290 * k], fill=0)
    d.polygon(P([(-98, 215), (10, -60), (98, 215)]), fill=0)


def wind(m, c=(512, 512), k=1.0):
    for r, w, s, e in ((300, 56, 200, 520), (200, 50, 20, 330), (100, 44, 210, 470)):
        arc(m, [c[0] - r * k, c[1] - r * k, c[0] + r * k, c[1] + r * k], s, e, w * k)
    thick_line(m, (c[0] + 120 * k, c[1] + 300 * k), (c[0] + 330 * k, c[1] + 300 * k), 50 * k)


def bolt(m, c=(512, 512), k=1.0):
    pts = [(80, -330), (-170, 40), (-10, 40), (-90, 330), (180, -60), (20, -60), (120, -330)]
    poly(m, [(c[0] + x * k, c[1] + y * k) for x, y in pts])


def light(m, c=(512, 512), k=1.0):
    star4(m, c, 330 * k, 70 * k)
    ImageDraw.Draw(m).ellipse([c[0] - 210 * k, c[1] - 210 * k, c[0] + 210 * k, c[1] + 210 * k], outline=WHITE,
                              width=int(30 * k))


def dark(m, c=(512, 512), k=1.0):
    r = 300 * k
    ImageDraw.Draw(m).ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=WHITE)
    o = 130 * k
    ImageDraw.Draw(m).ellipse([c[0] - r + o, c[1] - r - o * 0.5, c[0] + r + o, c[1] + r - o * 0.5], fill=0)
    star4(m, (c[0] + 150 * k, c[1] + 120 * k), 90 * k, 22 * k)


def earth(m, c=(512, 512), k=1.0):
    pts = [(c[0] + 300 * k * math.cos(math.radians(a)), c[1] + 300 * k * math.sin(math.radians(a)))
           for a in range(-90, 270, 60)]
    poly(m, pts)
    d = ImageDraw.Draw(m)
    d.line([(c[0], c[1] - 300 * k), (c[0] - 40 * k, c[1] - 40 * k), (c[0] + 60 * k, c[1] + 60 * k),
            (c[0], c[1] + 300 * k)], fill=0, width=int(34 * k))
    d.line([(c[0] - 40 * k, c[1] - 40 * k), (c[0] - 260 * k, c[1] + 40 * k)], fill=0, width=int(30 * k))


ELEMENTS = {"fire": flame, "wind": wind, "lightning": bolt, "light": light, "dark": dark, "earth": earth}


# ---------------- Ghép ----------------

def burst(m, r0=360, r1=470, n=12, w=34):
    for i in range(n):
        a = math.radians(i * 360 / n + 15)
        thick_line(m, (512 + r0 * math.cos(a), 512 + r0 * math.sin(a)),
                   (512 + r1 * math.cos(a), 512 + r1 * math.sin(a)), w)


def shrink(draw_fn, k):
    """Vẽ hình rồi thu nhỏ quanh tâm (để chừa chỗ cho tia sáng bao quanh)."""
    t = canvas()
    draw_fn(t)
    sz = int(S * k)
    t = t.resize((sz, sz), Image.LANCZOS)
    m = canvas()
    m.paste(t, ((S - sz) // 2, (S - sz) // 2))
    return m


def jump(m):
    for y in (300, 520):
        poly(m, [(512, y - 170), (790, y + 110), (690, y + 190), (512, y + 30), (334, y + 190), (234, y + 110)])
    thick_line(m, (300, 850), (724, 850), 40)


def dodge(m):
    poly(m, [(560, 230), (840, 512), (560, 794), (450, 690), (630, 512), (450, 334)])
    for y, x0 in ((330, 140), (512, 80), (694, 140)):
        thick_line(m, (x0, y), (x0 + 250, y), 44)


def default_skill(m):
    star4(m, (512, 512), 360, 90)


def ultimate_frame(inner):
    m = shrink(inner, 0.62)
    burst(m, 340, 470, 16, 30)
    return m


def finish(mask, path):
    """Hình trắng + viền tối mềm, thu về 256 px."""
    outline = mask.filter(ImageFilter.MaxFilter(25)).filter(ImageFilter.GaussianBlur(6))
    rgba = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (S, S), (10, 14, 28, 255))
    shadow.putalpha(outline.point(lambda v: int(v * 0.75)))
    rgba = Image.alpha_composite(rgba, shadow)
    glyph = Image.new("RGBA", (S, S), (255, 255, 255, 255))
    glyph.putalpha(mask)
    rgba = Image.alpha_composite(rgba, glyph)
    rgba = rgba.resize((FINAL, FINAL), Image.LANCZOS)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    rgba.save(path)


def make(fn):
    m = canvas()
    fn(m)
    return m


def icon_sets():
    sets = {"default": {
        "attack": make(lambda m: sword(m)),
        "jump": make(jump),
        "dodge": make(dodge),
        "skill": make(default_skill),
        "weapon": (lambda m: (burst(m), m)[1])(shrink(lambda t: sword(t, -45), 0.7)),
        "ultimate": ultimate_frame(lambda t: star4(t, (512, 512), 300, 110)),
    }}
    for sid, (el, wp) in SUITS.items():
        w_draw = WEAPONS[wp]
        e_draw = ELEMENTS[el]
        weapon = shrink(w_draw, 0.72)
        burst(weapon, 380, 480, 10, 30)
        sets[sid] = {
            "attack": make(w_draw),
            "skill": make(e_draw),
            "weapon": weapon,
            "ultimate": ultimate_frame(e_draw),
        }
    return sets


def main(argv):
    force = "--force" in argv
    wrote = kept = 0
    for folder, icons in icon_sets().items():
        for slot, mask in icons.items():
            path = os.path.join(OUT, folder, slot + ".png")
            if os.path.exists(path) and not force:
                kept += 1
                continue
            finish(mask, path)
            wrote += 1
    print("Đã ghi %d icon, giữ nguyên %d icon đã có, thư mục %s" % (wrote, kept, OUT))


if __name__ == "__main__":
    for _s in (sys.stdout, sys.stderr):
        if hasattr(_s, "reconfigure"):
            _s.reconfigure(encoding="utf-8", errors="replace")
    main(sys.argv[1:])
