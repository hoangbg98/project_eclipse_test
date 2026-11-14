"""Tách ảnh nút di chuyển (đã xóa nền) thành đế và phím trung tâm cho VirtualJoystick.

  python -I tools/ui/split_joystick.py <ảnh vuông RGBA, tâm vòng = tâm ảnh> [bán kính cắt px]

Phím trung tâm = phần bên trong vòng cung trắng thứ hai (vòng tròn xanh nhạt nằm giữa vòng trắng nhỏ ở tâm và
các cung trắng, owner 2026-11-14), cắt ở khe kính tối r ≈ 152 px (ảnh 816 px), mép mềm 4 px.
Đế = phần còn lại; lỗ ở giữa đế lấp bằng màu kính trung vị của vành kính tối ngay trong đường cắt để khi phím lệch
khỏi tâm, đế vẫn liền mạch. Ghi:
  assets/ui/hud/joystick/joystick_full.png   ảnh đầy đủ (để owner chỉnh)
  assets/ui/hud/joystick/joystick_base.png   đế (cùng kích thước ảnh đầy đủ)
  assets/ui/hud/joystick/joystick_knob.png   phím (vuông, tâm = tâm phím)
"""
import os
import shutil
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "ui", "hud", "joystick")
src = sys.argv[1]
R_CUT = float(sys.argv[2]) if len(sys.argv) > 2 else 152.0
FEATHER = 4.0

im = np.asarray(Image.open(src).convert("RGBA")).astype(np.float64)
H, W, _ = im.shape
cx, cy = W / 2.0, H / 2.0
yy, xx = np.mgrid[0:H, 0:W]
r = np.hypot(xx + 0.5 - cx, yy + 0.5 - cy)
al = im[..., 3] / 255.0
P = im[..., :3] * al[..., None]
inside = np.clip((R_CUT + FEATHER / 2 - r) / FEATHER, 0.0, 1.0)      # 1 trong phím, 0 ngoài


def to_img(prem, alpha):
    rgb = np.clip(prem / np.maximum(alpha, 1e-4)[..., None], 0, 255)
    rgb[alpha <= 0] = 0
    return Image.fromarray(np.dstack([rgb, np.clip(alpha, 0, 1) * 255]).round().astype(np.uint8), "RGBA")


# Phím.
ka = al * inside
knob = to_img(P * inside[..., None], ka)
half = int(np.ceil(R_CUT + FEATHER)) + 1
knob = knob.crop((int(cx) - half, int(cy) - half, int(cx) + half, int(cy) + half))

# Đế: bỏ phần phím, lấp lỗ bằng màu kính tối ngay trong đường cắt (r ∈ [R_CUT-16, R_CUT-2], bỏ nét sáng;
# ngay ngoài đường cắt là các cung trắng nên không lấy mẫu ở đó).
ring = (r > R_CUT - 16) & (r < R_CUT - 2) & (im[..., :3].max(axis=2) < 150) & (al > 0.2)
assert ring.sum() > 100, "không đủ pixel kính để lấy màu lấp"
fill_P = np.median(P[ring], axis=0)
fill_a = float(np.median(al[ring]))
bP = P * (1 - inside[..., None]) + fill_P[None, None, :] * inside[..., None]
ba = al * (1 - inside) + fill_a * inside
base = to_img(bP, ba)

os.makedirs(OUT, exist_ok=True)
shutil.copyfile(src, os.path.join(OUT, "joystick_full.png"))
base.save(os.path.join(OUT, "joystick_base.png"))
knob.save(os.path.join(OUT, "joystick_knob.png"))
print("đế %s, phím %s (bán kính cắt %.0f px trên ảnh %d px → tỉ lệ phím %.4f)" % (
    base.size, knob.size, R_CUT, W, knob.size[0] / W))
