class_name EquipmentDef
extends Resource
## Định nghĩa một món trang bị (data/equipment/{id}.tres). Món người chơi sở hữu nằm trong save
## (inventory.equipment: uid → {def_id, level}); cấp cường hóa bắt đầu từ 0.

## Mỗi nhân vật: 1 vũ khí + 3 vết thánh theo thứ tự Đầu / Thân / Chân (owner, 2026-11-12).
## Vết thánh chỉ cộng chỉ số và có ảnh minh họa; không đổi ngoại hình / giáp của nhân vật.
const SLOTS: Array[String] = ["weapon", "stigma_top", "stigma_mid", "stigma_bot"]
const STIGMA_SLOTS: Array[String] = ["stigma_top", "stigma_mid", "stigma_bot"]

@export var id := ""
@export var name_key := ""
@export_enum("weapon", "stigma_top", "stigma_mid", "stigma_bot") var slot := "weapon"
@export_range(1, 5) var rarity := 1
## Chỉ vũ khí: loại (khớp CharacterDef.weapon_type). Rỗng = nhân vật nào cũng dùng được.
@export var weapon_type := ""
## Ảnh minh họa (vũ khí, vết thánh). Rỗng = ảnh placeholder. Không đổi ngoại hình nhân vật khi mặc.
@export_file("*.png", "*.webp", "*.jpg") var art := ""
@export var max_level := 10

@export_group("Hiệu ứng (EQUIPMENT_5STAR.md)")
## Giáp chủ sở hữu (Data ID, owner Q1). Rỗng = không có phần độc quyền.
@export var owner_id := ""
## Vết thánh: id bộ (StigmaSetDef trong data/equipment/sets/). Rỗng = không thuộc bộ nào.
@export var set_id := ""
## Hiệu ứng riêng của món (phần chung + phần độc quyền). Cố định, không tăng theo cường hóa (owner Q8).
@export var effects: Array[EquipEffect] = []

@export_group("Chỉ số cộng ở cấp 0")
@export var atk := 0.0
@export var max_hp := 0.0
@export var def := 0.0
@export_range(0.0, 1.0) var crit_rate := 0.0
@export var crit_damage := 0.0
@export_range(0.0, 1.0) var cdr := 0.0

@export_group("Cường hóa")
## Mỗi cấp cường hóa tăng bấy nhiêu % các chỉ số cộng thẳng (atk, max_hp, def).
@export var growth_per_level := 0.10
## Vàng để lên cấp L + 1 = enhance_gold_base × (L + 1).
@export var enhance_gold_base := 200
## Điểm cường hóa (từ nguyên liệu Kind.ENHANCE) để lên cấp L + 1 = enhance_points_base × (L + 1).
@export var enhance_points_base := 100


## Hệ số chỉ số cộng thẳng ở cấp cường hóa `level`. `cap` âm = giới hạn `max_level`; vũ khí đã nâng bậc truyền
## giới hạn mới (Inventory.level_cap).
func flat_multiplier(level: int, cap := -1) -> float:
	return 1.0 + growth_per_level * float(clampi(level, 0, cap if cap >= 0 else max_level))


func gold_to_enhance(level: int) -> int:
	return enhance_gold_base * (level + 1)


func points_to_enhance(level: int) -> int:
	return enhance_points_base * (level + 1)


func validate() -> PackedStringArray:
	var e := PackedStringArray()
	if id.is_empty():
		e.append("thiếu id")
	if name_key.is_empty() or name_key != name_key.to_upper():
		e.append("%s: name_key phải là khóa UPPER_SNAKE" % id)
	if slot not in SLOTS:
		e.append("%s: slot lạ '%s'" % [id, slot])
	if max_level < 0 or growth_per_level < 0.0:
		e.append("%s: max_level / growth không được âm" % id)
	if not set_id.is_empty() and slot == "weapon":
		e.append("%s: vũ khí không thuộc bộ vết thánh" % id)
	for i in effects.size():
		if effects[i] == null:
			e.append("%s: effects[%d] rỗng" % [id, i])
			continue
		e.append_array(effects[i].validate("%s.effects[%d]" % [id, i]))
		if effects[i].exclusive and owner_id.is_empty():
			e.append("%s: hiệu ứng độc quyền cần owner_id" % id)
	if atk == 0.0 and max_hp == 0.0 and def == 0.0 and crit_rate == 0.0 and crit_damage == 0.0 and cdr == 0.0:
		e.append("%s: không cộng chỉ số nào" % id)
	return e
