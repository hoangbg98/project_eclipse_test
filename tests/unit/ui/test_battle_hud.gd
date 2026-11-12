extends GdUnitTestSuite
## Test M4-7: HUD icon dự bị — HP, vòng SI-CD, vòng sáng Liên kết (README 15.5, 17.5).

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")

var _stage: Node2D
var _party: PartyManager
var _hud: BattleHud
var _bus: Node


func _setup(ids: Array = ["char_lightning_01", "char_fire_01", "char_wind_01"]) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.spawn_enemies = false
	_stage.party_ids = PackedStringArray(ids)
	add_child(_stage)
	_party = _stage.party
	_party.use_player_input = false
	for m in _party.members:
		m.controller.use_player_input = false
	_hud = _stage.hud
	for icon in _hud.icons:
		icon.set_process(false)          # test tự bước bằng advance()
		icon.advance(0.0)
	_bus = get_tree().root.get_node("EventBus")
	_stage.player.global_position = Vector2(3000, 896)   # xa mọi kẻ địch
	await get_tree().physics_frame


func _icon(i: int) -> ReserveIcon:
	return _hud.icons[i]


# ---------- Bố cục ----------

func test_theme_matches_spec() -> void:
	assert_float(HudTheme.RESERVE_ICON_SIZE).is_greater_equal(140.0)          # vùng chạm ≥ 140 px
	assert_array([HudTheme.RING_FADE_IN_SEC, HudTheme.RING_FADE_OUT_SEC, HudTheme.RING_PULSE_SEC,
			HudTheme.RING_SCALE_MAX, HudTheme.RING_BRIGHT_MIN, HudTheme.RING_BRIGHT_MAX,
			HudTheme.RING_BURST_SEC]).is_equal([0.15, 0.3, 0.8, 1.12, 0.6, 1.0, 0.2])
	var tokens := {"fire": "#FF6A3D", "wind": "#3DDBB5", "lightning": "#FFD93D", "light": "#FFF2B8",
			"dark": "#A855F7", "earth": "#D99A3E"}
	for e: String in tokens:
		assert_bool(HudTheme.ring_color(e).is_equal_approx(Color(tokens[e]))).is_true()


func test_two_icons_top_right_no_overlap_and_touch_buttons_hidden() -> void:
	await _setup()
	assert_int(_hud.icons.size()).is_equal(2)
	await get_tree().process_frame
	var a := _icon(0).get_global_rect()
	var b := _icon(1).get_global_rect()
	assert_bool(a.intersects(b)).is_false()
	for r: Rect2 in [a, b]:
		assert_float(minf(r.size.x, r.size.y)).is_greater_equal(140.0)
		assert_float(r.position.y).is_less(300.0)                               # hàng trên cùng
	assert_float(a.position.x).is_less(b.position.x)                             # icon 1 bên trái icon 2
	assert_float(b.end.x).is_greater(_icon(1).get_viewport_rect().size.x - 300.0)   # sát mép phải
	var touch := _stage.get_node("TouchControls") as TouchControls
	assert_bool(touch.buttons[&"switch_1"].visible).is_false()
	assert_bool(touch.buttons[&"switch_2"].visible).is_false()


func test_icons_follow_reserve_order() -> void:
	await _setup()
	assert_str(_icon(0).member.id).is_equal("char_fire_01")
	assert_str(_icon(1).member.id).is_equal("char_wind_01")
	_party.request_switch(2)
	for icon in _hud.icons:
		icon.advance(0.0)
	assert_str(_icon(0).member.id).is_equal("char_lightning_01")
	assert_str(_icon(1).member.id).is_equal("char_fire_01")


# ---------- HP, SI-CD ----------

func test_hp_bar_and_down_state() -> void:
	await _setup()
	var r := _icon(0).member.resources()
	r.take_damage(r.max_hp * 0.25)
	assert_float(_icon(0).hp_ratio()).is_equal_approx(0.75, 0.001)
	assert_bool(_icon(0).is_down()).is_false()
	r.take_damage(1e9)
	assert_bool(_icon(0).is_down()).is_true()
	assert_float(_icon(0).hp_ratio()).is_equal(0.0)


func test_si_cd_radial_ratio() -> void:
	await _setup()
	assert_float(_icon(0).si_cd_ratio()).is_equal(0.0)                           # đã hồi
	_party.request_switch(1)                                                     # Aether vào Thường → SI-CD 10 s
	_party.tick(1.0)
	_party.request_switch(0)                                                     # Aether về dự bị (icon 1)
	for icon in _hud.icons:
		icon.advance(0.0)
	assert_str(_icon(0).member.id).is_equal("char_fire_01")
	var left := _party.links.si_cd_left(_icon(0).member)
	assert_float(_icon(0).si_cd_ratio()).is_equal_approx(left / 10.0, 0.001)
	_party.tick(left + 0.1)
	assert_float(_icon(0).si_cd_ratio()).is_equal(0.0)


# ---------- Vòng sáng Liên kết ----------

func test_ring_fades_in_150ms_pulses_and_arc_shrinks() -> void:
	await _setup()
	var icon := _icon(0)                                                         # Aether: Choáng
	assert_float(icon.ring_visibility).is_equal(0.0)
	_bus.enemy_stunned.emit(null, _party.active().combatant())
	icon.advance(0.075)
	assert_float(icon.ring_visibility).is_equal_approx(0.5, 0.01)                # nửa đường hiện
	icon.advance(0.075)
	assert_float(icon.ring_visibility).is_equal_approx(1.0, 0.01)                # hiện hẳn sau 150 ms
	assert_float(_icon(1).ring_visibility).is_equal(0.0)                         # icon kia không sáng
	# Nhịp đập 0.8 s: 1.0 → 1.12, độ sáng 0.6 → 1.0.
	icon._pulse_t = 0.0
	assert_float(icon.ring_scale()).is_equal_approx(1.0, 0.0001)
	assert_float(icon.ring_brightness()).is_equal_approx(0.6, 0.0001)
	icon._pulse_t = 0.4
	assert_float(icon.ring_scale()).is_equal_approx(1.12, 0.0001)
	assert_float(icon.ring_brightness()).is_equal_approx(1.0, 0.0001)
	icon._pulse_t = 0.8
	assert_float(icon.ring_scale()).is_equal_approx(1.0, 0.0001)
	# Cung mỏng co theo cửa sổ 6.0 s.
	assert_float(icon.arc_ratio()).is_equal_approx(1.0, 0.001)
	_party.tick(3.0)
	assert_float(icon.arc_ratio()).is_equal_approx(0.5, 0.001)


func test_ring_fades_out_300ms_on_expiry() -> void:
	await _setup()
	var icon := _icon(0)
	_bus.enemy_stunned.emit(null, _party.active().combatant())
	icon.advance(0.2)
	_party.tick(6.1)                                                             # hết cửa sổ
	icon.advance(0.15)
	assert_float(icon.ring_visibility).is_equal_approx(0.5, 0.01)
	icon.advance(0.15)
	assert_float(icon.ring_visibility).is_equal(0.0)


func test_ring_hidden_while_si_cd_running_even_if_window_open() -> void:
	await _setup()
	_party.request_switch(1)
	_party.tick(1.0)
	_party.request_switch(0)
	for icon in _hud.icons:
		icon.advance(0.0)
	_bus.enemy_stunned.emit(null, _party.active().combatant())
	_icon(0).advance(0.2)
	assert_float(_party.links.window_left(_icon(0).member)).is_greater(0.0)
	assert_float(_icon(0).ring_visibility).is_equal(0.0)
	assert_float(_icon(0).si_cd_ratio()).is_greater(0.0)


func test_two_icons_can_glow_together() -> void:
	await _setup()
	_bus.enemy_stunned.emit(null, _party.active().combatant())
	_party.active_controller().perfect_dodged.emit(HitInfo.new())
	for icon in _hud.icons:
		icon.advance(0.2)
	assert_float(_icon(0).ring_visibility).is_equal(1.0)
	assert_float(_icon(1).ring_visibility).is_equal(1.0)


func test_linked_use_bursts_200ms() -> void:
	await _setup()
	var icon := _icon(0)
	_bus.enemy_stunned.emit(null, _party.active().combatant())
	icon.advance(0.2)
	_party.request_switch(1)                                                     # Liên kết
	assert_str(_party.last_switch_mode).is_equal("linked")
	assert_float(icon.burst_left).is_equal_approx(0.2, 0.0001)
	assert_float(icon.ring_visibility).is_equal(0.0)
	icon.advance(0.1)
	assert_float(icon.burst_left).is_equal_approx(0.1, 0.0001)
	icon.advance(0.11)
	assert_float(icon.burst_left).is_equal(0.0)


func test_normal_switch_has_no_burst() -> void:
	await _setup()
	_party.request_switch(1)
	assert_float(_icon(0).burst_left).is_equal(0.0)


# ---------- Chạm để chuyển ----------

func test_tap_icon_switches_character() -> void:
	await _setup()
	_icon(1).tap()                                                               # icon 2 = Lyra
	assert_str(_party.active().id).is_equal("char_wind_01")


func test_click_event_on_icon_switches() -> void:
	await _setup()
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	_icon(0)._gui_input(ev)
	assert_str(_party.active().id).is_equal("char_fire_01")


func test_tap_downed_member_is_rejected() -> void:
	await _setup()
	var rejected := []
	_party.switch_rejected.connect(func(_i: int, reason: String) -> void: rejected.append(reason))
	_icon(0).member.resources().take_damage(1e9)
	_icon(0).tap()
	assert_str(_party.active().id).is_equal("char_lightning_01")
	assert_array(rejected).is_equal([PartyManager.REASON_DOWN])
