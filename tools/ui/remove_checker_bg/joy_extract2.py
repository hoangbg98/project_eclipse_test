"""Tách nút di chuyển khỏi nền caro vẽ sẵn (bản 2).

- Lưới ô khớp từ mép ảnh (ô ~11.30 px, đều trên toàn ảnh).
- Ô sáng / tối quyết định từng ô: chọn giả thiết (nền tối hay sáng) làm độ đục của ô khớp nhất với các ô kề
  (lớp phủ xanh mịn nên độ đục thay đổi chậm), lặp vài lượt.
- Tách màu theo nền đã biết từng pixel (color-to-alpha): quầng xanh mờ giữ nguyên độ trong.
- Dải 1–2 px ở mép ô (ảnh gốc có răng cưa / nhòe ở mép ô caro): pixel trong mờ ở đó lấy theo lân cận lõi ô
  (trung bình có trọng số, dạng premultiplied) để không còn vệt lưới.
"""
import os
import sys

import numpy as np
from PIL import Image

src, out_dir = sys.argv[1], sys.argv[2]
a = np.asarray(Image.open(src).convert("RGB")).astype(np.float64)
H, W, _ = a.shape
g = a.mean(axis=2)
P = 11.3035
X0, Y0 = 7.665, 0.115


def fit_axis(lines):
    ts, ks = [], []
    for line in lines:
        t = np.nonzero(np.diff((line > 72).astype(int)))[0] + 1.0
        ts.append(t)
        ks.append(np.round(t / 11.30))
    t, k = np.concatenate(ts), np.concatenate(ks)
    p, x0 = np.polyfit(k, t, 1)
    keep = np.abs(t - (x0 + p * k)) < 1.5
    p, x0 = np.polyfit(k[keep], t[keep], 1)
    return p, x0


px, x0 = fit_axis([g[y] for y in (2, 4, 6, 837, 839, 841)])
py, y0 = fit_axis([g[:, x] for x in (2, 4, 6, 1257, 1259, 1261)])
x0 %= px
y0 %= py
print("lưới x0=%.3f px=%.4f  y0=%.3f py=%.4f" % (x0, px, y0, py))
NX = int(np.ceil(W / px)) + 3
NY = int(np.ceil(H / py)) + 3
yy, xx = np.mgrid[0:H, 0:W]
ci = np.floor((xx + 0.5 - x0) / px).astype(int) + 1
cj = np.floor((yy + 0.5 - y0) / py).astype(int) + 1
fx = ((xx + 0.5 - x0) / px) % 1.0
fy = ((yy + 0.5 - y0) / py) % 1.0
edge_dist = np.minimum(np.minimum(fx, 1 - fx) * px, np.minimum(fy, 1 - fy) * py)   # px tới mép ô gần nhất
core = edge_dist > 2.0

# Mức nền (lõi ô thuần ở dải mép ảnh).
border = np.zeros((H, W), bool)
border[:22, :] = border[-22:, :] = True
border[:, :22] = border[:, -22:] = True
bc = border & core
lo = g[bc] < 72
D = np.median(a[bc][lo], axis=0)
L = np.median(a[bc][~lo], axis=0)
print("nền tối", D.round(1).tolist(), "sáng", L.round(1).tolist())


def c2a(bg):
    d = a - bg
    up = np.where(d > 0, d / np.maximum(255.0 - bg, 1.0), 0.0)
    dn = np.where(d < 0, -d / np.maximum(bg, 1.0), 0.0)
    return np.maximum(up, dn).max(axis=2)


aD = c2a(D[None, None, :])
aL = c2a(L[None, None, :])


def cell_median(v):
    out = np.full((NY, NX), np.nan)
    order = np.lexsort((ci[core], cj[core]))
    keys = cj[core][order] * NX + ci[core][order]
    vals = v[core][order]
    starts = np.r_[0, np.nonzero(np.diff(keys))[0] + 1]
    ends = np.r_[starts[1:], len(keys)]
    for s, e in zip(starts, ends):
        k = keys[s]
        out[k // NX, k % NX] = np.median(vals[s:e])
    return out


mD, mL = cell_median(aD), cell_median(aL)
valid = ~np.isnan(mD)
# Khởi tạo: ô nào giả thiết "nền tối" cho độ đục thấp hơn thì coi là tối (đúng ở nền thuần).
light = mL < mD
for it in range(6):
    chosen = np.where(light, mL, mD)
    pad = np.pad(np.where(valid, chosen, np.nan), 1, constant_values=np.nan)
    nb = np.nanmedian(np.stack([pad[:-2, 1:-1], pad[2:, 1:-1], pad[1:-1, :-2], pad[1:-1, 2:],
                                pad[:-2, :-2], pad[:-2, 2:], pad[2:, :-2], pad[2:, 2:]]), axis=0)
    new = np.abs(mL - nb) < np.abs(mD - nb)
    # Ô gần như đục: hai giả thiết như nhau, giữ lựa chọn cũ.
    same = np.abs(mL - mD) < 0.04
    new = np.where(same | ~valid, light, new)
    changed = int((new != light).sum())
    light = new
    print("lượt %d: đổi %d ô" % (it, changed))
    if changed == 0:
        break

# Nền từng pixel với độ phủ (lấy mẫu 8×) ở mép ô.
SS = 8
cover = np.zeros((H, W))
for sy in range(SS):
    for sx in range(SS):
        i = np.floor((xx + (sx + 0.5) / SS - x0) / px).astype(int) + 1
        j = np.floor((yy + (sy + 0.5) / SS - y0) / py).astype(int) + 1
        cover += light[np.clip(j, 0, NY - 1), np.clip(i, 0, NX - 1)]
cover /= SS * SS
bg = D[None, None, :] * (1 - cover[..., None]) + L[None, None, :] * cover[..., None]
alpha = c2a(bg)
noise = float(np.percentile(alpha[border & core], 99.5))
print("sàn nhiễu lõi nền thuần p99.5 = %.4f" % noise)
alpha = np.clip((alpha - noise) / (1 - noise), 0, 1)
prem = np.clip(a - (1 - alpha[..., None]) * bg, 0, 255)     # màu đã nhân alpha

# Sửa dải mép ô: pixel trong mờ (nền ảnh hưởng nhiều) lấy trung bình lõi ô lân cận (cửa sổ 7×7).
band = (edge_dist <= 2.0) & (alpha < 0.85)
w = (core & (alpha < 0.98)).astype(np.float64) + 1e-6 * core


def box(v, r=3):
    k = 2 * r + 1
    pad = np.pad(v, ((r, r), (r, r)) + ((0, 0),) * (v.ndim - 2), mode="edge")
    c = pad.cumsum(0).cumsum(1)
    c = np.pad(c, ((1, 0), (1, 0)) + ((0, 0),) * (v.ndim - 2))
    return c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]


ws = box(w)
alpha_s = box(alpha * w) / np.maximum(ws, 1e-9)
prem_s = box(prem * w[..., None]) / np.maximum(ws, 1e-9)[..., None]
ok = band & (ws > 3)
alpha = np.where(ok, alpha_s, alpha)
prem = np.where(ok[..., None], prem_s, prem)
fg = np.clip(prem / np.maximum(alpha, 1e-4)[..., None], 0, 255)
fg[alpha < 1e-4] = 0
np.save(os.path.join(out_dir, "alpha2.npy"), alpha.astype(np.float32))
np.save(os.path.join(out_dir, "fg2.npy"), fg.astype(np.float32))
rgba = np.dstack([fg, alpha * 255]).round().astype(np.uint8)
Image.fromarray(rgba, "RGBA").save(os.path.join(out_dir, "raw2_rgba.png"))
print("xong")
