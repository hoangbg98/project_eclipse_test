"""Lọc giữ cạnh nhẹ cho quầng ngoài (r 336–410, phần trong mờ), dạng premultiplied: xóa caro sót rất mờ trong quầng,
mép nét sáng giữ nguyên (trọng số theo độ khác màu). Sau đó cắt khung, xuất ảnh sạch + bản xem trước."""
import os
import sys

import numpy as np
from PIL import Image

out_dir = sys.argv[1]
im = np.asarray(Image.open(os.path.join(out_dir, "merged7_full.png"))).astype(np.float64)
H, W, _ = im.shape
CX, CY = 628.0, 424.0
yy, xx = np.mgrid[0:H, 0:W]
r = np.hypot(xx + 0.5 - CX, yy + 0.5 - CY)
al = im[..., 3] / 255.0
P = np.dstack([im[..., :3] * al[..., None], im[..., 3]])
soft = (al < 0.8) & (r > 334) & (r < 412)
RB, SIG_S, SIG_R = 6, 4.0, 7.0
for _ in range(2):
    num = np.zeros_like(P)
    den = np.zeros((H, W))
    Pp = np.pad(P, ((RB, RB), (RB, RB), (0, 0)), mode="edge")
    Sp = np.pad(soft, RB)
    for dy in range(-RB, RB + 1):
        for dx in range(-RB, RB + 1):
            sh = Pp[RB + dy:RB + dy + H, RB + dx:RB + dx + W]
            ss = Sp[RB + dy:RB + dy + H, RB + dx:RB + dx + W]
            w = np.exp(-(dx * dx + dy * dy) / (2 * SIG_S ** 2)) * np.exp(-((sh - P) ** 2).sum(axis=2) / (2 * SIG_R ** 2 * 4)) * ss
            num += w[..., None] * sh
            den += w
    P = np.where((soft & (den > 1e-6))[..., None], num / np.maximum(den, 1e-9)[..., None], P)
alpha = np.clip(P[..., 3] / 255.0, 0, 1)
alpha = np.where(alpha < 0.012, 0.0, alpha)        # bỏ lớp mờ gần 0 (không thấy được) để mép ảnh sạch
rgb = np.clip(P[..., :3] / np.maximum(alpha, 1e-4)[..., None], 0, 255)
rgb[alpha <= 0] = 0
img = Image.fromarray(np.dstack([rgb, alpha * 255]).round().astype(np.uint8), "RGBA")
bb = img.getchannel("A").getbbox()
# Khung vuông quanh tâm (để tâm ảnh = tâm vòng, joystick xoay / co giãn đúng).
half = int(np.ceil(max(CX - bb[0], bb[2] - CX, CY - bb[1], bb[3] - CY))) + 2
sq = Image.new("RGBA", (2 * half, 2 * half), (0, 0, 0, 0))
sq.paste(img.crop((int(CX) - half, int(CY) - half, int(CX) + half, int(CY) + half)), (0, 0))
sq.save(os.path.join(out_dir, "joystick_full_clean.png"))
print("ảnh vuông", sq.size, "bán kính", half)
for name, col in (("black", (0, 0, 0, 255)), ("white", (255, 255, 255, 255)), ("game", (36, 44, 66, 255))):
    b = Image.new("RGBA", sq.size, col)
    b.alpha_composite(sq)
    b.convert("RGB").save(os.path.join(out_dir, "final_%s.png" % name))
