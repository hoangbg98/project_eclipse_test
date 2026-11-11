extends SceneTree
## Sinh ảnh placeholder nhân vật (chạy tay, không chạy trong game).
## Chạy: godot --headless --path . --script res://tools/gen_placeholders.gd
##
## placeholder_character_384.png: canvas 384x384 trong suốt, thân hình viên nang màu xám
## cao 256 px đứng trên đường chân y = 336, tâm x = 192, có mũi tam giác chỉ hướng phải.
## Màu nguyên tố được tô bằng modulate khi chạy, nên ảnh để xám.

const OUT_DIR := "res://assets/placeholders"
const SIZE := 384
const PIVOT := Vector2i(192, 336)
const BODY_W := 96
const BODY_H := 256


func _initialize() -> void:
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var body := Color(0.82, 0.82, 0.82, 1.0)
	var edge := Color(0.35, 0.35, 0.35, 1.0)
	var left := PIVOT.x - BODY_W / 2
	var top := PIVOT.y - BODY_H
	var r := BODY_W / 2
	for y in range(top, PIVOT.y):
		for x in range(left, left + BODY_W):
			var inside := true
			# Bo tròn đầu và chân
			if y < top + r:
				inside = Vector2(x + 0.5, y + 0.5).distance_to(Vector2(PIVOT.x, top + r)) <= r
			elif y >= PIVOT.y - r:
				inside = Vector2(x + 0.5, y + 0.5).distance_to(Vector2(PIVOT.x, PIVOT.y - r)) <= r
			if inside:
				img.set_pixel(x, y, body)
	# Viền 3 px
	var copy := img.duplicate()
	for y in SIZE:
		for x in SIZE:
			if copy.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
					Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2),
					Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3)]:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < SIZE and p.y < SIZE and copy.get_pixelv(p).a > 0.0:
					img.set_pixel(x, y, edge)
					break
	# Mũi tam giác hướng phải (ngang tầm mắt)
	var eye_y := top + 70
	for i in 40:
		for j in range(-(20 - i / 2), 20 - i / 2):
			img.set_pixel(PIVOT.x + BODY_W / 2 - 6 + i, eye_y + j, edge)
	# Vạch đường chân để kiểm tra pivot bằng mắt
	for x in range(PIVOT.x - 70, PIVOT.x + 70):
		img.set_pixel(x, PIVOT.y, Color(1, 0.3, 0.3, 1))

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var ok := _save(img, "placeholder_character_384.png")
	ok = _save(_tiles(), "placeholder_tiles_64.png") and ok
	quit(0 if ok else 1)


func _save(img: Image, file: String) -> bool:
	var path := OUT_DIR.path_join(file)
	var err := img.save_png(ProjectSettings.globalize_path(path))
	print("save %s -> %s" % [path, error_string(err)])
	return err == OK


## placeholder_tiles_64.png: atlas 128x64.
## Ô (0,0): khối đặc (đá xám xanh, viền sáng phía trên).
## Ô (1,0): platform một chiều (thanh gỗ 16 px trên cùng, phần dưới trong suốt).
func _tiles() -> Image:
	var t := 64
	var img := Image.create_empty(t * 2, t, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var base := Color(0.29, 0.33, 0.42)
	var dark := Color(0.2, 0.23, 0.3)
	var top := Color(0.55, 0.62, 0.75)
	for y in t:
		for x in t:
			var c := base
			if y < 4:
				c = top
			elif x == 0 or y == t - 1 or x == t - 1:
				c = dark
			elif (x / 16 + y / 16) % 2 == 0:
				c = base.lightened(0.04)
			img.set_pixel(x, y, c)
	var wood := Color(0.62, 0.45, 0.28)
	var wood_dark := Color(0.42, 0.29, 0.17)
	for y in 16:
		for x in t:
			var c := wood if y > 1 and y < 14 else wood_dark
			if x % 16 == 0:
				c = wood_dark
			img.set_pixel(t + x, y, c)
	return img
