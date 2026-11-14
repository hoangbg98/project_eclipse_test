"""Bản 6 (vùng quầng sáng ngoài đĩa): biên độ ô caro k từng pixel bằng hồi quy cục bộ BẬC HAI
  ảnh ≈ b0 + b1·x + b2·y + b3·x² + b4·xy + b5·y² + k·s       (cửa sổ 25×25, bỏ pixel đục)
để khớp được độ cong của quầng sáng quanh vòng ngoài. Ghép: trong đĩa (r < 330) lấy bản 5 đã dọn,
ngoài (r > 342) lấy bản 6, giữa trộn tuyến tính.
"""
import os
import sys

import numpy as np
from PIL import Image

src, out_dir = sys.argv[1], sys.argv[2]
a = np.asarray(Image.open(src).convert("RGB")).astype(np.float64)
H, W, _ = a.shape
alpha2 = np.load(os.path.join(out_dir, "alpha2.npy")).astype(np.float64)
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "joy_grid.py"), encoding="utf-8").read())
h = (L - D) / 2.0
M = (L + D) / 2.0
s = 2.0 * cover - 1.0
CX, CY = 628.0, 424.0
RW = 12


def box(v):
    k = 2 * RW + 1
    pad = np.pad(v, ((RW, RW), (RW, RW)), mode="reflect")
    c = np.pad(pad.cumsum(0).cumsum(1), ((1, 0), (1, 0)))
    return c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]


opaque = alpha2 > 0.9
for _ in range(1):
    o2 = opaque.copy()
    o2[1:] |= opaque[:-1]; o2[:-1] |= opaque[1:]; o2[:, 1:] |= opaque[:, :-1]; o2[:, :-1] |= opaque[:, 1:]
    opaque = o2
wgt = (~opaque).astype(np.float64)
# Tọa độ cục bộ: dùng tọa độ tuyệt đối đã chuẩn hóa (cửa sổ nhỏ so với thang 1/30).
X = (xx - CX) / 30.0
Y = (yy - CY) / 30.0
basis = [np.ones((H, W)), X, Y, X * X, X * Y, Y * Y, s]
nb = len(basis)
r = np.hypot(xx + 0.5 - CX, yy + 0.5 - CY)
region = (r > 320) & (r < 410)
idx = np.nonzero(region)
A = np.empty((len(idx[0]), nb, nb))
for i in range(nb):
    for j in range(i, nb):
        v = box(wgt * basis[i] * basis[j])[idx]
        A[:, i, j] = v
        A[:, j, i] = v
A += np.eye(nb)[None] * 1e-2
k6 = np.zeros((H, W, 3))
for ch in range(3):
    b = np.stack([box(wgt * bb * a[..., ch])[idx] for bb in basis], axis=-1)
    sol = np.linalg.solve(A, b[..., None])[..., 0]
    k6[idx[0], idx[1], ch] = sol[:, -1]
cnt = box(wgt)
k6 = np.clip(k6, 0.0, h[None, None, :])
# Cửa sổ gần như không có pixel nền (giữa nét đục): coi như đục.
k6 = np.where((cnt < 40)[..., None], 0.0, k6)
k6 = np.where((alpha2 > 0.97)[..., None], np.minimum(k6, (1 - alpha2)[..., None] * h[None, None, :]), k6)
C = a - k6 * s[..., None]
trans = np.clip((k6 / h[None, None, :]).mean(axis=2), 0.0, 1.0)
alpha6 = 1.0 - trans
d = C - M[None, None, :]
amin = np.maximum(np.where(d > 0, d / (255.0 - M), 0.0), np.where(d < 0, -d / M, 0.0)).max(axis=2)
alpha6 = np.clip(np.maximum(alpha6, amin), 0.0, 1.0)
# Nền thuần (k ≈ h): sàn nhiễu nhỏ để không còn lớp mờ.
alpha6 = np.clip((alpha6 - 0.02) / 0.98, 0.0, 1.0)
fg6 = np.clip((C - (1 - alpha6)[..., None] * M[None, None, :]) / np.maximum(alpha6, 1e-4)[..., None], 0, 255)
np.save(os.path.join(out_dir, "alpha6.npy"), alpha6.astype(np.float32))
np.save(os.path.join(out_dir, "fg6.npy"), fg6.astype(np.float32))

# Ghép với bản 5 (đĩa, đã dọn ở joy_final → raw5_clean.png chưa cắt khung).
in5 = np.asarray(Image.open(os.path.join(out_dir, "final5_full.png"))).astype(np.float64)
a5 = in5[..., 3] / 255.0
f5 = in5[..., :3]
t = np.clip((r - 330.0) / 12.0, 0.0, 1.0)
alpha = a5 * (1 - t) + alpha6 * t
prem = f5 * (a5 * (1 - t))[..., None] + fg6 * (alpha6 * t)[..., None]
fg = np.clip(prem / np.maximum(alpha, 1e-4)[..., None], 0, 255)
keep = np.clip((408.0 - r) / 12.0, 0.0, 1.0)
alpha *= keep
fg[alpha <= 0] = 0
out = np.dstack([fg, alpha * 255]).round().astype(np.uint8)
Image.fromarray(out, "RGBA").save(os.path.join(out_dir, "merged6_full.png"))
print("xong")
