"""Sinh dữ liệu khởi điểm cho M5-2 / M5-3: luật tăng trưởng, nguyên liệu, trang bị + khóa dịch.
Chạy: python -X utf8 tools/gen_item_data.py   (ghi đè data/config/progression.tres, data/items/*.tres, data/equipment/*.tres)
Mọi số là giá trị Claude đặt làm khởi điểm (README chưa có); owner chỉnh trong file .tres.
"""
import io
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = "Số khởi điểm do Claude đặt (README chưa có); owner chỉnh."


def write(rel, script, cls, fields):
    p = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    lines = ['[gd_resource type="Resource" script_class="%s" load_steps=2 format=3]' % cls, "",
             '[ext_resource type="Script" path="res://scripts/progression/%s" id="1"]' % script, "",
             "[resource]", 'script = ExtResource("1")']
    for k, v in fields:
        if isinstance(v, bool):
            v = "true" if v else "false"
        elif isinstance(v, str) and not v.startswith("Packed"):
            v = '"%s"' % v
        lines.append("%s = %s" % (k, v))
    lines.append('metadata/source = "%s"' % SRC)
    io.open(p, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")


write("data/config/progression.tres", "progression_rules.gd", "ProgressionRules", [
    ("max_level", 50), ("exp_base", 100.0), ("exp_exponent", 1.5),
    ("hp_growth_per_level", 0.06), ("atk_growth_per_level", 0.06), ("def_growth_per_level", 0.05),
    ("gold_per_exp", 0.2), ("skill_max_level", 10), ("skill_upgrade_gold_base", 500),
    ("captain_max_level", 50), ("captain_exp_base", 50.0), ("promotion_fragments", "PackedInt32Array(10, 20, 25)"),
    ("promotion_stat_bonus", 0.05)])

EXP, ENHANCE, MISC = 0, 1, 2
ITEMS = [  # id, kind, value, rarity, vi, en
    ("mat_exp_small", EXP, 100, 1, "Sách kinh nghiệm nhỏ", "Small EXP Book"),
    ("mat_exp_medium", EXP, 500, 2, "Sách kinh nghiệm vừa", "Medium EXP Book"),
    ("mat_exp_large", EXP, 2000, 3, "Sách kinh nghiệm lớn", "Large EXP Book"),
    ("mat_enhance_ore", ENHANCE, 50, 1, "Quặng cường hóa", "Enhancement Ore"),
    ("mat_enhance_crystal", ENHANCE, 250, 3, "Tinh thể cường hóa", "Enhancement Crystal"),
]
for iid, kind, value, rarity, vi, en in ITEMS:
    write("data/items/%s.tres" % iid, "item_def.gd", "ItemDef",
          [("id", iid), ("name_key", "ITEM_" + iid.upper()), ("kind", kind), ("value", value), ("rarity", rarity)])

# Trang bị (owner, 2026-11-12): mỗi nhân vật mang 1 vũ khí + 3 vết thánh theo thứ tự Đầu / Thân / Chân.
# Độ hiếm 3★ / 4★ (khớp tiếp tế vũ khí). `cost` là hệ số giá cường hóa giữ từ thiết kế trước (200 vàng, 100 điểm × cost).
WEAPON_TYPE = {"eq_weapon_iron": "sword", "eq_weapon_flame": "sword", "eq_weapon_bow_gale": "bow",
               "eq_weapon_blades_spark": "dual_blades"}
EQUIP = [  # id, slot, rarity, cost, atk, hp, def, crit_rate, crit_dmg, cdr, vi, en
    ("eq_weapon_iron", "weapon", 3, 1, 80.0, 0.0, 0.0, 0.0, 0.0, 0.0, "Lõi vũ khí sắt", "Iron Weapon Core"),
    ("eq_weapon_flame", "weapon", 4, 3, 160.0, 0.0, 0.0, 0.05, 0.0, 0.0, "Lõi vũ khí hỏa tinh", "Flame Weapon Core"),
    ("eq_weapon_bow_gale", "weapon", 3, 1, 75.0, 0.0, 0.0, 0.0, 0.0, 0.0, "Cung gió lốc", "Gale Bow"),
    ("eq_weapon_blades_spark", "weapon", 3, 1, 78.0, 0.0, 0.0, 0.0, 0.0, 0.0, "Song đao tia lửa", "Spark Blades"),
    ("eq_stigma_top_elite", "stigma_top", 3, 2, 30.0, 0.0, 0.0, 0.04, 0.10, 0.0, "Ấn Tinh Anh (Đầu)", "Elite Sigil (Top)"),
    ("eq_stigma_mid_hide", "stigma_mid", 3, 1, 0.0, 900.0, 40.0, 0.0, 0.0, 0.0, "Ấn Da Thú (Thân)", "Hide Sigil (Middle)"),
    ("eq_stigma_mid_guardian", "stigma_mid", 4, 3, 0.0, 1800.0, 90.0, 0.0, 0.0, 0.0, "Ấn Hộ Vệ (Thân)", "Guardian Sigil (Middle)"),
    ("eq_stigma_bot_hourglass", "stigma_bot", 4, 3, 0.0, 400.0, 0.0, 0.0, 0.0, 0.08, "Ấn Đồng Hồ Cát (Chân)", "Hourglass Sigil (Bottom)"),
    # Bộ vết thánh 4★ đề cử cho Aether (banner tiếp tế, owner 2026-11-13) + vết thánh Chân 3★ cho đủ 3 ô ở bậc 3★.
    ("eq_stigma_top_blaze", "stigma_top", 4, 3, 60.0, 0.0, 0.0, 0.06, 0.0, 0.0, "Ấn Viêm Hoàng (Đầu)", "Blaze Sovereign Sigil (Top)"),
    ("eq_stigma_mid_blaze", "stigma_mid", 4, 3, 40.0, 1500.0, 0.0, 0.0, 0.0, 0.0, "Ấn Viêm Hoàng (Thân)", "Blaze Sovereign Sigil (Middle)"),
    ("eq_stigma_bot_blaze", "stigma_bot", 4, 3, 50.0, 0.0, 0.0, 0.0, 0.0, 0.06, "Ấn Viêm Hoàng (Chân)", "Blaze Sovereign Sigil (Bottom)"),
    ("eq_stigma_bot_sandal", "stigma_bot", 3, 1, 0.0, 500.0, 30.0, 0.0, 0.0, 0.0, "Ấn Dép Cỏ (Chân)", "Straw Sandal Sigil (Bottom)"),
]
for eid, slot, rarity, cost, atk, hp, df, cr, cd, cdr, vi, en in EQUIP:
    write("data/equipment/%s.tres" % eid, "equipment_def.gd", "EquipmentDef",
          [("id", eid), ("name_key", "EQUIP_" + eid.upper()), ("slot", slot), ("rarity", rarity),
           ("weapon_type", WEAPON_TYPE.get(eid, "")), ("max_level", 10),
           ("atk", atk), ("max_hp", hp), ("def", df), ("crit_rate", cr), ("crit_damage", cd), ("cdr", cdr),
           ("growth_per_level", 0.1), ("enhance_gold_base", 200 * cost), ("enhance_points_base", 100 * cost)])

EXTRA = [("CURRENCY_GOLD", "Vàng", "Gold"), ("CURRENCY_GEMS", "Ngọc", "Gems"),
         ("SLOT_WEAPON", "Vũ khí", "Weapon"), ("SLOT_STIGMA_TOP", "Vết thánh Đầu", "Stigma (Top)"),
         ("SLOT_STIGMA_MID", "Vết thánh Thân", "Stigma (Middle)"), ("SLOT_STIGMA_BOT", "Vết thánh Chân", "Stigma (Bottom)"),
         ("WEAPON_TYPE_SWORD", "Kiếm", "Sword"), ("WEAPON_TYPE_BOW", "Cung", "Bow"),
         ("WEAPON_TYPE_DUAL_BLADES", "Song đao", "Dual Blades"), ("WEAPON_TYPE_STAFF", "Trượng", "Staff"),
         ("WEAPON_TYPE_SCYTHE", "Lưỡi hái", "Scythe"), ("WEAPON_TYPE_GREATSWORD", "Đại kiếm", "Greatsword")]
for po, idx in (("vi.po", 0), ("en.po", 1)):
    p = os.path.join(ROOT, "localization", po)
    s = io.open(p, encoding="utf-8").read()
    add = ""
    rows = [("ITEM_" + i[0].upper(), i[4], i[5]) for i in ITEMS] + [("EQUIP_" + e[0].upper(), e[10], e[11]) for e in EQUIP] + EXTRA
    for key, vi, en in rows:
        if 'msgid "%s"' % key not in s:
            add += '\nmsgid "%s"\nmsgstr "%s"\n' % (key, (vi, en)[idx])
    if add:
        io.open(p, "w", encoding="utf-8", newline="\n").write(s.rstrip("\n") + "\n\n# Vật phẩm, trang bị (M5)" + add)
print("ok")
