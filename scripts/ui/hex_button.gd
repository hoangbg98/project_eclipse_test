class_name HexButton
extends BaseButton
## Nút lục giác của màn Hub (owner 2026-11-14, theo ảnh tham chiếu): nền kính tối viền sáng, icon trắng ở giữa,
## chữ dưới icon, huy hiệu "Mới!" tùy chọn. Chỉ nhận chạm / bấm trong hình lục giác (đỉnh hướng lên).
## Màu và độ dày lấy từ các biến dưới đây (Hub đặt theo data/ui/hub_home_layout.json).

var label_text := ""
var icon: Texture2D
## Chữ nhỏ góc trên-phải (vd "Mới!"); rỗng = không vẽ.
var badge_text := ""
var font_size := 30
var fill := Color(0.08, 0.12, 0.2, 0.78)
var fill_hover := Color(0.12, 0.2, 0.32, 0.86)
var rim := Color("#7FD4FF")
var glow := Color(0.5, 0.83, 1.0, 0.35)
var text_color := Color.WHITE
var badge_color := Color("#FFD23F")
## Ảnh nền trong lòng lục giác (vd ảnh màn chơi cho nút Xuất kích); null = chỉ màu.
var background: Texture2D


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


## Đỉnh lục giác (đỉnh hướng lên), bán kính `r` quanh tâm khung.
func hex_points(r: float) -> PackedVector2Array:
	var c := size * 0.5
	var pts := PackedVector2Array()
	for i in 6:
		var a := deg_to_rad(-90.0 + 60.0 * i)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


func radius() -> float:
	return minf(size.x / sqrt(3.0), size.y * 0.5)


func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, hex_points(radius()))


func _draw() -> void:
	var r := radius()
	var outer := hex_points(r)
	var inner := hex_points(r - 8.0)
	var hot := is_hovered() or is_pressed()
	# Quầng ngoài.
	var halo := hex_points(r + 4.0)
	halo.append(halo[0])
	draw_polyline(halo, glow, 8.0, true)
	draw_colored_polygon(outer, fill_hover if hot else fill)
	if background:
		var uvs := PackedVector2Array()
		var tex_size := background.get_size()
		var side := minf(tex_size.x, tex_size.y)
		var off := (tex_size - Vector2(side, side)) * 0.5
		var c := size * 0.5
		for p in inner:
			uvs.append((off + (p - c + Vector2(r, r)) / (2.0 * r) * side) / tex_size)
		draw_colored_polygon(inner, Color(1, 1, 1, 0.9), uvs, background)
		draw_colored_polygon(inner, Color(0, 0, 0, 0.25))
	var ring := outer.duplicate()
	ring.append(ring[0])
	draw_polyline(ring, rim if not hot else rim.lightened(0.3), 4.0, true)
	var ring2 := inner.duplicate()
	ring2.append(ring2[0])
	draw_polyline(ring2, Color(rim, 0.35), 2.0, true)
	var font := ThemeDB.fallback_font
	var c := size * 0.5
	var text_h := float(font_size) * 1.2 if label_text != "" else 0.0
	if icon:
		var side := r * 0.95
		var top := c.y - side * 0.5 - text_h * 0.35
		draw_texture_rect(icon, Rect2(c.x - side * 0.5, top, side, side), false)
	if label_text != "":
		var ts := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var y := c.y + r * (0.62 if icon else 0.0) + (0.0 if icon else font.get_ascent(font_size) * 0.5)
		var pos := Vector2(c.x - ts.x * 0.5, y)
		draw_string_outline(font, pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(0, 0, 0, 0.8))
		draw_string(font, pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	if badge_text != "":
		var bs := 24
		var bpos := c + Vector2(r * 0.25, -r * 0.62)
		draw_string_outline(font, bpos, badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, bs, 6, Color(0, 0, 0, 0.8))
		draw_string(font, bpos, badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, bs, badge_color)
