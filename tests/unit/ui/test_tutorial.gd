extends GdUnitTestSuite
## Hướng dẫn người mới (owner 2026-11-14): game mới chỉ có Enkiba; qua ải 1-1 lần đầu nhận Kazeyumi và vé chiêu mộ x10
## đầu tiên; hướng dẫn khóa màn, chỉ sáng nút cần bấm: Xuất kích → Cốt truyện → Chuẩn bị → Khai chiến → (thắng) Về Hub →
## Tiếp tế → Chiêu mộ → x10 miễn phí (chắc chắn Raikiba) → Xác nhận → Trở về → Xuất kích → Đội hình → ô trống →
## Kazeyumi → Xác nhận đội ngũ → xong (owner 2026-11-15: đội ban đầu chỉ Enkiba, giáp mới không tự vào đội).

const GC := preload("res://scripts/core/game_config.gd")
const GUIDE_SCRIPT := preload("res://scripts/ui/tutorial_guide.gd")
const RECRUIT_SCENE := preload("res://scenes/main/recruit_screen.tscn")
const SAVE_DIR := "user://test_saves_tutorial"
const STARTER_PATH := "res://data/tutorial/starter_pull.tres"

var _save: Node
var _old_store: SaveStore
var _old_data: Dictionary
var _global_guide: Node
var _global_enabled := true


func before_test() -> void:
	_save = get_tree().root.get_node("SaveService")
	_old_store = _save.store
	_old_data = _save.data
	_save.store = SaveStore.new(SAVE_DIR)
	_save.store.delete_all()
	_save.data = SaveSchema.default_data()
	# Autoload thật có thể đang chạy: tắt để không chồng lên guide của test.
	_global_guide = get_tree().root.get_node_or_null("TutorialGuide")
	if _global_guide:
		_global_enabled = _global_guide.enabled
		_global_guide.enabled = false


func after_test() -> void:
	_save.store.delete_all()
	DirAccess.remove_absolute(SAVE_DIR)
	_save.store = _old_store
	_save.data = _old_data
	if _global_guide:
		_global_guide.enabled = _global_enabled


func _stage_first_clear() -> Dictionary:
	return StageMap.load_from("res://data/stages/stage_01.json").data["first_clear_rewards"]


## Giả lập lượt x10 miễn phí: nhận Raikiba, dùng vé (như GachaService.pull_starter, không vào đội lúc hướng dẫn).
func _pull_starter(data: Dictionary) -> void:
	var p := PlayerProfile.new(data)
	p.progression.unlock("char_lightning_01")
	p.auto_join_party("char_lightning_01")
	data["gacha"]["starter_used"].append("starter_pull")
	data["inventory"]["materials"].erase("ticket_starter_x10")


func _clear_stage(data: Dictionary) -> PlayerProfile:
	var p := PlayerProfile.new(data)
	p.grant(_stage_first_clear())
	data["progress"]["stages"]["stage_01"] = {"cleared": true, "best_time_sec": 200.0, "objectives": []}
	return p


# ---------- Đội khởi đầu, save ----------

func test_new_game_has_only_enkiba_and_tutorial_pending() -> void:
	var d := SaveSchema.default_data()
	assert_array(d["characters"].keys()).is_equal(["char_fire_01"])
	assert_array(d["party"]).is_equal(["char_fire_01"])
	assert_bool(TutorialFlow.is_done(d)).is_false()
	assert_str(TutorialFlow.phase(d)).is_equal(TutorialFlow.PHASE_STORY)
	assert_bool(SaveSchema.sanitize(d)["tutorial"]["done"]).is_false()


func test_old_save_migrates_with_tutorial_done() -> void:
	var old := {"characters": {"char_fire_01": {}, "char_wind_01": {}, "char_lightning_01": {}}, "party": ["char_fire_01"],
			"account": {"level": 3, "exp": 0, "name": ""}, "cosmetics": {"backgrounds": [], "hub_background": ""}}
	var d: Dictionary = SaveSchema.sanitize(SaveSchema.migrate(old, 5))
	assert_bool(d["tutorial"]["done"]).is_true()
	assert_int(d["characters"].size()).is_equal(3)                     # người chơi cũ giữ nhân vật
	assert_str(TutorialFlow.phase(d)).is_equal(TutorialFlow.PHASE_DONE)


# ---------- Thưởng ải 1-1 ----------

func test_stage_1_1_first_clear_gives_kazeyumi_and_ticket() -> void:
	var data := SaveSchema.default_data()
	var p := PlayerProfile.new(data)
	var got := p.grant(_stage_first_clear())
	assert_array(got["characters"]).is_equal(["char_wind_01"])
	assert_bool(p.progression.owns("char_wind_01")).is_true()
	# Owner 2026-11-15: lúc hướng dẫn, giáp mới không tự vào đội (NEO chỉ cách xếp đội sau).
	assert_array(Array(p.party_ids())).is_equal(["char_fire_01"])
	assert_int(p.inventory.material_count("ticket_starter_x10")).is_equal(1)
	# Nhận lại (đã có) thì không thêm.
	assert_array(p.grant({"characters": ["char_wind_01"]})["characters"]).is_empty()
	assert_array(Array(p.party_ids())).is_equal(["char_fire_01"])


func test_new_character_joins_party_after_tutorial() -> void:
	var data := SaveSchema.default_data()
	TutorialFlow.finish(data)
	var p := PlayerProfile.new(data)
	p.grant({"characters": ["char_wind_01"]})
	assert_array(Array(p.party_ids())).is_equal(["char_fire_01", "char_wind_01"])
	# Save không có mục tutorial (dữ liệu cũ chưa qua sanitize) coi như đã xong.
	var old := SaveSchema.default_data()
	old.erase("tutorial")
	var q := PlayerProfile.new(old)
	assert_bool(q.progression.unlock("char_wind_01")).is_true()
	assert_bool(q.auto_join_party("char_wind_01")).is_true()


func test_stage_code_shown_in_title() -> void:
	var data := StageMap.load_from("res://data/stages/stage_01.json").data
	assert_str(StageInfoScreen.title_of(data, "stage_01")).starts_with("1-1 · ")
	assert_str(StageInfoScreen.title_of({}, "x")).is_equal("x")


func test_join_party_respects_room_and_same_person() -> void:
	var data := SaveSchema.default_data()
	var p := PlayerProfile.new(data)
	for id in ["char_wind_01", "char_lightning_01", "char_dark_01"]:
		p.progression.unlock(id)
	assert_bool(p.join_party_if_room("char_wind_01")).is_true()
	assert_bool(p.join_party_if_room("char_wind_01")).is_false()          # đã trong đội
	assert_bool(p.join_party_if_room("char_lightning_01")).is_true()
	assert_bool(p.join_party_if_room("char_dark_01")).is_false()          # đội đủ 3
	assert_bool(p.join_party_if_room("char_light_01")).is_false()         # chưa sở hữu


# ---------- Các bước ----------

func _targets(data: Dictionary, scene: String) -> Array:
	return TutorialFlow.step(data, scene).get("targets", [])


func test_story_phase_steps() -> void:
	var d := SaveSchema.default_data()
	assert_array(_targets(d, GC.SCENE_HUB)).is_equal(["Tile_sortie"])
	assert_array(_targets(d, GC.SCENE_SORTIE)).is_equal(["Card_story"])
	assert_array(_targets(d, GC.SCENE_CHAPTERS)).is_equal(["ChapterCard_1"])
	assert_array(_targets(d, GC.SCENE_CHAPTER_MAP)).is_equal(["Stage_1-1"])
	assert_array(_targets(d, GC.SCENE_STAGE_INFO)).is_equal(["PrepareButton"])
	assert_array(_targets(d, GC.SCENE_PARTY_PREP)).is_equal(["GoButton"])
	assert_array(_targets(d, GC.SCENE_STAGE)).is_equal(["RetryButton"])
	assert_array(_targets(d, GC.SCENE_SUPPLY)).is_equal(["MenuButton"])   # lạc màn → về sảnh
	assert_dict(TutorialFlow.step(d, GC.SCENE_TITLE)).is_empty()           # Title không khóa
	assert_dict(TutorialFlow.step(d, "res://scenes/khac.tscn")).is_empty()


func test_pull_and_finish_phase_steps() -> void:
	var d := SaveSchema.default_data()
	_clear_stage(d)
	assert_str(TutorialFlow.phase(d)).is_equal(TutorialFlow.PHASE_PULL)
	assert_array(_targets(d, GC.SCENE_STAGE)).is_equal(["HubButton"])
	assert_array(_targets(d, GC.SCENE_PARTY_PREP)).is_equal(["MenuButton"])
	assert_array(_targets(d, GC.SCENE_HUB)).is_equal(["Tile_supply"])
	assert_array(_targets(d, GC.SCENE_SUPPLY)).is_equal(["Go_gacha"])
	assert_array(_targets(d, GC.SCENE_RECRUIT)).is_equal(["Wish_starter"])
	_pull_starter(d)
	# Đội vẫn chỉ Enkiba → NEO chỉ xếp đội: đóng kết quả / Trở về → Xuất kích → Đội hình → ô trống → Kazeyumi.
	assert_str(TutorialFlow.phase(d)).is_equal(TutorialFlow.PHASE_PARTY)
	assert_str(TutorialFlow.party_candidate(d)).is_equal("char_wind_01")
	var r := TutorialFlow.step(d, GC.SCENE_RECRUIT)
	assert_array(r["targets"]).is_equal(["ResultClose", "CloseButton"])
	assert_str(TutorialFlow.pick(r, 0)["hint"]).is_equal("TUTORIAL_RECRUIT_CLOSE")
	assert_str(TutorialFlow.pick(r, 1)["hint"]).is_equal("TUTORIAL_RECRUIT_BACK")
	assert_array(TutorialFlow.pick(r, 1)["targets"]).is_equal(["CloseButton"])
	assert_array(_targets(d, GC.SCENE_SUPPLY)).is_equal(["MenuButton"])
	assert_array(_targets(d, GC.SCENE_HUB)).is_equal(["Tile_sortie"])
	assert_str(TutorialFlow.step(d, GC.SCENE_HUB)["hint"]).is_equal("TUTORIAL_HUB_PARTY")
	assert_array(_targets(d, GC.SCENE_SORTIE)).is_equal(["Card_party"])
	assert_array(_targets(d, GC.SCENE_PARTY_PREP)).is_equal(["Slot_1"])
	assert_array(_targets(d, GC.SCENE_PARTY_SELECT)).is_equal(["Suit_char_wind_01"])
	assert_bool(TutorialFlow.step(d, GC.SCENE_HUB).get("finish", false)).is_false()
	# Thêm Kazeyumi: đội 2 người → Xác nhận đội ngũ → xong.
	assert_str(PlayerProfile.new(d).toggle_party("char_wind_01")).is_equal(PlayerProfile.PARTY_OK)
	assert_array(d["party"]).is_equal(["char_fire_01", "char_wind_01"])
	assert_str(TutorialFlow.phase(d)).is_equal(TutorialFlow.PHASE_FINISH)
	assert_array(_targets(d, GC.SCENE_PARTY_SELECT)).is_equal(["ConfirmButton"])
	assert_bool(TutorialFlow.step(d, GC.SCENE_PARTY_PREP).get("finish", false)).is_true()
	assert_bool(TutorialFlow.step(d, GC.SCENE_HUB).get("finish", false)).is_true()
	# Save cũ đang dở ở bước đóng kết quả quay (đội đã đủ người): vẫn kết thúc như trước.
	var s := TutorialFlow.step(d, GC.SCENE_RECRUIT)
	assert_array(s["targets"]).is_equal(["ResultClose"])
	assert_bool(s["finish_if_missing"]).is_true()
	TutorialFlow.finish(d)
	assert_str(TutorialFlow.phase(d)).is_equal(TutorialFlow.PHASE_DONE)
	assert_dict(TutorialFlow.step(d, GC.SCENE_HUB)).is_empty()


# ---------- Màn Chiêu mộ: banner lượt miễn phí ----------

func _recruit() -> RecruitScreen:
	var s: RecruitScreen = auto_free(RECRUIT_SCENE.instantiate())
	add_child(s)
	s.set_anchors_preset(Control.PRESET_TOP_LEFT)
	s.size = Vector2(1920, 1080)
	s.service.rng = RandomSource.new(5)
	return s


func test_recruit_hides_starter_without_ticket() -> void:
	var s := _recruit()
	for b in s.banners:
		assert_bool(b.starter_free_multi).is_false()
	assert_object(s.find_child("Wish_starter", true, false)).is_null()


func test_recruit_starter_with_ticket_pulls_raikiba_and_disappears() -> void:
	_clear_stage(_save.data)
	var s := _recruit()
	assert_bool(s.is_starter(s.current())).is_true()                      # đầu danh sách, đang chọn
	var btn := s.find_child("Wish_starter", true, false) as Button
	assert_object(btn).is_not_null()
	assert_bool(btn.disabled).is_false()
	assert_object(s.find_child("Wish_1", true, false)).is_null()           # không có quay ×1
	assert_str(btn.text).contains(tr("RECRUIT_UI_STARTER_TICKET") % 1)
	var gems := s.profile.inventory.currency("gems")
	btn.pressed.emit()
	assert_bool(s.profile.progression.owns("char_lightning_01")).is_true()
	assert_array(Array(s.profile.party_ids())).is_equal(["char_fire_01"])   # lúc hướng dẫn không tự vào đội
	assert_int(s.profile.inventory.currency("gems")).is_equal(gems)
	assert_int(s.last_results.size()).is_equal(10)
	assert_object(s.find_child("ResultClose", true, false)).is_not_null()
	(s.find_child("ResultClose", true, false) as Button).pressed.emit()
	for b in s.banners:
		assert_bool(b.starter_free_multi).is_false()                      # đã dùng: bỏ khỏi danh sách


func test_starter_details_explain_rule() -> void:
	_clear_stage(_save.data)
	var s := _recruit()
	var text := "\n".join(s.rate_lines(s.current()))
	assert_str(text).contains(tr("CHAR_LIGHTNING_01"))
	assert_str(text).contains(tr("ITEM_MAT_EXP_SMALL"))


# ---------- Lớp hướng dẫn: ô sáng, chặn, bấm ----------

func _fake_scene(path: String, button_name: String) -> Control:
	var root: Control = auto_free(Control.new())
	root.scene_file_path = path
	root.size = Vector2(1920, 1080)
	var other := Button.new()
	other.name = "Other"
	other.position = Vector2(100, 100)
	other.size = Vector2(200, 100)
	root.add_child(other)
	var b := Button.new()
	b.name = button_name
	b.position = Vector2(1200, 300)
	b.size = Vector2(400, 200)
	root.add_child(b)
	add_child(root)
	return root


func _guide(scene: Node) -> CanvasLayer:
	var g: CanvasLayer = auto_free(GUIDE_SCRIPT.new())
	g.scene_override = scene
	add_child(g)
	g.set_process(false)
	return g


func test_guide_highlights_target_and_blocks_rest() -> void:
	var scene := _fake_scene(GC.SCENE_HUB, "Tile_sortie")
	var g := _guide(scene)
	g.refresh()
	assert_bool(g.is_active()).is_true()
	assert_str(g.target.name).is_equal("Tile_sortie")
	assert_str(g.hint_key).is_equal("TUTORIAL_HUB_SORTIE")
	# Lần đầu: NEO trò chuyện trước, cả màn bị che (kể cả nút của bước).
	assert_bool(g.is_talking()).is_true()
	assert_vector((g.get_node("Dim0") as ColorRect).size).is_equal(g.get_viewport().get_visible_rect().size)
	g.skip_talk()
	g.refresh()
	assert_bool(g.is_talking()).is_false()
	assert_bool(TutorialFlow.has_seen(_save.data, "hub_sortie")).is_true()
	var hole: Rect2 = g.hole_rect()
	assert_bool(hole.encloses(Rect2(1200, 300, 400, 200))).is_true()
	# Bốn ô tối chặn chuột, phủ nút khác, không phủ ô sáng.
	var dims := g.find_children("Dim*", "ColorRect", false, false)
	assert_int(dims.size()).is_equal(4)
	var covers_other := false
	for d: ColorRect in dims:
		assert_int(d.mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)
		assert_bool(d.get_rect().intersects(hole.grow(-1))).is_false()
		if d.get_rect().has_point(Vector2(200, 150)):
			covers_other = true
	assert_bool(covers_other).is_true()
	assert_bool(g.intercept_back()).is_true()
	var pressed := [false]
	(scene.find_child("Tile_sortie", false, false) as Button).pressed.connect(func() -> void: pressed[0] = true)
	g.press_target()
	assert_bool(pressed[0]).is_true()


func test_guide_inactive_when_done_or_target_hidden() -> void:
	var scene := _fake_scene(GC.SCENE_HUB, "Tile_sortie")
	var g := _guide(scene)
	(scene.find_child("Tile_sortie", false, false) as Control).visible = false
	g.refresh()
	assert_bool(g.is_active()).is_false()
	assert_bool(g.intercept_back()).is_false()
	(scene.find_child("Tile_sortie", false, false) as Control).visible = true
	TutorialFlow.finish(_save.data)
	g.refresh()
	assert_bool(g.is_active()).is_false()


func test_guide_recruit_close_then_back_in_party_phase() -> void:
	_clear_stage(_save.data)
	_pull_starter(_save.data)
	TutorialFlow.mark_seen(_save.data, "recruit_close")
	var scene := _fake_scene(GC.SCENE_RECRUIT, "ResultClose")
	var back := Button.new()
	back.name = "CloseButton"
	back.size = Vector2(200, 80)
	scene.add_child(back)
	var g := _guide(scene)
	g.refresh()
	assert_str(g.target.name).is_equal("ResultClose")
	assert_str(g.hint_key).is_equal("TUTORIAL_RECRUIT_CLOSE")
	(scene.find_child("ResultClose", false, false) as Control).visible = false
	g.refresh()
	assert_bool(g.is_active()).is_true()
	assert_str(g.target.name).is_equal("CloseButton")
	assert_str(g.hint_key).is_equal("TUTORIAL_RECRUIT_BACK")
	assert_str(g.step_id).is_equal("recruit_back")
	assert_bool(TutorialFlow.is_done(_save.data)).is_false()             # chưa xếp đội thì chưa xong


func test_guide_party_add_then_confirm_finishes() -> void:
	_clear_stage(_save.data)
	_pull_starter(_save.data)
	for id in ["party_add", "party_confirm"]:
		TutorialFlow.mark_seen(_save.data, id)
	var scene := _fake_scene(GC.SCENE_PARTY_SELECT, "Suit_char_wind_01")
	var confirm := Button.new()
	confirm.name = "ConfirmButton"
	confirm.size = Vector2(300, 90)
	scene.add_child(confirm)
	var g := _guide(scene)
	g.refresh()
	assert_str(g.target.name).is_equal("Suit_char_wind_01")
	assert_str(g.hint_key).is_equal("TUTORIAL_PARTY_ADD")
	PlayerProfile.new(_save.data).toggle_party("char_wind_01")
	g.refresh()
	assert_str(g.target.name).is_equal("ConfirmButton")
	assert_str(g.hint_key).is_equal("TUTORIAL_PARTY_CONFIRM")
	# Xác nhận → về màn đội hình → hướng dẫn xong, đội 2 người.
	g.scene_override = _fake_scene(GC.SCENE_PARTY_PREP, "GoButton")
	g.refresh()
	assert_bool(g.is_active()).is_false()
	assert_bool(TutorialFlow.is_done(_save.data)).is_true()
	assert_array(_save.data["party"]).is_equal(["char_fire_01", "char_wind_01"])


func test_guide_finishes_after_results_closed() -> void:
	# Save cũ: lượt miễn phí đã đưa Raikiba vào đội (trước 2026-11-15), đang dở ở bước đóng kết quả.
	_clear_stage(_save.data)
	_save.data["gacha"]["starter_used"].append("starter_pull")
	_save.data["inventory"]["materials"].erase("ticket_starter_x10")
	_save.data["party"] = ["char_fire_01", "char_wind_01"]
	TutorialFlow.mark_seen(_save.data, "recruit_done")
	var scene := _fake_scene(GC.SCENE_RECRUIT, "ResultClose")
	var g := _guide(scene)
	g.refresh()
	assert_bool(g.is_active()).is_true()
	assert_str(g.hint_key).is_equal("TUTORIAL_RECRUIT_DONE")
	(scene.find_child("ResultClose", false, false) as Control).visible = false
	g.refresh()
	assert_bool(g.is_active()).is_false()
	assert_bool(TutorialFlow.is_done(_save.data)).is_true()


func test_tutorial_texts_translated() -> void:
	for k in ["TUTORIAL_HUB_SORTIE", "TUTORIAL_SORTIE_STORY", "TUTORIAL_STAGE_PREPARE", "TUTORIAL_PARTY_GO",
			"TUTORIAL_RETRY", "TUTORIAL_RESULT_HUB", "TUTORIAL_MENU", "TUTORIAL_HUB_SUPPLY", "TUTORIAL_SUPPLY_GACHA",
			"TUTORIAL_RECRUIT_STARTER", "TUTORIAL_RECRUIT_DONE", "TUTORIAL_RECRUIT_CLOSE", "TUTORIAL_RECRUIT_BACK",
			"TUTORIAL_HUB_PARTY", "TUTORIAL_SORTIE_PARTY", "TUTORIAL_PARTY_SLOT", "TUTORIAL_PARTY_ADD",
			"TUTORIAL_PARTY_CONFIRM", "ITEM_TICKET_STARTER_X10", "RESULT_NEW_CHARACTER",
			"REASON_NO_TICKET"]:
		assert_str(tr(k)).is_not_equal(k)


# ---------- Hội thoại với trợ lý AI ----------

func test_conversation_lines_reply_and_seen_once() -> void:
	var scene := _fake_scene(GC.SCENE_HUB, "Tile_sortie")
	var g := _guide(scene)
	g.refresh()
	var n: int = g.lines.size()
	assert_int(n).is_greater(1)
	assert_str(g.lines[n - 1]["text"]).is_equal("TUTORIAL_HUB_SORTIE")     # câu cuối là câu chỉ dẫn
	assert_str(g.lines[n - 1]["reply"]).is_equal("")
	# Chữ hiện dần: lần chạm đầu hiện hết câu, nút đáp của Quản lý hiện khi đã hết chữ.
	assert_bool(g.line_done()).is_false()
	g.advance()
	assert_bool(g.line_done()).is_true()
	assert_int(g.line_index).is_equal(0)
	g.refresh()
	var reply := g.find_child("Reply", true, false) as Button
	assert_bool(reply.visible).is_true()
	assert_str(reply.text).contains(tr("TUTORIAL_PLAYER_NAME"))
	assert_str(reply.text).contains(tr("TUTORIAL_HUB_SORTIE_1_R"))
	assert_str((g.find_child("Speaker", true, false) as Label).text).contains(tr("TUTORIAL_AI_NAME"))
	reply.pressed.emit()
	assert_int(g.line_index).is_equal(1)
	for i in n * 2:
		g.advance()
	assert_int(g.line_index).is_equal(n - 1)
	assert_bool(TutorialFlow.has_seen(_save.data, "hub_sortie")).is_true()
	# Đã nghe rồi: lần sau chỉ còn câu chỉ dẫn.
	assert_int(TutorialFlow.lines_for(_save.data, TutorialFlow.step(_save.data, GC.SCENE_HUB)).size()).is_equal(1)


func test_dialogue_file_covers_steps_and_is_translated() -> void:
	var dlg := TutorialFlow.dialogue()
	var steps: Dictionary = dlg["steps"]
	for id in ["hub_sortie", "sortie_story", "chapter_card", "map_stage", "stage_prepare", "party_go", "retry", "result_hub", "hub_supply",
			"supply_gacha", "recruit_starter", "recruit_done", "recruit_close", "hub_party", "sortie_party", "party_slot",
			"party_add", "party_confirm"]:
		assert_bool(steps.has(id)).override_failure_message("thiếu thoại bước " + id).is_true()
		for l: Dictionary in steps[id]:
			assert_str(tr(str(l["text"]))).is_not_equal(str(l["text"]))
			assert_str(tr(str(l["reply"]))).is_not_equal(str(l["reply"]))
	for k in [dlg["speaker_key"], dlg["speaker_title_key"], dlg["player_key"], "TUTORIAL_SKIP_TALK", "TUTORIAL_TAP_NEXT"]:
		assert_str(tr(str(k))).is_not_equal(str(k))
	# Mỗi id bước của TutorialFlow có câu chỉ dẫn đã dịch.
	var d := SaveSchema.default_data()
	assert_str(str(TutorialFlow.step(d, GC.SCENE_HUB)["id"])).is_equal("hub_sortie")
