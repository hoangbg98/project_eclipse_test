"""Sinh data/stages/stage_01.json — màn đầu (README 15.7: 3–5 phút, 2–3 đợt quái, boss, checkpoint).
Chạy: python -X utf8 tools/gen_stage_01.py   (ghi đè file; sau đó có thể sửa tay file JSON)
Bố cục và số lượng quái do Claude đặt làm khởi điểm; owner chỉnh trong JSON.
"""
import io
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 200, 17
GROUND = 14  # hàng mặt đất (0-based); chân nhân vật đứng trên hàng 13

rows = [["."] * W for _ in range(H)]
for y in range(H):
    rows[y][0] = "#"
    rows[y][W - 1] = "#"
for x in range(W):
    for y in range(GROUND, H):
        rows[y][x] = "#"


def block(x0, x1, top):          # khối đặc từ hàng `top` xuống mặt đất
    for x in range(x0, x1 + 1):
        for y in range(top, GROUND):
            rows[y][x] = "#"


def plat(x0, x1, y):             # platform một chiều
    for x in range(x0, x1 + 1):
        rows[y][x] = "="


def pit(x0, x1):                 # hố
    for x in range(x0, x1 + 1):
        for y in range(GROUND, H):
            rows[y][x] = "."


rows[GROUND - 1][3] = "P"
# Khu A (đợt 1): sân phẳng + hai platform.
plat(18, 22, 10)
plat(30, 34, 9)
# Hố thứ nhất có platform bắc qua, rồi checkpoint.
pit(46, 49)
plat(46, 49, 12)
rows[GROUND - 1][53] = "C"
# Khu B (đợt 2): bậc thang lên xuống.
block(58, 59, 12)
block(60, 61, 11)
plat(70, 75, 9)
plat(82, 86, 10)
pit(98, 100)
rows[GROUND - 1][104] = "C"
# Khu C (đợt 3): sân rộng có bục giữa.
block(122, 125, 12)
plat(114, 118, 9)
plat(130, 134, 9)
pit(142, 144)
rows[GROUND - 1][147] = "C"
# Đấu trường boss: sân phẳng, hai platform để né.
plat(158, 162, 10)
plat(176, 180, 10)

stage = {
    "id": "stage_01",
    "name": "Màn 1 — Thung lũng tro tàn",
    "name_key": "STAGE_01_NAME",
    "description": "Màn đầu: 3 đợt quái, 3 checkpoint, boss 2 pha. Ký hiệu như test_stage + C = checkpoint.",
    "tile_size": 64,
    "legend": {"#": "khối đặc", "=": "platform một chiều", "P": "điểm xuất phát", "C": "checkpoint", ".": "trống"},
    "waves": [
        {"trigger_col": 16, "lock_cols": [8, 44],
         "enemies": [{"id": "enemy_slime_01", "col": 26}, {"id": "enemy_slime_01", "col": 32},
                     {"id": "enemy_slime_01", "col": 38}]},
        {"trigger_col": 68, "lock_cols": [63, 96],
         "enemies": [{"id": "enemy_slime_01", "col": 74}, {"id": "enemy_slime_01", "col": 80},
                     {"id": "enemy_slime_01", "col": 86}, {"id": "enemy_slime_01", "col": 92}]},
        {"trigger_col": 112, "lock_cols": [106, 140],
         "enemies": [{"id": "enemy_slime_01", "col": 116}, {"id": "enemy_slime_01", "col": 120},
                     {"id": "enemy_slime_01", "col": 128}, {"id": "enemy_slime_01", "col": 133},
                     {"id": "enemy_slime_01", "col": 137}]},
    ],
    "boss": {"id": "boss_golem_01", "trigger_col": 156, "lock_cols": [150, 190], "col": 178},
    "rewards": {"gold": 1200, "captain_exp": 400, "exp": 600, "materials": {"mat_exp_small": 4, "mat_enhance_ore": 3}},
    "first_clear_rewards": {"gems": 300, "equipment": ["eq_weapon_iron"], "materials": {"mat_exp_medium": 2}},
    "rows": ["".join(r) for r in rows],
}
out = os.path.join(ROOT, "data", "stages", "stage_01.json")
io.open(out, "w", encoding="utf-8", newline="\n").write(json.dumps(stage, ensure_ascii=False, indent="\t") + "\n")
print("ok", W, H)
