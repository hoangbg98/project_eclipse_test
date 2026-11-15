"""Cắt ảnh tham chiếu cho phiếu Codex từ tờ bộ phận nền trắng, theo tên owner đã điền.

  python -I tools/sprite_parts/cut_refs.py char_earth_01 1:toan_than 2:mat_binh_thuong 52:pose_dung_cam_kiem ...

Đọc rig_parts/source/{id}_parts_sheet.jpg + {id}_parts_boxes.json, ghi
rig_parts/source/refs/{id}_ref_{NN}_{tên}.png (nền trong suốt).
Nền trắng nối với mép khung bị xóa (loang từ mép); mảnh nhỏ < 3% mảnh lớn nhất và mảnh của bộ phận
bên cạnh (chạm mép khung, nằm ngoài khung đối với mảnh chính) bị bỏ.
"""
import json
import os
import sys

import cv2
import numpy as np

cid = sys.argv[1]
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
src = os.path.join(root, "assets", "characters", cid, "rig_parts", "source")
sheet = cv2.imread(os.path.join(src, cid + "_parts_sheet.jpg"))
boxes = {p["id"]: p for p in json.load(open(os.path.join(src, cid + "_parts_boxes.json"), encoding="utf-8"))["parts"]}
out_dir = os.path.join(src, "refs")
os.makedirs(out_dir, exist_ok=True)
PAD = 6

for arg in sys.argv[2:]:
    num, name = arg.split(":", 1)
    p = boxes[int(num)]
    x0, y0 = max(0, p["x"] - PAD), max(0, p["y"] - PAD)
    x1, y1 = min(sheet.shape[1], p["x"] + p["w"] + PAD), min(sheet.shape[0], p["y"] + p["h"] + PAD)
    crop = sheet[y0:y1, x0:x1].copy()
    h, w = crop.shape[:2]
    gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
    sat = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)[..., 1]
    white = ((gray > 228) & (sat < 30)).astype(np.uint8)
    # loang nền trắng từ mép
    bg = np.zeros((h + 2, w + 2), np.uint8)
    flood = white.copy() * 255
    for sx, sy in [(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)] + [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)]:
        if flood[sy, sx] == 255 and bg[sy + 1, sx + 1] == 0:
            cv2.floodFill(flood, bg, (sx, sy), 128)
    fg = (flood != 128).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(fg, 8)
    if n > 1:
        big = st[1:, cv2.CC_STAT_AREA].max()
        keep = np.zeros(n, bool)
        for i in range(1, n):
            a = st[i, cv2.CC_STAT_AREA]
            bx, by, bw, bh = st[i, :4]
            touches = bx <= PAD - 1 or by <= PAD - 1 or bx + bw >= w - PAD + 1 or by + bh >= h - PAD + 1
            if a == big or (a >= 0.03 * big and not (touches and a < 0.5 * big)):
                keep[i] = True
        fg = keep[lab].astype(np.uint8)
    alpha = cv2.GaussianBlur(fg.astype(np.float32), (3, 3), 0)
    rgba = np.dstack([crop, (alpha * 255).astype(np.uint8)])
    ys, xs = np.where(fg > 0)
    rgba = rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    fn = "%s_ref_%02d_%s.png" % (cid, int(num), name)
    cv2.imwrite(os.path.join(out_dir, fn), rgba)
    print(fn, rgba.shape[1], "x", rgba.shape[0])
