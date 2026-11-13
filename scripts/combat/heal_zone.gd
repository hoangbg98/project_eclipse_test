class_name HealZone
extends Node2D
## Thực hiện một HealDef: hồi theo nhịp cho đội của người hồi (CHARACTER_SKILLS mục 4, 8.1).
## Gắn vào thế giới (độc lập) hoặc vào người hồi (follow_caster, SkillRunner xoá khi kỹ năng dừng).

var def: HealDef
var caster: Combatant
## Combatant cả đội (PlayerController.team_combatants); rỗng = chỉ người hồi.
var team: Array[Combatant] = []

var _delay := 0.0
var _next := 0.0
var _done := 0
var _revived := false


static func spawn(parent: Node, p_def: HealDef, p_caster: Combatant, p_team: Array[Combatant], pos: Vector2) -> HealZone:
	var z := HealZone.new()
	z.name = "HealZone"
	z.def = p_def
	z.caster = p_caster
	z.team = p_team
	z._delay = p_def.delay_ms / 1000.0
	parent.add_child(z)
	z.global_position = pos
	if z._delay <= 0.0:
		z._tick()
	return z


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	if _delay > 0.0:
		_delay -= delta
		if _delay <= 0.000001:
			_delay = 0.0
			_tick()
		return
	if _done >= def.ticks:
		queue_free()
		return
	_next -= delta
	if _next <= 0.000001:
		_tick()


func _members() -> Array[Combatant]:
	if team.is_empty():
		return [caster] as Array[Combatant]
	return team


func _tick() -> void:
	_done += 1
	_next = def.interval_ms / 1000.0
	if caster == null or not is_instance_valid(caster):
		queue_free()
		return
	var targets: Array[Combatant] = []
	var alive: Array[Combatant] = []
	for c in _members():
		if is_instance_valid(c) and not c.resources.is_dead():
			alive.append(c)
	match def.target:
		HealDef.TARGET_SELF:
			targets = [caster] as Array[Combatant]
		HealDef.TARGET_LOWEST:
			var low := lowest(alive)
			if low:
				targets = [low] as Array[Combatant]
		HealDef.TARGET_AREA:
			for c in alive:
				if c.resources.on_field and _inside(c):
					targets.append(c)
			_try_revive()
		_:
			targets = alive
	var low_one := lowest(alive) if def.lowest_multiplier != 1.0 else null
	for c in targets:
		var amount := caster.current_atk() * def.atk_ratio + c.resources.max_hp * def.max_hp_ratio
		if c == low_one:
			amount *= def.lowest_multiplier
		if amount > 0.0:
			caster.heal_target(c, amount)
		if def.cleanse > 0 and _done == 1:
			c.statuses.cleanse(def.cleanse)
		for st in def.ally_statuses:
			c.statuses.apply(st.status_id, st.duration, st.magnitude, caster)
	if _done >= def.ticks:
		queue_free()


func _inside(c: Combatant) -> bool:
	var n := c.get_parent() as Node2D
	return n != null and n.is_inside_tree() and n.global_position.distance_to(global_position) <= def.radius_px


## Hồi sinh người đã gục trong vùng (người dự bị đã gục cũng được, mục 8.1), một lần mỗi vùng; tắt theo Q6.
func _try_revive() -> void:
	if _revived or def.revive_hp_ratio <= 0.0 or caster.rules == null or not caster.rules.revive_enabled:
		return
	for c in _members():
		if is_instance_valid(c) and c.resources.is_dead() and (not c.resources.on_field or _inside(c)):
			c.resources.hp = c.resources.max_hp * def.revive_hp_ratio
			c.resources.hp_changed.emit(c.resources.hp, c.resources.max_hp)
			_revived = true
			return


## Người có % HP thấp nhất (null nếu rỗng).
static func lowest(list: Array[Combatant]) -> Combatant:
	var best: Combatant = null
	var best_r := INF
	for c in list:
		var r := c.resources.hp_ratio()
		if r < best_r:
			best_r = r
			best = c
	return best
