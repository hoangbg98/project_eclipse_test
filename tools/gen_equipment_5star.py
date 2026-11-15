"""Sinh dữ liệu trang bị 5★ (docs/design/EQUIPMENT_5STAR.md) + hiệu ứng bộ 4★ + khóa dịch.
Chạy: python -X utf8 tools/gen_equipment_5star.py
Ghi: data/equipment/eq_weapon_<5★>.tres, eq_stigma_{top,mid,bot}_<bộ>.tres, data/equipment/sets/*.tres,
thêm set_id vào vết thánh 4★ blaze / bedrock, thêm khóa EQUIP_* / SET_* vào localization (không sửa khóa đã có).

Mỗi hiệu ứng là một dòng của tài liệu. Dòng chưa cài được (buff có thời hạn, đổi cơ chế kit) ghi kind PENDING
kèm mô tả để không mất thiết kế; test liệt kê chúng (tests/unit/progression/test_equipment_effects.gd).
Chỉ số cộng thẳng (ATK, HP...) của đồ 5★ là số khởi điểm Claude đặt; owner chỉnh trong .tres.
"""
import io
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = "EQUIPMENT_5STAR.md (owner 2026-11-14). Chỉ số cộng thẳng: số khởi điểm Claude đặt; owner chỉnh."
STAT, PARAM, VS, HIT, PENDING = 0, 1, 2, 3, 4


# ---------- Bộ dựng hiệu ứng ----------
def S(stat, v, note, req="", team=""):
    return dict(kind=STAT, stat=stat, value=v, note=note, requires_element=req, team=bool(team), effect_id=team)


def P(param, v, note, req=""):
    return dict(kind=PARAM, param=param, value=v, note=note, requires_element=req)


def V(cond, v, note, req=""):
    return dict(kind=VS, condition=cond, value=v, note=note, requires_element=req)


def H(status, dur, note, mag=-1.0, req=""):
    return dict(kind=HIT, status_id=status, value=dur, magnitude=mag, note=note, requires_element=req)


def N(note, req=""):
    return dict(kind=PENDING, note=note, requires_element=req)


def X(*effects):
    """Đánh dấu độc quyền."""
    return [dict(e, exclusive=True) for e in effects]


TRIGGER = 5
# Buff trạng thái của hiệu ứng theo sự kiện: id → (magnitude_meaning, vs_status, vi, en). Sinh data/statuses/eqb_*.tres.
BUFFS = {}


def B(sid, meaning, vi, en, vs=""):
    BUFFS[sid] = (meaning, vs, vi, en)
    return sid


def T(trigger, action, note, value=0.0, mag=-1.0, status="", team=False, element="", icd=0.0, arg="",
      tval=0.0, window=0.0, cd_keys=(), cap=-1.0, req=""):
    return dict(kind=TRIGGER, trigger=trigger, action=action, note=note, value=value, magnitude=mag, status_id=status,
                team=team, target_element=element, icd=icd, trigger_arg=arg, trigger_value=tval,
                trigger_window=window, cd_keys=list(cd_keys), cap=cap, requires_element=req)


DMG, ASPD, MSPD, ENR, TAKEN, DEFUP = ("damage_dealt_up", "attack_speed_up", "move_speed_up", "en_regen_up",
                                       "damage_taken_down", "def_up")

# ---------- Vũ khí 5★ (mục 1) ----------
# id, owner, element, weapon_type, vi, en, (atk, hp, def, crit_rate, crit_dmg), common, exclusive
WEAPONS = [
    ("eq_weapon_dusk_inferno", "char_fire_01", "fire", "sword", "Hoàng Hôn Thiêu Rụi", "Dusk Inferno",
     (230.0, 0.0, 0.0, 0.06, 0.0),
     [S("elem_dmg", 0.15, "Cộng hưởng: người đeo hệ Hỏa +15% ST Hỏa", "fire"),
      S("all_dmg", 0.08, "Người đeo +8% tất cả ST"),
      V("burn", 0.08, "Kẻ địch đang Cháy chịu +8% ST Hỏa từ người đeo", "fire"),
      H("burn", 3.0, "Kĩ năng vũ khí áp Cháy 3s lên mục tiêu trúng", req="fire"),
      T("ultimate_used", "buff", "Dùng Tuyệt kỹ: người đeo +6% tất cả ST trong 6s", value=6.0, mag=0.06,
        status=B("eqb_dusk_ult", DMG, "Hoàng Hôn: +ST", "Dusk: DMG up"))],
     X(S("all_dmg", 0.08, "Toàn đội +8% tất cả ST", team="fire_wpn_team_dmg"),
       T("while_self_stacks", "buff", "+8% tất cả ST nữa (toàn đội) khi Enkiba có ≥ 3 Nhiệt", mag=0.08, team=True,
         arg="heat", tval=3, status=B("eqb_dusk_heat_team", DMG, "Hoàng Hôn: Nhiệt +ST", "Dusk: Heat DMG up")),
       V("stun", 0.15, "Kẻ địch đang Choáng chịu +15% tất cả ST từ Enkiba"),
       P("skill:weapon:cooldown_sec", -2.0, "CD Kĩ năng vũ khí 12.0s → 10.0s"),
       P("status_mag:melt", 0.05, "Nung chảy −10% → −15% DEF"),
       P("kit:heat_full_consume", 3.0, "Bonus +25% của Kĩ năng vũ khí vẫn cần 5 Nhiệt, chỉ tiêu 3 tầng (giữ lại 2)"),
       T("weapon_hit", "buff", "Kĩ năng vũ khí trúng: toàn đội +10% ST Hỏa 8s (ICD 10s, làm mới)", value=8.0,
         mag=0.10, team=True, element="fire", icd=10.0,
         status=B("eqb_dusk_fire_team", DMG, "Hoàng Hôn: +ST Hỏa", "Dusk: Fire DMG up")),
       P("status_dur:phoenix", 2.0, "Hỏa Hoàng 8s → 10s"))),
    ("eq_weapon_last_gale", "char_wind_01", "wind", "bow", "Hơi Thở Cuối Mùa Gió", "Last Breath of the Gale",
     (215.0, 0.0, 0.0, 0.05, 0.0),
     [S("elem_dmg", 0.15, "Cộng hưởng: người đeo hệ Phong +15% ST Phong", "wind"),
      S("move_speed", 0.08, "Người đeo +8% tốc độ di chuyển"),
      S("all_dmg", 0.06, "Người đeo +6% tất cả ST"),
      V("slow", 0.08, "Kẻ địch đang Chậm chịu +8% ST từ người đeo"),
      H("slow", 2.0, "Kĩ năng vũ khí thêm Chậm 20% trong 2s", mag=0.2),
      T("distinct_targets", "buff", "Bắn trúng 2 kẻ địch khác nhau trong 4s: +8% tốc độ di chuyển 4s", value=4.0,
        mag=0.08, tval=2, window=4.0, status=B("eqb_gale_move", MSPD, "Mùa Gió: +tốc độ", "Gale: move speed"))],
     X(S("en_regen", 0.06, "Toàn đội +6% tốc độ nạp EN", team="wind_wpn_team_en"),
       V("wind_domain", 0.12, "Kẻ địch trong Phong Vực chịu +12% ST từ Kazeyumi"),
       P("skill:weapon:cooldown_sec", -2.0, "CD Kĩ năng vũ khí 13.0s → 11.0s"),
       P("skill:weapon:hits.bonus_vs_status_ratio", 0.10, "Bonus mục tiêu đứng trong Phong Vực +25% → +35%"),
       T("perfect_dodge", "cd", "Né hoàn hảo: Kĩ năng vũ khí giảm 3.0s CD (ICD 8s)", value=3.0, icd=8.0,
         cd_keys=["weapon"]),
       P("kit:zone_ally_damage", 0.10, "Đồng đội trong Phong Vực +10% ST nguyên tố"))),
    ("eq_weapon_twin_thunder", "char_lightning_01", "lightning", "dual_blades", "Hai Tiếng Sấm", "Twin Thunderclaps",
     (220.0, 0.0, 0.0, 0.0, 0.15),
     [S("elem_dmg", 0.15, "Cộng hưởng: người đeo hệ Lôi +15% ST Lôi", "lightning"),
      S("atk_speed", 0.08, "Người đeo +8% tốc độ tấn công"),
      S("all_dmg", 0.06, "Người đeo +6% tất cả ST"),
      V("elemental", 0.08, "Kẻ địch đang mang hiệu ứng nguyên tố chịu +8% tất cả ST từ người đeo"),
      H("lightning_mark", 6.0, "Kĩ năng vũ khí thêm 1 Dấu Sét lên mục tiêu trúng", req="lightning"),
      T("elemental_applied", "buff", "Gây hiệu ứng nguyên tố: người đeo +6% tốc độ nạp EN trong 4s (ICD 4s)",
        value=4.0, mag=0.06, icd=4.0, status=B("eqb_thunder_en", ENR, "Hai Tiếng Sấm: +nạp EN", "Thunder: EN regen"))],
     X(T("lightning_burst", "buff", "Sau mỗi Bùng nổ Sét: toàn đội +8% tốc độ tấn công 6s (làm mới, ICD 4s)",
         value=6.0, mag=0.08, team=True, icd=4.0,
         status=B("eqb_thunder_aspd_team", ASPD, "Hai Tiếng Sấm: +tốc độ tấn công", "Thunder: attack speed")),
       P("kit:burst.atk_ratio", 0.40, "Bùng nổ Sét +40% ST (150% → 190% ATK)"),
       P("skill:weapon:cooldown_sec", -2.0, "CD Kĩ năng vũ khí 11.0s → 9.0s"),
       H("lightning_mark", 6.0, "Kĩ năng vũ khí áp 2 Dấu Sét mỗi lượt đao thay vì 1 (thêm 1 Dấu Sét)"),
       P("skill:weapon:blocks_normal_ms", -300.0, "Khóa đòn thường sau Kĩ năng vũ khí 800 ms → 500 ms"),
       T("lightning_burst", "en", "Mỗi Bùng nổ Sét hồi 8 EN cho Raikiba (ICD 4s)", value=8.0, icd=4.0))),
    ("eq_weapon_solar_verdict", "char_light_01", "light", "staff", "Nhật Miện Phán Quyết", "Solar Crown Verdict",
     (200.0, 1200.0, 0.0, 0.0, 0.0),
     [S("elem_dmg", 0.15, "Cộng hưởng: người đeo hệ Quang +15% ST Quang", "light"),
      S("heal_bonus", 0.10, "Người đeo +10% hiệu quả hồi máu"),
      V("judgment", 0.06, "Kẻ địch có Phán quyết chịu +6% ST từ người đeo", "light"),
      T("weapon_hit", "heal_team", "Kĩ năng vũ khí hồi cho toàn đội 3% HP tối đa nếu trúng ít nhất 1 kẻ địch",
        value=0.03),
      T("heal_low", "buff", "Hồi máu cho đồng đội dưới 50% HP: người đeo +6% ST 5s (ICD 8s)", value=5.0,
        mag=0.06, icd=8.0, status=B("eqb_verdict_heal", DMG, "Nhật Miện: +ST", "Verdict: DMG up"))],
     X(S("heal_bonus", 0.08, "Toàn đội +8% hiệu quả hồi máu", team="light_wpn_team_heal"),
       P("status_mag:judgment", 0.04, "Phán quyết từ Hikarine +8% → +12% ST nhận"),
       P("skill:weapon:cooldown_sec", -2.0, "CD Kĩ năng vũ khí 12.0s → 10.0s"),
       P("skill:weapon:heals.atk_ratio", 0.30, "Hồi đồng đội trong vùng 60% → 90% ATK"),
       T("weapon_used", "buff", "Đồng đội trong vùng +10% tất cả ST trong 6s (làm mới). Cách làm: người trên sân",
         value=6.0, mag=0.10, team=True,
         status=B("eqb_verdict_zone_team", DMG, "Nhật Miện: vùng +ST", "Verdict: zone DMG up")),
       P("kit:shield_max_ratio", 0.04, "Khiên từ hồi thừa tối đa 8% → 12% HP tối đa"))),
    ("eq_weapon_crescent_pact", "char_dark_01", "dark", "scythe", "Liềm Khế Ước Trăng Khuyết", "Crescent Pact Scythe",
     (225.0, 0.0, 0.0, 0.0, 0.15),
     [S("elem_dmg", 0.15, "Cộng hưởng: người đeo hệ Ám +15% ST Ám", "dark"),
      S("all_dmg", 0.08, "Người đeo +8% tất cả ST"),
      S("lifesteal", 0.04, "Người đeo +4% hút máu"),
      T("kill", "heal_self", "Hạ gục kẻ địch: người đeo hồi 2% HP tối đa (ICD 2s)", value=0.02, icd=2.0),
      H("root", 0.8, "Kĩ năng vũ khí Trói 0.8s (boss 0.3s)"),
      V("low_hp", 0.08, "Kẻ địch dưới 30% HP chịu +8% ST từ người đeo")],
     X(S("lifesteal_curse", 0.06, "Toàn đội +6% hút máu khi đánh kẻ địch đang Nguyền", team="dark_wpn_team_curse_ls"),
       T("kill", "cd", "Hạ gục kẻ địch giảm 1.5s CD Kĩ năng thường và Kĩ năng vũ khí (ICD 1.0s)", value=1.5,
         icd=1.0, cd_keys=["skill", "weapon"]),
       P("skill:weapon:cooldown_sec", -2.0, "CD Kĩ năng vũ khí 12.0s → 10.0s"),
       P("status_mag:curse", 0.05, "Nguyền từ Yomigari −15% → −20% DEF"),
       P("kit:skill_lifesteal.weapon", 0.04, "Hút máu Kĩ năng vũ khí 6% → 10%"),
       T("kill_cursed", "buff", "Hạ gục kẻ địch đang Nguyền: toàn đội +8% ST lên mục tiêu Nguyền trong 6s",
         value=6.0, mag=0.08, team=True,
         status=B("eqb_crescent_curse_team", DMG, "Trăng Khuyết: +ST lên Nguyền", "Crescent: DMG vs Curse",
                  vs="curse")))),
    ("eq_weapon_unyielding_peak", "char_earth_01", "earth", "greatsword", "Cốt Sơn Bất Khuất", "Unyielding Mountain Bone",
     (235.0, 0.0, 100.0, 0.0, 0.0),
     [S("elem_dmg", 0.15, "Cộng hưởng: người đeo hệ Địa +15% ST Địa", "earth"),
      S("all_dmg", 0.08, "Người đeo +8% tất cả ST"),
      S("dmg_taken_down", 0.06, "Người đeo giảm 6% ST nhận"),
      V("def_down", 0.08, "Kẻ địch đang bị giảm DEF chịu +8% ST từ người đeo"),
      T("during_skill", "buff", "Kĩ năng vũ khí: giảm 20% ST nhận trong lúc dùng", mag=0.20, arg="weapon",
        status=B("eqb_peak_guard", TAKEN, "Cốt Sơn: giảm ST nhận", "Peak: guard")),
      T("damaged", "buff", "Nhận ST: người đeo +4% DEF trong 5s (ICD 2s)", value=5.0, mag=0.04, icd=2.0,
        status=B("eqb_peak_def", DEFUP, "Cốt Sơn: +DEF", "Peak: DEF up"))],
     X(T("weapon_used", "buff", "Toàn đội giảm 6% ST nhận trong 6s sau khi Iwagane dùng Kĩ năng vũ khí (ICD 10s)",
         value=6.0, mag=0.06, team=True, icd=10.0,
         status=B("eqb_peak_team_guard", TAKEN, "Cốt Sơn: đội giảm ST nhận", "Peak: team guard")),
       V("armor_break", 0.12, "Kẻ địch mang Phá Giáp chịu +12% ST từ Iwagane"),
       P("skill:weapon:cooldown_sec", -2.0, "CD Kĩ năng vũ khí 14.0s → 12.0s"),
       P("kit:full_bones", -1.0, "Bonus Cốt Đá của Kĩ năng vũ khí kích hoạt ở 4 tầng thay vì 5"),
       P("status_mag:armor_break", 0.05, "Phá Giáp −15% → −20% DEF"),
       P("kit:bone_burst.atk_ratio", 0.5, "Nổ cuối 130% → 180% ATK"),
       P("kit:bone_damage_reduction", 0.005, "Mỗi tầng Cốt Đá giảm 3% → 3.5% ST nhận"))),
]

# ---------- Bộ vết thánh 5★ (mục 2) ----------
# set key, owner, element, vi, en, pieces[(vi, en, common, exclusive) × 3], bonus_2, bonus_3
def ELEM(el, vi_el):
    return S("elem_dmg", 0.10, "ST %s +10%% (chỉ hệ %s)" % (vi_el, vi_el), el)


SETS = [
    ("lavoisier", "char_fire_01", "fire", "Antoine Lavoisier", "Antoine Lavoisier", [
        ("Oxy", "Oxygen", [ELEM("fire", "Hỏa")], X(P("status_dur:heat", 2.0, "Nhiệt tồn tại 6s → 8s"))),
        ("Định Luật Bảo Toàn Khối Lượng", "Law of Conservation of Mass",
         [S("hp_pct", 0.08, "HP tối đa +8%"),
          P("self_status_dur_pct:burn", -0.3, "Thời gian bị Cháy −30% (chỉ hệ Hỏa)", "fire")],
         X(P("kit:heat_atk_per_stack", 0.01, "Mỗi tầng Nhiệt +4% → +5% ATK (tối đa +25%)"))),
        ("Chuyên Luận Hóa Học", "Elementary Treatise on Chemistry", [S("all_dmg", 0.08, "Tất cả ST +8%")],
         X(P("kit:heat_icd_sec", -0.1, "ICD cộng tầng Nhiệt 0.3s → 0.2s")))],
     [S("elem_dmg", 0.10, "Người đeo +10% ST Hỏa", "fire"),
      V("burn", 0.05, "Kẻ địch đang Cháy chịu +5% ST Hỏa từ người đeo", "fire")]
     + X(T("skill_hit", "self_status", "Kĩ năng thường trúng mục tiêu: +1 tầng Nhiệt ngay (ICD 3s)", icd=3.0,
           status="heat")),
     [T("ultimate_used", "buff", "Khi người đeo dùng Tuyệt kỹ: toàn đội +8% tất cả ST trong 8s", value=8.0,
        mag=0.08, team=True, status=B("eqb_lavoisier_ult", DMG, "Lavoisier: đội +ST", "Lavoisier: team DMG"))]
     + X(T("self_max_stacks", "buff", "Đạt 5 Nhiệt: toàn đội +10% ST Hỏa 6s (làm mới, ICD 8s)", value=6.0,
           mag=0.10, team=True, element="fire", icd=8.0, arg="heat",
           status=B("eqb_lavoisier_heat", DMG, "Lavoisier: +ST Hỏa", "Lavoisier: Fire DMG")),
         P("status_mag:phoenix", 0.10, "Hỏa Hoàng +20% → +30% ST"))),
    ("davinci", "char_wind_01", "wind", "Leonardo da Vinci", "Leonardo da Vinci", [
        ("Chong Chóng Trên Không", "Aerial Screw", [ELEM("wind", "Phong")],
         X(P("kit:fair_wind_targets", -1.0, "Gió Thuận kích hoạt khi bắn trúng 2 kẻ địch khác nhau thay vì 3"))),
        ("Cỗ Máy Cánh Chim", "Ornithopter", [S("move_speed", 0.08, "Tốc độ di chuyển +8%")],
         X(P("kit:fair_wind_sec", 2.0, "Buff Gió Thuận kéo dài 5s → 7s"))),
        ("Bản Thảo Codex", "Codex Manuscript", [S("en_regen", 0.10, "Tốc độ nạp EN +10%")],
         X(P("kit:fair_wind_icd_sec", -2.0, "ICD Gió Thuận 10s → 8s")))],
     [S("elem_dmg", 0.10, "Người đeo +10% ST Phong", "wind"),
      T("perfect_dodge", "buff", "Né hoàn hảo: +10% tất cả ST 4s", value=4.0, mag=0.10,
        status=B("eqb_davinci_dodge", DMG, "da Vinci: +ST", "da Vinci: DMG up"))]
     + X(P("kit:zone_duration_sec", 1.5, "Phong Vực kéo dài +1.5s"),
         P("skill:skill:hits.statuses@slow.magnitude", 0.05, "Chậm trong Phong Vực 20% → 25%")),
     [T("distinct_targets", "buff", "Bắn trúng ≥ 3 kẻ địch khác nhau trong 4s: toàn đội +8% ST nguyên tố 6s (ICD 10s)",
        value=6.0, mag=0.08, team=True, icd=10.0, tval=3, window=4.0,
        status=B("eqb_davinci_multi", DMG, "da Vinci: đội +ST", "da Vinci: team DMG"))]
     + X(P("skill:ultimate:hits[0].duration_ms", 2000.0, "Tuyệt kỹ: bão kéo dài +2s"),
         P("status_dur:storm_blessing", 2.0, "Tuyệt kỹ: buff trong bão kéo dài theo bão (+2s)"),
         P("status_mag:storm_blessing", 0.05, "Buff đồng đội trong bão +15% → +20% ST"))),
    ("franklin", "char_lightning_01", "lightning", "Benjamin Franklin", "Benjamin Franklin", [
        ("Con Diều Trong Bão", "Kite in the Storm", [ELEM("lightning", "Lôi")],
         X(P("status_dur:lightning_mark", 2.0, "Dấu Sét tồn tại 6s → 8s"))),
        ("Cột Thu Lôi", "Lightning Rod", [S("atk_speed", 0.08, "Tốc độ tấn công +8%")],
         X(P("kit:burst.atk_ratio", 0.20, "Bùng nổ Sét 150% → 170% ATK"))),
        ("Niên Lịch Richard Nghèo", "Poor Richard's Almanack",
         [V("elemental", 0.08, "+8% ST lên kẻ địch mang hiệu ứng nguyên tố")],
         X(P("kit:burst_icd_per_target_sec", -1.0, "ICD Bùng nổ mỗi mục tiêu 4s → 3s")))],
     [S("elem_dmg", 0.10, "Người đeo +10% ST Lôi", "lightning"),
      dict(V("elemental", 0.06, "Mục tiêu đang có hiệu ứng nguyên tố chịu +6% tất cả ST từ toàn đội"),
           team=True, effect_id="franklin_team_elemental")]
     + X(T("lightning_burst", "spread", "Bùng nổ Sét lan 1 Dấu Sét sang kẻ địch gần nhất (ICD 4s)", value=6.0,
           icd=4.0, status="lightning_mark")),
     [T("elemental_applied", "buff", "Gây hiệu ứng nguyên tố lên kẻ địch: người đeo +6% tốc độ tấn công 4s (ICD 4s)",
        value=4.0, mag=0.06, icd=4.0, status=B("eqb_franklin_aspd", ASPD, "Franklin: +tốc độ tấn công", "Franklin: attack speed"))]
     + X(P("status_mag:overload", 0.05, "Quá Tải +25% → +30% tốc độ tấn công"),
         T("lightning_burst", "buff", "Sau Bùng nổ Sét: toàn đội +8% ST Lôi 6s", value=6.0, mag=0.08, team=True,
           element="lightning", status=B("eqb_franklin_burst", DMG, "Franklin: +ST Lôi", "Franklin: Lightning DMG")))),
    ("nightingale", "char_light_01", "light", "Florence Nightingale", "Florence Nightingale", [
        ("Ngọn Đèn Scutari", "Lamp of Scutari", [ELEM("light", "Quang")],
         X(P("kit:overflow_to_shield", 0.10, "Tỉ lệ hồi thừa chuyển thành Khiên 50% → 60%"))),
        ("Biểu Đồ Hoa Hồng", "Rose Diagram", [S("heal_bonus", 0.10, "Hiệu quả hồi máu +10%")],
         X(P("kit:shield_max_ratio", 0.02, "Khiên tối đa 8% → 10% HP tối đa mục tiêu"))),
        ("Ghi Chép Về Điều Dưỡng", "Notes on Nursing", [S("hp_pct", 0.08, "HP tối đa +8%")],
         X(P("kit:shield_icd_sec", -0.5, "ICD Ân Huệ Ánh Sáng 2s → 1.5s")))],
     [S("elem_dmg", 0.10, "Người đeo +10% ST Quang", "light"), S("heal_bonus", 0.08, "Mọi hồi máu của người đeo +8%")]
     + X(P("skill:skill:heals[0].cleanse", 1.0, "Kĩ năng thường gỡ 2 hiệu ứng xấu thay vì 1"),
         P("skill:skill:heals.lowest_multiplier", 0.2, "Hệ số hồi cho đồng đội thấp máu nhất ×1.3 → ×1.5")),
     [T("heal_low", "buff", "Hồi máu cho đồng đội dưới 50% HP: toàn đội +8% ST 5s (ICD 8s)", value=5.0, mag=0.08,
        team=True, icd=8.0, status=B("eqb_nightingale_heal", DMG, "Nightingale: đội +ST", "Nightingale: team DMG"))]
     + X(P("status_mag:sanctuary", 0.05, "Tuyệt kỹ: giảm ST nhận của đồng đội 25% → 30%"),
         P("skill:ultimate:heals.max_hp_ratio", 0.01, "Tuyệt kỹ: hồi 4% → 5% HP tối đa mỗi giây"))),
    ("poe", "char_dark_01", "dark", "Edgar Allan Poe", "Edgar Allan Poe", [
        ("Con Quạ", "The Raven", [ELEM("dark", "Ám")],
         X(P("kit:cursed_lifesteal", 0.02, "Hồi máu từ ST lên mục tiêu Nguyền 4% → 6%"),
           P("kit:cursed_lifesteal_boss", 0.01, "Hồi máu từ ST lên boss Nguyền 2% → 3%"))),
        ("Trái Tim Tố Giác", "The Tell-Tale Heart", [S("lifesteal", 0.05, "Hút máu +5%")],
         X(P("status_mag:curse", 0.03, "Nguyền −15% → −18% DEF"))),
        ("Chiếc Hố Và Con Lắc", "The Pit and the Pendulum",
         [V("def_down", 0.08, "+8% ST lên kẻ địch bị giảm DEF (Nguyền cũng là giảm DEF)")],
         X(P("kit:cursed_kill_icd_sec", -0.4, "ICD phần thưởng hạ gục 1.0s → 0.6s")))],
     [S("elem_dmg", 0.10, "Người đeo +10% ST Ám", "dark"),
      T("kill", "heal_self", "Hạ gục kẻ địch: hồi 3% HP tối đa (ICD 2s)", value=0.03, icd=2.0)]
     + X(T("kill", "si_cd", "Hạ gục kẻ địch: giảm 1.5s SI-CD, không vượt 3.0s mỗi chu kỳ", value=1.5, cap=3.0)),
     [V("low_hp", 0.10, "Kẻ địch dưới 30% HP chịu +10% ST từ người đeo")]
     + X(P("kit:execute_hp_ratio", 0.05, "Thu hoạch: ngưỡng xử tử 20% → 25% HP"),
         P("kit:night_king_normal_bonus", 0.05, "Dạ Vương +15% → +20% ST đòn thường"),
         T("kill_cursed", "spread", "Hạ gục kẻ địch đang Nguyền: Nguyền lan sang 1 kẻ địch gần nhất, giữ thời gian còn lại",
           status="curse"))),
    ("darwin", "char_earth_01", "earth", "Charles Darwin", "Charles Darwin", [
        ("Chuyến Đi Beagle", "Voyage of the Beagle", [ELEM("earth", "Địa")],
         X(P("status_dur:stone_bone", 2.0, "Cốt Đá tồn tại 8s → 10s"))),
        ("Chọn Lọc Tự Nhiên", "Natural Selection", [S("dmg_taken_down", 0.06, "Giảm 6% ST nhận")],
         X(P("kit:bone_damage_reduction", 0.005, "Mỗi tầng Cốt Đá giảm 3% → 3.5% ST nhận"))),
        ("Lý Luận Tiến Hoá", "Theory of Evolution", [S("hp_pct", 0.12, "HP tối đa +12%")],
         X(P("kit:bone_icd_sec", -0.2, "ICD cộng tầng Cốt Đá 0.5s → 0.3s")))],
     [S("elem_dmg", 0.10, "Người đeo +10% ST Địa", "earth"),
      T("while_self_hp_below", "buff", "Dưới 50% HP: giảm thêm 8% ST nhận (đệm 5% HP khi tắt)", mag=0.08, tval=0.5,
        status=B("eqb_darwin_low_hp", TAKEN, "Darwin: giảm ST nhận", "Darwin: guard"))]
     + X(P("skill:skill:self_statuses@shield.magnitude", 0.05,
           "Khiên Đá (khiên của Giáp Địa, Kĩ năng thường) hấp thụ tối đa 20% → 25% HP tối đa")),
     [T("weapon_or_ultimate_used", "buff", "Dùng Kĩ năng vũ khí hoặc Tuyệt kỹ: toàn đội giảm 6% ST nhận 6s (ICD 10s)",
        value=6.0, mag=0.06, team=True, icd=10.0,
        status=B("eqb_darwin_team_guard", TAKEN, "Darwin: đội giảm ST nhận", "Darwin: team guard"))]
     + X(P("status_mag:stone_god", 0.05, "Thạch Thần: giảm ST nhận −40% → −45%"),
         P("kit:stone_god_atk", 0.05, "Thạch Thần: +20% → +25% ATK"))),
]

# Buff do kit áp (không qua TRIGGER) nhưng định nghĩa ở đây: Phong Vực +ST cho đồng đội (vũ khí Kazeyumi).
B("eqb_wind_zone_dmg", DMG, "Phong Vực: +ST", "Wind Domain: DMG up")

# Chỉ số cộng thẳng vết thánh 5★ theo ô (khởi điểm, ≈ 1.3 × 4★).
PIECE_STATS = {"top": (80.0, 0.0, 0.0, 0.08, 0.0, 0.0), "mid": (50.0, 2000.0, 60.0, 0.0, 0.0, 0.0),
               "bot": (60.0, 0.0, 0.0, 0.0, 0.0, 0.08)}
SLOT_VI = {"top": "Đầu", "mid": "Thân", "bot": "Chân"}
SLOT_EN = {"top": "Top", "mid": "Middle", "bot": "Bottom"}

# ---------- Bộ 4★ (owner Q9: bản nhỏ, chỉ phần chung, số ≈ một nửa 5★) ----------
SETS_4 = [
    ("blaze", "fire", "Ấn Viêm Hoàng", "Blaze Sovereign Sigil",
     [S("elem_dmg", 0.05, "Người đeo +5% ST Hỏa", "fire")],
     [V("burn", 0.04, "Kẻ địch đang Cháy chịu +4% ST Hỏa từ người đeo", "fire")]),
    ("bedrock", "earth", "Ấn Nham Thạch", "Bedrock Sigil",
     [S("elem_dmg", 0.05, "Người đeo +5% ST Địa", "earth")],
     [S("dmg_taken_down", 0.03, "Người đeo giảm 3% ST nhận")]),
    # Owner 2026-11-15: bộ 4★ cho từng loại vũ khí (cung, song đao, trượng, lưỡi hái); số ≈ một nửa phần chung 5★.
    ("whirlwind", "wind", "Ấn Lốc Xoáy", "Whirlwind Sigil",
     [S("elem_dmg", 0.05, "Người đeo +5% ST Phong", "wind")],
     [S("en_regen", 0.05, "Tốc độ nạp EN +5%")]),
    ("thunderclap", "lightning", "Ấn Lôi Đình", "Thunderclap Sigil",
     [S("elem_dmg", 0.05, "Người đeo +5% ST Lôi", "lightning")],
     [V("elemental", 0.04, "+4% ST lên kẻ địch mang hiệu ứng nguyên tố")]),
    ("dawnlight", "light", "Ấn Bình Minh", "Dawnlight Sigil",
     [S("elem_dmg", 0.05, "Người đeo +5% ST Quang", "light")],
     [S("heal_bonus", 0.04, "Hiệu quả hồi máu +4%")]),
    ("nightshade", "dark", "Ấn Dạ Ảnh", "Nightshade Sigil",
     [S("elem_dmg", 0.05, "Người đeo +5% ST Ám", "dark")],
     [V("def_down", 0.04, "+4% ST lên kẻ địch bị giảm DEF (Nguyền cũng là giảm DEF)")]),
]

FIELD_ORDER = ["kind", "exclusive", "requires_element", "team", "effect_id", "stat", "param", "condition",
               "status_id", "value", "magnitude", "trigger", "trigger_arg", "trigger_value", "trigger_window", "icd",
               "action", "target_element", "cd_keys", "cap", "note"]
FLOAT_FIELDS = {"value", "magnitude", "trigger_value", "trigger_window", "icd", "cap"}


def fmt(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, list):
        return "PackedStringArray(%s)" % ", ".join('"%s"' % x for x in v)
    if isinstance(v, (int, float)) and not isinstance(v, bool):
        return repr(float(v)) if isinstance(v, float) else str(v)
    return '"%s"' % str(v).replace('"', '\\"')


def effect_block(sid, e):
    lines = ['[sub_resource type="Resource" id="%s"]' % sid, 'script = ExtResource("2")']
    for k in FIELD_ORDER:
        v = e.get(k, 0)
        if k != "kind" and (k not in e or v in ("", None, False, []) or (k in ("magnitude", "cap") and v == -1.0)):
            continue
        lines.append("%s = %s" % (k, fmt(float(v) if k in FLOAT_FIELDS else v)))
    return "\n".join(lines)


def write_res(rel, cls, script, fields, effect_lists):
    """effect_lists: [(tên trường, [hiệu ứng])]."""
    subs, refs = [], {}
    n = 0
    for name, effs in effect_lists:
        refs[name] = []
        for e in effs:
            sid = "Effect_%d" % n
            n += 1
            subs.append(effect_block(sid, e))
            refs[name].append('SubResource("%s")' % sid)
    head = '[gd_resource type="Resource" script_class="%s" load_steps=%d format=3]' % (cls, 3 + n)
    out = [head, "", '[ext_resource type="Script" path="res://scripts/progression/%s" id="1"]' % script,
           '[ext_resource type="Script" path="res://scripts/progression/equip_effect.gd" id="2"]', ""]
    for s in subs:
        out += [s, ""]
    out += ["[resource]", 'script = ExtResource("1")']
    for k, v in fields:
        out.append("%s = %s" % (k, v if isinstance(v, str) and v.startswith("Packed") else fmt(v)))
    for name in refs:
        out.append('%s = Array[ExtResource("2")]([%s])' % (name, ", ".join(refs[name])))
    out.append('metadata/source = "%s"' % SRC)
    p = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    io.open(p, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")


def equip_fields(eid, slot, owner, set_id, wtype, st):
    atk, hp, df, cr, cd, cdr = st
    return [("id", eid), ("name_key", "EQUIP_" + eid.upper()), ("slot", slot), ("rarity", 5),
            ("weapon_type", wtype), ("max_level", 10), ("owner_id", owner), ("set_id", set_id),
            ("atk", atk), ("max_hp", hp), ("def", df), ("crit_rate", cr), ("crit_damage", cd), ("cdr", cdr),
            ("growth_per_level", 0.1), ("enhance_gold_base", 1000), ("enhance_points_base", 500)] + art_field(eid, slot)


def art_field(eid, slot):
    """Ảnh món (owner 2026-11-15): có file assets/equipment/{weapons|stigmata}/<id>.png thì ghi `art`."""
    rel = "assets/equipment/%s/%s.png" % ("weapons" if slot == "weapon" else "stigmata", eid)
    return [("art", "res://" + rel)] if os.path.exists(os.path.join(ROOT, rel)) else []


locale = []
for eid, owner, el, wtype, vi, en, (atk, hp, df, cr, cd), common, excl in WEAPONS:
    write_res("data/equipment/%s.tres" % eid, "EquipmentDef", "equipment_def.gd",
              equip_fields(eid, "weapon", owner, "", wtype, (atk, hp, df, cr, cd, 0.0)), [("effects", common + excl)])
    locale.append(("EQUIP_" + eid.upper(), vi, en))

for key, owner, el, vi, en, pieces, b2, b3 in SETS:
    sid = "set_" + key
    for slot, (pvi, pen, common, excl) in zip(("top", "mid", "bot"), pieces):
        eid = "eq_stigma_%s_%s" % (slot, key)
        write_res("data/equipment/%s.tres" % eid, "EquipmentDef", "equipment_def.gd",
                  equip_fields(eid, "stigma_" + slot, owner, sid, "", PIECE_STATS[slot]), [("effects", common + excl)])
        locale.append(("EQUIP_" + eid.upper(), "%s (%s)" % (pvi, SLOT_VI[slot]), "%s (%s)" % (pen, SLOT_EN[slot])))
    write_res("data/equipment/sets/%s.tres" % sid, "StigmaSetDef", "stigma_set_def.gd",
              [("id", sid), ("name_key", "SET_" + sid.upper()), ("rarity", 5), ("owner_id", owner), ("element", el)],
              [("bonus_2", b2), ("bonus_3", b3)])
    locale.append(("SET_" + sid.upper(), vi, en))

for key, el, vi, en, b2, b3 in SETS_4:
    sid = "set_" + key
    write_res("data/equipment/sets/%s.tres" % sid, "StigmaSetDef", "stigma_set_def.gd",
              [("id", sid), ("name_key", "SET_" + sid.upper()), ("rarity", 4), ("owner_id", ""), ("element", el)],
              [("bonus_2", b2), ("bonus_3", b3)])
    locale.append(("SET_" + sid.upper(), vi, en))
    # Gắn set_id vào 3 vết thánh 4★ đã có (gen_item_data.py cũng ghi set_id khi chạy lại).
    for slot in ("top", "mid", "bot"):
        p = os.path.join(ROOT, "data/equipment/eq_stigma_%s_%s.tres" % (slot, key))
        s = io.open(p, encoding="utf-8").read()
        s = re.sub(r'\nset_id = "[^"]*"', "", s)
        s = s.replace('\nmax_level = ', '\nset_id = "%s"\nmax_level = ' % sid, 1)
        io.open(p, "w", encoding="utf-8", newline="\n").write(s)

# Trạng thái buff của hiệu ứng theo sự kiện (data/statuses/eqb_*.tres): REFRESH, không cộng dồn (mục 3.3).
for sid, (meaning, vs, vi, en) in sorted(BUFFS.items()):
    lines = ['[gd_resource type="Resource" script_class="StatusDef" load_steps=2 format=3]', "",
             '[ext_resource type="Script" path="res://scripts/combat/status_def.gd" id="1"]', "", "[resource]",
             'script = ExtResource("1")', 'id = "%s"' % sid, 'name_key = "STATUS_%s"' % sid.upper(), "kind = 1",
             "stacking = 0", "max_stacks = 1", "default_duration = 1.0", "default_magnitude = 0.1",
             'magnitude_meaning = "%s"' % meaning, "equipment = true", 'vs_status = "%s"' % vs,
             'metadata/source = "%s"' % SRC]
    io.open(os.path.join(ROOT, "data/statuses/%s.tres" % sid), "w", encoding="utf-8", newline="\n").write(
        "\n".join(lines) + "\n")
    locale.append(("STATUS_" + sid.upper(), vi, en))

for po, idx in (("vi.po", 1), ("en.po", 2)):
    p = os.path.join(ROOT, "localization", po)
    s = io.open(p, encoding="utf-8").read()
    add = ""
    for row in locale:
        if 'msgid "%s"' % row[0] not in s:
            add += '\nmsgid "%s"\nmsgstr "%s"\n' % (row[0], row[idx].replace('"', '\\"'))
    if add:
        io.open(p, "w", encoding="utf-8", newline="\n").write(s.rstrip("\n") + "\n\n# Trang bị 5★, bộ vết thánh" + add)
print("ok: %d vũ khí, %d bộ 5★, %d bộ 4★, %d khóa dịch" % (len(WEAPONS), len(SETS), len(SETS_4), len(locale)))
