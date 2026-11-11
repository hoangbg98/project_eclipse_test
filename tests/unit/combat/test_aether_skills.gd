extends GdUnitTestSuite
## Test M3-5 phần 3: Kĩ năng thường, Kĩ năng vũ khí, Tuyệt kỹ, nội tại Nhiệt, né hoàn hảo — Hơi Nóng, Hỏa Hoàng.

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")

var _stage: Node2D
var _player: PlayerController
var _dummy: TrainingDummy
var _hits: Array[int] = []
var _started: Array[String] = []
var _rejected: Array[String] = []


func before_test() -> void:
	_hits.clear()
	_started.clear()
	_rejected.clear()


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
	_player.runner.skill_rejected.connect(func(k: String, why: String) -> void: _rejected.append(k + ":" + why))
	await _frames(20)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _buf() -> float:
	return _player.config.jump_buffer_time


func _press(action: StringName) -> void:
	_player.intent.press(action, _buf())


func _wait_skill_end(max_frames := 240) -> void:
	for i in 10:
		if _player.runner.is_running():
			break
		await get_tree().physics_frame
	for i in max_frames:
		if not _player.runner.is_running():
			return
		await get_tree().physics_frame


func _set_heat(n: int) -> void:
	for i in n:
		_player.combatant.statuses.apply("heat", -1.0, -1.0, _player.combatant)


# ---------- Dữ liệu ----------

func test_data_matches_document() -> void:
	var s := (load("res://data/characters/char_fire_01.tres") as CharacterDef).load_skills()
	assert_float(s["skill"].total_atk_ratio()).is_equal_approx(3.5, 0.0001)     # 80×3 + 110
	assert_float(s["weapon"].total_atk_ratio()).is_equal_approx(3.5, 0.0001)    # 220 + 130
	assert_float(s["ultimate"].total_atk_ratio()).is_equal_approx(11.0, 0.0001) # 5×120 + 500
	assert_float(s["skill"].en_cost).is_equal(25.0)
	assert_float(s["skill"].cooldown_sec).is_equal(6.0)
	assert_float(s["weapon"].en_cost).is_equal(35.0)
	assert_float(s["weapon"].cooldown_sec).is_equal(12.0)
	assert_float(s["ultimate"].ug_cost).is_equal(100.0)
	assert_float(s["ultimate"].cooldown_sec).is_equal(2.0)
	for k in ["skill", "weapon", "ultimate"]:
		assert_array(s[k].validate()).is_empty()


# ---------- Kĩ năng thường ----------

func test_skill_four_ticks_burn_and_costs() -> void:
	await _setup()
	_player.combatant.resources.add_en(100.0)
	_press(PlayerIntent.SKILL)
	await _wait_skill_end()
	await _frames(3)
	assert_array(_started).contains_exactly(["skill"])
	# 80% ×3 + 110% (× 0.5 DEF). Nhịp 1 áp Cháy → nhịp 2 trúng mục tiêu đang Cháy → +1 Nhiệt (+4% ATK)
	# → nhịp 3: 0.8 × 1040 × 0.5 = 416; nhịp 4: 1.1 × 1040 × 0.5 = 572 (ICD Nhiệt 0.3 s).
	assert_array(_hits).contains_exactly([400, 400, 416, 572])
	# Nhịp 2 và nhịp 4 cách đúng 300 ms = ICD → làm tròn theo khung vật lý (16.7 ms) nên 1 hoặc 2 tầng.
	assert_int(_player.combatant.statuses.stacks("heat")).is_between(1, 2)
	assert_bool(_dummy.combatant.statuses.has("burn")).is_true()
	assert_float(_player.combatant.resources.en).is_less(80.0)           # −25
	assert_float(_player.combatant.cooldowns.remaining(&"skill")).is_between(4.5, 6.0)
	assert_float(_player.combatant.resources.ug).is_equal_approx(40.0, 0.01)  # 4 nhịp × 10 UG


func test_skill_rejected_without_energy() -> void:
	await _setup()
	_press(PlayerIntent.SKILL)
	await _frames(3)
	assert_array(_started).is_empty()
	assert_array(_rejected).contains(["skill:energy"])


func test_skill_cooldown_reduced_by_basic_hits_on_burning() -> void:
	await _setup()
	_player.combatant.resources.add_en(100.0)
	_press(PlayerIntent.SKILL)
	await _wait_skill_end()
	var before := _player.combatant.cooldowns.remaining(&"skill")
	_player.intent.tap_attack(_buf())                                  # mục tiêu đang Cháy
	await _wait_skill_end()
	var after := _player.combatant.cooldowns.remaining(&"skill")
	# rút thêm 0.2 s ngoài thời gian trôi
	assert_float(before - after).is_greater(0.2)


# ---------- Kĩ năng vũ khí ----------

func test_weapon_dash_melt_and_delayed_explosion() -> void:
	await _setup(Vector2(700, 896))
	_player.combatant.resources.add_en(100.0)
	var x0 := _player.global_position.x
	_press(PlayerIntent.WEAPON)
	for f in 20:
		if _player.runner.current_key == "weapon" and _player.runner.elapsed_ms > 200.0:
			break
		await get_tree().physics_frame
	assert_bool(_player.hurtbox.invulnerable).is_true()                 # bất tử khi lướt
	await _wait_skill_end()
	assert_float(_player.global_position.x - x0).is_equal_approx(400.0, 12.0)
	assert_array(_hits).contains_exactly([1100])                       # 220%
	assert_bool(_dummy.combatant.statuses.has("melt")).is_true()
	await _frames(60)
	# nổ 130%, mục tiêu −10% DEF: 1300 × 500/(500+450) = 684
	assert_array(_hits).contains_exactly([1100, 684])


# ---------- Tuyệt kỹ ----------

func test_ultimate_needs_full_ug() -> void:
	await _setup()
	_press(PlayerIntent.ULTIMATE)
	await _frames(3)
	assert_array(_rejected).contains(["ultimate:ultimate"])


func test_ultimate_hits_nearest_target_and_grants_phoenix() -> void:
	await _setup(Vector2(600, 896))  # hình nộm gần nhất cách 328 px
	_player.combatant.resources.add_ug(100.0)
	_press(PlayerIntent.ULTIMATE)
	await _frames(3)
	assert_float(_player.combatant.resources.ug).is_equal(0.0)
	assert_bool(_player.hurtbox.invulnerable).is_true()
	await _wait_skill_end()
	await _frames(5)
	# 5 nhịp × 120% = 600 mỗi nhịp, nổ 500% = 2500
	assert_array(_hits).contains_exactly([600, 600, 600, 600, 600, 2500])
	assert_bool(_dummy.combatant.statuses.has("burn")).is_true()
	assert_bool(_player.combatant.statuses.has("phoenix")).is_true()
	assert_bool(_player.combatant.cooldowns.is_ready(&"ultimate")).is_false()  # khóa 2.0 s


func test_ultimate_without_target_lands_in_front() -> void:
	# Hình nộm cách 778 px > 500: không nhắm; vùng đặt trước mặt 200 px (x = 350),
	# nổ cuối bán kính 450 tới x = 800 < mép hình nộm 878 → không trúng.
	await _setup(Vector2(150, 896))
	_player.combatant.resources.add_ug(100.0)
	_press(PlayerIntent.ULTIMATE)
	await _wait_skill_end()
	await _frames(5)
	assert_array(_hits).is_empty()


# ---------- Nội tại Nhiệt ----------

func test_heat_stacks_on_burning_target_with_icd() -> void:
	await _setup()
	_dummy.combatant.statuses.apply("burn", 6.0, -1.0, _player.combatant)
	_player.intent.tap_attack(_buf())
	await _wait_skill_end()
	assert_int(_player.combatant.statuses.stacks("heat")).is_equal(1)
	await _frames(2)
	assert_float(_player.combatant.current_atk()).is_equal_approx(1040.0, 0.01)   # +4% ATK


func test_no_heat_on_target_not_burning() -> void:
	await _setup()
	_player.intent.tap_attack(_buf())
	await _wait_skill_end()
	assert_int(_player.combatant.statuses.stacks("heat")).is_equal(0)


func test_full_heat_boosts_skill_and_is_consumed() -> void:
	await _setup()
	_set_heat(5)
	await _frames(2)
	assert_float(_player.combatant.current_atk()).is_equal_approx(1200.0, 0.01)   # +20%
	_player.combatant.resources.add_en(100.0)
	_press(PlayerIntent.SKILL)
	await _wait_skill_end()
	await _frames(3)
	# Tiêu 5 tầng khi bắt đầu (ATK về 1000), cả kỹ năng +25%: 400 × 1.25 = 500.
	# Nhịp 1 áp Cháy → nhịp 2 cộng lại 1 Nhiệt (+4% ATK) → nhịp 3: 0.8 × 1040 × 0.5 × 1.25 = 520,
	# nhịp 4: 1.1 × 1040 × 0.5 × 1.25 = 715.
	assert_array(_hits).contains_exactly([500, 500, 520, 715])
	assert_int(_player.combatant.statuses.stacks("heat")).is_between(1, 2)  # tầng mới, không phải 5 cũ


func test_three_heat_speeds_ug_gain() -> void:
	await _setup()
	_set_heat(3)
	await _frames(2)
	assert_float(_player.combatant.resources.ug_gain_multiplier).is_equal(1.2)
	_player.combatant.resources.register_hit(ResourceComponent.HitKind.SKILL)
	assert_float(_player.combatant.resources.ug).is_equal_approx(12.0, 0.001)   # 10 × 1.2


func test_reaching_full_heat_cuts_skill_cooldown() -> void:
	await _setup()
	_player.combatant.resources.add_en(100.0)
	_press(PlayerIntent.SKILL)
	await _wait_skill_end()
	var before := _player.combatant.cooldowns.remaining(&"skill")
	_set_heat(5)
	var after := _player.combatant.cooldowns.remaining(&"skill")
	assert_float(before - after).is_equal_approx(1.0, 0.001)


# ---------- Né hoàn hảo — Hơi Nóng ----------

func test_perfect_dodge_hot_breath() -> void:
	await _setup(Vector2(820, 896))
	var perfect := [0]
	_player.perfect_dodged.connect(func(_h: HitInfo) -> void: perfect[0] += 1)
	# Đòn của "kẻ địch" (chủ là hình nộm) trùm lên người chơi.
	var enemy_hit := Hitbox.new()
	enemy_hit.team = PhysicsLayers.Team.ENEMY
	enemy_hit.attacker = _dummy
	enemy_hit.atk_ratio = 1.0
	var poly := CollisionPolygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(-400, -300), Vector2(400, -300), Vector2(400, 0), Vector2(-400, 0)])
	enemy_hit.add_child(poly)
	_stage.add_child(enemy_hit)
	enemy_hit.global_position = _player.global_position
	_press(PlayerIntent.DODGE)
	for f in 20:
		if _player.runner.current_key == "dodge" and _player.runner.elapsed_ms >= 50.0:
			break
		await get_tree().physics_frame
	enemy_hit.activate()
	await _frames(4)
	enemy_hit.deactivate()
	assert_int(perfect[0]).is_equal(1)
	assert_int(_player.combatant.resources.dodge_charges).is_equal(2)              # hoàn 1 lượt
	assert_bool(_dummy.combatant.statuses.has("slow")).is_true()                    # kẻ đánh chậm 30%
	assert_bool(_player.combatant.statuses.has("hot_breath")).is_true()
	assert_float(_player.combatant.resources.hp).is_equal(_player.combatant.resources.max_hp)  # không mất máu
	await _wait_skill_end()
	await _frames(50)  # vệt lửa của cú né (2 × 125) đã xong
	_player.global_position = Vector2(820, 896)
	_player.facing = 1
	_dummy.combatant.statuses.remove("burn")
	_hits.clear()
	await _frames(3)
	_player.intent.tap_attack(_buf())
	await _wait_skill_end()
	await _frames(2)
	assert_array(_hits).contains_exactly([455])                                     # 350 × 1.3
	assert_bool(_dummy.combatant.statuses.has("burn")).is_true()                    # Hơi Nóng áp Cháy
	assert_bool(_player.combatant.statuses.has("hot_breath")).is_false()           # đã dùng


# ---------- Hỏa Hoàng ----------

func test_phoenix_boosts_damage_and_adds_wave() -> void:
	await _setup()
	_player.combatant.statuses.apply("phoenix", -1.0, -1.0, _player.combatant)
	_player.intent.tap_attack(_buf())
	await _wait_skill_end()
	await _frames(20)
	# đòn 1: 350 × 1.2 = 420; sóng lửa thêm 40%: 200 × 1.2 = 240
	assert_array(_hits).contains_exactly_in_any_order([420, 240])
