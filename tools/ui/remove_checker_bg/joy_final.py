"""Bước dọn cuối trên ảnh RGBA đã tách (dạng premultiplied, 4 kênh): mọi ô còn lệch theo đúng dấu ô caro so với
8 ô quanh thì trừ phần lệch; lọc giữ cạnh trên phần trong mờ; bỏ mảnh lạ ngoài bán kính hình (hình mờ xám, dấu
lấp lánh của công cụ tạo ảnh). Xuất ảnh cuối + bản xem trước."""
import os
import sys

import numpy as np
from PIL import Image

src, out_dir = sys.argv[1], sys.argv[2]
a = np.asarray(Image.open(src).convert("RGB")).astype(np.float64)
H, W, _ = a.shape
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "joy_grid.py"), encoding="utf-8").read())
s_cell = np.where(light, 1.0, -1.0)
CX, CY = 628.0, 424.0
R_KEEP0, R_KEEP1 = 396.0, 408.0

rgba = np.asarray(Image.open(os.path.join(out_dir, "raw5_rgba.png"))).astype(np.float64)
al = rgba[..., 3] / 255.0
P = np.dstack([rgba[..., :3] * al[..., None], rgba[..., 3]])          # premultiplied + alpha (0..255)
r = np.hypot(xx + 0.5 - CX, yy + 0.5 - CY)
soft = (al < 0.85) & (r < 338.0)          # chỉ trong đĩa kính; quầng ngoài (bản 2) đã sạch


def fix_outlier_cells(P, thr=1.5):
    gm = soft & (edge_dist > 1.2)
    order = np.lexsort((ci[gm], cj[gm]))
    keys = cj[gm][order] * NX + ci[gm][order]
    vals = P[gm][order]
    st = np.r_[0, np.nonzero(np.diff(keys))[0] + 1]
    en = np.r_[st[1:], len(keys)]
    med = np.full((NY, NX, 4), np.nan)
    for s_, e_ in zip(st, en):
        if e_ - s_ >= 4:
            kk = keys[s_]
            med[kk // NX, kk % NX] = np.median(vals[s_:e_], axis=0)
    pm = np.pad(med, ((1, 1), (1, 1), (0, 0)), constant_values=np.nan)
    nb = np.nanmedian(np.stack([pm[1 + dj:1 + dj + NY, 1 + di:1 + di + NX]
                                for dj in (-1, 0, 1) for di in (-1, 0, 1) if dj or di]), axis=0)
    dev = np.nan_to_num(med - nb)                 # lệch so với 8 ô quanh, cả hai chiều (ô bị phân loại sai cũng sửa)
    score = np.abs(dev.mean(axis=2))
    bad = score > thr
    corr = np.where(bad[..., None], dev, 0.0)
    c_px = corr[np.clip(cj, 0, NY - 1), np.clip(ci, 0, NX - 1)]
    print("  sửa %d ô" % int(bad.sum()))
    return np.where(soft[..., None], P - c_px, P)


RB, SIG_S, SIG_R = 6, 4.5, 8.0


def bilateral(P):
    num = np.zeros_like(P)
    den = np.zeros(P.shape[:2])
    Pp = np.pad(P, ((RB, RB), (RB, RB), (0, 0)), mode="edge")
    Sp = np.pad(soft, RB, mode="constant")
    for dy in range(-RB, RB + 1):
        for dx in range(-RB, RB + 1):
            sh = Pp[RB + dy:RB + dy + H, RB + dx:RB + dx + W]
            ss = Sp[RB + dy:RB + dy + H, RB + dx:RB + dx + W]
            w = (np.exp(-(dx * dx + dy * dy) / (2 * SIG_S ** 2))
                 * np.exp(-((sh - P) ** 2).sum(axis=2) / (2 * SIG_R ** 2 * 4)) * ss)
            num += w[..., None] * sh
            den += w
    Pb = num / np.maximum(den, 1e-9)[..., None]
    return np.where((soft & (den > 1e-6))[..., None], Pb, P)


for _ in range(3):
    P = fix_outlier_cells(P)
    P = bilateral(P)

P = np.clip(P, 0, 255)
alpha = P[..., 3] / 255.0
keep = np.clip((R_KEEP1 - r) / (R_KEEP1 - R_KEEP0), 0.0, 1.0)      # mờ dần về 0 ngoài bán kính hình
alpha *= keep
rgb = np.clip(P[..., :3] / np.maximum(P[..., 3:4] / 255.0, 1e-4), 0, 255)
rgb[alpha <= 0] = 0
out = np.dstack([rgb, alpha * 255]).round().astype(np.uint8)
img = Image.fromarray(out, "RGBA")
img.save(os.path.join(out_dir, "final5_full.png"))
bb = img.getchannel("A").point(lambda v: 255 if v > 0 else 0).getbbox()
img = img.crop(bb)
img.save(os.path.join(out_dir, "joystick_clean.png"))
print("kích thước", img.size, "khung", bb)
for name, col in (("black", (0, 0, 0, 255)), ("white", (255, 255, 255, 255)), ("game", (36, 44, 66, 255))):
    b = Image.new("RGBA", img.size, col)
    b.alpha_composite(img)
    b.convert("RGB").save(os.path.join(out_dir, "check_%s.png" % name))
