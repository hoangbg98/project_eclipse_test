extends GdUnitTestSuite
## Test M4-5: 15 phản ứng nguyên tố + ReactionResolver (CHARACTER_SKILLS 8.4).

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy_slime.tscn")
const ELEMENTS := ["fire", "wind", "lightning", "light", "dark", "earth"]

## Tổng % ATK theo bảng 8.4 (gồm vùng kéo dài: Nhật Thiêu 160 + 6×20, Dung Nham 140 + 6×24).
const TOTALS := {
	"fire_wind": 1.80, "fire_lightning": 2.20, "fire_light": 2.80, "fire_dark": 1.50, "fire_earth": 2.84,
	"wind_lightning": 2.80, "wind_light": 1.00, "wind_dark": 1.20, "wind_earth": 1.20,
	"lightning_light": 2.60, "lightning_dark": 1.70, "lightning_earth": 2.00,
	"light_dark": 2.00, "light_earth": 1.20, "dark_earth": 1.80,
}

var _stage: Node2D
var _party: PartyManager
var _res: ReactionResolver
var _bus: Node


func after_test() -> void:
	Engine.time_scale = 1.0


func _setup(ids: Array, x := 820.0) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.spawn_enemies = false
	_stage.party_ids = PackedStringArray(ids)
	add_child(_stage)
	_party = _stage.party
	_party.use_player_input = false
	for m in _party.members:
		m.controller.use_player_input = false
		m.combatant().rng = RandomSource.Fixed.new(0.99)
	_res = _party.reactions
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


func _def(key: String) -> ReactionDef:
	return load("res://data/reactions/%s.tres" % key)


## Ghi sát thương từ phản ứng lên một Combatant.
func _watch(c: Combatant, into: Array) -> void:
	c.damaged.connect(func(r: DamageCalculator.Result, h: HitInfo) -> void:
		if h.skill_id.begins_with("reaction."):
			into.append(r.amount))


func _fire(key: String, by: PlayerController, center: Vector2) -> bool:
	return _res.trigger(_def(key), by, center, _party.members)


# ---------- Dữ liệu: đủ 15 cặp, không thiếu, không trùng ----------

func test_all_15_pairs_exist_once_and_valid() -> void:
	var r := ReactionResolver.new(load("res://data/config/combat_rules.tres"))
	assert_array(r.load_dir()).is_empty()
	assert_int(r.reactions.size()).is_equal(15)
	var seen := {}
	for i in ELEMENTS.size():
		for j in range(i + 1, ELEMENTS.size()):
			var d := r.find(ELEMENTS[i], ELEMENTS[j])
			assert_object(d).override_failure_message("thiếu %s + %s" % [ELEMENTS[i], ELEMENTS[j]]).is_not_null()
			assert_object(r.find(ELEMENTS[j], ELEMENTS[i])).is_same(d)          # đối xứng
			assert_bool(seen.has(d.id)).is_false()
			seen[d.id] = true
			assert_str(tr(d.name_key)).is_not_equal(d.name_key)                 # có bản dịch
	assert_int(seen.size()).is_equal(15)
	assert_object(r.find("fire", "fire")).is_null()


func test_totals_match_spec_table() -> void:
	for key: String in TOTALS:
		assert_float(_def(key).total_atk_ratio()).override_failure_message(key).is_equal_approx(TOTALS[key], 0.0001)


func test_rules_from_spec() -> void:
	var rules: CombatRules = load("res://data/config/combat_rules.tres")
	assert_float(rules.reaction_icd_sec).is_equal(5.0)
	assert_float(rules.reaction_boss_control_multiplier).is_equal(0.5)
	var c: HitFeedbackConfig = load("res://data/config/hit_feedback.tres")
	assert_array([c.reaction_hitstop_ms, c.reaction_name_sec, c.reaction_orb_sec]).is_equal([60.0, 0.8, 0.3])


func test_pair_key_is_canonical() -> void:
	assert_str(ReactionDef.pair_key("wind", "fire")).is_equal("fire_wind")
	assert_str(ReactionDef.pair_key("earth", "dark")).is_equal("dark_earth")
	assert_str(ReactionDef.pair_key("fire", "ice")).is_equal("")


# ---------- ICD ----------

func test_shared_icd_5s() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	var p := _party.active_controller()
	assert_bool(_fire("fire_wind", p, _dummy(0).global_position)).is_true()
	assert_bool(_fire("fire_lightning", p, _dummy(0).global_position)).is_false()   # phản ứng khác cũng bị chặn
	_party.tick(4.9)
	assert_bool(_res.can_trigger()).is_false()
	_party.tick(0.2)
	assert_bool(_fire("fire_lightning", p, _dummy(0).global_position)).is_true()


# ---------- Kích hoạt qua chuyển nhân vật ----------

func test_linked_switch_in_hit_triggers_reaction_at_first_enemy() -> void:
	await _setup(["char_lightning_01", "char_fire_01", "char_wind_01"], 640.0)
	var events := []
	_bus.reaction_triggered.connect(func(d: Resource, c: Vector2, by: Node) -> void: events.append([d.id, c, by]))
	var dmg := []
	_watch(_dummy(0).combatant, dmg)
	_bus.enemy_stunned.emit(_dummy(0), _party.active().combatant())     # mở Liên kết Aether
	_party.request_switch(1)
	assert_array(events).is_empty()                                     # chưa trúng: chưa nổ
	for i in 60:
		await get_tree().process_frame
		if not events.is_empty():
			break
	assert_int(events.size()).is_equal(1)
	assert_str(events[0][0]).is_equal("reaction.fire_lightning")        # Lôi (rời) + Hỏa (vào) = Quá Tải
	assert_object(events[0][2]).is_same(_m(1).controller)
	assert_str(_stage.feedback.last_reaction_id).is_equal("reaction.fire_lightning")
	await _frames(20)
	assert_int(dmg.size()).is_greater_equal(1)
	assert_bool(_res.can_trigger()).is_false()                          # ICD đã tính
	var shown := false
	for n in _stage.get_children():
		if n is ReactionFx:
			shown = n.text() == tr("REACTION_FIRE_LIGHTNING")
	assert_bool(shown).is_true()


func test_normal_switch_has_no_reaction() -> void:
	await _setup(["char_lightning_01", "char_fire_01", "char_wind_01"], 640.0)
	var events := [0]
	_bus.reaction_triggered.connect(func(_d: Resource, _c: Vector2, _b: Node) -> void: events[0] += 1)
	_party.request_switch(1)                                            # Thường
	await _frames(50)
	assert_int(events[0]).is_equal(0)
	assert_bool(_res.can_trigger()).is_true()


func test_linked_switch_in_that_misses_has_no_reaction_and_no_icd() -> void:
	await _setup(["char_lightning_01", "char_fire_01", "char_wind_01"], 3000.0)   # xa mọi kẻ địch
	var events := [0]
	_bus.reaction_triggered.connect(func(_d: Resource, _c: Vector2, _b: Node) -> void: events[0] += 1)
	_bus.enemy_stunned.emit(null, _party.active().combatant())
	_party.request_switch(1)
	assert_str(_party.last_switch_mode).is_equal("linked")
	await _frames(60)
	assert_int(events[0]).is_equal(0)
	assert_bool(_res.can_trigger()).is_true()


func test_reaction_blocked_by_icd_on_second_linked_switch() -> void:
	await _setup(["char_lightning_01", "char_fire_01", "char_wind_01"], 640.0)
	_fire("wind_earth", _party.active_controller(), Vector2(5000, 896))   # phản ứng khác vừa nổ ở xa
	var events := [0]
	_bus.reaction_triggered.connect(func(_d: Resource, _c: Vector2, _b: Node) -> void: events[0] += 1)
	_bus.enemy_stunned.emit(null, _party.active().combatant())
	_party.request_switch(1)
	await _frames(50)
	assert_int(events[0]).is_equal(0)


func test_self_reaction_fires_immediately_without_enemy() -> void:
	await _setup(["char_light_01", "char_wind_01", "char_fire_01"], 3000.0)
	var events := []
	_bus.reaction_triggered.connect(func(d: Resource, _c: Vector2, _b: Node) -> void: events.append(d.id))
	for m in _party.members:
		m.resources().take_damage(m.resources().max_hp * 0.5)
	_party.active().combatant().statuses.apply("curse", 5.0, -1.0, null)
	# Mở Liên kết Lyra (báo thẳng điều kiện: né hoàn hảo thật của Hikarine còn hồi 3% HP cả đội, làm lệch phép đo).
	_party.links.notify(LinkTracker.COND_PERFECT_DODGE)
	_party.request_switch(1)
	assert_array(events).is_equal(["reaction.wind_light"])             # Thanh Phong
	for m in _party.members:                                           # hồi cả đội 8% HP tối đa, kể cả dự bị
		assert_float(m.resources().hp_ratio()).is_equal_approx(0.58, 0.001)
	assert_bool(_m(0).combatant().statuses.has("curse")).is_false()    # xóa 1 hiệu ứng xấu
	assert_bool(_m(1).combatant().statuses.has("wind_step")).is_true()


# ---------- Từng hiệu ứng ----------

func test_damage_uses_incoming_characters_atk() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	var dmg := []
	_watch(_dummy(0).combatant, dmg)
	_fire("lightning_earth", _m(0).controller, _dummy(0).global_position)    # Aether ATK 1000
	await _frames(12)
	_party.tick(5.1)
	_party.request_switch(1)
	await _frames(40)
	dmg.clear()
	_fire("lightning_earth", _m(1).controller, _dummy(0).global_position)    # Kael ATK 950
	await _frames(12)
	assert_int(dmg.size()).is_equal(1)
	var kael: int = dmg[0]
	_party.tick(5.1)
	dmg.clear()
	_m(0).controller.global_position = _m(1).controller.global_position
	_party.request_switch(0)
	await _frames(40)
	dmg.clear()
	_party.tick(5.1)
	_fire("lightning_earth", _m(0).controller, _dummy(0).global_position)
	await _frames(12)
	assert_float(float(dmg[0]) / float(kael)).is_equal_approx(1000.0 / 950.0, 0.01)


func test_firestorm_burns_everyone_in_radius() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	_fire("fire_wind", _party.active_controller(), _dummy(0).global_position)
	await _frames(8)
	for i in 2:                                                         # 928 và 1056: cả hai trong 260 px
		assert_float(_dummy(i).combatant.statuses.remaining("burn")).is_between(4.5, 5.0)


func test_soulburn_double_tick_and_curse() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	var ratios := []
	_dummy(0).combatant.statuses.tick_damage.connect(func(id: String, r: float, _s: Object) -> void:
		if id == "burn":
			ratios.append(r))
	_fire("fire_dark", _party.active_controller(), _dummy(0).global_position)
	await _frames(45)
	assert_bool(ratios.size() >= 1).is_true()
	assert_float(ratios[0]).is_equal_approx(0.16, 0.0001)               # 8% × 2
	assert_bool(_dummy(0).combatant.statuses.has("curse")).is_true()


func test_zone_reactions_keep_ticking() -> void:
	await _setup(["char_fire_01", "char_lightning_01", "char_wind_01"])
	var dmg := []
	_watch(_dummy(0).combatant, dmg)
	_fire("fire_earth", _party.active_controller(), _dummy(0).global_position)
	await _frames(30)
	assert_float(_dummy(0).combatant.statuses.move_slow()).is_equal(0.30)   # Chậm 30% trong vùng
	await _frames(170)                                                  # > 3.1 s
	assert_int(dmg.size()).is_equal(7)                                  # 1 nổ + 6 nhịp dung nham
	await _frames(60)
	assert_float(_dummy(0).combatant.statuses.move_slow()).is_equal(0.0)    # ra khỏi vùng (hết vùng) thì hết Chậm


func test_thunderstorm_four_scattered_strikes() -> void:
	await _setup(["char_wind_01", "char_lightning_01", "char_fire_01"])
	var xs := []
	_stage.child_entered_tree.connect(func(n: Node) -> void:
		if n is DetachedHit:
			xs.append(n))
	var center := _dummy(0).global_position
	_fire("wind_lightning", _party.active_controller(), center)
	assert_int(xs.size()).is_equal(4)
	for d: DetachedHit in xs:
		assert_float(absf(d.global_position.x - center.x)).is_less_equal(400.0)
	assert_array([xs[0].delay, xs[1].delay, xs[2].delay, xs[3].delay]).is_equal([0.0, 0.3, 0.6, 0.9])


func test_divine_smite_hits_only_highest_hp_target() -> void:
	await _setup(["char_lightning_01", "char_light_01", "char_wind_01"])
	_dummy(0).combatant.resources.hp = 1000.0                           # hình nộm 2 nhiều máu hơn
	var d0 := []
	var d1 := []
	_watch(_dummy(0).combatant, d0)
	_watch(_dummy(1).combatant, d1)
	_fire("lightning_light", _party.active_controller(), _dummy(0).global_position)
	assert_int(d0.size()).is_equal(0)
	assert_int(d1.size()).is_equal(1)
	assert_float(_dummy(1).combatant.statuses.remaining("judgment")).is_equal_approx(6.0, 0.01)


func test_holy_aegis_shield_absorbs_then_breaks() -> void:
	await _setup(["char_light_01", "char_earth_01", "char_wind_01"], 3000.0)
	var p := _party.active_controller()
	_fire("light_earth", p, p.global_position)
	var r := p.combatant.resources
	assert_float(r.shield).is_equal_approx(r.max_hp * 0.12, 0.01)       # Khiên 12% HP tối đa
	assert_float(p.combatant.statuses.remaining("shield")).is_equal_approx(6.0, 0.01)
	assert_float(p.combatant.statuses.modifiers(StatusDef.MAGNITUDE_DAMAGE_TAKEN_DOWN).get("earth_guard", 0.0)).is_equal(0.20)
	r.take_damage(r.max_hp * 0.05)
	assert_float(r.hp).is_equal(r.max_hp)                               # khiên hấp thụ hết
	r.take_damage(r.max_hp * 0.10)                                      # còn 7% khiên: vỡ, 3% vào máu
	assert_float(r.hp_ratio()).is_equal_approx(0.97, 0.001)
	assert_float(r.shield).is_equal(0.0)
	assert_bool(p.combatant.statuses.has("shield")).is_false()


func test_shield_expires_with_status() -> void:
	await _setup(["char_light_01", "char_earth_01", "char_wind_01"], 3000.0)
	var p := _party.active_controller()
	_fire("light_earth", p, p.global_position)
	p.combatant.tick(6.1)
	assert_float(p.combatant.resources.shield).is_equal(0.0)


func test_wailing_vortex_pulls_enemy_toward_center_not_past() -> void:
	await _setup(["char_wind_01", "char_dark_01", "char_fire_01"], 3000.0)
	var enemy: EnemyController = ENEMY_SCENE.instantiate()
	enemy.position = Vector2(760, 896)
	_stage.add_child(enemy)
	var near: EnemyController = ENEMY_SCENE.instantiate()
	near.position = Vector2(590, 896)
	_stage.add_child(near)
	await _frames(5)
	var center := Vector2(560, 896)
	var before := enemy.global_position.x - center.x
	var near_before := near.global_position.x - center.x
	_fire("wind_dark", _party.active_controller(), center)
	await _frames(18)                                                   # nhịp đầu: kéo 120 px trong 0.15 s (có hit-stop)
	var after := enemy.global_position.x - center.x
	assert_float(before - after).is_between(100.0, 175.0)               # bị kéo vào 120 px (+ 20 px khựng, + tuần tra)
	# Kẻ địch cách tâm < 120 px: chỉ kéo tới tâm, không vượt qua.
	assert_float(near.global_position.x - center.x).is_between(-15.0, near_before)   # sai số một khung
	assert_bool(enemy.combatant.statuses.has("curse")).is_true()


func test_boss_control_is_halved() -> void:
	await _setup(["char_lightning_01", "char_dark_01", "char_fire_01"], 3000.0)
	var boss: EnemyController = ENEMY_SCENE.instantiate()
	boss.get_node("Combatant").is_boss = true
	boss.position = Vector2(1500, 896)
	_stage.add_child(boss)
	var normal: EnemyController = ENEMY_SCENE.instantiate()
	normal.position = Vector2(1560, 896)
	_stage.add_child(normal)
	await _frames(5)
	_fire("lightning_dark", _party.active_controller(), Vector2(1530, 896))   # Chậm 40% 3 s, Nguyền 6 s
	await _frames(6)
	assert_float(normal.combatant.statuses.remaining("slow")).is_between(2.8, 3.0)
	assert_float(boss.combatant.statuses.remaining("slow")).is_between(1.3, 1.5)     # × 0.5
	assert_float(boss.combatant.statuses.remaining("curse")).is_between(5.8, 6.0)    # không phải khống chế
	_party.tick(5.1)
	_fire("dark_earth", _party.active_controller(), Vector2(1530, 896))       # Trói 2.0 s (boss 0.8 s)
	await _frames(6)
	assert_float(normal.combatant.statuses.remaining("root")).is_between(1.8, 2.0)
	assert_float(boss.combatant.statuses.remaining("root")).is_between(0.65, 0.8)


func test_overload_sc_x2_and_magnetic_quake_x2_5() -> void:
	assert_float(_def("fire_lightning").hits[0].sc_multiplier).is_equal(2.0)
	assert_float(_def("fire_lightning").hits[0].knockback_px).is_equal(200.0)
	assert_float(_def("lightning_earth").hits[0].sc_multiplier).is_equal(2.5)
	assert_float(_def("lightning_light").hits[0].sc_multiplier).is_equal(1.5)
