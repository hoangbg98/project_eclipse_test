extends GdUnitTestSuite
## Màn 1-5 → 1-10 (tools/stages/gen_stages_01_05_10.py): dữ liệu từng màn, liên kết map chương, thoại có chữ,
## boss kẻ đeo mặt nạ (BossDef hợp lệ), 1-10 hạ boss thì qua màn và phát clip kết chương.

const STAGE_SCENE := preload("res://scenes/stages/stage.tscn")
const SAVE_DIR := "user://test_saves_stages_01_05_10"
const IDS := ["stage_01_05", "stage_01_06", "stage_01_07", "stage_01_08", "stage_01_09", "stage_01_10"]

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


func _setup(id: String) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.use_selected_stage = false
	_stage.stage_id = id
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


func _clear_waves() -> void:
	var waves: Array = _stage.waves()
	for i in waves.size():
		await _teleport_col(int(waves[i]["trigger_col"]))
		assert_int(_stage.phase).is_equal(StageController.Phase.WAVE)
		for e in _stage.enemies.duplicate():
			e.combatant.resources.take_damage(1e9)
		await _frames(2)
		assert_int(_stage.waves_cleared).is_equal(i + 1)


func test_every_stage_is_valid_and_on_the_chapter_map() -> void:
	for i in IDS.size():
		var id: String = IDS[i]
		var m := StageMap.load_from("res://data/stages/%s.json" % id)
		assert_array(m.errors).is_empty()
		var code := "1-%d" % (i + 5)
		assert_str(str(m.data["code"])).is_equal(code)
		assert_str(str(ChapterBook.stage(code)["stage_id"])).is_equal(id)
		assert_int((m.data["waves"] as Array).size()).is_between(2, 3)      # README 15.7
		assert_int(m.checkpoint_cells.size()).is_equal(3)
		assert_str(tr(m.data["name_key"])).is_not_equal(m.data["name_key"])
		assert_str(tr(m.data["desc_key"])).is_not_equal(m.data["desc_key"])
		assert_bool(m.data.has("boss") != m.data.has("goal_col")).is_true()  # boss hoặc đích, không cả hai
		for w: Dictionary in m.data["waves"]:
			for e: Dictionary in w["enemies"]:
				assert_bool(StageController.ENEMY_SCENES.has(e["id"])).is_true()
		# Màn sau khó hơn màn trước (cấp đề nghị tăng).
		if i > 0:
			var prev := StageMap.load_from("res://data/stages/%s.json" % IDS[i - 1])
			assert_int(int(m.data["recommended_level"])).is_greater(int(prev.data["recommended_level"]))


func test_story_barks_have_text_in_both_languages() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tutorial/battle_barks.json"))
	var found := {}
	for l: Dictionary in data["lines"]:
		if str(l.get("stage", "")) in IDS:
			found[l["stage"]] = true
			for k in ["text", "neo_text"]:
				if l.has(k):
					assert_str(tr(str(l[k]))).is_not_equal(str(l[k]))
	assert_int(found.size()).is_equal(IDS.size())


func test_henchman_boss_definition_is_valid() -> void:
	var b := load("res://data/enemies/boss_henchman_01.tres") as BossDef
	assert_array(b.validate()).is_empty()
	assert_int(b.phases.size()).is_equal(2)
	var golem := load("res://data/enemies/boss_golem_01.tres") as BossDef
	assert_float(b.stats.max_hp).is_greater(golem.stats.max_hp)          # boss cuối chương mạnh hơn golem 1-1
	assert_str(tr(b.name_key)).is_not_equal(b.name_key)
	var m := StageMap.load_from("res://data/stages/stage_01_10.json")
	assert_str(str(m.data["boss"]["id"])).is_equal("boss_henchman_01")
	assert_str(str(m.data["end_clip"])).is_equal("ch01_end")


func test_no_boss_stage_clears_at_goal() -> void:
	await _setup("stage_01_07")
	await _clear_waves()
	await _teleport_col(int(_stage.map.data["goal_col"]) + 1)
	assert_int(_stage.phase).is_equal(StageController.Phase.CLEARED)


func test_final_stage_needs_the_boss_down() -> void:
	await _setup("stage_01_10")
	await _clear_waves()
	var b: Dictionary = _stage.boss_data()
	await _teleport_col(int(b["trigger_col"]) + 1)
	assert_int(_stage.phase).is_equal(StageController.Phase.BOSS)
	assert_object(_stage.boss).is_not_null()
	assert_str(_stage.boss.enemy_id).is_equal("boss_henchman_01")
	_stage.boss.combatant.resources.take_damage(1e9)
	await _frames(5)
	assert_int(_stage.phase).is_equal(StageController.Phase.CLEARED)
	assert_bool(bool(_save.data["progress"]["stages"]["stage_01_10"]["cleared"])).is_true()
