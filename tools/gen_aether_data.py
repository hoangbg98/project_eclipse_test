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

# --- Kĩ năng thường — Liệt Diễm Luân: 25 EN / 6 s; bán kính 200; 4 nhịp trong 600 ms: 80% x3 + 110%;
#     Cháy 4s; nhịp cuối đẩy 120 px; kháng khựng; 5 Nhiệt +25% (kit) ---
BURN4 = ("burn", 4.0, -1.0)
write_skill("skill", base("skill", "skill", "skill_1", SKILL, 120, 600, 260, en_cost=25.0, cooldown_sec=6.0,
            super_armor=True),
            [hit(120 + i * 150, 60, 0.80 if i < 3 else 1.10, shape=CIRCLE, radius=200, statuses=[BURN4],
                 knock=120 if i == 3 else 0) for i in range(4)],
            "Mục 1 Liệt Diễm Luân: 25 EN, CD 6s, 4 nhịp 80/80/80/110 trong 600 ms, bán kính 200, Cháy 4s, 120/600/260")

# --- Kĩ năng vũ khí — Thiên Hỏa Nhất Kích: 35 EN / 12 s; lướt xuyên 400 px rộng 100; 220% + Nung chảy -10% DEF 5s;
#     vết chém nổ sau 1.0 s bán kính 140: 130%; bất tử khi lướt; 150/200/360 ---
write_skill("weapon", base("weapon", "weapon", "skill_2", WEAPON, 150, 200, 360, en_cost=35.0, cooldown_sec=12.0,
            move_px=400.0, move_from_ms=150.0, move_to_ms=350.0, suspend_gravity=True,
            invuln_from_ms=150.0, invuln_to_ms=350.0),
            [hit(150, 200, 2.20, shape=RECT, rect=(120, 100), offset=(0, -110), statuses=[("melt", -1.0, -1.0)]),
             dict(hit(150, 120, 1.30, shape=RECT, rect=(400, 280), offset=(200, -120), detached=True), delay_ms=1200.0)],
            "Mục 1 Thiên Hỏa Nhất Kích: 35 EN, CD 12s, lướt 400 px 220% + Nung chảy, vết chém nổ sau 1.0s 130%, 150/200/360")

# --- Tuyệt kỹ — Viêm Hoàng Tuyệt Trảm: 100 UG, khóa 2.0 s; mục tiêu gần nhất trong 500 px;
#     5 nhịp x 120% (bán kính 350) + nổ 500% (bán kính 450); Cháy 6s; Hỏa Hoàng 8s (kit);
#     cut-in 600 (dừng thời gian: M3-7) / 300 / 1400 / 500; bất tử từ cut-in tới hết hiệu lực ---
ULT_START = 900
write_skill("ultimate", base("ultimate", "ultimate", "ultimate", ULTIMATE, ULT_START, 1400, 500, ug_cost=100.0,
            cooldown_sec=2.0, cooldown_uses_cdr=False, cooldown_starts_on_end=True, target_range_px=500.0, name_key="SKILL_FIRE_01_ULTIMATE", time_stop_ms=600.0, suspend_gravity=True,
            super_armor=True, invuln_from_ms=0.0, invuln_to_ms=float(ULT_START + 1400)),
            [dict(hit(ULT_START + i * 250, 80, 1.20, shape=CIRCLE, radius=350, detached=True), at_target=True)
             for i in range(5)] +
            [dict(hit(ULT_START + 1300, 100, 5.00, shape=CIRCLE, radius=450, detached=True,
                      statuses=[("burn", 6.0, -1.0)]), at_target=True)],
            "Mục 1 Viêm Hoàng Tuyệt Trảm: 100 UG, khóa 2s, 5x120% + 500%, Cháy 6s, cut-in 600/300/1400/500")

# --- Kit Aether (nội tại, rút CD, Hơi Nóng, Hỏa Hoàng) ---
wave = hit(0, 300, 0.40, shape=RECT, rect=(220, 90), offset=(110, -45), detached=True, travel=220)
wave.pop("statuses")
kit = ['[gd_resource type="Resource" script_class="FireKitConfig" load_steps=3 format=3]', "",
       '[ext_resource type="Script" path="res://scripts/characters/kits/fire_kit_config.gd" id="1"]',
       '[ext_resource type="Script" path="res://scripts/combat/hit_def.gd" id="2"]', "",
       '[sub_resource type="Resource" id="wave"]', 'script = ExtResource("2")']
kit += ["%s = %s" % (k, fmt(v)) for k, v in wave.items()]
kit += ["", "[resource]", 'script = ExtResource("1")',
        "heat_icd_sec = 0.3", "heat_atk_per_stack = 0.04", "heat_full_bonus = 0.25",
        "heat_full_skill_cd_reduce_sec = 1.0", "heat_full_skill_cd_icd_sec = 6.0",
        "skill_cd_per_hit_sec = 0.2", "skill_cd_max_per_cycle_sec = 2.0",
        "weapon_cd_per_kill_sec = 2.0", "weapon_cd_max_per_cycle_sec = 4.0",
        "ug_bonus_heat_threshold = 3", "ug_bonus_multiplier = 1.2", "hot_breath_burn_sec = 3.0",
        'phoenix_wave = SubResource("wave")',
        'metadata/source = "Mục 1 Aether: nội tại Lửa Bùng Cháy, giảm hồi chiêu, Hơi Nóng, Hỏa Hoàng (sóng lửa = sóng đòn 4, 40%: Claude chọn)"']
with open(os.path.join(ROOT, "data", "characters", "char_fire_01_kit.tres"), "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(kit) + "\n")

# --- CharacterDef (chỉ số tạm do Claude đặt; owner chỉnh) ---
char = """[gd_resource type="Resource" script_class="CharacterDef" load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/characters/character_def.gd" id="1"]
[ext_resource type="Script" path="res://scripts/characters/combat_stats.gd" id="2"]
[ext_resource type="Resource" path="res://data/config/movement_default.tres" id="3"]
[ext_resource type="Script" path="res://scripts/characters/kits/fire_kit.gd" id="4"]
[ext_resource type="Resource" path="res://data/characters/char_fire_01_kit.tres" id="5"]

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
kit_script = ExtResource("4")
kit_config = ExtResource("5")
"""
os.makedirs(os.path.join(ROOT, "data", "characters"), exist_ok=True)
with open(os.path.join(ROOT, "data", "characters", "char_fire_01.tres"), "w", encoding="utf-8", newline="\n") as f:
    f.write(char)
print("ok")
