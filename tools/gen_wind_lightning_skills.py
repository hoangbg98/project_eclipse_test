"""Sinh kỹ năng còn lại (giữ, trên không, đáp đất, Kĩ năng thường, Kĩ năng vũ khí, Tuyệt kỹ) của
Kazeyumi (char_wind_01, CHARACTER_SKILLS mục 2) và Raikiba (char_lightning_01, mục 3).
Đòn thường + né: tools/gen_kael_lyra_data.py. Vào sân: tools/gen_switch_in_data.py.
Chạy: python -X utf8 tools/gen_wind_lightning_skills.py   (ghi đè các file kỹ năng dưới đây + trạng thái storm_blessing)
"""
import io
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skill_data_lib import AIR, CIRCLE, HOLD, LANDING, RECT, SKILL, ULTIMATE, WEAPON, hit, write_skill  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def base(cid, sid, key, anim, kind, s, a, r, **kw):
    d = dict(id="%s.%s" % (cid, sid), key=key, animation=anim, hit_kind=kind,
             startup_ms=float(s), active_ms=float(a), recovery_ms=float(r))
    d.update(kw)
    return d


# ======================= Kazeyumi — Phong · Cung =======================
W = "char_wind_01"
WD = os.path.join(ROOT, "data", "skills", W)
ARROW_SPEED = 1800.0  # px/s, như Phong Tiễn


def arrow(at, ratio, travel, max_targets=1, angle=0.0, statuses=(), knock=0, rect=(70, 24), offset=(50, -150), **extra):
    return hit(at, round(travel / ARROW_SPEED * 1000), ratio, shape=RECT, rect=rect, offset=offset, detached=True,
               travel=travel, statuses=statuses, knock=knock, max_targets=max_targets, travel_angle_deg=float(angle),
               **extra)


# --- Nhấn giữ TC — Xuyên Phong Tiễn: giữ >= 500 ms nạp (chậm 50%); Cấp 1 tại 900 ms xuyên 900 px 180%;
#     Cấp 2 tại 1600 ms xuyên mọi mục tiêu 1200 px 300%, đẩy 120, Chậm 30% 3s; CD 1.2 s sau khi nhả; +6 EN ---
HOLD_W = dict(cooldown_sec=1.2, cooldown_uses_cdr=False, cooldown_group="hold", extra_en_on_hit=3.0,
              charge_start_ms=500.0, charge_move_slow=0.5)
write_skill("hold_1", base(W, "hold_1", "hold", "hold_release", HOLD, 100, 50, 300, charge_level_ms=900.0, **HOLD_W),
            [arrow(100, 1.80, 900, max_targets=0, rect=(90, 28))],
            "Mục 2 Xuyên Phong Tiễn Cấp 1: tên xuyên 900 px 180%, 100/50/300", WD)
write_skill("hold_2", base(W, "hold_2", "hold", "hold_release_2", HOLD, 100, 50, 300, charge_level_ms=1600.0, **HOLD_W),
            [arrow(100, 3.00, 1200, max_targets=0, rect=(120, 40), knock=120, statuses=[("slow", 3.0, 0.30)])],
            "Mục 2 Xuyên Phong Tiễn Cấp 2: xuyên mọi mục tiêu 1200 px 300%, đẩy lùi 120 px, Chậm 30% 3s, 100/50/300", WD)

# --- TC trên không — Thiên Phong Loạt Tiễn: quạt 3 tên chếch xuống 30° (±12°), tầm 600, 45% x3;
#     bật lùi 80 px, lơ lửng 200 ms; tối đa 2 lần mỗi lần nhảy (air_1, air_2 cùng số liệu;
#     animation riêng "air_2", chưa có hình thì game dùng "air_1") ---
for n in (1, 2):
    # Lần 1 nối sang lần 2 nếu bấm trong 200 ms cuối (như Enkiba), không thì lúc rơi bấm TC sẽ ra đáp đất.
    chain = dict(chain_window_ms=200.0, next_skill="air_2") if n == 1 else {}
    write_skill("air_%d" % n, base(W, "air_%d" % n, "air", "air_%d" % n, AIR, 90, 90, 160,
                move_px=-80.0, move_from_ms=90.0, move_to_ms=180.0, gravity_off_from_ms=90.0, gravity_off_to_ms=290.0,
                **chain),
                [arrow(90, 0.45, 600, angle=30 + d, offset=(40, -140)) for d in (-12, 0, 12)],
                "Mục 2 Thiên Phong Loạt Tiễn lần %d: quạt 3 tên chếch xuống 30° ±12°, 45%% x3, tầm 600; bật lùi 80 px, "
                "lơ lửng 200 ms; 90/90/160" % n, WD)

# --- TC đáp đất — Hạ Phong Trận: rơi chậm như thả dù; chạm đất 60% + vùng gió bán kính 160 1.5 s: 20% mỗi 0.5 s x3,
#     kéo nhẹ về tâm, Chậm 35%; không bị khựng khi tiếp đất; 70 / vùng 1500 / 220 ---
write_skill("landing", base(W, "landing", "landing", "landing_attack", LANDING, 0, 80, 220,
            super_armor=True, dive_speed_px=500.0, min_height_px=200.0, pre_dive_ms=70.0),
            [hit(0, 80, 0.60, shape=CIRCLE, radius=160, offset=(0, -40)),
             hit(0, 1500, 0.20, shape=CIRCLE, radius=160, offset=(0, -40), detached=True, tick=500, knock=30,
                 pull_to_origin=True, statuses=[("slow", 0.6, 0.35)])],
            "Mục 2 Hạ Phong Trận: chạm đất 60%, vùng gió bán kính 160 1.5s 20% mỗi 0.5s x3, kéo về tâm, Chậm 35%; "
            "rơi 500 px/s (thả dù, Claude chọn); 70/80/220", WD)

# --- Kĩ năng thường — Phong Vực: 20 EN / 10 s; vùng bán kính 300 cách 400 px phía trước, 6 s, 20% mỗi 0.5 s;
#     kẻ địch Chậm 20%, kéo nhẹ về tâm; người đứng trong vùng +15% tốc độ tấn công, +10% tốc độ di chuyển (WindKit) ---
write_skill("skill", base(W, "skill", "skill", "skill_1", SKILL, 150, 60, 220, en_cost=20.0, cooldown_sec=10.0),
            [hit(150, 6000, 0.20, shape=CIRCLE, radius=300, offset=(400, -60), detached=True, tick=500, knock=20,
                 pull_to_origin=True, statuses=[("slow", 0.6, 0.20), ("wind_domain", 0.6, -1.0)])],
            "Mục 2 Phong Vực: 20 EN, CD 10s, vùng bán kính 300 cách 400 px, 6s, 20% mỗi 0.5s (240%), Chậm 20%, kéo về tâm, "
            "đánh dấu kẻ địch trong vùng (wind_domain); buff người trong vùng do WindKit áp; 150/60/220", WD)

# --- Kĩ năng vũ khí — Liên Châu Phong Tiễn: 35 EN / 13 s; nhảy lùi 150 px rồi 6 tên trong 900 ms, tầm 800, quạt ±8°,
#     60% x6; tên cuối đẩy 100 px, Chậm 30% 2s; 200/900/300 ---
angles = [0, -8, 8, -4, 4, 0]
write_skill("weapon", base(W, "weapon", "weapon", "skill_2", WEAPON, 200, 900, 300, en_cost=35.0, cooldown_sec=13.0,
            move_px=-150.0, move_from_ms=0.0, move_to_ms=200.0),
            [arrow(200 + i * 150, 0.60, 800, angle=angles[i],
                   knock=100 if i == 5 else 0, rect=(100, 36) if i == 5 else (70, 24),
                   statuses=[("slow", 2.0, 0.30)] if i == 5 else [],
                   bonus_vs_status="wind_domain", bonus_vs_status_ratio=0.25) for i in range(6)],
            "Mục 2 Liên Châu Phong Tiễn: 35 EN, CD 13s, lùi 150 px, 6 tên 60% trong 900 ms tầm 800 quạt ±8°, "
            "tên cuối đẩy 100 px + Chậm 30% 2s, +25% nếu mục tiêu trong Phong Vực; 200/900/300", WD)

# --- Tuyệt kỹ — Bão Tiễn Thiên Không: 100 UG, khóa 2 s; bão bán kính 450 quanh Kazeyumi 5 s, 35% mỗi 0.25 s (20 nhịp),
#     kéo vào tâm 150 px/s (37.5 px mỗi nhịp), Chậm 30%; nổ cuối 300%; người dùng +15% sát thương, +20% tốc độ 8 s;
#     loại vùng: bất tử trong khởi động 700 ms rồi chuyển được nhân vật; cut-in 500 ---
ULT_W = 700
write_skill("ultimate", base(W, "ultimate", "ultimate", "ultimate", ULTIMATE, ULT_W, 1000, 400, ug_cost=100.0,
            cooldown_sec=2.0, cooldown_uses_cdr=False, cooldown_starts_on_end=True,
            name_key="SKILL_WIND_01_ULTIMATE", time_stop_ms=500.0, suspend_gravity=True, super_armor=True,
            rise_px=300.0, rise_from_ms=0.0, rise_to_ms=float(ULT_W),
            invuln_from_ms=0.0, invuln_to_ms=float(ULT_W)),
            # Đặt lúc 0 ms (còn ở mặt đất) để tâm bão ở mặt đất dưới chỗ Kazeyumi bay lên; bật sau khởi động.
            [hit(0, 5000, 0.35, shape=CIRCLE, radius=450, offset=(0, -150), detached=True, tick=250, knock=37.5,
                 pull_to_origin=True, statuses=[("slow", 0.5, 0.30)], delay_ms=float(ULT_W)),
             hit(0, 120, 3.00, shape=CIRCLE, radius=450, offset=(0, -150), detached=True, delay_ms=float(ULT_W + 5000))],
            "Mục 2 Bão Tiễn Thiên Không: 100 UG, khóa 2s, bão bán kính 450 5s 35% mỗi 0.25s (700%) kéo 150 px/s, "
            "Chậm 30%, nổ cuối 300%; +15% sát thương +20% tốc độ 8s; cut-in 500 / 700 / 5000 (bão) / 400; "
            "bay lên 300 px trong 700 ms; thân nhân vật 700/1000/400", WD,
            self_statuses=[("storm_blessing", 8.0, 0.15), ("wind_step", 8.0, 0.20)])

# Trạng thái Bão Tiễn (buff sát thương của tuyệt kỹ Kazeyumi).
STATUS = '''[gd_resource type="Resource" script_class="StatusDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/combat/status_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = "storm_blessing"
name_key = "STATUS_STORM_BLESSING"
kind = 1
stacking = 0
max_stacks = 1
default_duration = 8.0
boss_duration_multiplier = 1.0
resist_after_sec = 0.0
tick_interval_sec = 0.0
tick_atk_ratio = 0.0
default_magnitude = 0.15
magnitude_meaning = "damage_dealt_up"
blocks_movement = false
blocks_actions = false
stagger_immune = false
counts_as_elemental = false
on_max_stacks_event = ""
metadata/source = "Mục 2 Kazeyumi Tuyệt kỹ: trong bão 8s +15% sát thương"
'''
with io.open(os.path.join(ROOT, "data", "statuses", "storm_blessing.tres"), "w", encoding="utf-8", newline="\n") as f:
    f.write(STATUS)


def write_status(sid, name_key, kind, duration, magnitude, meaning, source):
    """kind: 0 = bất lợi, 1 = có lợi (StatusDef.Kind)."""
    body = STATUS.replace('id = "storm_blessing"', 'id = "%s"' % sid)
    body = body.replace('name_key = "STATUS_STORM_BLESSING"', 'name_key = "%s"' % name_key)
    body = body.replace("kind = 1", "kind = %d" % kind)
    body = body.replace("default_duration = 8.0", "default_duration = %s" % float(duration))
    body = body.replace("default_magnitude = 0.15", "default_magnitude = %s" % float(magnitude))
    body = body.replace('magnitude_meaning = "damage_dealt_up"', 'magnitude_meaning = "%s"' % meaning)
    body = body.replace('metadata/source = "Mục 2 Kazeyumi Tuyệt kỹ: trong bão 8s +15% sát thương"',
                        'metadata/source = "%s"' % source)
    with io.open(os.path.join(ROOT, "data", "statuses", sid + ".tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write(body)


write_status("fair_wind", "STATUS_FAIR_WIND", 1, 5.0, 0.08, "en_regen_up",
             "Mục 2 Gió Thuận: +8% tốc độ nạp EN 5s")
write_status("fair_wind_haste", "STATUS_FAIR_WIND_HASTE", 1, 5.0, 0.10, "move_speed_up",
             "Mục 2 Gió Thuận: +10% tốc độ di chuyển 5s (tách khỏi wind_step để không gộp mức với né hoàn hảo)")
write_status("wind_domain", "STATUS_WIND_DOMAIN", 0, 0.6, 0.0, "",
             "Mục 2 Phong Vực: dấu kẻ địch đang trong vùng (Liên Châu +25%); làm mới mỗi nhịp 0.5s")
write_status("wind_domain_haste", "STATUS_WIND_DOMAIN_HASTE", 1, 0.3, 0.10, "move_speed_up",
             "Mục 2 Phong Vực: người đứng trong vùng +10% tốc độ di chuyển (WindKit làm mới mỗi tick)")
write_status("overload", "STATUS_OVERLOAD", 1, 8.0, 0.25, "attack_speed_up",
             "Mục 3 Lôi Thần Quyết — Quá Tải 8s: +25% tốc độ tấn công, đòn thường áp Dấu Sét (LightningKit)")

# ======================= Raikiba — Lôi · Song đao =======================
K = "char_lightning_01"
KD = os.path.join(ROOT, "data", "skills", K)
MARK = ("lightning_mark", -1.0, -1.0)

# --- Nhấn giữ TC — Lôi Quang Loạn Vũ: giữ >= 350 ms: lao tới kẻ địch gần nhất trong 300 px, chém 30% mỗi 150 ms,
#     tối đa 8 nhịp (1.2 s); 1 Dấu Sét mỗi 2 nhịp; thả nút dừng sớm; kháng khựng; CD 3 s sau khi kết thúc;
#     150 (lao) / 1200 / 220 ---
write_skill("hold_1", base(K, "hold_1", "hold", "hold_release", HOLD, 150, 1200, 220,
            charge_start_ms=350.0, charge_level_ms=350.0, fire_on_charge=True, release_ends=True,
            cooldown_sec=3.0, cooldown_uses_cdr=False, cooldown_group="hold", cooldown_starts_on_end=True,
            target_range_px=300.0, approach_target=True, approach_max_px=300.0, approach_stop_px=40.0,
            move_from_ms=0.0, move_to_ms=150.0, super_armor=True, extra_en_on_hit=-2.0),
            [hit(150 + i * 150, 60, 0.30, shape=CIRCLE, radius=130, offset=(40, -110),
                 statuses=[MARK] if i % 2 == 1 else []) for i in range(8)],
            "Mục 3 Lôi Quang Loạn Vũ: giữ 350 ms tự kích hoạt, lao tới mục tiêu trong 300 px, 30% mỗi 150 ms x8 (240%), "
            "Dấu Sét mỗi 2 nhịp, thả nút dừng sớm, kháng khựng, CD 3s sau khi kết thúc; 150/1200/220", KD)

# --- TC trên không — Phi Lôi Tam Kích (3 đòn): 120 px, cung 180°; 40/40/70%; mỗi đòn lơ lửng 100 ms; Đ3 Dấu Sét ---
for n, (s, a, r, ratio) in enumerate([(60, 50, 100, 0.40), (60, 50, 100, 0.40), (90, 70, 140, 0.70)], start=1):
    extra = dict(chain_window_ms=150.0, next_skill="air_%d" % (n + 1)) if n < 3 else {}
    write_skill("air_%d" % n, base(K, "air_%d" % n, "air", "air_%d" % n, AIR, s, a, r, keep_momentum=True,
                gravity_off_from_ms=float(s), gravity_off_to_ms=float(s + 100), **extra),
                [hit(s, a, ratio, radius=120, arc=180, statuses=[MARK] if n == 3 else [])],
                "Mục 3 Phi Lôi Tam Kích Đ%d: %d%%, 120 px cung 180°, lơ lửng 100 ms%s, %d/%d/%d" % (
                    n, round(ratio * 100), ", 1 Dấu Sét" if n == 3 else "", s, a, r), KD)

# --- TC đáp đất — Lôi Trụy Thuấn: lao chéo 45° về hướng mặt, nổ bán kính 170 130%, 1 Dấu Sét;
#     vệt điện 1 s Chậm 20% (gộp vào vụ nổ); 50/110/240 ---
write_skill("landing", base(K, "landing", "landing", "landing_attack", LANDING, 0, 110, 240,
            super_armor=True, dive_speed_px=1400.0, min_height_px=200.0, pre_dive_ms=50.0, dive_angle_deg=45.0),
            [hit(0, 110, 1.30, shape=CIRCLE, radius=170, offset=(0, -40), statuses=[MARK, ("slow", 1.0, 0.20)])],
            "Mục 3 Lôi Trụy Thuấn: lao chéo 45° 1400 px/s, nổ bán kính 170 130%, 1 Dấu Sét, Chậm 20% 1s "
            "(vệt điện gộp vào vụ nổ: Claude chọn); 50/110/240", KD)

# --- Kĩ năng thường — Chớp Giật Liên Hoàn: 20 EN / 5 s; lao 350 px rộng 100, 3 nhát x70%, 2 Dấu Sét mỗi nhát;
#     bất tử 100–450 ms; 100/350/200 ---
write_skill("skill", base(K, "skill", "skill", "skill_1", SKILL, 100, 350, 200, en_cost=20.0, cooldown_sec=5.0,
            move_px=350.0, move_from_ms=100.0, move_to_ms=450.0, suspend_gravity=True,
            invuln_from_ms=100.0, invuln_to_ms=450.0),
            [hit(100 + i * 117, 117, 0.70, shape=RECT, rect=(120, 100), offset=(30, -100), statuses=[MARK, MARK])
             for i in range(3)],
            "Mục 3 Chớp Giật Liên Hoàn: 20 EN, CD 5s, lao 350 px rộng 100, 3 nhát 70%, 2 Dấu Sét mỗi nhát, "
            "bất tử 100-450 ms; 100/350/200", KD)

# --- Kĩ năng vũ khí — Song Lôi Phi Nhận: 30 EN / 11 s; hai đao bay vòng hai bên rộng 450 px: đi 400 ms, về 400 ms,
#     mỗi đao mỗi lượt 50% + 1 Dấu Sét; 800 ms không dùng được đòn thường (vẫn di chuyển, né, kỹ năng).
#     Thân nhân vật chỉ giữ tư thế ném 140 + 180 ms để di chuyển được (Claude chọn) ---
BLADE_Y = -100.0
SPREAD = 10.0  # độ lệch lên / xuống của hai đao
blades = []
for sgn in (-1, 1):
    a = sgn * SPREAD
    end = (450 * math.cos(math.radians(a)), BLADE_Y + 450 * math.sin(math.radians(a)))
    blades.append(hit(140, 400, 0.50, shape=RECT, rect=(110, 110), offset=(0, BLADE_Y), detached=True,
                      travel=450, travel_angle_deg=a, statuses=[MARK]))
    # Lượt về: đặt cùng lúc ném (vùng tách chỉ sinh trong thời lượng kỹ năng), bật sau 400 ms tại điểm xa nhất.
    blades.append(hit(140, 400, 0.50, shape=RECT, rect=(110, 110), offset=(round(end[0], 1), round(end[1], 1)),
                      detached=True, travel=-450, travel_angle_deg=a, statuses=[MARK], delay_ms=400.0))
write_skill("weapon", base(K, "weapon", "weapon", "skill_2", WEAPON, 140, 0, 180, en_cost=30.0, cooldown_sec=11.0,
            blocks_normal_ms=800.0),
            blades,
            "Mục 3 Song Lôi Phi Nhận: 30 EN, CD 11s, hai đao bay 450 px đi 400 ms về 400 ms, 50% mỗi đao mỗi lượt "
            "(200%), 1 Dấu Sét mỗi lượt, khóa đòn thường 800 ms; thân 140/0/180 (đao bay độc lập)", KD)

# --- Tuyệt kỹ — Lôi Thần Quyết: 100 UG, khóa 2 s; dịch chuyển tới mục tiêu gần nhất trong 600 px; 8 nhát x80% +
#     sét bán kính 300 450%; mục tiêu có Dấu Sét bị Bùng nổ ngay (+150%); Quá Tải 8 s +25% tốc độ tấn công;
#     cut-in 500 / 300 / 1500 (chuỗi 1100 + sét 400) / 400; loại chuỗi đòn ---
ULT_K = 800
slashes = []
for i in range(8):
    h = hit(ULT_K + round(i * 1100 / 8), 60, 0.80, shape=CIRCLE, radius=160, detached=True, at_target=True)
    if i == 0:
        h.update(bonus_vs_status="lightning_mark", bonus_vs_status_ratio=1.875)  # 80% x (1 + 1.875) = 80% + 150%
    slashes.append(h)
write_skill("ultimate", base(K, "ultimate", "ultimate", "ultimate", ULTIMATE, ULT_K, 1500, 400, ug_cost=100.0,
            cooldown_sec=2.0, cooldown_uses_cdr=False, cooldown_starts_on_end=True, target_range_px=600.0,
            approach_target=True, teleport=True, approach_max_px=600.0, approach_stop_px=60.0,
            name_key="SKILL_LIGHTNING_01_ULTIMATE", time_stop_ms=500.0, suspend_gravity=True, super_armor=True,
            locks_switch=True, invuln_from_ms=0.0, invuln_to_ms=float(ULT_K + 1500)),
            slashes + [hit(ULT_K + 1100, 120, 4.50, shape=CIRCLE, radius=300, detached=True, at_target=True)],
            "Mục 3 Lôi Thần Quyết: 100 UG, khóa 2s, dịch chuyển tới mục tiêu trong 600 px, 8 nhát 80% + sét 450% bán kính 300, "
            "nhát đầu +150% nếu mục tiêu có Dấu Sét; Quá Tải 8s +25% tốc độ tấn công; cut-in 500/300/1500/400", KD,
            self_statuses=[("overload", 8.0, 0.25)])
print("ok")
