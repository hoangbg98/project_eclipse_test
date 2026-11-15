extends GdUnitTestSuite
## Màn chọn chương (nhóm chương + thẻ) và map chương kéo ngang (owner 2026-11-14).

const SAVE_DIR := "user://test_saves_chapter_screens"

var _save: Node
var _old_store: SaveStore
var _old_data: Dictionary


func before_test() -> void:
	_save = get_tree().root.get_node("SaveService")
	_old_store = _save.store
	_old_data = _save.data
	_save.store = SaveStore.new(SAVE_DIR)
	_save.store.delete_all()
	_save.data = SaveSchema.default_data()
	_save.data["tutorial"]["done"] = true
	GameConfig.selected_chapter = 1
	GameConfig.selected_part = 0


func after_test() -> void:
	_save.store.delete_all()
	DirAccess.remove_absolute(SAVE_DIR)
	_save.store = _old_store
	_save.data = _old_data


func _screen(path: String) -> HubScreen:
	var s := (load(path) as PackedScene).instantiate() as HubScreen
	s.profile = PlayerProfile.new(_save.data)
	s.save_enabled = false
	s.navigate_enabled = false
	add_child(auto_free(s))
	s.set_anchors_preset(Control.PRESET_TOP_LEFT)
	s.size = Vector2(1920, 1080)
	return s


func test_sortie_story_opens_chapter_select() -> void:
	var s := _screen(GameConfig.SCENE_SORTIE) as SortieScreen
	s.activate("story")
	assert_str(s.last_target).is_equal(GameConfig.SCENE_CHAPTERS)


func test_select_arcs_and_cards() -> void:
	var s := _screen(GameConfig.SCENE_CHAPTERS) as ChapterSelectScreen
	assert_str(s.arc_id).is_equal("arc_01")                          # hành trình mới nhất
	assert_array(s.card_buttons.keys()).contains_exactly(["1", "2"])
	for a: Dictionary in ChapterBook.arcs():
		assert_object(s.find_child("Arc_" + str(a["id"]), true, false)).is_not_null()
	s.select_arc("arc_04")                                            # một chương nhiều phần: thẻ theo phần
	assert_array(s.card_buttons.keys()).contains_exactly(["7_1", "7_2"])
	s.card_buttons["7_2"].pressed.emit()
	assert_str(s.last_target).is_equal(GameConfig.SCENE_CHAPTER_MAP)
	assert_int(GameConfig.selected_chapter).is_equal(7)
	assert_int(GameConfig.selected_part).is_equal(2)
	(s.find_child("LatestButton", true, false) as Button).pressed.emit()
	assert_str(s.arc_id).is_equal("arc_01")


func test_map_nodes_and_stage_press() -> void:
	var m := _screen(GameConfig.SCENE_CHAPTER_MAP) as ChapterMapScreen
	assert_int(m.stage_nodes.size()).is_equal(10)
	assert_int(m.chest_buttons.size()).is_equal(1)
	assert_object(m.find_child("PartTitle_ch01_p1", true, false)).is_not_null()
	# Ải chưa có màn: thông báo Sắp ra mắt, không đổi scene.
	m.press_stage("2-1")
	assert_str(m.notice).is_equal(tr("MAP_STAGE_SOON") % "2-1")
	assert_str(m.last_target).is_equal("")
	# 1-2 có màn nhưng 1-1 chưa qua: khóa.
	m.press_stage("1-2")
	assert_str(m.notice).is_equal(tr("MAP_STAGE_LOCKED") % "1-2")
	assert_str(m.last_target).is_equal("")
	# 1-1 lần đầu: clip mở chương rồi Thông tin màn.
	m.stage_nodes["1-1"].pressed.emit()
	assert_str(m.last_target).is_equal(GameConfig.SCENE_STORY_CLIP)
	assert_str(GameConfig.story_clip_id).is_equal("ch01_open")
	assert_str(GameConfig.story_clip_next).is_equal(GameConfig.SCENE_STAGE_INFO)
	assert_str(GameConfig.selected_stage_id).is_equal("stage_01")
	TutorialFlow.mark_seen(_save.data, "clip:ch01_open")
	m.press_stage("1-1")
	assert_str(m.last_target).is_equal(GameConfig.SCENE_STAGE_INFO)


func test_map_drag_scrolls_and_blocks_press() -> void:
	GameConfig.selected_chapter = 4
	var m := _screen(GameConfig.SCENE_CHAPTER_MAP) as ChapterMapScreen
	assert_int(m.stage_nodes.size()).is_equal(20)
	assert_float(m.max_scroll()).is_greater(0.0)
	var area := m.find_child("MapArea", true, false) as Control
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(900, 500)
	area.gui_input.emit(down)
	var x0 := m.scroll_x
	var move := InputEventMouseMotion.new()
	move.position = Vector2(600, 500)
	move.relative = Vector2(-300, 0)
	area.gui_input.emit(move)
	assert_bool(m.dragged).is_true()
	assert_float(m.scroll_x).is_equal_approx(minf(x0 + 300.0, m.max_scroll()), 0.5)
	m.set_scroll(-50)
	assert_float(m.scroll_x).is_equal(0.0)
	m.set_scroll(1e9)
	assert_float(m.scroll_x).is_equal(m.max_scroll())


func test_map_part_scroll_and_chest_claim() -> void:
	GameConfig.selected_chapter = 7
	GameConfig.selected_part = 2
	var m := _screen(GameConfig.SCENE_CHAPTER_MAP) as ChapterMapScreen
	assert_float(m.scroll_x).is_greater(0.0)                          # cuộn tới phần 2
	m.claim_chest("ch07_p1")
	assert_str(m.notice).is_equal(tr("MAP_CHEST_NOT_READY"))
