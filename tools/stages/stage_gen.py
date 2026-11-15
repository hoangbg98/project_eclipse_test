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
