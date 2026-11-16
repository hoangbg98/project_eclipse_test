extends GdUnitTestSuite
## Bộ chấm chế độ nhịp điệu (M10): đúng một trong 3 lựa chọn (trên / dưới / cả hai), giữ, ấn liên tục, HP, combo,
## fever, hạng. Luật lấy từ data/rhythm/rhythm_rules.tres.

const UP := RhythmChart.LANE_UP
const DOWN := RhythmChart.LANE_DOWN
const BOTH := RhythmChart.LANE_BOTH

var rules: RhythmRules


func before_test() -> void:
	rules = load("res://data/rhythm/rhythm_rules.tres") as RhythmRules


func _chart(notes: Array) -> RhythmChart:
	return RhythmChart.from_dict({"format": 1, "song_id": "t", "difficulty": "normal", "bpm": 120, "notes": notes})


func _judge(notes: Array) -> RhythmJudge:
	return RhythmJudge.new(rules, _chart(notes))


func _tap(j: RhythmJudge, lane: int, t: float) -> void:
	j.press(lane, t)
	j.release(lane, t + 0.01)


func test_rules_data() -> void:
	assert_float(rules.ring_radius).is_greater(0.0)
	assert_float(rules.note_speed).is_greater(0.0)
	assert_float(rules.perfect_overlap).is_greater(rules.great_overlap)
	assert_float(rules.great_overlap).is_equal(0.75)
	assert_float(rules.good_overlap).is_equal(0.5)
	assert_float(rules.chord_window).is_greater(0.0)
	assert_int(rules.max_hp).is_greater(0)


## Độ chồng hai hình tròn cùng bán kính: trùng tâm = 1, cách 2R = 0 (chỉ chạm).
func test_overlap_geometry() -> void:
	assert_float(RhythmRules.overlap_fraction(0.0, 72.0)).is_equal_approx(1.0, 0.0001)
	assert_float(RhythmRules.overlap_fraction(144.0, 72.0)).is_equal(0.0)
	assert_float(RhythmRules.overlap_fraction(-36.0, 72.0)).is_equal(RhythmRules.overlap_fraction(36.0, 72.0))
	var prev := 1.1
	for d in range(0, 150, 10):
		var f := RhythmRules.overlap_fraction(float(d), 72.0)
		assert_float(f).is_less(prev)   # càng xa càng ít chồng
		prev = f
	var t := rules.offset_for_overlap(0.75)
	assert_float(RhythmRules.overlap_fraction(rules.distance_at(t), rules.ring_radius)).is_equal_approx(0.75, 0.001)


## 5 mức theo độ khớp hitbox với vòng: khít, ≥ 3/4, ≥ 1/2, đã qua viền, chỉ chạm viền ngoài; xa hơn = chưa chạm.
func test_grade_by_overlap() -> void:
	var t_perfect := rules.offset_for_overlap(rules.perfect_overlap)
	var t_great := rules.offset_for_overlap(rules.great_overlap)
	var t_good := rules.offset_for_overlap(rules.good_overlap)
	var t_touch := 2.0 * rules.ring_radius / rules.note_speed
	assert_float(t_perfect).is_less(t_great)
	assert_float(t_great).is_less(t_good)
	assert_float(t_good).is_less(t_touch)
	assert_str(rules.grade(0.0)).is_equal("perfect")
	assert_str(rules.grade(t_perfect * 0.9)).is_equal("perfect")
	assert_str(rules.grade(-t_perfect * 0.9)).is_equal("perfect")   # sớm hay trễ như nhau
	assert_str(rules.grade((t_perfect + t_great) * 0.5)).is_equal("great")
	assert_str(rules.grade((t_great + t_good) * 0.5)).is_equal("good")
	assert_str(rules.grade((t_good + t_touch) * 0.5)).is_equal("normal")
	assert_str(rules.grade(t_touch + rules.ring_rim * 0.5 / rules.note_speed)).is_equal("miss")
	assert_str(rules.grade(rules.reach_sec() + 0.01)).is_equal("")


func test_tap_grades_combo_and_late_miss() -> void:
	var t_great := (rules.offset_for_overlap(rules.perfect_overlap) + rules.offset_for_overlap(rules.great_overlap)) * 0.5
	var t_good := (rules.offset_for_overlap(rules.great_overlap) + rules.offset_for_overlap(rules.good_overlap)) * 0.5
	var t_normal := (rules.offset_for_overlap(rules.good_overlap) + 2.0 * rules.ring_radius / rules.note_speed) * 0.5
	var t_rim := (2.0 * rules.ring_radius + rules.ring_rim * 0.5) / rules.note_speed
	var j := _judge([{"t": 1.0, "lane": "up"}, {"t": 2.0, "lane": "down"}, {"t": 3.0, "lane": "up"},
			{"t": 4.0, "lane": "down"}, {"t": 5.0, "lane": "up"}, {"t": 6.0, "lane": "down"}])
	_tap(j, UP, 1.0)
	_tap(j, DOWN, 2.0 + t_great)
	_tap(j, UP, 3.0 - t_good)
	_tap(j, DOWN, 4.0 + t_normal)
	j.update(4.5)
	assert_array([j.states[0]["result"], j.states[1]["result"], j.states[2]["result"], j.states[3]["result"]]).is_equal(
			[RhythmJudge.PERFECT, RhythmJudge.GREAT, RhythmJudge.GOOD, RhythmJudge.NORMAL])
	assert_int(j.combo).is_equal(4)
	assert_int(j.hp).is_equal(rules.max_hp)
	assert_int(j.score).is_greater(rules.score_perfect + rules.score_great + rules.score_good + rules.score_normal - 1)
	_tap(j, UP, 5.0 - t_rim)   # chỉ chạm viền ngoài
	j.update(5.5)
	assert_str(j.states[4]["result"]).is_equal(RhythmJudge.MISS)
	assert_int(j.combo).is_equal(0)
	assert_int(j.hp).is_equal(rules.max_hp - rules.miss_damage)
	j.update(6.0 + rules.reach_sec() + 0.01)   # để trôi qua
	assert_str(j.states[5]["result"]).is_equal(RhythmJudge.MISS)
	assert_bool(j.is_finished()).is_true()
	assert_float(j.accuracy()).is_equal_approx((1.0 + 0.75 + 0.5 + 0.25) / 6.0, 0.0001)


func test_wrong_lane_costs_hp() -> void:
	var j := _judge([{"t": 1.0, "lane": "up"}])
	_tap(j, DOWN, 1.0)
	j.update(1.5)
	assert_str(j.states[0]["result"]).is_equal(RhythmJudge.WRONG)
	assert_int(j.hp).is_equal(rules.max_hp - rules.wrong_damage)
	assert_int(j.counts[RhythmJudge.WRONG]).is_equal(1)


func test_both_keys_on_single_note_is_wrong() -> void:
	var j := _judge([{"t": 1.0, "lane": "down"}])
	j.press(DOWN, 1.0)
	j.press(UP, 1.02)   # trong chord_window: chọn "cả hai" cho nốt chỉ cần dưới
	j.update(1.5)
	assert_str(j.states[0]["result"]).is_equal(RhythmJudge.WRONG)


func test_single_key_on_both_note_is_wrong_and_chord_is_hit() -> void:
	var j := _judge([{"t": 1.0, "lane": "both"}, {"t": 2.0, "lane": "both"}])
	j.press(UP, 1.0)
	j.update(1.0 + rules.chord_window + 0.01)
	assert_str(j.states[0]["result"]).is_equal(RhythmJudge.WRONG)
	j.press(DOWN, 2.0)
	j.press(UP, 2.03)
	assert_str(j.states[1]["result"]).is_equal(RhythmJudge.PERFECT)


func test_early_press_outside_window_is_free() -> void:
	var j := _judge([{"t": 2.0, "lane": "up"}])
	var empties: Array = []
	j.empty_press.connect(func(l: int) -> void: empties.append(l))
	_tap(j, DOWN, 1.0)
	assert_int(j.hp).is_equal(rules.max_hp)
	assert_array(empties).is_equal([DOWN])
	_tap(j, UP, 2.0)
	j.update(2.5)
	assert_str(j.states[0]["result"]).is_equal(RhythmJudge.PERFECT)


func test_hold_full_and_broken() -> void:
	var j := _judge([{"t": 1.0, "lane": "down", "kind": "hold", "dur": 1.0},
			{"t": 3.0, "lane": "down", "kind": "hold", "dur": 1.0}])
	j.press(DOWN, 1.0)
	j.update(1.5)
	assert_int(int(j.states[0]["state"])).is_equal(1)
	j.update(2.01)
	assert_int(j.counts[RhythmJudge.PERFECT]).is_equal(2)   # đầu + cuối
	j.release(DOWN, 2.02)
	j.press(DOWN, 3.0)
	j.release(DOWN, 3.4)    # thả sớm
	assert_int(j.counts[RhythmJudge.PERFECT]).is_equal(3)
	assert_int(j.counts[RhythmJudge.MISS]).is_equal(1)
	assert_int(j.hp).is_equal(rules.max_hp - rules.hold_break_damage)
	assert_bool(j.is_finished()).is_true()
	assert_int(j.chart.judgment_units()).is_equal(4)


func test_hold_both_lanes_needs_both_held() -> void:
	var j := _judge([{"t": 1.0, "lane": "both", "kind": "hold", "dur": 1.0}])
	j.press(UP, 1.0)
	j.press(DOWN, 1.01)
	j.release(UP, 1.5)
	assert_int(j.counts[RhythmJudge.MISS]).is_equal(1)


func test_mash_ratios() -> void:
	var j := _judge([{"t": 1.0, "lane": "up", "kind": "mash", "dur": 1.0, "hits": 6},
			{"t": 3.0, "lane": "both", "kind": "mash", "dur": 1.0, "hits": 6},
			{"t": 5.0, "lane": "down", "kind": "mash", "dur": 1.0, "hits": 6}])
	for k in 6:
		_tap(j, UP, 1.0 + k * 0.1)
	j.update(2.1)
	assert_str(j.states[0]["result"]).is_equal(RhythmJudge.PERFECT)
	for k in 3:   # "cả hai": làn nào cũng tính
		_tap(j, UP if k % 2 == 0 else DOWN, 3.0 + k * 0.1)
	j.update(4.1)
	assert_str(j.states[1]["result"]).is_equal(RhythmJudge.GREAT)
	_tap(j, DOWN, 5.0)
	j.update(6.1)
	assert_str(j.states[2]["result"]).is_equal(RhythmJudge.MISS)
	assert_int(j.score).is_greater(0)


func test_mash_wrong_lane_start() -> void:
	var j := _judge([{"t": 1.0, "lane": "up", "kind": "mash", "dur": 1.0, "hits": 4}])
	_tap(j, DOWN, 1.0)
	assert_str(j.states[0]["result"]).is_equal(RhythmJudge.WRONG)


func test_fail_when_hp_zero_and_rank() -> void:
	var notes: Array = []
	for i in 20:
		notes.append({"t": 1.0 + i * 0.5, "lane": "up"})
	var j := _judge(notes)
	var failed := [false]
	j.failed.connect(func() -> void: failed[0] = true)
	j.update(20.0)
	assert_bool(j.is_failed).is_true()
	assert_bool(failed[0]).is_true()
	assert_bool(j.is_finished()).is_true()
	assert_str(j.rank()).is_equal("D")
	# Toàn Hoàn hảo => S, 3 vương miện.
	var k := _judge(notes)
	for n in notes:
		_tap(k, UP, float(n["t"]))
	k.update(20.0)
	assert_float(k.accuracy()).is_equal(1.0)
	assert_str(k.rank()).is_equal("S")
	assert_int(RhythmJudge.crowns_of(k.rank())).is_equal(3)
	assert_int(k.max_combo).is_equal(20)


func test_fever_and_combo_bonus() -> void:
	var notes: Array = []
	var need := int(ceil(rules.fever_max / rules.fever_gain_perfect))
	for i in need + 2:
		notes.append({"t": 1.0 + i * 0.3, "lane": "down"})
	var j := _judge(notes)
	var started := [false]
	j.fever_started.connect(func(_u: float) -> void: started[0] = true)
	for i in need:
		_tap(j, DOWN, float(notes[i]["t"]))
	j.update(float(notes[need - 1]["t"]) + 0.1)
	assert_bool(started[0]).is_true()
	assert_bool(j.in_fever()).is_true()
	var before := j.score
	_tap(j, DOWN, float(notes[need]["t"]))
	j.update(float(notes[need]["t"]) + 0.1)
	assert_int(j.score - before).is_greater(rules.score_perfect)
