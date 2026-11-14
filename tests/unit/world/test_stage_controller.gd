extends GdUnitTestSuite
## Test M6: màn đầu — đợt quái khóa sân, checkpoint, boss, hoàn thành / thất bại, phần thưởng, lưu, màn kết quả.

const STAGE_SCENE := preload("res://scenes/stages/stage.tscn")
const SAVE_DIR := "user://test_saves_m6"

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
	_stage.stage_id = "stage_01"
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


# ---------- Dữ liệu màn ----------

func test_stage_data_matches_requirements() -> void:
	var m := StageMap.load_from("res://data/stages/stage_01.json")
	assert_array(m.errors).is_empty()
	var waves: Array = m.data["waves"]
	assert_int(waves.size()).is_between(2, 3)                         # README 15.7: 2–3 đợt quái
	assert_int(m.checkpoint_cells.size()).is_greater_equal(1)
	assert_str(m.data["boss"]["id"]).is_equal("boss_golem_01")
	var last_trigger := -1
	for w: Dictionary in waves:
		assert_int(int(w["trigger_col"])).is_greater(last_trigger)    # theo thứ tự từ trái sang
		last_trigger = int(w["trigger_col"])
		assert_bool(int(w["lock_cols"][0]) < int(w["trigger_col"]) and int(w["trigger_col"]) < int(w["lock_cols"][1])).is_true()
		for e: Dictionary in w["enemies"]:
			assert_bool(StageController.ENEMY_SCENES.has(e["id"])).is_true()
			assert_bool(int(e["col"]) > int(w["lock_cols"][0]) and int(e["col"]) < int(w["lock_cols"][1])).is_true()
	assert_int(int(m.data["boss"]["trigger_col"])).is_greater(last_trigger)
	assert_bool(m.data["rewards"].has("gold") and m.data["rewards"].has("exp")).is_true()
	assert_str(tr(m.data["name_key"])).is_not_equal(m.data["name_key"])


func test_ground_feet_finds_floor_and_block_tops() -> void:
	var m := StageMap.load_from("res://data/stages/stage_01.json")
	assert_vector(m.ground_feet(10)).is_equal(Vector2(10.5 * 64, 14 * 64))          # mặt đất
	assert_vector(m.ground_feet(60)).is_equal(Vector2(60.5 * 64, 11 * 64))          # đỉnh bậc


# ---------- Khởi tạo ----------

func test_stage_starts_in_explore_with_party_from_save() -> void:
	_save.data["party"] = ["char_wind_01", "char_fire_01"]
	_save.data["characters"]["char_wind_01"]["level"] = 11
	await _setup()
	assert_int(_stage.phase).is_equal(StageController.Phase.EXPLORE)
	assert_str(_stage.party.active().id).is_equal("char_wind_01")
	assert_int(_stage.party.members.size()).is_equal(2)
	assert_float(_stage.player.combatant.stats.atk).is_equal(1280.0)                # 800 × 1.6 (cấp 11)
	assert_bool(_stage.player.is_on_floor()).is_true()
	assert_int(_stage.enemies_alive()).is_equal(0)
	assert_object(_stage.hud).is_not_null()
	assert_int((_stage.get_node("Parallax") as ParallaxBackdrop).layers.size()).is_equal(3)


# ---------- Đợt quái ----------

func test_wave_triggers_locks_arena_and_clears() -> void:
	await _setup()
	var started := []
	var cleared := []
	_stage.wave_started.connect(func(i: int) -> void: started.append(i))
	_stage.wave_cleared.connect(func(i: int) -> void: cleared.append(i))
	await _teleport_col(12)
	assert_int(_stage.phase).is_equal(StageController.Phase.EXPLORE)                # chưa tới điểm kích hoạt
	await _teleport_col(17)
	assert_int(_stage.phase).is_equal(StageController.Phase.WAVE)
	assert_array(started).is_equal([0])
	assert_int(_stage.enemies_alive()).is_equal(3)
	assert_bool(_stage.is_locked()).is_true()
	assert_int(_stage.camera.limit_left).is_equal(8 * 64)                           # camera khóa theo sân
	assert_int(_stage.camera.limit_right).is_equal(45 * 64)
	var hud := _stage.get_node("StageHud") as StageHud
	assert_str(hud.objective_text()).is_equal(tr("STAGE_OBJ_WAVE") % [1, 3, 3])
	await _kill_all()
	assert_array(cleared).is_equal([0])
	assert_int(_stage.phase).is_equal(StageController.Phase.EXPLORE)
	assert_bool(_stage.is_locked()).is_false()
	assert_int(_stage.camera.limit_right).is_equal(200 * 64)                        # mở lại toàn màn
	assert_int(_stage.waves_cleared).is_equal(1)
	assert_str(hud.objective_text()).is_equal(tr("STAGE_OBJ_ADVANCE"))


func test_arena_walls_block_the_player() -> void:
	await _setup()
	await _teleport_col(17)
	var p := _stage.player
	p.global_position = Vector2(44 * 64, 14 * 64)                                   # sát mép phải sân (cột 44)
	p.intent.move_x = 1.0
	await _frames(90)
	assert_float(p.global_position.x).is_less(45 * 64 + 4.0)                        # không ra khỏi sân
	p.intent.move_x = 0.0
	await _kill_all()
	p.intent.move_x = 1.0
	await _frames(40)
	assert_float(p.global_position.x).is_greater(45 * 64 + 4.0)                     # hết khóa thì đi tiếp được


# ---------- Checkpoint ----------

func test_checkpoint_sets_respawn_and_fall_returns_there() -> void:
	await _setup()
	var reached := []
	_stage.checkpoint_reached.connect(func(p: Vector2) -> void: reached.append(p))
	var spawn := _stage.respawn_point
	_stage.player.global_position = Vector2(5 * 64, 5000)                           # rơi trước khi qua checkpoint
	await _frames(3)
	assert_float(_stage.player.global_position.distance_to(spawn)).is_less(80.0)
	_stage.waves_cleared = 3                                                        # bỏ qua các đợt để đi thẳng
	_stage.map.data.erase("boss")
	await _teleport_col(55)
	assert_int(reached.size()).is_equal(1)
	assert_vector(_stage.respawn_point).is_equal(_stage.map.cell_feet(Vector2i(53, 13)))
	_stage.player.global_position = Vector2(99 * 64, 5000)
	await _frames(3)
	assert_float(_stage.player.global_position.distance_to(_stage.respawn_point)).is_less(80.0)


# ---------- Boss, hoàn thành ----------

func test_boss_arena_then_clear_grants_rewards_and_saves() -> void:
	await _setup()
	_stage.waves_cleared = 3
	var summaries := []
	_stage.stage_cleared.connect(func(s: Dictionary) -> void: summaries.append(s))
	await _teleport_col(157)
	assert_int(_stage.phase).is_equal(StageController.Phase.BOSS)
	assert_object(_stage.boss).is_not_null()
	assert_bool(_stage.is_locked()).is_true()
	var hud := _stage.get_node("StageHud") as StageHud
	assert_bool(hud.boss_bar_visible()).is_true()
	assert_str(hud.objective_text()).is_equal(tr("STAGE_OBJ_BOSS"))
	_stage.elapsed_sec = 200.0
	await _kill_all()
	assert_int(_stage.phase).is_equal(StageController.Phase.CLEARED)
	assert_int(summaries.size()).is_equal(1)
	var s: Dictionary = summaries[0]
	assert_bool(s["victory"]).is_true()
	assert_bool(s["first_clear"]).is_true()
	assert_int(s["rewards"]["gold"]).is_equal(1200)
	assert_int(s["first_clear_rewards"]["gems"]).is_equal(300)
	# Dữ liệu người chơi đã đổi và đã ghi ra file.
	# 3 objectives met (200 s, no hits, no downs): +300 +300 +400 gold.
	assert_int(s["objectives"].size()).is_equal(3)
	assert_int(s["objective_rewards"]["gold"]).is_equal(1000)
	assert_int(_save.data["currencies"]["gold"]).is_equal(2200)
	assert_int(_save.data["currencies"]["gems"]).is_equal(300)
	assert_array(_save.data["progress"]["stages"]["stage_01"]["objectives"]).contains_exactly(["time", "hits", "downs"])
	assert_bool(_save.data["progress"]["stages"]["stage_01"]["cleared"]).is_true()
	assert_float(_save.data["progress"]["stages"]["stage_01"]["best_time_sec"]).is_between(200.0, 201.0)
	assert_int(int(_save.data["characters"]["char_fire_01"]["level"])).is_greater(1)   # 600 EXP cho cả đội
	var disk := SaveStore.new(SAVE_DIR).read()
	assert_int(disk["currencies"]["gold"]).is_equal(2200)
	assert_bool(disk["progress"]["stages"]["stage_01"]["cleared"]).is_true()
	assert_int(disk["inventory"]["equipment"].size()).is_equal(1)                   # thưởng lần đầu: 1 món
	# Màn kết quả hiện, có dòng thưởng và lên cấp.
	var result := _stage.get_node("ResultScreen") as ResultScreen
	assert_bool(result.visible).is_true()
	var lines := "\n".join(result.result_lines(s))
	assert_bool(lines.contains("1200") and lines.contains(tr("RESULT_FIRST_CLEAR")) and lines.contains("3:20")).is_true()
	assert_bool(_stage.party.use_player_input).is_false()                           # hết điều khiển sau khi xong


func test_second_clear_has_no_first_clear_bonus_and_keeps_best_time() -> void:
	_save.data["progress"]["stages"]["stage_01"] = {"cleared": true, "best_time_sec": 150.0, "objectives": ["downs"]}
	await _setup()
	_stage.waves_cleared = 3
	await _teleport_col(157)
	_stage.elapsed_sec = 400.0
	_stage.objectives.hits_taken = 30
	await _kill_all()
	var s := _stage.last_summary
	# Only "no downs" is met again: +400 gold; achieved list keeps the old entry without duplicates.
	assert_int(s["objective_rewards"]["gold"]).is_equal(400)
	assert_int(_save.data["currencies"]["gold"]).is_equal(1600)
	assert_array(_save.data["progress"]["stages"]["stage_01"]["objectives"]).contains_exactly(["downs"])
	assert_bool(s["first_clear"]).is_false()
	assert_bool(s["best_time"]).is_false()
	assert_int(_save.data["currencies"]["gems"]).is_equal(0)
	assert_float(_save.data["progress"]["stages"]["stage_01"]["best_time_sec"]).is_equal(150.0)


# ---------- Thất bại ----------

func test_party_wipe_fails_stage_without_rewards() -> void:
	await _setup()
	var failed := [0]
	_stage.stage_failed.connect(func() -> void: failed[0] += 1)
	for m in _stage.party.members:
		m.resources().take_damage(1e9)
	await _frames(2)
	assert_int(_stage.phase).is_equal(StageController.Phase.FAILED)
	assert_int(failed[0]).is_equal(1)
	assert_int(_save.data["currencies"]["gold"]).is_equal(0)
	assert_bool(_save.data["progress"]["stages"].has("stage_01")).is_false()
	var result := _stage.get_node("ResultScreen") as ResultScreen
	assert_bool(result.visible).is_true()
	assert_bool("\n".join(result.result_lines(_stage.last_summary)).contains(tr("RESULT_DEFEAT_HINT"))).is_true()


func test_format_time() -> void:
	assert_str(StageHud.format_time(0.0)).is_equal("0:00")
	assert_str(StageHud.format_time(200.4)).is_equal("3:20")
	assert_str(StageHud.format_time(3725.0)).is_equal("62:05")
