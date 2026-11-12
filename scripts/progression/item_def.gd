class_name ItemDef
extends Resource
## Nguyên liệu / vật phẩm tiêu hao (data/items/{id}.tres). Số lượng người chơi có nằm trong save (inventory.materials).

enum Kind { EXP, ENHANCE, MISC }

@export var id := ""
@export var name_key := ""
@export var kind := Kind.MISC
## EXP cho nhân vật (Kind.EXP) hoặc điểm cường hóa (Kind.ENHANCE) mỗi món.
@export var value := 0
@export_range(1, 5) var rarity := 1


func validate() -> PackedStringArray:
	var e := PackedStringArray()
	if id.is_empty():
		e.append("thiếu id")
	if name_key.is_empty() or name_key != name_key.to_upper():
		e.append("%s: name_key phải là khóa UPPER_SNAKE" % id)
	if kind != Kind.MISC and value <= 0:
		e.append("%s: value phải > 0" % id)
	return e
