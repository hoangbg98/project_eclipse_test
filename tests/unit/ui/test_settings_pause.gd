extends GdUnitTestSuite
## Test M7-1: Cài đặt (ngôn ngữ, âm lượng, lưu), AudioRouter, Tạm dừng (dừng cây, xác nhận thoát, Back), Credits, safe area.

const STAGE_SCENE := preload("res://scenes/stages/stage.tscn")
const SAVE_DIR := "user://test_saves_m7_1"

var _save: Node
var _old_store: SaveStore
var _old_data: Dictionary
var _old_locale := ""


func before_test() -> void:
	_save = get_tree().root.get_node("SaveService")
	_old_store = _save.store
	_old_data = _save.data
	_old_locale = TranslationServer.get_locale()
	_save.store = SaveStore.new(SAVE_DIR)
	_save.store.delete_all()
	_save.data = SaveSchema.default_data()


func after_test() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_save.store.delete_all()
	DirAccess.remove_absolute(SAVE_DIR)
	_save.store = _old_store
	_save.data = _old_data
	TranslationServer.set_locale(_old_locale)
	for bus in [&"Master", &"Music", &"SFX"]:
		AudioRouter.set_volume(bus, 1.0)


func _panel() -> SettingsPanel:
	var p: SettingsPanel = auto_free(SettingsPanel.new())
	add_child(p)
	return p


# ---------- Cài đặt ----------

func test_language_change_applies_saves_and_persists() -> void:
	var p := _panel()
	p.set_language("en")
	assert_str(TranslationServer.get_locale()).is_equal("en")
	assert_str(tr("PAUSE_RESUME")).is_equal("Resume")
	assert_str(_save.data["settings"]["language"]).is_equal("en")
	assert_str(SaveStore.new(SAVE_DIR).read()["settings"]["language"]).is_equal("en")   # đã ghi file
	p.set_language("xx")                                              # không hỗ trợ: bỏ qua
	assert_str(_save.data["settings"]["language"]).is_equal("en")
	p.set_language("vi")
	assert_str(tr("PAUSE_RESUME")).is_equal("Tiếp tục")


func test_volume_sliders_drive_audio_buses() -> void:
	var p := _panel()
	p.set_volume(0.5, "music_volume")
	assert_float(AudioRouter.get_volume(&"Music")).is_equal_approx(0.5, 0.01)
	assert_float(_save.data["settings"]["music_volume"]).is_equal(0.5)
	p.set_volume(0.0, "sfx_volume")
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"SFX"))).is_true()   # 0 = tắt tiếng
	p.set_volume(5.0, "master_volume")
	assert_float(_save.data["settings"]["master_volume"]).is_equal(1.0)                 # chặn 0..1
	p.set_volume(0.3, "bogus")
	assert_bool(_save.data["settings"].has("bogus")).is_false()


func test_apply_settings_from_saved_data() -> void:
	SettingsPanel.apply_settings({"language": "en", "master_volume": 0.4, "music_volume": 0.2, "sfx_volume": 0.9})
	assert_str(TranslationServer.get_locale()).is_equal("en")
	assert_float(AudioRouter.get_volume(&"Master")).is_equal_approx(0.4, 0.01)
	assert_float(AudioRouter.get_volume(&"Music")).is_equal_approx(0.2, 0.01)
	SettingsPanel.apply_settings({"language": "vi"}, false)           # --lang trên dòng lệnh: không đổi ngôn ngữ
	assert_str(TranslationServer.get_locale()).is_equal("en")


func test_settings_schema_keeps_fullscreen_bool() -> void:
	var d := SaveSchema.sanitize({"settings": {"fullscreen": true, "language": "en"}})
	assert_bool(d["settings"]["fullscreen"]).is_true()
	assert_bool(SaveSchema.sanitize({"settings": {"fullscreen": "yes"}})["settings"]["fullscreen"]).is_false()


# ---------- AudioRouter ----------

func test_audio_buses_exist_and_missing_files_are_safe() -> void:
	for bus in [&"Music", &"SFX"]:
		assert_int(AudioServer.get_bus_index(bus)).is_greater(0)
		assert_str(str(AudioServer.get_bus_send(AudioServer.get_bus_index(bus)))).is_equal("Master")
	assert_bool(AudioRouter.play_sfx("sfx_does_not_exist")).is_false()
	assert_bool(AudioRouter.play_music("music_does_not_exist")).is_false()
	assert_bool(AudioRouter.missing.has("sfx_does_not_exist")).is_true()   # ghi nhận để owner biết thiếu gì
	assert_str(AudioRouter.current_music).is_equal("")


# ---------- Tạm dừng ----------

func _stage() -> StageController:
	var s: StageController = auto_free(STAGE_SCENE.instantiate())
	s.use_selected_stage = false
	s.stage_id = "stage_01"
	add_child(s)
	return s


func test_pause_stops_tree_and_resume_restores() -> void:
	var s := _stage()
	var menu := s.get_node("PauseMenu") as PauseMenu
	assert_bool(menu.is_open()).is_false()
	menu.open()
	assert_bool(get_tree().paused).is_true()
	assert_bool(menu.is_open()).is_true()
	assert_int(menu.view).is_equal(PauseMenu.View.MAIN)
	menu.resume()
	assert_bool(get_tree().paused).is_false()
	assert_bool(menu.is_open()).is_false()


func test_back_button_steps_through_pause_views() -> void:
	var s := _stage()
	var menu := s.get_node("PauseMenu") as PauseMenu
	assert_bool(menu.intercept_back()).is_true()                      # Esc lần 1: mở
	assert_bool(menu.is_open()).is_true()
	menu.show_view(PauseMenu.View.CONFIRM_QUIT)
	assert_bool(menu.intercept_back()).is_true()                      # đang ở xác nhận: về menu chính
	assert_int(menu.view).is_equal(PauseMenu.View.MAIN)
	assert_bool(menu.is_open()).is_true()
	assert_bool(menu.intercept_back()).is_true()                      # ở menu chính: tiếp tục
	assert_bool(menu.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()


func test_quit_needs_confirmation() -> void:
	var s := _stage()
	var menu := s.get_node("PauseMenu") as PauseMenu
	var quits := [0]
	menu.quit_requested.connect(func() -> void: quits[0] += 1)
	menu.open()
	menu.show_view(PauseMenu.View.CONFIRM_QUIT)
	assert_int(quits[0]).is_equal(0)                                  # mới hỏi, chưa thoát
	menu.show_view(PauseMenu.View.MAIN)
	assert_int(quits[0]).is_equal(0)
	menu.resume()


func test_pause_disabled_on_result_screen() -> void:
	var s := _stage()
	await get_tree().physics_frame
	for m in s.party.members:
		m.resources().take_damage(1e9)
	await get_tree().physics_frame
	var menu := s.get_node("PauseMenu") as PauseMenu
	assert_bool(menu.enabled).is_false()
	menu.open()
	assert_bool(menu.is_open()).is_false()
	assert_bool(menu.intercept_back()).is_false()                     # Back lúc này quay về Hub như thường


func test_hud_pause_button_opens_menu_and_is_big_enough() -> void:
	var s := _stage()
	await get_tree().process_frame
	var b := s.hud.pause_button
	assert_float(minf(b.size.x, b.size.y)).is_greater_equal(128.0)
	for icon in s.hud.icons:
		assert_bool(b.get_global_rect().intersects(icon.get_global_rect())).is_false()   # xa icon dự bị
	b.pressed.emit()
	assert_bool((s.get_node("PauseMenu") as PauseMenu).is_open()).is_true()
	(s.get_node("PauseMenu") as PauseMenu).resume()


# ---------- Credits, safe area ----------

func test_credits_lists_shipped_licenses() -> void:
	var c: CreditsPanel = auto_free(CreditsPanel.new())
	add_child(c)
	var text := c.build_text()
	assert_bool(text.contains("PROJECT ECLIPSE")).is_true()
	assert_bool(text.contains("pixelfx") and text.contains("MIT")).is_true()
	assert_bool(text.contains("Godot Engine") and text.contains("Juan Linietsky")).is_true()   # giấy phép MIT của Godot
	assert_int(CreditsPanel.load_entries().size()).is_greater_equal(2)


func test_safe_margins_scale_to_design_size() -> void:
	# Màn 2400×1080 có tai thỏ 90 px bên trái, thanh 60 px bên dưới; viewport thiết kế cao 1080.
	var m := UiKit.safe_margins(Vector2(2400, 1080), Vector2i(2400, 1080), Rect2i(90, 0, 2310, 1020))
	assert_array(m).is_equal([90.0, 0.0, 0.0, 60.0])
	# Màn 1200×540 (tỉ lệ 0.5): lề nhân đôi theo khung thiết kế.
	m = UiKit.safe_margins(Vector2(2400, 1080), Vector2i(1200, 540), Rect2i(45, 0, 1155, 540))
	assert_array(m).is_equal([90.0, 0.0, 0.0, 0.0])
	assert_array(UiKit.safe_margins(Vector2(1920, 1080), Vector2i(0, 0), Rect2i())).is_equal([0.0, 0.0, 0.0, 0.0])
