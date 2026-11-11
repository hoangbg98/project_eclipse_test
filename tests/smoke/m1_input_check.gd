extends SceneTree
## Kiểm tra khói M1-4 (headless): bảng action, bộ đệm input, nút/joystick ảo đa điểm.
## Chạy: godot --headless --path . --script res://tests/smoke/m1_input_check.gd

var _failures := 0
var _router: Node


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		_failures += 1


func _frames(n: int = 3) -> void:
	for i in n:
		await process_frame


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = pressed
	root.push_input(e, true)


func _drag(index: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	root.push_input(e, true)


func _run() -> void:
	_router = root.get_node_or_null("InputRouter")
	_check(_router != null, "autoload InputRouter tồn tại")
	if _router == null:
		quit(1)
		return

	# 1. Bảng action
	for a in ["move_left", "move_right", "jump", "attack", "dodge", "skill", "weapon",
			"ultimate", "switch_1", "switch_2", "pause", "ui_back"]:
		_check(InputMap.has_action(a) and InputMap.action_get_events(a).size() > 0,
				"action %s có phím gán" % a)

	# 2. Bộ đệm input: nhấn rồi nhả, tiêu thụ trong cửa sổ
	Input.action_press(&"jump")
	await _frames()
	Input.action_release(&"jump")
	_check(_router.consume_buffered(&"jump"), "bộ đệm: nhấn sớm vẫn được tính")
	_check(not _router.consume_buffered(&"jump"), "bộ đệm: chỉ tiêu thụ một lần")

	# 3. Bộ đệm hết hạn
	Input.action_press(&"attack")
	await _frames()
	Input.action_release(&"attack")
	await create_timer(0.25).timeout
	_check(not _router.consume_buffered(&"attack"), "bộ đệm: quá 120 ms thì hết hiệu lực")

	# 4. Cảm ứng đa điểm
	var tc := TouchControls.new()
	tc.force_visible = true
	root.add_child(tc)
	await _frames()
	var attack: TouchButton = tc.buttons[&"attack"]
	var jump: TouchButton = tc.buttons[&"jump"]
	var stick: VirtualJoystick = tc.joystick
	for b: TouchButton in tc.buttons.values():
		_check(minf(b.size.x, b.size.y) >= 128.0, "nút %s >= 128 px" % b.action)

	var rects: Array[Rect2] = [stick.get_global_rect()]
	for b: TouchButton in tc.buttons.values():
		rects.append(b.get_global_rect())
	var overlap := false
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			if rects[i].intersects(rects[j]):
				overlap = true
	_check(not overlap, "các vùng chạm không chồng nhau")

	_touch(0, attack.get_global_rect().get_center(), true)
	_touch(1, jump.get_global_rect().get_center(), true)
	await _frames()
	_check(Input.is_action_pressed(&"attack") and Input.is_action_pressed(&"jump"),
			"hai ngón nhấn hai nút cùng lúc")
	_touch(0, attack.get_global_rect().get_center(), false)
	await _frames()
	_check(not Input.is_action_pressed(&"attack") and Input.is_action_pressed(&"jump"),
			"nhả một ngón không ảnh hưởng nút kia")
	_touch(1, jump.get_global_rect().get_center(), false)
	await _frames()
	_check(not Input.is_action_pressed(&"jump"), "nhả hết thì action nhả")

	# 5. Joystick: kéo sang phải rồi sang trái rồi nhả
	var c := stick.get_global_rect().get_center()
	_touch(2, c, true)
	_drag(2, c + Vector2(stick.size.x * 0.5, 0))
	await _frames()
	_check(_router.get_move_x() > 0.9, "joystick kéo phải -> move_x > 0.9")
	_drag(2, c - Vector2(stick.size.x * 0.25, 0))
	await _frames()
	var mx: float = _router.get_move_x()
	_check(mx < -0.4 and mx > -0.6, "joystick kéo trái nửa chừng -> move_x khoảng -0.5 (thực tế %.2f)" % mx)
	_drag(2, c + Vector2(5, 0))
	await _frames()
	_check(is_zero_approx(_router.get_move_x()), "trong vùng chết -> move_x = 0")
	_touch(2, c, false)
	await _frames()
	_check(is_zero_approx(_router.get_move_x()) and not stick.is_active(), "nhả joystick -> về 0")

	# 6. Ẩn controls thì nhả hết
	_touch(0, attack.get_global_rect().get_center(), true)
	await _frames()
	tc.visible = false
	await _frames()
	_check(not Input.is_action_pressed(&"attack"), "ẩn lớp cảm ứng thì nhả nút đang giữ")

	print("KẾT QUẢ: %d lỗi" % _failures)
	quit(1 if _failures > 0 else 0)
