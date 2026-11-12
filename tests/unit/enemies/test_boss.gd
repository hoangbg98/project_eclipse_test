extends GdUnitTestSuite
## Test M6 (boss): 2 pha, telegraph ≥ 0.4 s, không khựng, chuyển pha đúng điều kiện, bất tử khi chuyển pha.

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")
const BOSS_SCENE := preload("res://scenes/enemies/boss_golem.tscn")

var _stage: Node2D
var _player: PlayerController
var _boss: BossController


func after_test() -> void:
	Engine.time_scale = 1.0


func _setup(boss_x := 1000.0, player_x := 600.0) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.spawn_enemies = false
	_stage.party_ids = PackedStringArray(["char_fire_01"])
	add_child(_stage)
	for d in _stage.dummies:
		d.queue_free()
	_stage.dummies.clear()
	_stage.party.use_player_input = false
	_player = _stage.player
	_player.use_player_input = false
	_player.global_position = Vector2(player_x, 896)
	_boss = BOSS_SCENE.instantiate()
	_boss.position = Vector2(boss_x, 896)
	_stage.add_child(_boss)
	await _frames(5)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _def() -> BossDef:
	return load("res://data/enemies/boss_golem_01.tres")


# ---------- Dữ liệu ----------

func test_boss_data_valid_two_phases_and_telegraphs() -> void:
	var d := _def()
	assert_array(d.validate()).is_empty()
	assert_int(d.phases.size()).is_greater_equal(2)
	assert_float(d.phases[0].hp_ratio_below).is_equal(1.0)
	assert_float(d.phases[1].hp_ratio_below).is_equal(0.5)
	for p in d.phases:
		for a in p.attacks:
			assert_float(a.startup_ms).override_failure_message(a.id).is_greater_equal(400.0)   # README 15.7
			assert_bool(a.super_armor).is_true()
	assert_float(d.stagger_sec).is_equal(0.0)                         # boss kháng khựng
	assert_str(tr(d.name_key)).is_not_equal(d.name_key)


func test_validate_rejects_short_telegraph_and_single_phase() -> void:
	var d := _def().duplicate(true) as BossDef
	d.phases[0].attacks[0].startup_ms = 300.0
	assert_bool(d.validate().size() > 0).is_true()
	var one := _def().duplicate(true) as BossDef
	one.phases.resize(1)
	assert_bool(one.validate().size() > 0).is_true()


# ---------- Hành vi ----------

func test_boss_setup_and_markers() -> void:
	await _setup()
	assert_bool(_boss.combatant.is_boss).is_true()
	assert_int(_boss.phase).is_equal(1)
	assert_int(_boss.phase_count()).is_equal(2)
	assert_array(Array(_boss.phase_markers())).is_equal([0.5])
	assert_float(_boss.combatant.resources.max_hp).is_equal(60000.0)


func test_boss_telegraphs_at_least_400ms_then_hits_player() -> void:
	await _setup(820.0, 600.0)
	var hurt := [false]
	_player.combatant.damaged.connect(func(_r: DamageCalculator.Result, _h: HitInfo) -> void: hurt[0] = true)
	var telegraph_frames := 0
	for i in 240:
		await get_tree().physics_frame
		if _boss.is_telegraphing():
			telegraph_frames += 1
		if hurt[0]:
			break
	assert_bool(hurt[0]).is_true()
	assert_int(telegraph_frames).is_greater_equal(24)                 # ≥ 0.4 s ở 60 khung/s


func test_boss_is_not_staggered_by_hits() -> void:
	await _setup(820.0, 600.0)
	var h := HitInfo.new()
	h.attacker = _player
	h.atk_ratio = 1.0
	h.sc_ratio = 0.1
	h.knockback_px = 100.0
	_boss.combatant.receive_hit(h)
	assert_int(_boss.state).is_not_equal(EnemyController.State.STAGGER)


func test_phase_two_at_half_hp_with_invulnerable_transition() -> void:
	await _setup(1500.0, 600.0)                                       # xa: chưa đánh
	var changes := []
	_boss.phase_changed.connect(func(p: int) -> void: changes.append(p))
	var r := _boss.combatant.resources
	r.take_damage(r.max_hp * 0.49)
	await _frames(2)
	assert_int(_boss.phase).is_equal(1)                               # 51%: chưa chuyển
	r.take_damage(r.max_hp * 0.02)
	await _frames(2)
	assert_int(_boss.phase).is_equal(2)
	assert_array(changes).is_equal([2])
	assert_bool(_boss.is_transitioning()).is_true()
	assert_bool(_boss.hurtbox.invulnerable).is_true()                 # bất tử khi chuyển pha
	var x0 := _boss.global_position.x
	await _frames(30)
	assert_float(_boss.global_position.x).is_equal_approx(x0, 1.0)    # đứng yên
	await _frames(50)                                                 # > 1.2 s
	assert_bool(_boss.is_transitioning()).is_false()
	assert_bool(_boss.hurtbox.invulnerable).is_false()
	assert_array(changes).is_equal([2])                               # chỉ phát một lần


func test_phase_two_uses_phase_two_attacks() -> void:
	await _setup(820.0, 600.0)
	_boss.combatant.resources.take_damage(_boss.combatant.resources.max_hp * 0.6)
	var ids := {}
	for i in 420:
		await get_tree().physics_frame
		_player.combatant.resources.hp = _player.combatant.resources.max_hp   # giữ người chơi sống
		if _boss.runner.is_running():
			ids[_boss.runner.current.id] = true
		if ids.size() >= 2:
			break
	var phase2 := {}
	for a in _def().phases[1].attacks:
		phase2[a.id] = true
	assert_bool(ids.size() >= 1).is_true()
	for id in ids:
		assert_bool(phase2.has(id)).override_failure_message("đòn %s không thuộc pha 2" % id).is_true()


func test_boss_death_emits_defeated() -> void:
	await _setup(1500.0, 600.0)
	var bus := get_tree().root.get_node("EventBus")
	var dead := []
	var cb := func(e: Node, _by: Object) -> void: dead.append(e)
	bus.enemy_defeated.connect(cb)
	_boss.combatant.resources.take_damage(1e9)
	await _frames(2)
	bus.enemy_defeated.disconnect(cb)
	assert_array(dead).is_equal([_boss])
	assert_bool(_boss.is_dead()).is_true()
