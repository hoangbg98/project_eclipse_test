extends GdUnitTestSuite
## Test M3-1: CombatRules và StatusDef khớp CHARACTER_SKILLS mục 0, ghi đè 8.1, quyết định Q1-Q4, Q6.

const RULES_PATH := "res://data/config/combat_rules.tres"
const EXPECTED_STATUSES := ["armor_break", "attack_speed_up", "burn", "curse", "earth_guard", "fair_wind",
		"fair_wind_haste", "guard", "hard_armor", "heat", "hot_breath", "judgment", "lightning_mark", "melt", "night_king",
		"overload", "phoenix", "root", "sanctuary", "sand_blind", "shield", "slow", "stone_bone", "stone_god",
		"storm_blessing", "stun", "taunt", "wind_domain", "wind_domain_haste", "wind_step"]

var _rules: CombatRules
var _lib: StatusLibrary


func before() -> void:
	_rules = load(RULES_PATH)
	_lib = StatusLibrary.load_dir()


# ---------- CombatRules ----------

func test_rules_load_and_validate() -> void:
	assert_object(_rules).is_not_null()
	assert_array(_rules.validate()).is_empty()


func test_damage_rules_match_q1_q2_q3() -> void:
	assert_float(_rules.skill_level_scaling).is_equal(0.06)   # Q1
	assert_float(_rules.def_constant_k).is_equal(500.0)       # Q1
	assert_float(_rules.base_crit_rate).is_equal(0.05)        # Q2
	assert_float(_rules.base_crit_damage).is_equal(0.5)       # Q2
	assert_float(_rules.def_reduction_cap).is_equal(0.40)     # Q3
	assert_float(_rules.cdr_cap).is_equal(0.40)               # mục 0


func test_resources_match_section_0() -> void:
	assert_float(_rules.en_max).is_equal(100.0)
	assert_float(_rules.en_regen_per_sec).is_equal(2.0)
	assert_float(_rules.en_per_basic_hit).is_equal(3.0)
	assert_float(_rules.ug_max).is_equal(100.0)
	assert_float(_rules.ug_per_normal_hit).is_equal(2.0)
	assert_float(_rules.ug_per_skill_hit).is_equal(10.0)
	assert_float(_rules.ug_per_weapon_hit).is_equal(15.0)
	assert_float(_rules.ug_per_hp_percent_lost).is_equal(0.3)
	assert_int(_rules.dodge_charges).is_equal(2)
	assert_float(_rules.dodge_recharge_sec).is_equal(4.0)


func test_reserve_values_use_section_8_1_override() -> void:
	# 8.1 ghi đè: dự bị +1 EN/s (không phải 2) và nhận 30% UG (không phải 50%).
	assert_float(_rules.reserve_en_regen_per_sec).is_equal(1.0)
	assert_float(_rules.reserve_ug_share).is_equal(0.30)


func test_perfect_dodge_and_flags() -> void:
	assert_float(_rules.perfect_dodge_window_sec).is_equal(0.15)
	assert_float(_rules.perfect_dodge_enemy_slow).is_equal(0.30)
	assert_float(_rules.perfect_dodge_slow_sec).is_equal(0.6)
	assert_int(_rules.perfect_dodge_refund_charges).is_equal(1)
	assert_float(_rules.perfect_dodge_icd_sec).is_equal(1.0)
	assert_bool(_rules.revive_enabled).is_false()             # Q6


func test_rules_validate_catches_bad_values() -> void:
	var bad: CombatRules = _rules.duplicate()
	bad.def_constant_k = 0.0
	bad.cdr_cap = 1.5
	bad.dodge_charges = 0
	assert_int(bad.validate().size()).is_equal(3)


# ---------- StatusDef ----------

func test_all_statuses_load_without_errors() -> void:
	assert_array(_lib.errors).is_empty()
	# Buff của hiệu ứng trang bị (eqb_*, sinh bằng tools/gen_equipment_5star.py) kiểm ở test_equipment_effects.gd.
	var core := Array(_lib.ids()).filter(func(id: String) -> bool: return not id.begins_with("eqb_"))
	assert_array(core).contains_exactly(EXPECTED_STATUSES)
	for id in _lib.ids():
		if id.begins_with("eqb_"):
			assert_bool(_lib.get_status(id).equipment).is_true()


func test_every_status_has_translated_name() -> void:
	for id in _lib.ids():
		var key := _lib.get_status(id).name_key
		assert_str(key).is_equal("STATUS_" + id.to_upper())
		for lang in ["vi", "en"]:
			TranslationServer.set_locale(lang)
			assert_str(TranslationServer.translate(key)).override_failure_message(
					"%s chưa có bản dịch %s" % [key, lang]).is_not_equal(key)
	TranslationServer.set_locale("vi")


func test_burn() -> void:
	var s := _lib.get_status("burn")
	assert_float(s.default_duration).is_equal(4.0)
	assert_float(s.tick_interval_sec).is_equal(0.5)
	assert_float(s.tick_atk_ratio).is_equal(0.08)
	assert_int(s.tick_count()).is_equal(8)                    # 8 nhịp × 8% = 64% ATK
	assert_int(s.stacking).is_equal(StatusDef.Stacking.REFRESH)


func test_stun_and_resist() -> void:
	var s := _lib.get_status("stun")
	assert_float(s.duration_for(false)).is_equal(2.0)
	assert_float(s.duration_for(true)).is_equal(1.0)
	assert_float(s.resist_after_sec).is_equal(8.0)
	assert_bool(s.blocks_actions).is_true()
	assert_bool(s.blocks_movement).is_true()


func test_lightning_mark_stacks() -> void:
	var s := _lib.get_status("lightning_mark")
	assert_int(s.stacking).is_equal(StatusDef.Stacking.STACKS)
	assert_int(s.max_stacks).is_equal(3)
	assert_float(s.default_duration).is_equal(6.0)
	assert_str(s.on_max_stacks_event).is_equal("lightning_burst")


func test_stat_modifiers() -> void:
	assert_float(_lib.get_status("judgment").default_magnitude).is_equal(0.08)
	assert_str(_lib.get_status("judgment").magnitude_meaning).is_equal(StatusDef.MAGNITUDE_DAMAGE_TAKEN_UP)
	assert_float(_lib.get_status("curse").default_magnitude).is_equal(0.15)
	assert_str(_lib.get_status("curse").magnitude_meaning).is_equal(StatusDef.MAGNITUDE_DEF_REDUCTION)
	assert_float(_lib.get_status("sand_blind").default_magnitude).is_equal(0.20)
	assert_float(_lib.get_status("sand_blind").default_duration).is_equal(4.0)
	assert_bool(_lib.get_status("earth_guard").stagger_immune).is_true()
	assert_bool(_lib.get_status("root").blocks_movement).is_true()
	assert_bool(_lib.get_status("root").blocks_actions).is_false()   # Trói: vẫn tấn công


func test_def_debuffs_refresh_not_stack() -> void:
	# Q3: cùng tên làm mới thời gian (không cộng tầng); khác tên mới cộng dồn (trần ở CombatRules).
	for id in _lib.ids():
		var s := _lib.get_status(id)
		if s.magnitude_meaning == StatusDef.MAGNITUDE_DEF_REDUCTION:
			assert_int(s.stacking).is_equal(StatusDef.Stacking.REFRESH)
			assert_int(s.max_stacks).is_equal(1)


func test_elemental_flags_for_kael_link() -> void:
	# Mục 8.3: Cháy, Chậm, Dấu Sét, Nguyền, Phán quyết, Trói... tính là hiệu ứng nguyên tố.
	for id in ["burn", "slow", "lightning_mark", "curse", "judgment", "root"]:
		assert_bool(_lib.get_status(id).counts_as_elemental).override_failure_message(id).is_true()
	for id in ["stun", "shield", "earth_guard", "taunt"]:
		assert_bool(_lib.get_status(id).counts_as_elemental).override_failure_message(id).is_false()


func test_status_validate_catches_bad_values() -> void:
	var s: StatusDef = _lib.get_status("burn").duplicate()
	s.tick_atk_ratio = 0.0         # tick không có sát thương
	s.max_stacks = 3               # REFRESH mà nhiều tầng
	s.magnitude_meaning = "foo"
	assert_int(s.validate().size()).is_equal(3)


# ---------- GameConfig ----------

func test_game_config_autoload_exposes_data() -> void:
	var gc := get_tree().root.get_node_or_null("GameConfig")
	if gc == null:
		gc = auto_free(load("res://scripts/core/game_config.gd").new())
		gc.load_data()
	assert_object(gc.combat_rules).is_not_null()
	assert_float(gc.combat_rules.def_constant_k).is_equal(500.0)
	assert_object(gc.statuses.get_status("burn")).is_not_null()
