"""Sinh toàn bộ kỹ năng của Hikarine (char_light_01, CHARACTER_SKILLS mục 4 + 8.8), Yomigari (char_dark_01, mục 5 + 8.9),
Iwagane (char_earth_01, mục 6 + 8.10): đòn thường, né, giữ, trên không, đáp đất, Kĩ năng thường, Kĩ năng vũ khí,
Tuyệt kỹ, Kĩ năng vào sân; trạng thái mới; config kit; CharacterDef (giữ nguyên chỉ số cũ).
Chạy: python -X utf8 tools/gen_light_dark_earth_skills.py   (ghi đè các file đó)
"""
import io
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skill_data_lib import (AIR, ARC, CIRCLE, HOLD, LANDING, NONE, NORMAL, RECT, SKILL, SWITCH_IN,  # noqa: E402
                            ULTIMATE, WEAPON, heal, hit, write_hitdef_resource, write_skill)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def sdir(cid):
    return os.path.join(ROOT, "data", "skills", cid)


def base(cid, sid, key, anim, kind, s, a, r, **kw):
    d = dict(id="%s.%s" % (cid, sid), key=key, animation=anim, hit_kind=kind,
             startup_ms=float(s), active_ms=float(a), recovery_ms=float(r))
    d.update(kw)
    return d


def chain(n, last, window=200.0, prefix="normal_"):
    return {} if n == last else dict(chain_window_ms=window, next_skill="%s%d" % (prefix, n + 1))


# =============================== Hikarine — Quang · Trượng ===============================
L = "char_light_01"
LD = sdir(L)
ORB_SPEED = 1200.0  # px/s, quả cầu sáng (Claude chọn)


def orb(at, ratio, travel=450, angle=0.0, **extra):
    return hit(at, round(travel / ORB_SPEED * 1000), ratio, shape=CIRCLE, radius=34, offset=(50, -150), detached=True,
               travel=travel, max_targets=1, travel_angle_deg=float(angle), **extra)


# Quang Châm (3 đòn): cầu sáng bay 450 px; đòn 3 tia sáng xuyên 450 px (2 mục tiêu) + hồi 40% ATK cho người % HP thấp nhất
for n, (s, a, r, ratio) in enumerate([(120, 40, 160, 0.50), (120, 40, 160, 0.50), (200, 60, 280, 0.95)], start=1):
    if n < 3:
        write_skill("normal_%d" % n, base(L, "normal_%d" % n, "normal", "attack_%d" % n, NORMAL, s, a, r, **chain(n, 3)),
                    [orb(s, ratio)], "Mục 4 Quang Châm Đ%d: cầu sáng 50%% bay 450 px, %d/%d/%d" % (n, s, a, r), LD)
    else:
        write_skill("normal_3", base(L, "normal_3", "normal", "attack_3", NORMAL, s, a, r),
                    [hit(s, a, ratio, shape=RECT, rect=(450, 44), offset=(225, -150), max_targets=2)],
                    "Mục 4 Quang Châm Đ3: tia sáng xuyên 450 px (2 mục tiêu) 95%, hồi 40% ATK người % HP thấp nhất; 200/60/280",
                    LD, heals=[heal(s, atk=0.40, target="lowest")])

# Quang Bộ: hóa tia sáng dịch 260 px, bất tử 40–180 ms; 40/140/120. (Ảo ảnh khiêu khích: AI quái chưa có khiêu khích.)
write_skill("dodge", base(L, "dodge", "dodge", "dodge", NONE, 40, 140, 120, move_px=260.0, move_from_ms=40.0,
            move_to_ms=40.0, teleport=True, suspend_gravity=True, invuln_from_ms=40.0, invuln_to_ms=180.0), [],
            "Mục 4 Quang Bộ: dịch 260 px, bất tử 40-180 ms, 40/140/120", LD)

# Thánh Quang Cầu Nguyện: giữ >= 400 ms; 8 EN/s tối đa 3 s; vòng 250: mỗi 0.5 s hồi 25% ATK + 1% HP người trong vòng,
# kẻ địch 20% mỗi nhịp; đi chậm 70%; CD 2 s sau khi kết thúc; 150 / 3000 / 220
write_skill("hold_1", base(L, "hold_1", "hold", "hold_charge", HOLD, 150, 3000, 220,
            charge_start_ms=400.0, charge_level_ms=400.0, fire_on_charge=True, release_ends=True, en_per_sec=8.0,
            move_while_active=0.3, cooldown_sec=2.0, cooldown_uses_cdr=False, cooldown_group="hold",
            cooldown_starts_on_end=True),
            [hit(150 + i * 500, 60, 0.20, shape=CIRCLE, radius=250, offset=(0, -100)) for i in range(6)],
            "Mục 4 Thánh Quang Cầu Nguyện: giữ 400 ms, 8 EN/s tối đa 3s, vòng 250, mỗi 0.5s hồi 25% ATK + 1% HP, "
            "kẻ địch 20%; chậm 70%; CD 2s sau khi kết thúc; 150/3000/220", LD,
            heals=[heal(150, atk=0.25, hp=0.01, target="area", radius_px=250, ticks=6, interval=500, follow_caster=True)])

# Thiên Quang Hạ Phúc: 3 tia chéo xuống tầm 400, 45% x3; lơ lửng 300 ms; tối đa 2 lần mỗi lần nhảy; 110/90/180
for n in (1, 2):
    write_skill("air_%d" % n, base(L, "air_%d" % n, "air", "air_1", AIR, 110, 90, 180,
                gravity_off_from_ms=80.0, gravity_off_to_ms=380.0, **chain(n, 2, prefix="air_")),
                [hit(110, 220, 0.45, shape=RECT, rect=(60, 30), offset=(30, -160), detached=True, travel=400,
                     travel_angle_deg=float(a), max_targets=1) for a in (25, 40, 55)],
                "Mục 4 Thiên Quang Hạ Phúc lần %d: 3 tia chéo xuống tầm 400, 45%% x3, lơ lửng 300 ms; 110/90/180" % n, LD)

# Giáng Quang Trụ: cột sáng bán kính 160, 110%, khựng; người trên sân trong 160 px hồi 20% ATK; 70/100/260
write_skill("landing", base(L, "landing", "landing", "landing_attack", LANDING, 0, 100, 260,
            dive_speed_px=1400.0, min_height_px=200.0, pre_dive_ms=70.0),
            [hit(0, 100, 1.10, shape=CIRCLE, radius=160, offset=(0, -60), knock=40)],
            "Mục 4 Giáng Quang Trụ: cột sáng bán kính 160, 110%, khựng, hồi 20% ATK trong 160 px; 70/100/260", LD,
            heals=[heal(0, atk=0.20, target="area", radius_px=160)])

# Thánh Ân Chữa Lành: 25 EN / 9 s; cả đội: ngay 90% ATK + 4% HP, rồi 20% ATK mỗi giây 4 s; % HP thấp nhất x1.3;
# xóa 1 hiệu ứng xấu mỗi người; 200/300/260
write_skill("skill", base(L, "skill", "skill", "skill_1", SKILL, 200, 300, 260, en_cost=25.0, cooldown_sec=9.0), [],
            "Mục 4 Thánh Ân Chữa Lành: 25 EN, CD 9s, cả đội 90% ATK + 4% HP rồi 20% ATK/s x4, thấp nhất x1.3, "
            "xóa 1 hiệu ứng xấu; 200/300/260", LD,
            heals=[heal(200, atk=0.90, hp=0.04, lowest_multiplier=1.3, cleanse=1),
                   heal(200, atk=0.20, ticks=4, interval=1000, delay_ms=1000, lowest_multiplier=1.3)])

# Thái Dương Phán Xét: 35 EN / 12 s; tại mục tiêu gần nhất trong 600 px, rơi trễ 600 ms, bán kính 200, 280% + Phán quyết 6s;
# người trên sân trong vùng hồi 60% ATK; 250 (cast) / 600 / 300
write_skill("weapon", base(L, "weapon", "weapon", "skill_2", WEAPON, 250, 0, 300, en_cost=35.0, cooldown_sec=12.0,
            target_range_px=600.0),
            [hit(250, 120, 2.80, shape=CIRCLE, radius=200, offset=(0, -80), detached=True, at_target=True,
                 delay_ms=600.0, statuses=[("judgment", 6.0, -1.0)])],
            "Mục 4 Thái Dương Phán Xét: 35 EN, CD 12s, mục tiêu trong 600 px, rơi trễ 600 ms, bán kính 200 280%, "
            "Phán quyết 6s, hồi 60% ATK trong vùng; 250/600/300", LD,
            heals=[heal(250, atk=0.60, target="area", radius_px=200, at_target=True, delay_ms=600)])

# Thiên Sứ Giáng Lâm: 100 UG, khóa 2 s; vùng thánh bán kính 500 cố định 8 s: người trong vùng hồi 4% HP mỗi giây,
# −25% sát thương nhận; kẻ địch 25% mỗi 0.5 s (400%), Phán quyết; bay lên 200 px; loại vùng (bất tử 700 ms rồi chuyển được);
# hồi sinh 40% HP (chỉ khi revive_enabled); cut-in 500 / 700 / 8000 / 400
ULT_L = 700
write_skill("ultimate", base(L, "ultimate", "ultimate", "ultimate", ULTIMATE, ULT_L, 300, 400, ug_cost=100.0,
            cooldown_sec=2.0, cooldown_uses_cdr=False, cooldown_starts_on_end=True, name_key="SKILL_LIGHT_01_ULTIMATE",
            time_stop_ms=500.0, suspend_gravity=True, super_armor=True, rise_px=200.0, rise_from_ms=0.0,
            rise_to_ms=float(ULT_L), invuln_from_ms=0.0, invuln_to_ms=float(ULT_L)),
            [hit(0, 8000, 0.25, shape=CIRCLE, radius=500, offset=(0, -100), detached=True, tick=500,
                 delay_ms=float(ULT_L), statuses=[("judgment", 1.0, -1.0)])],
            "Mục 4 Thiên Sứ Giáng Lâm: 100 UG, khóa 2s, vùng 500 8s, hồi 4% HP/s, -25% sát thương nhận, kẻ địch 25%/0.5s "
            "(400%) + Phán quyết, bay lên 200 px, hồi sinh 40% (revive_enabled); cut-in 500/700/8000/400", LD,
            heals=[heal(0, hp=0.04, target="area", radius_px=500, ticks=8, interval=1000, delay_ms=ULT_L,
                        revive_hp_ratio=0.4, ally_statuses=[("sanctuary", 1.1, 0.25)])])

# Quang Giáng Hộ Vệ (8.8): vòng 300 quanh Hikarine; Thường 80% + hồi cả đội 50% ATK + 2% HP; Liên kết 120% + hồi
# 100% ATK + 5% HP (thấp nhất x1.5), xóa 1 hiệu ứng xấu, Khiên 8% (SwitchInDef); 250/150/220, bất tử 0–400
for linked in (False, True):
    sid = "switch_in_linked" if linked else "switch_in"
    write_skill(sid, base(L, sid, "switch_in", "switch_in", SWITCH_IN, 250, 150, 220,
                invuln_from_ms=0.0, invuln_to_ms=400.0),
                [hit(250, 150, 1.20 if linked else 0.80, shape=CIRCLE, radius=300, offset=(0, -80))],
                "Mục 8.8 Quang Giáng Hộ Vệ (%s): vòng 300, %s; 250/150/220, bất tử 0-400" % (
                    "Liên kết" if linked else "Thường",
                    "120%, hồi cả đội 100% ATK + 5% HP (thấp nhất x1.5), xóa 1 hiệu ứng xấu" if linked
                    else "80%, hồi cả đội 50% ATK + 2% HP"), LD,
                heals=[heal(250, atk=1.0, hp=0.05, lowest_multiplier=1.5, cleanse=1) if linked
                       else heal(250, atk=0.5, hp=0.02)])

# =============================== Yomigari — Ám · Lưỡi hái ===============================
D = "char_dark_01"
DD = sdir(D)
CURSE = "curse"

# Ảnh Liêm (4 đòn): 200 px cung 130°; Đ3 xoay vòng 180 đẩy 60; Đ4 kéo kẻ địch trong 200 px vào cách 80 px + Nguyền 2s
normals = [(120, 70, 200, 0.70, hit(120, 70, 0.70, radius=200, arc=130)),
           (120, 70, 200, 0.70, hit(120, 70, 0.70, radius=200, arc=130)),
           (150, 100, 230, 0.90, hit(150, 100, 0.90, shape=CIRCLE, radius=180, offset=(0, -100), knock=60)),
           (190, 120, 340, 1.30, hit(190, 120, 1.30, shape=CIRCLE, radius=200, offset=(80, -100), knock=140,
                                     pull_to_origin=True, statuses=[(CURSE, 2.0, -1.0)]))]
for n, (s, a, r, ratio, h) in enumerate(normals, start=1):
    write_skill("normal_%d" % n, base(D, "normal_%d" % n, "normal", "attack_%d" % n, NORMAL, s, a, r, **chain(n, 4)),
                [h], "Mục 5 Ảnh Liêm Đ%d: %d%%, %d/%d/%d" % (n, round(ratio * 100), s, a, r), DD)

# Ảnh Bộ: hóa bóng 300 px, bất tử 30–270 ms; 30/240/130
write_skill("dodge", base(D, "dodge", "dodge", "dodge", NONE, 30, 240, 130, move_px=300.0, move_from_ms=30.0,
            move_to_ms=270.0, suspend_gravity=True, invuln_from_ms=30.0, invuln_to_ms=270.0), [],
            "Mục 5 Ảnh Bộ: hóa bóng 300 px, bất tử 30-270 ms, 30/240/130", DD)

# Ám Liêm Triệu Hồi: 10 EN; giữ >= 450 ms; xoáy 260 kéo 150 px/s, 28% mỗi 0.3 s tối đa 6 nhịp, Chậm 30%; đi chậm 50%;
# nhả nút / hết nhịp: chém bổ cuối 90% + Nguyền 4s; CD 2.5 s sau khi kết thúc; 180 / 1800 + 100 / 320
write_skill("hold_1", base(D, "hold_1", "hold", "hold_charge", HOLD, 180, 1800, 0, en_cost=10.0,
            charge_start_ms=450.0, charge_level_ms=450.0, fire_on_charge=True, release_ends=True,
            release_skill="hold_finish", move_while_active=0.5, cooldown_sec=2.5, cooldown_uses_cdr=False,
            cooldown_group="hold", cooldown_starts_on_end=True),
            [hit(180 + i * 300, 60, 0.28, shape=CIRCLE, radius=260, offset=(0, -100), knock=45, pull_to_origin=True,
                 statuses=[("slow", 0.5, 0.30)]) for i in range(6)],
            "Mục 5 Ám Liêm Triệu Hồi: 10 EN, giữ 450 ms, xoáy 260 kéo 150 px/s, 28% mỗi 0.3s x6, Chậm 30%, chậm 50%, "
            "CD 2.5s; 180/1800", DD)
write_skill("hold_finish", base(D, "hold_finish", "hold_end", "hold_release", HOLD, 0, 100, 320),
            [hit(0, 100, 0.90, radius=240, arc=150, statuses=[(CURSE, 4.0, -1.0)])],
            "Mục 5 Ám Liêm Triệu Hồi — chém bổ cuối 90% + Nguyền 4s; 0/100/320", DD)

# Huyết Nguyệt Liêm (2 đòn): bán nguyệt 240 px cung 90°; 80% / 100%; Đ2 Nguyền 3s
for n, (s, a, r, ratio) in enumerate([(100, 70, 160, 0.80), (120, 80, 200, 1.00)], start=1):
    write_skill("air_%d" % n, base(D, "air_%d" % n, "air", "air_%d" % n, AIR, s, a, r, keep_momentum=True,
                **chain(n, 2, prefix="air_")),
                [hit(s, a, ratio, radius=240, arc=90, statuses=[(CURSE, 3.0, -1.0)] if n == 2 else [])],
                "Mục 5 Huyết Nguyệt Liêm Đ%d: %d%%, 240 px cung 90°%s, %d/%d/%d" % (
                    n, round(ratio * 100), ", Nguyền 3s" if n == 2 else "", s, a, r), DD)

# Ám Trụy Lực: cắm hái, vùng bóng 180 kéo về tâm, 130%, Nguyền 2s; 70/120/300
write_skill("landing", base(D, "landing", "landing", "landing_attack", LANDING, 0, 120, 300,
            dive_speed_px=1400.0, min_height_px=200.0, pre_dive_ms=70.0),
            [hit(0, 120, 1.30, shape=CIRCLE, radius=180, offset=(0, -50), knock=60, pull_to_origin=True,
                 statuses=[(CURSE, 2.0, -1.0)])],
            "Mục 5 Ám Trụy Lực: bán kính 180 kéo về tâm, 130%, Nguyền 2s; 70/120/300", DD)

# Vực Bóng Nguyền Rủa: 25 EN / 8 s; tại kẻ địch gần nhất trong 450 px, vùng 280 4 s, 25% mỗi 0.5 s (200%),
# Chậm 35%, Nguyền làm mới liên tục, kéo nhẹ; 180 / 4000 / 240
write_skill("skill", base(D, "skill", "skill", "skill_1", SKILL, 180, 60, 240, en_cost=25.0, cooldown_sec=8.0,
            target_range_px=450.0),
            [hit(180, 4000, 0.25, shape=CIRCLE, radius=280, offset=(0, -60), detached=True, at_target=True, tick=500,
                 knock=20, pull_to_origin=True, statuses=[("slow", 0.6, 0.35), (CURSE, 1.0, -1.0)])],
            "Mục 5 Vực Bóng Nguyền Rủa: 25 EN, CD 8s, tại mục tiêu trong 450 px, vùng 280 4s 25%/0.5s (200%), Chậm 35%, "
            "Nguyền liên tục, kéo nhẹ; 180/4000/240", DD)

# Liêm Phá Hồn Trảm: 35 EN / 12 s; ném hái bay 500 px, quay lại sau 0.5 s, 130% mỗi lượt, Trói 1.5s (boss 0.6s),
# hút máu 6% (DarkKit), 1.0 s không dùng được đòn thường; 220 / 1000 / 280 (thân giữ 220 + 280, hái bay độc lập)
write_skill("weapon", base(D, "weapon", "weapon", "skill_2", WEAPON, 220, 0, 280, en_cost=35.0, cooldown_sec=12.0,
            blocks_normal_ms=1000.0),
            [hit(220, 500, 1.30, shape=CIRCLE, radius=90, offset=(0, -110), detached=True, travel=500,
                 statuses=[("root", 1.5, -1.0)]),
             hit(220, 500, 1.30, shape=CIRCLE, radius=90, offset=(500, -110), detached=True, travel=-500,
                 delay_ms=500.0, statuses=[("root", 1.5, -1.0)])],
            "Mục 5 Liêm Phá Hồn Trảm: 35 EN, CD 12s, hái bay 500 px đi + về 130% mỗi lượt (260%), Trói 1.5s, hút máu 6%, "
            "khóa đòn thường 1s; thân 220/0/280", DD)

# Đêm Vĩnh Hằng: 100 UG, khóa 2 s; kéo kẻ địch trong 500 px vào tâm (0.4 s), 6 nhát x100% trong 350 px, nhát cuối 550%
# trong 450 px; Nguyền 8s, hút máu 10%, Thu hoạch (kit), boss +25%; Dạ Vương 8s; loại chuỗi đòn;
# cut-in 500 / 300 / 1900 (kéo 400 + chém 1200 + nhát cuối 300) / 450
ULT_D = 300
slashes = [hit(ULT_D + 400 + i * 200, 80, 1.00, shape=CIRCLE, radius=500 if i == 0 else 350, offset=(0, -110),
               knock=420 if i == 0 else 0, pull_to_origin=i == 0, statuses=[(CURSE, 8.0, -1.0)] if i == 0 else [],
               bonus_vs_status="boss", bonus_vs_status_ratio=0.25) for i in range(6)]
slashes.append(hit(ULT_D + 1600, 150, 5.50, shape=CIRCLE, radius=450, offset=(0, -110),
                   bonus_vs_status="boss", bonus_vs_status_ratio=0.25))
write_skill("ultimate", base(D, "ultimate", "ultimate", "ultimate", ULTIMATE, ULT_D, 1900, 450, ug_cost=100.0,
            cooldown_sec=2.0, cooldown_uses_cdr=False, cooldown_starts_on_end=True, name_key="SKILL_DARK_01_ULTIMATE",
            time_stop_ms=500.0, suspend_gravity=True, super_armor=True, locks_switch=True,
            invuln_from_ms=0.0, invuln_to_ms=float(ULT_D + 1900)),
            slashes,
            "Mục 5 Đêm Vĩnh Hằng: 100 UG, khóa 2s, kéo trong 500 px (gộp vào nhát 1), 6x100% bán kính 350 + 550% bán kính 450, "
            "Nguyền 8s, hút máu 10%, xử tử dưới 20% (boss +25%), Dạ Vương 8s; cut-in 500/300/1900/450", DD,
            self_statuses=[("night_king", 8.0, -1.0)])

# Ảnh Liêm Tập Hậu (8.9): xuất hiện từ bóng kẻ địch gần nhất trong 500 px, chém 180° bán kính 220, kéo kẻ địch trong 260
# vào cách 100 px; Thường 130% Nguyền 3s; Liên kết 180% Nguyền 5s, Trói 1s, hút máu 6% (kit); 220/140/280, bất tử 0–360
for linked in (False, True):
    sid = "switch_in_linked" if linked else "switch_in"
    sts = [(CURSE, 5.0, -1.0), ("root", 1.0, -1.0)] if linked else [(CURSE, 3.0, -1.0)]
    write_skill(sid, base(D, sid, "switch_in", "switch_in", SWITCH_IN, 220, 140, 280, target_range_px=500.0,
                approach_target=True, teleport=True, approach_max_px=500.0, approach_stop_px=60.0,
                invuln_from_ms=0.0, invuln_to_ms=360.0),
                [hit(220, 140, 1.80 if linked else 1.30, shape=CIRCLE, radius=260, offset=(100, -100), knock=160,
                     pull_to_origin=True, statuses=sts)],
                "Mục 8.9 Ảnh Liêm Tập Hậu (%s): %s; 220/140/280, bất tử 0-360" % (
                    "Liên kết" if linked else "Thường",
                    "180%, Nguyền 5s, Trói 1s, hút máu 6%" if linked else "130%, Nguyền 3s"), DD)

# =============================== Iwagane — Địa · Đại kiếm ===============================
E = "char_earth_01"
ED = sdir(E)

# Đại Địa Trảm (3 đòn): 220 px; 100% / 110% / 180% (đòn 3 = kiếm 130% + sóng đá 260x80 bay 260 px 50%: Claude chọn);
# kháng khựng từ đòn 2; SC x1.5, đòn 3 x2; mỗi đòn tiến 30 px
for n, (s, a, r, ratio) in enumerate([(180, 90, 260, 1.00), (180, 90, 260, 1.10), (260, 130, 420, 1.30)], start=1):
    sc = 2.0 if n == 3 else 1.5
    hits = [hit(s, a, ratio, radius=220, arc=130, sc=sc)]
    if n == 3:
        hits.append(hit(s, 300, 0.50, shape=RECT, rect=(260, 80), offset=(130, -40), detached=True, travel=260, sc=sc))
    write_skill("normal_%d" % n, base(E, "normal_%d" % n, "normal", "attack_%d" % n, NORMAL, s, a, r,
                move_px=30.0, move_from_ms=0.0, move_to_ms=float(s), super_armor=n >= 2, **chain(n, 3)),
                hits, "Mục 6 Đại Địa Trảm Đ%d: %d%%, SC x%s%s, %d/%d/%d" % (
                    n, 180 if n == 3 else round(ratio * 100), sc, ", sóng đá 260 px" if n == 3 else "", s, a, r), ED)

# Lăn Giáp: lao vai 180 px; bất tử 50–140 ms, sau đó Giáp cứng tới 340 ms (−50% sát thương nhận, kháng khựng); 50/290/160
write_skill("dodge", base(E, "dodge", "dodge", "dodge", NONE, 50, 290, 160, move_px=180.0, move_from_ms=50.0,
            move_to_ms=200.0, invuln_from_ms=50.0, invuln_to_ms=140.0, super_armor=True), [],
            "Mục 6 Lăn Giáp: lao 180 px, bất tử 50-140 ms, Giáp cứng tới 340 ms; 50/290/160", ED,
            self_statuses=[("hard_armor", 0.34, -1.0)])

# Thủ Thế Đại Địa: 6 EN/s tối đa 2.5 s; giữ >= 300 ms: −70% sát thương (Claude: mọi hướng), kháng khựng, đi chậm 60%;
# nhả: đã chặn >= 1 đòn → chém 170% SC x1.5, chưa → 90%; CD 1.5 s sau khi nhả; dựng 120 / chắn 2500 / nhả 140/90/300
write_skill("hold_1", base(E, "hold_1", "hold", "hold_charge", HOLD, 120, 2500, 0,
            charge_start_ms=300.0, charge_level_ms=300.0, fire_on_charge=True, release_ends=True, en_per_sec=6.0,
            move_while_active=0.4, super_armor=True, cooldown_sec=1.5, cooldown_uses_cdr=False, cooldown_group="hold",
            cooldown_starts_on_end=True), [],
            "Mục 6 Thủ Thế Đại Địa: giữ 300 ms, 6 EN/s tối đa 2.5s, -70% sát thương nhận, kháng khựng, chậm 60%, "
            "CD 1.5s; dựng 120 / chắn 2500", ED, self_statuses=[("guard", 2.7, -1.0)])
for sid, ratio, sc in (("hold_slash", 1.70, 1.5), ("hold_slash_weak", 0.90, 1.0)):
    write_skill(sid, base(E, sid, "hold_end", "hold_release", HOLD, 140, 90, 300),
                [hit(140, 90, ratio, radius=220, arc=150, sc=sc)],
                "Mục 6 Thủ Thế Đại Địa — nhả: chém ngang %d%%%s; 140/90/300" % (
                    round(ratio * 100), " SC x1.5 (đã chặn đòn)" if sc > 1 else " (chưa chặn đòn)"), ED)

# Thiên Trụy Trảm: 1 đòn mỗi lần nhảy; 230 px chéo xuống, 120%, khựng 200 ms, SC x1.5; 140/90/220
write_skill("air_1", base(E, "air_1", "air", "air_1", AIR, 140, 90, 220, keep_momentum=True),
            [hit(140, 90, 1.20, radius=230, arc=120, tilt=35, sc=1.5, knock=30)],
            "Mục 6 Thiên Trụy Trảm: 230 px chéo xuống, 120%, khựng, SC x1.5; 140/90/220", ED)

# Địa Chấn Trụy: bán kính 240 190% + hai sóng đá sang hai bên 220 px 60%; Giáp Địa 2s (−15%), SC x1.5,
# kháng khựng khi tiếp đất; 60/140/380
write_skill("landing", base(E, "landing", "landing", "landing_attack", LANDING, 0, 140, 380, super_armor=True,
            dive_speed_px=1500.0, min_height_px=200.0, pre_dive_ms=60.0),
            [hit(0, 140, 1.90, shape=CIRCLE, radius=240, offset=(0, -60), sc=1.5),
             hit(0, 300, 0.60, shape=RECT, rect=(120, 60), offset=(0, -30), detached=True, travel=220, sc=1.5),
             hit(0, 300, 0.60, shape=RECT, rect=(120, 60), offset=(0, -30), detached=True, travel=-220, sc=1.5)],
            "Mục 6 Địa Chấn Trụy: bán kính 240 190% + 2 sóng 220 px 60%, Giáp Địa 2s -15%, SC x1.5; 60/140/380", ED,
            self_statuses=[("earth_guard", 2.0, 0.15)])

# Khiên Đá Hộ Thể: 25 EN / 10 s; dậm bán kính 200 120%, Chậm 20% 2s; khiêu khích trong 400 px 3s (boss 1.5s);
# Giáp Địa 6s −35% kháng khựng, Khiên 20% HP; 200/120/300
write_skill("skill", base(E, "skill", "skill", "skill_1", SKILL, 200, 120, 300, en_cost=25.0, cooldown_sec=10.0),
            [hit(200, 120, 1.20, shape=CIRCLE, radius=200, offset=(0, -60), statuses=[("slow", 2.0, 0.20)]),
             hit(200, 120, 0.0, shape=CIRCLE, radius=400, offset=(0, -60), statuses=[("taunt", 3.0, -1.0)])],
            "Mục 6 Khiên Đá Hộ Thể: 25 EN, CD 10s, dậm 200 120% Chậm 20% 2s, khiêu khích 400 px 3s, Giáp Địa 6s -35%, "
            "Khiên 20% HP; 200/120/300", ED,
            self_statuses=[("earth_guard", 6.0, 0.35), ("shield", 6.0, 0.20)])

# Thạch Phá Thiên Kích: 40 EN / 14 s; sóng đá thẳng 500 x 120 xuyên, 300%, Phá Giáp −15% DEF 5s, SC x2;
# 5 Cốt Đá: +40% và nổ cuối 130% bán kính 200 (EarthKit); Giáp cứng suốt hiệu lực; 300/500/420
write_skill("weapon", base(E, "weapon", "weapon", "skill_2", WEAPON, 300, 500, 420, en_cost=40.0, cooldown_sec=14.0,
            super_armor=True),
            [hit(300, 500, 3.00, shape=RECT, rect=(500, 120), offset=(250, -60), sc=2.0,
                 statuses=[("armor_break", 5.0, -1.0)])],
            "Mục 6 Thạch Phá Thiên Kích: 40 EN, CD 14s, sóng đá 500x120 xuyên 300%, Phá Giáp -15% DEF 5s, SC x2, "
            "Giáp cứng; 300/500/420", ED, self_statuses=[("hard_armor", 0.8, -1.0)])

# Sơn Băng Địa Liệt: 100 UG, khóa 2 s; nhảy lên 400 px (bất tử) rồi rơi 250 ms; tiếp đất bán kính 500 650% +
# 3 sóng chấn 150%; Choáng 3s (boss theo StatusDef); Thạch Thần 8s (−40% sát thương nhận, +20% ATK); khiêu khích 4s;
# khiên 10% HP; loại chuỗi đòn; cut-in 500 / nhảy 400 / rơi 250 / 1200 / 500
ULT_E = 650
write_skill("ultimate", base(E, "ultimate", "ultimate", "ultimate", ULTIMATE, ULT_E, 1200, 500, ug_cost=100.0,
            cooldown_sec=2.0, cooldown_uses_cdr=False, cooldown_starts_on_end=True, name_key="SKILL_EARTH_01_ULTIMATE",
            time_stop_ms=500.0, gravity_off_from_ms=0.0, gravity_off_to_ms=float(ULT_E), rise_px=400.0,
            rise_from_ms=0.0, rise_to_ms=400.0, fall_ms=250.0, super_armor=True, locks_switch=True,
            invuln_from_ms=0.0, invuln_to_ms=float(ULT_E + 1200)),
            [hit(ULT_E, 120, 6.50, shape=CIRCLE, radius=500, offset=(0, -60), statuses=[("stun", 3.0, -1.0), ("taunt", 4.0, -1.0)])] +
            [hit(ULT_E, 120, 1.50, shape=CIRCLE, radius=500, offset=(0, -60), detached=True, delay_ms=float(300 * (i + 1)))
             for i in range(3)],
            "Mục 6 Sơn Băng Địa Liệt: 100 UG, khóa 2s, nhảy 400 px rơi 250 ms, bán kính 500 650% + 3 sóng 150%, Choáng 3s, "
            "khiêu khích 4s, Thạch Thần 8s, khiên 10%; cut-in 500/400/250/1200/500", ED,
            self_statuses=[("stone_god", 8.0, -1.0), ("shield", 6.0, 0.10)])

# Đại Địa Giáng Thế (8.10): AoE 220; Thường 140% Chậm 20% 2s, +1 Cốt Đá; Liên kết 190% SC x2, +3 Cốt Đá, Giáp Địa 4s −25%,
# khiêu khích 400 px 2s (boss 1s), Khiên 8% (SwitchInDef); 280/140/340, bất tử 0–420
for linked in (False, True):
    sid = "switch_in_linked" if linked else "switch_in"
    hits = [hit(280, 140, 1.90 if linked else 1.40, shape=CIRCLE, radius=220, offset=(0, -60), sc=2.0 if linked else 1.0,
                statuses=[] if linked else [("slow", 2.0, 0.20)])]
    if linked:
        hits.append(hit(280, 140, 0.0, shape=CIRCLE, radius=400, offset=(0, -60), statuses=[("taunt", 2.0, -1.0)]))
    write_skill(sid, base(E, sid, "switch_in", "switch_in", SWITCH_IN, 280, 140, 340, invuln_from_ms=0.0, invuln_to_ms=420.0),
                hits, "Mục 8.10 Đại Địa Giáng Thế (%s): %s; 280/140/340, bất tử 0-420" % (
                    "Liên kết" if linked else "Thường",
                    "190% SC x2, khiêu khích 400 px 2s" if linked else "140%, Chậm 20% 2s"), ED)

# =============================== Trạng thái mới ===============================
STATUS_TEMPLATE = '''[gd_resource type="Resource" script_class="StatusDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/combat/status_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = "{id}"
name_key = "{name_key}"
kind = {kind}
stacking = {stacking}
max_stacks = {max_stacks}
default_duration = {duration}
boss_duration_multiplier = 1.0
resist_after_sec = 0.0
tick_interval_sec = 0.0
tick_atk_ratio = 0.0
default_magnitude = {magnitude}
magnitude_meaning = "{meaning}"
blocks_movement = false
blocks_actions = false
stagger_immune = {stagger_immune}
counts_as_elemental = false
on_max_stacks_event = ""
metadata/source = "{source}"
'''


def status(sid, kind, duration, magnitude, meaning, source, stacking=0, max_stacks=1, stagger_immune=False):
    body = STATUS_TEMPLATE.format(id=sid, name_key="STATUS_" + sid.upper(), kind=kind, stacking=stacking,
                                  max_stacks=max_stacks, duration=float(duration), magnitude=float(magnitude),
                                  meaning=meaning, stagger_immune="true" if stagger_immune else "false", source=source)
    with io.open(os.path.join(ROOT, "data", "statuses", sid + ".tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write(body)


status("sanctuary", 1, 1.1, 0.25, "damage_taken_down", "Mục 4 Thiên Sứ Giáng Lâm: người trong vùng thánh -25% sát thương nhận (làm mới mỗi giây)")
status("night_king", 1, 8.0, 0.0, "", "Mục 5 Đêm Vĩnh Hằng — Dạ Vương 8s: +8% hút máu, +15% sát thương đòn thường (DarkKit)")
status("stone_bone", 1, 8.0, 0.03, "damage_taken_down", "Mục 6 Cốt Đá: tối đa 5 tầng 8s, mỗi tầng -3% sát thương nhận (EarthKit đặt độ lớn theo tầng)",
       stacking=1, max_stacks=5)
status("guard", 1, 2.7, 0.70, "damage_taken_down", "Mục 6 Thủ Thế Đại Địa: -70% sát thương nhận khi chắn (Claude: mọi hướng)", stagger_immune=True)
status("hard_armor", 1, 0.5, 0.50, "damage_taken_down", "Mục 6 Giáp cứng (Lăn Giáp, Thạch Phá Thiên Kích): -50% sát thương nhận, kháng khựng", stagger_immune=True)
status("armor_break", 0, 5.0, 0.15, "def_reduction", "Mục 6 Thạch Phá Thiên Kích — Phá Giáp: -15% DEF 5s")
status("stone_god", 1, 8.0, 0.40, "damage_taken_down", "Mục 6 Sơn Băng Địa Liệt — Thạch Thần 8s: -40% sát thương nhận, +20% ATK (EarthKit)", stagger_immune=True)

# =============================== Config kit ===============================
CHAR = os.path.join(ROOT, "data", "characters")
write_hitdef_resource(os.path.join(CHAR, "char_light_01_kit.tres"), "LightKitConfig",
                      "res://scripts/characters/kits/light_kit_config.gd", [], {},
                      "Mục 4: Ân Huệ Ánh Sáng (khiên từ hồi thừa), rút CD, Hào Quang; số mặc định trong light_kit_config.gd")
write_hitdef_resource(os.path.join(CHAR, "char_dark_01_kit.tres"), "DarkKitConfig",
                      "res://scripts/characters/kits/dark_kit_config.gd", [],
                      {"shadow_clone": hit(0, 100, 1.20, shape=CIRCLE, radius=150, offset=(0, -80), detached=True,
                                           delay_ms=800.0, statuses=[(CURSE, 3.0, -1.0)])},
                      "Mục 5: Khế Ước Bóng, hút máu, Thu hoạch, Dạ Vương, Phân Thân Bóng (nổ sau 0.8s 120% bán kính 150, Nguyền 3s)")
write_hitdef_resource(os.path.join(CHAR, "char_earth_01_kit.tres"), "EarthKitConfig",
                      "res://scripts/characters/kits/earth_kit_config.gd", [],
                      {"bone_burst": hit(0, 120, 1.30, shape=CIRCLE, radius=200, offset=(500, -60), detached=True,
                                         delay_ms=800.0),
                       "block_reflect": hit(0, 100, 1.20, shape=CIRCLE, radius=180, offset=(0, -80), detached=True),
                       "counter_wave": hit(0, 120, 1.00, shape=CIRCLE, radius=160, offset=(0, -40), detached=True)},
                      "Mục 6: Cốt Đá, chặn hoàn hảo (phản 120% bán kính 180), nổ Cốt Đá 130% bán kính 200, Phản Chấn 100% bán kính 160")


# =============================== CharacterDef ===============================
def write_character(cid, kit, normal_statuses, linked_statuses, reduce, source):
    path = os.path.join(CHAR, cid + ".tres")
    old = io.open(path, encoding="utf-8").read()
    stats = re.search(r'\[sub_resource type="Resource" id="stats"\]\n(.*?)\n\n', old, re.S).group(1)
    head = dict(re.findall(r'^(\w+) = (.+)$', old.split("[resource]")[1], re.M))
    ext = ['[ext_resource type="Script" path="res://scripts/characters/character_def.gd" id="1"]',
           '[ext_resource type="Script" path="res://scripts/characters/combat_stats.gd" id="2"]',
           '[ext_resource type="Resource" path="res://data/config/movement_default.tres" id="3"]',
           '[ext_resource type="Script" path="res://scripts/party/switch_in_def.gd" id="si_def"]',
           '[ext_resource type="Script" path="res://scripts/combat/status_application.gd" id="si_st"]',
           '[ext_resource type="Script" path="res://scripts/characters/kits/%s_kit.gd" id="kit_s"]' % kit,
           '[ext_resource type="Resource" path="res://data/characters/%s_kit.tres" id="kit_c"]' % cid]
    subs = ['[sub_resource type="Resource" id="stats"]\n' + stats + "\n"]
    n_ids, l_ids = [], []
    for prefix, lst, ids in (("si_n", normal_statuses, n_ids), ("si_l", linked_statuses, l_ids)):
        for i, (sid, dur, mag) in enumerate(lst):
            rid = "%s_%d" % (prefix, i)
            ids.append(rid)
            subs.append('[sub_resource type="Resource" id="%s"]\nscript = ExtResource("si_st")\nstatus_id = "%s"\n'
                        'duration = %s\nmagnitude = %s\n' % (rid, sid, float(dur), float(mag)))
    si = ['[sub_resource type="Resource" id="switch_in"]', 'script = ExtResource("si_def")',
          'self_statuses_normal = Array[ExtResource("si_st")]([%s])' % ", ".join('SubResource("%s")' % i for i in n_ids),
          'self_statuses_linked = Array[ExtResource("si_st")]([%s])' % ", ".join('SubResource("%s")' % i for i in l_ids),
          'reduce_on = "%s"' % reduce[0], "reduce_sec = %s" % float(reduce[1]),
          "reduce_max_per_cycle_sec = %s" % float(reduce[2]), "reduce_window_sec = %s" % float(reduce[3]),
          "reduce_icd_sec = 0.0", 'metadata/source = "%s"' % source]
    subs.append("\n".join(si) + "\n")
    keep = ["id", "name_key", "element", "rank", "person_id", "suit_key", "weapon_type"]
    res = ["[resource]", 'script = ExtResource("1")'] + ["%s = %s" % (k, head[k]) for k in keep if k in head]
    res += ['stats = SubResource("stats")', 'movement = ExtResource("3")',
            "link_condition = %s" % head["link_condition"], "switch_in_cd_sec = %s" % head["switch_in_cd_sec"],
            'switch_in = SubResource("switch_in")', 'skills_dir = "res://data/skills/%s"' % cid,
            'kit_script = ExtResource("kit_s")', 'kit_config = ExtResource("kit_c")',
            'metadata/source = "Mục 4-6, 8.8-8.10: đủ kỹ năng (tools/gen_light_dark_earth_skills.py)"']
    lines = ['[gd_resource type="Resource" script_class="CharacterDef" load_steps=%d format=3]' % (len(ext) + len(subs) + 1), ""]
    lines += ext + [""] + subs + res
    io.open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")


write_character("char_light_01", "light", [], [("shield", 5.0, 0.08)], ("heal_low_hp", 1.5, 3.0, 6.0),
                "Mục 8.8: Liên kết Khiên 8% 5s; hồi cho người dưới 50% HP trong 6s sau khi vào sân -1.5s (tối đa -3.0s; cửa sổ 6s Claude chọn)")
write_character("char_dark_01", "dark", [], [], ("cursed_kill", 2.0, 4.0, 6.0),
                "Mục 8.9: hạ gục kẻ địch mang Nguyền trong 6s sau khi vào sân -2.0s (tối đa -4.0s)")
write_character("char_earth_01", "earth", [("stone_bone", 8.0, -1.0)],
                [("stone_bone", 8.0, -1.0)] * 3 + [("earth_guard", 4.0, 0.25), ("shield", 6.0, 0.08)],
                ("perfect_block", 2.0, 4.0, 6.0),
                "Mục 8.10: Thường +1 Cốt Đá; Liên kết +3 Cốt Đá, Giáp Địa 4s -25%, Khiên 8% (6s Claude chọn); "
                "chặn hoàn hảo trong 6s sau khi vào sân -2.0s (tối đa -4.0s)")
print("ok")
