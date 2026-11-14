class_name PlayerProfile
extends RefCounted
## Gom Inventory + Progression trên một bản dữ liệu save, dùng định nghĩa tĩnh từ data/ (M5-2, M5-3).
## UI và màn chơi tạo một PlayerProfile từ `SaveService.data` khi cần; lớp này không tự ghi file.

const RULES_PATH := "res://data/config/progression.tres"
const ITEMS_DIR := "res://data/items"
const EQUIPMENT_DIR := "res://data/equipment"
const BACKGROUNDS_DIR := "res://data/backgrounds"
const CHARACTER_DATA := "res://data/characters/%s.tres"

var data: Dictionary
var rules: ProgressionRules
var inventory: Inventory
var progression: Progression

static var _items: DefLibrary
static var _equipment: DefLibrary
static var _backgrounds: DefLibrary


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


# ---------- Nền sảnh chính (owner 2026-11-14) ----------

const BG_OK := ""
const BG_UNKNOWN := "bg_unknown"
const BG_NOT_OWNED := "bg_not_owned"
const BG_OWNED := "bg_owned"
const BG_NOT_FOR_SALE := "bg_not_for_sale"
const BG_NO_GEMS := "bg_no_gems"


static func background_defs() -> DefLibrary:
	if _backgrounds == null:
		_backgrounds = DefLibrary.load_dir(BACKGROUNDS_DIR)
	return _backgrounds


func _cosmetics() -> Dictionary:
	if not (data.get("cosmetics") is Dictionary):
		data["cosmetics"] = {"backgrounds": [], "hub_background": ""}
	return data["cosmetics"]


## Mọi nền theo thứ tự hiển thị (sort_order rồi id).
func all_backgrounds() -> Array[BackgroundDef]:
	var out: Array[BackgroundDef] = []
	for id in background_defs().ids():
		var b := background_defs().get_def(id) as BackgroundDef
		if b:
			out.append(b)
	out.sort_custom(func(a: BackgroundDef, b: BackgroundDef) -> bool:
		return a.id < b.id if a.sort_order == b.sort_order else a.sort_order < b.sort_order)
	return out


func owns_background(id: String) -> bool:
	var b := background_defs().get_def(id) as BackgroundDef
	if b == null:
		return false
	return b.source == BackgroundDef.Source.STARTER or id in _cosmetics()["backgrounds"]


## Nền đang dùng: nền đã chọn nếu còn sở hữu, không thì nền starter đầu tiên ("" nếu data không có nền nào).
func hub_background() -> String:
	var sel := str(_cosmetics().get("hub_background", ""))
	if sel != "" and owns_background(sel):
		return sel
	for b in all_backgrounds():
		if b.source == BackgroundDef.Source.STARTER:
			return b.id
	return ""


func set_hub_background(id: String) -> String:
	if background_defs().get_def(id) == null:
		return BG_UNKNOWN
	if not owns_background(id):
		return BG_NOT_OWNED
	_cosmetics()["hub_background"] = id
	return BG_OK


## Mở khóa nền (phần thưởng sự kiện, quà). Trả về false nếu không có nền đó hoặc đã có.
func unlock_background(id: String) -> bool:
	if background_defs().get_def(id) == null or owns_background(id):
		return false
	(_cosmetics()["backgrounds"] as Array).append(id)
	return true


## Mua nền bằng ngọc (giá trong BackgroundDef.price_gems). Thiếu ngọc thì không trừ gì.
func buy_background(id: String) -> String:
	var b := background_defs().get_def(id) as BackgroundDef
	if b == null:
		return BG_UNKNOWN
	if owns_background(id):
		return BG_OWNED
	if b.price_gems <= 0:
		return BG_NOT_FOR_SALE
	if not inventory.spend_currency("gems", b.price_gems):
		return BG_NO_GEMS
	unlock_background(id)
	return BG_OK


const NAME_OK := ""
const NAME_EMPTY := "name_empty"
const NAME_TOO_LONG := "name_too_long"
const NAME_SAME := "name_same"


## Tên người chơi ("" nếu chưa đặt; UI hiện tên mặc định PLAYER_DEFAULT_NAME).
func player_name() -> String:
	return str(data["account"].get("name", ""))


## Đổi tên người chơi; trả về lý do ("" = được). Tên được làm sạch (SaveSchema.clean_name) trước khi kiểm tra.
func set_player_name(raw: String) -> String:
	var n := SaveSchema.clean_name(raw)
	if n.is_empty():
		return NAME_EMPTY
	if raw.strip_edges().length() > SaveSchema.NAME_MAX:
		return NAME_TOO_LONG
	if n == player_name():
		return NAME_SAME
	data["account"]["name"] = n
	return NAME_OK


## Đội hiện tại (ID theo thứ tự).
func party_ids() -> PackedStringArray:
	return PackedStringArray(data["party"])


## Chỉ số cuối cùng của một nhân vật đang sở hữu (cấp + trang bị); chưa sở hữu thì trả chỉ số gốc cấp 1.
func stats_of(character_id: String) -> CombatStats:
	var path := CHARACTER_DATA % character_id
	if not ResourceLoader.exists(path):
		return CombatStats.new()
	return progression.stats_for(load(path) as CharacterDef)


## Hiệu ứng trang bị đã gom của một nhân vật (cho PartyManager.loadout_provider).
func loadout_of(character_id: String) -> EquipmentResolver.Loadout:
	var path := CHARACTER_DATA % character_id
	var d := load(path) as CharacterDef if ResourceLoader.exists(path) else null
	return inventory.loadout_of(character_id, d.element if d else "")


## Cấp kỹ năng theo SkillDef.key của một nhân vật (cho PartyManager.skill_levels_provider).
func skill_levels_of(character_id: String) -> Dictionary:
	return progression.skill_levels_by_key(character_id)


## Đặt đội (1–3 nhân vật đang sở hữu, không trùng). Trả về false và giữ nguyên nếu không hợp lệ.
## Nhân vật (person_id) mà giáp `character_id` thuộc về; đọc CharacterDef một lần rồi nhớ (test có thể điền sẵn).
var person_cache := {}


func person_of(character_id: String) -> String:
	if not person_cache.has(character_id):
		var p := CHARACTER_DATA % character_id
		var d := load(p) as CharacterDef if ResourceLoader.exists(p) else null
		person_cache[character_id] = d.person() if d else character_id
	return person_cache[character_id]


func set_party(ids: Array) -> bool:
	if ids.is_empty() or ids.size() > 3:
		return false
	var seen := {}
	var persons := {}
	for id in ids:
		if not progression.owns(str(id)) or seen.has(str(id)):
			return false
		seen[str(id)] = true
		# Hai giáp của cùng một nhân vật không ra trận cùng lúc.
		var p := person_of(str(id))
		if persons.has(p):
			return false
		persons[p] = true
	data["party"] = ids.duplicate()
	return true


const PARTY_OK := "ok"
const PARTY_LAST := "party_last"
const PARTY_FULL := "party_full"
const PARTY_SAME_PERSON := "party_same_person"
const PARTY_NOT_OWNED := "party_not_owned"


## Thêm (xuống cuối) / bỏ một giáp khỏi đội. Không bỏ được người cuối cùng; đội đủ 3 thì không thêm;
## không thêm giáp khác của nhân vật đã có trong đội. Trả về PARTY_*.
func toggle_party(id: String) -> String:
	var party := Array(party_ids())
	if id in party:
		if party.size() <= 1:
			return PARTY_LAST
		party.erase(id)
	else:
		if not progression.owns(id):
			return PARTY_NOT_OWNED
		if party.size() >= 3:
			return PARTY_FULL
		for other: String in party:
			if person_of(other) == person_of(id):
				return PARTY_SAME_PERSON
		party.append(id)
	return PARTY_OK if set_party(party) else PARTY_NOT_OWNED


## Thêm giáp vừa nhận vào cuối đội nếu đội còn chỗ và chưa có giáp nào của cùng nhân vật. Trả về true nếu đã thêm.
func join_party_if_room(id: String) -> bool:
	var party := Array(party_ids())
	if id in party or party.size() >= 3 or not progression.owns(id):
		return false
	for other: String in party:
		if person_of(other) == person_of(id):
			return false
	party.append(id)
	return set_party(party)


## Nhận thưởng: {"gold": n, "gems": n, "materials": {id: n}, "equipment": [def_id], "characters": [char_id],
## "exp": {char_id: n} | n cho cả đội}. Nhân vật mới vào đội luôn nếu còn chỗ.
## Trả về bản tóm tắt những gì đã nhận thật (để màn kết quả hiển thị).
func grant(reward: Dictionary) -> Dictionary:
	var got := {"gold": 0, "gems": 0, "materials": {}, "equipment": [], "characters": [], "levels": {}, "captain_levels": 0}
	for id in reward.get("characters", []):
		if progression.unlock(str(id)):
			got["characters"].append(str(id))
			join_party_if_room(str(id))
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
