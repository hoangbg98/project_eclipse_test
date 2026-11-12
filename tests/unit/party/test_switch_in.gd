extends GdUnitTestSuite
## Test M4-4: Kĩ năng vào sân Thường / Liên kết / mặc định của Aether, Lyra, Kael (mục 8.2, 8.5–8.7).

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")
const IDS := ["char_fire_01", "char_wind_01", "char_lightning_01"]

var _stage: Node2D
var _party: PartyManager
var _bus: Node


func _setup(ids: Array, x := 820.0) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.spawn_enemies = false
	_stage.party_ids = PackedStringArray(ids)
	add_child(_stage)
	_party = _stage.party
	_party.use_player_input = false
	for m in _party.members:
		m.controller.use_player_input = false
		m.combatant().rng = RandomSource.Fixed.new(0.99)   # không chí mạng
	_bus = get_tree().root.get_node("EventBus")
	_stage.player.global_position = Vector2(x, 896)
	_stage.player.facing = 1
	await _frames(10)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _m(i: int) -> CharacterRuntime:
	return _party.members[i]


func _dummy(i: int) -> TrainingDummy:
	return _stage.dummies[i]


func _skills(id: String) -> Dictionary:
	return (load("res://data/characters/%s.tres" % id) as CharacterDef).load_skills()


func _wait_runner_done(p: PlayerController) -> void:
	for i in 120:
		await get_tree().physics_frame
		if not p.runner.is_running():
			return


# ---------- Dữ liệu ----------

func test_switch_in_data_matches_spec() -> void:
	# [Thường, Liên kết] tổng % ATK; khởi động / hiệu lực / hồi phục; bất tử tới (ms)
	var spec := {
		"char_fire_01": [1.30, 1.90, [220.0, 120.0, 260.0], 340.0],
		"char_wind_01": [1.20, 1.80, [180.0, 200.0, 220.0], 380.0],
		"char_lightning_01": [1.10, 1.60, [120.0, 100.0, 180.0], 220.0],
	}
	for id: String in spec:
		var s := _skills(id)
		for k in ["switch_in", "switch_in_linked"]:
			assert_bool(s.has(k)).override_failure_message("%s thiếu %s" % [id, k]).is_true()
			var d: SkillDef = s[k]
			assert_array(d.validate()).is_empty()
			assert_str(d.id).is_equal("%s.%s" % [id, k])
			assert_int(d.hit_kind).is_equal(ResourceComponent.HitKind.SWITCH_IN)
			assert_float(d.en_cost).is_equal(0.0)                       # 8.2: không tốn EN
			assert_float(d.cooldown_sec).is_equal(0.0)                  # SI-CD do LinkTracker giữ
			assert_array([d.startup_ms, d.active_ms, d.recovery_ms]).is_equal(spec[id][2])
			assert_float(d.invuln_from_ms).is_equal(0.0)
			assert_float(d.invuln_to_ms).is_equal(spec[id][3])
			assert_float(d.invuln_to_ms).is_less_equal(500.0)           # 8.2: tối đa 500 ms
		assert_float(s["switch_in"].total_atk_ratio()).is_equal_approx(spec[id][0], 0.0001)
		assert_float(s["switch_in_linked"].total_atk_ratio()).is_equal_approx(spec[id][1], 0.0001)


func test_switch_in_def_data() -> void:
	var a: SwitchInDef = (load("res://data/characters/char_fire_01.tres") as CharacterDef).switch_in
	assert_str(a.reduce_on).is_equal(SwitchInDef.REDUCE_STUNNED_HIT)
	assert_array([a.reduce_sec, a.reduce_max_per_cycle_sec]).is_equal([1.0, 3.0])
	assert_int(a.self_statuses_linked.size()).is_equal(2)              # +2 Nhiệt
	var l: SwitchInDef = (load("res://data/characters/char_wind_01.tres") as CharacterDef).switch_in
	assert_str(l.reduce_on).is_equal(SwitchInDef.REDUCE_PERFECT_DODGE)
	assert_array([l.reduce_sec, l.reduce_max_per_cycle_sec, l.reduce_window_sec, l.reduce_icd_sec]).is_equal([1.5, 3.0, 4.0, 3.0])
	assert_array([l.self_statuses_normal[0].magnitude, l.self_statuses_normal[0].duration]).is_equal([0.10, 3.0])
	assert_array([l.self_statuses_linked[0].magnitude, l.self_statuses_linked[0].duration]).is_equal([0.25, 4.0])
	var k: SwitchInDef = (load("res://data/characters/char_lightning_01.tres") as CharacterDef).switch_in
	assert_str(k.reduce_on).is_equal(SwitchInDef.REDUCE_LIGHTNING_BURST)
	assert_array([k.reduce_sec, k.reduce_max_per_cycle_sec, k.reduce_window_sec]).is_equal([1.0, 3.0, 5.0])
	assert_str(k.self_statuses_linked[0].status_id).is_equal("attack_speed_up")
	assert_float(k.self_statuses_linked[0].magnitude).is_equal(0.15)


# ---------- Ba mức vào sân ----------

func test_normal_switch_runs_switch_in_and_is_invulnerable() -> void:
	await _setup(IDS)
	_party.request_switch(2)                                            # Kael, Thường
	var k := _m(2).controller
	assert_str(_party.last_switch_mode).is_equal("normal")
	assert_str(k.runner.current_key).is_equal("switch_in")
	assert_bool(k.hurtbox.invulnerable).is_true()
	await _wait_runner_done(k)
	assert_bool(k.hurtbox.invulnerable).is_false()


func test_default_switch_runs_no_skill() -> void:
	await _setup(IDS)
	_m(2).combatant().cooldowns.trigger(LinkTracker.SI_CD_KEY)
	_party.request_switch(2)
	assert_str(_party.last_switch_mode).is_equal("default")
	assert_bool(_m(2).controller.runner.is_running()).is_false()


func test_switch_in_costs_no_en() -> void:
	await _setup(IDS)
	_m(2).resources().en = 0.0
	_party.request_switch(2)
	assert_str(_m(2).controller.runner.current_key).is_equal("switch_in")


# ---------- Kael ----------

func test_kael_teleports_to_target_and_marks() -> void:
	await _setup(IDS)
	_party.request_switch(2)
	var k := _m(2).controller
	# Hình nộm gần nhất ở x = 928: dịch chuyển ngay, đứng cách 70 px.
	assert_float(k.global_position.x).is_equal_approx(928.0 - 70.0, 1.0)
	assert_int(k.facing).is_equal(1)
	await _wait_runner_done(k)
	assert_int(_dummy(0).combatant.statuses.stacks("lightning_mark")).is_equal(1)   # Thường: 1 Dấu Sét
	assert_int(_dummy(0).total_damage).is_greater(0)


func test_kael_prefers_target_with_elemental_status() -> void:
	await _setup(IDS)
	_dummy(1).combatant.statuses.apply("burn", 4.0, -1.0, null)
	_party.request_switch(2)
	var k := _m(2).controller
	assert_vector(k.runner.target_position).is_equal(_dummy(1).global_position)
	assert_float(k.global_position.x).is_equal_approx(_dummy(1).global_position.x - 70.0, 1.0)


func test_kael_linked_two_marks_and_attack_speed() -> void:
	await _setup(IDS)
	_bus.status_applied.emit(_dummy(0).combatant, "burn", _party.active().combatant())  # mở Liên kết Kael
	_party.request_switch(2)
	assert_str(_party.last_switch_mode).is_equal("linked")
	var k := _m(2).controller
	assert_str(k.runner.current_key).is_equal("switch_in_linked")
	assert_float(k.combatant.statuses.attack_speed_up()).is_equal(0.15)
	assert_float(k.combatant.statuses.remaining("attack_speed_up")).is_equal_approx(4.0, 0.05)
	await _wait_runner_done(k)
	assert_int(_dummy(0).combatant.statuses.stacks("lightning_mark")).is_equal(2)


func test_kael_lightning_burst_reduces_si_cd_in_5s() -> void:
	await _setup(IDS)
	_party.request_switch(2)
	var kc := _m(2).combatant()
	var left := kc.cooldowns.remaining(LinkTracker.SI_CD_KEY)
	_bus.status_max_stacks.emit(_dummy(0).combatant, "lightning_mark", _m(0).combatant())  # nguồn khác: không tính
	_bus.status_max_stacks.emit(_dummy(0).combatant, "burn", kc)                           # không phải Dấu Sét
	assert_float(kc.cooldowns.remaining(LinkTracker.SI_CD_KEY)).is_equal(left)
	_bus.status_max_stacks.emit(_dummy(0).combatant, "lightning_mark", kc)
	assert_float(kc.cooldowns.remaining(LinkTracker.SI_CD_KEY)).is_equal_approx(left - 1.0, 0.001)
	_party.tick(5.1)                                                     # hết cửa sổ 5 s
	var after := kc.cooldowns.remaining(LinkTracker.SI_CD_KEY)
	_bus.status_max_stacks.emit(_dummy(0).combatant, "lightning_mark", kc)
	assert_float(kc.cooldowns.remaining(LinkTracker.SI_CD_KEY)).is_equal(after)


# ---------- Aether ----------

func test_aether_dashes_up_to_350_toward_target() -> void:
	await _setup(["char_wind_01", "char_fire_01", "char_lightning_01"], 500.0)
	var start: float = _stage.player.global_position.x
	_party.request_switch(1)
	var a := _m(1).controller
	assert_str(a.runner.current_key).is_equal("switch_in")
	await _wait_runner_done(a)
	# Hình nộm ở 928: khoảng cách 428 − 80 = 348 (≤ 350).
	assert_float(a.global_position.x - start).is_equal_approx(348.0, 12.0)
	assert_bool(_dummy(0).combatant.statuses.has("burn")).is_true()
	assert_float(_dummy(0).combatant.statuses.remaining("burn")).is_between(2.0, 3.0)  # Thường: Cháy 3 s


func test_aether_dash_capped_at_350() -> void:
	await _setup(["char_wind_01", "char_fire_01", "char_lightning_01"], 460.0)
	var start: float = _stage.player.global_position.x
	_party.request_switch(1)
	await _wait_runner_done(_m(1).controller)
	assert_float(_m(1).controller.global_position.x - start).is_equal_approx(350.0, 12.0)  # 468 − 80 > 350


func test_aether_prefers_stunned_target() -> void:
	await _setup(["char_wind_01", "char_fire_01", "char_lightning_01"], 700.0)
	_dummy(1).combatant.statuses.apply("stun", -1.0, -1.0, null)
	_party.request_switch(1)
	assert_vector(_m(1).controller.runner.target_position).is_equal(_dummy(1).global_position)


func test_aether_linked_bonus_vs_stunned_heat_and_si_cd_cut() -> void:
	await _setup(["char_wind_01", "char_fire_01", "char_lightning_01"], 640.0)
	var dmg := {}
	for i in 2:
		_dummy(i).combatant.damaged.connect(func(r: DamageCalculator.Result, h: HitInfo) -> void:
			if h.skill_id.ends_with("switch_in_linked"):
				dmg[i] = r.amount)
	_dummy(0).combatant.statuses.apply("stun", -1.0, -1.0, null)
	_bus.enemy_stunned.emit(_dummy(0), _party.active().combatant())    # mở Liên kết Aether
	_party.request_switch(1)
	var a := _m(1)
	assert_str(_party.last_switch_mode).is_equal("linked")
	assert_int(a.combatant().statuses.stacks("heat")).is_equal(2)     # +2 Nhiệt
	await _wait_runner_done(a.controller)
	assert_bool(dmg.has(0) and dmg.has(1)).override_failure_message(str(dmg)).is_true()
	# Hai hình nộm cùng DEF: hình nộm đang Choáng nhận thêm 30%.
	assert_float(float(dmg[0]) / float(dmg[1])).is_equal_approx(1.3, 0.01)
	assert_float(_dummy(1).combatant.statuses.remaining("burn")).is_between(4.0, 5.0)   # Liên kết: Cháy 5 s
	# 1 kẻ địch Choáng trúng → −1.0 s SI-CD.
	assert_float(a.combatant().cooldowns.remaining(LinkTracker.SI_CD_KEY)).is_less(9.05)


func test_aether_si_cd_cut_capped_3s_per_cycle() -> void:
	await _setup(["char_wind_01", "char_fire_01", "char_lightning_01"], 640.0)
	_party.request_switch(1)
	var a := _m(1)
	var cds := a.combatant().cooldowns
	var full := cds.remaining(LinkTracker.SI_CD_KEY)
	# Đòn khác (không phải vào sân), hoặc mục tiêu không Choáng: không tính.
	var other := HitInfo.new()
	other.skill_id = "char_fire_01.normal_1"
	other.target_statuses_before = PackedStringArray(["stun"])
	_party._on_member_hit_dealt(_dummy(0).combatant, DamageCalculator.Result.new(), other, a)
	var not_stunned := HitInfo.new()
	not_stunned.skill_id = "char_fire_01.switch_in"
	_party._on_member_hit_dealt(_dummy(0).combatant, DamageCalculator.Result.new(), not_stunned, a)
	assert_float(cds.remaining(LinkTracker.SI_CD_KEY)).is_equal(full)
	for i in 5:
		var h := HitInfo.new()
		h.skill_id = "char_fire_01.switch_in"
		h.target_statuses_before = PackedStringArray(["stun"])
		_party._on_member_hit_dealt(_dummy(0).combatant, DamageCalculator.Result.new(), h, a)
	assert_float(cds.remaining(LinkTracker.SI_CD_KEY)).is_equal_approx(full - 3.0, 0.001)


# ---------- Lyra ----------

func test_lyra_fires_three_arrows_and_last_slows() -> void:
	await _setup(["char_fire_01", "char_wind_01", "char_lightning_01"], 700.0)
	var angles := []
	_stage.child_entered_tree.connect(func(n: Node) -> void:
		if n is DetachedHit:
			angles.append(roundi(rad_to_deg(n.rotation))))
	_party.request_switch(1)
	var l := _m(1)
	assert_str(l.controller.runner.current_key).is_equal("switch_in")
	assert_float(l.combatant().statuses.move_speed_up()).is_equal(0.10)        # Gió Trợ Bước Thường
	assert_float(l.combatant().statuses.remaining("wind_step")).is_equal_approx(3.0, 0.05)
	await _wait_runner_done(l.controller)
	await _frames(20)
	assert_array(angles).is_equal([-15, 15, 0])
	var d := _dummy(0).combatant
	assert_bool(d.statuses.has("slow")).is_true()
	assert_float(d.statuses.magnitude("slow")).is_equal(0.25)


func test_lyra_linked_wind_step() -> void:
	await _setup(["char_fire_01", "char_wind_01", "char_lightning_01"], 700.0)
	_party.active_controller().perfect_dodged.emit(HitInfo.new())      # mở Liên kết Lyra
	_party.request_switch(1)
	assert_str(_m(1).controller.runner.current_key).is_equal("switch_in_linked")
	assert_float(_m(1).combatant().statuses.move_speed_up()).is_equal(0.25)
	assert_float(_m(1).combatant().statuses.remaining("wind_step")).is_equal_approx(4.0, 0.05)


func test_lyra_perfect_dodge_cuts_si_cd_with_icd_and_window() -> void:
	await _setup(["char_fire_01", "char_wind_01", "char_lightning_01"], 700.0)
	_party.request_switch(1)
	var l := _m(1)
	var cds := l.combatant().cooldowns
	var full := cds.remaining(LinkTracker.SI_CD_KEY)
	l.controller.perfect_dodged.emit(HitInfo.new())
	l.controller.perfect_dodged.emit(HitInfo.new())                    # trong ICD 3 s
	assert_float(cds.remaining(LinkTracker.SI_CD_KEY)).is_equal_approx(full - 1.5, 0.001)
	_party.tick(3.1)                                                   # người trên sân không do party.tick đếm CD
	l.controller.perfect_dodged.emit(HitInfo.new())
	assert_float(cds.remaining(LinkTracker.SI_CD_KEY)).is_equal_approx(full - 3.0, 0.001)
	_party.tick(1.0)                                                   # quá cửa sổ 4 s
	assert_float(l.si_window_left).is_equal(0.0)


func test_wind_step_raises_run_speed() -> void:
	await _setup(["char_wind_01", "char_fire_01", "char_lightning_01"], 700.0)
	var p := _stage.player as PlayerController
	p.combatant.statuses.apply("wind_step", 4.0, 0.25, p.combatant)
	p.intent.move_x = 1.0
	await _frames(40)
	assert_float(p.velocity.x).is_equal_approx(p.config.run_speed * 1.25, 1.0)


# ---------- Tốc độ tấn công ----------

func test_attack_speed_scales_basic_attacks_only() -> void:
	await _setup(IDS)
	var p := _stage.player as PlayerController
	p.combatant.statuses.apply("attack_speed_up", 4.0, 0.15, p.combatant)
	p.runner.run("normal_1", 1)
	assert_float(p.attack_speed_factor()).is_equal(1.15)
	p.runner.cancel()
	p.combatant.resources.add_en(100.0)
	p.runner.run("skill", 1)
	assert_float(p.attack_speed_factor()).is_equal(1.0)


# ---------- Cơ chế chung ----------

func test_detached_hit_travel_angle_mirrors_with_facing() -> void:
	var h := HitDef.new()
	h.detached = true
	h.travel_px = 700.0
	h.duration_ms = 300.0
	h.travel_angle_deg = 15.0
	var parent := auto_free(Node2D.new()) as Node2D
	add_child(parent)
	var d := DetachedHit.spawn(parent, h, null, PhysicsLayers.Team.PLAYER, -1, Vector2.ZERO, {}, 0, "t")
	var speed := 700.0 / 0.3
	assert_float(d.velocity.x).is_equal_approx(-cos(deg_to_rad(15.0)) * speed, 0.01)
	assert_float(d.velocity.y).is_equal_approx(sin(deg_to_rad(15.0)) * speed, 0.01)


func test_bonus_vs_status_only_when_target_has_it() -> void:
	await _setup(IDS)
	var src := _party.active().combatant()
	var d := _dummy(0).combatant
	var h := HitInfo.new()
	h.attacker = _party.active_controller()
	h.atk_ratio = 1.0
	h.bonus_vs_status = "stun"
	h.bonus_vs_status_ratio = 0.3
	var plain := d.receive_hit(h).amount
	d.statuses.apply("stun", -1.0, -1.0, src)
	var h2 := HitInfo.new()
	h2.attacker = h.attacker
	h2.atk_ratio = 1.0
	h2.bonus_vs_status = "stun"
	h2.bonus_vs_status_ratio = 0.3
	assert_float(float(d.receive_hit(h2).amount) / float(plain)).is_equal_approx(1.3, 0.01)
