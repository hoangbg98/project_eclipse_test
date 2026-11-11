extends GdUnitTestSuite
## Test M3-4: ResourceComponent (HP/EN/UG/lượt né) và CooldownController (CDR trần 40%, rút CD riêng).

const HK := ResourceComponent.HitKind

var _rules: CombatRules


func before() -> void:
	_rules = load("res://data/config/combat_rules.tres")


func _res(max_hp := 10000.0) -> ResourceComponent:
	return ResourceComponent.new(_rules, max_hp)


func _tick(obj: RefCounted, seconds: float, step := 0.1) -> void:
	var t := 0.0
	while t < seconds - 0.00001:
		obj.tick(step)
		t += step


# ================= ResourceComponent =================

func test_initial_state() -> void:
	var r := _res()
	assert_float(r.hp).is_equal(10000.0)
	assert_float(r.en).is_equal(0.0)
	assert_float(r.ug).is_equal(0.0)
	assert_int(r.dodge_charges).is_equal(2)


func test_en_regen_on_field_and_reserve() -> void:
	var on := _res()
	_tick(on, 10.0)
	assert_float(on.en).is_equal_approx(20.0, 0.01)   # +2/s
	var off := _res()
	off.on_field = false
	_tick(off, 10.0)
	assert_float(off.en).is_equal_approx(10.0, 0.01)  # dự bị +1/s (mục 8.1)
	_tick(on, 100.0)
	assert_float(on.en).is_equal(100.0)               # trần 100


func test_spend_en_rejects_when_short() -> void:
	var r := _res()
	r.add_en(30.0)
	assert_bool(r.spend_en(40.0)).is_false()
	assert_float(r.en).is_equal(30.0)
	assert_bool(r.spend_en(25.0)).is_true()
	assert_float(r.en).is_equal(5.0)


func test_damage_lowers_hp_and_charges_ug() -> void:
	var r := _res()
	var lost := r.take_damage(2500.0)
	assert_float(lost).is_equal(2500.0)
	assert_float(r.hp).is_equal(7500.0)
	# mất 25% HP tối đa × 0.3 = 7.5 UG
	assert_float(r.ug).is_equal_approx(7.5, 0.0001)


func test_death_once_and_no_heal_after() -> void:
	var r := _res(1000.0)
	var deaths := [0]
	r.died.connect(func() -> void: deaths[0] += 1)
	r.take_damage(600.0)
	var lost := r.take_damage(5000.0)
	assert_float(lost).is_equal(400.0)   # chỉ mất phần còn lại
	assert_bool(r.is_dead()).is_true()
	r.take_damage(100.0)
	assert_int(deaths[0]).is_equal(1)
	assert_float(r.heal(500.0)).is_equal(0.0)
	assert_float(r.hp).is_equal(0.0)
	var en := r.en
	_tick(r, 5.0)
	assert_float(r.en).is_equal(en)      # đã gục thì không hồi EN
	assert_bool(r.try_dodge()).is_false()


func test_heal_returns_overflow() -> void:
	var r := _res()
	r.take_damage(1000.0)
	assert_float(r.heal(1500.0)).is_equal(500.0)
	assert_float(r.hp).is_equal(10000.0)
	assert_float(r.heal(200.0)).is_equal(200.0)  # đầy máu: thừa toàn bộ


func test_register_hit_by_kind() -> void:
	var r := _res()
	assert_float(r.register_hit(HK.NORMAL)).is_equal(2.0)
	assert_float(r.en).is_equal(3.0)
	assert_float(r.ug).is_equal(2.0)
	r.register_hit(HK.HOLD)
	r.register_hit(HK.AIR)
	r.register_hit(HK.LANDING)
	assert_float(r.en).is_equal(12.0)    # +3 mỗi loại
	assert_float(r.ug).is_equal(2.0)     # giữ/không/đáp không cộng UG
	assert_float(r.register_hit(HK.SKILL)).is_equal(10.0)
	assert_float(r.register_hit(HK.WEAPON)).is_equal(15.0)
	assert_float(r.ug).is_equal(27.0)
	assert_float(r.register_hit(HK.ULTIMATE)).is_equal(0.0)


func test_ultimate_ready_signal_and_use() -> void:
	var r := _res()
	var ready := [0]
	r.ultimate_ready.connect(func() -> void: ready[0] += 1)
	assert_bool(r.use_ultimate()).is_false()
	for i in 7:
		r.register_hit(HK.WEAPON)  # 7 × 15 = 105 → trần 100
	assert_float(r.ug).is_equal(100.0)
	r.register_hit(HK.WEAPON)
	assert_int(ready[0]).is_equal(1)     # chỉ báo một lần khi vừa đầy
	assert_bool(r.use_ultimate()).is_true()
	assert_float(r.ug).is_equal(0.0)


func test_dodge_charges_and_recharge() -> void:
	var r := _res()
	assert_bool(r.try_dodge()).is_true()
	assert_bool(r.try_dodge()).is_true()
	assert_bool(r.try_dodge()).is_false()   # hết lượt: từ chối an toàn
	_tick(r, 3.9)
	assert_int(r.dodge_charges).is_equal(0)
	_tick(r, 0.2)
	assert_int(r.dodge_charges).is_equal(1)  # 4.0 s / lượt
	_tick(r, 4.0)
	assert_int(r.dodge_charges).is_equal(2)
	_tick(r, 10.0)
	assert_int(r.dodge_charges).is_equal(2)  # không vượt tối đa


func test_dodge_recharge_uses_capped_cdr() -> void:
	var r := _res()
	r.cdr = 0.6                               # trần 40% → 4.0 × 0.6 = 2.4 s
	assert_float(r.dodge_recharge_time()).is_equal_approx(2.4, 0.0001)
	r.try_dodge()
	_tick(r, 2.5)
	assert_int(r.dodge_charges).is_equal(2)


func test_perfect_dodge_refund() -> void:
	var r := _res()
	r.try_dodge()
	r.try_dodge()
	r.refund_dodge()
	assert_int(r.dodge_charges).is_equal(1)   # hoàn 1 lượt
	r.refund_dodge(5)
	assert_int(r.dodge_charges).is_equal(2)   # không vượt tối đa


# ================= CooldownController =================

func _cd() -> CooldownController:
	var c := CooldownController.new(_rules)
	c.register(&"skill", 10.0)
	c.register(&"weapon", 15.0)
	c.register(&"switch_in", 8.0)
	return c


func test_trigger_and_recover() -> void:
	var c := _cd()
	var ready: Array[StringName] = []
	c.cooldown_ready.connect(func(k: StringName) -> void: ready.append(k))
	assert_bool(c.is_ready(&"skill")).is_true()
	assert_bool(c.trigger(&"skill")).is_true()
	assert_bool(c.trigger(&"skill")).is_false()  # đang hồi: từ chối
	assert_float(c.remaining(&"skill")).is_equal(10.0)
	_tick(c, 9.9)
	assert_bool(c.is_ready(&"skill")).is_false()
	_tick(c, 0.2)
	assert_bool(c.is_ready(&"skill")).is_true()
	assert_array(ready).contains_exactly([&"skill"])


func test_cdr_applies_with_40_percent_cap() -> void:
	var c := _cd()
	c.cdr = 0.25
	assert_float(c.duration_of(&"skill")).is_equal_approx(7.5, 0.0001)
	c.cdr = 0.6
	assert_float(c.effective_cdr()).is_equal(0.4)
	assert_float(c.duration_of(&"skill")).is_equal_approx(6.0, 0.0001)
	assert_float(c.duration_of(&"switch_in")).is_equal_approx(4.8, 0.0001)  # SI-CD chịu CDR (8.2)
	c.register(&"no_cdr", 10.0, false)
	assert_float(c.duration_of(&"no_cdr")).is_equal(10.0)


func test_cdr_fixed_when_cooldown_starts() -> void:
	var c := _cd()
	c.trigger(&"skill")
	c.cdr = 0.4  # đổi CDR giữa chừng không ảnh hưởng chu kỳ đang chạy
	assert_float(c.remaining(&"skill")).is_equal(10.0)


func test_flat_reduction_has_per_cycle_cap() -> void:
	var c := _cd()
	c.trigger(&"skill")
	assert_float(c.reduce(&"skill", 2.0, 3.0)).is_equal(2.0)
	assert_float(c.reduce(&"skill", 2.0, 3.0)).is_equal(1.0)   # còn 1 s trong mức 3 s
	assert_float(c.reduce(&"skill", 2.0, 3.0)).is_equal(0.0)
	assert_float(c.remaining(&"skill")).is_equal(7.0)
	_tick(c, 7.1)
	c.trigger(&"skill")                                         # chu kỳ mới: mức tối đa làm lại
	assert_float(c.reduce(&"skill", 2.0, 3.0)).is_equal(2.0)


func test_flat_reduction_not_limited_by_cdr_cap() -> void:
	var c := _cd()
	c.cdr = 0.4
	c.trigger(&"skill")                      # 6.0 s
	assert_float(c.reduce(&"skill", 5.0)).is_equal(5.0)  # không giới hạn mỗi chu kỳ
	assert_float(c.remaining(&"skill")).is_equal_approx(1.0, 0.0001)  # tổng giảm 90% > trần 40%


func test_reduction_cannot_go_below_zero_and_signals_ready() -> void:
	var c := _cd()
	var ready: Array[StringName] = []
	c.cooldown_ready.connect(func(k: StringName) -> void: ready.append(k))
	c.trigger(&"weapon")
	assert_float(c.reduce(&"weapon", 100.0)).is_equal(15.0)
	assert_bool(c.is_ready(&"weapon")).is_true()
	assert_array(ready).contains_exactly([&"weapon"])
	assert_float(c.reduce(&"weapon", 1.0)).is_equal(0.0)      # đã sẵn sàng: không rút nữa


func test_progress_for_hud_ring() -> void:
	var c := _cd()
	assert_float(c.progress(&"skill")).is_equal(1.0)
	c.trigger(&"skill")
	assert_float(c.progress(&"skill")).is_equal(0.0)
	_tick(c, 5.0)
	assert_float(c.progress(&"skill")).is_equal_approx(0.5, 0.01)


func test_keys_tick_independently_like_reserve() -> void:
	# Nhân vật dự bị vẫn tick: mọi khóa đếm song song.
	var c := _cd()
	c.trigger(&"skill")
	c.trigger(&"switch_in")
	_tick(c, 8.0)
	assert_bool(c.is_ready(&"switch_in")).is_true()
	assert_float(c.remaining(&"skill")).is_equal_approx(2.0, 0.01)


func test_unknown_key_is_rejected_safely() -> void:
	var c := _cd()
	assert_bool(c.is_ready(&"nope")).is_false()
	assert_bool(c.trigger(&"nope")).is_false()
	assert_float(c.reduce(&"nope", 1.0)).is_equal(0.0)
