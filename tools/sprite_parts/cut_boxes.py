"""Cắt bộ phận theo khung đặt tay (khung được chồng nhau) thành PNG nền trong suốt.

  python -I tools/sprite_parts/cut_boxes.py char_light_01 [--clear-holes 28] [--fill-holes 29] [--blue-only 18]

Đọc assets/characters/{id}/rig_parts/source/{id}_parts_sheet.jpg + {id}_parts_labels.json,
ghi assets/characters/{id}/rig_parts/{id}_part_{NN}_{loại}_{tên}.png + parts_manifest.json.

Khác cut_parts.py (cần mỗi khung trùng một vùng tự tách): ở đây khung là giới hạn cắt.
- Nền trắng nối với mép khung bị xóa (loang từ mép); trắng kín bên trong (áo, mắt) giữ lại.
- Mảnh nhỏ < 3% mảnh lớn nhất bị bỏ; mảnh chạm mép khung mà nhỏ hơn nửa mảnh lớn nhất cũng bỏ
  (thường là bộ phận bên cạnh lấn vào).
- Loại "fx" (quầng sáng mờ): alpha theo độ đậm so với nền trắng, không loang.
- --clear-holes N: trắng kín bên trong bộ phận N cũng là nền (vd lòng vòng mặt trời).
- --fill-holes N (fx): lấp lõi sáng gần trắng bên trong quầng (vd quả cầu sáng).
- --blue-only N: chỉ giữ vùng màu xanh (và nét viền sát nó) của bộ phận N, để tách đai vải khỏi váy.
Bộ phận dính liền với bộ phận khác trên tờ (vd tay áo chạm váy) vẫn còn phần lấn vào trong khung.
"""
import json
import os
import re
import sys
import unicodedata

import cv2
import numpy as np

PAD = 3


def slug(s):
    s = unicodedata.normalize("NFD", s.replace("đ", "d").replace("Đ", "D"))
    s = "".join(c for c in s if unicodedata.category(c) != "Mn").lower()
    return re.sub(r"[^a-z0-9]+", "_", s).strip("_")[:40]


def cut_solid(crop, clear_holes=False):
    h, w = crop.shape[:2]
    gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
    sat = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)[..., 1]
    white = ((gray > 228) & (sat < 30)).astype(np.uint8)
    flood = white * 255
    mask = np.zeros((h + 2, w + 2), np.uint8)
    edge = [(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)] + [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)]
    for sx, sy in edge:
        if flood[sy, sx] == 255:
            cv2.floodFill(flood, mask, (sx, sy), 128)
    if clear_holes:
        flood[flood == 255] = 128
    fg = (flood != 128).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(fg, 8)
    if n > 1:
        big = st[1:, cv2.CC_STAT_AREA].max()
        keep = np.zeros(n, bool)
        for i in range(1, n):
            a = st[i, cv2.CC_STAT_AREA]
            bx, by, bw, bh = st[i, :4]
            touches = bx <= PAD or by <= PAD or bx + bw >= w - PAD or by + bh >= h - PAD
            if a == big or (a >= 0.03 * big and not (touches and a < 0.5 * big)):
                keep[i] = True
        fg = keep[lab].astype(np.uint8)
    # Viền: điểm sát nền mà còn sáng thì trong một phần (bỏ quầng trắng JPEG).
    alpha = fg.astype(np.float32)
    ring = (cv2.dilate(1 - fg, np.ones((3, 3), np.uint8)) > 0) & (fg > 0)
    minc = crop.min(axis=2).astype(np.float32)
    alpha[ring] = np.clip((255 - minc[ring]) / 70.0, 0.35, 1.0)
    return alpha


def blue_mask(crop):
    hsv = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)
    m = ((hsv[..., 0] >= 95) & (hsv[..., 0] <= 125) & (hsv[..., 1] >= 25)).astype(np.uint8)
    m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, np.ones((7, 7), np.uint8))
    n, lab, st, _ = cv2.connectedComponentsWithStats(m, 8)
    if n > 1:
        big = st[1:, cv2.CC_STAT_AREA].max()
        m = np.isin(lab, [i for i in range(1, n) if st[i, cv2.CC_STAT_AREA] >= 0.05 * big]).astype(np.uint8)
    h, w = m.shape
    flood = m.copy()
    cv2.floodFill(flood, np.zeros((h + 2, w + 2), np.uint8), (0, 0), 2)
    m[flood == 0] = 1
    return cv2.dilate(m, np.ones((5, 5), np.uint8)).astype(np.float32)


def cut_glow(crop, fill_holes=False):
    minc = crop.min(axis=2).astype(np.float32)
    alpha = np.clip((250 - minc) / 60.0, 0, 1)
    if fill_holes:
        m = (alpha > 0.15).astype(np.uint8)
        h, w = m.shape
        flood = m.copy()
        cv2.floodFill(flood, np.zeros((h + 2, w + 2), np.uint8), (0, 0), 2)
        alpha[flood == 0] = 1.0
    return alpha


def main():
    args = sys.argv[1:]
    cid = args.pop(0)
    clear, fill, blue = set(), set(), set()
    while args:
        flag, num = args.pop(0), int(args.pop(0))
        {"--clear-holes": clear, "--fill-holes": fill, "--blue-only": blue}[flag].add(num)
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
    base = os.path.join(root, "assets", "characters", cid, "rig_parts")
    src = os.path.join(base, "source")
    sheet_name = cid + "_parts_sheet.jpg"
    sheet = cv2.imread(os.path.join(src, sheet_name))
    H, W = sheet.shape[:2]
    labels = json.load(open(os.path.join(src, cid + "_parts_labels.json"), encoding="utf-8"))["labels"]
    manifest = []
    for e in sorted(labels, key=lambda e: e["id"]):
        if e["category"] == "skip":
            continue
        b = e["box"]
        x0, y0 = max(0, b["x"] - PAD), max(0, b["y"] - PAD)
        x1, y1 = min(W, b["x"] + b["w"] + PAD), min(H, b["y"] + b["h"] + PAD)
        crop = sheet[y0:y1, x0:x1]
        alpha = cut_glow(crop, e["id"] in fill) if e["category"] == "fx" else cut_solid(crop, e["id"] in clear)
        if e["id"] in blue:
            alpha = alpha * blue_mask(crop)
        ys, xs = np.where(alpha > 0.02)
        if len(ys) == 0:
            raise SystemExit("bộ phận %d rỗng" % e["id"])
        ty0, ty1, tx0, tx1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        rgba = np.dstack([crop, (alpha * 255).astype(np.uint8)])[ty0:ty1, tx0:tx1]
        fn = "%s_part_%02d_%s_%s.png" % (cid, e["id"], e["category"], slug(e["name"]))
        cv2.imwrite(os.path.join(base, fn), rgba)
        manifest.append({"id": e["id"], "file": fn, "category": e["category"], "name": e["name"],
                         "side": e.get("side", ""), "note": e.get("note", ""),
                         "sheet_rect": [int(x0 + tx0), int(y0 + ty0), int(tx1 - tx0), int(ty1 - ty0)]})
    json.dump({"character_id": cid, "source_sheet": sheet_name, "sheet_size": [W, H], "parts": manifest},
              open(os.path.join(base, "parts_manifest.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(len(manifest), "parts written")


main()
