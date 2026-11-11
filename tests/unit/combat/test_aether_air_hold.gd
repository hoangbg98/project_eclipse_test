extends GdUnitTestSuite
## Test M3-5 phần 2: đòn giữ (nạp 2 cấp), đòn trên không (tối đa 2), đáp đất (lao xuống).

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")

var _stage: Node2D
var _player: PlayerController
var _dummy: TrainingDummy
var _hits: Array[int] = []
var _started: Array[String] = []


func before_test() -> void:
	_hits.clear()
	_started.clear()


func _setup(pos := Vector2(820, 896)) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	add_child(_stage)
	_player = _stage.player
	_player.use_player_input = false
	_player.combatant.rng = RandomSource.Fixed.new(0.99)
	_player.global_position = pos
	_player.facing = 1
	_dummy = _stage.dummies[0]
	_dummy.combatant.damaged.connect(func(r: DamageCalculator.Result, _h: HitInfo) -> void: _hits.append(r.amount))
	_player.runner.skill_started.connect(func(k: String, _s: SkillDef) -> void: _started.append(k))
	await _frames(20)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _buf() -> float:
	return _player.config.jump_buffer_time


## Giữ nút đánh `ms` mili-giây rồi nhả.
func _hold(ms: float) -> void:
	_player.intent.attack_down()
	await _frames(int(ceil(ms / (1000.0 / 60.0))))
	_player.intent.attack_up(_buf())


func _wait_skill_end(max_frames := 180) -> void:
	for i in 10:
		if _player.runner.is_running():
			break
		await get_tree().physics_frame
	for i in max_frames:
		if not _player.runner.is_running():
			return
		await get_tree().physics_frame


# ---------- Dữ liệu ----------

func test_data_matches_document() -> void:
	var s := (load("res://data/characters/char_fire_01.tres") as CharacterDef).load_skills()
	assert_float(s["hold_1"].total_atk_ratio()).is_equal_approx(1.6, 0.0001)
	assert_float(s["hold_2"].total_atk_ratio()).is_equal_approx(2.8, 0.0001)
	assert_float(s["air_1"].total_atk_ratio() + s["air_2"].total_atk_ratio()).is_equal_approx(1.55, 0.0001)
	assert_float(s["landing"].total_atk_ratio()).is_equal_approx(1.4, 0.0001)
	assert_str(s["hold_1"].cooldown_key()).is_equal("hold")
	assert_str(s["hold_2"].cooldown_key()).is_equal("hold")
	for k in ["hold_1", "hold_2", "air_1", "air_2", "landing"]:
		assert_array(s[k].validate()).is_empty()


# ---------- Đòn giữ ----------

func test_short_hold_is_normal_attack() -> void:
	await _setup()
	await _hold(250)
	await _wait_skill_end()
	assert_array(_started).contains_exactly(["normal_1"])


func test_hold_level_1_at_700ms() -> void:
	await _setup()
	_player.intent.attack_down()
	await _frames(30)  # 500 ms: đang nạp
	assert_str(String(_player.current_state())).is_equal("charge")
	await _frames(15)  # tổng 750 ms
	var en0 := _player.combatant.resources.en
	_player.intent.attack_up(_buf())
	await _wait_skill_end()
	await _frames(3)
	assert_array(_started).contains_exactly(["hold_1"])
	assert_array(_hits).contains_exactly([800])                     # 1000 × 160% × 0.5
	var gained := _player.combatant.resources.en - en0
	assert_float(gained).is_between(6.0, 7.5)                       # +6 khi trúng (+ hồi theo giây)


func test_hold_between_400_and_700_is_normal() -> void:
	await _setup()
	await _hold(550)
	await _wait_skill_end()
	assert_array(_started).contains_exactly(["normal_1"])


func test_hold_level_2_at_1500ms_burns() -> void:
	await _setup()
	await _hold(1550)
	for i in 10:
		if _player.runner.is_running():
			break
		await get_tree().physics_frame
	assert_bool(_player.runner.has_super_armor()).is_true()        # kháng khựng khi nhả
	await _wait_skill_end()
	await _frames(20)
	assert_array(_started).contains_exactly(["hold_2"])
	assert_array(_hits).contains_exactly([1400])                    # 1000 × 280% × 0.5
	assert_bool(_dummy.combatant.statuses.has("burn")).is_true()


func test_charging_slows_movement() -> void:
	await _setup(Vector2(400, 896))
	_player.intent.attack_down()
	_player.intent.move_x = 1.0
	await _frames(40)
	assert_str(String(_player.current_state())).is_equal("charge")
	assert_float(_player.velocity.x).is_equal_approx(450.0 * 0.6, 1.0)  # chậm 40%
	_player.intent.move_x = 0.0
	_player.intent.attack_up(_buf())


func test_hold_cooldown_one_second() -> void:
	await _setup()
	await _hold(750)
	await _wait_skill_end()  # đòn Cấp 1 dài 560 ms → còn ~440 ms hồi
	assert_str(_player.runner.check("hold_1")).is_equal("cooldown")
	assert_str(_player.runner.check("hold_2")).is_equal("cooldown")  # dùng chung khóa "hold"
	assert_float(_player.combatant.cooldowns.remaining(&"hold")).is_between(0.3, 0.5)
	await _frames(30)
	assert_str(_player.runner.check("hold_1")).is_equal("")


# ---------- Trên không ----------

func test_two_air_attacks_per_jump() -> void:
	await _setup(Vector2(400, 896))
	_player.intent.press_jump(_buf())
	await _frames(6)
	_player.intent.tap_attack(_buf())
	await _frames(3)
	assert_str(String(_player.current_state())).is_equal("attack")
	# bấm nối trong cửa sổ của đòn 1
	for f in 30:
		if _player.runner.can_queue_chain():
			break
		await get_tree().physics_frame
	_player.intent.tap_attack(_buf())
	for f in 40:
		if _player.runner.current_key == "air_2":
			break
		await get_tree().physics_frame
	assert_int(_player.air_attacks_used).is_equal(2)
	await _wait_skill_end()
	_player.intent.tap_attack(_buf())  # lần thứ 3: chỉ còn đáp đất nếu đủ cao
	await _frames(3)
	assert_int(_started.count("air_1") + _started.count("air_2")).is_equal(2)
	await _frames(90)
	assert_bool(_player.is_on_floor()).is_true()
	assert_int(_player.air_attacks_used).is_equal(0)                 # chạm đất: đếm lại


func test_air_2_hangs_after_hit() -> void:
	await _setup(Vector2(400, 896))
	_player.intent.press_jump(_buf())
	await _frames(6)
	_player.intent.tap_attack(_buf())
	for f in 30:
		if _player.runner.can_queue_chain():
			break
		await get_tree().physics_frame
	_player.intent.tap_attack(_buf())
	for f in 60:
		var r := _player.runner
		if r.current_key == "air_2" and r.elapsed_ms > 200.0 and r.elapsed_ms < 320.0:
			assert_float(_player.velocity.y).is_equal(0.0)              # treo 150 ms sau đòn 2
			return
		await get_tree().physics_frame
	fail("không thấy pha treo của đòn trên không 2")


# ---------- Đáp đất ----------

func test_plunge_from_height_explodes_and_burns() -> void:
	await _setup(Vector2(900, 896))
	_player.global_position = Vector2(900, 896 - 500)
	_player.air_attacks_used = 1
	_player.velocity = Vector2(0, 50)
	await _frames(2)
	_player.intent.tap_attack(_buf())
	await _frames(3)
	assert_str(String(_player.current_state())).is_equal("plunge")
	for f in 60:
		if _started.has("landing"):
			break
		await get_tree().physics_frame
	assert_array(_started).contains(["landing"])
	assert_float(_player.global_position.y).is_equal_approx(896.0, 2.0)
	await _wait_skill_end()
	assert_array(_hits).contains([700])                             # 1000 × 140% × 0.5
	assert_bool(_dummy.combatant.statuses.has("burn")).is_true()


func test_plunge_needs_height() -> void:
	await _setup(Vector2(400, 896))
	_player.global_position = Vector2(400, 896 - 120)  # thấp hơn 200 px
	_player.air_attacks_used = 1
	_player.velocity = Vector2(0, 50)
	await _frames(1)
	_player.intent.tap_attack(_buf())
	await _frames(3)
	assert_str(String(_player.current_state())).is_not_equal("plunge")
	assert_array(_started).contains(["air_2"])


func test_plunge_needs_an_air_attack_first() -> void:
	await _setup(Vector2(400, 896))
	_player.global_position = Vector2(400, 896 - 500)
	_player.air_attacks_used = 0
	_player.velocity = Vector2(0, 50)
	await _frames(1)
	_player.intent.tap_attack(_buf())
	await _frames(3)
	assert_array(_started).contains(["air_1"])
	assert_str(String(_player.current_state())).is_not_equal("plunge")
