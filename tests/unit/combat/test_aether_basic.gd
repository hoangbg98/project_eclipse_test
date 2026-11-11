extends GdUnitTestSuite
## Test M3-5 phần 1: dữ liệu Aether, chuỗi 4 đòn thường, né, hình nộm nhận sát thương.
## Chạy trên màn thử nghiệm với vòng vật lý thật của engine (va chạm cần khung vật lý).

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")
const SKILLS := "res://data/skills/char_fire_01"

var _stage: Node2D
var _player: PlayerController
var _dummy: TrainingDummy
var _hits: Array[int] = []


func before_test() -> void:
	_hits.clear()


func _setup(player_x := 820.0) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	add_child(_stage)
	_player = _stage.player
	_player.use_player_input = false
	_player.combatant.rng = RandomSource.Fixed.new(0.99)  # không chí mạng
	_player.global_position = Vector2(player_x, 896)
	_player.facing = 1
	_dummy = _stage.dummies[0]
	_dummy.combatant.damaged.connect(func(r: DamageCalculator.Result, _h: HitInfo) -> void: _hits.append(r.amount))
	await _frames(20)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _buf() -> float:
	return _player.config.jump_buffer_time


## Chờ kỹ năng bắt đầu (state đổi ở khung vật lý kế tiếp) rồi chờ tới khi không còn kỹ năng nào chạy.
func _wait_idle(max_frames := 120) -> void:
	for i in 5:
		if _player.runner.is_running():
			break
		await get_tree().physics_frame
	for i in max_frames:
		if not _player.runner.is_running():
			return
		await get_tree().physics_frame


# ---------- Dữ liệu ----------

func test_skill_data_matches_document() -> void:
	var c: CharacterDef = load("res://data/characters/char_fire_01.tres")
	var skills := c.load_skills()
	for k in ["normal_1", "normal_2", "normal_3", "normal_4", "dodge"]:
		assert_bool(skills.has(k)).override_failure_message("thiếu " + k).is_true()
		assert_array(skills[k].validate()).is_empty()
	# Hỏa Trảm: 70 / 75 / 85 / 125 (85 + 40) = 355% ATK
	var total := 0.0
	for k in ["normal_1", "normal_2", "normal_3", "normal_4"]:
		total += skills[k].total_atk_ratio()
	assert_float(total).is_equal_approx(3.55, 0.0001)
	assert_float(skills["normal_4"].total_ms()).is_equal(600.0)       # 160/120/320
	assert_float(skills["normal_1"].chain_window_ms).is_equal(260.0)
	assert_str(skills["normal_3"].next_skill).is_equal("normal_4")
	var d: SkillDef = skills["dodge"]
	assert_bool(d.is_invulnerable_at(39.0)).is_false()
	assert_bool(d.is_invulnerable_at(40.0)).is_true()
	assert_bool(d.is_invulnerable_at(219.0)).is_true()
	assert_bool(d.is_invulnerable_at(220.0)).is_false()
	assert_float(d.move_px).is_equal(280.0)
	assert_float(d.total_atk_ratio()).is_equal_approx(0.5, 0.0001)    # vệt lửa 2 × 25%


func test_character_stats_loaded_into_combatant() -> void:
	await _setup()
	assert_float(_player.combatant.resources.max_hp).is_equal(12000.0)
	assert_float(_player.combatant.stats.atk).is_equal(1000.0)


# ---------- Đòn thường ----------

func test_first_hit_damages_dummy_once() -> void:
	await _setup()
	_player.intent.tap_attack(_buf())
	await _wait_idle()
	await _frames(5)
	# ATK 1000 × 70%, DEF 500 → 350; một nhát chỉ trúng một lần
	assert_array(_hits).contains_exactly([350])
	assert_float(_player.combatant.resources.ug).is_equal_approx(2.0, 0.01)  # +2 UG mỗi đòn thường


func test_full_combo_chains_and_burns() -> void:
	await _setup()
	var started: Array[String] = []
	_player.runner.skill_started.connect(func(k: String, _s: SkillDef) -> void: started.append(k))
	_player.intent.tap_attack(_buf())
	for k in [1, 2, 3]:
		# bấm trong cửa sổ nối đòn (260 ms cuối) của đòn thứ k
		for f in 90:
			if _player.runner.current_key == "normal_%d" % k and _player.runner.can_queue_chain():
				break
			await get_tree().physics_frame
		_player.intent.tap_attack(_buf())
		await _frames(2)
	await _wait_idle()
	await _frames(30)
	assert_array(started).override_failure_message("started=%s hits=%s" % [started, _hits]) \
			.contains_exactly(["normal_1", "normal_2", "normal_3", "normal_4"])
	# 350, 375, 425 + đòn 4: kiếm 425, sóng lửa 200 (thứ tự sóng/kiếm có thể đổi)
	assert_array(_hits.slice(0, 3)).contains_exactly([350, 375, 425])
	assert_array(_hits.slice(3, 5)).contains_exactly_in_any_order([425, 200])
	assert_bool(_dummy.combatant.statuses.has("burn")).is_true()        # đòn 4 áp Cháy 3s


func test_burn_ticks_on_dummy() -> void:
	await _setup()
	var dots: Array[int] = []
	_dummy.combatant.dot_damaged.connect(func(a: int, _s: String) -> void: dots.append(a))
	_dummy.combatant.statuses.apply("burn", 3.0, -1.0, _player.combatant)
	await _frames(190)  # > 3 s
	# 3 s / 0.5 s = 6 nhịp × (1000 × 8% × 0.5) = 40
	assert_int(dots.size()).is_equal(6)
	assert_int(dots[0]).is_equal(40)


func test_combo_resets_after_pause() -> void:
	await _setup()
	_player.intent.tap_attack(_buf())
	await _wait_idle()
	assert_str(_player.runner.next_normal_key()).is_equal("normal_2")
	await _frames(60)  # 1.0 s > 0.8 s
	assert_str(_player.runner.next_normal_key()).is_equal("normal_1")


func test_attack_moves_forward_40px() -> void:
	await _setup(400.0)  # xa hình nộm
	var x0 := _player.global_position.x
	_player.intent.tap_attack(_buf())
	await _wait_idle()
	assert_float(_player.global_position.x - x0).is_equal_approx(40.0, 3.0)


# ---------- Né ----------

func test_dodge_dashes_and_is_invulnerable() -> void:
	await _setup(400.0)
	var x0 := _player.global_position.x
	_player.intent.press(PlayerIntent.DODGE, _buf())
	await _frames(2)
	assert_str(String(_player.current_state())).is_equal("dodge")
	assert_int(_player.combatant.resources.dodge_charges).is_equal(1)
	await _frames(6)  # ~100 ms: trong khung bất tử 40-220 ms
	assert_bool(_player.hurtbox.invulnerable).is_true()
	await _wait_idle()
	assert_bool(_player.hurtbox.invulnerable).is_false()
	assert_float(_player.global_position.x - x0).is_equal_approx(280.0, 10.0)


func test_dodge_follows_held_direction() -> void:
	await _setup(600.0)
	var x0 := _player.global_position.x
	_player.intent.move_x = -1.0
	_player.intent.press(PlayerIntent.DODGE, _buf())
	await _frames(2)
	_player.intent.move_x = 0.0
	await _wait_idle()
	assert_float(x0 - _player.global_position.x).is_greater(250.0)
	assert_int(_player.facing).is_equal(-1)


func test_dodge_trail_burns_dummy() -> void:
	await _setup(700.0)  # lướt xuyên qua hình nộm (x = 928)
	_player.intent.press(PlayerIntent.DODGE, _buf())
	await _frames(70)
	# vệt lửa 25% ATK → 125, hai nhịp trong 0.8 s
	assert_array(_hits).contains_exactly([125, 125])
	assert_float(_player.combatant.resources.en).is_less(5.0)  # vệt lửa không nạp EN (chỉ hồi theo giây)


func test_no_dodge_without_charges() -> void:
	await _setup(400.0)
	_player.combatant.resources.dodge_charges = 0
	_player.intent.press(PlayerIntent.DODGE, _buf())
	await _frames(3)
	assert_str(String(_player.current_state())).is_not_equal("dodge")


func test_dodge_cancels_late_recovery_only() -> void:
	await _setup(400.0)
	_player.intent.tap_attack(_buf())
	await _frames(3)
	_player.intent.press(PlayerIntent.DODGE, 0.03)  # sớm: chưa tới nửa sau hồi phục
	await _frames(3)
	assert_str(String(_player.current_state())).is_equal("attack")
	# nửa sau hồi phục của đòn 1: 90 + 70 + 80 = 240 ms
	for f in 30:
		if _player.runner.can_dodge_cancel():
			break
		await get_tree().physics_frame
	_player.intent.press(PlayerIntent.DODGE, _buf())
	await _frames(2)
	assert_str(String(_player.current_state())).is_equal("dodge")
