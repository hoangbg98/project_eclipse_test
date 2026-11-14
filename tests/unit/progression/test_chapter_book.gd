extends GdUnitTestSuite
## Cốt truyện theo chương (owner 2026-11-14): 10–30 ải mỗi chương, part 10–15 ải, chương sau ≥ chương trước; ải chưa có
## màn chơi khóa "Sắp ra mắt"; huy chương = mục tiêu đã đạt; quà phần khi đủ 100% huy chương, nhận một lần.


func _data() -> Dictionary:
	return SaveSchema.default_data()


func test_structure_follows_owner_rules() -> void:
	var prev := 0
	var codes := {}
	for c: Dictionary in ChapterBook.chapters():
		var n := ChapterBook.stages_of(int(c["num"])).size()
		assert_int(n).is_between(10, 30)
		assert_int(n).is_greater_equal(prev)                       # chương sau ≥ chương trước
		prev = n
		for p: Dictionary in c["parts"]:
			assert_int((p["stages"] as Array).size()).is_between(10, 15)
			assert_str(tr(str(p["title"]))).is_not_equal(str(p["title"]))
		for s: Dictionary in ChapterBook.stages_of(int(c["num"])):
			assert_bool(codes.has(s["code"])).is_false()
			codes[s["code"]] = true
			assert_float(float(s["pos"][0])).is_less(float(c["map_width"]))
		assert_str(ChapterBook.art_path(str(c["map_image"]))).is_not_empty()
		assert_str(ChapterBook.art_path(str(c["card_image"]))).is_not_empty()
	assert_int(ChapterBook.chapters().size()).is_equal(7)
	assert_int(codes.size()).is_equal(137)
	# Mỗi chương nằm đúng một nhóm.
	var seen := {}
	for a: Dictionary in ChapterBook.arcs():
		assert_str(tr(str(a["title"]))).is_not_equal(str(a["title"]))
		for n in a["chapters"]:
			assert_bool(seen.has(int(n))).is_false()
			seen[int(n)] = true
	assert_int(seen.size()).is_equal(7)


func test_stage_states_and_progress() -> void:
	var d := _data()
	var b := ChapterBook.new(d)
	var s11 := ChapterBook.stage("1-1")
	assert_str(s11["stage_id"]).is_equal("stage_01")
	assert_str(b.state_of(s11)).is_equal(ChapterBook.STATE_OPEN)
	assert_str(b.state_of(ChapterBook.stage("1-2"))).is_equal(ChapterBook.STATE_SOON)
	assert_str(str(b.current_stage(1)["code"])).is_equal("1-1")
	assert_int(b.chapter_progress(1)).is_equal(0)
	d["progress"]["stages"]["stage_01"] = {"cleared": true, "objectives": ["time", "downs"]}
	assert_str(b.state_of(s11)).is_equal(ChapterBook.STATE_CLEARED)
	assert_int(b.medals(s11)).is_equal(2)
	assert_int(b.chapter_progress(1)).is_equal(10)
	assert_str(str(b.latest_arc()["id"])).is_equal("arc_01")


func test_locked_when_previous_not_cleared() -> void:
	var d := _data()
	var b := ChapterBook.new(d)
	# Giả lập ải 1-2 đã có màn chơi (đổi tạm dữ liệu tĩnh, trả lại cuối test).
	var real := ChapterBook.stage("1-2")
	real["stage_id"] = "stage_01_02"
	assert_str(b.state_of(real)).is_equal(ChapterBook.STATE_LOCKED)
	d["progress"]["stages"]["stage_01"] = {"cleared": true}
	assert_str(b.state_of(real)).is_equal(ChapterBook.STATE_OPEN)
	real["stage_id"] = ""


func test_part_chest_needs_all_medals_and_claims_once() -> void:
	var d := _data()
	var b := ChapterBook.new(d)
	var p := ChapterBook.part("ch01_p1")
	assert_int(b.part_percent(p)).is_equal(0)
	d["progress"]["stages"]["stage_01"] = {"cleared": true, "objectives": ["a", "b", "c"]}
	assert_int(b.part_percent(p)).is_equal(10)                     # 3 / 30 huy chương
	var prof := PlayerProfile.new(d)
	assert_str(b.claim_part("ch01_p1", prof)).is_equal(ChapterBook.CLAIM_NOT_READY)
	assert_str(b.claim_part("khong_co", prof)).is_equal(ChapterBook.CLAIM_UNKNOWN)
	# Giả lập đủ huy chương: mọi ải của phần dùng chung màn đã đạt 3 mục tiêu.
	for s: Dictionary in p["stages"]:
		s["stage_id"] = "stage_01"
	assert_int(b.part_percent(p)).is_equal(100)
	var gems := prof.inventory.currency("gems")
	assert_str(b.claim_part("ch01_p1", prof)).is_equal(ChapterBook.CLAIM_OK)
	assert_int(prof.inventory.currency("gems")).is_equal(gems + int(ChapterBook.data()["part_reward"]["gems"]))
	assert_bool(b.part_claimed("ch01_p1")).is_true()
	assert_str(b.claim_part("ch01_p1", prof)).is_equal(ChapterBook.CLAIM_DONE)
	assert_array(SaveSchema.sanitize(d)["progress"]["parts_claimed"]).is_equal(["ch01_p1"])
	for i in (p["stages"] as Array).size():                          # trả lại dữ liệu tĩnh cho test khác
		p["stages"][i]["stage_id"] = "stage_01" if i == 0 else ""
