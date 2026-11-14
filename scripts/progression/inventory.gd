class_name Inventory
extends RefCounted
## Kho đồ của người chơi: tiền, nguyên liệu, trang bị (M5-2, M5-3). Thao tác trực tiếp trên dữ liệu save
## (SaveSchema) được truyền vào; không tự ghi file (người gọi quyết định lúc `SaveService.save_game()`).
## Mọi thao tác trả về false / lý do khi không hợp lệ và KHÔNG thay đổi gì trong trường hợp đó.

signal changed

const OK_REASON := ""
const REASON_UNKNOWN_ITEM := "unknown_item"
const REASON_NOT_ENOUGH := "not_enough"
const REASON_NOT_OWNED := "not_owned"
const REASON_UNKNOWN_CHARACTER := "unknown_character"
const REASON_MAX_LEVEL := "max_level"
const REASON_INVALID := "invalid"
const REASON_LEVEL_CAP := "level_cap"
const REASON_WRONG_WEAPON := "wrong_weapon"

var data: Dictionary
var items: DefLibrary        # ItemDef
var equipment: DefLibrary    # EquipmentDef


func _init(save_data: Dictionary, item_defs: DefLibrary, equipment_defs: DefLibrary) -> void:
	data = save_data
	items = item_defs
	equipment = equipment_defs


# ---------- Tiền ----------

func currency(id: String) -> int:
	return int(data["currencies"].get(id, 0))


func add_currency(id: String, amount: int) -> bool:
	if amount < 0 or not data["currencies"].has(id):
		return false
	data["currencies"][id] = currency(id) + amount
	changed.emit()
	return true


func can_spend(id: String, amount: int) -> bool:
	return amount >= 0 and data["currencies"].has(id) and currency(id) >= amount


## Trừ tiền nếu đủ; thiếu thì giữ nguyên và trả về false.
func spend_currency(id: String, amount: int) -> bool:
	if not can_spend(id, amount):
		return false
	data["currencies"][id] = currency(id) - amount
	changed.emit()
	return true


# ---------- Nguyên liệu ----------

func material_count(id: String) -> int:
	return int(data["inventory"]["materials"].get(id, 0))


func add_material(id: String, count: int) -> bool:
	if count <= 0 or not items.has(id):
		return false
	data["inventory"]["materials"][id] = material_count(id) + count
	changed.emit()
	return true


func consume_material(id: String, count: int) -> bool:
	if count <= 0 or material_count(id) < count:
		return false
	var left := material_count(id) - count
	if left > 0:
		data["inventory"]["materials"][id] = left
	else:
		data["inventory"]["materials"].erase(id)
	changed.emit()
	return true


# ---------- Trang bị ----------

## Thêm một món mới (cấp 0); trả về uid, hoặc "" nếu không có định nghĩa.
func add_equipment(def_id: String) -> String:
	if not equipment.has(def_id):
		return ""
	var uid := str(int(data["inventory"]["next_uid"]))
	data["inventory"]["next_uid"] = int(uid) + 1
	data["inventory"]["equipment"][uid] = {"def_id": def_id, "level": 0}
	changed.emit()
	return uid


func owns(uid: String) -> bool:
	return data["inventory"]["equipment"].has(uid)


func equipment_def_of(uid: String) -> EquipmentDef:
	return equipment.get_def(str(data["inventory"]["equipment"][uid]["def_id"])) as EquipmentDef if owns(uid) else null


func equipment_level(uid: String) -> int:
	return int(data["inventory"]["equipment"][uid].get("level", 0)) if owns(uid) else 0


## Đang có ít nhất một món theo định nghĩa `def_id`.
func owns_def(def_id: String) -> bool:
	for uid in data["inventory"]["equipment"]:
		if str(data["inventory"]["equipment"][uid]["def_id"]) == def_id:
			return true
	return false


func equipment_uids() -> PackedStringArray:
	return PackedStringArray(data["inventory"]["equipment"].keys())


## Nhân vật đang mặc món này ("" nếu không ai mặc).
func equipped_by(uid: String) -> String:
	for cid in data["characters"]:
		for slot in data["characters"][cid]["equipment"]:
			if str(data["characters"][cid]["equipment"][slot]) == uid:
				return cid
	return ""


func equipped_uid(character_id: String, slot: String) -> String:
	if not data["characters"].has(character_id):
		return ""
	return str(data["characters"][character_id]["equipment"].get(slot, ""))


## Mặc món `uid` cho nhân vật (ô theo định nghĩa món). Món đang ở ô đó được tháo ra;
## nếu món đang được nhân vật khác mặc thì chuyển sang nhân vật này. Trả về lý do ("" = được).
func equip(character_id: String, uid: String) -> String:
	if not data["characters"].has(character_id):
		return REASON_UNKNOWN_CHARACTER
	var def := equipment_def_of(uid)
	if def == null:
		return REASON_NOT_OWNED
	if def.slot == "weapon" and def.weapon_type != "":
		var cdef := load(PlayerProfile.CHARACTER_DATA % character_id) as CharacterDef if ResourceLoader.exists(PlayerProfile.CHARACTER_DATA % character_id) else null
		if cdef and cdef.weapon_type != "" and cdef.weapon_type != def.weapon_type:
			return REASON_WRONG_WEAPON
	var prev := equipped_by(uid)
	if prev != "":
		data["characters"][prev]["equipment"].erase(def.slot)
	data["characters"][character_id]["equipment"][def.slot] = uid
	changed.emit()
	return OK_REASON


func unequip(character_id: String, slot: String) -> bool:
	if not data["characters"].has(character_id) or not data["characters"][character_id]["equipment"].has(slot):
		return false
	data["characters"][character_id]["equipment"].erase(slot)
	changed.emit()
	return true


## Xóa món khỏi kho (tháo khỏi nhân vật nếu đang mặc).
func remove_equipment(uid: String) -> bool:
	if not owns(uid):
		return false
	var def := equipment_def_of(uid)
	var who := equipped_by(uid)
	if who != "" and def:
		data["characters"][who]["equipment"].erase(def.slot)
	data["inventory"]["equipment"].erase(uid)
	changed.emit()
	return true


## Lý do không cường hóa được lên cấp kế bằng nguyên liệu `material_id` ("" = được).
func check_enhance(uid: String, material_id: String) -> String:
	var def := equipment_def_of(uid)
	if def == null:
		return REASON_NOT_OWNED
	var level := equipment_level(uid)
	if level >= def.max_level:
		return REASON_MAX_LEVEL
	var mat := items.get_def(material_id) as ItemDef
	if mat == null or mat.kind != ItemDef.Kind.ENHANCE:
		return REASON_UNKNOWN_ITEM
	if not can_spend("gold", def.gold_to_enhance(level)):
		return REASON_NOT_ENOUGH
	if material_count(material_id) < materials_to_enhance(uid, material_id):
		return REASON_NOT_ENOUGH
	return OK_REASON


## Số nguyên liệu cần để lên cấp kế (làm tròn lên theo điểm mỗi món).
func materials_to_enhance(uid: String, material_id: String) -> int:
	var def := equipment_def_of(uid)
	var mat := items.get_def(material_id) as ItemDef
	if def == null or mat == null or mat.value <= 0:
		return 0
	return int(ceil(float(def.points_to_enhance(equipment_level(uid))) / float(mat.value)))


## Cường hóa +1 cấp: trừ vàng và nguyên liệu. Trả về lý do ("" = thành công); thất bại thì không trừ gì.
func enhance(uid: String, material_id: String) -> String:
	var reason := check_enhance(uid, material_id)
	if reason != OK_REASON:
		return reason
	var def := equipment_def_of(uid)
	var level := equipment_level(uid)
	var need := materials_to_enhance(uid, material_id)
	spend_currency("gold", def.gold_to_enhance(level))
	consume_material(material_id, need)
	data["inventory"]["equipment"][uid]["level"] = level + 1
	changed.emit()
	return OK_REASON


## Định nghĩa các món nhân vật đang mặc (bỏ qua món mất / sai ô).
func equipped_defs(character_id: String) -> Array[EquipmentDef]:
	var out: Array[EquipmentDef] = []
	if not data["characters"].has(character_id):
		return out
	for slot in data["characters"][character_id]["equipment"]:
		var def := equipment_def_of(str(data["characters"][character_id]["equipment"][slot]))
		if def and def.slot == slot:
			out.append(def)
	return out


## Hiệu ứng trang bị đã gom cho nhân vật (EquipmentResolver). `element` = nguyên tố của giáp.
func loadout_of(character_id: String, element: String) -> EquipmentResolver.Loadout:
	return EquipmentResolver.resolve(character_id, element, equipped_defs(character_id))


## Tổng chỉ số cộng từ trang bị đang mặc: {atk, max_hp, def, crit_rate, crit_damage, cdr}.
func equipped_bonus(character_id: String) -> Dictionary:
	var out := {"atk": 0.0, "max_hp": 0.0, "def": 0.0, "crit_rate": 0.0, "crit_damage": 0.0, "cdr": 0.0}
	if not data["characters"].has(character_id):
		return out
	for slot in data["characters"][character_id]["equipment"]:
		var uid := str(data["characters"][character_id]["equipment"][slot])
		var def := equipment_def_of(uid)
		if def == null or def.slot != slot:
			continue   # món không còn trong kho / sai ô: bỏ qua, không crash
		var m := def.flat_multiplier(equipment_level(uid))
		out["atk"] += def.atk * m
		out["max_hp"] += def.max_hp * m
		out["def"] += def.def * m
		out["crit_rate"] += def.crit_rate
		out["crit_damage"] += def.crit_damage
		out["cdr"] += def.cdr
	return out
