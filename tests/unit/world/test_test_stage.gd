extends GdUnitTestSuite
## Test M2-3: bản đồ ký tự, TileMapLayer, platform một chiều, hồi sinh khi rơi hố, camera.

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")
const MAP_PATH := "res://data/stages/test_stage.json"
const DT := 1.0 / 60.0
const TMP_MAP := "user://test_bad_map.json"

var _stage: Node2D
var _player: PlayerController
var _camera: FollowCamera


func after_test() -> void:
	if FileAccess.file_exists(TMP_MAP):
		DirAccess.remove_absolute(TMP_MAP)


func _setup() -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	add_child(_stage)
	_player = _stage.player
	_camera = _stage.camera
	# Tự bước vật lý với DT cố định.
	_stage.set_physics_process(false)
	_player.set_physics_process(false)
	_camera.set_physics_process(false)
	await await_idle_frame()
	await get_tree().physics_frame
	await get_tree().physics_frame


func _run(seconds: float) -> void:
	for i in int(round(seconds / DT)):
		_player.step(DT)
		_camera.update_camera(DT)
		_stage.check_fall()


func _place(cell_x: int, feet_y: float) -> void:
	_player.global_position = Vector2((cell_x + 0.5) * 64, feet_y)
	_player.velocity = Vector2.ZERO
	_camera.follow(_player)


# ---------- Bản đồ ----------

func test_map_loads_without_errors() -> void:
	var m := StageMap.load_from(MAP_PATH)
	assert_array(m.errors).is_empty()
	assert_vector(m.size_cells()).is_equal(Vector2i(112, 17))
	assert_vector(m.spawn_cell).is_equal(Vector2i(3, 13))
	assert_vector(m.spawn_position()).is_equal(Vector2(224, 896))
	assert_object(m.bounds_px()).is_equal(Rect2i(0, 0, 112 * 64, 17 * 64))


func test_bad_map_reports_errors() -> void:
	var f := FileAccess.open(TMP_MAP, FileAccess.WRITE)
	f.store_string(JSON.stringify({"rows": ["#P..", "#P.x", "###"]}))
	f.close()
	var m := StageMap.load_from(TMP_MAP)
	var text := "\n".join(m.errors)
	assert_str(text).contains("ký tự lạ 'x'")
	assert_str(text).contains("hàng 2 dài 3")
	assert_str(text).contains("cần đúng 1 điểm 'P', có 2")
	assert_bool(StageMap.load_from("user://khong_co.json").errors.is_empty()).is_false()


func test_layer_cells_match_map() -> void:
	var m := StageMap.load_from(MAP_PATH)
	var layer: TileMapLayer = auto_free(m.build_layer())
	assert_vector(layer.get_cell_atlas_coords(Vector2i(10, 14))).is_equal(StageMap.ATLAS_SOLID)
	assert_vector(layer.get_cell_atlas_coords(Vector2i(84, 11))).is_equal(StageMap.ATLAS_ONE_WAY)
	assert_int(layer.get_cell_source_id(Vector2i(53, 14))).is_equal(-1)  # hố
	var data := layer.get_cell_tile_data(Vector2i(84, 11))
	assert_bool(data.is_collision_polygon_one_way(0, 0)).is_true()


# ---------- Nhân vật trong màn ----------

func test_player_spawns_and_stands_on_ground() -> void:
	await _setup()
	_run(1.0)
	assert_bool(_player.is_on_floor()).is_true()
	assert_float(_player.global_position.y).is_equal_approx(896.0, 2.0)
	assert_float(_player.global_position.x).is_equal_approx(224.0, 1.0)


func test_one_way_platform_jump_through_and_land() -> void:
	await _setup()
	_place(84, 896)  # ngay dưới platform hàng 11 (mặt trên y = 704)
	_run(0.5)
	assert_bool(_player.is_on_floor()).is_true()
	_player.intent.press_jump(_player.config.jump_buffer_time)
	_run(1.5)
	assert_bool(_player.is_on_floor()).is_true()
	assert_float(_player.global_position.y).is_equal_approx(704.0, 2.0)


func test_solid_block_stops_running() -> void:
	await _setup()
	_place(18, 896)
	_run(0.3)
	_player.intent.move_x = 1.0
	_run(2.0)
	# Cột cao 1 ô ở cột 22: mép trái x = 1408, capsule bán kính 40.
	assert_float(_player.global_position.x).is_less_equal(1408.0 - 40.0 + 1.0)
	assert_float(_player.velocity.x).is_equal_approx(0.0, 1.0)


func test_falling_into_pit_respawns() -> void:
	await _setup()
	_place(53, 800)  # trên hố cột 52-54
	var respawned := false
	for i in 240:
		_player.step(DT)
		if _stage.check_fall():
			respawned = true
			break
	assert_bool(respawned).is_true()
	assert_vector(_player.global_position).is_equal(_stage.map.spawn_position())
	assert_vector(_player.velocity).is_equal(Vector2.ZERO)


# ---------- Camera ----------

func test_camera_looks_ahead_in_facing_direction() -> void:
	await _setup()
	_place(15, 896)
	_run(0.3)
	_player.intent.move_x = 1.0
	_run(1.0)
	_player.intent.move_x = 0.0
	_run(2.0)
	var ahead := _camera.global_position.x - _player.global_position.x
	assert_float(ahead).is_equal_approx(_camera.look_ahead, 10.0)

	_player.intent.move_x = -1.0
	_run(0.2)
	_player.intent.move_x = 0.0
	_run(2.0)
	ahead = _camera.global_position.x - _player.global_position.x
	assert_float(ahead).is_equal_approx(-_camera.look_ahead, 10.0)


func test_camera_holds_height_on_full_jump() -> void:
	await _setup()
	_place(10, 896)
	_run(1.5)
	var cam_y := _camera.global_position.y
	assert_float(cam_y).is_equal_approx(896.0 - _camera.height_offset, 2.0)
	_player.intent.press_jump(_player.config.jump_buffer_time)
	var max_shift := 0.0
	for i in 60:  # cả cú nhảy cao nhất (giữ nút) tới lúc chạm đất
		_player.step(DT)
		_camera.update_camera(DT)
		max_shift = maxf(max_shift, absf(_camera.global_position.y - cam_y))
	assert_float(max_shift).is_less(1.0)


func test_camera_follows_down_when_dropping_off() -> void:
	await _setup()
	_place(84, 704)  # đứng trên platform hàng 11
	_run(1.5)
	var cam_high := _camera.global_position.y
	_player.intent.move_x = 1.0  # bước khỏi mép phải platform (x = 5568), rơi xuống đất (896)
	_run(0.8)
	_player.intent.move_x = 0.0
	_run(2.0)
	assert_float(_player.global_position.y).is_equal_approx(896.0, 2.0)
	assert_float(_camera.global_position.y - cam_high).is_equal_approx(192.0, 3.0)


func test_camera_stays_inside_stage_bounds() -> void:
	await _setup()
	_run(1.0)  # điểm xuất phát sát tường trái
	# Camera2D tính lại tâm màn hình (có áp giới hạn) trong vòng xử lý nội bộ của engine.
	await get_tree().physics_frame
	await get_tree().process_frame
	# Đo theo khung thiết kế 1920x1080 (cửa sổ headless có tỉ lệ khác nên khung nhìn bị nới).
	var half := Vector2(GameConfig.BASE_RESOLUTION) * 0.5
	var center := _camera.get_screen_center_position()
	assert_float(center.x - half.x).is_greater_equal(-0.5)
	assert_float(center.y + half.y).is_less_equal(17 * 64 + 0.5)
	assert_float(center.y - half.y).is_greater_equal(-0.5)
