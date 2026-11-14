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


# ---------- Vũ khí 5★ (mục 1) ----------
# id, owner, element, weapon_type, vi, en, (atk, hp, def, crit_rate, crit_dmg), common, exclusive
WEAPONS = [
    ("eq_weapon_dusk_inferno", "char_fire_01", "fire", "sword", "Hoàng Hôn Thiêu Rụi", "Dusk Inferno",
     (230.0, 0.0, 0.0, 0.06, 0.0),
     [S("elem_dmg", 0.15, "Cộng hưởng: người đeo hệ Hỏa +15% ST Hỏa", "fire"),
      S("all_dmg", 0.08, "Người đeo +8% tất cả ST"),
      V("burn", 0.08, "Kẻ địch đang Cháy chịu +8% ST Hỏa từ người đeo", "fire"),
      H("burn", 3.0, "Kĩ năng vũ khí áp Cháy 3s lên mục tiêu trúng", req="fire"),
      N("Dùng Tuyệt kỹ: người đeo +6% tất cả ST trong 6s")],
     X(S("all_dmg", 0.08, "Toàn đội +8% tất cả ST", team="fire_wpn_team_dmg"),
       N("+8% tất cả ST nữa (toàn đội) khi Enkiba có ≥ 3 Nhiệt"),
       V("stun", 0.15, "Kẻ địch đang Choáng chịu +15% tất cả ST từ Enkiba"),
       P("skill:weapon:cooldown_sec", -2.0, "CD Kĩ năng vũ khí 12.0s → 10.0s"),
       P("status_mag:melt", 0.05, "Nung chảy −10% → −15% DEF"),
       N("Bonus +25% của Kĩ năng vũ khí vẫn cần 5 Nhiệt, chỉ tiêu 3 tầng (giữ lại 2)"),
       N("Kĩ năng vũ khí trúng: toàn đội +10% ST Hỏa 8s (ICD 10s, làm mới)"),
       P("status_dur:phoenix", 2.0, "Hỏa Hoàng 8s → 10s"))),
    ("eq_weapon_last_gale", "char_wind_01", "wind", "bow", "Hơi Thở Cuối Mùa Gió", "Last Breath of the Gale",
     (215.0, 0.0, 0.0, 0.05, 0.0),
     [S("elem_dmg", 0.15, "Cộng hưởng: người đeo hệ Phong +15% ST Phong", "wind"),
      S("move_speed", 0.08, "Người đeo +8% tốc độ di chuyển"),
      S("all_dmg", 0.06, "Người đeo +6% tất cả ST"),
      V("slow", 0.08, "Kẻ địch đang Chậm chịu +8% ST từ người đeo"),
      H("slow", 2.0, "Kĩ năng vũ khí thêm Chậm 20% trong 2s", mag=0.2),
      N("Bắn trúng 2 kẻ địch khác nhau trong 4s: +8% tốc độ di chuyển 4s")],
     X(S("en_regen", 0.06, "Toàn đội +6% tốc độ nạp EN", team="wind_wpn_team_en"),
       N("Kẻ địch trong Phong Vực chịu +12% ST từ Kazeyumi"),
       P("skill:weapon:cooldown_sec", -2.0, "CD Kĩ năng vũ khí 13.0s → 11.0s"),
       N("Bonus mục tiêu đứng trong Phong Vực +25% → +35%"),
       N("Né hoàn hảo: Kĩ năng vũ khí giảm 3.0s CD (ICD 8s)"),
       N("Đồng đội trong Phong Vực +10% ST nguyên tố"))),
    ("eq_weapon_twin_thunder", "char_lightning_01", "lightning", "dual_blades", "Hai Tiếng Sấm", "Twin Thunderclaps",
     (220.0, 0.0, 0.0, 0.0, 0.15),
     [S("elem_dmg", 0.15, "Cộng hưởng: người đeo hệ Lôi +15% ST Lôi", "lightning"),
      S("atk_speed", 0.08, "Người đeo +8% tốc độ tấn công"),
      S("all_dmg", 0.06, "Người đeo +6% tất cả ST"),
      V("elemental", 0.08, "Kẻ địch đang mang hiệu ứng nguyên tố chịu +8% tất cả ST từ người đeo"),
      H("lightning_mark", 6.0, "Kĩ năng vũ khí thêm 1 Dấu Sét lên mục tiêu trúng", req="lightning"),
      N("Gây hiệu ứng nguyên tố: người đeo +6% tốc độ nạp EN trong 4s (ICD 4s)")],
     X(N("Sau mỗi Bùng nổ Sét: toàn đội +8% tốc độ tấn công 6s (làm mới, ICD 4s)"),
       P("kit:burst.atk_ratio", 0.40, "Bùng nổ Sét +40% ST (150% → 190% ATK)"),
       P("skill:weapon:cooldown_sec", -2.0, "CD Kĩ năng vũ khí 11.0s → 9.0s"),
       N("Kĩ năng vũ khí áp 2 Dấu Sét mỗi lượt đao thay vì 1"),
       P("skill:weapon:blocks_normal_ms", -300.0, "Khóa đòn thường sau Kĩ năng vũ khí 800 ms → 500 ms"),
       N("Mỗi Bùng nổ Sét hồi 8 EN cho Raikiba (ICD 4s)"))),
    ("eq_weapon_solar_verdict", "char_light_01", "light", "staff", "Nhật Miện Phán Quyết", "Solar Crown Verdict",
     (200.0, 1200.0, 0.0, 0.0, 0.0),
     [S("elem_dmg", 0.15, "Cộng hưởng: người đeo hệ Quang +15% ST Quang", "light"),
      S("heal_bonus", 0.10, "Người đeo +10% hiệu quả hồi máu"),
      V("judgment", 0.06, "Kẻ địch có Phán quyết chịu +6% ST từ người đeo", "light"),
      N("Kĩ năng vũ khí hồi cho toàn đội 3% HP tối đa nếu trúng ít nhất 1 kẻ địch"),
      N("Hồi máu cho đồng đội dưới 50% HP: người đeo +6% ST 5s (ICD 8s)")],
     X(S("heal_bonus", 0.08, "Toàn đội +8% hiệu quả hồi máu", team="light_wpn_team_heal"),
       P("status_mag:judgment", 0.04, "Phán quyết từ Hikarine +8% → +12% ST nhận"),
       P("skill:weapon:cooldown_sec", -2.0, "CD Kĩ năng vũ khí 12.0s → 10.0s"),
       N("Hồi đồng đội trong vùng 60% → 90% ATK"),
       N("Đồng đội trong vùng +10% tất cả ST trong 6s (làm mới)"),
       P("kit:shield_max_ratio", 0.04, "Khiên từ hồi thừa tối đa 8% → 12% HP tối đa"))),
    ("eq_weapon_crescent_pact", "char_dark_01", "dark", "scythe", "Liềm Khế Ước Trăng Khuyết", "Crescent Pact Scythe",
     (225.0, 0.0, 0.0, 0.0, 0.15),
     [S("elem_dmg", 0.15, "Cộng hưởng: người đeo hệ Ám +15% ST Ám", "dark"),
      S("all_dmg", 0.08, "Người đeo +8% tất cả ST"),
      S("lifesteal", 0.04, "Người đeo +4% hút máu"),
      N("Hạ gục kẻ địch: người đeo hồi 2% HP tối đa (ICD 2s)"),
      H("root", 0.8, "Kĩ năng vũ khí Trói 0.8s (boss 0.3s)"),
      V("low_hp", 0.08, "Kẻ địch dưới 30% HP chịu +8% ST từ người đeo")],
     X(N("Toàn đội +6% hút máu khi đánh kẻ địch đang Nguyền"),
       N("Hạ gục kẻ địch giảm 1.5s CD Kĩ năng thường và Kĩ năng vũ khí (ICD 1.0s)"),
       P("skill:weapon:cooldown_sec", -2.0, "CD Kĩ năng vũ khí 12.0s → 10.0s"),
       P("status_mag:curse", 0.05, "Nguyền từ Yomigari −15% → −20% DEF"),
       P("kit:skill_lifesteal.weapon", 0.04, "Hút máu Kĩ năng vũ khí 6% → 10%"),
       N("Hạ gục kẻ địch đang Nguyền: toàn đội +8% ST lên mục tiêu Nguyền trong 6s"))),
    ("eq_weapon_unyielding_peak", "char_earth_01", "earth", "greatsword", "Cốt Sơn Bất Khuất", "Unyielding Mountain Bone",
     (235.0, 0.0, 100.0, 0.0, 0.0),
     [S("elem_dmg", 0.15, "Cộng hưởng: người đeo hệ Địa +15% ST Địa", "earth"),
      S("all_dmg", 0.08, "Người đeo +8% tất cả ST"),
      S("dmg_taken_down", 0.06, "Người đeo giảm 6% ST nhận"),
      V("def_down", 0.08, "Kẻ địch đang bị giảm DEF chịu +8% ST từ người đeo"),
      N("Kĩ năng vũ khí: giảm 20% ST nhận trong lúc dùng"),
      N("Nhận ST: người đeo +4% DEF trong 5s (ICD 2s)")],
     X(N("Toàn đội giảm 6% ST nhận trong 6s sau khi Iwagane dùng Kĩ năng vũ khí (làm mới, ICD 10s)"),
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
         [S("hp_pct", 0.08, "HP tối đa +8%"), N("Thời gian bị Cháy −30% (chỉ hệ Hỏa)", "fire")],
         X(P("kit:heat_atk_per_stack", 0.01, "Mỗi tầng Nhiệt +4% → +5% ATK (tối đa +25%)"))),
        ("Chuyên Luận Hóa Học", "Elementary Treatise on Chemistry", [S("all_dmg", 0.08, "Tất cả ST +8%")],
         X(P("kit:heat_icd_sec", -0.1, "ICD cộng tầng Nhiệt 0.3s → 0.2s")))],
     [S("elem_dmg", 0.10, "Người đeo +10% ST Hỏa", "fire"),
      V("burn", 0.05, "Kẻ địch đang Cháy chịu +5% ST Hỏa từ người đeo", "fire")]
     + X(N("Kĩ năng thường trúng mục tiêu: +1 tầng Nhiệt ngay (ICD 3s)")),
     [N("Khi người đeo dùng Tuyệt kỹ: toàn đội +8% tất cả ST trong 8s")]
     + X(N("Đạt 5 Nhiệt: toàn đội +10% ST Hỏa 6s (làm mới, ICD 8s)"),
         P("status_mag:phoenix", 0.10, "Hỏa Hoàng +20% → +30% ST"))),
    ("davinci", "char_wind_01", "wind", "Leonardo da Vinci", "Leonardo da Vinci", [
        ("Chong Chóng Trên Không", "Aerial Screw", [ELEM("wind", "Phong")],
         X(P("kit:fair_wind_targets", -1.0, "Gió Thuận kích hoạt khi bắn trúng 2 kẻ địch khác nhau thay vì 3"))),
        ("Cỗ Máy Cánh Chim", "Ornithopter", [S("move_speed", 0.08, "Tốc độ di chuyển +8%")],
         X(P("kit:fair_wind_sec", 2.0, "Buff Gió Thuận kéo dài 5s → 7s"))),
        ("Bản Thảo Codex", "Codex Manuscript", [S("en_regen", 0.10, "Tốc độ nạp EN +10%")],
         X(P("kit:fair_wind_icd_sec", -2.0, "ICD Gió Thuận 10s → 8s")))],
     [S("elem_dmg", 0.10, "Người đeo +10% ST Phong", "wind"), N("Né hoàn hảo: +10% tất cả ST 4s")]
     + X(P("kit:zone_duration_sec", 1.5, "Phong Vực kéo dài +1.5s"), N("Chậm trong Phong Vực 20% → 25%")),
     [N("Bắn trúng ≥ 3 kẻ địch khác nhau trong 4s: toàn đội +8% ST nguyên tố 6s (ICD 10s)")]
     + X(N("Tuyệt kỹ: bão kéo dài +2s"), P("status_mag:storm_blessing", 0.05, "Buff đồng đội trong bão +15% → +20% ST"))),
    ("franklin", "char_lightning_01", "lightning", "Benjamin Franklin", "Benjamin Franklin", [
        ("Con Diều Trong Bão", "Kite in the Storm", [ELEM("lightning", "Lôi")],
         X(P("status_dur:lightning_mark", 2.0, "Dấu Sét tồn tại 6s → 8s"))),
        ("Cột Thu Lôi", "Lightning Rod", [S("atk_speed", 0.08, "Tốc độ tấn công +8%")],
         X(P("kit:burst.atk_ratio", 0.20, "Bùng nổ Sét 150% → 170% ATK"))),
        ("Niên Lịch Richard Nghèo", "Poor Richard's Almanack",
         [V("elemental", 0.08, "+8% ST lên kẻ địch mang hiệu ứng nguyên tố")],
         X(P("kit:burst_icd_per_target_sec", -1.0, "ICD Bùng nổ mỗi mục tiêu 4s → 3s")))],
     [S("elem_dmg", 0.10, "Người đeo +10% ST Lôi", "lightning"),
      N("Mục tiêu đang có hiệu ứng nguyên tố chịu +6% tất cả ST từ toàn đội")]
     + X(N("Bùng nổ Sét lan 1 Dấu Sét sang kẻ địch gần nhất (ICD 4s)")),
     [N("Gây hiệu ứng nguyên tố lên kẻ địch: người đeo +6% tốc độ tấn công 4s (ICD 4s)")]
     + X(P("status_mag:overload", 0.05, "Quá Tải +25% → +30% tốc độ tấn công"),
         N("Sau Bùng nổ Sét: toàn đội +8% ST Lôi 6s"))),
    ("nightingale", "char_light_01", "light", "Florence Nightingale", "Florence Nightingale", [
        ("Ngọn Đèn Scutari", "Lamp of Scutari", [ELEM("light", "Quang")],
         X(P("kit:overflow_to_shield", 0.10, "Tỉ lệ hồi thừa chuyển thành Khiên 50% → 60%"))),
        ("Biểu Đồ Hoa Hồng", "Rose Diagram", [S("heal_bonus", 0.10, "Hiệu quả hồi máu +10%")],
         X(P("kit:shield_max_ratio", 0.02, "Khiên tối đa 8% → 10% HP tối đa mục tiêu"))),
        ("Ghi Chép Về Điều Dưỡng", "Notes on Nursing", [S("hp_pct", 0.08, "HP tối đa +8%")],
         X(P("kit:shield_icd_sec", -0.5, "ICD Ân Huệ Ánh Sáng 2s → 1.5s")))],
     [S("elem_dmg", 0.10, "Người đeo +10% ST Quang", "light"), S("heal_bonus", 0.08, "Mọi hồi máu của người đeo +8%")]
     + X(N("Kĩ năng thường gỡ 2 hiệu ứng xấu thay vì 1"), N("Hệ số hồi cho đồng đội thấp máu nhất ×1.3 → ×1.5")),
     [N("Hồi máu cho đồng đội dưới 50% HP: toàn đội +8% ST 5s (ICD 8s)")]
     + X(P("status_mag:sanctuary", 0.05, "Tuyệt kỹ: giảm ST nhận của đồng đội 25% → 30%"),
         N("Tuyệt kỹ: hồi 4% → 5% HP tối đa mỗi giây"))),
    ("poe", "char_dark_01", "dark", "Edgar Allan Poe", "Edgar Allan Poe", [
        ("Con Quạ", "The Raven", [ELEM("dark", "Ám")],
         X(P("kit:cursed_lifesteal", 0.02, "Hồi máu từ ST lên mục tiêu Nguyền 4% → 6%"),
           P("kit:cursed_lifesteal_boss", 0.01, "Hồi máu từ ST lên boss Nguyền 2% → 3%"))),
        ("Trái Tim Tố Giác", "The Tell-Tale Heart", [S("lifesteal", 0.05, "Hút máu +5%")],
         X(P("status_mag:curse", 0.03, "Nguyền −15% → −18% DEF"))),
        ("Chiếc Hố Và Con Lắc", "The Pit and the Pendulum",
         [V("def_down", 0.08, "+8% ST lên kẻ địch bị giảm DEF (Nguyền cũng là giảm DEF)")],
         X(P("kit:cursed_kill_icd_sec", -0.4, "ICD phần thưởng hạ gục 1.0s → 0.6s")))],
     [S("elem_dmg", 0.10, "Người đeo +10% ST Ám", "dark"), N("Hạ gục kẻ địch: hồi 3% HP tối đa (ICD 2s)")]
     + X(N("Hạ gục kẻ địch: giảm 1.5s SI-CD, không vượt 3.0s mỗi chu kỳ")),
     [V("low_hp", 0.10, "Kẻ địch dưới 30% HP chịu +10% ST từ người đeo")]
     + X(P("kit:execute_hp_ratio", 0.05, "Thu hoạch: ngưỡng xử tử 20% → 25% HP"),
         P("kit:night_king_normal_bonus", 0.05, "Dạ Vương +15% → +20% ST đòn thường"),
         N("Hạ gục kẻ địch đang Nguyền: Nguyền lan sang 1 kẻ địch gần nhất, giữ thời gian còn lại"))),
    ("darwin", "char_earth_01", "earth", "Charles Darwin", "Charles Darwin", [
        ("Chuyến Đi Beagle", "Voyage of the Beagle", [ELEM("earth", "Địa")],
         X(P("status_dur:stone_bone", 2.0, "Cốt Đá tồn tại 8s → 10s"))),
        ("Chọn Lọc Tự Nhiên", "Natural Selection", [S("dmg_taken_down", 0.06, "Giảm 6% ST nhận")],
         X(P("kit:bone_damage_reduction", 0.005, "Mỗi tầng Cốt Đá giảm 3% → 3.5% ST nhận"))),
        ("Lý Luận Tiến Hoá", "Theory of Evolution", [S("hp_pct", 0.12, "HP tối đa +12%")],
         X(P("kit:bone_icd_sec", -0.2, "ICD cộng tầng Cốt Đá 0.5s → 0.3s")))],
     [S("elem_dmg", 0.10, "Người đeo +10% ST Địa", "earth"), N("Dưới 50% HP: giảm thêm 8% ST nhận")]
     + X(N("Khiên Đá hấp thụ tối đa 20% → 25% HP tối đa")),
     [N("Dùng Kĩ năng vũ khí hoặc Tuyệt kỹ: toàn đội giảm 6% ST nhận 6s (ICD 10s)")]
     + X(P("status_mag:stone_god", 0.05, "Thạch Thần: giảm ST nhận −40% → −45%"),
         P("kit:stone_god_atk", 0.05, "Thạch Thần: +20% → +25% ATK"))),
]

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
]

FIELD_ORDER = ["kind", "exclusive", "requires_element", "team", "effect_id", "stat", "param", "condition",
               "status_id", "value", "magnitude", "note"]


def fmt(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)) and not isinstance(v, bool):
        return repr(float(v)) if isinstance(v, float) else str(v)
    return '"%s"' % str(v).replace('"', '\\"')


def effect_block(sid, e):
    lines = ['[sub_resource type="Resource" id="%s"]' % sid, 'script = ExtResource("2")']
    for k in FIELD_ORDER:
        if k in e and e[k] not in ("", None, False) or (k == "kind"):
            lines.append("%s = %s" % (k, fmt(e.get(k, 0))))
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
            ("growth_per_level", 0.1), ("enhance_gold_base", 1000), ("enhance_points_base", 500)]


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

for po, idx in (("vi.po", 1), ("en.po", 2)):
    p = os.path.join(ROOT, "localization", po)
    s = io.open(p, encoding="utf-8").read()
    add = ""
    for row in locale:
        if 'msgid "%s"' % row[0] not in s:
            add += '\nmsgid "%s"\nmsgstr "%s"\n' % (row[0], row[idx].replace('"', '\\"'))
    if add:
        io.open(p, "w", encoding="utf-8", newline="\n").write(s.rstrip("\n") + "\n\n# Trang bị 5★, bộ vết thánh" + add)
n_pending = sum(1 for w in WEAPONS for e in w[7] + w[8] if e["kind"] == PENDING)
print("ok: %d vũ khí, %d bộ 5★, %d bộ 4★, %d khóa dịch" % (len(WEAPONS), len(SETS), len(SETS_4), len(locale)))
