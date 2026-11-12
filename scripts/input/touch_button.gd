class_name TouchButton
extends Control
## Nút ảo trên màn hình cảm ứng: giữ ngón = giữ action. Mỗi nút theo dõi ngón riêng
## nên nhiều nút nhấn đồng thời, độc lập (multitouch).

@export var action: StringName = &""
@export var label_text := ""

var _finger := -1

## Trạng thái hiển thị do TouchControls cập nhật (README 15.5: nút kỹ năng có vòng hồi và số).
## Phần hồi chiêu còn lại 0..1 (0 = sẵn sàng): vẽ quạt tối phủ lên nút.
var cooldown_ratio := 0.0
## Số hiện giữa nút khi đang hồi (giây còn lại) hoặc số lượt (né); rỗng thì hiện `label_text`.
var overlay_text := ""
## Vòng nạp quanh nút 0..1 (tuyệt kỹ: UG); đầy thì vòng sáng.
var charge_ratio := -1.0
## true: chưa dùng được (thiếu EN, hết lượt né...) → vẽ mờ.
var dimmed := false


## Đặt trạng thái hiển thị; chỉ vẽ lại khi có thay đổi.
func set_state(state: Dictionary) -> void:
	var cd := float(state.get("cooldown_ratio", 0.0))
	var text := str(state.get("overlay_text", ""))
	var charge := float(state.get("charge_ratio", -1.0))
	var dim := bool(state.get("dimmed", false))
	if cd == cooldown_ratio and text == overlay_text and charge == charge_ratio and dim == dimmed:
		return
	cooldown_ratio = cd
	overlay_text = text
	charge_ratio = charge
	dimmed = dim
	queue_redraw()


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
	if dimmed:
		alpha *= 0.45
	draw_circle(center, radius, Color(1, 1, 1, alpha))
	draw_arc(center, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.8), 4.0)
	# Quạt hồi chiêu: phủ tối phần còn phải chờ, bắt đầu từ đỉnh, theo chiều kim đồng hồ.
	if cooldown_ratio > 0.0:
		var pts := PackedVector2Array([center])
		for i in 33:
			var a := -PI / 2.0 + TAU * cooldown_ratio * float(i) / 32.0
			pts.append(center + Vector2(cos(a), sin(a)) * radius)
		draw_colored_polygon(pts, Color(0, 0, 0, 0.55))
	# Vòng nạp (tuyệt kỹ): cung theo lượng UG, đầy thì sáng vàng.
	if charge_ratio >= 0.0:
		var full := charge_ratio >= 1.0
		draw_arc(center, radius + 8.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(charge_ratio, 0.0, 1.0), 48,
				Color(1.0, 0.85, 0.24, 1.0 if full else 0.6), 8.0 if full else 5.0)
	var text := overlay_text if not overlay_text.is_empty() else label_text
	if not text.is_empty():
		var font := ThemeDB.fallback_font
		var font_size := int(radius * 0.5)
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var on_dark := cooldown_ratio > 0.0
		draw_string(font, center + Vector2(-text_size.x * 0.5, text_size.y * 0.25),
				text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 1, 1, 0.95) if on_dark else Color(0, 0, 0, 0.85))
