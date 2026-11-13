class_name PlayerProfile
extends RefCounted
## Gom Inventory + Progression trên một bản dữ liệu save, dùng định nghĩa tĩnh từ data/ (M5-2, M5-3).
## UI và màn chơi tạo một PlayerProfile từ `SaveService.data` khi cần; lớp này không tự ghi file.

const RULES_PATH := "res://data/config/progression.tres"
const ITEMS_DIR := "res://data/items"
const EQUIPMENT_DIR := "res://data/equipment"
const CHARACTER_DATA := "res://data/characters/%s.tres"

var data: Dictionary
var rules: ProgressionRules
var inventory: Inventory
var progression: Progression

static var _items: DefLibrary
static var _equipment: DefLibrary


func _init(save_data: Dictionary) -> void:
	data = save_data
	rules = load(RULES_PATH)
	inventory = Inventory.new(data, item_defs(), equipment_defs())
	progression = Progression.new(data, rules, inventory)


static func item_defs() -> DefLibrary:
	if _items == null:
		_items = DefLibrary.load_dir(ITEMS_DIR)
	return _items


static func equipment_defs() -> DefLibrary:
	if _equipment == null:
		_equipment = DefLibrary.load_dir(EQUIPMENT_DIR)
	return _equipment


## Đội hiện tại (ID theo thứ tự).
func party_ids() -> PackedStringArray:
	return PackedStringArray(data["party"])


## Chỉ số cuối cùng của một nhân vật đang sở hữu (cấp + trang bị); chưa sở hữu thì trả chỉ số gốc cấp 1.
func stats_of(character_id: String) -> CombatStats:
	var path := CHARACTER_DATA % character_id
	if not ResourceLoader.exists(path):
		return CombatStats.new()
	return progression.stats_for(load(path) as CharacterDef)


## Cấp kỹ năng theo SkillDef.key của một nhân vật (cho PartyManager.skill_levels_provider).
func skill_levels_of(character_id: String) -> Dictionary:
	return progression.skill_levels_by_key(character_id)


## Đặt đội (1–3 nhân vật đang sở hữu, không trùng). Trả về false và giữ nguyên nếu không hợp lệ.
func set_party(ids: Array) -> bool:
	if ids.is_empty() or ids.size() > 3:
		return false
	var seen := {}
	for id in ids:
		if not progression.owns(str(id)) or seen.has(str(id)):
			return false
		seen[str(id)] = true
	data["party"] = ids.duplicate()
	return true


## Nhận thưởng: {"gold": n, "gems": n, "materials": {id: n}, "equipment": [def_id], "exp": {char_id: n} | n cho cả đội}.
## Trả về bản tóm tắt những gì đã nhận thật (để màn kết quả hiển thị).
func grant(reward: Dictionary) -> Dictionary:
	var got := {"gold": 0, "gems": 0, "materials": {}, "equipment": [], "levels": {}, "captain_levels": 0}
	# EXP đội trưởng trước: cấp đội trưởng là giới hạn cấp nhân vật.
	if int(reward.get("captain_exp", 0)) > 0:
		got["captain_levels"] = progression.add_captain_exp(int(reward["captain_exp"]))
	for cur in ["gold", "gems"]:
		var n := int(reward.get(cur, 0))
		if n > 0 and inventory.add_currency(cur, n):
			got[cur] = n
	var mats: Dictionary = reward.get("materials", {})
	for id in mats:
		if inventory.add_material(str(id), int(mats[id])):
			got["materials"][str(id)] = int(mats[id])
	for def_id in reward.get("equipment", []):
		var uid := inventory.add_equipment(str(def_id))
		if uid != "":
			got["equipment"].append(uid)
	var xp: Variant = reward.get("exp", 0)
	if xp is Dictionary:
		for id in xp:
			var up := progression.add_exp(str(id), int(xp[id]))
			if up > 0:
				got["levels"][str(id)] = up
	elif int(xp) > 0:
		for id in data["party"]:
			var up := progression.add_exp(str(id), int(xp))
			if up > 0:
				got["levels"][str(id)] = up
	return got
