"""Sinh màn 1-2 "Làng Lò Than" (stage_01_02) — owner 2026-11-15 "làm màn 1-2".

Chạy (thư mục gốc dự án):  python -X utf8 -I tools/stages/gen_stage_01_02.py

Sinh / cập nhật:
  data/stages/stage_01_02.json          — bản đồ (ký hiệu như stage_01), 3 đợt quái, 3 checkpoint, không boss: qua màn
                                          khi hạ hết đợt và tới cổng làng (goal_col)
  data/enemies/enemy_slime_02.tres      — Slime tro lớn: chậm, máu dày, cắn nặng, báo hiệu 0.7 s
  data/tutorial/battle_barks.json       — thoại trong trận của màn (id ch01_2_*), thêm / ghi đè theo id
  localization/vi.po, en.po             — STAGE_01_02_*, ENEMY_SLIME_02, BARK_CH01_2_* (thêm mới hoặc ghi đè)

Truyện (owner 2026-11-15): golem ở 1-1 chỉ là thủ vệ bị sai tới chặn đường, Lò Mẹ vẫn lạnh. Dấu kênh lạ của kẻ đeo
mặt nạ (tay sai của một Quản lý dưới trướng thủ lĩnh 00) đi về phía làng Lò Than; Cặn tro tràn xuống làng.
Số cân bằng là số Claude đặt (tự chủ chi tiết nhỏ), chỉnh ở đây rồi chạy lại.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))   # chạy với -I vẫn tìm thấy stage_gen
import stage_gen as sg  # noqa: E402

STAGE_ID = "stage_01_02"
W = 200

PITS = [(30, 33), (62, 66), (112, 115)]                 # cột hố [đầu, cuối]
BLOCKS = [(40, 43, 2), (100, 101, 1), (156, 157, 1)]     # (đầu, cuối, cao)
PLATFORMS = [(10, 20, 24), (11, 63, 65), (9, 54, 58), (10, 84, 88), (9, 134, 138), (10, 176, 180)]  # (hàng, đầu, cuối)
CHECKPOINTS = [48, 106, 150]
SPAWN = 3
GOAL_COL = 195

WAVES = [
    {"trigger_col": 14, "lock_cols": [8, 28], "enemies": [("enemy_slime_01", 19), ("enemy_slime_01", 23),
                                                           ("enemy_slime_01", 26)]},
    {"trigger_col": 74, "lock_cols": [70, 98], "enemies": [("enemy_slime_01", 80), ("enemy_slime_02", 88),
                                                           ("enemy_slime_01", 94)]},
    {"trigger_col": 166, "lock_cols": [161, 192], "enemies": [("enemy_slime_02", 172), ("enemy_slime_01", 178),
                                                              ("enemy_slime_02", 184), ("enemy_slime_01", 189)]},
]

TEXT = {
    "STAGE_01_02_NAME": ("Làng Lò Than", "Coalhearth Village"),
    "STAGE_01_02_DESC": ('Lò Mẹ vẫn lạnh, Cặn tro tràn xuống làng. Dấu kênh lạ của kẻ đeo mặt nạ cũng đi qua đây. Dọn sạch lối và giữ cổng làng Lò Than.',
                         "The Mother Hearth is still cold and ash Dregs are spilling into the village. The masked figure's channel trace passes through here too. Clear the road and hold Coalhearth's gate."),
    "ENEMY_SLIME_02": ("Slime tro lớn", "Big Ash Slime"),
    "BARK_CH01_2_START": ('Dấu kênh lạ đi về phía làng. Cặn tro cũng đang tràn xuống.',
                          'The strange channel trace heads for the village. The ash Dregs are spilling down too.'),
    "BARK_CH01_2_WAVE1": ("Không để con nào tới được làng!", "Not one of them reaches the village!"),
    "BARK_CH01_2_WAVE1_NEO": ("Cặn tro chặn đường. Dọn sạch rồi đi tiếp.", "Ash Dregs ahead. Clear them and move on."),
    "BARK_CH01_2_WAVE2": ("Con to kia là Cặn kết khối. Cắn chậm mà nặng, né rồi đánh trả.",
                          "That big one is clumped Dregs. Slow but heavy bites, dodge, then hit back."),
    "BARK_CH01_2_WAVE2_NEO": ("Cặn tro kết khối. Đòn chậm nhưng nặng, né rồi phản công.",
                              "Clumped Dregs. Slow but heavy, dodge and counter."),
    "BARK_CH01_2_CP2": ('Thấy mái làng rồi! Có khói bếp, vẫn còn người ở đó.',
                        'I can see the roofs! Chimney smoke, people are still there.'),
    "BARK_CH01_2_CP2_NEO": ("Làng Lò Than ở phía trước.", "Coalhearth Village is just ahead."),
    "BARK_CH01_2_WAVE3": ("Đàn cuối ở ngay cổng làng. Dồn hết sức!", "The last pack is right at the gate. Give it everything!"),
    "BARK_CH01_2_CLEAR": ('Làng tạm ổn rồi. Giờ tìm kẻ đã sai golem.',
                          "The village is safe for now. Now let's find whoever sent the golem."),
    "BARK_CH01_2_CLEAR_NEO": ('Cổng làng an toàn. Tiến tới cổng để hoàn tất.',
                              'The gate is safe. Head to it to finish.'),
}

BARKS = [
    {"id": "ch01_2_start", "on": "stage_start", "speaker": "neo", "text": "BARK_CH01_2_START"},
    {"id": "ch01_2_wave1", "on": "wave_started", "arg": 0, "speaker": "char_fire_01", "text": "BARK_CH01_2_WAVE1",
     "neo_text": "BARK_CH01_2_WAVE1_NEO"},
    {"id": "ch01_2_wave2", "on": "wave_started", "arg": 1, "speaker": "char_wind_01", "text": "BARK_CH01_2_WAVE2",
     "neo_text": "BARK_CH01_2_WAVE2_NEO"},
    {"id": "ch01_2_cp2", "on": "checkpoint", "arg": 2, "speaker": "char_lightning_01", "text": "BARK_CH01_2_CP2",
     "neo_text": "BARK_CH01_2_CP2_NEO"},
    {"id": "ch01_2_wave3", "on": "wave_started", "arg": 2, "speaker": "neo", "text": "BARK_CH01_2_WAVE3"},
    {"id": "ch01_2_clear", "on": "wave_cleared", "arg": 2, "speaker": "char_fire_01", "text": "BARK_CH01_2_CLEAR",
     "neo_text": "BARK_CH01_2_CLEAR_NEO"},
]

ENEMY_TRES = """[gd_resource type="Resource" script_class="EnemyDef" load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/enemies/enemy_def.gd" id="1"]
[ext_resource type="Script" path="res://scripts/characters/combat_stats.gd" id="2"]
[ext_resource type="Script" path="res://scripts/combat/skill_def.gd" id="3"]
[ext_resource type="Script" path="res://scripts/combat/hit_def.gd" id="4"]

[sub_resource type="Resource" id="stats"]
script = ExtResource("2")
max_hp = 15000.0
atk = 520.0
def = 360.0
crit_rate = 0.0
crit_damage = 0.5
cdr = 0.0

[sub_resource type="Resource" id="bite"]
script = ExtResource("4")
at_ms = 700.0
duration_ms = 180.0
atk_ratio = 1.4
sc_multiplier = 1.0
shape = 2
rect_size = Vector2(180, 120)
offset = Vector2(100, -60)
knockback_px = 220.0

[sub_resource type="Resource" id="attack"]
script = ExtResource("3")
id = "enemy_slime_02.attack"
key = "attack"
animation = "attack"
hit_kind = 8
startup_ms = 700.0
active_ms = 180.0
recovery_ms = 800.0
move_px = 80.0
move_from_ms = 700.0
move_to_ms = 880.0
hits = Array[ExtResource("4")]([SubResource("bite")])
metadata/source = "Claude đặt (màn 1-2): cắn lao 80 px, báo hiệu 700 ms, 140% ATK, đẩy lùi 220 px"

[resource]
script = ExtResource("1")
id = "enemy_slime_02"
name_key = "ENEMY_SLIME_02"
stats = SubResource("stats")
sc_max = 600.0
sc_decay_delay_sec = 2.5
sc_decay_per_sec = 50.0
move_speed = 110.0
gravity = 2400.0
patrol_radius = 160.0
patrol_pause_sec = 1.0
detect_range = 700.0
lose_range = 1000.0
attack_range = 200.0
attack_cooldown_sec = 2.2
attack = SubResource("attack")
stagger_sec = 0.2
stagger_push_px = 10.0
death_fade_sec = 0.8
placeholder_color = Color(0.58, 0.47, 0.42, 1)
metadata/source = "Claude đặt (màn 1-2): Slime tro lớn HP 15000, ATK 520, DEF 360, SC 600, chậm hơn slime thường"
"""


def stage():
    return {
        "id": STAGE_ID,
        "name": "Màn 1-2 — Làng Lò Than",
        "name_key": "STAGE_01_02_NAME",
        "code": "1-2",
        "chapter": 1,
        "description": "Sinh bởi tools/stages/gen_stage_01_02.py. 3 đợt quái (có Slime tro lớn), 3 checkpoint, không "
                       "boss: hạ hết đợt rồi tới cổng làng (goal_col).",
        "desc_key": "STAGE_01_02_DESC",
        "recommended_level": 6,
        "objectives": [
            {"id": "time", "type": "time_max", "value": 240, "gold": 300},
            {"id": "hits", "type": "hits_taken_max", "value": 20, "gold": 300},
            {"id": "downs", "type": "downs_max", "value": 0, "gold": 400},
        ],
        "tile_size": 64,
        "legend": sg.LEGEND,
        "backdrop": sg.backdrop(STAGE_ID),
        "waves": sg.waves(WAVES),
        "goal_col": GOAL_COL,
        "rewards": {"gold": 1300, "captain_exp": 450, "exp": 650,
                    "materials": {"mat_exp_small": 4, "mat_enhance_ore": 3}},
        "first_clear_rewards": {"gems": 100, "materials": {"mat_exp_medium": 2, "mat_enhance_ore": 2}},
        "rows": sg.rows(W, PITS, BLOCKS, PLATFORMS, SPAWN, CHECKPOINTS),
    }


def main():
    sg.write_json("data/stages/%s.json" % STAGE_ID, stage())
    with open(os.path.join(sg.ROOT, "data/enemies/enemy_slime_02.tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write(ENEMY_TRES)
    sg.merge_barks(STAGE_ID, BARKS)
    sg.write_text(TEXT)
    print("%s: %d hàng × %d cột, %d đợt, %d checkpoint" % (STAGE_ID, sg.H, W, len(WAVES), len(CHECKPOINTS)))


if __name__ == "__main__":
    main()
