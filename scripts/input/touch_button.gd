class_name TouchButton
extends Control
## Nút ảo trên màn hình cảm ứng: giữ ngón = giữ action. Mỗi nút theo dõi ngón riêng
## nên nhiều nút nhấn đồng thời, độc lập (multitouch).

@export var action: StringName = &""
@export var label_text := ""

var _finger := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	# Chỉ xử lý sự kiện chạm; bỏ qua chuột giả lập từ cảm ứng để không bị đếm đôi.
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _finger == -1:
			_finger = touch.index
			Input.action_press(action)
			queue_redraw()
		elif (not touch.pressed or touch.canceled) and touch.index == _finger:
			_release()


func _release() -> void:
	_finger = -1
	Input.action_release(action)
	queue_redraw()


func is_held() -> bool:
	return _finger != -1


func _exit_tree() -> void:
	if _finger != -1:
		Input.action_release(action)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree() and _finger != -1:
		_release()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	var alpha := 0.55 if is_held() else 0.3
	draw_circle(center, radius, Color(1, 1, 1, alpha))
	draw_arc(center, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.8), 4.0)
	if not label_text.is_empty():
		var font := ThemeDB.fallback_font
		var font_size := int(radius * 0.5)
		var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, center + Vector2(-text_size.x * 0.5, text_size.y * 0.25),
				label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, 0.85))
