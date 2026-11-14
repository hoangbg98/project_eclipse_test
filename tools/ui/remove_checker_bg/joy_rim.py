"""Dải mép đĩa (r 308–350): mép đĩa và khe giữa đĩa với vòng ngoài là cấu trúc tròn đều. Làm mịn theo hệ cực:
với mỗi bán kính, trung vị theo góc trong cửa sổ ±12° (dạng premultiplied, bỏ pixel nét đục), rồi thay các pixel
không phải nét trong dải bằng giá trị đó (trộn mềm ở hai biên dải). Bỏ răng cưa theo ô caro ở mép đĩa."""
import os
import sys

import numpy as np
from PIL import Image

out_dir = sys.argv[1]
im = np.asarray(Image.open(os.path.join(out_dir, "merged6_full.png"))).astype(np.float64)
alpha2 = np.load(os.path.join(out_dir, "alpha2.npy")).astype(np.float64)
H, W, _ = im.shape
CX, CY = 628.0, 424.0
R0, R1, FADE = 308.0, 350.0, 6.0
al = im[..., 3] / 255.0
P = np.dstack([im[..., :3] * al[..., None], im[..., 3]])
feat = alpha2 > 0.9
for _ in range(2):
    f2 = feat.copy()
    f2[1:] |= feat[:-1]; f2[:-1] |= feat[1:]; f2[:, 1:] |= feat[:, :-1]; f2[:, :-1] |= feat[:, 1:]
    feat = f2

NR, NT = int((R1 - R0) * 2) + 1, 2880
rs = np.linspace(R0, R1, NR)
ts = np.linspace(0, 2 * np.pi, NT, endpoint=False)
RR, TT = np.meshgrid(rs, ts, indexing="ij")
sx = CX - 0.5 + RR * np.cos(TT)
sy = CY - 0.5 + RR * np.sin(TT)
ix = np.clip(np.round(sx).astype(int), 0, W - 1)
iy = np.clip(np.round(sy).astype(int), 0, H - 1)
samp = P[iy, ix]                                   # NR × NT × 4
fmask = feat[iy, ix]
samp = np.where(fmask[..., None], np.nan, samp)
HALF = int(NT * 12 / 360)
ext = np.concatenate([samp[:, -HALF:], samp, samp[:, :HALF]], axis=1)
prof = np.empty_like(samp)
STEP = 8
for t0 in range(0, NT, STEP):
    win = ext[:, t0:t0 + 2 * HALF + 1]
    med = np.nanmedian(win, axis=1)
    prof[:, t0:t0 + STEP] = med[:, None, :]
prof = np.where(np.isnan(prof), 0.0, prof)

yy, xx = np.mgrid[0:H, 0:W]
r = np.hypot(xx + 0.5 - CX, yy + 0.5 - CY)
th = np.mod(np.arctan2(yy + 0.5 - CY, xx + 0.5 - CX), 2 * np.pi)
band = (r >= R0) & (r <= R1)
ri = np.clip((r - R0) / (R1 - R0) * (NR - 1), 0, NR - 1)
ti = th / (2 * np.pi) * NT
r0i = np.floor(ri).astype(int); r1i = np.minimum(r0i + 1, NR - 1); fr = ri - r0i
t0i = np.floor(ti).astype(int) % NT; t1i = (t0i + 1) % NT; ft = ti - np.floor(ti)
val = ((prof[r0i, t0i] * (1 - ft)[..., None] + prof[r0i, t1i] * ft[..., None]) * (1 - fr)[..., None]
       + (prof[r1i, t0i] * (1 - ft)[..., None] + prof[r1i, t1i] * ft[..., None]) * fr[..., None])
w = np.clip(np.minimum(r - R0, R1 - r) / FADE, 0.0, 1.0) * band * (~feat)
P = P * (1 - w[..., None]) + val * w[..., None]
alpha = np.clip(P[..., 3] / 255.0, 0, 1)
rgb = np.clip(P[..., :3] / np.maximum(alpha, 1e-4)[..., None], 0, 255)
rgb[alpha <= 0] = 0
Image.fromarray(np.dstack([rgb, alpha * 255]).round().astype(np.uint8), "RGBA").save(os.path.join(out_dir, "merged7_full.png"))
print("xong")
