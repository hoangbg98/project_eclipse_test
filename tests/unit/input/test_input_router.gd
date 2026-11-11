extends GdUnitTestSuite
## Unit test cho InputRouter (scripts/input/input_router.gd): bảng action và bộ đệm.

const InputRouterScript := preload("res://scripts/input/input_router.gd")

var _router: Node


func before_test() -> void:
	_router = auto_free(InputRouterScript.new())
	_router.register_actions()


func after_test() -> void:
	for action in InputRouterScript.BUFFERED_ACTIONS:
		Input.action_release(action)


func test_all_actions_registered_with_events() -> void:
	for action in [&"move_left", &"move_right", &"jump", &"attack", &"dodge", &"skill",
			&"weapon", &"ultimate", &"switch_1", &"switch_2", &"pause", &"ui_back"]:
		assert_bool(InputMap.has_action(action)).override_failure_message(
				"thiếu action %s" % action).is_true()
		assert_int(InputMap.action_get_events(action).size()).is_greater(0)


func test_register_actions_is_idempotent() -> void:
	var before := InputMap.action_get_events(&"jump").size()
	_router.register_actions()
	assert_int(InputMap.action_get_events(&"jump").size()).is_equal(before)


func test_buffer_window_within_spec() -> void:
	# ARCHITECTURE: bộ đệm input 100-150 ms
	assert_int(InputRouterScript.BUFFER_MS).is_between(100, 150)


func test_consume_without_press_is_false() -> void:
	assert_bool(_router.consume_buffered(&"jump")).is_false()


func test_buffered_press_consumed_once() -> void:
	add_child(_router)
	Input.action_press(&"jump")
	await await_idle_frame()
	Input.action_release(&"jump")
	assert_bool(_router.consume_buffered(&"jump")).is_true()
	assert_bool(_router.consume_buffered(&"jump")).is_false()


func test_buffered_press_expires() -> void:
	add_child(_router)
	Input.action_press(&"attack")
	await await_idle_frame()
	Input.action_release(&"attack")
	await await_millis(InputRouterScript.BUFFER_MS + 80)
	assert_bool(_router.consume_buffered(&"attack")).is_false()


func test_clear_buffer_drops_pending_press() -> void:
	add_child(_router)
	Input.action_press(&"dodge")
	await await_idle_frame()
	Input.action_release(&"dodge")
	_router.clear_buffer()
	assert_bool(_router.consume_buffered(&"dodge")).is_false()
