class_name ParallaxBackdrop
extends Node2D
## Nền nhiều lớp trượt theo camera (README "Parallax and layered backgrounds"). Hình tạm: các dãy đồi đa giác
## sinh theo seed cố định; thay bằng ảnh nền thật khi owner giao (mỗi lớp một Sprite2D trong Parallax2D).

## [hệ số trượt, màu, độ cao đỉnh (px), số đỉnh mỗi đoạn lặp]
const LAYERS := [
	[0.15, Color(0.16, 0.19, 0.30), 520.0, 5],
	[0.35, Color(0.20, 0.22, 0.33), 400.0, 7],
	[0.60, Color(0.25, 0.25, 0.36), 280.0, 9],
]
const REPEAT_WIDTH := 1920.0
## Đáy các lớp (y, theo tọa độ thế giới): mặt đất của màn.
@export var base_y := 960.0

var layers: Array[Parallax2D] = []


func _ready() -> void:
	z_index = -20
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261112
	for spec in LAYERS:
		var p := Parallax2D.new()
		p.scroll_scale = Vector2(float(spec[0]), 1.0)
		p.repeat_size = Vector2(REPEAT_WIDTH, 0.0)
		p.repeat_times = 4
		var poly := Polygon2D.new()
		poly.color = spec[1]
		var pts := PackedVector2Array([Vector2(0, base_y + 400.0)])
		var n: int = spec[3]
		var first_h := float(spec[2]) * rng.randf_range(0.55, 1.0)
		for i in n + 1:
			var h := first_h if i == 0 or i == n else float(spec[2]) * rng.randf_range(0.45, 1.0)   # hai mép khớp nhau khi lặp
			pts.append(Vector2(REPEAT_WIDTH * float(i) / n, base_y - h))
		pts.append(Vector2(REPEAT_WIDTH, base_y + 400.0))
		poly.polygon = pts
		p.add_child(poly)
		add_child(p)
		layers.append(p)


## Thay nền tạm bằng ảnh thật theo data màn: [{image: "res://...png", scroll: 0.1}, ...] từ xa tới gần.
## Mỗi ảnh co về cao VIEW_HEIGHT, đáy ảnh ở base_y + BOTTOM_PAD (phần dưới bị nền đất che), lặp ngang liền mạch.
## Không ảnh nào có thật thì giữ nền tạm. Trả về số lớp ảnh đã dùng.
const VIEW_HEIGHT := 1080.0
const BOTTOM_PAD := 120.0

func use_images(specs: Array) -> int:
	var found: Array[Array] = []
	for spec: Variant in specs:
		if spec is Dictionary and ResourceLoader.exists(str(spec.get("image", ""))):
			var tex := load(str(spec["image"])) as Texture2D
			if tex and tex.get_height() > 0:
				found.append([tex, float(spec.get("scroll", 0.3))])
	if found.is_empty():
		return 0
	for p in layers:
		p.queue_free()
	layers.clear()
	for f in found:
		var tex: Texture2D = f[0]
		var k := VIEW_HEIGHT / tex.get_height()
		var p := Parallax2D.new()
		p.scroll_scale = Vector2(float(f[1]), 1.0)
		p.repeat_size = Vector2(tex.get_width() * k, 0.0)
		p.repeat_times = 4
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		sp.scale = Vector2(k, k)
		sp.position = Vector2(0.0, base_y + BOTTOM_PAD - VIEW_HEIGHT)
		p.add_child(sp)
		add_child(p)
		layers.append(p)
	return found.size()
