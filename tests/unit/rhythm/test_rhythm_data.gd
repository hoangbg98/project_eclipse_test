extends GdUnitTestSuite
## Bản nốt (RhythmChart), thư viện bài tải từ máy chủ (RhythmLibrary, máy chủ giả) và tiến độ / thưởng (RhythmProgress).

const CACHE := "user://test_rhythm_cache"


func after_test() -> void:
	_rm(CACHE)


func _rm(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)


# ---------- RhythmChart ----------

func test_chart_parse_sort_and_drop_overlaps() -> void:
	var c := RhythmChart.from_json_text(JSON.stringify({"format": 1, "song_id": "s", "difficulty": "easy", "level": 3,
		"bpm": 128, "notes": [
			{"t": 3.0, "lane": "down"},
			{"t": 1.0, "lane": "up", "kind": "hold", "dur": 1.5},
			{"t": 2.0, "lane": "up"},                          # nằm trong nốt giữ => bỏ
			{"t": 4.0, "lane": "sideways"},                    # làn sai => bỏ
			{"t": 5.0, "lane": "both", "kind": "mash", "dur": 1.0},
			{"t": 7.0, "lane": "up", "kind": "hold", "dur": 0},  # giữ không có độ dài => bỏ
		]}))
	assert_bool(c.is_valid()).is_true()
	assert_int(c.notes.size()).is_equal(3)
	assert_int(c.dropped).is_equal(3)
	assert_float(float(c.notes[0]["t"])).is_equal(1.0)
	assert_int(int(c.notes[2]["hits"])).is_greater(0)
	assert_int(c.judgment_units()).is_equal(4)
	assert_float(c.last_note_end()).is_equal(6.0)
	assert_str(RhythmChart.lane_name(RhythmChart.LANE_BOTH)).is_equal("both")


func test_chart_rejects_bad_input() -> void:
	assert_bool(RhythmChart.from_json_text("not json").is_valid()).is_false()
	assert_bool(RhythmChart.from_dict({"format": 99, "notes": []}).is_valid()).is_false()
	assert_bool(RhythmChart.load_file("user://khong_co.json").is_valid()).is_false()


# ---------- RhythmLibrary (máy chủ giả) ----------

class FakeServer:
	var files: Dictionary = {}   # url -> PackedByteArray
	var down := false
	var requests: Array = []

	func fetch(url: String) -> Dictionary:
		requests.append(url)
		await Engine.get_main_loop().process_frame
		if down:
			return {"ok": false, "code": 0, "body": PackedByteArray(), "error": "network"}
		if not files.has(url):
			return {"ok": false, "code": 404, "body": PackedByteArray(), "error": "http_404"}
		return {"ok": true, "code": 200, "body": files[url], "error": ""}


func _sha(b: PackedByteArray) -> String:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(b)
	return h.finish().hex_encode()


func _server() -> FakeServer:
	var srv := FakeServer.new()
	var chart := JSON.stringify({"format": 1, "song_id": "song_a", "difficulty": "easy", "notes": [{"t": 1.0, "lane": "up"}]}).to_utf8_buffer()
	var audio := PackedByteArray([1, 2, 3, 4, 5])
	srv.files["http://h/music/song_a_easy.json"] = chart
	srv.files["http://h/music/song_a.wav"] = audio
	srv.files["http://h/music/catalog.json"] = JSON.stringify({"format": 1, "songs": [
		{"id": "song_a", "title": "A", "audio": {"file": "song_a.wav", "sha256": _sha(audio), "bytes": 5},
			"charts": {"easy": {"file": "song_a_easy.json", "sha256": _sha(chart), "bytes": chart.size(), "level": 2}}},
		{"id": "evil", "title": "E", "audio": {"file": "../x.wav"}, "charts": {}},
	]}).to_utf8_buffer()
	return srv


func test_library_download_cache_and_offline() -> void:
	var srv := _server()
	var lib := RhythmLibrary.new("http://h/music", srv.fetch, CACHE)
	assert_bool(await lib.refresh_catalog()).is_true()
	assert_bool(lib.from_cache).is_false()
	assert_int(lib.songs().size()).is_equal(1)       # bài có tên file nguy hiểm bị bỏ
	assert_bool(lib.is_cached("song_a", "easy")).is_false()
	assert_int(lib.missing_bytes("song_a", "easy")).is_greater(5)
	var res: Dictionary = await lib.ensure("song_a", "easy")
	assert_bool(res["ok"]).is_true()
	assert_bool(lib.is_cached("song_a", "easy")).is_true()
	assert_int(lib.load_chart("song_a", "easy").notes.size()).is_equal(1)
	# Mất mạng: danh mục lấy từ bản đã lưu, bài đã tải vẫn chơi được, không tải lại.
	srv.down = true
	var off := RhythmLibrary.new("http://h/music/", srv.fetch, CACHE)
	assert_bool(await off.refresh_catalog()).is_true()
	assert_bool(off.from_cache).is_true()
	assert_bool(off.is_cached("song_a", "easy")).is_true()
	var n := srv.requests.size()
	assert_bool((await off.ensure("song_a", "easy"))["ok"]).is_true()
	assert_int(srv.requests.size()).is_equal(n)


func test_library_checksum_and_errors() -> void:
	var srv := _server()
	srv.files["http://h/music/song_a.wav"] = PackedByteArray([9, 9, 9])   # khác sha256 trong danh mục
	var lib := RhythmLibrary.new("http://h/music/", srv.fetch, CACHE)
	await lib.refresh_catalog()
	var res: Dictionary = await lib.ensure("song_a", "easy")
	assert_bool(res["ok"]).is_false()
	assert_str(res["error"]).is_equal("checksum")
	assert_bool(lib.is_cached("song_a", "easy")).is_false()
	assert_str((await lib.ensure("khong_co", "easy"))["error"]).is_equal("unknown_song")
	srv.down = true
	var none := RhythmLibrary.new("http://h/music/", srv.fetch, CACHE + "_empty")
	assert_bool(await none.refresh_catalog()).is_false()
	assert_bool(RhythmLibrary.safe_name("a/b.wav")).is_false()
	assert_bool(RhythmLibrary.safe_name("..")).is_false()
	assert_bool(RhythmLibrary.safe_name("song_a-1.ogg")).is_true()


# ---------- RhythmProgress ----------

func test_progress_unlock_rewards_and_endless() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var prog := RhythmProgress.new(p)
	var stages := prog.stages()
	assert_int(stages.size()).is_equal(5)
	assert_bool(bool(stages[4]["boss"])).is_true()
	assert_str(str(stages[4]["chart"])).is_equal("boss")
	assert_bool(prog.is_unlocked("rhythm_mat_01")).is_true()
	assert_bool(prog.is_unlocked("rhythm_mat_02")).is_false()
	assert_bool(prog.endless_unlocked()).is_false()
	# Thua: không thưởng, không mở ải sau.
	var lost := prog.finish("rhythm_mat_01", {"cleared": false, "score": 999})
	assert_dict(lost["rewards"]).is_empty()
	assert_bool(prog.is_unlocked("rhythm_mat_02")).is_false()
	var gold0 := p.inventory.currency("gold")
	var won := prog.finish("rhythm_mat_01", {"cleared": true, "score": 5000, "rank": "S", "max_combo": 80, "accuracy": 0.97})
	assert_bool(won["first_clear"]).is_true()
	assert_bool(won["new_best"]).is_true()
	var base: Dictionary = prog.stage("rhythm_mat_01")["rewards"]
	var mult := float(prog.defs["rank_multiplier"]["S"])
	assert_int(p.inventory.currency("gold") - gold0).is_equal(int(floor(int(base["gold"]) * mult)))
	assert_dict(won["first_clear_rewards"]).is_not_empty()
	assert_bool(prog.is_unlocked("rhythm_mat_02")).is_true()
	assert_str(prog.best_rank("rhythm_mat_01")).is_equal("S")
	# Lần sau điểm thấp hơn: giữ kỷ lục, không còn thưởng lần đầu.
	var again := prog.finish("rhythm_mat_01", {"cleared": true, "score": 100, "rank": "B"})
	assert_bool(again["first_clear"]).is_false()
	assert_bool(again["new_best"]).is_false()
	assert_str(prog.best_rank("rhythm_mat_01")).is_equal("S")
	assert_int(int(prog.record("rhythm_mat_01")["plays"])).is_equal(3)
	for i in range(2, 6):
		prog.finish("rhythm_mat_0%d" % i, {"cleared": true, "score": 1, "rank": "C"})
	assert_bool(prog.endless_unlocked()).is_true()
	var key := RhythmProgress.endless_key("song_x", "hard")
	assert_dict(prog.base_rewards(key)).is_not_empty()
	assert_dict(prog.finish(key, {"cleared": true, "score": 1, "rank": "A"})["rewards"]).is_not_empty()
	assert_bool(prog.toggle_favorite("song_x")).is_true()
	assert_bool(prog.is_favorite("song_x")).is_true()
	assert_bool(prog.toggle_favorite("song_x")).is_false()


func test_save_keeps_rhythm_data() -> void:
	var d := SaveSchema.default_data()
	d["rhythm"]["records"]["rhythm_mat_01"] = {"cleared": true, "best_score": 12}
	d["rhythm"]["favorites"] = ["song_a"]
	var clean := SaveSchema.sanitize(d)
	assert_bool(bool(clean["rhythm"]["records"]["rhythm_mat_01"]["cleared"])).is_true()
	assert_array(clean["rhythm"]["favorites"]).is_equal(["song_a"])
	var old := SaveSchema.default_data()
	old.erase("rhythm")   # save cũ chưa có mục này
	assert_dict(SaveSchema.sanitize(old)["rhythm"]["records"]).is_empty()


func test_stage_speeds_increase_to_boss() -> void:
	var prog := RhythmProgress.new(PlayerProfile.new(SaveSchema.default_data()))
	var prev := 0.0
	for s in prog.stages():
		var sp := prog.note_speed(str(s["id"]))
		assert_float(sp).is_greater(prev)
		prev = sp
	assert_float(prog.note_speed(RhythmProgress.endless_key("x", "hard"))).is_greater(
			prog.note_speed(RhythmProgress.endless_key("x", "easy")))
	assert_float(prog.note_speed("khong_co")).is_equal(0.0)
	# Ải đầu: chỉ nốt ấn, có hướng dẫn; ải 2 giới thiệu Rắn Ngân.
	assert_array(prog.stage("rhythm_mat_01").get("kinds", [])).is_equal(["tap"])
	assert_bool(bool(prog.stage("rhythm_mat_01").get("tutorial", false))).is_true()
	assert_str(str(prog.stage("rhythm_mat_02").get("intro_key", ""))).is_not_empty()
	var tut: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rhythm/tutorial.json"))
	assert_bool(tut is Dictionary and tut["steps"].size() >= 3).is_true()
