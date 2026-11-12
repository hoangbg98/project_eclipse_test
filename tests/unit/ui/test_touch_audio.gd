extends GdUnitTestSuite
## Test M7-3: nút kỹ năng cảm ứng (vòng hồi chiêu, số giây, vòng UG, mờ khi chưa dùng được, lượt né)
## và âm thanh theo sự kiện (bảng data/config/audio_events.json).

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")

var _stage: Node2D
var _p: PlayerController
var _bus: Node


func after_test() -> void:
	Engine.time_scale = 1.0


func _setup(ids: Array = ["char_fire_01", "char_lightning_01", "char_wind_01"]) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.spawn_enemies = false
	_stage.party_ids = PackedStringArray(ids)
	add_child(_stage)
	_stage.party.use_player_input = false
	_p = _stage.player
	_p.use_player_input = false
	_bus = get_tree().root.get_node("EventBus")
	await get_tree().physics_frame


func _state(action: StringName) -> Dictionary:
	return TouchControls.button_state(action, _stage.party.active_controller())


# ---------- Nút kỹ năng ----------

func test_skill_button_ready_then_cooldown_then_ready() -> void:
	await _setup()
	_p.combatant.resources.add_en(100.0)
	var s := _state(&"skill")
	assert_float(s["cooldown_ratio"]).is_equal(0.0)
	assert_bool(s["dimmed"]).is_false()
	assert_str(s["overlay_text"]).is_equal("")
	_p.combatant.cooldowns.trigger(&"skill")                          # CD 6 s
	s = _state(&"skill")
	assert_float(s["cooldown_ratio"]).is_equal_approx(1.0, 0.001)
	assert_str(s["overlay_text"]).is_equal("6")
	_p.combatant.tick(4.5)
	s = _state(&"skill")
	assert_float(s["cooldown_ratio"]).is_equal_approx(0.25, 0.01)     # còn 1.5 / 6
	assert_str(s["overlay_text"]).is_equal("2")                       # làm tròn lên
	_p.combatant.tick(2.0)
	assert_float(_state(&"skill")["cooldown_ratio"]).is_equal(0.0)


func test_skill_button_dims_without_energy() -> void:
	await _setup()
	_p.combatant.resources.en = 0.0
	assert_bool(_state(&"skill")["dimmed"]).is_true()                 # cần 25 EN
	assert_bool(_state(&"weapon")["dimmed"]).is_true()                # cần 35 EN
	_p.combatant.resources.en = 30.0
	assert_bool(_state(&"skill")["dimmed"]).is_false()
	assert_bool(_state(&"weapon")["dimmed"]).is_true()


func test_ultimate_button_shows_charge_ring() -> void:
	await _setup()
	_p.combatant.resources.ug = 40.0
	var s := _state(&"ultimate")
	assert_float(s["charge_ratio"]).is_equal_approx(0.4, 0.001)
	assert_bool(s["dimmed"]).is_true()
	_p.combatant.resources.add_ug(100.0)
	s = _state(&"ultimate")
	assert_float(s["charge_ratio"]).is_equal(1.0)
	assert_bool(s["dimmed"]).is_false()


func test_dodge_button_shows_charges() -> void:
	await _setup()
	assert_str(_state(&"dodge")["overlay_text"]).is_equal("2")
	_p.combatant.resources.try_dodge()
	_p.combatant.resources.try_dodge()
	var s := _state(&"dodge")
	assert_str(s["overlay_text"]).is_equal("0")
	assert_bool(s["dimmed"]).is_true()


func test_buttons_follow_active_character() -> void:
	await _setup()
	_stage.party.request_switch(1)                                    # Kael: chưa có kỹ năng / vũ khí / tuyệt kỹ (ngoài slice)
	for a: StringName in [&"skill", &"weapon", &"ultimate"]:
		assert_bool(_state(a)["dimmed"]).is_true()
	assert_bool(_state(&"dodge")["dimmed"]).is_false()                # Kael có né


func test_touch_controls_update_real_buttons() -> void:
	await _setup()
	var touch := _stage.get_node("TouchControls") as TouchControls
	assert_object(touch.party).is_same(_stage.party)
	touch.visible = true
	_p.combatant.resources.add_en(100.0)
	_p.combatant.cooldowns.trigger(&"weapon")
	touch._process(0.016)
	var b := touch.buttons[&"weapon"] as TouchButton
	assert_float(b.cooldown_ratio).is_equal_approx(1.0, 0.001)
	assert_str(b.overlay_text).is_equal("12")
	assert_str((touch.buttons[&"dodge"] as TouchButton).overlay_text).is_equal("2")
	assert_bool(TouchControls.button_state(&"skill", null).is_empty()).is_false()   # không có nhân vật: trạng thái mặc định


# ---------- Âm thanh theo sự kiện ----------

func test_audio_event_table_is_loaded() -> void:
	for e in ["hit", "hit_crit", "player_hurt", "enemy_down", "switch", "switch_linked", "link_ready", "reaction",
			"ultimate", "stage_clear", "stage_fail"]:
		assert_str(str(AudioRouter.events["sfx"].get(e, ""))).override_failure_message(e).is_not_equal("")
	for m in ["title", "hub", "stage", "boss"]:
		assert_str(str(AudioRouter.events["music"].get(m, ""))).is_not_equal("")


func test_game_events_request_their_sounds() -> void:
	await _setup()
	AudioRouter.requested.clear()
	AudioRouter._last_played_ms.clear()
	_bus.link_window_opened.emit("char_fire_01", 6.0)                 # vòng sáng bật: có âm thanh ngắn (README 17.5)
	_bus.character_switched.emit("a", "b", "linked")
	_bus.character_switched.emit("a", "b", "normal")
	_bus.enemy_defeated.emit(null, null)
	_bus.ultimate_started.emit(null, null)
	assert_array(AudioRouter.requested).is_equal(["sfx_link_ready", "sfx_switch_linked", "sfx_switch",
			"sfx_enemy_down", "sfx_ultimate"])
	assert_bool(AudioRouter.play_event("no_such_event")).is_false()   # sự kiện chưa gán: bỏ qua


func test_hit_sounds_by_target_and_crit_with_rate_limit() -> void:
	await _setup()
	AudioRouter.requested.clear()
	AudioRouter._last_played_ms.clear()
	var normal := DamageCalculator.Result.new()
	var crit := DamageCalculator.Result.new()
	crit.is_crit = true
	var dummy_c: Combatant = _stage.dummies[0].combatant
	_bus.hit_landed.emit(_p.combatant, dummy_c, normal, HitInfo.new())
	_bus.hit_landed.emit(_p.combatant, dummy_c, normal, HitInfo.new())   # cùng lúc: không phát chồng
	_bus.hit_landed.emit(_p.combatant, dummy_c, crit, HitInfo.new())
	_bus.hit_landed.emit(dummy_c, _p.combatant, normal, HitInfo.new())
	assert_array(AudioRouter.requested).is_equal(["sfx_hit", "sfx_hit_crit", "sfx_player_hurt"])


func test_scene_change_requests_music() -> void:
	AudioRouter.requested.clear()
	_bus.scene_changed.emit("res://scenes/main/hub.tscn")
	_bus.scene_changed.emit("res://scenes/stages/stage.tscn")
	_bus.scene_changed.emit("res://scenes/unknown/thing.tscn")        # scene lạ: giữ nhạc đang phát
	assert_array(AudioRouter.requested).is_equal(["music_menu", "music_stage"])
