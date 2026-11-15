extends GdUnitTestSuite
## Clip truyện tranh mở / kết chương (owner 2026-11-14): trang 1–4 ô đa giác hiện dần, thoại, Tự động / Lịch sử / Ẩn /
## Bỏ qua (tóm tắt), placeholder đánh số có diễn biến cảnh, phát một lần, nối vào Xuất kích / kết quả / Thông tin màn.

const SAVE_DIR := "user://test_saves_story_clip"
const CLIPS := ["ch01_open", "ch01_golem", "ch01_end"]

var _save: Node
var _old_store: SaveStore
var _old_data: Dictionary
var _old_clip := ""
var _old_next := ""


func before_test() -> void:
	_save = get_tree().root.get_node("SaveService")
	_old_store = _save.store
	_old_data = _save.data
	_save.store = SaveStore.new(SAVE_DIR)
	_save.store.delete_all()
	_save.data = SaveSchema.default_data()
	_old_clip = GameConfig.story_clip_id
	_old_next = GameConfig.story_clip_next


func after_test() -> void:
	_save.store.delete_all()
	DirAccess.remove_absolute(SAVE_DIR)
	_save.store = _old_store
	_save.data = _old_data
	GameConfig.story_clip_id = _old_clip
	GameConfig.story_clip_next = _old_next


func _clip(id: String) -> StoryClip:
	var c: StoryClip = auto_free((load(GameConfig.SCENE_STORY_CLIP) as PackedScene).instantiate())
	c.clip_id = id
	c.navigate_enabled = false
	add_child(c)
	return c


func _bounds(poly: Array) -> Rect2:
	var r := Rect2(Vector2(poly[0][0], poly[0][1]), Vector2.ZERO)
	for q in poly:
		r = r.expand(Vector2(q[0], q[1]))
	return r


# ---------- Dữ liệu ----------

func test_clip_data_valid_with_numbered_placeholders() -> void:
	for id in CLIPS:
		var d := StoryClip.load_clip(id)
		assert_bool(d.is_empty()).override_failure_message("thiếu clip " + id).is_false()
		assert_str(tr(str(d["summary"]))).is_not_equal(str(d["summary"]))
		var n := 0
		var has_card := false
		for pg: Dictionary in d["pages"]:
			if pg.has("card"):
				has_card = true
				assert_str(tr(str(pg["card"]["title"]))).is_not_equal(str(pg["card"]["title"]))
				continue
			var panels: Array = pg["panels"]
			assert_int(panels.size()).is_between(1, 4)
			for p: Dictionary in panels:
				n += 1
				assert_str(str(p["image"])).is_equal("%s_%02d" % [id, n])
				assert_int((p["poly"] as Array).size()).is_greater_equal(3)
				var b := _bounds(p["poly"])
				assert_bool(Rect2(0, 0, 1920, 810).encloses(b)).is_true()     # không đè hộp thoại
				assert_str(str(p.get("desc", ""))).is_not_empty()                # diễn biến cảnh cho placeholder
				var ph := "res://assets/placeholders/story/placeholder_%s.png" % p["image"]
				assert_bool(ResourceLoader.exists(ph)).override_failure_message("thiếu " + ph).is_true()
				var img := (load(ph) as Texture2D).get_image()
				assert_vector(Vector2(img.get_size())).is_equal(b.size)          # đúng kích thước ô
				for l: Dictionary in p["lines"]:
					assert_str(tr(str(l["text"]))).is_not_equal(str(l["text"]))
		assert_int(n).is_greater(0)
		assert_bool(has_card).is_true()


func test_should_play_once() -> void:
	assert_bool(StoryClip.should_play("ch01_open", _save.data)).is_true()
	assert_bool(StoryClip.should_play("khong_co", _save.data)).is_false()
	TutorialFlow.mark_seen(_save.data, "clip:ch01_open")
	assert_bool(StoryClip.should_play("ch01_open", _save.data)).is_false()


# ---------- Luồng ----------

func test_play_through_marks_seen() -> void:
	var c := _clip("ch01_open")
	var done := [false, true]
	c.finished.connect(func(skipped: bool) -> void:
		done[0] = true
		done[1] = skipped)
	var total := 0
	for pg: Dictionary in c.pages():
		for p: Dictionary in pg.get("panels", []):
			total += (p["lines"] as Array).size()
	for i in 400:
		if done[0]:
			break
		c.advance()
		if c.state == StoryClip.State.PAGE_OUT:
			c._process(1.0)                         # hết thời gian xóa trang
	assert_bool(done[0]).is_true()
	assert_bool(done[1]).is_false()
	assert_int(c.history.size()).is_equal(total)
	assert_bool(TutorialFlow.has_seen(_save.data, "clip:ch01_open")).is_true()


func test_panels_appear_one_by_one_and_page_clears() -> void:
	var c := _clip("ch01_open")
	var page: Control = c.get_node("Root/Page")
	assert_int(page.get_child_count()).is_equal(1)
	var first: int = (c.current_page()["panels"] as Array).size()
	while c.page_index == 0:
		c.advance()
		if c.state == StoryClip.State.PAGE_OUT:
			assert_int(page.get_child_count()).is_equal(first)   # đủ ô của trang trước khi xóa
			c._process(1.0)
	await get_tree().process_frame
	assert_int(c.page_index).is_equal(1)
	assert_int(page.get_child_count()).is_equal(1)
	assert_float(page.modulate.a).is_equal(1.0)


func test_skip_shows_summary_then_finishes() -> void:
	var c := _clip("ch01_end")
	var skipped := [false]
	c.finished.connect(func(s: bool) -> void: skipped[0] = s)
	(c.find_child("Btn_skip", true, false) as Button).pressed.emit()
	assert_object(c.find_child("SkipConfirm", true, false)).is_not_null()
	(c.find_child("SkipYes", true, false) as Button).pressed.emit()
	assert_int(c.state).is_equal(StoryClip.State.SUMMARY)
	var summary := c.find_child("Summary", true, false)
	assert_object(summary).is_not_null()
	(c.find_child("SummaryContinue", true, false) as Button).pressed.emit()
	assert_bool(skipped[0]).is_true()
	assert_bool(TutorialFlow.has_seen(_save.data, "clip:ch01_end")).is_true()


func test_back_asks_skip_and_no_keeps_watching() -> void:
	var c := _clip("ch01_open")
	assert_bool(c.intercept_back()).is_true()
	assert_object(c.find_child("SkipConfirm", true, false)).is_not_null()
	(c.find_child("SkipNo", true, false) as Button).pressed.emit()
	assert_int(c.state).is_not_equal(StoryClip.State.SUMMARY)


func test_hide_history_auto() -> void:
	var c := _clip("ch01_open")
	var box: Control = c.find_child("DialogBox", true, false)
	(c.find_child("Btn_hide", true, false) as Button).pressed.emit()
	assert_bool(box.visible).is_false()
	c._on_tap(_click())
	assert_bool(box.visible).is_true()
	c.advance()
	c.advance()
	(c.find_child("Btn_history", true, false) as Button).pressed.emit()
	var h := c.find_child("HistoryText", true, false) as Label
	assert_str(h.text).contains(tr("STORY_CH01_OPEN_01_1"))
	c.close_overlay()
	var auto := c.find_child("Btn_auto", true, false) as Button
	auto.button_pressed = true
	assert_bool(c.auto).is_true()


func _click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e


func test_speakers_and_portraits() -> void:
	assert_str(StoryClip.speaker_name("neo")).is_equal(tr("TUTORIAL_AI_NAME"))
	assert_str(StoryClip.speaker_name("narration")).is_equal("")
	assert_str(StoryClip.speaker_name("unknown")).is_equal("???")
	assert_str(StoryClip.speaker_name("char_wind_01")).is_equal(tr("CHAR_WIND_01"))
	assert_object(StoryClip.portrait_of("char_lightning_01")).is_not_null()     # chưa có chân dung: frame idle


# ---------- Nối vào game ----------

func test_map_stage_plays_open_clip_first_time() -> void:
	GameConfig.selected_chapter = 1
	GameConfig.selected_part = 0
	var s := (load(GameConfig.SCENE_CHAPTER_MAP) as PackedScene).instantiate() as ChapterMapScreen
	s.profile = PlayerProfile.new(_save.data)
	s.save_enabled = false
	s.navigate_enabled = false
	add_child(auto_free(s))
	s.press_stage("1-1")
	assert_str(s.last_target).is_equal(GameConfig.SCENE_STORY_CLIP)
	assert_str(GameConfig.story_clip_id).is_equal("ch01_open")
	assert_str(GameConfig.story_clip_next).is_equal(GameConfig.SCENE_STAGE_INFO)
	TutorialFlow.mark_seen(_save.data, "clip:ch01_open")
	s.press_stage("1-1")
	assert_str(s.last_target).is_equal(GameConfig.SCENE_STAGE_INFO)


func test_result_end_clip_and_stage_info_replay() -> void:
	var r: ResultScreen = auto_free(ResultScreen.new())
	r.summary = {"victory": true, "stage_id": "stage_01"}
	assert_str(r.end_clip()).is_equal("ch01_golem")
	r.summary = {"victory": false, "stage_id": "stage_01"}
	assert_str(r.end_clip()).is_equal("")
	GameConfig.selected_stage_id = "stage_01"
	var info := (load(GameConfig.SCENE_STAGE_INFO) as PackedScene).instantiate() as StageInfoScreen
	info.profile = PlayerProfile.new(_save.data)
	info.save_enabled = false
	info.navigate_enabled = false
	add_child(auto_free(info))
	assert_object(info.find_child("ReplayButton", true, false)).is_null()      # chưa xem: chưa có Xem lại
	TutorialFlow.mark_seen(_save.data, "clip:ch01_open")
	info.refresh()
	var btn := info.find_child("ReplayButton", true, false) as Button
	assert_object(btn).is_not_null()
	btn.pressed.emit()
	assert_str(info.last_target).is_equal(GameConfig.SCENE_STORY_CLIP)
	assert_str(GameConfig.story_clip_next).is_equal(GameConfig.SCENE_STAGE_INFO)
