extends GdUnitTestSuite
## Mục tiêu chiến đấu (owner 2026-11-14): đọc từ dữ liệu màn, chấm điểm theo số liệu trận, cộng vàng.

const OBJS := [
	{"id": "time", "type": "time_max", "value": 300, "gold": 300},
	{"id": "hits", "type": "hits_taken_max", "value": 25, "gold": 300},
	{"id": "dmg", "type": "damage_taken_max", "value": 2000, "gold": 100},
	{"id": "downs", "type": "downs_max", "value": 0, "gold": 400},
	{"id": "bad", "type": "unknown", "value": 1, "gold": 999},
	{"type": "time_max", "value": 1},
]


func test_list_of_skips_invalid_entries() -> void:
	var l := BattleObjectives.list_of({"objectives": OBJS})
	assert_int(l.size()).is_equal(4)
	assert_int(BattleObjectives.list_of({}).size()).is_equal(0)
	assert_int(BattleObjectives.list_of({"objectives": "x"}).size()).is_equal(0)


func test_evaluate_and_gold() -> void:
	var l := BattleObjectives.list_of({"objectives": OBJS})
	var r := BattleObjectives.evaluate(l, {"time_sec": 300.0, "hits_taken": 26, "damage_taken": 1500, "downs": 0})
	assert_array(r.map(func(o: Dictionary) -> bool: return o["met"])).is_equal([true, false, true, true])
	assert_int(BattleObjectives.gold_of(r)).is_equal(800)
	var none := BattleObjectives.evaluate(l, {"time_sec": 301.0, "hits_taken": 99, "damage_taken": 9999, "downs": 2})
	assert_int(BattleObjectives.gold_of(none)).is_equal(0)


func test_counters() -> void:
	var o := BattleObjectives.new()
	var res := DamageCalculator.Result.new()
	res.amount = 120
	o._on_damaged(res, null)
	o._on_damaged(res, null)
	var zero := DamageCalculator.Result.new()
	o._on_damaged(zero, null)            # đòn 0 sát thương (khiên...) không tính
	o._on_dot_damaged(30, "burn")
	o._on_member_down(null)
	assert_dict(o.stats(12.0)).is_equal({"time_sec": 12.0, "hits_taken": 2, "damage_taken": 270, "downs": 1})


func test_describe_uses_translation() -> void:
	assert_str(BattleObjectives.describe(OBJS[0])).contains("5:00")
	assert_str(BattleObjectives.describe(OBJS[1])).contains("25")
	assert_str(BattleObjectives.describe(OBJS[3])).is_equal(tr("OBJ_NO_DOWNS"))
	assert_str(BattleObjectives.describe({"type": "downs_max", "value": 1})).is_equal(tr("OBJ_DOWNS_MAX") % 1)


func test_stage_01_has_objectives() -> void:
	var data := StageMap.load_from("res://data/stages/stage_01.json").data
	var l := BattleObjectives.list_of(data)
	assert_int(l.size()).is_equal(3)
	for o in l:
		assert_int(int(o["gold"])).is_greater(0)
