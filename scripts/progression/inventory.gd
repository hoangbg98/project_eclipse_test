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
## Nâng bậc: chưa cường hóa tới giới hạn cấp của bậc hiện tại.
const REASON_NEED_LEVEL := "need_level"
## Tẩy phụ tố: món không có phụ tố / đang có kết quả tẩy chờ chọn / chưa có kết quả để chọn.
const REASON_NO_AFFIX := "no_affix"
const REASON_PENDING := "pending"

var data: Dictionary
var items: DefLibrary        # ItemDef
var equipment: DefLibrary    # EquipmentDef
## Luật bậc cường hóa, phụ tố (PlayerProfile gán). null = không có bậc / phụ tố, giới hạn = EquipmentDef.max_level.
var rules: ProgressionRules
## Định nghĩa phụ tố (AffixDef, PlayerProfile gán). null = vết thánh không có phụ tố.
var affixes: DefLibrary
## Nguồn ngẫu nhiên của phụ tố (test đặt seed để tái lập).
var rng := RandomNumberGenerator.new()


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
	var rolled := roll_affixes(equipment.get_def(def_id) as EquipmentDef)
	if not rolled.is_empty():
		data["inventory"]["equipment"][uid]["affixes"] = rolled
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


# ---------- Bậc cường hóa (owner 2026-11-15) ----------

## Bậc hiện tại của món (0 = chưa nâng).
func equipment_tier(uid: String) -> int:
	return int(data["inventory"]["equipment"][uid].get("tier", 0)) if owns(uid) else 0


func level_caps(uid: String) -> PackedInt32Array:
	var def := equipment_def_of(uid)
	var caps := rules.level_caps_for(def) if rules and def else PackedInt32Array()
	if caps.is_empty() and def:
		caps = PackedInt32Array([def.max_level])
	return caps


## Bậc tối đa (số lần nâng bậc được): vũ khí theo độ hiếm, vết thánh theo stigma_level_caps.
func max_tier(uid: String) -> int:
	return maxi(level_caps(uid).size() - 1, 0)


## Giới hạn cấp cường hóa ở bậc hiện tại (chưa tính cấp người chơi).
func level_cap(uid: String) -> int:
	var caps := level_caps(uid)
	return caps[clampi(equipment_tier(uid), 0, caps.size() - 1)] if not caps.is_empty() else 0


## Giới hạn cấp cao nhất (bậc cuối).
func final_level_cap(uid: String) -> int:
	var caps := level_caps(uid)
	return caps[caps.size() - 1] if not caps.is_empty() else 0


## Cấp người chơi (thủ lĩnh): cấp cường hóa trang bị không vượt quá (owner 2026-11-15).
func captain_level() -> int:
	var a: Variant = data.get("account")
	return int(a.get("level", 1)) if a is Dictionary else 1


## Giá bước nâng bậc kế: {"material": id, "count": n, "gold": g}; rỗng nếu đã tối đa / không nâng được.
func ascend_cost(uid: String) -> Dictionary:
	var t := equipment_tier(uid)
	if rules == null or t >= max_tier(uid) or t >= mini(rules.ascend_material_count.size(), rules.ascend_gold.size()):
		return {}
	return {"material": rules.ascend_material, "count": rules.ascend_material_count[t], "gold": rules.ascend_gold[t]}


## Lý do không nâng bậc được ("" = được). Phải cường hóa tới giới hạn cấp của bậc hiện tại trước.
func check_ascend(uid: String) -> String:
	if equipment_def_of(uid) == null:
		return REASON_NOT_OWNED
	var cost := ascend_cost(uid)
	if cost.is_empty():
		return REASON_MAX_LEVEL
	if equipment_level(uid) < level_cap(uid):
		return REASON_NEED_LEVEL
	if not can_spend("gold", int(cost["gold"])) or material_count(str(cost["material"])) < int(cost["count"]):
		return REASON_NOT_ENOUGH
	return OK_REASON


## Nâng bậc +1: trừ vàng và nguyên liệu, mở giới hạn cấp kế. Thất bại thì không trừ gì.
func ascend(uid: String) -> String:
	var reason := check_ascend(uid)
	if reason != OK_REASON:
		return reason
	var cost := ascend_cost(uid)
	spend_currency("gold", int(cost["gold"]))
	consume_material(str(cost["material"]), int(cost["count"]))
	data["inventory"]["equipment"][uid]["tier"] = equipment_tier(uid) + 1
	changed.emit()
	return OK_REASON


# ---------- Phụ tố vết thánh (owner 2026-11-15) ----------

## Bốc phụ tố cho một vết thánh mới: affix_count_for(độ hiếm) dòng, không trùng loại, theo trọng số.
func roll_affixes(def: EquipmentDef) -> Array:
	var out: Array = []
	if def == null or def.slot == "weapon" or rules == null or affixes == null:
		return out
	var pool: Array = []
	for id in affixes.ids():
		pool.append(affixes.get_def(id))
	var scale := rules.affix_scale_for(def.rarity)
	for i in rules.affix_count_for(def.rarity):
		var total := 0
		for a: AffixDef in pool:
			total += a.weight
		if total <= 0:
			break
		var pick := rng.randi_range(1, total)
		for a: AffixDef in pool:
			pick -= a.weight
			if pick <= 0:
				var v := a.round_value(lerpf(a.min_value, a.max_value, rng.randf()) * scale)
				out.append({"id": a.id, "value": v})
				pool.erase(a)
				break
	return out


## Gieo phụ tố cho vết thánh chưa có (save cũ). Trả về số món đã gieo.
func ensure_affixes() -> int:
	var n := 0
	for uid in equipment_uids():
		var e: Dictionary = data["inventory"]["equipment"][uid]
		if e.has("affixes"):
			continue
		var rolled := roll_affixes(equipment_def_of(uid))
		if not rolled.is_empty():
			e["affixes"] = rolled
			n += 1
	return n


## Phụ tố của món: mảng {"id", "value"} (bỏ dòng có id lạ).
func affixes_of(uid: String) -> Array:
	return _valid_affixes(data["inventory"]["equipment"][uid].get("affixes", []) if owns(uid) else [])


## Kết quả tẩy đang chờ chọn (rỗng = không có).
func pending_affixes(uid: String) -> Array:
	return _valid_affixes(data["inventory"]["equipment"][uid].get("affix_pending", []) if owns(uid) else [])


func _valid_affixes(arr: Variant) -> Array:
	var out: Array = []
	if not (arr is Array) or affixes == null:
		return out
	for a: Variant in arr:
		if a is Dictionary and affixes.has(str(a.get("id", ""))):
			out.append(a)
	return out


## Số đá tẩy cho một lần tẩy món này.
func reroll_cost(uid: String) -> int:
	var def := equipment_def_of(uid)
	return rules.affix_reroll_cost_for(def.rarity) if rules and def else 0


func check_reroll(uid: String) -> String:
	var def := equipment_def_of(uid)
	if def == null:
		return REASON_NOT_OWNED
	if rules == null or affixes_of(uid).is_empty():
		return REASON_NO_AFFIX
	if not pending_affixes(uid).is_empty():
		return REASON_PENDING
	if material_count(rules.affix_reroll_material) < reroll_cost(uid):
		return REASON_NOT_ENOUGH
	return OK_REASON


## Tẩy phụ tố: trừ đá, bốc bộ phụ tố mới vào "affix_pending"; người chơi chọn giữ mới / cũ bằng `confirm_reroll`.
func reroll_affixes(uid: String) -> String:
	var reason := check_reroll(uid)
	if reason != OK_REASON:
		return reason
	consume_material(rules.affix_reroll_material, reroll_cost(uid))
	data["inventory"]["equipment"][uid]["affix_pending"] = roll_affixes(equipment_def_of(uid))
	changed.emit()
	return OK_REASON


## Chọn kết quả tẩy: `keep_new` = thay bằng phụ tố mới; false = giữ phụ tố cũ. Đá đã tiêu khi tẩy.
func confirm_reroll(uid: String, keep_new: bool) -> String:
	if pending_affixes(uid).is_empty():
		return REASON_INVALID
	var e: Dictionary = data["inventory"]["equipment"][uid]
	if keep_new:
		e["affixes"] = e["affix_pending"]
	e.erase("affix_pending")
	changed.emit()
	return OK_REASON


## Tổng phụ tố của các món nhân vật đang mặc: stat → giá trị.
func affix_bonus(character_id: String) -> Dictionary:
	var out := {}
	if not data["characters"].has(character_id):
		return out
	for slot in data["characters"][character_id]["equipment"]:
		var uid := str(data["characters"][character_id]["equipment"][slot])
		for a: Dictionary in affixes_of(uid):
			var d := affixes.get_def(str(a["id"])) as AffixDef
			out[d.stat] = float(out.get(d.stat, 0.0)) + float(a["value"])
	return out


## Lý do không cường hóa được lên cấp kế bằng nguyên liệu `material_id` ("" = được).
func check_enhance(uid: String, material_id: String) -> String:
	var def := equipment_def_of(uid)
	if def == null:
		return REASON_NOT_OWNED
	var level := equipment_level(uid)
	if level >= level_cap(uid):
		return REASON_MAX_LEVEL
	if level >= captain_level():
		return REASON_LEVEL_CAP
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
	var out := EquipmentResolver.resolve(character_id, element, equipped_defs(character_id))
	# Phụ tố dạng % (all_dmg, elem_dmg, atk_pct...) vào chỉ số của người đeo; dạng cộng thẳng ở equipped_bonus.
	var bonus := affix_bonus(character_id)
	for st: String in bonus:
		if st not in AffixDef.FLAT_STATS:
			out.stats[st] = float(out.stats.get(st, 0.0)) + float(bonus[st])
	return out


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
		var m := def.flat_multiplier(equipment_level(uid), final_level_cap(uid))
		out["atk"] += def.atk * m
		out["max_hp"] += def.max_hp * m
		out["def"] += def.def * m
		out["crit_rate"] += def.crit_rate
		out["crit_damage"] += def.crit_damage
		out["cdr"] += def.cdr
	var bonus := affix_bonus(character_id)
	for st: String in bonus:
		if out.has(st):
			out[st] += float(bonus[st])
	return out
