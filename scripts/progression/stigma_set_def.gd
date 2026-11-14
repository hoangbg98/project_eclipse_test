class_name StigmaSetDef
extends Resource
## Bộ vết thánh (data/equipment/sets/{id}.tres): hiệu ứng khi đeo 2 món và 3 món cùng bộ (Đầu / Thân / Chân).
## Bộ 5★ có phần chung + phần độc quyền; bộ 4★ chỉ có phần chung, số khoảng một nửa (owner 2026-11-14, Q9).

@export var id := ""
@export var name_key := ""
@export_range(1, 5) var rarity := 5
## Giáp chủ sở hữu (Data ID). Rỗng = bộ không có phần độc quyền.
@export var owner_id := ""
@export var element := ""
@export var bonus_2: Array[EquipEffect] = []
@export var bonus_3: Array[EquipEffect] = []


func effects_for(count: int) -> Array[EquipEffect]:
	var out: Array[EquipEffect] = []
	if count >= 2:
		out.append_array(bonus_2)
	if count >= 3:
		out.append_array(bonus_3)
	return out


func validate() -> PackedStringArray:
	var e := PackedStringArray()
	if id.is_empty():
		e.append("bộ vết thánh thiếu id")
	if name_key.is_empty() or name_key != name_key.to_upper():
		e.append("%s: name_key phải là khóa UPPER_SNAKE" % id)
	for i in bonus_2.size():
		e.append_array(bonus_2[i].validate("%s.bonus_2[%d]" % [id, i]))
		if bonus_2[i].exclusive and owner_id.is_empty():
			e.append("%s: hiệu ứng độc quyền cần owner_id" % id)
	for i in bonus_3.size():
		e.append_array(bonus_3[i].validate("%s.bonus_3[%d]" % [id, i]))
		if bonus_3[i].exclusive and owner_id.is_empty():
			e.append("%s: hiệu ứng độc quyền cần owner_id" % id)
	return e
