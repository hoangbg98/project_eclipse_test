extends GdUnitTestSuite
## Test M3-7: hit-stop (thời gian thật), rung camera, số sát thương, combo, dừng thời gian + cut-in tuyệt kỹ.

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy_slime.tscn")

var _stage: Node2D
var _player: PlayerController
var _fb: HitFeedback


func after_test() -> void:
	Engine.time_scale = 1.0


func _setup(player_x := 820.0) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.spawn_enemies = false
	add_child(_stage)
	_player = _stage.player
	_player.use_player_input = false
	_player.combatant.rng = RandomSource.Fixed.new(0.99)
	_player.global_position = Vector2(player_x, 896)
	_player.facing = 1
	_fb = _stage.feedback
	await _frames(10)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _buf() -> float:
	return _player.config.jump_buffer_time


func _hit(ratio: float, sc_mult := 1.0) -> HitInfo:
	var h := HitInfo.new()
	h.atk_ratio = ratio
	h.sc_ratio = ratio * sc_mult
	return h


func _res(crit := false) -> DamageCalculator.Result:
	var r := DamageCalculator.Result.new()
	r.is_crit = crit
	return r


## Chờ tới khi hết hit-stop; trả về số micro-giây thật đã trôi.
func _measure_hitstop() -> int:
	var t0 := Time.get_ticks_usec()
	for i in 600:
		if not _fb.is_hitstopping():
			break
		await get_tree().process_frame
	return Time.get_ticks_usec() - t0


# ---------- Cấu hình ----------

func test_config_within_spec() -> void:
	var c: HitFeedbackConfig = load("res://data/config/hit_feedback.tres")
	for v in [c.hitstop_light_ms, c.hitstop_heavy_ms, c.hitstop_max_ms]:
		assert_float(v).is_between(40.0, 80.0)   # README 15.7: 40-80 ms


func test_hitstop_duration_rules() -> void:
	await _setup()
	assert_float(_fb.hitstop_ms_for(_hit(0.7), _res())).is_equal(45.0)          # nhẹ
	assert_float(_fb.hitstop_ms_for(_hit(1.6), _res())).is_equal(70.0)          # nặng theo % ATK
	assert_float(_fb.hitstop_ms_for(_hit(0.85, 1.5), _res())).is_equal(70.0)    # nặng theo SC ×1.5
	assert_float(_fb.hitstop_ms_for(_hit(0.7), _res(true))).is_equal(55.0)      # chí mạng +10
	assert_float(_fb.hitstop_ms_for(_hit(2.8), _res(true))).is_equal(80.0)      # trần 80


# ---------- Hit-stop ----------

func test_hitstop_freezes_and_restores_in_real_time() -> void:
	await _setup()
	_fb.hitstop(70.0)
	assert_float(Engine.time_scale).is_equal(0.0)
	var usec := await _measure_hitstop()
	assert_float(Engine.time_scale).is_equal(1.0)
	assert_int(usec).is_between(60_000, 200_000)


func test_overlapping_hitstops_take_max_not_sum() -> void:
	await _setup()
	_fb.hitstop(45.0)
	_fb.hitstop(70.0)
	_fb.hitstop(45.0)
	var usec := await _measure_hitstop()
	assert_int(usec).is_between(60_000, 110_000)  # ~70 ms, không phải 160 ms


func test_hitstop_can_be_disabled() -> void:
	await _setup()
	_fb.config = _fb.config.duplicate()
	_fb.config.hitstop_enabled = false
	_fb.hitstop(70.0)
	assert_float(Engine.time_scale).is_equal(1.0)


# ---------- Trúng đòn thật ----------

func test_player_hit_triggers_feedback() -> void:
	await _setup()
	var stopped := [false]
	var numbers_before := _count_numbers()
	_player.intent.tap_attack(_buf())
	for i in 600:
		await get_tree().process_frame
		if _fb.is_hitstopping():
			stopped[0] = true
			break
	assert_bool(stopped[0]).is_true()
	assert_bool(_stage.camera.is_shaking()).is_true()
	assert_int(_count_numbers()).is_greater(numbers_before)
	assert_int(_fb.combo).is_equal(1)
	await _measure_hitstop()


func test_combo_counts_and_resets_after_window() -> void:
	await _setup()
	for k in 3:
		_player.intent.tap_attack(_buf())
		for i in 60:
			await get_tree().physics_frame
			if _fb.combo > k and not _player.runner.is_running():
				break
	# Combo đếm số lần trúng mục tiêu: từ đòn 2 Aether đã tiến đủ gần để chém trúng cả 2 hình nộm.
	assert_int(_fb.combo).is_greater_equal(3)
	await _frames(130)  # > 2.0 s không trúng
	assert_int(_fb.combo).is_equal(0)


func test_player_hurt_resets_combo_and_shows_red_number() -> void:
	await _setup(500.0)
	_fb.add_combo()
	_fb.add_combo()
	var enemy: EnemyController = ENEMY_SCENE.instantiate()
	enemy.position = Vector2(640, 896)
	_stage.add_child(enemy)
	var hurt := [false]
	_player.combatant.damaged.connect(func(_r: DamageCalculator.Result, _h: HitInfo) -> void: hurt[0] = true)
	for i in 120:
		await get_tree().physics_frame
		if hurt[0]:
			break
	assert_bool(hurt[0]).is_true()
	assert_int(_fb.combo).is_equal(0)
	var red := false
	for n in _stage.get_children():
		if n is FloatingNumber and n.kind == FloatingNumber.Kind.PLAYER_HURT:
			red = true
	assert_bool(red).is_true()


func test_dot_shows_number() -> void:
	await _setup()
	var dummy: TrainingDummy = _stage.dummies[0]
	dummy.combatant.statuses.apply("burn", 1.0, -1.0, _player.combatant)
	await _frames(35)
	var dot := false
	for n in _stage.get_children():
		if n is FloatingNumber and n.kind == FloatingNumber.Kind.DOT:
			dot = true
	assert_bool(dot).is_true()


# ---------- Tuyệt kỹ ----------

func test_ultimate_freezes_enemies_and_shows_cut_in() -> void:
	await _setup(500.0)
	var enemy: EnemyController = ENEMY_SCENE.instantiate()
	enemy.position = Vector2(900, 896)
	_stage.add_child(enemy)
	await _frames(5)
	_player.combatant.resources.add_ug(100.0)
	_player.intent.press(PlayerIntent.ULTIMATE, _buf())
	for i in 10:
		await get_tree().physics_frame
		if enemy.is_frozen():
			break
	assert_bool(enemy.is_frozen()).is_true()
	assert_bool(_fb.is_cut_in_showing()).is_true()
	assert_bool(_stage.dummies[0].is_inside_tree()).is_true()
	var x0 := enemy.global_position.x
	await _frames(25)                                    # ~0.4 s: vẫn đứng yên
	assert_float(enemy.global_position.x).is_equal(x0)
	await _frames(20)                                    # quá 600 ms
	assert_bool(enemy.is_frozen()).is_false()
	assert_bool(_fb.is_cut_in_showing()).is_false()


func _count_numbers() -> int:
	var n := 0
	for c in _stage.get_children():
		if c is FloatingNumber:
			n += 1
	return n
