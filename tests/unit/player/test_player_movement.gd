extends GdUnitTestSuite
## Test M2-2: controller di chuyển + state machine (chạy, nhảy cao/thấp, coyote, bộ đệm, rơi, đáp).
## Vật lý chạy bằng step(DT) cố định để tái lập được; không dùng input thật.

const PLAYER_SCENE := preload("res://scenes/player/player_character.tscn")
const DT := 1.0 / 60.0

var _world: Node2D
var _player: PlayerController
var _states: Array[StringName] = []


func before_test() -> void:
	_states.clear()


## floor_left/right: mép sàn theo x; mặt sàn ở y = 0.
func _setup(spawn: Vector2, floor_left := -3000.0, floor_right := 3000.0) -> void:
	_world = auto_free(Node2D.new())
	add_child(_world)
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(floor_right - floor_left, 200)
	shape.shape = rect
	floor_body.position = Vector2((floor_left + floor_right) * 0.5, 100)
	floor_body.add_child(shape)
	_world.add_child(floor_body)

	_player = PLAYER_SCENE.instantiate()
	_player.use_player_input = false
	_player.position = spawn
	_world.add_child(_player)
	_player.set_physics_process(false)
	_player.state_changed.connect(func(_f: StringName, t: StringName) -> void: _states.append(t))
	await await_idle_frame()
	await get_tree().physics_frame
	await get_tree().physics_frame


func _run(seconds: float) -> void:
	for i in int(round(seconds / DT)):
		_player.step(DT)


## Chạy tới khi đứng yên trên sàn.
func _settle() -> void:
	_run(1.5)
	_states.clear()


func _cfg() -> MovementConfig:
	return _player.config


# ---------- Cấu hình ----------

func test_default_config_within_spec() -> void:
	var c: MovementConfig = load("res://data/config/movement_default.tres")
	assert_float(c.coyote_time).is_between(0.08, 0.12)        # README 15.7
	assert_float(c.jump_buffer_time).is_between(0.10, 0.15)   # ARCHITECTURE: 100-150 ms
	assert_float(c.jump_velocity()).is_equal_approx(2.0 * c.jump_height / c.jump_time_to_peak, 0.001)
	assert_float(c.rise_gravity()).is_equal_approx(2.0 * c.jump_height / pow(c.jump_time_to_peak, 2), 0.001)
	assert_float(c.fall_gravity()).is_greater(c.rise_gravity())


# ---------- Rơi và đáp ----------

func test_spawn_falls_lands_then_idles() -> void:
	await _setup(Vector2(0, -300))
	assert_str(String(_player.current_state())).is_equal("fall")
	_run(1.5)
	assert_bool(_player.is_on_floor()).is_true()
	assert_float(_player.position.y).is_equal_approx(0.0, 2.0)
	assert_str(String(_player.current_state())).is_equal("idle")
	assert_array(_states).contains_exactly([&"land", &"idle"])


func test_animation_follows_state_and_placeholder_is_tinted() -> void:
	await _setup(Vector2(0, -300))
	_settle()
	assert_str(String(_player.sprite.animation)).is_equal("idle")
	assert_bool(_player.sprite.is_playing()).is_true()
	assert_vector(_player.sprite.offset).is_equal(Vector2(0, -144))
	# Aether chưa có hình: placeholder tô màu lửa.
	assert_object(_player.sprite.modulate).is_equal(PlayerController.PLACEHOLDER_TINT["fire"])


# ---------- Chạy ----------

func test_run_reaches_speed_faces_and_stops() -> void:
	await _setup(Vector2(0, -10))
	_settle()
	_player.intent.move_x = 1.0
	_run(0.5)
	assert_str(String(_player.current_state())).is_equal("run")
	assert_float(_player.velocity.x).is_equal_approx(_cfg().run_speed, 0.01)
	assert_int(_player.facing).is_equal(1)
	assert_bool(_player.sprite.flip_h).is_false()

	_player.intent.move_x = -1.0
	_run(0.5)
	assert_float(_player.velocity.x).is_equal_approx(-_cfg().run_speed, 0.01)
	assert_int(_player.facing).is_equal(-1)
	assert_bool(_player.sprite.flip_h).is_true()

	_player.intent.move_x = 0.0
	_run(0.5)
	assert_float(_player.velocity.x).is_equal(0.0)
	assert_str(String(_player.current_state())).is_equal("idle")
	# Thả nút vẫn giữ hướng nhìn cuối.
	assert_int(_player.facing).is_equal(-1)


func test_analog_input_scales_speed() -> void:
	await _setup(Vector2(0, -10))
	_settle()
	_player.intent.move_x = 0.5
	_run(0.5)
	assert_float(_player.velocity.x).is_equal_approx(_cfg().run_speed * 0.5, 0.01)


# ---------- Nhảy ----------

func _jump_peak(hold_ticks: int) -> float:
	var start_y := _player.position.y
	var min_y := start_y
	_player.intent.press_jump(_cfg().jump_buffer_time)
	for i in 120:
		if i == hold_ticks:
			_player.intent.release_jump()
		_player.step(DT)
		min_y = minf(min_y, _player.position.y)
	return start_y - min_y


func test_full_jump_reaches_configured_height() -> void:
	await _setup(Vector2(0, -10))
	_settle()
	var h := _jump_peak(1000)  # giữ suốt
	assert_float(h).is_between(_cfg().jump_height * 0.96, _cfg().jump_height * 1.04)
	assert_array(_states.slice(0, 2)).contains_exactly([&"jump_up", &"fall"])
	assert_bool(_player.current_state() in [&"land", &"idle"]).is_true()


func test_short_tap_jumps_lower() -> void:
	await _setup(Vector2(0, -10))
	_settle()
	var full := _cfg().jump_height
	var h := _jump_peak(3)  # thả sau 3 tick
	assert_float(h).is_less(full * 0.5)
	assert_float(h).is_greater(10.0)


func test_cannot_double_jump_in_air() -> void:
	await _setup(Vector2(0, -10))
	_settle()
	_player.intent.press_jump(_cfg().jump_buffer_time)
	_run(0.5)  # đang ở trên không, đã qua đỉnh
	_states.clear()
	_player.intent.press_jump(_cfg().jump_buffer_time)
	_run(0.05)
	assert_bool(&"jump_up" in _states).is_false()


# ---------- Coyote time ----------

## Chạy sang phải tới mép sàn (x = 0), trả về khi vừa rời mặt đất.
func _run_off_ledge() -> void:
	await _setup(Vector2(-300, -10), -3000.0, 0.0)
	_settle()
	_player.intent.move_x = 1.0
	for i in 300:
		_player.step(DT)
		if not _player.is_on_floor():
			return
	fail("không rời được mép sàn")


func test_coyote_jump_allowed_just_after_ledge() -> void:
	await _run_off_ledge()
	_run(_cfg().coyote_time * 0.5)
	_player.intent.press_jump(_cfg().jump_buffer_time)
	_player.step(DT)
	assert_str(String(_player.current_state())).is_equal("jump_up")
	assert_float(_player.velocity.y).is_less(0.0)


func test_coyote_jump_refused_after_window() -> void:
	await _run_off_ledge()
	_run(_cfg().coyote_time + 0.05)
	_player.intent.press_jump(_cfg().jump_buffer_time)
	_run(0.05)
	assert_str(String(_player.current_state())).is_equal("fall")
	assert_float(_player.velocity.y).is_greater(0.0)


# ---------- Bộ đệm nhảy ----------

## Số tick từ lúc thả ở độ cao 300 tới khi chạm đất (không nhảy).
func _ticks_to_land() -> int:
	await _setup(Vector2(0, -300))
	for i in 300:
		_player.step(DT)
		if _player.is_on_floor():
			_world.queue_free()
			await await_idle_frame()
			return i
	return -1


func _drop_and_press_at(press_tick: int, total_ticks: int) -> void:
	await _setup(Vector2(0, -300))
	for i in total_ticks:
		if i == press_tick:
			_player.intent.press_jump(_cfg().jump_buffer_time)
		_player.step(DT)


func test_jump_pressed_shortly_before_landing_is_buffered() -> void:
	var land_tick := await _ticks_to_land()
	assert_int(land_tick).is_greater(10)
	var buffer := PlayerController.DEFAULT_CONFIG.jump_buffer_time
	var early := int(floor(buffer * 0.6 / DT))  # ~70 ms trước khi chạm đất
	await _drop_and_press_at(land_tick - early, land_tick + 3)
	assert_bool(&"jump_up" in _states).override_failure_message("states: %s" % [_states]).is_true()
	assert_float(_player.velocity.y).is_less(0.0)


func test_jump_pressed_too_early_is_dropped() -> void:
	var land_tick := await _ticks_to_land()
	var buffer := PlayerController.DEFAULT_CONFIG.jump_buffer_time
	var early := int(ceil((buffer + 0.1) / DT))
	await _drop_and_press_at(land_tick - early, land_tick + 30)
	assert_bool(&"jump_up" in _states).is_false()
	assert_bool(_player.is_on_floor()).is_true()
