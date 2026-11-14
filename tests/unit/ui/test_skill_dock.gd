extends GdUnitTestSuite
## Cụm nút kỹ năng góc dưới-phải (owner 2026-11-14): luôn hiện kể cả trên PC, icon theo giáp (Data ID) có
## bộ mặc định dự phòng, phím tắt dưới nút; thanh nhân vật trên sân chuyển xuống giữa-dưới.

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")

var _stage: Node2D


func _setup(ids: Array = ["char_wind_01", "char_lightning_01", "char_fire_01"]) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.spawn_enemies = false
	_stage.party_ids = PackedStringArray(ids)
	add_child(_stage)
	_stage.party.use_player_input = false
	for m in _stage.party.members:
		m.controller.use_player_input = false
	await get_tree().process_frame
	await get_tree().process_frame


func _touch() -> TouchControls:
	return _stage.get_node("TouchControls") as TouchControls


func test_every_suit_has_icons_and_falls_back_to_default() -> void:
	for slot in HudIcons.SLOTS:
		assert_str(HudIcons.path_for("", slot)).is_equal("%s/default/%s.png" % [HudIcons.DIR, slot])
		assert_object(HudIcons.icon("", slot)).is_not_null()
	for f in DirAccess.get_files_at("res://data/characters"):
		if f.ends_with("_kit.tres") or not f.ends_with(".tres"):
			continue
		var id := f.get_basename()
		for slot in ["attack", "skill", "weapon", "ultimate"]:
			assert_str(HudIcons.path_for(id, slot)).override_failure_message(id + " " + slot) \
					.is_equal("%s/%s/%s.png" % [HudIcons.DIR, id, slot])
		# Nhảy / né: giáp chưa có bản riêng thì dùng bản mặc định.
		assert_str(HudIcons.path_for(id, "jump")).is_equal("%s/default/jump.png" % HudIcons.DIR)
	assert_str(HudIcons.path_for("char_khong_co_01", "skill")).is_equal("%s/default/skill.png" % HudIcons.DIR)


func test_dock_visible_on_pc_with_key_hints() -> void:
	await _setup()
	var tc := _touch()
	assert_bool(tc.visible).is_true()
	if DisplayServer.is_touchscreen_available():
		return                                                               # máy cảm ứng: không có phím tắt
	assert_bool(tc.joystick.visible).is_false()
	for action: StringName in HudTheme.SKILL_BUTTONS:
		var b := tc.buttons[action] as TouchButton
		assert_bool(b.visible).is_true()
		assert_int(b.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_str((tc.buttons[&"attack"] as TouchButton).key_hint).is_equal("J")
	assert_str((tc.buttons[&"ultimate"] as TouchButton).key_hint).is_equal("O")
	assert_str((tc.buttons[&"jump"] as TouchButton).key_hint).is_equal("Space")


func test_icons_follow_active_suit() -> void:
	await _setup()
	var tc := _touch()
	tc._process(0.0)
	var atk := tc.buttons[&"attack"] as TouchButton
	assert_str(atk.icon.resource_path).is_equal(HudIcons.path_for("char_wind_01", "attack"))
	_stage.party.request_switch(1)
	for i in 30:
		await get_tree().physics_frame
		if _stage.party.active_controller().character_id == "char_lightning_01":
			break
	tc._process(0.0)
	assert_str(tc.icon_set_id).is_equal("char_lightning_01")
	assert_str(atk.icon.resource_path).is_equal(HudIcons.path_for("char_lightning_01", "attack"))
	assert_str((tc.buttons[&"jump"] as TouchButton).icon.resource_path).is_equal(HudIcons.path_for("", "jump"))


func test_layout_buttons_and_vitals_do_not_overlap() -> void:
	await _setup()
	var tc := _touch()
	var rects: Array[Rect2] = []
	for action: StringName in HudTheme.SKILL_BUTTONS:
		var b := tc.buttons[action] as TouchButton
		assert_float(minf(b.size.x, b.size.y)).is_greater_equal(128.0)
		rects.append(b.get_global_rect())
	var attack := (tc.buttons[&"attack"] as TouchButton).get_global_rect()
	for r in rects:
		assert_float(attack.size.x).is_greater_equal(r.size.x)               # nút đánh lớn nhất
	var vitals := (_stage.hud.get_node("Control/Vitals") as Control).get_global_rect() \
			if _stage.hud.has_node("Control/Vitals") else _find_vitals()
	assert_float(vitals.end.y).is_greater(900.0)                             # nằm dưới đáy màn hình
	rects.append(vitals)
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			assert_bool(rects[i].intersects(rects[j])).override_failure_message("%d chồng %d" % [i, j]).is_false()


func _find_vitals() -> Rect2:
	for n in _stage.hud.find_children("Vitals", "Control", true, false):
		return (n as Control).get_global_rect()
	return Rect2()
