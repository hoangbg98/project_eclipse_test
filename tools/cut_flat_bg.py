"""Xóa nền một màu phẳng (vd xám #3B3B3B) của ảnh vũ khí / vật phẩm, GIỮ NGUYÊN kích thước khung, xuất PNG có alpha.

  python -I tools/cut_flat_bg.py <ảnh vào> <ảnh ra.png> [--t0 8] [--t1 34] [--close 4] [--holes 400]

Cách làm (Pillow + numpy):
1. Màu nền = trung vị 4 góc ảnh.
2. d = khoảng cách màu (RGB) tới màu nền. Vùng "gần nền" (d < --t1) nối với mép ảnh là nền (loang 4 hướng).
3. Trong vùng nền: alpha = (d - t0) / (t1 - t0) kẹp [0, 1] (quầng sáng, khói lửa giữ dạng trong mờ), màu được
   tách khỏi nền: c = (px - nền × (1 − a)) / a để không còn viền xám khi đặt lên nền khác. Ngoài vùng nền: đục.
Không cắt sát: ảnh ra cùng kích thước ảnh vào (chuẩn ô ảnh vũ khí 1950 × 1030). In tỉ lệ điểm trong suốt; mã thoát 0.
"""
import argparse
from collections import deque

import numpy as np
from PIL import Image


def _dilate(m, r):
    """Nới mặt nạ bool r px (ô vuông), chỉ dùng numpy."""
    if r <= 0:
        return m.copy()
    out = m.copy()
    h, w = m.shape
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dy == 0 and dx == 0:
                continue
            ys, yd = (slice(0, h - dy), slice(dy, h)) if dy >= 0 else (slice(-dy, h), slice(0, h + dy))
            xs, xd = (slice(0, w - dx), slice(dx, w)) if dx >= 0 else (slice(-dx, w), slice(0, w + dx))
            out[yd, xd] |= m[ys, xs]
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--t0", type=float, default=8.0, help="d dưới ngưỡng này: trong suốt hẳn")
    ap.add_argument("--t1", type=float, default=34.0, help="d từ ngưỡng này: đục hẳn; cũng là ngưỡng loang nền")
    ap.add_argument("--close", type=int, default=4, help="bịt khe viền (px) trước khi loang nền")
    ap.add_argument("--holes", type=int, default=0,
                    help="xóa cả lỗ nền bị bao kín có diện tích >= N px (0 = tắt); vd 400")
    ap.add_argument("--hole-t", type=float, default=12.0, help="ngưỡng màu của lỗ nền (chặt hơn --t1)")
    a = ap.parse_args()

    rgb = np.asarray(Image.open(a.src).convert("RGB")).astype(np.float32)
    h, w, _ = rgb.shape
    corners = np.array([rgb[0, 0], rgb[0, w - 1], rgb[h - 1, 0], rgb[h - 1, w - 1]])
    bg = np.median(corners, axis=0)
    d = np.sqrt(((rgb - bg) ** 2).sum(axis=2))
    near = d < a.t1
    # Bịt khe: nới vật thể --close px rồi mới loang nền, để nền không lọt qua khe viền vào phần có màu gần nền
    # (lưỡi kiếm tối); loang xong nới vùng nền lại --close px trong phần gần nền để viền vẫn mượt.
    obj = _dilate(~near, a.close)
    near_for_flood = ~obj

    region = np.zeros((h, w), dtype=bool)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if near_for_flood[y, x] and not region[y, x]:
                region[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if near_for_flood[y, x] and not region[y, x]:
                region[y, x] = True
                q.append((y, x))
    while q:
        y, x = q.popleft()
        for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= ny < h and 0 <= nx < w and near_for_flood[ny, nx] and not region[ny, nx]:
                region[ny, nx] = True
                q.append((ny, nx))
    region = _dilate(region, a.close) & near
    if a.holes > 0:
        # Lỗ nền bị vật bao kín (giữa dây và thân cung, trong vòng tròn): vùng liền gần như đúng màu nền
        # (d < --hole-t), đủ lớn (>= --holes px), không nối mép ảnh → cũng là nền.
        strict = (d < a.hole_t) & ~region
        seen = np.zeros((h, w), dtype=bool)
        holes = np.zeros((h, w), dtype=bool)
        ys, xs = np.nonzero(strict)
        for y0, x0 in zip(ys.tolist(), xs.tolist()):
            if seen[y0, x0]:
                continue
            comp = [(y0, x0)]
            seen[y0, x0] = True
            i = 0
            while i < len(comp):
                y, x = comp[i]
                i += 1
                for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                    if 0 <= ny < h and 0 <= nx < w and strict[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        comp.append((ny, nx))
            if len(comp) >= a.holes:
                cy, cx = zip(*comp)
                holes[list(cy), list(cx)] = True
        region |= _dilate(holes, a.close) & near

    alpha = np.ones((h, w), dtype=np.float32)
    soft = np.clip((d - a.t0) / (a.t1 - a.t0), 0.0, 1.0)
    alpha[region] = soft[region]
    out = rgb.copy()
    m = region & (alpha > 0.0)
    am = alpha[m][:, None]
    out[m] = np.clip((rgb[m] - bg * (1.0 - am)) / am, 0, 255)
    out[alpha <= 0.0] = 0
    rgba = np.dstack([out, alpha * 255.0]).round().astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(a.dst, optimize=True)
    print("%s: %dx%d, nền %s, trong suốt hẳn %.1f%%, trong mờ %.1f%%" % (
        a.dst, w, h, tuple(int(v) for v in bg), 100.0 * (alpha <= 0).mean(), 100.0 * ((alpha > 0) & (alpha < 1)).mean()))


if __name__ == "__main__":
    main()
