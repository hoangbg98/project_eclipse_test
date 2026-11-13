extends GdUnitTestSuite
## Kazeyumi (char_wind_01) và Raikiba (char_lightning_01): đòn giữ, trên không, đáp đất, Kĩ năng thường,
## Kĩ năng vũ khí, Tuyệt kỹ (CHARACTER_SKILLS mục 2, 3; tools/gen_wind_lightning_skills.py).

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")

var _stage: Node2D
var _p: PlayerController
var _started: Array[String] = []


func before_test() -> void:
	_started.clear()


func after_test() -> void:
	Engine.time_scale = 1.0


func _setup(id: String, x := 820.0) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.spawn_enemies = false
	_stage.party_ids = PackedStringArray([id])
	add_child(_stage)
	_stage.party.use_player_input = false
	_p = _stage.player
	_p.use_player_input = false
	_p.combatant.rng = RandomSource.Fixed.new(0.99)
	_p.global_position = Vector2(x, 896)
	_p.facing = 1
	_p.runner.skill_started.connect(func(k: String, _s: SkillDef) -> void: _started.append(k))
	for i in 30:
		await get_tree().physics_frame
		if _p.is_on_floor():
			break


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _buf() -> float:
	return _p.config.jump_buffer_time


func _dummy(i: int) -> TrainingDummy:
	return _stage.dummies[i]


func _skills(id: String) -> Dictionary:
	return (load("res://data/characters/%s.tres" % id) as CharacterDef).load_skills()


func _watch(c: Combatant, into: Array) -> void:
	c.damaged.connect(func(_r: DamageCalculator.Result, h: HitInfo) -> void: into.append(h.skill_id))


func _wait_done(max_frames := 240) -> void:
	for i in 10:
		if _p.runner.is_running():
			break
		await get_tree().physics_frame
	for i in max_frames:
		if not _p.runner.is_running():
			return
		await get_tree().physics_frame


func _press(action: StringName) -> void:
	_p.intent.press(action, _buf())


# ---------- Dữ liệu ----------

func test_kazeyumi_data_matches_spec() -> void:
	var s := _skills("char_wind_01")
	for k in ["hold_1", "hold_2", "air_1", "air_2", "landing", "skill", "weapon", "ultimate"]:
		assert_bool(s.has(k)).override_failure_message("thiếu " + k).is_true()
		assert_array(s[k].validate()).is_empty()
	assert_float(s["hold_1"].total_atk_ratio()).is_equal_approx(1.80, 0.0001)
	assert_float(s["hold_2"].total_atk_ratio()).is_equal_approx(3.00, 0.0001)
	assert_array([s["hold_1"].charge_start_ms, s["hold_1"].charge_level_ms, s["hold_2"].charge_level_ms]).is_equal([500.0, 900.0, 1600.0])
	assert_float(s["air_1"].total_atk_ratio()).is_equal_approx(1.35, 0.0001)         # 45% x3
	assert_float(s["landing"].total_atk_ratio()).is_equal_approx(1.20, 0.0001)       # 60% + 20% x3
	assert_float(s["skill"].total_atk_ratio()).is_equal_approx(2.40, 0.0001)         # 20% x12
	assert_array([s["skill"].en_cost, s["skill"].cooldown_sec]).is_equal([20.0, 10.0])
	assert_float(s["weapon"].total_atk_ratio()).is_equal_approx(3.60, 0.0001)        # 60% x6
	assert_array([s["weapon"].en_cost, s["weapon"].cooldown_sec]).is_equal([35.0, 13.0])
	assert_float(s["ultimate"].total_atk_ratio()).is_equal_approx(10.0, 0.0001)      # 35% x20 + 300%
	assert_bool(s["ultimate"].locks_switch).is_false()                               # loại vùng


func test_raikiba_data_matches_spec() -> void:
	var s := _skills("char_lightning_01")
	for k in ["hold_1", "air_1", "air_2", "air_3", "landing", "skill", "weapon", "ultimate"]:
		assert_bool(s.has(k)).override_failure_message("thiếu " + k).is_true()
		assert_array(s[k].validate()).is_empty()
	assert_float(s["hold_1"].total_atk_ratio()).is_equal_approx(2.40, 0.0001)        # 30% x8
	assert_float(s["air_1"].total_atk_ratio() + s["air_2"].total_atk_ratio() + s["air_3"].total_atk_ratio()) \
			.is_equal_approx(1.50, 0.0001)
	assert_float(s["landing"].total_atk_ratio()).is_equal_approx(1.30, 0.0001)
	assert_float(s["landing"].dive_angle_deg).is_equal(45.0)
	assert_float(s["skill"].total_atk_ratio()).is_equal_approx(2.10, 0.0001)         # 70% x3
	assert_float(s["weapon"].total_atk_ratio()).is_equal_approx(2.00, 0.0001)        # 50% x4
	assert_float(s["ultimate"].total_atk_ratio()).is_equal_approx(10.9, 0.0001)      # 80% x8 + 450%
	assert_bool(s["ultimate"].locks_switch).is_true()                                # loại chuỗi đòn


# ---------- Kazeyumi ----------

func test_kazeyumi_skill_zone_ticks_slows_and_buffs() -> void:
	await _setup("char_wind_01", 520.0)
	var hits := []
	_watch(_dummy(0).combatant, hits)
	_p.combatant.resources.en = 100.0
	_press(PlayerIntent.SKILL)
	await _frames(3)
	assert_array(_started).contains(["skill"])
	assert_float(_p.combatant.statuses.attack_speed_up()).is_equal(0.15)
	assert_float(_p.combatant.statuses.move_speed_up()).is_equal(0.10)
	await _frames(80)
	assert_int(hits.count("char_wind_01.skill")).is_greater_equal(2)                 # vùng gây sát thương nhiều nhịp
	assert_bool(_dummy(0).combatant.statuses.has("slow")).is_true()


func test_kazeyumi_weapon_hops_back_and_fires_six() -> void:
	await _setup("char_wind_01", 600.0)
	var hits := []
	_watch(_dummy(0).combatant, hits)
	_p.combatant.resources.en = 100.0
	_press(PlayerIntent.WEAPON)
	await _wait_done()
	await _frames(30)
	assert_float(600.0 - _p.global_position.x).is_equal_approx(150.0, 12.0)
	assert_int(hits.count("char_wind_01.weapon")).is_equal(6)


func test_kazeyumi_two_fan_shots_per_jump() -> void:
	await _setup("char_wind_01", 400.0)
	_p.intent.press_jump(_buf())
	await _frames(6)
	_p.intent.tap_attack(_buf())
	for f in 30:
		if _p.runner.can_queue_chain():
			break
		await get_tree().physics_frame
	_p.intent.tap_attack(_buf())
	await _frames(40)
	assert_array(_started).is_equal(["air_1", "air_2"])
	assert_int(_p.air_attacks_used).is_equal(2)


func test_kazeyumi_hold_level_2_pierces() -> void:
	await _setup("char_wind_01", 600.0)
	var h0 := []
	var h1 := []
	_watch(_dummy(0).combatant, h0)
	_watch(_dummy(1).combatant, h1)
	_p.intent.attack_down()
	await _frames(100)                                                              # ~1670 ms
	_p.intent.attack_up(_buf())
	await _wait_done()
	await _frames(30)
	assert_array(_started).contains_exactly(["hold_2"])
	assert_bool(h0.has("char_wind_01.hold_2") and h1.has("char_wind_01.hold_2")).is_true()


func test_kazeyumi_ultimate_storm_hits_and_switch_allowed() -> void:
	await _setup("char_wind_01", 820.0)
	var hits := []
	_watch(_dummy(0).combatant, hits)
	_p.combatant.resources.ug = 100.0
	_press(PlayerIntent.ULTIMATE)
	await _frames(3)
	assert_array(_started).contains(["ultimate"])
	assert_bool(_p.is_switch_locked()).is_false()
	assert_float(_p.combatant.statuses.move_speed_up()).is_equal(0.20)
	await _frames(90)
	assert_int(hits.count("char_wind_01.ultimate")).is_greater_equal(3)


# ---------- Raikiba ----------

func test_raikiba_hold_fires_while_held_and_release_stops() -> void:
	await _setup("char_lightning_01", 700.0)
	var hits := []
	_watch(_dummy(0).combatant, hits)
	_p.intent.attack_down()
	await _frames(30)                                                               # 500 ms: đã quá 350 ms
	assert_str(_p.runner.current_key).is_equal("hold_1")                            # chạy khi vẫn đang giữ
	await _frames(20)
	_p.intent.attack_up(_buf())
	await _frames(2)
	assert_bool(_p.runner.is_running()).is_false()                                  # nhả: dừng sớm
	var n := hits.count("char_lightning_01.hold_1")
	assert_int(n).is_between(1, 7)
	assert_str(_p.runner.check("hold_1")).is_equal("cooldown")


func test_raikiba_three_air_attacks() -> void:
	await _setup("char_lightning_01", 400.0)
	_p.intent.press_jump(_buf())
	await _frames(6)
	for n in 3:
		_p.intent.tap_attack(_buf())
		for f in 40:
			await get_tree().physics_frame
			if _started.size() == n + 1 and _p.runner.can_queue_chain():
				break
	await _wait_done()
	assert_array(_started).is_equal(["air_1", "air_2", "air_3"])


func test_raikiba_landing_dives_diagonally() -> void:
	await _setup("char_lightning_01", 500.0)
	_p.global_position = Vector2(500, 896 - 400)
	_p.air_attacks_used = 1
	_p.velocity = Vector2(0, 50)
	await _frames(2)
	_p.intent.tap_attack(_buf())
	for f in 60:
		if _started.has("landing"):
			break
		await get_tree().physics_frame
	assert_array(_started).contains(["landing"])
	assert_float(_p.global_position.x - 500.0).is_greater(250.0)                    # lao chéo 45° về phía trước


func test_raikiba_skill_dash_marks() -> void:
	await _setup("char_lightning_01", 700.0)
	_p.combatant.resources.en = 100.0
	_press(PlayerIntent.SKILL)
	await _wait_done()
	assert_float(_p.global_position.x - 700.0).is_equal_approx(350.0, 15.0)
	# 3 nhát x 2 Dấu Sét = đủ 3 → Bùng nổ (dấu bị xóa) ít nhất một lần.
	assert_int(_p.kit.bursts).is_greater_equal(1)


func test_raikiba_weapon_blocks_normal_800ms() -> void:
	await _setup("char_lightning_01", 700.0)
	var hits := []
	_watch(_dummy(0).combatant, hits)
	_p.combatant.resources.en = 100.0
	_press(PlayerIntent.WEAPON)
	await _wait_done()
	_p.intent.tap_attack(_buf())
	await _frames(2)
	assert_bool(_started.has("normal_1")).is_false()
	await _frames(40)
	assert_int(hits.count("char_lightning_01.weapon")).is_equal(4)                  # hai đao x đi và về (200%)
	_p.intent.tap_attack(_buf())
	await _frames(2)
	assert_bool(_started.has("normal_1")).is_true()


func test_raikiba_ultimate_teleports_and_locks_switch() -> void:
	await _setup("char_lightning_01", 500.0)
	var hits := []
	_watch(_dummy(0).combatant, hits)
	_p.combatant.resources.ug = 100.0
	_press(PlayerIntent.ULTIMATE)
	await _frames(3)
	assert_bool(_p.is_switch_locked()).is_true()
	assert_float(absf(_p.global_position.x - _dummy(0).global_position.x)).is_less(120.0)
	assert_float(_p.combatant.statuses.attack_speed_up()).is_equal(0.25)
	await _wait_done()
	await _frames(5)
	assert_int(hits.count("char_lightning_01.ultimate")).is_greater_equal(8)
