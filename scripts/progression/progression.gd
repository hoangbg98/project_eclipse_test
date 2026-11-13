class_name Progression
extends RefCounted
## Cấp và EXP của nhân vật + chỉ số cuối cùng (gốc × cấp + trang bị) (M5-2, M5-3).
## Thao tác trên dữ liệu save được truyền vào; không tự ghi file.

signal leveled_up(character_id: String, from_level: int, to_level: int)
signal changed

## Nhóm kỹ năng nâng cấp được → các `SkillDef.key` thuộc nhóm (cây skill ở màn Nhân vật).
## Nội tại (passive) không có cấp.
const SKILL_GROUPS := {
	"normal": ["normal"],
	"special": ["hold", "air", "landing"],
	"dodge": ["dodge"],
	"skill": ["skill"],
	"weapon": ["weapon"],
	"ultimate": ["ultimate"],
	"switch_in": ["switch_in"],
}

var data: Dictionary
var rules: ProgressionRules
var inventory: Inventory


func _init(save_data: Dictionary, progression_rules: ProgressionRules, inv: Inventory) -> void:
	data = save_data
	rules = progression_rules
	inventory = inv


func owns(character_id: String) -> bool:
	return data["characters"].has(character_id)


func level_of(character_id: String) -> int:
	return clampi(int(data["characters"][character_id]["level"]), 1, rules.max_level) if owns(character_id) else 1


func exp_of(character_id: String) -> int:
	return int(data["characters"][character_id]["exp"]) if owns(character_id) else 0


func is_max_level(character_id: String) -> bool:
	return level_of(character_id) >= rules.max_level


## Mở khóa nhân vật mới ở cấp 1 (đã có thì không đổi). Trả về true nếu vừa thêm.
func unlock(character_id: String) -> bool:
	if owns(character_id):
		return false
	data["characters"][character_id] = SaveSchema.default_character()
	changed.emit()
	return true


## Cộng EXP, tự lên cấp; EXP thừa ở cấp tối đa bị bỏ. Trả về số cấp đã lên.
func add_exp(character_id: String, amount: int) -> int:
	if not owns(character_id) or amount < 0:
		return 0
	var c: Dictionary = data["characters"][character_id]
	var start := level_of(character_id)
	var level := start
	var xp := exp_of(character_id) + amount
	var cap := level_cap()
	while level < cap and xp >= rules.exp_to_next(level):
		xp -= rules.exp_to_next(level)
		level += 1
	if level >= rules.max_level:
		xp = 0
	elif level >= cap:
		xp = mini(xp, rules.exp_to_next(level))   # chạm cấp đội trưởng: thanh EXP đầy, chờ đội trưởng lên cấp
	c["level"] = level
	c["exp"] = xp
	changed.emit()
	if level > start:
		leveled_up.emit(character_id, start, level)
	return level - start


# ---------- Cấp đội trưởng ----------

func captain_level() -> int:
	var a: Variant = data.get("account")
	return clampi(int(a.get("level", 1)), 1, rules.captain_max_level) if a is Dictionary else 1


func captain_exp() -> int:
	var a: Variant = data.get("account")
	return int(a.get("exp", 0)) if a is Dictionary else 0


## Cấp tối đa nhân vật đạt được lúc này = min(cấp tối đa, cấp đội trưởng).
func level_cap() -> int:
	return mini(rules.max_level, captain_level())


## Đã chạm giới hạn cấp đội trưởng (và chưa phải cấp tối đa của game).
func is_capped(character_id: String) -> bool:
	return level_of(character_id) >= level_cap() and level_cap() < rules.max_level


## Cộng EXP đội trưởng, tự lên cấp; lên cấp thì nhân vật đang đầy thanh EXP được lên tiếp. Trả về số cấp đã lên.
func add_captain_exp(amount: int) -> int:
	if amount <= 0:
		return 0
	if not (data.get("account") is Dictionary):
		data["account"] = {"level": 1, "exp": 0}
	var start := captain_level()
	var level := start
	var xp := captain_exp() + amount
	while level < rules.captain_max_level and xp >= rules.captain_exp_to_next(level):
		xp -= rules.captain_exp_to_next(level)
		level += 1
	if level >= rules.captain_max_level:
		xp = 0
	data["account"]["level"] = level
	data["account"]["exp"] = xp
	if level > start:
		for id in data["characters"]:
			add_exp(str(id), 0)
	changed.emit()
	return level - start


# ---------- Mảnh, tiến cấp ----------

func fragments_of(character_id: String) -> int:
	return int(data["characters"][character_id].get("fragments", 0)) if owns(character_id) else 0


func promotion_of(character_id: String) -> int:
	return clampi(int(data["characters"][character_id].get("promotion", 0)), 0, rules.max_promotion()) if owns(character_id) else 0


func add_fragments(character_id: String, count: int) -> bool:
	if not owns(character_id) or count <= 0:
		return false
	data["characters"][character_id]["fragments"] = fragments_of(character_id) + count
	changed.emit()
	return true


## Số mảnh cần cho bước tiến cấp kế (0 = đã tối đa).
func fragments_to_promote(character_id: String) -> int:
	var p := promotion_of(character_id)
	return rules.promotion_fragments[p] if p < rules.max_promotion() else 0


func check_promote(character_id: String) -> String:
	if not owns(character_id):
		return Inventory.REASON_UNKNOWN_CHARACTER
	if promotion_of(character_id) >= rules.max_promotion():
		return Inventory.REASON_MAX_LEVEL
	if fragments_of(character_id) < fragments_to_promote(character_id):
		return Inventory.REASON_NOT_ENOUGH
	return Inventory.OK_REASON


## Tiến cấp một bước (S → S1 …), trừ mảnh. Trả về lý do ("" = thành công).
func promote(character_id: String) -> String:
	var reason := check_promote(character_id)
	if reason != Inventory.OK_REASON:
		return reason
	var c: Dictionary = data["characters"][character_id]
	c["fragments"] = fragments_of(character_id) - fragments_to_promote(character_id)
	c["promotion"] = promotion_of(character_id) + 1
	changed.emit()
	return Inventory.OK_REASON


## Bậc hiển thị, vd "S", "S2". Hạng lấy từ CharacterDef.rank ("?" nếu chưa gán).
func rank_label(def: CharacterDef) -> String:
	var r := def.rank if def and def.rank != "" else "?"
	var p := promotion_of(def.id) if def else 0
	return r + (str(p) if p > 0 else "")


## EXP còn nhận được trước khi chạm cấp tối đa.
func exp_room(character_id: String) -> int:
	if not owns(character_id) or is_max_level(character_id):
		return 0
	return rules.total_exp_for(rules.max_level) - rules.total_exp_for(level_of(character_id)) - exp_of(character_id)


## Lý do không dùng được `count` nguyên liệu EXP cho nhân vật ("" = được).
func check_use_exp_material(character_id: String, material_id: String, count: int) -> String:
	if not owns(character_id):
		return Inventory.REASON_UNKNOWN_CHARACTER
	var mat := inventory.items.get_def(material_id) as ItemDef
	if mat == null or mat.kind != ItemDef.Kind.EXP:
		return Inventory.REASON_UNKNOWN_ITEM
	if count <= 0:
		return Inventory.REASON_INVALID
	if is_max_level(character_id):
		return Inventory.REASON_MAX_LEVEL
	if is_capped(character_id) and exp_of(character_id) >= rules.exp_to_next(level_of(character_id)):
		return Inventory.REASON_LEVEL_CAP
	if inventory.material_count(material_id) < count:
		return Inventory.REASON_NOT_ENOUGH
	if not inventory.can_spend("gold", exp_material_gold_cost(material_id, count)):
		return Inventory.REASON_NOT_ENOUGH
	return Inventory.OK_REASON


func exp_material_gold_cost(material_id: String, count: int) -> int:
	var mat := inventory.items.get_def(material_id) as ItemDef
	return int(ceil(mat.value * count * rules.gold_per_exp)) if mat else 0


## Dùng nguyên liệu EXP: trừ nguyên liệu + vàng, cộng EXP. Trả về lý do ("" = thành công); thất bại thì không trừ gì.
func use_exp_material(character_id: String, material_id: String, count: int) -> String:
	var reason := check_use_exp_material(character_id, material_id, count)
	if reason != Inventory.OK_REASON:
		return reason
	var mat := inventory.items.get_def(material_id) as ItemDef
	inventory.spend_currency("gold", exp_material_gold_cost(material_id, count))
	inventory.consume_material(material_id, count)
	add_exp(character_id, mat.value * count)
	return Inventory.OK_REASON


# ---------- Cấp kỹ năng ----------

func skill_level(character_id: String, group: String) -> int:
	if not owns(character_id):
		return 1
	var s: Variant = data["characters"][character_id].get("skills")
	return clampi(int(s.get(group, 1)), 1, rules.skill_max_level) if s is Dictionary else 1


## {SkillDef.key: cấp} cho mọi key thuộc các nhóm (dùng trong trận: SkillRunner tra theo key của kỹ năng).
func skill_levels_by_key(character_id: String) -> Dictionary:
	var out := {}
	for group: String in SKILL_GROUPS:
		var lv := skill_level(character_id, group)
		for key: String in SKILL_GROUPS[group]:
			out[key] = lv
	return out


func check_upgrade_skill(character_id: String, group: String) -> String:
	if not owns(character_id):
		return Inventory.REASON_UNKNOWN_CHARACTER
	if not SKILL_GROUPS.has(group):
		return Inventory.REASON_INVALID
	var lv := skill_level(character_id, group)
	if lv >= rules.skill_max_level:
		return Inventory.REASON_MAX_LEVEL
	if not inventory.can_spend("gold", rules.skill_upgrade_gold(lv)):
		return Inventory.REASON_NOT_ENOUGH
	return Inventory.OK_REASON


## Nâng nhóm kỹ năng +1 cấp, trừ vàng. Trả về lý do ("" = thành công); thất bại thì không trừ gì.
func upgrade_skill(character_id: String, group: String) -> String:
	var reason := check_upgrade_skill(character_id, group)
	if reason != Inventory.OK_REASON:
		return reason
	var lv := skill_level(character_id, group)
	inventory.spend_currency("gold", rules.skill_upgrade_gold(lv))
	var c: Dictionary = data["characters"][character_id]
	if not (c.get("skills") is Dictionary):
		c["skills"] = {}
	c["skills"][group] = lv + 1
	changed.emit()
	return Inventory.OK_REASON


## Chỉ số chiến đấu cuối cùng: gốc (CharacterDef) × hệ số cấp + trang bị. Trả về CombatStats mới (không sửa bản gốc).
func stats_for(def: CharacterDef) -> CombatStats:
	var base := def.stats if def and def.stats else CombatStats.new()
	var out := base.duplicate() as CombatStats
	var id := def.id if def else ""
	var level := level_of(id)
	var bonus := inventory.equipped_bonus(id) if inventory else {}
	var promo := 1.0 + rules.promotion_stat_bonus * float(promotion_of(id))
	out.max_hp = round(base.max_hp * rules.stat_multiplier(rules.hp_growth_per_level, level) * promo + float(bonus.get("max_hp", 0.0)))
	out.atk = round(base.atk * rules.stat_multiplier(rules.atk_growth_per_level, level) * promo + float(bonus.get("atk", 0.0)))
	out.def = round(base.def * rules.stat_multiplier(rules.def_growth_per_level, level) * promo + float(bonus.get("def", 0.0)))
	out.crit_rate = clampf(base.crit_rate + float(bonus.get("crit_rate", 0.0)), 0.0, 1.0)
	out.crit_damage = base.crit_damage + float(bonus.get("crit_damage", 0.0))
	out.cdr = clampf(base.cdr + float(bonus.get("cdr", 0.0)), 0.0, 1.0)
	return out
