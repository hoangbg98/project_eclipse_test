extends GdUnitTestSuite
## Test M4-6: Kael và Lyra — đòn thường, né, Bùng nổ Sét, né hoàn hảo (CHARACTER_SKILLS mục 2, 3; phạm vi Q5).

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")

var _stage: Node2D
var _p: PlayerController


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
	for i in 30:
		await get_tree().physics_frame
		if _p.is_on_floor():
			break


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _dummy(i: int) -> TrainingDummy:
	return _stage.dummies[i]


func _skills(id: String) -> Dictionary:
	return (load("res://data/characters/%s.tres" % id) as CharacterDef).load_skills()


func _watch(c: Combatant, into: Array) -> void:
	c.damaged.connect(func(_r: DamageCalculator.Result, h: HitInfo) -> void: into.append(h.skill_id))


func _wait_done() -> void:
	for i in 120:
		await get_tree().physics_frame
		if not _p.runner.is_running():
			return


# ---------- Dữ liệu ----------

func test_kael_data_matches_spec() -> void:
	var s := _skills("char_lightning_01")
	var total := 0.0
	for n in range(1, 6):
		var d: SkillDef = s["normal_%d" % n]
		assert_array(d.validate()).is_empty()
		total += d.total_atk_ratio()
		assert_float(d.move_px).is_equal(50.0)
		assert_int(d.hits[0].statuses.size()).is_equal(1 if n in [2, 4, 5] else 0)   # Dấu Sét ở đòn 2, 4, 5
		if n < 5:
			assert_array([d.startup_ms, d.active_ms, d.recovery_ms]).is_equal([70.0, 50.0, 110.0])
			assert_str(d.next_skill).is_equal("normal_%d" % (n + 1))
	assert_float(total).is_equal_approx(3.10, 0.0001)                              # 45+45+55+55+110
	assert_float(s["normal_5"].hits[0].knockback_px).is_equal(80.0)
	assert_array([s["normal_5"].startup_ms, s["normal_5"].active_ms, s["normal_5"].recovery_ms]).is_equal([130.0, 90.0, 260.0])
	var dg: SkillDef = s["dodge"]
	assert_array([dg.startup_ms, dg.active_ms, dg.recovery_ms]).is_equal([20.0, 180.0, 100.0])
	assert_array([dg.move_px, dg.invuln_from_ms, dg.invuln_to_ms]).is_equal([320.0, 20.0, 200.0])
	assert_float(dg.total_atk_ratio()).is_equal_approx(0.40, 0.0001)
	var k: LightningKitConfig = load("res://data/characters/char_lightning_01_kit.tres")
	assert_array([k.burst.atk_ratio, k.burst.radius_px, k.burst.sc_multiplier, k.burst_icd_per_target_sec]).is_equal([1.5, 140.0, 2.0, 4.0])
	assert_array([k.counter.atk_ratio, k.counter.radius_px]).is_equal([0.8, 150.0])
	assert_int(k.counter.statuses.size()).is_equal(2)


func test_lyra_data_matches_spec() -> void:
	var s := _skills("char_wind_01")
	var total := 0.0
	for n in range(1, 4):
		var d: SkillDef = s["normal_%d" % n]
		assert_array(d.validate()).is_empty()
		total += d.total_atk_ratio()
		assert_float(d.hits[0].travel_px).is_equal(700.0)
		assert_float(d.hits[0].travel_px / (d.hits[0].duration_ms / 1000.0)).is_equal_approx(1800.0, 5.0)   # 1800 px/s
		assert_int(d.hits[0].max_targets).is_equal(2 if n == 3 else 1)             # phát 3 xuyên 2 mục tiêu
	assert_float(total).is_equal_approx(2.00, 0.0001)                              # 55+55+90
	assert_array([s["normal_3"].startup_ms, s["normal_3"].active_ms, s["normal_3"].recovery_ms]).is_equal([180.0, 60.0, 260.0])
	var slow: StatusApplication = s["normal_3"].hits[0].statuses[0]
	assert_array([slow.status_id, slow.duration, slow.magnitude]).is_equal(["slow", 2.0, 0.20])
	var dg: SkillDef = s["dodge"]
	assert_array([dg.startup_ms, dg.active_ms, dg.recovery_ms]).is_equal([30.0, 160.0, 110.0])
	assert_array([dg.move_px, dg.invuln_from_ms, dg.invuln_to_ms]).is_equal([-240.0, 30.0, 190.0])
	assert_float(dg.hits[0].travel_px).is_equal(500.0)
	var w: WindKitConfig = load("res://data/characters/char_wind_01_kit.tres")
	assert_array([w.perfect_dodge_speed, w.perfect_dodge_speed_sec, w.perfect_dodge_en]).is_equal([0.25, 3.0, 5.0])


# ---------- Kael ----------

func test_kael_five_hit_combo_marks_and_bursts() -> void:
	await _setup("char_lightning_01", 840.0)
	var hits := []
	_watch(_dummy(0).combatant, hits)
	var keys := []
	_p.runner.skill_started.connect(func(k: String, _s: SkillDef) -> void: keys.append(k))
	_p.intent.tap_attack(_p.config.jump_buffer_time)
	for i in 200:
		await get_tree().physics_frame
		if _p.runner.is_running() and _p.runner.can_queue_chain() and not _p.runner.has_queued():
			_p.intent.tap_attack(_p.config.jump_buffer_time)
		if keys.size() == 5 and not _p.runner.is_running():
			break
	assert_array(keys).is_equal(["normal_1", "normal_2", "normal_3", "normal_4", "normal_5"])
	await _frames(12)
	# Dấu Sét ở đòn 2, 4, 5 → đủ 3 → Bùng nổ Sét, xóa dấu.
	assert_int(_p.kit.bursts).is_equal(1)
	assert_bool(hits.has("char_lightning_01.burst")).is_true()
	assert_bool(_dummy(1).combatant.statuses.has("lightning_mark")).is_false()
	assert_float(_p.combatant.statuses.attack_speed_up()).is_equal(0.10)            # +10% tốc độ tấn công
	assert_float(_p.global_position.x).is_greater(840.0 + 150.0)                    # mỗi đòn tiến 50 px


func test_kael_burst_icd_4s_per_target() -> void:
	await _setup("char_lightning_01")
	var d := _dummy(0).combatant
	for i in 3:
		d.statuses.apply("lightning_mark", -1.0, -1.0, _p.combatant)
	await _frames(2)
	assert_int(_p.kit.bursts).is_equal(1)
	for i in 3:
		d.statuses.apply("lightning_mark", -1.0, -1.0, _p.combatant)
	await _frames(2)
	assert_int(_p.kit.bursts).is_equal(1)                                           # còn ICD
	_p.kit.tick(4.1)
	d.statuses.remove("lightning_mark")
	for i in 3:
		d.statuses.apply("lightning_mark", -1.0, -1.0, _p.combatant)
	assert_int(_p.kit.bursts).is_equal(2)
	# Mục tiêu khác không bị ICD của mục tiêu này chặn.
	for i in 3:
		_dummy(1).combatant.statuses.apply("lightning_mark", -1.0, -1.0, _p.combatant)
	assert_int(_p.kit.bursts).is_equal(3)


func test_kael_marks_from_others_do_not_burst() -> void:
	await _setup("char_lightning_01")
	for i in 3:
		_dummy(0).combatant.statuses.apply("lightning_mark", -1.0, -1.0, null)
	assert_int(_p.kit.bursts).is_equal(0)


func test_kael_dodge_blinks_320_through_enemy_and_damages() -> void:
	await _setup("char_lightning_01", 780.0)
	var hits := []
	_watch(_dummy(0).combatant, hits)
	_p.intent.press(PlayerIntent.DODGE, _p.config.jump_buffer_time)
	await _frames(4)
	assert_bool(_p.hurtbox.invulnerable).is_true()
	await _wait_done()
	assert_float(_p.global_position.x - 780.0).is_equal_approx(320.0, 12.0)
	assert_float(_p.global_position.x).is_greater(_dummy(0).global_position.x)      # hiện ra sau lưng
	assert_bool(hits.has("char_lightning_01.dodge")).is_true()


func test_kael_perfect_dodge_counter_at_origin() -> void:
	await _setup("char_lightning_01", 900.0)
	_p.intent.press(PlayerIntent.DODGE, _p.config.jump_buffer_time)
	await _frames(3)
	_p.perfect_dodged.emit(HitInfo.new())
	await _frames(10)
	# Hình nộm ở 928 nằm trong 150 px quanh điểm xuất phát 900: nhận 2 Dấu Sét.
	assert_int(_dummy(0).combatant.statuses.stacks("lightning_mark")).is_equal(2)


# ---------- Lyra ----------

func test_lyra_arrow_stops_at_first_target_third_pierces_two() -> void:
	await _setup("char_wind_01", 600.0)
	var h0 := []
	var h1 := []
	_watch(_dummy(0).combatant, h0)
	_watch(_dummy(1).combatant, h1)
	_p.intent.tap_attack(_p.config.jump_buffer_time)
	await _wait_done()
	await _frames(30)
	assert_array(h0).is_equal(["char_wind_01.normal_1"])
	assert_array(h1).is_empty()                                                     # tên thường dừng ở mục tiêu đầu
	_p.runner.run("normal_3", 1)
	await _wait_done()
	await _frames(30)
	assert_bool(h0.has("char_wind_01.normal_3") and h1.has("char_wind_01.normal_3")).is_true()
	assert_float(_dummy(1).combatant.statuses.magnitude("slow")).is_equal(0.20)


func test_lyra_arrow_range_is_700() -> void:
	await _setup("char_wind_01", 90.0)                                              # hình nộm gần nhất cách 838 px (tên tới ~785)
	var h0 := []
	_watch(_dummy(0).combatant, h0)
	_p.intent.tap_attack(_p.config.jump_buffer_time)
	await _wait_done()
	await _frames(40)
	assert_array(h0).is_empty()


func test_lyra_dodge_flips_back_and_shoots_forward() -> void:
	await _setup("char_wind_01", 700.0)
	var h0 := []
	_watch(_dummy(0).combatant, h0)
	_p.intent.press(PlayerIntent.DODGE, _p.config.jump_buffer_time)
	await _wait_done()
	await _frames(25)
	assert_float(700.0 - _p.global_position.x).is_equal_approx(240.0, 12.0)         # lùi 240 px
	assert_int(_p.facing).is_equal(1)                                               # vẫn nhìn về trước
	assert_array(h0).is_equal(["char_wind_01.dodge"])


func test_lyra_perfect_dodge_wind_step_and_en() -> void:
	await _setup("char_wind_01")
	_p.combatant.resources.en = 0.0
	_p.perfect_dodged.emit(HitInfo.new())
	assert_float(_p.combatant.statuses.move_speed_up()).is_equal(0.25)
	assert_float(_p.combatant.statuses.remaining("wind_step")).is_equal_approx(3.0, 0.01)
	assert_float(_p.combatant.resources.en).is_equal(5.0)


# ---------- Cơ chế chung ----------

func test_hitbox_max_targets_deactivates() -> void:
	var hb: Hitbox = auto_free(Hitbox.new())
	add_child(hb)
	hb.max_targets = 1
	var a := Hurtbox.new()
	var b := Hurtbox.new()
	a.team = PhysicsLayers.Team.ENEMY
	b.team = PhysicsLayers.Team.ENEMY
	for hu: Hurtbox in [a, b]:                                                      # chủ khác với Hitbox
		var owner_node: Node2D = auto_free(Node2D.new())
		add_child(owner_node)
		owner_node.add_child(hu)
	hb.activate()
	assert_bool(hb.try_hit(a)).is_true()
	assert_bool(hb.active).is_false()
	assert_bool(hb.try_hit(b)).is_false()
	hb.activate()                                                                   # lần bật mới đếm lại
	assert_bool(hb.try_hit(b)).is_true()
