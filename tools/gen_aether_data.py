"""Sinh data/characters/char_fire_01.tres và data/skills/char_fire_01/*.tres từ CHARACTER_SKILLS mục 1.

Chạy một lần khi dựng dữ liệu ban đầu: python tools/gen_aether_data.py
CẢNH BÁO: chạy lại sẽ GHI ĐÈ các file .tres (mất chỉnh sửa trong editor). Sau khi sinh, file .tres là nguồn chính.
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILL_DIR = os.path.join(ROOT, "data", "skills", "char_fire_01")

# ResourceComponent.HitKind
NORMAL, HOLD, AIR, LANDING, SKILL, WEAPON, ULTIMATE, SWITCH_IN, NONE = range(9)
ARC, CIRCLE, RECT = range(3)


def fmt(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(float(v)) if isinstance(v, float) else str(v)
    if isinstance(v, tuple):
        return "Vector2(%s, %s)" % (float(v[0]), float(v[1]))
    return '"%s"' % v


def hit(at, dur, ratio, shape=ARC, radius=140, arc=120, tilt=0, rect=(100, 100), offset=(0, -120),
        sc=1.0, knock=0, statuses=(), detached=False, travel=0, tick=0):
    return dict(at_ms=float(at), duration_ms=float(dur), atk_ratio=float(ratio), sc_multiplier=float(sc),
                shape=shape, radius_px=float(radius), arc_deg=float(arc), arc_tilt_deg=float(tilt),
                rect_size=rect, offset=offset, knockback_px=float(knock), statuses=list(statuses),
                detached=detached, travel_px=float(travel), tick_interval_ms=float(tick))


def write_skill(name, skill, hits, source):
    ext = ['[ext_resource type="Script" path="res://scripts/combat/skill_def.gd" id="1"]',
           '[ext_resource type="Script" path="res://scripts/combat/hit_def.gd" id="2"]',
           '[ext_resource type="Script" path="res://scripts/combat/status_application.gd" id="3"]']
    subs, hit_ids = [], []
    for i, h in enumerate(hits):
        st_ids = []
        for j, (sid, dur, mag) in enumerate(h.pop("statuses")):
            st_id = "st_%d_%d" % (i, j)
            st_ids.append(st_id)
            subs.append('[sub_resource type="Resource" id="%s"]\nscript = ExtResource("3")\nstatus_id = "%s"\n'
                        'duration = %s\nmagnitude = %s\n' % (st_id, sid, float(dur), float(mag)))
        hid = "hit_%d" % i
        hit_ids.append(hid)
        body = ['[sub_resource type="Resource" id="%s"]' % hid, 'script = ExtResource("2")']
        body += ["%s = %s" % (k, fmt(v)) for k, v in h.items()]
        body.append('statuses = Array[ExtResource("3")]([%s])' % ", ".join('SubResource("%s")' % s for s in st_ids))
        subs.append("\n".join(body) + "\n")
    lines = ['[gd_resource type="Resource" script_class="SkillDef" load_steps=%d format=3]' % (len(ext) + len(subs) + 1), ""]
    lines += [e for e in ext] + [""]
    lines += subs
    lines += ["[resource]", 'script = ExtResource("1")']
    lines += ["%s = %s" % (k, fmt(v)) for k, v in skill.items()]
    lines.append('hits = Array[ExtResource("2")]([%s])' % ", ".join('SubResource("%s")' % h for h in hit_ids))
    lines.append('metadata/source = "%s"' % source)
    os.makedirs(SKILL_DIR, exist_ok=True)
    with open(os.path.join(SKILL_DIR, name + ".tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


def base(sid, key, anim, kind, s, a, r, **kw):
    d = dict(id="char_fire_01." + sid, key=key, animation=anim, hit_kind=kind,
             startup_ms=float(s), active_ms=float(a), recovery_ms=float(r))
    d.update(kw)
    return d


BURN3 = ("burn", 3.0, -1.0)

# --- Tấn công thường — Hỏa Trảm (4 đòn): cung 120°, 140 px; mỗi đòn tiến 40 px; nối 260 ms, reset 0.8 s ---
write_skill("normal_1", base("normal_1", "normal", "attack_1", NORMAL, 90, 70, 160,
            move_px=40.0, move_from_ms=0.0, move_to_ms=160.0, chain_window_ms=260.0, next_skill="normal_2"),
            [hit(90, 70, 0.70)], "Mục 1 Hỏa Trảm Đ1: 70%, 90/70/160")
write_skill("normal_2", base("normal_2", "normal", "attack_2", NORMAL, 90, 70, 160,
            move_px=40.0, move_from_ms=0.0, move_to_ms=160.0, chain_window_ms=260.0, next_skill="normal_3"),
            [hit(90, 70, 0.75)], "Mục 1 Hỏa Trảm Đ2: 75%, 90/70/160")
write_skill("normal_3", base("normal_3", "normal", "attack_3", NORMAL, 110, 80, 190,
            move_px=40.0, move_from_ms=0.0, move_to_ms=190.0, chain_window_ms=260.0, next_skill="normal_4"),
            [hit(110, 80, 0.85, knock=60)], "Mục 1 Hỏa Trảm Đ3: 85%, đẩy lùi 60 px, 110/80/190")
write_skill("normal_4", base("normal_4", "normal", "attack_4", NORMAL, 160, 120, 320,
            move_px=40.0, move_from_ms=0.0, move_to_ms=280.0),
            [hit(160, 120, 0.85, sc=1.5, statuses=[BURN3]),
             hit(160, 300, 0.40, shape=RECT, rect=(220, 90), offset=(110, -45), sc=1.5, statuses=[BURN3],
                 detached=True, travel=220)],
            "Mục 1 Hỏa Trảm Đ4: kiếm 85% + sóng lửa 40% (220x90 bay 220 px), Cháy 3s, SC x1.5, 160/120/320")

# --- Né tránh — Lướt Lửa: 280 px, bất tử 40-220 ms, vệt lửa 0.8 s gây 25% mỗi 0.4 s ---
write_skill("dodge", base("dodge", "dodge", "dodge", NONE, 40, 180, 120,
            move_px=280.0, move_from_ms=40.0, move_to_ms=220.0, suspend_gravity=True,
            invuln_from_ms=40.0, invuln_to_ms=220.0),
            [hit(40, 800, 0.25, shape=RECT, rect=(280, 60), offset=(140, -30), detached=True, tick=400)],
            "Mục 1 Lướt Lửa: lướt 280 px, bất tử 40-220 ms, vệt lửa 0.8 s x 25% mỗi 0.4 s, 40/180/120")

# --- Nhấn giữ TC — Liệt Hỏa Tích Lực: giữ >= 400 ms nạp (chậm 40%); Cấp 1 tại 700 ms, Cấp 2 tại 1500 ms;
#     CD 1.0 s sau khi nhả; +6 EN nếu trúng (3 theo loại + 3) ---
HOLD_COMMON = dict(cooldown_sec=1.0, cooldown_uses_cdr=False, cooldown_group="hold", extra_en_on_hit=3.0,
                   charge_start_ms=400.0, charge_move_slow=0.4)
write_skill("hold_1", base("hold_1", "hold", "hold_release", HOLD, 120, 100, 340, charge_level_ms=700.0,
            **HOLD_COMMON),
            [hit(120, 100, 1.60, radius=180, sc=1.5)],
            "Mục 1 Liệt Hỏa Tích Lực Cấp 1: hất chém 180 px cung 120°, 160%, khựng, SC x1.5, 120/100/340")
write_skill("hold_2", base("hold_2", "hold", "hold_release", HOLD, 160, 140, 420, charge_level_ms=1500.0,
            super_armor=True, **HOLD_COMMON),
            [hit(160, 400, 2.80, shape=RECT, rect=(320, 140), offset=(160, -70), sc=2.0,
                 statuses=[("burn", 4.0, -1.0)], detached=True, travel=320)],
            "Mục 1 Liệt Hỏa Tích Lực Cấp 2: sóng chém 320x140 bay 320 px, 280%, kháng khựng khi nhả, Cháy 4s, SC x2, 160/140/420")

# --- TC trên không — Phi Trảm (2 đòn): 150 px, cung 140° hơi chếch xuống; tối đa 2 đòn/lần nhảy;
#     treo 150 ms sau đòn 2 ---
write_skill("air_1", base("air_1", "air", "air_1", AIR, 80, 60, 140, keep_momentum=True,
            chain_window_ms=200.0, next_skill="air_2"),
            [hit(80, 60, 0.65, radius=150, arc=140, tilt=20)],
            "Mục 1 Phi Trảm Đ1: 65%, 80/60/140")
write_skill("air_2", base("air_2", "air", "air_2", AIR, 100, 80, 200, keep_momentum=True,
            gravity_off_from_ms=180.0, gravity_off_to_ms=330.0),
            [hit(100, 80, 0.90, radius=150, arc=140, tilt=30, knock=60)],
            "Mục 1 Phi Trảm Đ2: 90%, đẩy xuống 30° (hướng đẩy làm ở M3-6), treo 150 ms sau đòn, 100/80/200")

# --- TC đáp đất — Hỏa Trụy: cần >= 1 đòn trên không và cao >= 200 px; lao 1400 px/s; nổ bán kính 180 ---
write_skill("landing", base("landing", "landing", "landing_attack", LANDING, 0, 120, 280,
            super_armor=True, dive_speed_px=1400.0, min_height_px=200.0, pre_dive_ms=60.0),
            [hit(0, 120, 1.40, shape=CIRCLE, radius=180, offset=(0, -40), sc=1.5, statuses=[("burn", 2.0, -1.0)])],
            "Mục 1 Hỏa Trụy: 140%, nổ bán kính 180, Cháy 2s, SC x1.5; 60 ms treo trước khi lao, rồi 120/280 khi chạm đất")

# --- CharacterDef (chỉ số tạm do Claude đặt; owner chỉnh) ---
char = """[gd_resource type="Resource" script_class="CharacterDef" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/characters/character_def.gd" id="1"]
[ext_resource type="Script" path="res://scripts/characters/combat_stats.gd" id="2"]
[ext_resource type="Resource" path="res://data/config/movement_default.tres" id="3"]

[sub_resource type="Resource" id="stats"]
script = ExtResource("2")
max_hp = 12000.0
atk = 1000.0
def = 500.0
crit_rate = 0.05
crit_damage = 0.5
cdr = 0.0
metadata/source = "Số tạm do Claude đặt (README chưa có chỉ số gốc); owner chỉnh."

[resource]
script = ExtResource("1")
id = "char_fire_01"
name_key = "CHAR_FIRE_01"
element = "fire"
stats = SubResource("stats")
movement = ExtResource("3")
skills_dir = "res://data/skills/char_fire_01"
"""
os.makedirs(os.path.join(ROOT, "data", "characters"), exist_ok=True)
with open(os.path.join(ROOT, "data", "characters", "char_fire_01.tres"), "w", encoding="utf-8", newline="\n") as f:
    f.write(char)
print("ok")
