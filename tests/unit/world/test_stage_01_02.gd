extends GdUnitTestSuite
## Màn 1-2 "Làng Lò Than" (tools/stages/gen_stage_01_02.py): dữ liệu, quái mới, qua màn không boss bằng goal_col,
## ảnh nền theo data (thiếu ảnh thì giữ nền tạm).

const STAGE_SCENE := preload("res://scenes/stages/stage.tscn")
const SAVE_DIR := "user://test_saves_stage_01_02"

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
	_stage.stage_id = "stage_01_02"
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


func _kill_all() -> void:
	for e in _stage.enemies.duplicate():
		e.combatant.resources.take_damage(1e9)
	await _frames(2)


func test_stage_data_is_valid() -> void:
	var m := StageMap.load_from("res://data/stages/stage_01_02.json")
	assert_array(m.errors).is_empty()
	assert_str(str(m.data["code"])).is_equal("1-2")
	var waves: Array = m.data["waves"]
	assert_int(waves.size()).is_between(2, 3)                         # README 15.7: 2–3 đợt quái
	assert_int(m.checkpoint_cells.size()).is_equal(3)
	assert_bool(m.data.has("boss")).is_false()
	var last := -1
	for w: Dictionary in waves:
		assert_int(int(w["trigger_col"])).is_greater(last)
		last = int(w["trigger_col"])
		for e: Dictionary in w["enemies"]:
			assert_bool(StageController.ENEMY_SCENES.has(e["id"])).is_true()
			assert_bool(ResourceLoader.exists("res://data/enemies/%s.tres" % e["id"])).is_true()
			assert_bool(int(e["col"]) > int(w["lock_cols"][0]) and int(e["col"]) < int(w["lock_cols"][1])).is_true()
	assert_int(int(m.data["goal_col"])).is_greater(int(waves[-1]["lock_cols"][1]))
	assert_str(tr(m.data["name_key"])).is_not_equal(m.data["name_key"])
	assert_str(tr(m.data["desc_key"])).is_not_equal(m.data["desc_key"])
	assert_int((m.data["backdrop"] as Array).size()).is_equal(3)


func test_big_ash_slime_is_slower_and_tougher() -> void:
	var small := load("res://data/enemies/enemy_slime_01.tres") as EnemyDef
	var big := load("res://data/enemies/enemy_slime_02.tres") as EnemyDef
	assert_float(big.stats.max_hp).is_greater(small.stats.max_hp)
	assert_float(big.move_speed).is_less(small.move_speed)
	assert_float(big.attack.startup_ms).is_greater_equal(400.0)       # báo hiệu ≥ 0.4 s
	assert_str(tr(big.name_key)).is_not_equal(big.name_key)


func test_chapter_map_points_1_2_here() -> void:
	assert_str(str(ChapterBook.stage("1-2")["stage_id"])).is_equal("stage_01_02")


func test_gate_does_nothing_before_waves_are_cleared() -> void:
	await _setup()
	await _teleport_col(int(_stage.map.data["goal_col"]))
	await _frames(5)
	assert_int(_stage.phase).is_not_equal(StageController.Phase.CLEARED)


func test_clear_needs_all_waves_then_reaching_gate() -> void:
	await _setup()
	var goal := int(_stage.map.data["goal_col"])
	var waves: Array = _stage.waves()
	for i in waves.size():
		await _teleport_col(int(waves[i]["trigger_col"]))
		assert_int(_stage.phase).is_equal(StageController.Phase.WAVE)
		await _kill_all()
		assert_int(_stage.waves_cleared).is_equal(i + 1)
	assert_int(_stage.phase).is_equal(StageController.Phase.EXPLORE)
	await _teleport_col(goal + 1)
	assert_int(_stage.phase).is_equal(StageController.Phase.CLEARED)
	assert_bool(bool(_save.data["progress"]["stages"]["stage_01_02"]["cleared"])).is_true()
	assert_bool(bool(_stage.last_summary["first_clear"])).is_true()


func test_backdrop_keeps_placeholder_without_images_and_uses_real_ones() -> void:
	var pb := ParallaxBackdrop.new()
	add_child(pb)
	auto_free(pb)
	var n := pb.layers.size()
	assert_int(pb.use_images([{"image": "res://khong_co.png", "scroll": 0.2}])).is_equal(0)
	assert_int(pb.layers.size()).is_equal(n)
	var img := "res://assets/placeholders/story/placeholder_map_ch01.png"
	assert_int(pb.use_images([{"image": img, "scroll": 0.2}, {"image": "res://khong_co.png"}])).is_equal(1)
	assert_int(pb.layers.size()).is_equal(1)
	assert_float(pb.layers[0].scroll_scale.x).is_equal_approx(0.2, 0.001)
	var sp := pb.layers[0].get_child(0) as Sprite2D
	assert_float(sp.texture.get_height() * sp.scale.y).is_equal_approx(ParallaxBackdrop.VIEW_HEIGHT, 0.01)
