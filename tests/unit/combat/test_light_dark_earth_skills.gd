extends GdUnitTestSuite
## Hikarine (char_light_01), Yomigari (char_dark_01), Iwagane (char_earth_01): đủ bộ kỹ năng
## (CHARACTER_SKILLS mục 4, 5, 6, 8.8–8.10; tools/gen_light_dark_earth_skills.py).

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")

var _stage: Node2D
var _p: PlayerController
var _started: Array[String] = []


func before_test() -> void:
	_started.clear()


func _setup(ids: Array, x := 820.0) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.spawn_enemies = false
	_stage.party_ids = PackedStringArray(ids)
	add_child(_stage)
	_stage.party.use_player_input = false
	for m in _stage.party.members:
		m.controller.use_player_input = false
		m.combatant().rng = RandomSource.Fixed.new(0.99)
	_p = _stage.player
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


func _wait_done(max_frames := 300) -> void:
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


func _total(s: Dictionary, keys: Array) -> float:
	var t := 0.0
	for k in keys:
		t += (s[k] as SkillDef).total_atk_ratio()
	return t


func _heal_total(s: SkillDef) -> Array:
	var atk := 0.0
	var hp := 0.0
	for h: HealDef in s.heals:
		atk += h.atk_ratio * h.ticks
		hp += h.max_hp_ratio * h.ticks
	return [snappedf(atk, 0.0001), snappedf(hp, 0.0001)]


func _assert_heal(s: SkillDef, atk: float, hp: float) -> void:
	var t := _heal_total(s)
	assert_float(t[0]).is_equal_approx(atk, 0.0001)
	assert_float(t[1]).is_equal_approx(hp, 0.0001)


## Đòn giả vào người chơi (không có người đánh: dùng ATK mặc định của luật).
func _incoming_hit(ratio := 1.0) -> DamageCalculator.Result:
	var h := HitInfo.new()
	h.atk_ratio = ratio
	h.team = PhysicsLayers.Team.ENEMY
	return _p.combatant.receive_hit(h)


# ---------- Dữ liệu ----------

const ALL_KEYS := ["normal_1", "normal_2", "normal_3", "dodge", "hold_1", "air_1", "landing", "skill", "weapon",
		"ultimate", "switch_in", "switch_in_linked"]


func test_all_three_have_full_valid_kits() -> void:
	for id in ["char_light_01", "char_dark_01", "char_earth_01"]:
		var c: CharacterDef = load("res://data/characters/%s.tres" % id)
		assert_object(c.kit_script).override_failure_message(id + " thiếu kit").is_not_null()
		assert_object(c.switch_in).is_not_null()
		var s := c.load_skills()
		for k in ALL_KEYS:
			assert_bool(s.has(k)).override_failure_message("%s thiếu %s" % [id, k]).is_true()
		for k: String in s:
			assert_array((s[k] as SkillDef).validate()).is_empty()


func test_hikarine_numbers_match_spec() -> void:
	var s := _skills("char_light_01")
	assert_float(_total(s, ["normal_1", "normal_2", "normal_3"])).is_equal_approx(1.95, 0.0001)
	_assert_heal(s["normal_3"], 0.4, 0.0)
	assert_float(_total(s, ["hold_1"])).is_equal_approx(1.20, 0.0001)                 # 20% x6 lên kẻ địch
	_assert_heal(s["hold_1"], 1.5, 0.06)                      # 25% ATK + 1% HP x6
	assert_float(s["hold_1"].en_per_sec).is_equal(8.0)
	assert_float(_total(s, ["air_1"])).is_equal_approx(1.35, 0.0001)
	assert_float(_total(s, ["landing"])).is_equal_approx(1.10, 0.0001)
	_assert_heal(s["skill"], 1.7, 0.04)                       # 90% + 20% x4, 4% HP
	assert_float(_total(s, ["weapon"])).is_equal_approx(2.80, 0.0001)
	assert_float(_total(s, ["ultimate"])).is_equal_approx(4.00, 0.0001)               # 25% x16
	_assert_heal(s["ultimate"], 0.0, 0.32)                   # 4% x8
	assert_bool(s["ultimate"].locks_switch).is_false()


func test_yomigari_numbers_match_spec() -> void:
	var s := _skills("char_dark_01")
	assert_float(_total(s, ["normal_1", "normal_2", "normal_3", "normal_4"])).is_equal_approx(3.60, 0.0001)
	assert_float(_total(s, ["hold_1", "hold_finish"])).is_equal_approx(2.58, 0.0001)  # 28% x6 + 90%
	assert_float(_total(s, ["air_1", "air_2"])).is_equal_approx(1.80, 0.0001)
	assert_float(_total(s, ["landing"])).is_equal_approx(1.30, 0.0001)
	assert_float(_total(s, ["skill"])).is_equal_approx(2.00, 0.0001)                  # 25% x8
	assert_float(_total(s, ["weapon"])).is_equal_approx(2.60, 0.0001)
	assert_float(_total(s, ["ultimate"])).is_equal_approx(11.5, 0.0001)               # 6x100% + 550%
	assert_bool(s["ultimate"].locks_switch).is_true()


func test_iwagane_numbers_match_spec() -> void:
	var s := _skills("char_earth_01")
	assert_float(_total(s, ["normal_1", "normal_2", "normal_3"])).is_equal_approx(3.90, 0.0001)
	assert_float(_total(s, ["hold_slash"])).is_equal_approx(1.70, 0.0001)
	assert_float(_total(s, ["hold_slash_weak"])).is_equal_approx(0.90, 0.0001)
	assert_bool(s.has("air_2")).is_false()                                             # 1 đòn mỗi lần nhảy
	assert_float(_total(s, ["air_1"])).is_equal_approx(1.20, 0.0001)
	assert_float(_total(s, ["landing"])).is_equal_approx(3.10, 0.0001)                # 190% + 2 x 60%
	assert_float(_total(s, ["weapon"])).is_equal_approx(3.00, 0.0001)
	assert_float(_total(s, ["ultimate"])).is_equal_approx(11.0, 0.0001)               # 650% + 3 x 150%


# ---------- Hikarine ----------

func test_hikarine_skill_heals_whole_team_lowest_more_and_cleanses() -> void:
	await _setup(["char_light_01", "char_wind_01", "char_fire_01"])
	var ms: Array = _stage.party.members
	for m in ms:
		m.resources().take_damage(m.resources().max_hp * 0.5)
	ms[2].resources().take_damage(ms[2].resources().max_hp * 0.2)                    # Enkiba thấp nhất (30%)
	ms[1].combatant().statuses.apply("burn", 4.0, -1.0, null)
	_p.combatant.resources.en = 100.0
	var hp0: Array = ms.map(func(m: CharacterRuntime) -> float: return m.resources().hp)
	_press(PlayerIntent.SKILL)
	await _frames(20)                                                               # qua 200 ms
	var atk := _p.combatant.current_atk()
	var gain0: float = ms[0].resources().hp - hp0[0]
	assert_float(gain0).is_equal_approx(atk * 0.9 + ms[0].resources().max_hp * 0.04, 2.0)
	var gain2: float = ms[2].resources().hp - hp0[2]
	assert_float(gain2).is_equal_approx((atk * 0.9 + ms[2].resources().max_hp * 0.04) * 1.3, 2.0)   # thấp nhất x1.3
	assert_float(ms[1].resources().hp).is_greater(hp0[1])                            # dự bị cũng được hồi
	assert_bool(ms[1].combatant().statuses.has("burn")).is_false()                   # xóa hiệu ứng xấu


func test_hikarine_overflow_heal_becomes_shield() -> void:
	await _setup(["char_light_01"])
	var r := _p.combatant.resources
	r.take_damage(100.0)
	_p.combatant.heal_target(_p.combatant, 2000.0)                                  # thừa 1900
	assert_bool(_p.combatant.statuses.has("shield")).is_true()
	assert_float(r.shield).is_equal_approx(r.max_hp * 0.08, 1.0)                    # 50% thừa, trần 8% HP


func test_hikarine_prayer_drains_en_heals_and_slows() -> void:
	# Đứng xa hình nộm: nhịp trúng kẻ địch cũng cộng EN (đòn giữ +3), sẽ che mất lượng EN bị tiêu.
	await _setup(["char_light_01"], 150.0)
	_p.combatant.resources.take_damage(3000.0)
	_p.combatant.resources.en = 50.0
	var hp0 := _p.combatant.resources.hp
	_p.intent.attack_down()
	await _frames(30)
	assert_str(_p.runner.current_key).is_equal("hold_1")
	_p.intent.move_x = 1.0
	await _frames(30)
	assert_float(absf(_p.velocity.x)).is_less_equal(_p.config.run_speed * 0.3 + 1.0)  # đi chậm 70%
	_p.intent.move_x = 0.0
	assert_float(_p.combatant.resources.hp).is_greater(hp0)
	assert_float(_p.combatant.resources.en).is_less(50.0)                           # 8 EN/s > hồi 2 EN/s
	_p.intent.attack_up(_buf())
	await _frames(3)
	assert_bool(_p.runner.is_running()).is_false()
	assert_str(_p.runner.check("hold_1")).is_equal("cooldown")


func test_hikarine_ultimate_zone_heals_and_reduces_damage() -> void:
	await _setup(["char_light_01"], 820.0)
	var hits := []
	_watch(_dummy(0).combatant, hits)
	_p.combatant.resources.take_damage(5000.0)
	_p.combatant.resources.ug = 100.0
	_press(PlayerIntent.ULTIMATE)
	await _frames(3)
	assert_bool(_p.is_switch_locked()).is_false()
	await _frames(100)                                                              # > 700 ms + 1 nhịp
	assert_float(_p.combatant.resources.hp_ratio()).is_greater(0.5)
	assert_bool(_p.combatant.statuses.has("sanctuary")).is_true()
	assert_bool(hits.has("char_light_01.ultimate")).is_true()
	assert_bool(_dummy(0).combatant.statuses.has("judgment")).is_true()


# ---------- Yomigari ----------

func test_yomigari_lifesteal_on_cursed_target() -> void:
	await _setup(["char_dark_01"], 820.0)
	_p.combatant.resources.take_damage(4000.0)
	_dummy(0).combatant.statuses.apply("curse", 10.0, -1.0, null)
	var hp0 := _p.combatant.resources.hp
	_p.intent.tap_attack(_buf())
	await _wait_done()
	assert_float(_p.combatant.resources.hp).is_greater(hp0)                         # hồi 4% sát thương


func test_yomigari_hold_spins_then_finisher_curses() -> void:
	await _setup(["char_dark_01"], 760.0)
	_p.combatant.resources.en = 50.0
	_p.intent.attack_down()
	await _frames(40)
	assert_str(_p.runner.current_key).is_equal("hold_1")
	assert_float(_p.combatant.resources.en).is_less_equal(42.0)                     # 10 EN khi bắt đầu (+2 EN/s tự hồi)
	_p.intent.attack_up(_buf())
	await _frames(3)
	assert_str(_p.runner.current_key).is_equal("hold_finish")
	await _wait_done()
	assert_bool(_dummy(0).combatant.statuses.has("curse")).is_true()


func test_yomigari_ultimate_executes_low_hp_and_grants_night_king() -> void:
	await _setup(["char_dark_01"], 840.0)
	var d := _dummy(0).combatant
	d.resources.hp = d.resources.max_hp * 0.15
	_p.combatant.resources.ug = 100.0
	_press(PlayerIntent.ULTIMATE)
	await _frames(3)
	assert_bool(_p.is_switch_locked()).is_true()
	assert_bool(_p.combatant.statuses.has("night_king")).is_true()
	await _wait_done()
	assert_int(_p.kit.executions).is_greater_equal(1)


func test_yomigari_weapon_roots_and_blocks_normals() -> void:
	await _setup(["char_dark_01"], 700.0)
	_p.combatant.resources.en = 100.0
	_press(PlayerIntent.WEAPON)
	await _wait_done()
	_p.intent.tap_attack(_buf())
	await _frames(2)
	assert_bool(_started.has("normal_1")).is_false()                                # khóa đòn thường 1 s
	await _frames(20)
	assert_bool(_dummy(0).combatant.statuses.has("root")).is_true()


# ---------- Iwagane ----------

func test_iwagane_bones_from_damage_reduce_taken() -> void:
	await _setup(["char_earth_01"])
	_incoming_hit()
	await _frames(40)                                                               # qua ICD 0.5 s
	_incoming_hit()
	assert_int(_p.kit.bones()).is_equal(2)
	await _frames(1)
	assert_float(_p.combatant.statuses.magnitude("stone_bone")).is_equal_approx(0.06, 0.0001)


func test_iwagane_guard_perfect_block_then_strong_slash() -> void:
	await _setup(["char_earth_01"], 700.0)
	_p.combatant.resources.en = 100.0
	_p.intent.attack_down()
	await _frames(28)                                                               # ~470 ms: chắn được 170 ms
	assert_str(_p.runner.current_key).is_equal("hold_1")
	assert_bool(_p.combatant.statuses.has("guard")).is_true()
	var blocked_hit := _incoming_hit()                                              # đòn tới trong 200 ms đầu
	assert_int(_p.kit.perfect_blocks).is_equal(1)
	assert_int(_p.kit.blocked).is_equal(1)
	assert_float(blocked_hit.taken).is_less_equal(0.3 + 0.0001)                     # giảm >= 70% (chắn + Cốt Đá)
	await _frames(30)
	_p.intent.attack_up(_buf())
	await _frames(3)
	assert_str(_p.runner.current_key).is_equal("hold_slash")
	assert_bool(_p.combatant.statuses.has("guard")).is_false()


func test_iwagane_unblocked_guard_releases_weak_slash() -> void:
	await _setup(["char_earth_01"], 700.0)
	_p.combatant.resources.en = 100.0
	_p.intent.attack_down()
	await _frames(40)
	_p.intent.attack_up(_buf())
	await _frames(3)
	assert_str(_p.runner.current_key).is_equal("hold_slash_weak")


func test_iwagane_weapon_with_five_bones_consumes_them() -> void:
	await _setup(["char_earth_01"], 600.0)
	var hits := []
	_watch(_dummy(0).combatant, hits)
	for i in 5:
		_p.kit.add_bone()
	assert_int(_p.kit.bones()).is_equal(5)
	_p.combatant.resources.en = 100.0
	_press(PlayerIntent.WEAPON)
	await _frames(3)
	assert_int(_p.kit.bones()).is_equal(0)
	await _wait_done()
	await _frames(30)
	assert_bool(hits.has("char_earth_01.weapon")).is_true()
	assert_bool(_dummy(0).combatant.statuses.has("armor_break")).is_true()


func test_iwagane_ultimate_jumps_lands_and_stuns() -> void:
	await _setup(["char_earth_01"], 820.0)
	_p.combatant.resources.ug = 100.0
	_press(PlayerIntent.ULTIMATE)
	for f in 40:                                                                    # tới đỉnh nhảy (400 ms)
		if _p.runner.current_key == "ultimate" and _p.runner.elapsed_ms >= 400.0:
			break
		await get_tree().physics_frame
	assert_float(896.0 - _p.global_position.y).override_failure_message("cao %f, kỹ năng '%s' %f ms" % [
			896.0 - _p.global_position.y, _p.runner.current_key, _p.runner.elapsed_ms]).is_equal_approx(400.0, 60.0)
	await _frames(30)
	assert_float(_p.global_position.y).is_equal_approx(896.0, 4.0)                  # đã rơi xuống
	assert_bool(_dummy(0).combatant.statuses.has("stun")).is_true()
	assert_bool(_p.combatant.statuses.has("stone_god")).is_true()
	assert_bool(_p.is_switch_locked()).is_true()
