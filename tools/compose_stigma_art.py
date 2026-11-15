"""Ghép ảnh vết thánh (owner 2026-11-15): biểu tượng bộ ở chính giữa phía sau làm nền, có hào quang màu; ảnh nhân vật / món
(vuông 1:1, đã xóa nền) đặt chính giữa phía trước. Khung ra mặc định 1248 × 2280 (thẻ vết thánh 312 × 570 × 4).

  python -X utf8 -I tools/compose_stigma_art.py <biểu tượng.png> <ra.png> <ảnh vào.png> [--size 1248x2280]
         [--emblem-scale 0.96] [--glow #FF2A1A] [--glow-radius 46] [--glow-strength 1.6] [--emblem-tint 0.25]
         [--fit] [--margin 24] [--overflow 1.0] [--shift-x 0] [--no-emblem]
Lớp riêng cho full art ở bảng thông tin vết thánh: bỏ <ảnh vào> → chỉ biểu tượng + hào quang (vd --size 1400x1400
--emblem-scale 0.8); --no-emblem → chỉ nhân vật.

Ảnh vào và biểu tượng là PNG có alpha (xóa nền trước bằng tools/cut_flat_bg.py). Ảnh vào thu vừa bề ngang khung, giữ tỉ
lệ. Hào quang = mặt nạ alpha của biểu tượng làm mờ (2 lớp: rộng + sát viền) tô màu --glow. --emblem-tint pha màu
hào quang vào chính biểu tượng (0 = giữ màu gốc).
"""
import argparse

from PIL import Image, ImageChops, ImageFilter


def parse_color(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def glow_layer(alpha, color, radius, strength):
    out = Image.new("RGBA", alpha.size, color + (0,))
    a = Image.new("L", alpha.size, 0)
    for r, k in ((radius, 1.0), (radius * 0.35, 0.8)):
        blurred = alpha.filter(ImageFilter.GaussianBlur(r)).point(lambda v, k=k: min(255, int(v * strength * k)))
        a = ImageChops.lighter(a, blurred)
    out.putalpha(a)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("emblem")
    ap.add_argument("dst")
    ap.add_argument("src", nargs="?", default="", help="bỏ trống = chỉ biểu tượng + hào quang (lớp nền cho full art)")
    ap.add_argument("--size", default="1248x2280")
    ap.add_argument("--emblem-scale", type=float, default=0.96, help="bề ngang biểu tượng / bề ngang khung")
    ap.add_argument("--glow", default="#FF2A1A")
    ap.add_argument("--glow-radius", type=float, default=46.0)
    ap.add_argument("--glow-strength", type=float, default=1.6)
    ap.add_argument("--emblem-tint", type=float, default=0.25)
    ap.add_argument("--fit", action="store_true",
                    help="cắt ảnh vào theo vùng có hình rồi phóng cho vừa khít khung (trừ --margin); biểu tượng có thể bị xén")
    ap.add_argument("--margin", type=int, default=24, help="lề quanh hình khi --fit (px)")
    ap.add_argument("--no-emblem", action="store_true", help="chỉ ảnh vào (lớp nhân vật cho full art), không biểu tượng")
    ap.add_argument("--shift-x", type=int, default=0,
                    help="dời ảnh vào sang phải bấy nhiêu px (âm = sang trái) sau khi căn giữa; dùng khi đạo cụ một bên làm lệch nhân vật")
    ap.add_argument("--overflow", type=float, default=1.0,
                    help="--fit: cho hình rộng hơn khung tối đa bấy nhiêu lần (xén hai bên), vd 1.35 cho ảnh có cánh dang ngang")
    a = ap.parse_args()
    w, h = (int(v) for v in a.size.lower().split("x"))
    color = parse_color(a.glow)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    # Biểu tượng: thu theo bề ngang, đặt chính giữa; pha màu hào quang; hào quang phía sau.
    if not a.no_emblem:
        _draw_emblem(canvas, a, w, h, color)
    if a.src:
        _draw_src(canvas, a, w, h)
    canvas.save(a.dst, optimize=True)
    print("%s: %dx%d" % (a.dst, w, h))


def _draw_emblem(canvas, a, w, h, color):
    em = Image.open(a.emblem).convert("RGBA")
    ew = int(w * a.emblem_scale)
    em = em.resize((ew, int(em.height * ew / em.width)), Image.LANCZOS)
    if a.emblem_tint > 0:
        tint = Image.new("RGBA", em.size, color + (255,))
        mixed = Image.blend(em, tint, a.emblem_tint)
        mixed.putalpha(em.getchannel("A"))
        em = mixed
    pad = int(a.glow_radius * 3)
    big = Image.new("RGBA", (em.width + 2 * pad, em.height + 2 * pad), (0, 0, 0, 0))
    big.alpha_composite(em, (pad, pad))
    glow = glow_layer(big.getchannel("A"), color, a.glow_radius, a.glow_strength)
    ex, ey = (w - big.width) // 2, (h - big.height) // 2
    canvas.alpha_composite(glow, (ex, ey))
    canvas.alpha_composite(big, (ex, ey))


def _draw_src(canvas, a, w, h):
    # Ảnh vào: thu vừa bề ngang (hoặc vừa khít khung với --fit), chính giữa.
    src = Image.open(a.src).convert("RGBA")
    if a.fit:
        # Owner 2026-11-15: nhân vật vừa khít khung; cắt theo vùng alpha > 8 rồi phóng giữ tỉ lệ.
        box = src.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
        if box:
            src = src.crop(box)
        k = min((w - 2 * a.margin) * a.overflow / src.width, (h - 2 * a.margin) / src.height)
        src = src.resize((max(1, int(src.width * k)), max(1, int(src.height * k))), Image.LANCZOS)
    else:
        src = src.resize((w, int(src.height * w / src.width)), Image.LANCZOS)
    # alpha_composite cần vị trí trong khung: xén phần ra ngoài mép trước (khi dời --shift-x hoặc ảnh rộng hơn khung).
    x, y = (w - src.width) // 2 + a.shift_x, (h - src.height) // 2
    left, top = max(0, -x), max(0, -y)
    right, bottom = min(src.width, w - x), min(src.height, h - y)
    if right > left and bottom > top:
        canvas.alpha_composite(src.crop((left, top, right, bottom)), (x + left, y + top))


if __name__ == "__main__":
    main()
