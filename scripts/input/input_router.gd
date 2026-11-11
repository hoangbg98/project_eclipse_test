extends Node
## Gộp bàn phím / tay cầm / cảm ứng thành các action chung và giữ bộ đệm input.
## Không biết nhân vật nào đang chơi (xem docs/ARCHITECTURE.md mục 3 và 11).
##
## Action đăng ký bằng code để mọi nơi dùng cùng một bảng; cảm ứng ảo ghi vào
## chính các action này qua Input.action_press / action_release.

## Cửa sổ bộ đệm mặc định, trong khoảng 100-150 ms theo ARCHITECTURE mục 3.
const BUFFER_MS := 120

## Action có bộ đệm (nhấn sớm một chút vẫn được tính).
const BUFFERED_ACTIONS: Array[StringName] = [
	&"jump", &"attack", &"dodge", &"skill", &"weapon", &"ultimate",
	&"switch_1", &"switch_2",
]

const MOVE_DEADZONE := 0.25

var _pressed_at: Dictionary = {}  # StringName -> msec của lần nhấn gần nhất chưa tiêu thụ


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	register_actions()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	for action in BUFFERED_ACTIONS:
		if Input.is_action_just_pressed(action):
			_pressed_at[action] = now


## Trục ngang -1..1 từ bàn phím, D-pad, cần analog hoặc joystick ảo.
func get_move_x() -> float:
	return Input.get_axis(&"move_left", &"move_right")


## True nếu action được nhấn trong cửa sổ bộ đệm; tiêu thụ lần nhấn đó (chỉ trả true một lần).
func consume_buffered(action: StringName, window_ms: int = BUFFER_MS) -> bool:
	if not _pressed_at.has(action):
		return false
	var age := Time.get_ticks_msec() - int(_pressed_at[action])
	_pressed_at.erase(action)
	return age <= window_ms


## Xóa bộ đệm (vd khi đổi scene hoặc bị khống chế).
func clear_buffer() -> void:
	_pressed_at.clear()


## Tạo bảng action. Gọi lại an toàn: bỏ qua action đã có và chỉ thêm event còn thiếu.
func register_actions() -> void:
	_bind(&"move_left", [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)])
	_bind(&"move_right", [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)])
	_bind(&"jump", [_key(KEY_SPACE), _key(KEY_K), _joy_button(JOY_BUTTON_A)])
	_bind(&"attack", [_key(KEY_J), _joy_button(JOY_BUTTON_X)])
	_bind(&"dodge", [_key(KEY_L), _key(KEY_SHIFT), _joy_button(JOY_BUTTON_B)])
	_bind(&"skill", [_key(KEY_U), _joy_button(JOY_BUTTON_Y)])
	_bind(&"weapon", [_key(KEY_I), _joy_button(JOY_BUTTON_LEFT_SHOULDER)])
	_bind(&"ultimate", [_key(KEY_O), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)])
	_bind(&"switch_1", [_key(KEY_Q), _key(KEY_1), _joy_button(JOY_BUTTON_DPAD_UP)])
	_bind(&"switch_2", [_key(KEY_E), _key(KEY_2), _joy_button(JOY_BUTTON_DPAD_DOWN)])
	_bind(&"pause", [_key(KEY_P), _joy_button(JOY_BUTTON_START)])
	# Esc và nút Back/Select của tay cầm; phím Back Android do SceneRouter bắt riêng.
	_bind(&"ui_back", [_key(KEY_ESCAPE), _joy_button(JOY_BUTTON_BACK)])


func _bind(action: StringName, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, MOVE_DEADZONE if action in [&"move_left", &"move_right"] else 0.5)
	for event: InputEvent in events:
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


func _key(keycode: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = keycode
	return e


func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e


func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e
