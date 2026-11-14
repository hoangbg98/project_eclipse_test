"""Hoàn thiện để đẹp trên MỌI nền (không chỉ nền tối):
1. Quầng mờ ngoài đĩa (a < 0.6): màu ép về sắc xanh của nét sáng (lấy trung vị màu các pixel quầng đậm), độ đục
   tính lại để phần đã nhân alpha (thứ thấy được trên nền tối) giữ nguyên kênh xanh lá → hết vệt xám trên nền sáng.
2. Kính trong đĩa (không phải nét): làm mịn độ đục bằng Gaussian lớn trong vùng kính, giữ nguyên phần đã nhân alpha
   (nên nhìn trên nền tối không đổi), độ đục không nhỏ hơn mức để màu ≤ 255 → hết loang trên nền sáng.
"""
import os
import sys

import numpy as np
from PIL import Image

out_dir = sys.argv[1]
im = np.asarray(Image.open(os.path.join(out_dir, "joystick_full_clean.png"))).astype(np.float64)
H, W, _ = im.shape
c = (W / 2.0, H / 2.0)
yy, xx = np.mgrid[0:H, 0:W]
r = np.hypot(xx + 0.5 - c[0], yy + 0.5 - c[1])
al = im[..., 3] / 255.0
P = im[..., :3] * al[..., None]

# 1. Quầng ngoài.
strong = (al > 0.55) & (al < 0.95) & (r > 340)
glow_col = np.median(im[..., :3][strong], axis=0)
print("màu quầng:", glow_col.round(1).tolist())
gmask = (r > 336) & (al < 0.6) & (al > 0)
wgt = np.clip((0.6 - al) / 0.25, 0.0, 1.0) * gmask
new_a = np.clip(P[..., 1] / glow_col[1], 0.0, 1.0)
new_P = glow_col[None, None, :] * new_a[..., None]
P = P * (1 - wgt[..., None]) + new_P * wgt[..., None]
al = al * (1 - wgt) + new_a * wgt

# (Bỏ bước làm phẳng kính: các mảng tối trong đĩa là bóng đổ ĐỤC có sẵn trong ảnh gốc, không phải nền sót.)
rgb = np.clip(P / np.maximum(al, 1e-4)[..., None], 0, 255)
rgb[al <= 0] = 0
img = Image.fromarray(np.dstack([rgb, al * 255]).round().astype(np.uint8), "RGBA")
img.save(os.path.join(out_dir, "joystick_final.png"))
for name, col in (("black", (0, 0, 0, 255)), ("white", (255, 255, 255, 255)), ("game", (36, 44, 66, 255))):
    b = Image.new("RGBA", img.size, col)
    b.alpha_composite(img)
    b.convert("RGB").save(os.path.join(out_dir, "polish_%s.png" % name))
print("xong")
