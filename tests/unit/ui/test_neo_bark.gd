extends GdUnitTestSuite
## Băng thoại trong trận (owner 2026-11-14): câu cốt truyện theo sự kiện màn + NEO gợi ý cách dùng chiêu; mỗi câu
## một lần; nhân vật không có trong đội thì NEO nói thay; chữ checkpoint là "điểm neo".

const KNOWN_EVENTS := ["stage_start", "wave_started", "wave_cleared", "checkpoint", "boss_started", "boss_phase",
		"skill_ready", "hit_taken", "sc_high", "link_glow", "reaction"]


func _bark() -> NeoBark:
	var b: NeoBark = auto_free(NeoBark.new())
	b.test_stage_id = "stage_01"
	add_child(b)
	return b


func test_data_valid_and_translated() -> void:
	var d := NeoBark.load_data()
	assert_bool(d.has("lines") and d.has("settings")).is_true()
	var ids := {}
	for l: Dictionary in d["lines"]:
		var id := str(l["id"])
		assert_bool(ids.has(id)).override_failure_message("trùng id " + id).is_false()
		ids[id] = true
		assert_bool(str(l["on"]) in KNOWN_EVENTS).override_failure_message("sự kiện lạ " + str(l["on"])).is_true()
		for k in ["text", "neo_text"]:
			if l.has(k):
				assert_str(tr(str(l[k]))).is_not_equal(str(l[k]))
		var spk := str(l.get("speaker", "neo"))
		if spk != "neo":
			assert_bool(ResourceLoader.exists(PlayerProfile.CHARACTER_DATA % spk)).is_true()
			assert_bool(l.has("neo_text")).override_failure_message(id + ": câu nhân vật cần neo_text").is_true()
	# Đủ 7 gợi ý chiêu của STORY_PROPOSAL D4b (+ phản ứng nguyên tố).
	for h in ["hint_skill", "hint_weapon", "hint_ultimate", "hint_dodge", "hint_hold", "hint_stun", "hint_link"]:
		assert_bool(ids.has(h)).override_failure_message("thiếu " + h).is_true()


func test_checkpoint_text_is_anchor_point() -> void:
	var old := TranslationServer.get_locale()
	TranslationServer.set_locale("vi")
	var vi := tr("STAGE_CHECKPOINT")
	TranslationServer.set_locale("en")
	var en := tr("STAGE_CHECKPOINT")
	TranslationServer.set_locale(old)
	assert_str(vi).is_equal("Đã cắm điểm neo")
	assert_str(en).is_equal("Anchor point set")


func test_story_line_neo_speaks_when_character_absent() -> void:
	var b := _bark()
	b.test_party = PackedStringArray(["char_fire_01"])
	b.fire("wave_started", 0)                      # câu của Kazeyumi, Kazeyumi không có trong đội
	assert_int(b.pending.size()).is_equal(1)
	var line: Dictionary = b.pending[0]["line"]
	assert_str(line["speaker"]).is_equal("neo")
	assert_str(line["name"]).is_equal(tr("TUTORIAL_AI_NAME"))
	assert_str(line["text"]).is_equal(tr("BARK_CH01_WAVE1_NEO"))


func test_story_line_character_speaks_when_in_party() -> void:
	var b := _bark()
	b.test_party = PackedStringArray(["char_fire_01", "char_wind_01"])
	b.fire("wave_started", 0)
	var line: Dictionary = b.pending[0]["line"]
	assert_str(line["speaker"]).is_equal("char_wind_01")
	assert_str(line["text"]).is_equal(tr("BARK_CH01_WAVE1"))
	assert_str(line["name"]).is_equal(tr("CHAR_WIND_01"))


func test_each_line_once_and_args_filter() -> void:
	var b := _bark()
	b.fire("wave_started", 5)                      # không có câu cho đợt 6
	assert_int(b.pending.size()).is_equal(0)
	b.fire("checkpoint", 1)
	b.fire("checkpoint", 1)
	assert_int(b.pending.size()).is_equal(1)
	assert_bool(b.was_seen("ch01_cp1")).is_true()
	b.test_stage_id = "stage_khac"                  # câu cốt truyện chỉ cho đúng màn
	b.fire("checkpoint", 2)
	assert_int(b.pending.size()).is_equal(1)


func test_skill_hints_match_action_and_key_label() -> void:
	var b := _bark()
	b.fire("skill_ready", "weapon")
	assert_int(b.pending.size()).is_equal(1)
	var text := str(b.pending[0]["line"]["text"])
	assert_str(text).contains(NeoBark.key_label("weapon"))
	assert_bool(b.was_seen("hint_skill")).is_false()
	b.fire("skill_ready", "weapon")
	assert_int(b.pending.size()).is_equal(1)
	# Máy tính: "phím <phím trong InputMap>".
	var key := ""
	for e in InputMap.action_get_events("skill"):
		if e is InputEventKey:
			var k := e as InputEventKey
			key = OS.get_keycode_string(k.keycode if k.keycode != KEY_NONE else k.physical_keycode)
			break
	if key != "":
		assert_str(NeoBark.key_label("skill")).contains(key)


func test_delayed_lines_show_in_order() -> void:
	var b := _bark()
	b.fire("boss_phase", 2)                        # 3 câu, trễ 0 / 2.8 / 6.0 s
	assert_int(b.pending.size()).is_equal(3)
	assert_float(float(b.pending[1]["at"]) - float(b.pending[0]["at"])).is_equal_approx(2.8, 0.01)
	b.show_line(b.pending.pop_front()["line"])
	assert_str((b.find_child("Line", true, false) as Label).text).is_equal(tr("BARK_CH01_PHASE2"))
	assert_bool((b.find_child("AiCore", true, false) as Control).visible).is_true()
