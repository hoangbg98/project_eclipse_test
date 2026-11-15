"""Sinh dữ liệu chọn chương + map chương (owner 2026-11-14) và ảnh tạm.

Chạy (thư mục gốc dự án):  python -X utf8 -I tools/story/gen_chapters.py

Sinh ra:
  data/story/chapters.json                       — nhóm chương (cột trái), chương, phần, ải (vị trí nút trên map)
  localization/vi.po, en.po                      — khóa ARC_*, CHAPTER_*, PART_* (thêm mới hoặc ghi đè)
  assets/placeholders/story/placeholder_map_chNN.png   — tranh map dài, mờ (kéo ngang trong game)
  assets/placeholders/story/placeholder_card_chNN.png  — ảnh thẻ chương ở màn chọn chương
  docs/prompts/story/CHAPTER_ART.md               — kích thước + prompt ChatGPT cho map và thẻ

Owner 2026-11-14: mỗi chương 10–30 ải, chia part 10–15 ải, chương sau ≥ chương trước; ải chưa có màn chơi vẫn hiện
nhưng khóa "Sắp ra mắt"; chương 1 cũng dùng map cuộn; quà mỗi phần theo huy chương (3 mục tiêu / ải).
Ảnh thật: assets/story/chapters/map_chNN.png, card_chNN.png (cùng tỉ lệ). Số thưởng là số tạm (owner chỉnh ở đây).
"""
import io
import json
import math
import os
import random
import re

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

MAP_H = 1080
STEP_X = 280          # khoảng cách ngang giữa hai ải
PART_GAP = 360        # khoảng trống giữa hai phần (đặt rương quà)
MARGIN = 360
ROWS_Y = [560, 420, 700, 480, 640]   # nút đi zíc zắc như ảnh tham chiếu
CARD = (380, 600)

PART_REWARD = {"gems": 300, "materials": {"mat_exp_medium": 3, "mat_enhance_ore": 5}}   # số tạm, owner chỉnh

# Nhóm chương ở cột trái (đề xuất, đổi tên ở đây)
ARCS = [
    ("arc_01", ("Tro Tàn Và Đá Ngủ", "Ash and Sleeping Stone"), [1, 2]),
    ("arc_02", ("Sét Câm, Ngọn Đèn Cuối", "Silent Thunder, Last Lamp"), [3, 4]),
    ("arc_03", ("Rừng Không Bóng, Đỉnh Gió Lặng", "Shadowless Forest, Windless Peak"), [5, 6]),
    ("arc_04", ("Nhật Thực", "Eclipse"), [7]),
]

# Chương: (số, tên vi, tên en, màu nền map (trên, dưới), [(tên phần vi, en, số ải)], màn chơi đã có {số ải: stage_id})
CHAPTERS = [
    (1, "Thung Lũng Tro Tàn", "The Ashen Valley", ((150, 120, 110), (60, 55, 60)),
     [("Thung Lũng Tro Tàn", "The Ashen Valley", 10)], {1: "stage_01", 2: "stage_01_02", 3: "stage_01_03"}),
    (2, "Xưởng Đá Ngủ", "The Sleeping Stone Workshop", ((140, 130, 105), (55, 60, 55)),
     [("Cao Nguyên Thủ Vệ", "Guardian Highlands", 12)], {}),
    (3, "Thành Tháp Sét Câm", "City of Silent Towers", ((70, 80, 120), (25, 28, 50)),
     [("Thành Tháp Sét Câm", "City of Silent Towers", 15)], {}),
    (4, "Thánh Đường Ngọn Đèn Cuối", "Sanctuary of the Last Lamp", ((190, 170, 120), (70, 60, 50)),
     [("Đường Tới Thánh Đường", "Road to the Sanctuary", 10), ("Ngọn Đèn Cuối", "The Last Lamp", 10)], {}),
    (5, "Rừng Không Bóng", "The Shadowless Forest", ((60, 90, 80), (15, 25, 25)),
     [("Bìa Rừng Không Bóng", "Edge of the Shadowless Forest", 12), ("Tàn Tích Trụ Thứ Bảy", "Ruins of the Seventh Pillar", 12)], {}),
    (6, "Đỉnh Gió Lặng", "The Windless Peak", ((120, 160, 180), (40, 55, 70)),
     [("Chân Núi Gió", "Foot of the Wind Mountain", 13), ("Đỉnh Gió Lặng", "The Windless Peak", 13)], {}),
    (7, "Nhật Thực", "Eclipse", ((60, 40, 70), (10, 8, 18)),
     [("Vào Lòng Nhật Thực", "Into the Eclipse", 15), ("Vành Sáng", "The Bright Ring", 15)], {}),
]

# Mô tả tranh map / thẻ cho prompt (tiếng Anh) theo tuyến truyện đã chốt
SCENES = {
    1: "a grey ash-covered valley with a dirt road winding toward a cliff carved with a gigantic dark furnace (the Mother Hearth), dead trees, ash falling, a small village at the valley mouth",
    2: "high stone plateau with ancient guardian workshops carved into rock, giant dormant stone golem statues, cranes and forges, misty",
    3: "a city of tall lightning-rod towers under a dark storm-less sky, power lines gone dead, empty streets, unlit windows",
    4: "a white marble sanctuary on a hill holding one great lamp of light, pilgrims' road, warm glow against a dim sky",
    5: "a deep forest where nothing casts a shadow, pale flat light, eerie silver trees, ancient pillar ruins half buried",
    6: "a towering wind mountain with dead still clouds, rope bridges, wind shrines, a summit with a broken ring-shaped pillar",
    7: "inside the eclipse: a vast dark sky with the bitten sun overhead, floating fragments of the seventh pillar, a bright ring of light",
}


def font(size, bold=True):
    for f in (("arialbd.ttf",) if bold else ()) + ("arial.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            continue
    return ImageFont.load_default()


def map_width(parts):
    n = sum(p[2] for p in parts)
    return MARGIN * 2 + (n - 1) * STEP_X + (len(parts) - 1) * PART_GAP


def gen_map(path, num, w, colors, title):
    """Tranh dài, mờ: trời chuyển màu, mặt trời khuyết, ba lớp núi / kiến trúc silhouette, rồi làm mờ."""
    rnd = random.Random(num * 7919)
    top, bot = colors
    img = Image.new("RGB", (w, MAP_H))
    d = ImageDraw.Draw(img)
    for y in range(MAP_H):
        t = y / MAP_H
        d.line([(0, y), (w, y)], fill=tuple(int(top[i] * (1 - t) + bot[i] * t) for i in range(3)))
    # mặt trời khuyết lặp lại theo chiều dài
    for sx in range(400, w, 2400):
        cx, cy, r = sx + rnd.randint(0, 600), 220 + rnd.randint(-40, 40), 110
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(245, 190, 120))
        d.ellipse([cx + r * 0.55, cy - r * 0.95, cx + r * 1.75, cy + r * 0.25], fill=tuple(int(c * 0.9) for c in top))
    for layer, (base, amp, shade) in enumerate([(640, 160, 0.75), (760, 120, 0.55), (880, 90, 0.35)]):
        col = tuple(int((top[i] * 0.4 + bot[i] * 0.6) * shade) for i in range(3))
        pts = [(0, MAP_H)]
        x = 0
        while x <= w:
            pts.append((x, base - rnd.randint(0, amp)))
            x += rnd.randint(60, 220)
        pts += [(w, MAP_H)]
        d.polygon(pts, fill=col)
        for _ in range(w // 900):                     # tháp / tòa nhà mờ
            bx = rnd.randint(0, w)
            bw, bh = rnd.randint(40, 120), rnd.randint(120, 360)
            d.rectangle([bx, base - bh, bx + bw, MAP_H], fill=col)
    img = img.filter(ImageFilter.GaussianBlur(14))
    d = ImageDraw.Draw(img)
    label = "placeholder_map_ch%02d  ·  %d × %d px  ·  Chương %d: %s" % (num, w, MAP_H, num, title)
    f = font(34)
    for x in range(200, w, 1800):
        d.text((x, 950), label, font=f, fill=(255, 255, 255))
    img.save(path)


def gen_card(path, num, colors, title):
    w, h = CARD
    top, bot = colors
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(int(top[i] * (1 - t) + bot[i] * t) for i in range(3)))
    d.ellipse([w - 170, 40, w - 40, 170], fill=(245, 190, 120))
    d.ellipse([w - 85, 15, w + 15, 115], fill=top)
    d.text((w / 2, h * 0.42), "%02d" % num, font=font(150), fill=(255, 255, 255), anchor="mm")
    d.text((w / 2, h * 0.62), "Chương %d" % num, font=font(36), fill=(255, 230, 160), anchor="mm")
    words, lines, cur = title.split(" "), [], ""
    f = font(28, False)
    for wd in words:
        if f.getlength((cur + " " + wd).strip()) > w - 40:
            lines.append(cur)
            cur = wd
        else:
            cur = (cur + " " + wd).strip()
    lines.append(cur)
    for i, l in enumerate(lines):
        d.text((w / 2, h * 0.70 + i * 34), l, font=f, fill=(240, 240, 250), anchor="mm")
    d.text((w / 2, h - 30), "placeholder_card_ch%02d · %d×%d" % (num, w, h), font=font(18, False), fill=(200, 200, 210), anchor="mm")
    img.save(path)


def esc(t):
    return t.replace("\\", "\\\\").replace('"', '\\"')


def main():
    keys = {}
    out = {"_comment": "Sinh bởi tools/story/gen_chapters.py — sửa ở đó rồi chạy lại.",
           "map_height": MAP_H, "art_dir": "res://assets/story/chapters",
           "placeholder_dir": "res://assets/placeholders/story", "part_reward": PART_REWARD,
           "arcs": [], "chapters": []}
    doc = ["""# Ảnh map chương và thẻ chương (ChatGPT)

> Sinh bởi `tools/story/gen_chapters.py`. Mỗi chương có **một tranh dài** làm nền map (người chơi kéo ngang liền mạch)
> và **một ảnh thẻ** ở màn chọn chương. Ảnh thật lưu ở `assets/story/chapters/` đúng tên, game tự thay placeholder.
> Ảnh AI phải ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.

## Cách làm tranh map dài

ChatGPT không tạo được ảnh rất dài một lần: tạo **nhiều ảnh ngang 1536×1024 nối tiếp** (mỗi ảnh nói rõ "continues
seamlessly from the previous image, same horizon line and lighting"), rồi ghép trong Photoshop thành một dải, co về chiều
cao 1080 px và đúng chiều rộng ghi dưới đây. Làm mờ nhẹ (Gaussian ~6–12 px) để nút ải nổi lên trên nền.

Phong cách chung: *anime 2D background painting, soft painterly, wide panoramic side view, horizon at about 60% height,
no characters, no text, slightly desaturated so UI on top stays readable; the Eclipsed Sun (pale orange sun with a dark
bite missing from one side) appears in the sky.*
"""]
    for aid, (vi, en), chs in ARCS:
        keys["ARC_" + aid.upper()] = (vi, en)
        out["arcs"].append({"id": aid, "title": "ARC_" + aid.upper(), "chapters": chs})
    for num, vi, en, colors, parts, built in CHAPTERS:
        ck = "CHAPTER_%02d_TITLE" % num
        keys[ck] = (vi, en)
        w = map_width(parts)
        ch = {"num": num, "title": ck, "map_image": "map_ch%02d" % num, "card_image": "card_ch%02d" % num,
              "map_width": w, "parts": []}
        x = MARGIN
        idx = 0
        for pi, (pvi, pen, n) in enumerate(parts, 1):
            pk = "PART_%02d_%d_TITLE" % (num, pi)
            keys[pk] = (pvi, pen)
            part = {"id": "ch%02d_p%d" % (num, pi), "title": pk, "x": x - 80, "stages": []}
            for k in range(n):
                idx += 1
                code = "%d-%d" % (num, idx)
                st = {"code": code, "stage_id": built.get(idx, ""), "pos": [x, ROWS_Y[(idx - 1) % len(ROWS_Y)]],
                      "boss": k == n - 1}
                if idx == 1 and num == 1:
                    st["clip"] = True
                if k == n - 1 and pi == len(parts):
                    st["clip"] = True                       # ải cuối chương có truyện kết chương
                part["stages"].append(st)
                if k < n - 1:
                    x += STEP_X
            part["chest_x"] = x + PART_GAP / 2
            x += PART_GAP
            ch["parts"].append(part)
        out["chapters"].append(ch)
        gen_map(os.path.join(ROOT, "assets/placeholders/story/placeholder_map_ch%02d.png" % num), num, w, colors, vi)
        gen_card(os.path.join(ROOT, "assets/placeholders/story/placeholder_card_ch%02d.png" % num), num, colors, vi)
        total = sum(p[2] for p in parts)
        doc.append("""
## Chương %d — %s (%d ải, %d phần)

- **Tranh map:** `assets/story/chapters/map_ch%02d.png` — **%d × %d px** (placeholder `placeholder_map_ch%02d.png`).
  Ghép khoảng %d ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch%02d.png` — **%d × %d px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, %s. Horizon at ~60%% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, %s, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25%% calmer
(the game draws the title there). No text, no logo.
```
""" % (num, vi, total, len(parts), num, w, MAP_H, num, math.ceil(w / 1400), num, CARD[0], CARD[1], SCENES[num], SCENES[num]))
    with io.open(os.path.join(ROOT, "data/story/chapters.json"), "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(out, ensure_ascii=False, indent="\t") + "\n")
    with io.open(os.path.join(ROOT, "docs/prompts/story/CHAPTER_ART.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write("".join(doc))
    for path, i in (("localization/vi.po", 0), ("localization/en.po", 1)):
        full = os.path.join(ROOT, path)
        s = io.open(full, encoding="utf-8").read()
        add = []
        for k, v in keys.items():
            val = esc(v[i])
            pat = re.compile(r'(msgid "%s"\nmsgstr ")[^\n]*(")\n' % re.escape(k))
            if pat.search(s):
                s = pat.sub(lambda m: m.group(1) + val + m.group(2) + "\n", s)
            else:
                add.append('msgid "%s"\nmsgstr "%s"\n' % (k, val))
        if add:
            s = s.rstrip("\n") + "\n\n" + "\n".join(add)
        io.open(full, "w", encoding="utf-8", newline="\n").write(s)
    print("chương:", len(CHAPTERS), "ải:", sum(sum(p[2] for p in c[4]) for c in CHAPTERS), "khóa:", len(keys))


if __name__ == "__main__":
    main()
