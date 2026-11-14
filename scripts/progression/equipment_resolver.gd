class_name EquipmentResolver
extends RefCounted
## Gom hiệu ứng của trang bị đang mặc thành một Loadout và chặn trần ở MỘT chỗ (EQUIPMENT_5STAR mục 3.4).
## Hàm thuần: không node, không autoload. Quy tắc:
## - Hiệu ứng độc quyền chỉ nhận khi giáp người đeo == owner_id (owner Q1: so theo Data ID, không theo person_id).
## - requires_element: người đeo khác nguyên tố thì dòng đó không kích hoạt (mục 3.2, quyết định 5.3).
## - Bộ vết thánh: đếm món cùng set_id; 2 món → bonus_2, 3 món → thêm bonus_3.
## - PARAM nhiều nguồn: cộng dồn phần tăng (owner Q3), rồi chặn theo EquipmentRules.param_caps.
## - Buff toàn đội: cùng effect_id từ nhiều người đeo chỉ lấy mức cao nhất (mục 3.3).

const SETS_DIR := "res://data/equipment/sets"
const RULES_PATH := "res://data/config/equipment_rules.tres"

static var _sets: DefLibrary
static var _rules: EquipmentRules


static func set_defs() -> DefLibrary:
	if _sets == null:
		_sets = DefLibrary.load_dir(SETS_DIR)
	return _sets


static func default_rules() -> EquipmentRules:
	if _rules == null:
		_rules = load(RULES_PATH) as EquipmentRules if ResourceLoader.exists(RULES_PATH) else EquipmentRules.new()
	return _rules


## Kết quả gom cho một người đeo.
class Loadout:
	extends RefCounted
	var rules: EquipmentRules
	var character_id := ""
	var element := ""
	## Chỉ số của riêng người đeo: stat → tổng.
	var stats: Dictionary = {}
	## Buff toàn đội người đeo này phát ra: effect_id → {stat, value}.
	var team_out: Dictionary = {}
	## Buff toàn đội người đeo nhận (PartyManager gán sau khi gom cả đội): stat → tổng.
	var team_in: Dictionary = {}
	## param → tổng phần tăng.
	var params: Dictionary = {}
	## condition → % sát thương thêm.
	var vs_target: Dictionary = {}
	var on_weapon_hit: Array[EquipEffect] = []
	var pending: Array[EquipEffect] = []
	## set_id → số món đang mặc.
	var set_counts: Dictionary = {}

	func is_empty() -> bool:
		return stats.is_empty() and team_out.is_empty() and team_in.is_empty() and params.is_empty() \
				and vs_target.is_empty() and on_weapon_hit.is_empty()

	## Chỉ số tổng (riêng + toàn đội) trước trần.
	func stat(name: String) -> float:
		return float(stats.get(name, 0.0)) + float(team_in.get(name, 0.0))

	## Giá trị tham số sau khi cộng phần tăng, chặn theo param_caps.
	func param_value(param: String, base: float) -> float:
		var v := base + float(params.get(param, 0.0))
		if rules and rules.param_caps.has(param):
			v = minf(v, float(rules.param_caps[param]))
		return v

	func has_param(param: String) -> bool:
		return params.has(param)

	## % sát thương từ trang bị lên một mục tiêu (dòng 8: tổng không quá equip_damage_cap).
	## `met` = các điều kiện mục tiêu đang thỏa (tên trạng thái, "elemental", "def_down", "low_hp", "boss").
	func damage_bonus(met: Array = []) -> float:
		var total := stat("all_dmg") + stat("elem_dmg")
		for c in vs_target:
			if c in met:
				total += float(vs_target[c])
		return clampf(total, 0.0, rules.equip_damage_cap if rules else 1.0)

	## Tổng tốc độ tấn công (phần từ trạng thái + trang bị), chặn trần dòng 3.
	func attack_speed(status_part: float) -> float:
		return minf(status_part + stat("atk_speed"), rules.atk_speed_cap if rules else 0.6)

	## Hút máu từ trang bị, còn chỗ trong trần sau phần `kit_part` của kit (dòng 5).
	func lifesteal(kit_part := 0.0) -> float:
		var cap := rules.lifesteal_cap if rules else 0.3
		return clampf(stat("lifesteal"), 0.0, maxf(cap - kit_part, 0.0))

	## Trần hút máu cho phần của kit (kit + trang bị ≤ trần).
	func kit_lifesteal(kit_part: float) -> float:
		var cap := rules.lifesteal_cap if rules else 0.3
		return clampf(kit_part, 0.0, maxf(cap - clampf(stat("lifesteal"), 0.0, cap), 0.0))

	func heal_bonus() -> float:
		return clampf(stat("heal_bonus"), 0.0, rules.heal_bonus_cap if rules else 0.5)


static func is_active(e: EquipEffect, owner_id: String, character_id: String, element: String) -> bool:
	if e == null:
		return false
	if e.exclusive and (owner_id.is_empty() or owner_id != character_id):
		return false
	if not e.requires_element.is_empty() and e.requires_element != element:
		return false
	return true


## Gom hiệu ứng của các món `items` cho người đeo `character_id` (nguyên tố `element`).
static func resolve(character_id: String, element: String, items: Array, sets: DefLibrary = null,
		rules: EquipmentRules = null) -> Loadout:
	var out := Loadout.new()
	out.rules = rules if rules else default_rules()
	out.character_id = character_id
	out.element = element
	var lib := sets if sets else set_defs()
	for item in items:
		var d := item as EquipmentDef
		if d == null:
			continue
		for e in d.effects:
			if is_active(e, d.owner_id, character_id, element):
				_add(out, e)
		if not d.set_id.is_empty():
			out.set_counts[d.set_id] = int(out.set_counts.get(d.set_id, 0)) + 1
	for sid in out.set_counts:
		var s := lib.get_def(sid) as StigmaSetDef if lib else null
		if s == null:
			continue
		for e in s.effects_for(int(out.set_counts[sid])):
			if is_active(e, s.owner_id, character_id, element):
				_add(out, e)
	return out


static func _add(out: Loadout, e: EquipEffect) -> void:
	match e.kind:
		EquipEffect.Kind.STAT:
			if e.team and not e.effect_id.is_empty():
				var prev: Dictionary = out.team_out.get(e.effect_id, {})
				if prev.is_empty() or float(prev["value"]) < e.value:
					out.team_out[e.effect_id] = {"stat": e.stat, "value": e.value}
			else:
				out.stats[e.stat] = float(out.stats.get(e.stat, 0.0)) + e.value
		EquipEffect.Kind.PARAM:
			out.params[e.param] = float(out.params.get(e.param, 0.0)) + e.value
		EquipEffect.Kind.VS_TARGET:
			out.vs_target[e.condition] = float(out.vs_target.get(e.condition, 0.0)) + e.value
		EquipEffect.Kind.ON_WEAPON_HIT:
			out.on_weapon_hit.append(e)
		EquipEffect.Kind.PENDING:
			out.pending.append(e)


## Bản sao các SkillDef có tham số "skill:<key>:<thuộc tính>" (cộng phần tăng). Không sửa resource gốc.
static func apply_to_skills(skills: Dictionary, lo: Loadout) -> Dictionary:
	var out := skills.duplicate()
	for param: String in lo.params:
		if param.get_slice(":", 0) != "skill" or param.get_slice_count(":") != 3:
			continue
		var key := param.get_slice(":", 1)
		var prop := param.get_slice(":", 2)
		for id in out:
			var s := out[id] as SkillDef
			if s == null or s.key != key:
				continue
			if not (prop in s):
				push_warning("EquipmentResolver: SkillDef không có '%s'" % prop)
				continue
			var copy := s.duplicate() as SkillDef
			copy.set(prop, maxf(lo.param_value(param, float(s.get(prop))), 0.0))
			out[id] = copy
	return out


## Bản sao cấu hình kit có tham số "kit:<thuộc tính>" hoặc "kit:<thuộc tính dạng Dictionary>.<khóa>".
static func apply_to_kit_config(cfg: Resource, lo: Loadout) -> Resource:
	if cfg == null or lo == null:
		return cfg
	var copy: Resource = null
	for param: String in lo.params:
		if param.get_slice(":", 0) != "kit":
			continue
		var path := param.get_slice(":", 1)
		var prop := path.get_slice(".", 0)
		if not (prop in cfg):
			push_warning("EquipmentResolver: cấu hình kit không có '%s'" % prop)
			continue
		if copy == null:
			copy = cfg.duplicate()
		if path.contains("."):
			var k := path.get_slice(".", 1)
			var sub: Variant = copy.get(prop)
			if sub is Dictionary:
				var d: Dictionary = (sub as Dictionary).duplicate()
				d[k] = lo.param_value(param, float(d.get(k, 0.0)))
				copy.set(prop, d)
			elif sub is Resource and k in sub:
				# Vd "kit:burst.atk_ratio": HitDef con của cấu hình kit.
				var r := (sub as Resource).duplicate()
				r.set(k, lo.param_value(param, float(r.get(k))))
				copy.set(prop, r)
			else:
				push_warning("EquipmentResolver: không sửa được '%s'" % param)
		else:
			var base: Variant = copy.get(prop)
			var v := lo.param_value(param, float(base))
			copy.set(prop, int(round(v)) if base is int else v)
	return copy if copy else cfg


## Gom buff toàn đội của cả đội: cùng effect_id lấy mức cao nhất (không cộng dồn), khác id cộng lại.
## Trả về stat → tổng; gán vào `team_in` của từng Loadout.
static func merge_team(loadouts: Array) -> Dictionary:
	var best := {}
	for l in loadouts:
		var lo := l as Loadout
		if lo == null:
			continue
		for id in lo.team_out:
			var v: Dictionary = lo.team_out[id]
			if not best.has(id) or float(best[id]["value"]) < float(v["value"]):
				best[id] = v
	var total := {}
	for id in best:
		var st := str(best[id]["stat"])
		total[st] = float(total.get(st, 0.0)) + float(best[id]["value"])
	for l in loadouts:
		if l is Loadout:
			(l as Loadout).team_in = total.duplicate()
	return total
