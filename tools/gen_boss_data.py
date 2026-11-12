"""Sinh data/enemies/boss_golem_01.tres (BossDef 2 pha) — số khởi điểm do Claude đặt, owner chỉnh trong .tres.
Chạy: python -X utf8 tools/gen_boss_data.py   (ghi đè file)
Mọi đòn có pha khởi động ≥ 400 ms (README 15.7: telegraph ≥ 0.4 s).
"""
import io
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NONE = 8
RECT = 2


def hit(hid, at, dur, ratio, rect, offset, knock=0.0, detached=False, travel=0.0, sc=1.0):
    return ('[sub_resource type="Resource" id="%s"]\nscript = ExtResource("4")\nat_ms = %s\nduration_ms = %s\n'
            'atk_ratio = %s\nsc_multiplier = %s\nshape = %d\nrect_size = Vector2(%s, %s)\noffset = Vector2(%s, %s)\n'
            'knockback_px = %s\ndetached = %s\ntravel_px = %s\n'
            % (hid, float(at), float(dur), ratio, sc, RECT, float(rect[0]), float(rect[1]), float(offset[0]),
               float(offset[1]), float(knock), "true" if detached else "false", float(travel)))


def skill(sid, name, s, a, r, hits, move=0.0, move_from=0.0, move_to=0.0, source=""):
    return ('[sub_resource type="Resource" id="%s"]\nscript = ExtResource("3")\nid = "boss_golem_01.%s"\nkey = "attack"\n'
            'animation = "%s"\nhit_kind = %d\nstartup_ms = %s\nactive_ms = %s\nrecovery_ms = %s\nmove_px = %s\n'
            'move_from_ms = %s\nmove_to_ms = %s\nsuper_armor = true\nhits = Array[ExtResource("4")]([%s])\n'
            'metadata/source = "%s"\n'
            % (sid, name, name, NONE, float(s), float(a), float(r), float(move), float(move_from), float(move_to),
               ", ".join('SubResource("%s")' % h for h in hits), source))


subs = [
    # --- Pha 1 ---
    hit("h_slam", 700, 150, 1.5, (300, 180), (170, -90), knock=220),
    skill("slam", "slam", 700, 150, 700, ["h_slam"], source="Đập đất: báo hiệu 700 ms, 150% ATK, vùng 300x180 trước mặt, đẩy lùi 220 px"),
    hit("h_charge", 600, 400, 1.2, (200, 220), (60, -110), knock=260),
    skill("charge", "charge", 600, 400, 800, ["h_charge"], move=420.0, move_from=600.0, move_to=1000.0,
          source="Húc: báo hiệu 600 ms, lao 420 px trong 400 ms, 120% ATK, đẩy lùi 260 px"),
    # --- Pha 2 ---
    hit("h_quake_f", 800, 600, 1.3, (160, 90), (120, -45), knock=160, detached=True, travel=600),
    hit("h_quake_b", 800, 600, 1.3, (160, 90), (-120, -45), knock=160, detached=True, travel=-600),
    skill("quake", "quake", 800, 200, 700, ["h_quake_f", "h_quake_b"],
          source="Địa chấn: báo hiệu 800 ms, hai sóng đất chạy hai phía 600 px, 130% ATK mỗi sóng"),
    hit("h_slam2", 450, 150, 1.6, (320, 190), (175, -95), knock=240),
    skill("slam_fast", "slam", 450, 150, 550, ["h_slam2"], source="Đập đất nhanh (pha 2): báo hiệu 450 ms, 160% ATK"),
    hit("h_charge2", 500, 400, 1.3, (200, 220), (60, -110), knock=280),
    skill("charge_fast", "charge", 500, 400, 650, ["h_charge2"], move=480.0, move_from=500.0, move_to=900.0,
          source="Húc nhanh (pha 2): báo hiệu 500 ms, lao 480 px, 130% ATK"),
    ('[sub_resource type="Resource" id="stats"]\nscript = ExtResource("2")\nmax_hp = 60000.0\natk = 600.0\ndef = 400.0\n'
     'crit_rate = 0.0\ncrit_damage = 0.5\ncdr = 0.0\n'),
    ('[sub_resource type="Resource" id="phase1"]\nscript = ExtResource("5")\nhp_ratio_below = 1.0\n'
     'attacks = Array[ExtResource("3")]([SubResource("slam"), SubResource("charge")])\nattack_cooldown_sec = 1.8\n'
     'attack_range = 280.0\nmove_speed_multiplier = 1.0\n'),
    ('[sub_resource type="Resource" id="phase2"]\nscript = ExtResource("5")\nhp_ratio_below = 0.5\n'
     'attacks = Array[ExtResource("3")]([SubResource("quake"), SubResource("slam_fast"), SubResource("charge_fast")])\n'
     'attack_cooldown_sec = 1.1\nattack_range = 300.0\nmove_speed_multiplier = 1.35\n'),
]
head = ['[gd_resource type="Resource" script_class="BossDef" load_steps=%d format=3]' % (len(subs) + 6), "",
        '[ext_resource type="Script" path="res://scripts/enemies/boss_def.gd" id="1"]',
        '[ext_resource type="Script" path="res://scripts/characters/combat_stats.gd" id="2"]',
        '[ext_resource type="Script" path="res://scripts/combat/skill_def.gd" id="3"]',
        '[ext_resource type="Script" path="res://scripts/combat/hit_def.gd" id="4"]',
        '[ext_resource type="Script" path="res://scripts/enemies/boss_phase_def.gd" id="5"]', ""]
tail = ["[resource]", 'script = ExtResource("1")', 'id = "boss_golem_01"', 'name_key = "BOSS_GOLEM_01"',
        'stats = SubResource("stats")', "sc_max = 1000.0", "sc_decay_delay_sec = 3.0", "sc_decay_per_sec = 60.0",
        "move_speed = 130.0", "gravity = 2400.0", "patrol_radius = 0.0", "patrol_pause_sec = 0.5",
        "detect_range = 2000.0", "lose_range = 4000.0", "attack_range = 280.0", "attack_cooldown_sec = 1.8",
        "stagger_sec = 0.0", "stagger_push_px = 0.0", "death_fade_sec = 1.2",
        "placeholder_color = Color(0.62, 0.5, 0.36, 1)",
        'phases = Array[ExtResource("5")]([SubResource("phase1"), SubResource("phase2")])',
        "phase_transition_sec = 1.2",
        'metadata/source = "Boss màn đầu (placeholder do Claude đặt): HP 60000, ATK 600, DEF 400, SC 1000; pha 2 khi HP <= 50%"']
out = os.path.join(ROOT, "data", "enemies", "boss_golem_01.tres")
io.open(out, "w", encoding="utf-8", newline="\n").write("\n".join(head) + "\n" + "\n".join(subs) + "\n" + "\n".join(tail) + "\n")
print("ok")
