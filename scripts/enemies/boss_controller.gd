class_name BossController
extends EnemyController
## Boss nhiều pha (README "Enemies and bosses", 15.7): dùng lại AI của EnemyController (đuổi, báo hiệu, đánh)
## với bộ đòn theo pha. HP xuống dưới ngưỡng → chuyển pha: huỷ đòn, đứng yên và bất tử trong
## `phase_transition_sec`, rồi dùng bộ đòn mới. Số liệu trong BossDef.

signal phase_changed(phase: int)

## Pha hiện tại, đếm từ 1.
var phase := 1

var _attack_index := 0
var _transition_left := 0.0


func boss_def() -> BossDef:
	return def as BossDef


func phase_def() -> BossPhaseDef:
	var b := boss_def()
	return b.phases[clampi(phase - 1, 0, b.phases.size() - 1)] if b and not b.phases.is_empty() else null


func phase_count() -> int:
	return boss_def().phases.size() if boss_def() else 1


func is_transitioning() -> bool:
	return _transition_left > 0.0


## Ngưỡng HP (tỉ lệ) của các pha sau pha 1: để thanh máu boss vẽ vạch.
func phase_markers() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if boss_def():
		for i in range(1, boss_def().phases.size()):
			out.append(boss_def().phases[i].hp_ratio_below)
	return out


func _skill_table() -> Dictionary:
	var t := {}
	var b := boss_def()
	if b == null:
		return super()
	for pi in b.phases.size():
		for ai in b.phases[pi].attacks.size():
			t[_key(pi + 1, ai)] = b.phases[pi].attacks[ai]
	return t


static func _key(p: int, index: int) -> String:
	return "p%d_a%d" % [p, index]


func _next_attack_key() -> String:
	var p := phase_def()
	if p == null or p.attacks.is_empty():
		return super()
	var k := _key(phase, _attack_index % p.attacks.size())
	_attack_index += 1
	return k


func _attack_range() -> float:
	return phase_def().attack_range if phase_def() else super()


func _attack_cooldown() -> float:
	return phase_def().attack_cooldown_sec if phase_def() else super()


func _move_speed() -> float:
	return super() * (phase_def().move_speed_multiplier if phase_def() else 1.0)


func step(delta: float) -> void:
	if state != State.DEAD and _frozen <= 0.0:
		if _transition_left > 0.0:
			_transition_left -= delta
			combatant.tick(delta)
			velocity.x = 0.0
			velocity.y = minf(velocity.y + def.gravity * delta, 2000.0)
			move_and_slide()
			if _transition_left <= 0.0:
				hurtbox.invulnerable = false
				state = State.CHASE
			_update_look()
			queue_redraw()
			return
		_check_phase()
	super(delta)


func _check_phase() -> void:
	var b := boss_def()
	if b == null or phase >= b.phases.size():
		return
	if combatant.resources.hp_ratio() <= b.phases[phase].hp_ratio_below:
		phase += 1
		_attack_index = 0
		_attack_cd = 0.0
		runner.cancel()
		_knock_t = 0.0
		_transition_left = b.phase_transition_sec
		hurtbox.invulnerable = true
		phase_changed.emit(phase)


func _update_look() -> void:
	super()
	if is_transitioning():
		body.modulate = Color(2.2, 1.2, 0.6)   # gầm chuyển pha
