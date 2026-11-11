extends GdUnitTestSuite
## Test M3-3: DamageCalculator (Q1-Q3) và RandomSource. Số kỳ vọng tính tay trong chú thích.

const DC := preload("res://scripts/combat/damage_calculator.gd")
const NO_CRIT := 0.99   # roll 0.99 ≥ 5% → không chí mạng
const ALWAYS_CRIT := 0.0

var _rules: CombatRules


func before() -> void:
	_rules = load("res://data/config/combat_rules.tres")


func _atk(atk := 1000.0) -> DC.Attacker:
	return DC.Attacker.from_rules(_rules, atk)


func _target(def := 500.0) -> DC.Target:
	var t := DC.Target.new()
	t.def = def
	return t


func _dmg(a: DC.Attacker, t: DC.Target, ratio := 0.7, level := 1, roll := NO_CRIT) -> DC.Result:
	return DC.compute(_rules, a, t, ratio, level, RandomSource.Fixed.new(roll))


# ---------- Công thức cơ bản (Q1) ----------

func test_base_case() -> void:
	# 1000 × 0.7 = 700; DEF 500 → 500/(500+500) = 0.5 → 350
	var r := _dmg(_atk(), _target())
	assert_int(r.amount).is_equal(350)
	assert_float(r.raw).is_equal_approx(700.0, 0.001)
	assert_float(r.mitigation).is_equal_approx(0.5, 0.0001)
	assert_bool(r.is_crit).is_false()


func test_skill_level_scaling() -> void:
	# cấp 10: × (1 + 0.06 × 9) = 1.54 → 700 × 1.54 × 0.5 = 539
	assert_int(_dmg(_atk(), _target(), 0.7, 10).amount).is_equal(539)
	assert_float(DC.level_multiplier(_rules, 1)).is_equal(1.0)
	assert_float(DC.level_multiplier(_rules, 0)).is_equal(1.0)  # cấp không hợp lệ coi như 1


func test_zero_def_means_full_damage() -> void:
	assert_int(_dmg(_atk(), _target(0.0), 1.0).amount).is_equal(1000)


func test_higher_def_reduces_damage() -> void:
	# DEF 1500 → 500/2000 = 0.25 → 1000 × 0.25 = 250
	assert_int(_dmg(_atk(), _target(1500.0), 1.0).amount).is_equal(250)


# ---------- Chí mạng (Q2) ----------

func test_crit_multiplies_by_one_and_half() -> void:
	# 350 × 1.5 = 525
	var r := _dmg(_atk(), _target(), 0.7, 1, ALWAYS_CRIT)
	assert_bool(r.is_crit).is_true()
	assert_float(r.crit_multiplier).is_equal(1.5)
	assert_int(r.amount).is_equal(525)


func test_default_crit_from_rules() -> void:
	var a := _atk()
	assert_float(a.crit_rate).is_equal(0.05)
	assert_float(a.crit_damage).is_equal(0.5)


func test_crit_rate_over_many_rolls_with_seed() -> void:
	var rng := RandomSource.new(12345)
	var crits := 0
	for i in 10000:
		if DC.compute(_rules, _atk(), _target(), 0.7, 1, rng).is_crit:
			crits += 1
	assert_int(crits).is_between(400, 600)  # 5% ± 1%


# ---------- Giảm DEF (Q3) ----------

func test_def_reductions_from_different_names_stack() -> void:
	# 0.15 + 0.20 = 0.35 → DEF 325 → 500/825 → 1000 × 0.60606 = 606
	var t := _target()
	t.def_reduction["curse"] = 0.15
	t.def_reduction["armor_break"] = 0.20
	assert_float(DC.total_def_reduction(_rules, t)).is_equal_approx(0.35, 0.0001)
	assert_int(_dmg(_atk(), t, 1.0).amount).is_equal(606)


func test_def_reduction_capped_at_40_percent() -> void:
	# 0.15 + 0.30 = 0.45 → trần 0.40 → DEF 300 → 500/800 = 0.625 → 625
	var t := _target()
	t.def_reduction["curse"] = 0.15
	t.def_reduction["other"] = 0.30
	assert_float(DC.total_def_reduction(_rules, t)).is_equal_approx(0.40, 0.0001)
	assert_int(_dmg(_atk(), t, 1.0).amount).is_equal(625)


func test_same_name_debuff_counts_once() -> void:
	# Áp Nguyền hai lần: cùng khóa "curse" → vẫn 0.15 → DEF 425 → 500/925 → 540.54 → 541
	var t := _target()
	t.def_reduction["curse"] = 0.15
	t.def_reduction["curse"] = 0.15
	assert_int(_dmg(_atk(), t, 1.0).amount).is_equal(541)


# ---------- Tăng/giảm sát thương ----------

func test_bonus_and_judgment_add_up() -> void:
	# 1 + 0.12 (buff) + 0.08 (Phán quyết) = 1.20 → 1000 × 1.2 × 0.5 = 600
	var a := _atk()
	a.damage_bonus["buff"] = 0.12
	var t := _target()
	t.damage_taken_up["judgment"] = 0.08
	var r := _dmg(a, t, 1.0)
	assert_float(r.bonus).is_equal_approx(1.2, 0.0001)
	assert_int(r.amount).is_equal(600)


func test_damage_taken_reduction_and_cap() -> void:
	# Giáp Địa 0.35 + Thạch Thần 0.40 = 0.75 → × 0.25 → 500 × 0.25 = 125
	var t := _target()
	t.damage_taken_down["earth_guard"] = 0.35
	t.damage_taken_down["stone_god"] = 0.40
	assert_int(_dmg(_atk(), t, 1.0).amount).is_equal(125)
	# Thêm 0.15 → 0.90 → trần 0.80 → × 0.2 → 100
	t.damage_taken_down["extra"] = 0.15
	var r := _dmg(_atk(), t, 1.0)
	assert_float(r.taken).is_equal_approx(0.2, 0.0001)
	assert_int(r.amount).is_equal(100)


func test_sand_blind_reduces_dealt_damage() -> void:
	# Mù cát −20% sát thương gây ra → 500 × 0.8 = 400
	var a := _atk()
	a.damage_dealt_down["sand_blind"] = 0.20
	assert_int(_dmg(a, _target(), 1.0).amount).is_equal(400)


func test_all_factors_together() -> void:
	# raw 1000 × 0.7 × 1.12 (cấp 3) = 784
	# bonus 1.08 (Phán quyết); dealt 1; DEF 500 − 15% = 425 → 500/925
	# crit × 1.5; taken × 0.65 (Giáp Địa 0.35)
	# 784 × 1.08 × (500/925) × 1.5 × 0.65 = 446.27 → 446
	var a := _atk()
	var t := _target()
	t.damage_taken_up["judgment"] = 0.08
	t.def_reduction["curse"] = 0.15
	t.damage_taken_down["earth_guard"] = 0.35
	assert_int(_dmg(a, t, 0.7, 3, ALWAYS_CRIT).amount).is_equal(446)


# ---------- Giá trị biên ----------

func test_never_negative() -> void:
	assert_int(_dmg(_atk(0.0), _target()).amount).is_equal(0)
	var a := _atk()
	a.damage_bonus["huge_debuff"] = -2.0  # bonus âm bị chặn ở 0
	assert_int(_dmg(a, _target()).amount).is_equal(0)
	var t := _target(-300.0)  # DEF âm coi như 0
	assert_int(_dmg(_atk(), t, 1.0).amount).is_equal(1000)


# ---------- Hồi máu ----------

func test_heal_formula() -> void:
	# 1000 × 0.5 + 10000 × 0.03 = 800; cấp 3 × 1.12 = 896
	assert_int(DC.heal(_rules, 1000.0, 0.5, 10000.0, 0.03, 1)).is_equal(800)
	assert_int(DC.heal(_rules, 1000.0, 0.5, 10000.0, 0.03, 3)).is_equal(896)


# ---------- RandomSource ----------

func test_same_seed_same_sequence() -> void:
	var a := RandomSource.new(777)
	var b := RandomSource.new(777)
	for i in 50:
		assert_float(a.randf()).is_equal(b.randf())


func test_state_save_and_restore() -> void:
	var r := RandomSource.new(42)
	r.randf()
	var s := r.get_state()
	var next := [r.randf(), r.randf()]
	r.set_state(s)
	assert_float(r.randf()).is_equal(next[0])
	assert_float(r.randf()).is_equal(next[1])


func test_chance_edges() -> void:
	var r := RandomSource.new(1)
	for i in 100:
		assert_bool(r.chance(0.0)).is_false()
		assert_bool(r.chance(1.0)).is_true()
