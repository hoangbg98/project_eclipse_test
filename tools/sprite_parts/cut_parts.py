"""Cắt các bộ phận từ sheet nền trắng thành PNG nền trong suốt theo nhãn owner đã điền.
Dùng: python cut_parts.py sheet.jpg labels.json out_dir
"""
import json
import os
import re
import sys
import unicodedata
from collections import deque

import numpy as np
from PIL import Image

src, labels_path, out_dir = sys.argv[1:4]
img = Image.open(src).convert("RGB")
W, H = img.size
a = np.asarray(img).astype(np.int32)
minc = a.min(axis=2)

# --- Nhãn vùng ở độ phân giải 1/4 (giống segment_parts.py, ngưỡng 190, không giãn) ---
S = 4
h2, w2 = H // S, W // S
mask = minc < 190
small = mask[: h2 * S, : w2 * S].reshape(h2, S, w2, S).any(axis=(1, 3))
lab = np.zeros((h2, w2), dtype=np.int32)
comp_box = {}
n = 0
for y in range(h2):
    for x in range(w2):
        if small[y, x] and not lab[y, x]:
            n += 1
            q = deque([(y, x)])
            lab[y, x] = n
            y0 = y1 = y
            x0 = x1 = x
            while q:
                cy, cx = q.popleft()
                y0, y1, x0, x1 = min(y0, cy), max(y1, cy), min(x0, cx), max(x1, cx)
                for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                    if 0 <= ny < h2 and 0 <= nx < w2 and small[ny, nx] and not lab[ny, nx]:
                        lab[ny, nx] = n
                        q.append((ny, nx))
            comp_box[n] = (x0 * S, y0 * S, (x1 + 1) * S - x0 * S, (y1 + 1) * S - y0 * S)
box_to_label = {v: k for k, v in comp_box.items()}

labels = json.load(open(labels_path, encoding="utf-8"))

_filled_cache = {}


def filled(lid):
    """Vùng của nhãn `lid` ở độ phân giải thấp, giãn 1 ô và lấp lỗ kín."""
    if lid in _filled_cache:
        return _filled_cache[lid]
    own = (lab == lid)
    outside = np.zeros_like(own)
    q2 = deque()
    for yy in range(h2):
        for xx in (0, w2 - 1):
            if not own[yy, xx] and not outside[yy, xx]:
                outside[yy, xx] = True
                q2.append((yy, xx))
    for xx in range(w2):
        for yy in (0, h2 - 1):
            if not own[yy, xx] and not outside[yy, xx]:
                outside[yy, xx] = True
                q2.append((yy, xx))
    while q2:
        cy, cx = q2.popleft()
        for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
            if 0 <= ny < h2 and 0 <= nx < w2 and not own[ny, nx] and not outside[ny, nx]:
                outside[ny, nx] = True
                q2.append((ny, nx))
    own = own | ~outside
    grown = own.copy()
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            grown |= np.roll(np.roll(own, dy, 0), dx, 1)
    _filled_cache[lid] = grown
    return grown


def to_full(m):
    f = np.repeat(np.repeat(m, S, 0), S, 1)
    return np.pad(f, ((0, H - f.shape[0]), (0, W - f.shape[1])))

used_labels = []
for _e in labels:
    _b = _e['box']
    used_labels.append(box_to_label[(_b['x'], _b['y'], _b['w'], _b['h'])])


def slug(s):
    s = unicodedata.normalize("NFD", s.replace("đ", "d").replace("Đ", "D"))
    s = "".join(c for c in s if unicodedata.category(c) != "Mn").lower()
    return re.sub(r"[^a-z0-9]+", "_", s).strip("_")[:40]


os.makedirs(out_dir, exist_ok=True)
manifest = []
for e in sorted(labels, key=lambda e: e["id"]):
    b = e["box"]
    key = (b["x"], b["y"], b["w"], b["h"])
    lid = box_to_label.get(key)
    if lid is None:
        raise SystemExit("không khớp vùng cho bộ phận %d %s" % (e["id"], key))
    pad = 6
    x0, y0 = max(b["x"] - pad, 0), max(b["y"] - pad, 0)
    x1, y1 = min(b["x"] + b["w"] + pad, W), min(b["y"] + b["h"] + pad, H)
    crop = a[y0:y1, x0:x1]
    cmin = minc[y0:y1, x0:x1]
    # Vùng thuộc bộ phận này: ô nhãn = lid, giãn 1 ô để lấy viền mờ.
    own_full = to_full(filled(lid))
    others = np.zeros((H, W), dtype=bool)
    for other in used_labels:
        if other != lid:
            ob = comp_box[other]
            if ob[0] < x1 and ob[0] + ob[2] > x0 and ob[1] < y1 and ob[1] + ob[3] > y0:
                others |= to_full(filled(other))
    # Pixel thuộc bộ phận khác (và không thuộc bộ phận này) thì bỏ.
    full = ~(others & ~own_full)
    full = full[y0:y1, x0:x1]
    # Nền: loang từ mép khung qua điểm gần trắng (giữ màu trắng bên trong như áo sơ mi, mắt).
    hh, ww = cmin.shape
    bg = np.zeros((hh, ww), dtype=bool)
    near_white = cmin >= 232
    q = deque()
    for yy in range(hh):
        for xx in (0, ww - 1):
            if near_white[yy, xx] and not bg[yy, xx]:
                bg[yy, xx] = True
                q.append((yy, xx))
    for xx in range(ww):
        for yy in (0, hh - 1):
            if near_white[yy, xx] and not bg[yy, xx]:
                bg[yy, xx] = True
                q.append((yy, xx))
    while q:
        cy, cx = q.popleft()
        for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
            if 0 <= ny < hh and 0 <= nx < ww and near_white[ny, nx] and not bg[ny, nx]:
                bg[ny, nx] = True
                q.append((ny, nx))
    alpha = np.where(bg | ~full, 0, 255).astype(np.int32)
    # Làm mềm viền: điểm sát nền mà còn sáng thì trong một phần (bỏ quầng trắng JPEG).
    edge = np.zeros_like(bg)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        edge |= np.roll(np.roll(bg, dy, 0), dx, 1)
    soft = edge & (alpha > 0)
    alpha[soft] = np.clip((255 - cmin[soft]) * 255 // 70, 0, 255)
    # Bỏ mảnh vụn: giữ các mảnh liền ≥ 2% mảnh lớn nhất (chấm lẻ từ bộ phận bên cạnh / nhiễu JPEG).
    vis = alpha > 0
    seen = np.zeros_like(vis)
    comps = []
    for sy, sx in zip(*np.nonzero(vis)):
        if seen[sy, sx]:
            continue
        seen[sy, sx] = True
        q3 = deque([(sy, sx)])
        pts = []
        while q3:
            cy, cx = q3.popleft()
            pts.append((cy, cx))
            for ny in (cy - 1, cy, cy + 1):
                for nx in (cx - 1, cx, cx + 1):
                    if 0 <= ny < hh and 0 <= nx < ww and vis[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        q3.append((ny, nx))
        comps.append(pts)
    biggest = max(len(c) for c in comps)
    for c in comps:
        if len(c) < 0.02 * biggest:
            ys_, xs_ = zip(*c)
            alpha[list(ys_), list(xs_)] = 0
    rgba = np.dstack([crop, alpha]).astype(np.uint8)
    # Cắt sát theo alpha.
    ys, xs = np.nonzero(alpha)
    if len(ys) == 0:
        raise SystemExit("bộ phận %d rỗng" % e["id"])
    ty0, ty1, tx0, tx1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    rgba = rgba[ty0:ty1, tx0:tx1]
    name = "char_fire_01_part_%02d_%s_%s.png" % (e["id"], e["category"], slug(e["name"]))
    Image.fromarray(rgba, "RGBA").save(os.path.join(out_dir, name), optimize=True)
    manifest.append({
        "id": e["id"], "file": name, "category": e["category"], "name": e["name"], "side": e.get("side", ""),
        "note": e.get("note", ""),
        "sheet_rect": [int(x0 + tx0), int(y0 + ty0), int(tx1 - tx0), int(ty1 - ty0)],
    })
json.dump({"character_id": "char_fire_01", "source_sheet": "char_fire_01_parts_sheet.jpg",
           "sheet_size": [W, H], "parts": manifest},
          open(os.path.join(out_dir, "parts_manifest.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(manifest), "parts written")
