class_name EquipTriggers
extends RefCounted
## Hiệu ứng trang bị theo sự kiện (EquipEffect.Kind.TRIGGER) của một nhân vật (docs/design/EQUIPMENT_5STAR.md).
## PlayerController tạo sau khi gắn kit, gọi tick() cả khi ở dự bị. Mỗi dòng có ICD riêng.
## Buff dùng trạng thái riêng trong data/statuses/eqb_*.tres (REFRESH): cùng hiệu ứng từ nhiều người đeo chỉ làm mới,
## không cộng dồn (mục 3.3). Buff liên tục (while_*) làm mới mỗi tick với thời gian ngắn, hết điều kiện thì tự tắt.
## Không gọi thẳng tên autoload (AGENTS 3): EventBus lấy qua cây.

## Thời gian làm mới của buff liên tục (while_self_stacks, while_self_hp_below).
const CONTINUOUS_SEC := 0.3
const MARK := "lightning_mark"
const CURSE := "curse"

var player: PlayerController
var combatant: Combatant
var effects: Array[EquipEffect] = []
## Số lần mỗi dòng đã kích hoạt (test / gỡ lỗi), khóa = chỉ số trong `effects`.
var fired: Dictionary = {}

var _icd: Dictionary = {}       # chỉ số → giây còn lại
var _targets: Dictionary = {}   # chỉ số → {instance id mục tiêu: giây còn trong cửa sổ}
var _cast_hit: Dictionary = {}  # chỉ số → đã kích hoạt trong lần dùng Kĩ năng vũ khí hiện tại
var _hp_low: Dictionary = {}    # chỉ số → điều kiện HP thấp đang bật (có đệm, mục 3.4 dòng 9)


func attach(p: PlayerController, lo: EquipmentResolver.Loadout) -> void:
	player = p
	combatant = p.combatant
	effects = lo.triggers if lo else effects
	if effects.is_empty():
		return
	p.runner.skill_started.connect(_on_skill_started)
	p.runner.skill_finished.connect(_on_skill_finished)
	p.perfect_dodged.connect(func(_h: HitInfo) -> void: _event("perfect_dodge"))
	combatant.hit_dealt.connect(_on_hit_dealt)
	combatant.heal_done.connect(_on_heal_done)
	combatant.damaged.connect(func(_r: DamageCalculator.Result, _h: HitInfo) -> void: _event("damaged"))
	combatant.statuses.max_stacks_reached.connect(_on_self_max_stacks)
	var bus := p.get_tree().root.get_node_or_null("EventBus") if p.is_inside_tree() else null
	if bus:
		bus.status_applied.connect(_on_status_applied)
		bus.status_max_stacks.connect(_on_status_max_stacks)


func tick(delta: float) -> void:
	for i in _icd.keys():
		_icd[i] = float(_icd[i]) - delta
		if float(_icd[i]) <= 0.0:
			_icd.erase(i)
	for i in _targets:
		var w: Dictionary = _targets[i]
		for k in w.keys():
			w[k] = float(w[k]) - delta
			if float(w[k]) <= 0.0:
				w.erase(k)
	if combatant == null or combatant.resources == null or combatant.resources.is_dead():
		return
	var buffer := EquipmentResolver.default_rules().hp_threshold_buffer
	for i in effects.size():
		var e := effects[i]
		match e.trigger:
			"while_self_stacks":
				if combatant.statuses.stacks(e.trigger_arg) >= int(e.trigger_value):
					_act(i, {}, CONTINUOUS_SEC)
			"while_self_hp_below":
				var r := combatant.resources.hp_ratio()
				var on: bool = _hp_low.get(i, false)
				if r < e.trigger_value:
					on = true
				elif r > e.trigger_value + buffer:
					on = false
				_hp_low[i] = on
				if on:
					_act(i, {}, CONTINUOUS_SEC)


# ---------- Sự kiện ----------

func _event(name: String, ctx: Dictionary = {}) -> void:
	for i in effects.size():
		var t := effects[i].trigger
		if t == name or (t == "weapon_or_ultimate_used" and name in ["weapon_used", "ultimate_used"]):
			_fire(i, ctx)


func _on_skill_started(_key: String, skill: SkillDef) -> void:
	match skill.key:
		"ultimate":
			_event("ultimate_used")
		"weapon":
			_cast_hit.clear()
			_event("weapon_used")
	for i in effects.size():
		var e := effects[i]
		if e.trigger == "during_skill" and e.trigger_arg == skill.key:
			combatant.statuses.apply(e.status_id, maxf(skill.total_ms() / 1000.0, 0.1) + 0.5, e.magnitude, combatant)


func _on_skill_finished(_key: String, skill: SkillDef) -> void:
	for e in effects:
		if e.trigger == "during_skill" and e.trigger_arg == skill.key:
			combatant.statuses.remove(e.status_id)


func _on_hit_dealt(target: Combatant, _result: DamageCalculator.Result, hit: HitInfo) -> void:
	var key := hit.skill_id.get_slice(".", 1)
	var ctx := {"target": target, "hit": hit}
	for i in effects.size():
		var e := effects[i]
		match e.trigger:
			"weapon_hit":
				if key == "weapon" and not _cast_hit.get(i, false):
					_cast_hit[i] = true
					_fire(i, ctx)
			"skill_hit":
				if key == "skill":
					_fire(i, ctx)
			"distinct_targets":
				if target:
					if not _targets.has(i):
						_targets[i] = {}
					_targets[i][target.get_instance_id()] = e.trigger_window
					if (_targets[i] as Dictionary).size() >= int(e.trigger_value) and not _icd.has(i):
						_targets[i] = {}
						_fire(i, ctx)
	if target and hit.killed_target:
		_event("kill", ctx)
		if CURSE in hit.target_statuses_before:
			_event("kill_cursed", ctx)


func _on_heal_done(_target: Combatant, _healed: float, _overflow: float, ratio_before: float) -> void:
	if ratio_before < EquipmentResolver.default_rules().heal_low_ratio:
		_event("heal_low")


func _on_self_max_stacks(status_id: String, _source: Object) -> void:
	for i in effects.size():
		if effects[i].trigger == "self_max_stacks" and effects[i].trigger_arg == status_id:
			_fire(i)


func _on_status_applied(target: Object, status_id: String, source: Object) -> void:
	if source != combatant or target == combatant or not (target is Combatant):
		return
	var def := combatant.statuses.library.get_status(status_id) if combatant.statuses.library else null
	if def and def.counts_as_elemental:
		_event("elemental_applied", {"target": target})


func _on_status_max_stacks(target: Object, status_id: String, source: Object) -> void:
	if source == combatant and status_id == MARK and target is Combatant:
		_event("lightning_burst", {"target": target})


# ---------- Hành động ----------

func _fire(i: int, ctx: Dictionary = {}) -> void:
	if _icd.has(i):
		return
	var e := effects[i]
	if e.icd > 0.0:
		_icd[i] = e.icd
	fired[i] = int(fired.get(i, 0)) + 1
	_act(i, ctx)


func _act(i: int, ctx: Dictionary, duration_override := -1.0) -> void:
	var e := effects[i]
	match e.action:
		"buff":
			var dur := duration_override if duration_override > 0.0 else e.value
			for c in (_team() if e.team else [combatant]):
				if c.resources.is_dead():
					continue
				if not e.target_element.is_empty() and _element_of(c) != e.target_element:
					continue
				c.statuses.apply(e.status_id, dur, e.magnitude, combatant)
		"self_status":
			combatant.statuses.apply(e.status_id, e.value if e.value > 0.0 else -1.0, e.magnitude, combatant)
		"cd":
			for k in e.cd_keys:
				combatant.cooldowns.reduce(StringName(k), e.value, e.cap)
		"si_cd":
			combatant.cooldowns.reduce(LinkTracker.SI_CD_KEY, e.value, e.cap)
		"heal_self":
			combatant.heal_target(combatant, combatant.resources.max_hp * e.value)
		"heal_team":
			for c in _team():
				if not c.resources.is_dead():
					combatant.heal_target(c, c.resources.max_hp * e.value)
		"en":
			combatant.resources.add_en(e.value)
		"spread":
			_spread(e, ctx.get("target") as Combatant)


## Lan trạng thái từ mục tiêu sang kẻ địch gần nhất còn sống (Dấu Sét, Nguyền).
## `value` > 0: thời gian mới; = 0: giữ thời gian còn lại của trạng thái trên mục tiêu cũ.
func _spread(e: EquipEffect, from: Combatant) -> void:
	if from == null or not is_instance_valid(from) or not player.is_inside_tree():
		return
	var origin := from.get_parent() as Node2D
	if origin == null:
		return
	var dur := e.value
	if dur <= 0.0:
		dur = from.statuses.remaining(e.status_id)
		if dur <= 0.0:
			return
	var radius := EquipmentResolver.default_rules().spread_radius_px
	var best: Combatant = null
	var best_d := INF
	for n in player.get_tree().get_nodes_in_group(Combatant.GROUP):
		var c := Combatant.of(n)
		if c == null or c == from or c.team == combatant.team or c.resources == null or c.resources.is_dead():
			continue
		var d := (n as Node2D).global_position.distance_to(origin.global_position) if n is Node2D else INF
		if d <= radius and d < best_d:
			best = c
			best_d = d
	if best:
		best.statuses.apply(e.status_id, dur, e.magnitude, combatant)


func _team() -> Array[Combatant]:
	if player.team_combatants.is_empty():
		return [combatant] as Array[Combatant]
	return player.team_combatants


static func _element_of(c: Combatant) -> String:
	var pc := c.get_parent() as PlayerController
	return pc.character.element if pc and pc.character else ""
