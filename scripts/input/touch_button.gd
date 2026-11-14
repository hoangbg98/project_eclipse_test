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
## Số trong huy hiệu tròn góc trên-phải (lượt né còn lại); rỗng = không vẽ.
var badge_text := ""
## Icon của nút (HudIcons, theo giáp đang trên sân); null thì hiện `label_text`.
var icon: Texture2D
## Phím bàn phím hiện dưới nút (PC); rỗng = không hiện.
var key_hint := ""


## Đặt trạng thái hiển thị; chỉ vẽ lại khi có thay đổi.
func set_state(state: Dictionary) -> void:
	var cd := float(state.get("cooldown_ratio", 0.0))
	var text := str(state.get("overlay_text", ""))
	var charge := float(state.get("charge_ratio", -1.0))
	var dim := bool(state.get("dimmed", false))
	var badge := str(state.get("badge_text", ""))
	if cd == cooldown_ratio and text == overlay_text and charge == charge_ratio and dim == dimmed \
			and badge == badge_text:
		return
	cooldown_ratio = cd
	overlay_text = text
	charge_ratio = charge
	dimmed = dim
	badge_text = badge
	queue_redraw()


func set_icon(tex: Texture2D) -> void:
	if tex == icon:
		return
	icon = tex
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


func _process(_delta: float) -> void:
	# Tuyệt kỹ sẵn sàng: vòng sáng nhấp nháy cần vẽ lại liên tục.
	if charge_ratio >= 1.0 and is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	var font := ThemeDB.fallback_font
	var ready_ult := charge_ratio >= 1.0
	# Nền: đĩa tối trong mờ, viền sáng (HudTheme).
	var fill := HudTheme.BUTTON_FILL_HELD if is_held() else HudTheme.BUTTON_FILL
	draw_circle(center, radius, fill)
	if ready_ult:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * TAU / HudTheme.ULT_PULSE_SEC)
		draw_circle(center, radius, Color(HudTheme.COLOR_UG, 0.18 + 0.17 * pulse))
		draw_arc(center, radius + 14.0 + 4.0 * pulse, 0.0, TAU, 64, Color(HudTheme.COLOR_UG, 0.35 * pulse), 6.0)
	draw_arc(center, radius - 2.0, 0.0, TAU, 64, HudTheme.BUTTON_RIM.darkened(0.4 if dimmed else 0.0), 3.0)
	# Icon (hoặc chữ tạm).
	var content_alpha := 0.38 if dimmed or cooldown_ratio > 0.0 else 1.0
	if icon:
		var side := radius * 2.0 * HudTheme.BUTTON_ICON_RATIO
		draw_texture_rect(icon, Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side)), false,
				Color(1, 1, 1, content_alpha))
	elif not label_text.is_empty():
		_draw_centered(font, label_text, center, int(radius * 0.5), Color(1, 1, 1, 0.9 * content_alpha))
	# Quạt hồi chiêu: phủ tối phần còn phải chờ, bắt đầu từ đỉnh, theo chiều kim đồng hồ; số giây ở giữa.
	if cooldown_ratio > 0.0:
		var pts := PackedVector2Array([center])
		for i in 33:
			var a := -PI / 2.0 + TAU * cooldown_ratio * float(i) / 32.0
			pts.append(center + Vector2(cos(a), sin(a)) * radius)
		draw_colored_polygon(pts, HudTheme.COLOR_COOLDOWN)
		draw_arc(center, radius - 2.0, -PI / 2.0, -PI / 2.0 + TAU * cooldown_ratio, 48, HudTheme.COLOR_COOLDOWN_EDGE, 5.0)
	if not overlay_text.is_empty():
		_draw_centered(font, overlay_text, center, int(radius * 0.62), Color.WHITE, true)
	# Vòng nạp (tuyệt kỹ): cung theo lượng UG, đầy thì vàng đậm.
	if charge_ratio >= 0.0:
		draw_arc(center, radius + 7.0, 0.0, TAU, 64, Color(0, 0, 0, 0.45), 8.0)
		draw_arc(center, radius + 7.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(charge_ratio, 0.0, 1.0), 64,
				Color(HudTheme.COLOR_UG, 1.0 if ready_ult else 0.75), 8.0)
	# Huy hiệu số (lượt né): vòng tròn trắng viền đậm, số ở giữa.
	if not badge_text.is_empty():
		var br := maxf(radius * 0.3, 22.0)
		var bc := center + Vector2(radius * 0.72, -radius * 0.72)
		draw_circle(bc, br, Color(0.97, 0.97, 0.97, 0.95))
		draw_arc(bc, br - 2.5, 0.0, TAU, 32, Color(0.05, 0.05, 0.08), 5.0)
		_draw_centered(font, badge_text, bc, int(br * 1.15), Color(0.05, 0.05, 0.08))
	# Phím bàn phím (PC) dưới nút.
	if not key_hint.is_empty():
		_draw_centered(font, key_hint, center + Vector2(0.0, radius + 20.0), HudTheme.KEY_HINT_FONT_SIZE,
				Color(1, 1, 1, 0.85), true)


func _draw_centered(font: Font, text: String, at: Vector2, font_size: int, color: Color, shadow := false) -> void:
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos := at + Vector2(-ts.x * 0.5, font.get_ascent(font_size) - ts.y * 0.5)
	if shadow:
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(0, 0, 0, 0.75))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
