class_name PlaceholderArt
extends Control
## Vùng ảnh: có `texture` thì vẽ ảnh (giữ tỉ lệ, vừa khung hoặc cắt theo `crop`); chưa có ảnh thì vẽ hình người
## placeholder kèm tên vùng (`label_text`) để phân biệt từng khu vực (yêu cầu owner 2026-11-12).

var texture: Texture2D
var label_text := ""
## Vùng cắt trong ảnh (tỉ lệ 0..1), vd Rect2(0, 0, 1, 0.42) lấy phần đầu của ảnh đứng.
var crop := Rect2(0, 0, 1, 1)


## Vùng cắt (tỉ lệ 0..1) lấy phần vuông phía trên của ảnh dọc (ảnh vết thánh 1248 × 2280, nhân vật vừa khít khung,
## owner 2026-11-15: đầu → thân, kiểu chân dung) để hiện trong khung ngang / vuông; ảnh ngang hoặc vuông: cả ảnh.
static func center_square(tex: Texture2D) -> Rect2:
	if tex == null or tex.get_height() <= tex.get_width():
		return Rect2(0, 0, 1, 1)
	return Rect2(0, 0, 1, float(tex.get_width()) / float(tex.get_height()))
var fill_color := Color("#3A3F55")
var figure_color := Color("#5B6180")
var text_color := Color("#D8DCEB")
var border_color := Color(1, 1, 1, 0.25)
var font_size := 22
var dimmed := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func is_placeholder() -> bool:
	return texture == null


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if texture:
		var src := Rect2(crop.position * texture.get_size(), crop.size * texture.get_size())
		var scale := minf(r.size.x / src.size.x, r.size.y / src.size.y)
		var dst_size := src.size * scale
		var dst := Rect2((r.size - dst_size) * 0.5, dst_size)
		draw_texture_rect_region(texture, dst, src, Color(0.45, 0.45, 0.5) if dimmed else Color.WHITE)
		return
	draw_rect(r, fill_color)
	draw_rect(r, border_color, false, 2.0)
	# Hình người: đầu tròn + thân hình thang, cao ~70% khung.
	var h := minf(r.size.y * 0.72, r.size.x * 1.6)
	var c := Vector2(r.size.x * 0.5, r.size.y * 0.5 - h * 0.05)
	var head := h * 0.16
	draw_circle(c + Vector2(0, -h * 0.5 + head), head, figure_color)
	var top := c.y - h * 0.5 + head * 2.2
	var body := PackedVector2Array([
		Vector2(c.x - h * 0.16, top), Vector2(c.x + h * 0.16, top),
		Vector2(c.x + h * 0.26, c.y + h * 0.5), Vector2(c.x - h * 0.26, c.y + h * 0.5)])
	draw_colored_polygon(body, figure_color)
	if label_text != "":
		var font := ThemeDB.fallback_font
		var fs := mini(font_size, int(r.size.y * 0.18))
		draw_string(font, Vector2(4, r.size.y - fs * 0.6), label_text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 8, fs, text_color)
