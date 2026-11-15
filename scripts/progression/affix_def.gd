class_name AffixDef
extends Resource
## Một loại phụ tố ngẫu nhiên của vết thánh (owner 2026-11-15). Data: data/equipment/affixes/{id}.tres.
## Giá trị một dòng = ngẫu nhiên trong [min_value, max_value] × ProgressionRules.affix_scale_for(độ hiếm), làm tròn.
## Chỉ số cộng thẳng (FLAT_STATS) vào Inventory.equipped_bonus; còn lại là khóa EquipEffect.STATS, vào Loadout.stats.

const FLAT_STATS := ["atk", "max_hp", "def", "crit_rate", "crit_damage", "cdr"]
## Các khóa hiển thị dạng % (tỉ lệ 0..1).
const PERCENT_STATS := ["crit_rate", "crit_damage", "cdr"]

@export var id := ""
@export var name_key := ""
## Khóa chỉ số: một trong FLAT_STATS hoặc EquipEffect.STATS.
@export var stat := ""
@export var min_value := 0.0
@export var max_value := 0.0
## Trọng số khi bốc (cao = hay ra hơn).
@export var weight := 10


func is_flat() -> bool:
	return stat in FLAT_STATS


func is_percent() -> bool:
	return stat in PERCENT_STATS or not is_flat()


## Làm tròn: số nguyên cho chỉ số cộng thẳng (atk, max_hp, def), 0.1% cho tỉ lệ.
func round_value(v: float) -> float:
	return roundf(v * 1000.0) / 1000.0 if is_percent() else roundf(v)


## Chữ giá trị, vd "+45" hoặc "+4.5%".
func value_text(v: float) -> String:
	if is_percent():
		return "+" + ("%.1f" % (v * 100.0)).trim_suffix(".0") + "%"
	return "+%d" % roundi(v)


func validate() -> PackedStringArray:
	var e := PackedStringArray()
	if id.is_empty():
		e.append("thiếu id")
	if name_key.is_empty() or name_key != name_key.to_upper():
		e.append("%s: name_key phải là khóa UPPER_SNAKE" % id)
	if stat not in FLAT_STATS and stat not in EquipEffect.STATS:
		e.append("%s: stat lạ '%s'" % [id, stat])
	if min_value <= 0.0 or max_value < min_value:
		e.append("%s: cần 0 < min_value <= max_value" % id)
	if weight <= 0:
		e.append("%s: weight phải > 0" % id)
	return e
