extends GdUnitTestSuite
## Test M4-1 / M4-2: đội 3 người, 1 người trên sân, chờ chung 1.0 s, khóa chuyển,
## dự bị vẫn chạy (EN +1/s, UG 30%, hồi chiêu, trạng thái), tự đổi khi người trên sân gục.

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy_slime.tscn")

var _stage: Node2D
var _party: PartyManager
var _rules: CombatRules


func _setup() -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.spawn_enemies = false
	add_child(_stage)
	_party = _stage.party
	_party.use_player_input = false
	for m in _party.members:
		m.controller.use_player_input = false
	_rules = _party.rules
	_stage.player.global_position = Vector2(820, 896)
	await _frames(5)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _m(i: int) -> CharacterRuntime:
	return _party.members[i]


# ---------- Dữ liệu ----------

func test_rules_from_spec() -> void:
	var r: CombatRules = load("res://data/config/combat_rules.tres")
	assert_float(r.switch_cooldown_sec).is_equal(1.0)           # 8.2
	assert_float(r.reserve_en_regen_per_sec).is_equal(1.0)      # 8.1
	assert_float(r.reserve_ug_share).is_equal(0.30)             # 8.1
	assert_float(r.switch_input_buffer_sec).is_equal(0.15)      # 8.11
	assert_bool(r.validate().is_empty()).is_true()


func test_chain_ultimate_locks_switch() -> void:
	var u: SkillDef = load("res://data/skills/char_fire_01/ultimate.tres")
	assert_bool(u.locks_switch).is_true()


# ---------- Một người trên sân ----------

func test_only_active_member_is_on_field() -> void:
	await _setup()
	assert_int(_party.members.size()).is_equal(3)
	assert_str(_party.active().id).is_equal("char_fire_01")
	assert_bool(_m(0).is_on_field()).is_true()
	assert_bool(_m(1).is_on_field()).is_false()
	assert_bool(_m(2).is_on_field()).is_false()
	assert_object(_stage.player).is_same(_m(0).controller)
	assert_int(get_tree().get_nodes_in_group(EnemyController.PLAYER_GROUP).size()).is_equal(1)
	assert_bool(_m(0).resources().on_field).is_true()
	assert_bool(_m(1).resources().on_field).is_false()
	# Icon dự bị theo thứ tự trong đội.
	var r := _party.reserves()
	assert_str(r[0].id).is_equal("char_lightning_01")
	assert_str(r[1].id).is_equal("char_wind_01")


func test_switch_keeps_position_and_facing() -> void:
	await _setup()
	var old := _stage.player as PlayerController
	old.facing = -1
	var pos := old.global_position
	var got := []
	_party.switched.connect(func(a: CharacterRuntime, b: CharacterRuntime) -> void: got.append([a.id, b.id]))
	assert_bool(_party.request_switch_slot(0)).is_true()
	assert_str(_party.active().id).is_equal("char_lightning_01")
	assert_array(got).is_equal([["char_fire_01", "char_lightning_01"]])
	var now := _stage.player as PlayerController
	assert_object(now).is_same(_m(1).controller)
	assert_bool(now.is_inside_tree()).is_true()
	assert_bool(old.is_inside_tree()).is_false()
	assert_vector(now.global_position).is_equal(pos)
	assert_int(now.facing).is_equal(-1)
	assert_object(_stage.camera.target).is_same(now)
	assert_object(_stage.feedback.player).is_same(now)
	# Icon: Aether về ô 1, Lyra vẫn ô 2.
	assert_str(_party.reserves()[0].id).is_equal("char_fire_01")
	await _frames(3)
	assert_bool(now.is_on_floor() or now.velocity.y >= 0.0).is_true()


func test_shared_switch_cooldown() -> void:
	await _setup()
	assert_bool(_party.request_switch_slot(0)).is_true()
	assert_str(_party.check_switch(2)).is_equal(PartyManager.REASON_COOLDOWN)
	assert_bool(_party.request_switch(2)).is_false()
	_party.tick(0.95)
	assert_str(_party.check_switch(2)).is_equal(PartyManager.REASON_COOLDOWN)
	_party.tick(0.06)
	assert_str(_party.check_switch(2)).is_equal("")
	assert_bool(_party.request_switch(2)).is_true()
	assert_str(_party.active().id).is_equal("char_wind_01")


func test_cannot_switch_to_self_or_invalid() -> void:
	await _setup()
	assert_str(_party.check_switch(0)).is_equal(PartyManager.REASON_ACTIVE)
	assert_str(_party.check_switch(5)).is_equal(PartyManager.REASON_INVALID)
	assert_bool(_party.request_switch_slot(3)).is_false()


func test_buffered_switch_press_retries() -> void:
	await _setup()
	_party.request_switch_slot(0)
	_party.tick(0.9)                       # còn chờ 0.1 s
	_party.press_switch(0)                 # bấm sớm: giữ lệnh 0.15 s
	assert_str(_party.active().id).is_equal("char_lightning_01")
	_party.tick(0.12)
	assert_str(_party.active().id).is_equal("char_fire_01")


func test_buffered_switch_press_expires() -> void:
	await _setup()
	_party.request_switch_slot(0)
	var rejected := []
	_party.switch_rejected.connect(func(_i: int, reason: String) -> void: rejected.append(reason))
	_party.tick(0.5)
	_party.press_switch(0)
	_party.tick(0.2)                       # quá 0.15 s mà vẫn còn chờ
	assert_str(_party.active().id).is_equal("char_lightning_01")
	assert_array(rejected).is_equal([PartyManager.REASON_COOLDOWN])


func test_cannot_switch_during_chain_ultimate() -> void:
	await _setup()
	var p := _stage.player as PlayerController
	p.combatant.resources.add_ug(100.0)
	p.intent.press(PlayerIntent.ULTIMATE, p.config.jump_buffer_time)
	for i in 10:
		await get_tree().physics_frame
		if p.runner.is_running():
			break
	assert_str(p.runner.current_key).is_equal("ultimate")
	assert_str(_party.check_switch(1)).is_equal(PartyManager.REASON_LOCKED)
	for i in 400:
		await get_tree().physics_frame
		if not p.runner.is_running():
			break
	assert_str(_party.check_switch(1)).is_equal("")


func test_cannot_switch_to_downed_member() -> void:
	await _setup()
	_m(1).resources().take_damage(1e9)
	assert_bool(_m(1).is_down()).is_true()
	assert_str(_party.check_switch(1)).is_equal(PartyManager.REASON_DOWN)
	assert_str(_party.check_switch(2)).is_equal("")


# ---------- Dự bị vẫn chạy (M4-2) ----------

func test_reserve_en_regen_is_one_per_sec() -> void:
	await _setup()
	var act := _m(0).resources()
	var res := _m(1).resources()
	act.en = 0.0
	res.en = 0.0
	_party.tick(1.0)                       # dự bị
	_m(0).combatant().tick(1.0)            # trên sân
	assert_float(res.en).is_equal_approx(1.0, 0.001)
	assert_float(act.en).is_equal_approx(2.0, 0.001)


func test_switching_swaps_en_rate() -> void:
	await _setup()
	_party.request_switch_slot(0)
	assert_bool(_m(0).resources().on_field).is_false()
	assert_bool(_m(1).resources().on_field).is_true()


func test_reserves_get_30_percent_ug() -> void:
	await _setup()
	_m(1).resources().ug = 0.0
	_m(2).resources().ug = 0.0
	_m(0).resources().add_ug(10.0)
	assert_float(_m(1).resources().ug).is_equal_approx(3.0, 0.001)
	assert_float(_m(2).resources().ug).is_equal_approx(3.0, 0.001)
	# Phần UG dự bị nhận không chia ngược lại.
	assert_float(_m(0).resources().ug).is_equal_approx(10.0, 0.001)


func test_ug_share_uses_active_multiplier_only() -> void:
	await _setup()
	_m(0).resources().ug_gain_multiplier = 1.2   # Aether ≥ 3 Nhiệt
	_m(1).resources().ug_gain_multiplier = 2.0   # không được nhân lần nữa
	_m(1).resources().ug = 0.0
	_m(0).resources().register_hit(ResourceComponent.HitKind.SKILL)  # +10 × 1.2
	assert_float(_m(1).resources().ug).is_equal_approx(12.0 * 0.3, 0.001)


func test_downed_reserve_gets_no_ug() -> void:
	await _setup()
	_m(1).resources().take_damage(1e9)
	var before := _m(1).resources().ug
	_m(0).resources().add_ug(20.0)
	assert_float(_m(1).resources().ug).is_equal(before)


func test_reserve_timers_keep_running() -> void:
	await _setup()
	var aether := _m(0)
	var cds := aether.combatant().cooldowns
	assert_bool(cds.trigger(&"skill")).is_true()
	var cd_left := cds.remaining(&"skill")
	aether.combatant().statuses.apply("heat", -1.0, -1.0, aether.combatant())
	var heat_left := aether.combatant().statuses.remaining("heat")
	_party.request_switch_slot(0)
	_party.tick(2.0)
	assert_float(cd_left).is_greater(2.0)
	assert_float(cds.remaining(&"skill")).is_equal_approx(cd_left - 2.0, 0.01)
	assert_float(aether.combatant().statuses.remaining("heat")).is_equal_approx(heat_left - 2.0, 0.01)


# ---------- Gục ----------

func test_active_down_auto_switches_to_next_alive() -> void:
	await _setup()
	_m(1).resources().take_damage(1e9)     # Kael đã gục → bỏ qua
	_m(0).resources().take_damage(1e9)
	assert_str(_party.active().id).is_equal("char_fire_01")
	_party.tick(_rules.down_auto_switch_sec * 0.5)
	assert_str(_party.active().id).is_equal("char_fire_01")
	_party.tick(_rules.down_auto_switch_sec * 0.6)
	assert_str(_party.active().id).is_equal("char_wind_01")
	assert_object(_stage.player).is_same(_m(2).controller)


func test_all_down_emits_party_defeated() -> void:
	await _setup()
	var defeated := [false]
	_party.party_defeated.connect(func() -> void: defeated[0] = true)
	_m(1).resources().take_damage(1e9)
	_m(2).resources().take_damage(1e9)
	assert_bool(defeated[0]).is_false()
	_m(0).resources().take_damage(1e9)
	assert_bool(defeated[0]).is_true()
	assert_bool(_party.is_defeated()).is_true()


func test_enemy_retargets_after_switch() -> void:
	await _setup()
	var enemy: EnemyController = ENEMY_SCENE.instantiate()
	enemy.position = Vector2(1100, 896)
	_stage.add_child(enemy)
	await _frames(3)
	assert_object(enemy.target).is_same(_m(0).controller)
	_party.request_switch_slot(0)
	await _frames(2)
	assert_object(enemy.target).is_same(_m(1).controller)


func test_reserve_nodes_freed_with_stage() -> void:
	var stage: Node2D = STAGE_SCENE.instantiate()
	stage.spawn_enemies = false
	add_child(stage)
	var reserves := []
	for m in stage.party.reserves():
		reserves.append(weakref(m.controller))
	stage.free()
	for w: WeakRef in reserves:
		assert_object(w.get_ref()).is_null()
