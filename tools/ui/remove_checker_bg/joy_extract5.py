"""Bản 5: đĩa kính màu. Biên độ ô caro k đo THEO Ô (so với các ô kề khác loại → độ dốc tuyến tính của quầng
sáng triệt tiêu), chỉ dùng pixel không thuộc nét sáng (bản 2: a < 0.85, giãn 2 px), lấp ô thiếu từ ô kề, nội suy
song tuyến ra pixel. Trừ k·s (s theo ô, có độ phủ ở mép) → ảnh không caro C. Độ đục a = 1 - mean(k/h), không
nhỏ hơn mức tối thiểu để C dựng được từ nền xám trung bình M (tránh màu xám / cháy). Ngoài đĩa giữ bản 2.
"""
import os
import sys

import numpy as np
from PIL import Image

src, out_dir = sys.argv[1], sys.argv[2]
a = np.asarray(Image.open(src).convert("RGB")).astype(np.float64)
H, W, _ = a.shape
alpha2 = np.load(os.path.join(out_dir, "alpha2.npy")).astype(np.float64)
fg2 = np.load(os.path.join(out_dir, "fg2.npy")).astype(np.float64)
CX, CY = 628.0, 424.0
R_IN, R_OUT = 336.0, 344.0          # đĩa kính + mép đĩa: bản 5; vòng ngoài và quầng: bản 2
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "joy_grid.py"), encoding="utf-8").read())
h = (L - D) / 2.0
M = (L + D) / 2.0
s_cell = np.where(light, 1.0, -1.0)

bright = alpha2 >= 0.85
for _ in range(2):                                   # giãn 2 px
    b2 = bright.copy()
    b2[1:] |= bright[:-1]; b2[:-1] |= bright[1:]; b2[:, 1:] |= bright[:, :-1]; b2[:, :-1] |= bright[:, 1:]
    bright = b2
use = core & ~bright

def estimate_k(img, signed):
    # Trung vị màu từng ô chỉ trên pixel dùng được; ô < 12 pixel dùng được = thiếu.
    order = np.lexsort((ci[use], cj[use]))
    keys = cj[use][order] * NX + ci[use][order]
    vals = img[use][order]
    st = np.r_[0, np.nonzero(np.diff(keys))[0] + 1]
    en = np.r_[st[1:], len(keys)]
    cm = np.full((NY, NX, 3), np.nan)
    for s_, e_ in zip(st, en):
        if e_ - s_ >= 12:
            kk = keys[s_]
            cm[kk // NX, kk % NX] = np.median(vals[s_:e_], axis=0)

    pad = np.pad(cm, ((1, 1), (1, 1), (0, 0)), constant_values=np.nan)
    pads = np.pad(s_cell, 1, constant_values=0)
    acc = np.zeros((NY, NX, 3))
    n = np.zeros((NY, NX))
    for dj, di in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        nbv = pad[1 + dj:1 + dj + NY, 1 + di:1 + di + NX]
        nbs = pads[1 + dj:1 + dj + NY, 1 + di:1 + di + NX]
        ok = (nbs == -s_cell) & ~np.isnan(nbv).any(axis=2) & ~np.isnan(cm).any(axis=2)
        acc += np.where(ok[..., None], (cm - np.nan_to_num(nbv)) * s_cell[..., None] / 2.0, 0.0)
        n += ok
    k_cell = np.where(n[..., None] >= 2, acc / np.maximum(n, 1)[..., None], np.nan)
    k_cell = k_cell if signed else np.clip(k_cell, 0.0, h[None, None, :])
    # Lấp ô thiếu: trung vị lân cận, lặp tới khi đầy (vùng nét đục lớn).
    for _ in range(12):
        miss = np.isnan(k_cell).any(axis=2)
        if not miss.any():
            break
        pk = np.pad(k_cell, ((1, 1), (1, 1), (0, 0)), constant_values=np.nan)
        st8 = np.stack([pk[1 + dj:1 + dj + NY, 1 + di:1 + di + NX] for dj in (-1, 0, 1) for di in (-1, 0, 1)])
        fill = np.nanmedian(st8, axis=0)
        k_cell = np.where(miss[..., None], fill, k_cell)
    k_cell = np.nan_to_num(k_cell, nan=0.0)
    # Làm mịn nhẹ (trung vị 3×3 ô) để bỏ ô lẻ.
    pk = np.pad(k_cell, ((1, 1), (1, 1), (0, 0)), mode="edge")
    k_cell = np.median(np.stack([pk[1 + dj:1 + dj + NY, 1 + di:1 + di + NX] for dj in (-1, 0, 1) for di in (-1, 0, 1)]), axis=0)

    u = (xx + 0.5 - x0) / px + 0.5
    v = (yy + 0.5 - y0) / py + 0.5
    i0 = np.clip(np.floor(u).astype(int), 0, NX - 2)
    j0 = np.clip(np.floor(v).astype(int), 0, NY - 2)
    tu = np.clip(u - i0, 0, 1)[..., None]
    tv = np.clip(v - j0, 0, 1)[..., None]
    k_px = (k_cell[j0, i0] * (1 - tu) * (1 - tv) + k_cell[j0, i0 + 1] * tu * (1 - tv)
            + k_cell[j0 + 1, i0] * (1 - tu) * tv + k_cell[j0 + 1, i0 + 1] * tu * tv)
    return k_px


k_px = estimate_k(a, False)
for it in range(3):
    C_ = a - k_px * (2.0 * cover - 1.0)[..., None]
    dk = estimate_k(C_, True)
    k_px = np.clip(k_px + dk, 0.0, h[None, None, :])
    print("lượt %d: |dk| trung bình %.3f" % (it, float(np.abs(dk).mean())))
# Nét chắc chắn đục: nền không lọt qua.
k_px = np.where((alpha2 > 0.97)[..., None], np.minimum(k_px, (1 - alpha2)[..., None] * h[None, None, :]), k_px)
s_px = (2.0 * cover - 1.0)[..., None]
C = a - k_px * s_px
# Lọc giữ cạnh (bilateral) trên phần kính mờ trong đĩa: xóa caro sót (biên độ vài mức xám), nét sáng tương
# phản cao giữ nguyên. Chỉ pixel không phải nét (bản 2: a < 0.85) và trọng số chỉ lấy từ pixel cùng loại.
glass = (alpha2 < 0.85) & (np.hypot(xx + 0.5 - CX, yy + 0.5 - CY) < R_OUT + 4)
RB, SIG_S, SIG_R = 7, 5.0, 9.0


def bilateral(C):
    num = np.zeros_like(C)
    den = np.zeros(C.shape[:2])
    Cp = np.pad(C, ((RB, RB), (RB, RB), (0, 0)), mode="edge")
    Gp = np.pad(glass, RB, mode="constant")
    for dy in range(-RB, RB + 1):
        for dx in range(-RB, RB + 1):
            sh = Cp[RB + dy:RB + dy + H, RB + dx:RB + dx + W]
            gs = Gp[RB + dy:RB + dy + H, RB + dx:RB + dx + W]
            wgt = (np.exp(-(dx * dx + dy * dy) / (2 * SIG_S ** 2))
                   * np.exp(-((sh - C) ** 2).sum(axis=2) / (2 * SIG_R ** 2 * 3)) * gs)
            num += wgt[..., None] * sh
            den += wgt
    Cb = num / np.maximum(den, 1e-9)[..., None]
    return np.where((glass & (den > 1e-6))[..., None], Cb, C)


def fix_outlier_cells(C):
    """Ô kính còn lệch theo đúng dấu ô caro so với 8 ô quanh: trừ phần lệch (phần sót của nền cũ)."""
    gm = glass & (edge_dist > 1.2)
    order = np.lexsort((ci[gm], cj[gm]))
    keys = cj[gm][order] * NX + ci[gm][order]
    vals = C[gm][order]
    st = np.r_[0, np.nonzero(np.diff(keys))[0] + 1]
    en = np.r_[st[1:], len(keys)]
    med = np.full((NY, NX, 3), np.nan)
    for s_, e_ in zip(st, en):
        if e_ - s_ >= 4:
            kk = keys[s_]
            med[kk // NX, kk % NX] = np.median(vals[s_:e_], axis=0)
    pm = np.pad(med, ((1, 1), (1, 1), (0, 0)), constant_values=np.nan)
    nb = np.nanmedian(np.stack([pm[1 + dj:1 + dj + NY, 1 + di:1 + di + NX]
                                for dj in (-1, 0, 1) for di in (-1, 0, 1) if dj or di]), axis=0)
    dev = np.nan_to_num(med - nb) * s_cell[..., None]           # > 0: lệch đúng chiều ô caro
    lum = dev.mean(axis=2)
    corr = np.where((lum > 2.0)[..., None], np.clip(dev, 0, None), 0.0) * s_cell[..., None]
    c_px = corr[np.clip(cj, 0, NY - 1), np.clip(ci, 0, NX - 1)]
    print("  sửa %d ô lệch" % int((lum > 2.0).sum()))
    return np.where(glass[..., None], C - c_px, C)


C = bilateral(C)
for _ in range(3):
    C = fix_outlier_cells(C)
    C = bilateral(C)
trans = np.clip((k_px / h[None, None, :]).mean(axis=2), 0.0, 1.0)
alpha5 = 1.0 - trans
# Độ đục tối thiểu để C = a·fg + (1-a)·M có fg trong [0, 255].
d = C - M[None, None, :]
amin = np.maximum(np.where(d > 0, d / (255.0 - M), 0.0), np.where(d < 0, -d / M, 0.0)).max(axis=2)
alpha5 = np.clip(np.maximum(alpha5, amin), 0.0, 1.0)
fg5 = np.clip((C - (1 - alpha5)[..., None] * M[None, None, :]) / np.maximum(alpha5, 1e-4)[..., None], 0, 255)

r = np.hypot(xx + 0.5 - CX, yy + 0.5 - CY)
t = np.clip((r - R_IN) / (R_OUT - R_IN), 0.0, 1.0)
alpha = alpha5 * (1 - t) + alpha2 * t
prem = (fg5 * alpha5[..., None]) * (1 - t)[..., None] + (fg2 * alpha2[..., None]) * t[..., None]
fg = np.clip(prem / np.maximum(alpha, 1e-4)[..., None], 0, 255)
np.save(os.path.join(out_dir, "alpha5.npy"), alpha.astype(np.float32))
np.save(os.path.join(out_dir, "fg5.npy"), fg.astype(np.float32))
Image.fromarray(np.dstack([fg, alpha * 255]).round().astype(np.uint8), "RGBA").save(os.path.join(out_dir, "raw5_rgba.png"))
print("xong")
