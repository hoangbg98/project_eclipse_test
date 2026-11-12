extends GdUnitTestSuite
## Test M4-3: LinkTracker — 6 điều kiện Liên kết, cửa sổ 6.0 s, SI-CD, mức vào sân (mục 8.2, 8.3).

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")

const SPEC := {  # mục 8.3: id → [điều kiện, SI-CD]
	"char_fire_01": ["enemy_stunned", 10.0],
	"char_wind_01": ["perfect_dodge", 9.0],
	"char_lightning_01": ["elemental_status", 8.0],
	"char_light_01": ["low_hp", 12.0],
	"char_dark_01": ["enemy_defeated", 11.0],
	"char_earth_01": ["weapon_or_ultimate", 12.0],
}

var _stage: Node2D
var _party: PartyManager
var _links: LinkTracker
var _bus: Node


func _setup(ids: Array) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.spawn_enemies = false
	_stage.party_ids = PackedStringArray(ids)
	add_child(_stage)
	_party = _stage.party
	_party.use_player_input = false
	for m in _party.members:
		m.controller.use_player_input = false
	_links = _party.links
	_bus = get_tree().root.get_node("EventBus")
	await get_tree().physics_frame


func _m(i: int) -> CharacterRuntime:
	return _party.members[i]


func _active_c() -> Combatant:
	return _party.active().combatant()


func _dummy_c() -> Combatant:
	return _stage.dummies[0].combatant


# ---------- Dữ liệu ----------

func test_six_characters_match_spec_table() -> void:
	var seen := {}
	for id: String in SPEC:
		var d: CharacterDef = load("res://data/characters/%s.tres" % id)
		assert_str(d.link_condition).is_equal(SPEC[id][0])
		assert_float(d.switch_in_cd_sec).is_equal(SPEC[id][1])
		seen[d.link_condition] = true
	assert_int(seen.size()).is_equal(6)
	for c in LinkTracker.CONDITIONS:
		assert_bool(seen.has(c)).is_true()
	var r: CombatRules = load("res://data/config/combat_rules.tres")
	assert_float(r.link_window_sec).is_equal(6.0)
	assert_float(r.link_bonus_ug).is_equal(15.0)
	assert_float(r.link_bonus_en).is_equal(10.0)


# ---------- SI-CD ----------

func test_si_cd_ready_at_start_and_normal_mode() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	assert_bool(_links.si_cd_ready(_m(1))).is_true()
	assert_str(_party.mode_for(1)).is_equal(LinkTracker.MODE_NORMAL)
	assert_bool(_links.is_glowing(_m(1))).is_false()


func test_normal_switch_starts_si_cd_then_default() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	_party.request_switch(1)
	assert_str(_party.last_switch_mode).is_equal(LinkTracker.MODE_NORMAL)
	assert_float(_links.si_cd_left(_m(1))).is_equal_approx(8.0, 0.001)
	_party.tick(1.0)                  # chỉ chờ chung; người trên sân tự đếm theo khung vật lý
	_party.request_switch(0)
	_party.tick(1.0)
	# Kael đếm SI-CD cả khi ở dự bị: còn 7 s → vào mặc định.
	assert_float(_links.si_cd_left(_m(1))).is_equal_approx(7.0, 0.01)
	assert_str(_party.mode_for(1)).is_equal(LinkTracker.MODE_DEFAULT)
	_party.request_switch(1)
	assert_str(_party.last_switch_mode).is_equal(LinkTracker.MODE_DEFAULT)
	# Vào mặc định không bắt đầu lại SI-CD.
	assert_float(_links.si_cd_left(_m(1))).is_equal_approx(7.0, 0.01)


func test_si_cd_uses_cdr() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	_m(1).combatant().cooldowns.cdr = 0.25
	_party.request_switch(1)
	assert_float(_links.si_cd_left(_m(1))).is_equal_approx(6.0, 0.001)   # 8 × (1 − 0.25)
	_m(1).combatant().cooldowns.cdr = 0.9                                 # trần 40%
	_party.tick(1.0)
	_party.request_switch(0)
	_party.tick(10.0)
	_party.request_switch(1)
	assert_float(_links.si_cd_left(_m(1))).is_equal_approx(4.8, 0.001)   # 8 × 0.6


# ---------- Cửa sổ 6.0 s ----------

func test_stun_by_active_opens_6s_window() -> void:
	await _setup(["char_lightning_01", "char_fire_01", "char_wind_01"])
	var opened := []
	var closed := []
	_bus.link_window_opened.connect(func(id: String, s: float) -> void: opened.append([id, s]))
	_bus.link_window_closed.connect(func(id: String) -> void: closed.append(id))
	_bus.enemy_stunned.emit(_stage.dummies[0], _active_c())
	assert_bool(_links.is_glowing(_m(1))).is_true()
	assert_bool(_links.is_glowing(_m(2))).is_false()
	assert_str(_party.mode_for(1)).is_equal(LinkTracker.MODE_LINKED)
	assert_array(opened).is_equal([["char_fire_01", 6.0]])
	_party.tick(5.9)
	assert_bool(_links.is_glowing(_m(1))).is_true()
	_party.tick(0.2)
	assert_bool(_links.is_glowing(_m(1))).is_false()
	assert_array(closed).is_equal(["char_fire_01"])
	assert_str(_party.mode_for(1)).is_equal(LinkTracker.MODE_NORMAL)


func test_repeat_event_refreshes_without_reopening() -> void:
	await _setup(["char_lightning_01", "char_fire_01", "char_wind_01"])
	var opened := [0]
	_bus.link_window_opened.connect(func(_id: String, _s: float) -> void: opened[0] += 1)
	_bus.enemy_stunned.emit(null, _active_c())
	_party.tick(4.0)
	_bus.enemy_stunned.emit(null, _active_c())
	assert_float(_links.window_left(_m(1))).is_equal_approx(6.0, 0.001)
	assert_int(opened[0]).is_equal(1)


func test_event_by_reserve_or_other_is_ignored() -> void:
	await _setup(["char_lightning_01", "char_fire_01", "char_wind_01"])
	_bus.enemy_stunned.emit(null, _m(2).combatant())
	_bus.enemy_stunned.emit(null, null)
	_bus.enemy_stunned.emit(null, _dummy_c())
	assert_float(_links.window_left(_m(1))).is_equal(0.0)


func test_active_own_condition_opens_nothing() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	_bus.enemy_stunned.emit(null, _active_c())
	assert_float(_links.window_left(_m(0))).is_equal(0.0)
	assert_bool(_links.is_glowing(_m(1)) or _links.is_glowing(_m(2))).is_false()


func test_glow_needs_si_cd_ready() -> void:
	await _setup(["char_lightning_01", "char_fire_01", "char_wind_01"])
	_party.request_switch(1)          # Aether vào Thường → SI-CD 10 s
	_party.tick(1.0)
	_party.request_switch(0)          # Kael vào Thường
	_bus.enemy_stunned.emit(null, _active_c())
	assert_float(_links.window_left(_m(1))).is_greater(0.0)
	assert_bool(_links.is_glowing(_m(1))).is_false()
	assert_str(_party.mode_for(1)).is_equal(LinkTracker.MODE_DEFAULT)


func test_two_icons_glow_and_only_chosen_window_is_used() -> void:
	await _setup(["char_lightning_01", "char_fire_01", "char_wind_01"])
	_bus.enemy_stunned.emit(null, _active_c())
	_party.active_controller().perfect_dodged.emit(HitInfo.new())
	assert_bool(_links.is_glowing(_m(1))).is_true()
	assert_bool(_links.is_glowing(_m(2))).is_true()
	_party.request_switch(1)
	assert_str(_party.last_switch_mode).is_equal(LinkTracker.MODE_LINKED)
	assert_float(_links.window_left(_m(1))).is_equal(0.0)
	assert_bool(_links.is_glowing(_m(2))).is_true()


func test_linked_switch_bonus_and_bus_event() -> void:
	await _setup(["char_lightning_01", "char_fire_01", "char_wind_01"])
	var events := []
	_bus.character_switched.connect(func(a: String, b: String, mode: String) -> void: events.append([a, b, mode]))
	var r := _m(1).resources()
	r.en = 0.0
	r.ug = 0.0
	_bus.enemy_stunned.emit(null, _active_c())
	_party.request_switch(1)
	assert_float(r.en).is_equal_approx(10.0, 0.001)
	assert_float(r.ug).is_equal_approx(15.0, 0.001)
	assert_float(_links.si_cd_left(_m(1))).is_equal_approx(10.0, 0.001)
	assert_array(events).is_equal([["char_lightning_01", "char_fire_01", "linked"]])


func test_normal_switch_gives_no_bonus() -> void:
	await _setup(["char_lightning_01", "char_fire_01", "char_wind_01"])
	var r := _m(1).resources()
	r.en = 0.0
	r.ug = 0.0
	_party.request_switch(1)
	assert_float(r.en).is_equal(0.0)
	assert_float(r.ug).is_equal(0.0)


func test_auto_switch_on_down_is_default_mode() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	_active_c().resources.take_damage(1e9)
	_party.tick(1.1)
	assert_str(_party.active().id).is_equal("char_lightning_01")
	assert_str(_party.last_switch_mode).is_equal(LinkTracker.MODE_DEFAULT)
	assert_bool(_links.si_cd_ready(_m(1))).is_true()


# ---------- Từng điều kiện ----------

func test_kael_elemental_status_on_enemy() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	_active_c().statuses.apply("heat", -1.0, -1.0, _active_c())          # tự buff: không tính
	assert_float(_links.window_left(_m(1))).is_equal(0.0)
	_dummy_c().statuses.apply("burn", 4.0, -1.0, _m(2).combatant())       # dự bị gây: không tính
	assert_float(_links.window_left(_m(1))).is_equal(0.0)
	_dummy_c().statuses.apply("burn", 4.0, -1.0, _active_c())
	assert_bool(_links.is_glowing(_m(1))).is_true()


func test_kael_non_elemental_status_ignored() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	_dummy_c().statuses.apply("stun", -1.0, -1.0, _active_c())
	assert_float(_links.window_left(_m(1))).is_equal(0.0)


func test_lyra_perfect_dodge() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	_m(1).controller.perfect_dodged.emit(HitInfo.new())                  # người dự bị: không tính
	assert_float(_links.window_left(_m(2))).is_equal(0.0)
	_party.active_controller().perfect_dodged.emit(HitInfo.new())
	assert_bool(_links.is_glowing(_m(2))).is_true()


func test_seraphine_hp_at_or_below_half() -> void:
	await _setup(["char_fire_01", "char_light_01", "char_wind_01"])
	var r := _active_c().resources
	r.take_damage(r.max_hp * 0.2)
	_party.tick(0.016)                                                    # ghi nhận lần mất HP
	_party.tick(3.5)                                                      # quá 3 s, mới 20%
	r.take_damage(r.max_hp * 0.2)
	_party.tick(0.016)
	assert_float(_links.window_left(_m(1))).is_equal(0.0)                 # 60% HP, 20% trong 3 s
	r.take_damage(r.max_hp * 0.1)
	_party.tick(0.016)
	assert_bool(_links.is_glowing(_m(1))).is_true()                       # 50%


func test_seraphine_lost_quarter_in_3s() -> void:
	await _setup(["char_fire_01", "char_light_01", "char_wind_01"])
	var r := _active_c().resources
	r.take_damage(r.max_hp * 0.13)
	_party.tick(0.016)
	_party.tick(2.0)
	r.take_damage(r.max_hp * 0.13)
	_party.tick(0.016)
	assert_bool(_links.is_glowing(_m(1))).is_true()                       # 26% trong 2 s, HP 74%


func test_seraphine_low_hp_keeps_window_open() -> void:
	await _setup(["char_fire_01", "char_light_01", "char_wind_01"])
	var r := _active_c().resources
	r.take_damage(r.max_hp * 0.6)
	for i in 10:
		_party.tick(1.0)
	assert_bool(_links.is_glowing(_m(1))).is_true()                       # vẫn ≤ 50% sau 10 s


func test_noctis_enemy_defeated() -> void:
	await _setup(["char_fire_01", "char_dark_01", "char_wind_01"])
	_bus.enemy_defeated.emit(null, _active_c())
	assert_bool(_links.is_glowing(_m(1))).is_true()


func test_terra_weapon_or_ultimate() -> void:
	await _setup(["char_fire_01", "char_earth_01", "char_wind_01"])
	var runner := _party.active_controller().runner
	runner.skill_started.emit("skill", runner.skills["skill"])
	assert_float(_links.window_left(_m(1))).is_equal(0.0)
	runner.skill_started.emit("weapon", runner.skills["weapon"])
	assert_bool(_links.is_glowing(_m(1))).is_true()
	_party.tick(6.1)
	runner.skill_started.emit("ultimate", runner.skills["ultimate"])
	assert_bool(_links.is_glowing(_m(1))).is_true()


func test_downed_reserve_gets_no_window() -> void:
	await _setup(["char_lightning_01", "char_fire_01", "char_wind_01"])
	_m(1).resources().take_damage(1e9)
	_bus.enemy_stunned.emit(null, _active_c())
	assert_float(_links.window_left(_m(1))).is_equal(0.0)


# ---------- Thật trong trận ----------

func test_real_burn_hit_lights_kael() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	var p := _party.active_controller()
	p.global_position = Vector2(820, 896)
	p.facing = 1
	p.combatant.statuses.apply("hot_breath", -1.0, -1.0, p.combatant)   # đòn thường kế tiếp áp Cháy
	for i in 30:                                                          # chạm đất trước (không thì ra đòn trên không)
		await get_tree().physics_frame
		if p.is_on_floor():
			break
	p.intent.tap_attack(p.config.jump_buffer_time)
	for i in 60:
		await get_tree().physics_frame
		if _links.window_left(_m(1)) > 0.0:
			break
	assert_bool(_links.is_glowing(_m(1))).is_true()
