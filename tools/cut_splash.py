"""Xóa nền trắng của ảnh splash art (2D, không chibi) và cắt sát nhân vật, xuất PNG có alpha.

  python -I tools/cut_splash.py <ảnh vào> <ảnh ra.png> [--edge-thresh 235] [--hole-thresh 240] [--hole-area 100]
         [--hole-mean 246] [--erode 1] [--margin 8]

Cách làm (chỉ Pillow + numpy):
1. Nền nối mép: vùng gần trắng (mọi kênh >= --edge-thresh) nối với mép ảnh.
2. Lỗ kín (khoảng trắng bị nhân vật bao quanh: giữa tay và kiếm, khe giữa tay và thân...): vùng sáng (>= --hole-thresh)
   không nối mép, rộng >= --hole-area px và trắng thuần (trung bình >= --hole-mean) cũng là nền. Áo sơ mi trắng ngà và
   các điểm sáng nhỏ (tóc, mắt) không bị xóa.
3. Alpha = ngược của nền; làm sạch đốm lẻ, khử viền sáng (dải 2 px sát mép), co viền --erode px rồi làm mượt nhẹ để không
   còn quầng trắng khi đặt lên nền tối.
4. Cắt sát vùng có alpha + --margin px; ghi PNG.
Lưu ý Pillow 10.2: ImageDraw.floodfill trên ảnh tạo từ mảng numpy không làm gì, phải .copy() trước.
In kích thước và tỉ lệ điểm bị xóa để soát nhanh; mã thoát 0.
"""
import argparse
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# In tiếng Việt ra console Windows (cp1252) khi chạy bằng python -I (bỏ qua PYTHONUTF8).
for _s in (sys.stdout, sys.stderr):
    if hasattr(_s, "reconfigure"):
        _s.reconfigure(encoding="utf-8", errors="replace")


def flood(mask_img, seed):
    """Tô vùng liên thông của `seed` trong ảnh L (255 = gần trắng) bằng 128; trả về True nếu seed là 255."""
    if mask_img.getpixel(seed) != 255:
        return False
    ImageDraw.floodfill(mask_img, seed, 128)
    return True


def _fill_components(rest, min_area, min_mean, mn, limit=3000):
    """Duyệt các vùng 255 của ảnh L `rest`; trả về mảng bool gồm các vùng đủ lớn và đủ trắng."""
    out = np.zeros(mn.shape, dtype=bool)
    for _ in range(limit):
        ys, xs = np.nonzero(np.asarray(rest) == 255)
        if len(ys) == 0:
            break
        ImageDraw.floodfill(rest, (int(xs[0]), int(ys[0])), 100)
        reg = np.asarray(rest) == 100
        if int(reg.sum()) >= min_area and float(mn[reg].mean()) >= min_mean:
            out |= reg
        rest = Image.fromarray(np.where(reg, 0, np.asarray(rest)).astype(np.uint8), "L").copy()
    return out


def background_mask(rgb, edge_thresh, hole_thresh, hole_area, hole_mean):
    """Mảng bool, True = nền (nối mép hoặc lỗ kín)."""
    mn = rgb.min(axis=2)
    near_edge = mn >= edge_thresh
    # Khung 1 px trắng bao quanh để mọi điểm gần trắng ở mép nối với nhau.
    padded = Image.fromarray(np.pad(near_edge, 1, constant_values=True).astype(np.uint8) * 255, "L").copy()
    ImageDraw.floodfill(padded, (0, 0), 128)
    bg = np.asarray(padded)[1:-1, 1:-1] == 128
    rest = Image.fromarray(((mn >= hole_thresh) & ~bg).astype(np.uint8) * 255, "L").copy()
    return bg | _fill_components(rest, hole_area, hole_mean, mn)


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--edge-thresh", type=int, default=235, help="ngưỡng gần trắng cho nền nối mép")
    ap.add_argument("--hole-thresh", type=int, default=240, help="ngưỡng sáng cho lỗ kín")
    ap.add_argument("--hole-area", type=int, default=100, help="diện tích tối thiểu (px) của lỗ kín")
    ap.add_argument("--hole-mean", type=int, default=246, help="độ trắng trung bình tối thiểu của lỗ kín")
    ap.add_argument("--erode", type=int, default=1)
    ap.add_argument("--margin", type=int, default=8)
    args = ap.parse_args(argv)

    img = Image.open(args.src).convert("RGB")
    rgb = np.asarray(img)
    bg = background_mask(rgb, args.edge_thresh, args.hole_thresh, args.hole_area, args.hole_mean)
    alpha = Image.fromarray((~bg).astype(np.uint8) * 255, "L")
    # Bỏ đốm lẻ (mở hình thái), rồi co viền để mất quầng trắng, làm mượt nhẹ.
    alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    # Khử viền: trong dải 2 px sát mép, điểm càng sáng (trộn màu với nền trắng) càng trong suốt.
    fg = np.asarray(alpha) > 127
    inner = np.asarray(alpha.filter(ImageFilter.MinFilter(5))) > 127
    band = fg & ~inner
    factor = np.clip((250.0 - rgb.min(axis=2)) / 80.0, 0.0, 1.0)
    a2 = np.asarray(alpha).astype(np.float32)
    a2[band] *= factor[band]
    alpha = Image.fromarray(a2.astype(np.uint8), "L")
    for _ in range(max(args.erode, 0)):
        alpha = alpha.filter(ImageFilter.MinFilter(3))
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.8))
    out = img.convert("RGBA")
    out.putalpha(alpha)
    bbox = alpha.point(lambda v: 255 if v >= 24 else 0).getbbox()
    if bbox is None:
        print("LỖI: không còn điểm ảnh nào sau khi xóa nền (giảm --thresh?)")
        return 1
    x0, y0, x1, y1 = bbox
    m = args.margin
    box = (max(x0 - m, 0), max(y0 - m, 0), min(x1 + m, out.size[0]), min(y1 + m, out.size[1]))
    out = out.crop(box)
    out.save(args.dst, optimize=True)
    print("%s -> %s  %dx%d (gốc %dx%d), nền bị xóa %.1f%%" % (args.src, args.dst, out.size[0], out.size[1], img.size[0],
          img.size[1], 100.0 * bg.mean()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
