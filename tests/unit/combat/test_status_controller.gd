extends GdUnitTestSuite
## Test StatusController: làm mới, cộng tầng, nhịp sát thương, kháng sau Choáng, boss, chỉ số gộp.

var _lib: StatusLibrary


func before() -> void:
	_lib = StatusLibrary.load_dir()


func _sc(boss := false) -> StatusController:
	return StatusController.new(_lib, boss)


func _tick(sc: StatusController, seconds: float, step := 0.05) -> void:
	for i in int(round(seconds / step)):
		sc.tick(step)


func test_burn_ticks_eight_times_over_four_seconds() -> void:
	var sc := _sc()
	var ticks: Array[float] = []
	sc.tick_damage.connect(func(_id: String, ratio: float, _src: Object) -> void: ticks.append(ratio))
	assert_bool(sc.apply("burn")).is_true()
	_tick(sc, 3.9)
	assert_int(ticks.size()).is_equal(7)
	_tick(sc, 0.2)
	assert_int(ticks.size()).is_equal(8)        # 4 s / 0.5 s
	assert_float(ticks[0]).is_equal(0.08)        # 8% ATK mỗi nhịp
	assert_bool(sc.has("burn")).is_false()


func test_burn_refresh_does_not_stack() -> void:
	var sc := _sc()
	sc.apply("burn", 3.0)
	_tick(sc, 2.0)
	sc.apply("burn", 3.0)
	assert_float(sc.remaining("burn")).is_equal_approx(3.0, 0.001)  # làm mới
	assert_int(sc.stacks("burn")).is_equal(1)                       # không cộng dồn
	sc.apply("burn", 1.0)
	assert_float(sc.remaining("burn")).is_equal_approx(3.0, 0.001)  # không rút ngắn


func test_lightning_mark_stacks_to_three() -> void:
	var sc := _sc()
	var maxed := [0]
	sc.max_stacks_reached.connect(func(_id: String, _s: Object) -> void: maxed[0] += 1)
	sc.apply("lightning_mark")
	sc.apply("lightning_mark")
	assert_int(maxed[0]).is_equal(0)
	sc.apply("lightning_mark")
	assert_int(sc.stacks("lightning_mark")).is_equal(3)
	assert_int(maxed[0]).is_equal(1)
	sc.apply("lightning_mark")
	assert_int(sc.stacks("lightning_mark")).is_equal(3)
	assert_int(maxed[0]).is_equal(1)


func test_stun_resist_after_expiry() -> void:
	var sc := _sc()
	assert_bool(sc.apply("stun")).is_true()
	assert_bool(sc.blocks_actions()).is_true()
	_tick(sc, 2.05)
	assert_bool(sc.has("stun")).is_false()
	assert_bool(sc.is_resisting("stun")).is_true()
	assert_bool(sc.apply("stun")).is_false()     # đang kháng 8 s
	_tick(sc, 8.0)
	assert_bool(sc.apply("stun")).is_true()


func test_boss_durations() -> void:
	var sc := _sc(true)
	sc.apply("stun")
	assert_float(sc.remaining("stun")).is_equal_approx(1.0, 0.001)  # boss 1.0 s


func test_skill_defined_duration_required() -> void:
	var sc := _sc()
	assert_bool(sc.apply("slow")).is_false()                 # thời gian do kỹ năng ghi
	assert_bool(sc.apply("slow", 2.0, 0.3)).is_true()
	assert_float(sc.move_slow()).is_equal_approx(0.3, 0.0001)


func test_modifiers_feed_damage_calculator() -> void:
	var sc := _sc()
	sc.apply("curse", 5.0)
	sc.apply("judgment", 5.0)
	sc.apply("earth_guard", 5.0, 0.35)
	assert_dict(sc.modifiers(StatusDef.MAGNITUDE_DEF_REDUCTION)).is_equal({"curse": 0.15})
	assert_dict(sc.modifiers(StatusDef.MAGNITUDE_DAMAGE_TAKEN_UP)).is_equal({"judgment": 0.08})
	assert_dict(sc.modifiers(StatusDef.MAGNITUDE_DAMAGE_TAKEN_DOWN)).is_equal({"earth_guard": 0.35})
	assert_bool(sc.stagger_immune()).is_true()
	assert_bool(sc.has_elemental()).is_true()


func test_root_blocks_movement_not_actions() -> void:
	var sc := _sc()
	sc.apply("root", 2.0)
	assert_bool(sc.blocks_movement()).is_true()
	assert_bool(sc.blocks_actions()).is_false()


func test_unknown_status_rejected() -> void:
	assert_bool(_sc().apply("khong_co")).is_false()
