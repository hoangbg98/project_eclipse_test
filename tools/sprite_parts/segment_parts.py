"""Tách các bộ phận trên sheet nền trắng thành vùng (bounding box), đánh số theo hàng."""
import json
import sys
from collections import deque

import numpy as np
from PIL import Image, ImageDraw, ImageFont

src, out_json, out_png = sys.argv[1], sys.argv[2], sys.argv[3]
img = Image.open(src).convert("RGB")
W, H = img.size
a = np.asarray(img).astype(int)
# Không phải nền trắng (JPEG có nhiễu nhẹ).
mask = (a.min(axis=2) < int(sys.argv[4]) if len(sys.argv) > 4 else 225)
S = 4
h2, w2 = H // S, W // S
small = mask[: h2 * S, : w2 * S].reshape(h2, S, w2, S).any(axis=(1, 3))
# Giãn 1 ô (4 px) để nối các mảnh rời của cùng bộ phận.
d = small.copy()
DIL = int(sys.argv[5]) if len(sys.argv) > 5 else 1
for dy in range(-DIL, DIL + 1):
    for dx in range(-DIL, DIL + 1):
        d |= np.roll(np.roll(small, dy, 0), dx, 1)
lab = np.zeros_like(d, dtype=int)
boxes = []
n = 0
for y in range(h2):
    for x in range(w2):
        if d[y, x] and not lab[y, x]:
            n += 1
            q = deque([(y, x)])
            lab[y, x] = n
            y0 = y1 = y
            x0 = x1 = x
            cnt = 0
            while q:
                cy, cx = q.popleft()
                cnt += 1
                y0, y1, x0, x1 = min(y0, cy), max(y1, cy), min(x0, cx), max(x1, cx)
                for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                    if 0 <= ny < h2 and 0 <= nx < w2 and d[ny, nx] and not lab[ny, nx]:
                        lab[ny, nx] = n
                        q.append((ny, nx))
            if cnt >= 12:  # bỏ nhiễu
                boxes.append([x0 * S, y0 * S, (x1 + 1) * S, (y1 + 1) * S, cnt])
# Sắp theo hàng: nhóm theo tâm y (dung sai 60 px), rồi theo x.
boxes.sort(key=lambda b: ((b[1] + b[3]) / 2, b[0]))
rows = []
for b in boxes:
    cy = (b[1] + b[3]) / 2
    if rows and abs(cy - rows[-1][0]) < 60:
        rows[-1][1].append(b)
    else:
        rows.append([cy, [b]])
ordered = []
for _, rb in rows:
    ordered += sorted(rb, key=lambda b: b[0])
parts = [{"id": i + 1, "x": b[0], "y": b[1], "w": b[2] - b[0], "h": b[3] - b[1]} for i, b in enumerate(ordered)]
json.dump({"width": W, "height": H, "parts": parts}, open(out_json, "w"), indent=1)
# Ảnh xem thử có khung + số.
prev = img.copy()
dr = ImageDraw.Draw(prev)
try:
    font = ImageFont.truetype("arialbd.ttf", 22)
except OSError:
    font = ImageFont.load_default()
for p in parts:
    dr.rectangle([p["x"], p["y"], p["x"] + p["w"], p["y"] + p["h"]], outline=(0, 120, 255), width=2)
    dr.rectangle([p["x"], p["y"], p["x"] + 30, p["y"] + 26], fill=(0, 120, 255))
    dr.text((p["x"] + 3, p["y"] + 1), str(p["id"]), fill="white", font=font)
prev.save(out_png)
print(len(parts), "parts", W, H)
