"""Hàm chung sinh màn chơi cốt truyện (data/stages/<id>.json, thoại trong trận, chữ .po).

Dùng trong tools/stages/gen_stage_*.py. Mỗi màn khai báo: kích thước, hố, khối, platform, checkpoint, đợt quái,
goal_col (màn không boss) hoặc boss, thoại (BARKS) và chữ hai ngôn ngữ (TEXT: khóa -> (vi, en)).
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
H = 17
SURFACE = 13          # hàng đứng (ngay trên mặt đất)
GROUND = 14           # 3 hàng đất 14..16
LEGEND = {"#": "khối đặc", "=": "platform một chiều", "P": "điểm xuất phát", "C": "checkpoint", ".": "trống"}


def rows(w, pits, blocks, platforms, spawn, checkpoints, ceiling=()):
    """pits [(đầu, cuối)], blocks [(đầu, cuối, cao)], platforms [(hàng, đầu, cuối)], ceiling [(đầu, cuối, sâu)]."""
    g = [["."] * w for _ in range(H)]
    for y in range(H):
        g[y][0] = g[y][w - 1] = "#"
    for y in range(GROUND, H):
        for x in range(w):
            g[y][x] = "#"
    for a, b in pits:
        for y in range(GROUND, H):
            for x in range(a, b + 1):
                g[y][x] = "."
    for a, b, h in blocks:
        for y in range(GROUND - h, GROUND):
            for x in range(a, b + 1):
                g[y][x] = "#"
    for a, b, d in ceiling:
        for y in range(d):
            for x in range(a, b + 1):
                g[y][x] = "#"
    for r, a, b in platforms:
        for x in range(a, b + 1):
            g[r][x] = "="
    g[SURFACE][spawn] = "P"
    for c in checkpoints:
        g[SURFACE][c] = "C"
    return ["".join(r) for r in g]


def waves(spec):
    return [{"trigger_col": w["trigger_col"], "lock_cols": w["lock_cols"],
             "enemies": [{"id": i, "col": c} for i, c in w["enemies"]]} for w in spec]


def backdrop(stage_id, scrolls=(0.1, 0.3, 0.6)):
    d = "res://assets/backgrounds/stages/%s" % stage_id
    return [{"image": "%s/bg_%s_%s.png" % (d, stage_id, n), "scroll": s} for n, s in zip(("far", "mid", "near"), scrolls)]


def write_json(rel, data):
    with open(os.path.join(ROOT, rel), "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent="\t")
        f.write("\n")


def po_set(path, entries):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    for key, val in entries:
        val = val.replace("\\", "\\\\").replace('"', '\\"')
        pat = re.compile(r'(msgid "%s"\nmsgstr )"(?:[^"\\]|\\.)*"' % re.escape(key))
        if pat.search(text):
            text = pat.sub(lambda m: m.group(1) + '"%s"' % val, text)
        else:
            text = text.rstrip("\n") + '\n\nmsgid "%s"\nmsgstr "%s"\n' % (key, val)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def write_text(text):
    po_set(os.path.join(ROOT, "localization/vi.po"), [(k, v[0]) for k, v in text.items()])
    po_set(os.path.join(ROOT, "localization/en.po"), [(k, v[1]) for k, v in text.items()])


def merge_barks(stage_id, barks):
    """Thêm / ghi đè thoại của màn (theo id), đặt ở cuối nhóm thoại cốt truyện."""
    bp = os.path.join(ROOT, "data/tutorial/battle_barks.json")
    with open(bp, encoding="utf-8") as f:
        data = json.load(f)
    ids = {b["id"] for b in barks}
    lines = [l for l in data["lines"] if l.get("id") not in ids]
    at = max((i for i, l in enumerate(lines) if l.get("kind") == "story"), default=-1) + 1
    new = [dict({"id": b["id"], "kind": "story", "on": b["on"], "stage": stage_id},
                **{k: v for k, v in b.items() if k not in ("id", "on")}) for b in barks]
    data["lines"] = lines[:at] + new + lines[at:]
    with open(bp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent="\t")
        f.write("\n")



# ---------- Dựng màn từ một bảng mô tả (dùng cho gen_stages_01_05_10.py) ----------

def check_layout(s):
    """Tự kiểm tra bố cục; trả về danh sách lỗi (rỗng = ổn)."""
    err = []
    pit_cols = {x for a, b in s["pits"] for x in range(a, b + 1)}

    def arena_ok(lock, what):
        bad = [x for x in range(lock[0], lock[1] + 1) if x in pit_cols]
        if bad:
            err.append("%s: sân khóa %s có hố ở cột %s" % (what, lock, bad[:3]))

    last = -1
    for i, w in enumerate(s["waves"]):
        lock = w["lock_cols"]
        if not (lock[0] < w["trigger_col"] < lock[1]):
            err.append("đợt %d: trigger ngoài sân khóa" % (i + 1))
        if w["trigger_col"] <= last:
            err.append("đợt %d: trigger không tăng dần" % (i + 1))
        last = w["trigger_col"]
        arena_ok(lock, "đợt %d" % (i + 1))
        for _eid, c in w["enemies"]:
            if not (lock[0] < c < lock[1]):
                err.append("đợt %d: quái ở cột %d ngoài sân" % (i + 1, c))
    last_lock = s["waves"][-1]["lock_cols"][1]
    if "boss" in s:
        b = s["boss"]
        arena_ok(b["lock_cols"], "boss")
        if b["trigger_col"] <= last_lock:
            err.append("boss: trigger phải sau sân đợt cuối")
        if not (b["lock_cols"][0] < b["trigger_col"] < b["col"] < b["lock_cols"][1] < s["w"] - 1):
            err.append("boss: vị trí / sân sai")
    elif not (last_lock < s["goal_col"] < s["w"] - 1):
        err.append("goal_col phải sau sân đợt cuối và trước tường")
    for c in s["checkpoints"]:
        if c in pit_cols:
            err.append("checkpoint ở cột %d nằm trên hố" % c)
    return err


def build_stage(s):
    """s: id, code, name_vi, generator, design, w, pits, blocks, platforms, checkpoints, waves, goal_col | boss,
    ceiling?, level, objectives (time, hits), rewards, first_clear, scrolls?, end_clip?"""
    e = check_layout(s)
    assert not e, "%s: %s" % (s["id"], "; ".join(e))
    up = s["id"].upper()
    d = {
        "id": s["id"],
        "name": "Màn %s — %s" % (s["code"], s["name_vi"]),
        "name_key": "%s_NAME" % up,
        "code": s["code"],
        "chapter": int(s["code"].split("-")[0]),
        "description": "Sinh bởi tools/stages/%s. %s" % (s["generator"], s["design"]),
        "desc_key": "%s_DESC" % up,
        "recommended_level": s["level"],
        "objectives": [
            {"id": "time", "type": "time_max", "value": s["objectives"][0], "gold": 300},
            {"id": "hits", "type": "hits_taken_max", "value": s["objectives"][1], "gold": 300},
            {"id": "downs", "type": "downs_max", "value": 0, "gold": 400},
        ],
        "tile_size": 64,
        "legend": LEGEND,
        "backdrop": backdrop(s["id"], s.get("scrolls", (0.1, 0.3, 0.6))),
        "waves": waves(s["waves"]),
    }
    if s.get("end_clip"):
        d["end_clip"] = s["end_clip"]
    if "boss" in s:
        d["boss"] = s["boss"]
    else:
        d["goal_col"] = s["goal_col"]
    d["rewards"] = s["rewards"]
    d["first_clear_rewards"] = s["first_clear"]
    d["rows"] = rows(s["w"], s["pits"], s["blocks"], s["platforms"], s.get("spawn", 3), s["checkpoints"],
                     s.get("ceiling", ()))
    return d


BACKDROP_DOC = """# Ảnh nền màn {code} "{name}" (3 lớp parallax)

> Màn `{id}` (sinh bởi `tools/stages/{generator}`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/{id}.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/{generator}` rồi chạy lại.

## Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/{id}/bg_{id}_far.png` | {s0} | {far_vi} | Không (phủ kín) |
| Giữa | `.../bg_{id}_mid.png` | {s1} | {mid_vi} | Có |
| Gần | `.../bg_{id}_near.png` | {s2} | {near_vi} | Có ({near_alpha}) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**{ceiling_note}.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: {continuity}

## Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. {setting_en} Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level{ceiling_en}, keep it plain.
```

## Lớp xa — `bg_{id}_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. {far_en}
```

## Lớp giữa — `bg_{id}_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). {mid_en}
```

## Lớp gần — `bg_{id}_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, {near_alpha_en} (PNG with alpha). {near_en}
```

## Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn {code} theo docs/prompts/stages/{doc_name}.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: {refs}
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/{id}/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/{id}/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới){ceiling_preview} để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền {code}":
   - chép vào assets/backgrounds/stages/{id}/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\\Godot\\4.6.3\\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage {code}: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

## Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/{id}/`.
2. Chạy `C:\\Godot\\4.6.3\\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải {code} để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.
"""


def write_backdrop_doc(s, art):
    """art: far / mid / near = (vi, en), setting_en, continuity, refs, near_alpha?, near_alpha_en?"""
    ceil = bool(s.get("ceiling"))
    sc = s.get("scrolls", (0.1, 0.3, 0.6))
    doc_name = "STAGE_%s_BACKGROUND.md" % s["id"].replace("stage_", "").upper()
    text = BACKDROP_DOC.format(
        code=s["code"], name=s["name_vi"], id=s["id"], generator=s["generator"], s0=sc[0], s1=sc[1], s2=sc[2],
        far_vi=art["far"][0], mid_vi=art["mid"][0], near_vi=art["near"][0],
        far_en=art["far"][1], mid_en=art["mid"][1], near_en=art["near"][1],
        near_alpha=art.get("near_alpha", "trên ~55% trong suốt"),
        near_alpha_en=art.get("near_alpha_en", "transparent top 55%"),
        ceiling_note=", khoảng **15% trên cùng bị trần đá che**" if ceil else "",
        ceiling_en=" and the top 15% by the rock ceiling" if ceil else "",
        ceiling_preview=" và dải trần (15% trên)" if ceil else "",
        continuity=art["continuity"], setting_en=art["setting_en"], refs=art["refs"], doc_name=doc_name)
    with open(os.path.join(ROOT, "docs/prompts/stages", doc_name), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return doc_name
