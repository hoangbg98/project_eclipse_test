class_name VirtualJoystick
extends Control
## Joystick ảo chỉ cho trục ngang: ghi vào move_left / move_right với cường độ analog.

const DEADZONE := 0.25

var _finger := -1
var _vector := Vector2.ZERO  # -1..1 mỗi trục, để vẽ núm


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _finger == -1:
			_finger = touch.index
			_update(touch.position)
		elif (not touch.pressed or touch.canceled) and touch.index == _finger:
			_reset()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _finger:
			_update(drag.position)


func _update(local_pos: Vector2) -> void:
	var radius := minf(size.x, size.y) * 0.5
	_vector = ((local_pos - size * 0.5) / radius).limit_length(1.0)
	var x := _vector.x
	if x < -DEADZONE:
		Input.action_press(&"move_left", absf(x))
		Input.action_release(&"move_right")
	elif x > DEADZONE:
		Input.action_press(&"move_right", absf(x))
		Input.action_release(&"move_left")
	else:
		Input.action_release(&"move_left")
		Input.action_release(&"move_right")
	queue_redraw()


func _reset() -> void:
	_finger = -1
	_vector = Vector2.ZERO
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	queue_redraw()


func is_active() -> bool:
	return _finger != -1


func _exit_tree() -> void:
	if _finger != -1:
		_reset()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree() and _finger != -1:
		_reset()


## Ảnh đế / phím (HudTheme.JOYSTICK_*); thiếu file thì vẽ hình tròn tạm.
static var _base_tex: Texture2D
static var _knob_tex: Texture2D


static func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	if _base_tex == null:
		_base_tex = _tex(HudTheme.JOYSTICK_BASE)
		_knob_tex = _tex(HudTheme.JOYSTICK_KNOB)
	var tint := Color(1, 1, 1, HudTheme.JOYSTICK_ALPHA_ACTIVE if is_active() else HudTheme.JOYSTICK_ALPHA_IDLE)
	var knob_center := center + _vector * radius * HudTheme.JOYSTICK_TRAVEL
	if _base_tex and _knob_tex:
		draw_texture_rect(_base_tex, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, tint)
		var kr := radius * HudTheme.JOYSTICK_KNOB_RATIO
		draw_texture_rect(_knob_tex, Rect2(knob_center - Vector2.ONE * kr, Vector2.ONE * kr * 2.0), false, tint)
		return
	draw_circle(center, radius, Color(1, 1, 1, 0.2))
	draw_arc(center, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.6), 4.0)
	draw_circle(knob_center, radius * 0.35, Color(1, 1, 1, 0.55 if is_active() else 0.35))


## Vị trí tâm phím (toạ độ cục bộ), để test.
func knob_center() -> Vector2:
	return size * 0.5 + _vector * minf(size.x, size.y) * 0.5 * HudTheme.JOYSTICK_TRAVEL
