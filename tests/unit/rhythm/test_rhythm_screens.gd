extends GdUnitTestSuite
## Màn chơi nhịp điệu (đồng hồ tay, tự chơi), màn ải nguyên liệu và danh sách bài Vô tận (máy chủ giả).

const STAGE_SCENE := preload("res://scenes/main/rhythm_stage.tscn")
const MATERIAL_SCENE := preload("res://scenes/main/rhythm_material_screen.tscn")
const SONGS_SCENE := preload("res://scenes/main/rhythm_song_list_screen.tscn")
const CACHE := "user://test_rhythm_screens_cache"

## Giữ máy chủ giả sống (Callable không giữ tham chiếu tới RefCounted).
var _servers: Array = []


func after_test() -> void:
	if DirAccess.dir_exists_absolute(CACHE):
		for f in DirAccess.get_files_at(CACHE):
			DirAccess.remove_absolute(CACHE.path_join(f))
		DirAccess.remove_absolute(CACHE)
	GameConfig.rhythm_song_id = ""
	GameConfig.rhythm_chart_key = ""
	GameConfig.rhythm_record_key = ""
	GameConfig.rhythm_boss = false
	GameConfig.rhythm_note_speed = 0.0
	GameConfig.rhythm_tutorial = false
	GameConfig.rhythm_intro_key = ""
	GameConfig.rhythm_kinds = []


func _chart() -> RhythmChart:
	return RhythmChart.from_dict({"format": 1, "song_id": "song_a", "difficulty": "easy", "bpm": 120, "notes": [
		{"t": 0.5, "lane": "up"}, {"t": 1.0, "lane": "down"}, {"t": 1.5, "lane": "both"},
		{"t": 2.0, "lane": "down", "kind": "hold", "dur": 1.0},
		{"t": 3.5, "lane": "up", "kind": "mash", "dur": 1.0, "hits": 5},
		{"t": 5.0, "lane": "up"},
	]})


func _stage(p: PlayerProfile, key := "rhythm_mat_01") -> RhythmStage:
	var s := STAGE_SCENE.instantiate() as RhythmStage
	s.setup(_chart(), null, key, "Test", key == "rhythm_mat_05")
	s.manual_clock = true
	s.save_enabled = false
	s.profile = p
	add_child(auto_free(s))
	return s


func test_autoplay_clears_with_s_and_rewards() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var s := _stage(p)
	s.autoplay = true
	var got: Array = []
	s.finished.connect(func(r: Dictionary) -> void: got.append(r))
	assert_object(s.find_child("Character", true, false)).is_not_null()
	s.advance(10.0)
	assert_int(got.size()).is_equal(1)
	assert_bool(s.result["cleared"]).is_true()
	assert_str(s.result["rank"]).is_equal("S")
	assert_int(int(s.result["counts"][RhythmJudge.PERFECT])).is_equal(s.chart.judgment_units())
	assert_bool(RhythmProgress.new(p).is_cleared("rhythm_mat_01")).is_true()
	assert_int(p.inventory.currency("gold")).is_greater(0)
	assert_object(s.find_child("ResultLayer", true, false)).is_not_null()
	assert_str((s.find_child("Rank", true, false) as Label).text).is_equal("S")


## Tốc độ của lượt: vòng chấm phóng theo, hitbox cùng làn không đè nhau.
func test_stage_speed_scales_ring_and_spacing() -> void:
	var s := STAGE_SCENE.instantiate() as RhythmStage
	var c := RhythmChart.from_dict({"format": 1, "notes": [{"t": 1.0, "lane": "up"}, {"t": 1.05, "lane": "up"}, {"t": 1.1, "lane": "down"}]})
	s.setup(c, null, "", "T", false, 1200.0)
	s.manual_clock = true
	s.save_enabled = false
	s.profile = PlayerProfile.new(SaveSchema.default_data())
	add_child(auto_free(s))
	var base := load("res://data/rhythm/rhythm_rules.tres") as RhythmRules
	assert_float(s.rules.note_speed).is_equal(1200.0)
	assert_float(s.rules.ring_radius).is_equal_approx(base.ring_radius * 1200.0 / base.note_speed, 0.001)
	assert_int(s.spacing_dropped).is_equal(1)
	assert_int(s.chart.notes.size()).is_equal(2)


## Hướng dẫn ải N-1: luyện từng bước (không mất HP), xong thì vào bài thật và chơi hết bài.
func test_tutorial_steps_then_real_song() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var s := STAGE_SCENE.instantiate() as RhythmStage
	s.setup(_chart(), null, "rhythm_mat_01", "Test")
	s.tutorial = true
	s.manual_clock = true
	s.save_enabled = false
	s.profile = p
	add_child(auto_free(s))
	assert_str(s.phase).is_equal("tutorial")
	assert_object(s.find_child("TutorialPanel", true, false)).is_not_null()
	assert_str(s.chart.song_id).is_equal("tutorial")
	# Không ấn gì: bước 1 làm lại, HP không mất.
	s.advance(12.0)
	assert_str(s.phase).is_equal("tutorial")
	assert_int(s.judge.hp).is_equal(s.judge.rules.max_hp)
	assert_str((s.find_child("Tut_title", true, false) as Label).text).is_equal(tr("RHYTHM_TUT_TITLE") % [1, 4])
	# Tự chơi: qua hết các bước rồi vào bài thật.
	s.autoplay = true
	s.advance(60.0)
	assert_str(s.phase).is_equal("play")
	assert_object(s.find_child("TutorialPanel", true, false)).is_null()
	s.advance(15.0)
	assert_bool(s.result.is_empty()).is_false()
	assert_bool(s.result["cleared"]).is_true()
	assert_int(int(s.result["counts"][RhythmJudge.PERFECT])).is_equal(_chart().judgment_units())


func test_tutorial_skip_and_intro_and_kinds() -> void:
	var s := STAGE_SCENE.instantiate() as RhythmStage
	s.setup(_chart(), null, "", "Test")
	s.tutorial = true
	s.intro_key = "RHYTHM_INTRO_HOLD"
	s.kinds = ["tap"]
	s.manual_clock = true
	s.save_enabled = false
	s.profile = PlayerProfile.new(SaveSchema.default_data())
	add_child(auto_free(s))
	s.skip_tutorial()
	assert_str(s.phase).is_equal("play")
	assert_float(s.now).is_equal(-(s.rules.lead_in_sec + RhythmStage.INTRO_EXTRA_SEC))   # đếm ngược dài hơn để đọc
	assert_bool((s.find_child("Intro", true, false) as Label).text != "").is_true()
	for n in s.chart.notes:
		assert_str(str(n["kind"])).is_equal(RhythmChart.KIND_TAP)   # ải chỉ có nốt ấn
	s.advance(0.1)
	assert_bool((s.find_child("Intro", true, false) as Label).visible).is_true()
	s.advance(6.0)
	assert_bool((s.find_child("Intro", true, false) as Label).visible).is_false()


## Nốt giữ dùng hình Rắn Ngân: đầu, thân, đuôi; trúng đầu thì cắn và đứng ở vòng chấm tới hết thân.
func test_hold_note_uses_serpent() -> void:
	var s := STAGE_SCENE.instantiate() as RhythmStage
	var c := RhythmChart.from_dict({"format": 1, "notes": [{"t": 1.0, "lane": "both", "kind": "hold", "dur": 1.0}]})
	s.setup(c, null, "", "T")
	s.manual_clock = true
	s.save_enabled = false
	s.autoplay = true
	s.profile = PlayerProfile.new(SaveSchema.default_data())
	add_child(auto_free(s))
	s.advance(2.5)   # lead-in 2 s => giây 0.5
	assert_object(s.find_child("RhythmSerpent_0_1", true, false)).is_not_null()
	assert_object(s.find_child("RhythmSerpent_0_2", true, false)).is_not_null()
	assert_object(s.find_child("RhythmSerpentBody_0_1", true, false)).is_not_null()
	assert_object(s.find_child("RhythmSerpentTail_0_2", true, false)).is_not_null()
	s.advance(0.7)   # đã trúng đầu
	var head := s.find_child("RhythmSerpent_0_1", true, false) as AnimatedSprite2D
	assert_str(str(head.animation)).is_equal("bite")
	assert_float(head.position.x).is_equal_approx(380.0, 1.0)
	s.advance(1.2)
	assert_int(int(s.judge.counts[RhythmJudge.PERFECT])).is_equal(2)


func test_idle_run_fails_or_misses_everything() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var s := _stage(p)
	s.advance(10.0)
	assert_bool(s.result.is_empty()).is_false()
	assert_int(int(s.result["counts"][RhythmJudge.PERFECT])).is_equal(0)
	assert_str(s.judge.rank()).is_equal("D")


func test_input_actions_drive_judge_and_pause() -> void:
	var s := _stage(PlayerProfile.new(SaveSchema.default_data()))
	s.advance(2.5)   # lead-in 2 s => giây 0.5 của bài
	var ev := InputEventAction.new()
	ev.action = &"rhythm_up"
	ev.pressed = true
	s._input(ev)
	s.advance(0.1)
	assert_str(s.judge.states[0]["result"]).is_equal(RhythmJudge.PERFECT)
	# Hai phím cùng làn: nhả một phím chưa tính là nhả.
	s.press_lane(RhythmChart.LANE_DOWN)
	s.press_lane(RhythmChart.LANE_DOWN)
	s.release_lane(RhythmChart.LANE_DOWN)
	assert_int(s.judge.held & RhythmChart.LANE_DOWN).is_equal(RhythmChart.LANE_DOWN)
	assert_bool(s.intercept_back()).is_true()   # Esc = tạm dừng
	assert_bool(s.paused).is_true()
	assert_object(s.find_child("PauseLayer", true, false)).is_not_null()
	var t := s.now
	s.advance(1.0)
	assert_float(s.now).is_equal(t)
	s.set_paused(false)
	assert_bool(s.paused).is_false()


func test_stage_without_download_shows_error() -> void:
	GameConfig.rhythm_song_id = "khong_co"
	GameConfig.rhythm_chart_key = "easy"
	var s := STAGE_SCENE.instantiate() as RhythmStage
	s.manual_clock = true
	s.save_enabled = false
	s.profile = PlayerProfile.new(SaveSchema.default_data())
	add_child(auto_free(s))
	assert_str(s.load_error).is_not_empty()
	assert_object(s.find_child("ErrorLayer", true, false)).is_not_null()


# ---------- Màn chọn ----------

class Srv:
	var catalog: Dictionary

	func fetch(url: String) -> Dictionary:
		await Engine.get_main_loop().process_frame
		if url.ends_with("catalog.json"):
			return {"ok": true, "code": 200, "body": JSON.stringify(catalog).to_utf8_buffer(), "error": ""}
		return {"ok": false, "code": 404, "body": PackedByteArray(), "error": "http_404"}


func _lib() -> RhythmLibrary:
	var srv := Srv.new()
	_servers.append(srv)
	var songs: Array = []
	for id in ["song_ember_steps", "song_gale_runner", "song_thunder_lane", "song_lumen_waltz", "song_eclipse_boss", "song_night_market"]:
		var charts := {}
		for k in ["easy", "normal", "hard"]:
			charts[k] = {"file": "%s_%s.json" % [id, k], "sha256": "x", "bytes": 10, "level": 3}
		if id == "song_eclipse_boss":
			charts["boss"] = {"file": id + "_boss.json", "sha256": "x", "bytes": 10, "level": 9}
		songs.append({"id": id, "title": id.to_upper(), "artist": "T", "audio": {"file": id + ".wav", "sha256": "x", "bytes": 100}, "charts": charts})
	srv.catalog = {"format": 1, "songs": songs}
	return RhythmLibrary.new("http://h/music/", srv.fetch, CACHE)


func _screen(scene: PackedScene, p: PlayerProfile) -> RhythmMaterialScreen:
	var s := scene.instantiate() as RhythmMaterialScreen
	s.profile = p
	s.save_enabled = false
	s.navigate_enabled = false
	s.library = _lib()
	add_child(auto_free(s))
	return s


## Chờ màn tải xong danh mục (tối đa 5 s).
func _wait_catalog(s: RhythmMaterialScreen) -> void:
	for i in 300:
		if s.catalog_state != "loading":
			return
		await get_tree().process_frame


func test_material_screen_cards_lock_and_download_failure() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var s := _screen(MATERIAL_SCENE, p)
	await _wait_catalog(s)
	assert_str(s.catalog_state).is_equal("online")
	for i in range(1, 6):
		assert_bool(s.card_buttons.has("rhythm_mat_0%d" % i)).is_true()
	assert_bool(s.card_buttons.has("endless")).is_true()
	await s.start_stage("rhythm_mat_02")
	assert_str(s.notice).is_equal(tr("RHYTHM_LOCKED_HINT"))
	s.open_endless()
	assert_str(s.notice).is_equal(tr("RHYTHM_ENDLESS_LOCKED"))
	await s.start_stage("rhythm_mat_01")   # máy chủ giả không có file nhạc => báo lỗi tải, không mở màn chơi
	assert_str(s.last_target).is_equal("")
	assert_bool(s.notice.begins_with(tr("RHYTHM_DOWNLOAD_FAILED").get_slice("(", 0))).is_true()


func test_material_screen_starts_cached_stage() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var s := _screen(MATERIAL_SCENE, p)
	await _wait_catalog(s)
	# Giả lập đã tải: ghi file vào cache và bỏ kiểm sha256.
	DirAccess.make_dir_recursive_absolute(CACHE)
	for info in [s.library.song("song_ember_steps")["audio"], s.library.chart_info("song_ember_steps", "easy")]:
		info["sha256"] = ""
		var f := FileAccess.open(CACHE.path_join(info["file"]), FileAccess.WRITE)
		f.store_string("x")
		f.close()
	await s.start_stage("rhythm_mat_01")
	assert_str(s.last_target).is_equal(GameConfig.SCENE_RHYTHM_STAGE)
	assert_str(GameConfig.rhythm_song_id).is_equal("song_ember_steps")
	assert_str(GameConfig.rhythm_chart_key).is_equal("easy")
	assert_str(GameConfig.rhythm_record_key).is_equal("rhythm_mat_01")
	assert_float(GameConfig.rhythm_note_speed).is_equal(RhythmProgress.new(p).note_speed("rhythm_mat_01"))
	assert_bool(GameConfig.rhythm_tutorial).is_true()   # lần đầu chơi N-1 có hướng dẫn
	assert_array(GameConfig.rhythm_kinds).is_equal(["tap"])


func test_endless_list_rows_tabs_and_favorites() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var prog := RhythmProgress.new(p)
	for i in range(1, 6):
		prog.finish("rhythm_mat_0%d" % i, {"cleared": true, "score": 1, "rank": "C"})
	prog.finish(RhythmProgress.endless_key("song_gale_runner", "normal"), {"cleared": true, "score": 4321, "rank": "A"})
	var s := _screen(SONGS_SCENE, p) as RhythmSongListScreen
	await _wait_catalog(s)
	assert_int(s.row_buttons.size()).is_equal(6)
	var row := s.find_child("Row_song_gale_runner", true, false)
	assert_object(row).is_not_null()
	var texts: Array = []
	for c in row.get_children():
		if c is Label:
			texts.append((c as Label).text)
	assert_bool(texts.has("♛♛♔")).is_true()     # hạng A = 2 vương miện
	assert_bool(texts.has(tr("RHYTHM_BEST_SCORE") % 4321)).is_true()
	s.toggle_favorite("song_thunder_lane")
	assert_bool(prog.is_favorite("song_thunder_lane")).is_true()
	s._select_tab("fav")
	assert_int(s.row_buttons.size()).is_equal(1)
	s._select_tab("hard")
	assert_str(s.difficulty).is_equal("hard")
	assert_int(s.row_buttons.size()).is_equal(6)
