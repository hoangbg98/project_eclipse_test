extends GdUnitTestSuite
## Màn 1-4 "Vách Lò Mẹ" (tools/stages/gen_stage_01_04.py): dữ liệu, hố có platform bắc qua, qua màn bằng goal_col
## sau khi hạ hết đợt.

const STAGE_SCENE := preload("res://scenes/stages/stage.tscn")
const SAVE_DIR := "user://test_saves_stage_01_04"

var _stage: StageController
var _save: Node
var _old_store: SaveStore
var _old_data: Dictionary


func before_test() -> void:
	_save = get_tree().root.get_node("SaveService")
	_old_store = _save.store
	_old_data = _save.data
	_save.store = SaveStore.new(SAVE_DIR)
	_save.store.delete_all()
	_save.data = TestTeam.three()


func after_test() -> void:
	Engine.time_scale = 1.0
	_save.store.delete_all()
	DirAccess.remove_absolute(SAVE_DIR)
	_save.store = _old_store
	_save.data = _old_data


func _setup() -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.use_selected_stage = false
	_stage.stage_id = "stage_01_04"
	add_child(_stage)
	_stage.party.use_player_input = false
	for m in _stage.party.members:
		m.controller.use_player_input = false
	await _frames(20)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _teleport_col(col: int) -> void:
	_stage.player.global_position = _stage.map.ground_feet(col)
	_stage.player.velocity = Vector2.ZERO
	await _frames(3)


func test_stage_data_is_valid() -> void:
	var m := StageMap.load_from("res://data/stages/stage_01_04.json")
	assert_array(m.errors).is_empty()
	assert_str(str(m.data["code"])).is_equal("1-4")
	assert_str(str(ChapterBook.stage("1-4")["stage_id"])).is_equal("stage_01_04")
	var waves: Array = m.data["waves"]
	assert_int(waves.size()).is_between(2, 3)                         # README 15.7: 2–3 đợt quái
	assert_int(m.checkpoint_cells.size()).is_equal(3)
	var last := -1
	for w: Dictionary in waves:
		assert_int(int(w["trigger_col"])).is_greater(last)
		last = int(w["trigger_col"])
		for e: Dictionary in w["enemies"]:
			assert_bool(StageController.ENEMY_SCENES.has(e["id"])).is_true()
			assert_bool(int(e["col"]) > int(w["lock_cols"][0]) and int(e["col"]) < int(w["lock_cols"][1])).is_true()
	assert_int(int(m.data["goal_col"])).is_greater(int(waves[-1]["lock_cols"][1]))
	assert_str(tr(m.data["name_key"])).is_not_equal(m.data["name_key"])
	# Màn ngoài trời: không có trần; hố rộng ≥ 5 ô thì có platform bắc qua.
	var rows: Array = m.data["rows"]
	for y in range(0, 9):
		var row: String = rows[y]
		assert_bool(row.substr(1, row.length() - 2).contains("#")).is_false()
	var x := 1
	while x < (rows[14] as String).length() - 1:
		if (rows[14] as String)[x] == ".":
			var start := x
			while (rows[14] as String)[x] == ".":
				x += 1
			if x - start >= 5:
				assert_bool((rows[11] as String).substr(start, x - start).contains("=")).is_true()
		x += 1


func test_enemies_stand_on_floor() -> void:
	var m := StageMap.load_from("res://data/stages/stage_01_04.json")
	var floor_y := float(13 + 1) * 64.0
	for w: Dictionary in m.data["waves"]:
		for e: Dictionary in w["enemies"]:
			assert_float(m.ground_feet(int(e["col"])).y).is_equal_approx(floor_y, 1.0)


func test_clear_needs_all_waves_then_reaching_exit() -> void:
	await _setup()
	var waves: Array = _stage.waves()
	for i in waves.size():
		await _teleport_col(int(waves[i]["trigger_col"]))
		assert_int(_stage.phase).is_equal(StageController.Phase.WAVE)
		for e in _stage.enemies.duplicate():
			e.combatant.resources.take_damage(1e9)
		await _frames(2)
		assert_int(_stage.waves_cleared).is_equal(i + 1)
	await _teleport_col(int(_stage.map.data["goal_col"]) + 1)
	assert_int(_stage.phase).is_equal(StageController.Phase.CLEARED)
	assert_bool(bool(_save.data["progress"]["stages"]["stage_01_04"]["cleared"])).is_true()
