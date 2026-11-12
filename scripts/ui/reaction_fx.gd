class_name ReactionFx
extends Node2D
## Hiển thị tạm cho phản ứng nguyên tố (CHARACTER_SKILLS 8.4): hai quả cầu màu của hai nguyên tố
## va vào nhau trong `orb_sec`, rồi tên phản ứng hiện `name_sec`. Thay bằng VFX thật khi owner giao.

var orb_sec := 0.3
var name_sec := 0.8
var color_a := Color.WHITE
var color_b := Color.WHITE

var _age := 0.0
var _label: Label


func setup(text: String, a: Color, b: Color, p_orb_sec: float, p_name_sec: float) -> void:
	color_a = a
	color_b = b
	orb_sec = p_orb_sec
	name_sec = p_name_sec
	z_index = 60
	_label = Label.new()
	_label.text = text
	_label.add_theme_font_size_override("font_size", 52)
	_label.add_theme_color_override("font_color", a.lerp(b, 0.5).lightened(0.35))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 10)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(600, 70)
	_label.position = Vector2(-300, -110)
	add_child(_label)


func text() -> String:
	return _label.text if _label else ""


func _process(delta: float) -> void:
	_age += delta
	var total := maxf(orb_sec, name_sec)
	if _label:
		_label.modulate.a = 1.0 - clampf((_age - name_sec * 0.75) / (name_sec * 0.25), 0.0, 1.0)
		_label.position.y = -110.0 - 30.0 * clampf(_age / name_sec, 0.0, 1.0)
	queue_redraw()
	if _age >= total:
		queue_free()


func _draw() -> void:
	if _age >= orb_sec:
		# Chớp sáng ngắn sau va chạm.
		var k := clampf((_age - orb_sec) / 0.15, 0.0, 1.0)
		if k < 1.0:
			draw_circle(Vector2.ZERO, 40.0 + 90.0 * k, Color(1, 1, 1, 0.6 * (1.0 - k)))
		return
	var t := _age / maxf(orb_sec, 0.001)
	var d := lerpf(160.0, 0.0, t * t)
	draw_circle(Vector2(-d, 0), 34.0, color_a)
	draw_circle(Vector2(d, 0), 34.0, color_b)
