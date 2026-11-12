class_name ReactionResolver
extends RefCounted
## Tra và kích hoạt phản ứng nguyên tố (CHARACTER_SKILLS 8.4; ARCHITECTURE mục 6).
## - 15 ReactionDef trong data/reactions, khóa theo cặp nguyên tố.
## - ICD chung `reaction_icd_sec` (5.0 s).
## - Vùng đòn là DetachedHit (tồn tại độc lập), người đánh = nhân vật vào sân (% ATK của họ),
##   khống chế lên boss × `reaction_boss_control_multiplier`.
## PartyManager quyết định KHI NÀO gọi (vào sân Liên kết + Kĩ năng vào sân trúng kẻ địch).

signal triggered(reaction: ReactionDef, center: Vector2, by: Node)

const DATA_DIR := "res://data/reactions"

var rules: CombatRules
var reactions: Dictionary = {}   # "fire_wind" -> ReactionDef
var rng := RandomSource.new(0)

var _icd := 0.0


func _init(combat_rules: CombatRules) -> void:
	rules = combat_rules


func load_dir(dir := DATA_DIR) -> PackedStringArray:
	var errors := PackedStringArray()
	reactions.clear()
	for f in ResourceLoader.list_directory(dir):
		if f.get_extension() not in ["tres", "res"]:
			continue
		var d := load(dir.path_join(f)) as ReactionDef
		if d == null:
			errors.append("%s: không phải ReactionDef" % f)
			continue
		errors.append_array(d.validate())
		if d.elements.size() == 2:
			var key := ReactionDef.pair_key(d.elements[0], d.elements[1])
			if reactions.has(key):
				errors.append("trùng cặp %s" % key)
			reactions[key] = d
	return errors


## Phản ứng của cặp nguyên tố (thứ tự bất kỳ), hoặc null.
func find(element_a: String, element_b: String) -> ReactionDef:
	return reactions.get(ReactionDef.pair_key(element_a, element_b))


func tick(delta: float) -> void:
	_icd = maxf(_icd - delta, 0.0)


func icd_left() -> float:
	return _icd


func can_trigger() -> bool:
	return _icd <= 0.0


## Kích hoạt `def` tại `center` (chân mục tiêu trúng đầu tiên, hoặc chân người vào sân nếu SELF).
## `by` là nhân vật vào sân; `team` là mọi thành viên đội (để hồi máu / xóa hiệu ứng xấu).
## Trả về false nếu còn ICD.
func trigger(def: ReactionDef, by: Node2D, center: Vector2, team: Array = []) -> bool:
	if def == null or by == null or not can_trigger():
		return false
	_icd = rules.reaction_icd_sec
	var src := Combatant.of(by)
	var own_team: PhysicsLayers.Team = src.team if src else PhysicsLayers.Team.PLAYER
	var facing := int(by.facing) if "facing" in by else 1
	if def.target_mode == ReactionDef.TargetMode.HIGHEST_HP:
		_strike_highest_hp(def, by, center, own_team)
	else:
		var parent := by.get_parent()
		for h in def.hits:
			var pos := center
			if def.scatter_radius_px > 0.0:
				pos += Vector2((rng.randf() * 2.0 - 1.0) * def.scatter_radius_px, 0.0)
			var d := DetachedHit.spawn(parent, h, by, own_team, facing, pos, {},
					ResourceComponent.HitKind.NONE, def.id, 0.0, h.at_ms / 1000.0)
			d.hitbox.boss_control_multiplier = rules.reaction_boss_control_multiplier
	if src:
		for st in def.self_statuses:
			src.statuses.apply(st.status_id, st.duration, st.magnitude, src)
	for m in team:
		var c: Combatant = m.combatant() if m.has_method("combatant") else Combatant.of(m)
		if c == null or c.resources.is_dead():
			continue
		if def.team_heal_max_hp_ratio > 0.0:
			c.resources.heal(c.resources.max_hp * def.team_heal_max_hp_ratio)
		for i in def.team_cleanse_count:
			_cleanse_one(c)
	triggered.emit(def, center, by)
	return true


## Thần Phạt: đánh thẳng một mục tiêu HP cao nhất trong tầm (không qua vùng va chạm).
func _strike_highest_hp(def: ReactionDef, by: Node2D, center: Vector2, own_team: int) -> void:
	var best: Combatant = null
	for n in by.get_tree().get_nodes_in_group(Combatant.GROUP):
		var c := Combatant.of(n)
		if c == null or c.team == own_team or c.resources == null or c.resources.is_dead():
			continue
		if (n as Node2D).global_position.distance_to(center) > def.target_range_px:
			continue
		if best == null or c.resources.hp > best.resources.hp:
			best = c
	if best == null:
		return
	for h in def.hits:
		var hit := HitInfo.new()
		hit.attacker = by
		hit.team = own_team
		hit.skill_id = def.id
		hit.atk_ratio = h.atk_ratio
		hit.sc_ratio = h.atk_ratio * h.sc_multiplier
		hit.origin = center
		hit.knockback_px = h.knockback_px
		hit.hit_kind = ResourceComponent.HitKind.NONE
		hit.statuses = h.statuses
		hit.boss_control_multiplier = rules.reaction_boss_control_multiplier
		best.receive_hit(hit)


## Xóa một hiệu ứng xấu (DEBUFF hoặc CONTROL); ưu tiên khống chế.
func _cleanse_one(c: Combatant) -> void:
	var pick := ""
	for id in c.statuses.active_ids():
		var def := c.statuses.library.get_status(id)
		if def == null or def.kind == StatusDef.Kind.BUFF:
			continue
		if def.kind == StatusDef.Kind.CONTROL:
			pick = id
			break
		if pick == "":
			pick = id
	if pick != "":
		c.statuses.remove(pick)
