class_name TileButton
extends BaseButton
## Ô ghép nghiêng của sảnh chính (owner 2026-11-14, theo ảnh tham chiếu dự án cũ): hình bình hành (cạnh trên lệch phải
## `skew` px), ảnh phủ kín ô (cắt theo `art_crop`), dải màu dưới chứa tên, icon ở giữa khi chưa có ảnh, nhãn nhỏ góc
## (vd "Sắp có!"). Chỉ nhận chạm trong hình bình hành. Màu / ảnh / chữ do sảnh đặt theo data/ui/hub_home_layout.json.

var label_text := ""
var art: Texture2D
## Vùng ảnh dùng (tỉ lệ 0..1 của ảnh).
var art_crop := Rect2(0, 0, 1, 1)
var icon: Texture2D
var badge_text := ""
var bar_color := Color("#C8324A")
var fill := Color(0.12, 0.14, 0.22, 0.9)
var text_color := Color.WHITE
var badge_color := Color("#FFD23F")
var font_size := 38
var skew := 34.0
## Chiều cao dải chữ (px).
var bar_height := 74.0


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


## Bình hành trong khung [0, w] × [y0, y1], cạnh trên lệch phải `skew` px (lệch tỉ lệ theo chiều cao).
func shape(y0 := 0.0, y1 := -1.0) -> PackedVector2Array:
	var h := size.y
	if y1 < 0.0:
		y1 = h
	var off := func(y: float) -> float: return skew * (1.0 - y / h)
	return PackedVector2Array([Vector2(off.call(y0), y0), Vector2(size.x - skew + off.call(y0), y0),
			Vector2(size.x - skew + off.call(y1), y1), Vector2(off.call(y1), y1)])


func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, shape())


func _draw() -> void:
	var hot := is_hovered() or is_pressed()
	var poly := shape()
	draw_colored_polygon(poly, fill)
	if art:
		var ts := art.get_size()
		var src := Rect2(art_crop.position * ts, art_crop.size * ts)
		# Phủ kín ô, giữ tỉ lệ (cắt phần thừa).
		var scale := maxf(size.x / src.size.x, size.y / src.size.y)
		var view := size / scale
		var origin := src.position + (src.size - view) * 0.5
		var uvs := PackedVector2Array()
		for p in poly:
			uvs.append((origin + p / scale) / ts)
		draw_colored_polygon(poly, Color.WHITE if not hot else Color(1.12, 1.12, 1.12), uvs, art)
	elif icon:
		var side := minf(size.x, size.y - bar_height) * 0.6
		draw_texture_rect(icon, Rect2((size.x - side) * 0.5, (size.y - bar_height - side) * 0.5, side, side), false,
				Color(1, 1, 1, 0.92))
	if hot:
		draw_colored_polygon(poly, Color(1, 1, 1, 0.08))
	# Dải chữ dưới.
	var bar := shape(size.y - bar_height, size.y)
	draw_colored_polygon(bar, Color(bar_color, 0.92))
	var edge := shape(size.y - bar_height, size.y - bar_height + 4.0)
	draw_colored_polygon(edge, bar_color.lightened(0.35))
	var ring := poly.duplicate()
	ring.append(ring[0])
	draw_polyline(ring, Color(1, 1, 1, 0.75 if hot else 0.45), 3.0, true)
	var font := ThemeDB.fallback_font
	if label_text != "":
		var ts := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		# Tâm dải chữ: giữa hai cạnh bên tại độ cao giữa dải.
		var mid_off := skew * (bar_height * 0.5 / size.y)
		var bar_mid_x := (size.x - skew) * 0.5 + mid_off
		var pos := Vector2(bar_mid_x - ts.x * 0.5, size.y - bar_height * 0.5 + font.get_ascent(font_size) * 0.38)
		draw_string_outline(font, pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(0, 0, 0, 0.55))
		draw_string(font, pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	if badge_text != "":
		var bw := font.get_string_size(badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		var bpos := Vector2(size.x - bw - 24.0, 40.0)
		draw_string_outline(font, bpos, badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Color(0, 0, 0, 0.8))
		draw_string(font, bpos, badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, badge_color)
