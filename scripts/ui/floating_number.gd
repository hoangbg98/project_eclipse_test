class_name FloatingNumber
extends Label
## Số sát thương bay lên rồi mờ dần (README 15.7: số sát thương mỗi đòn). Bản tạm; hoàn thiện ở M3-7.

const LIFETIME := 0.8
const RISE_PX := 90.0

var _age := 0.0
var _start := Vector2.ZERO


static func spawn(parent: Node, world_pos: Vector2, amount: int, crit := false, dot := false) -> FloatingNumber:
	var n := FloatingNumber.new()
	n.text = str(amount) + ("!" if crit else "")
	n.add_theme_font_size_override("font_size", 52 if crit else (30 if dot else 38))
	n.add_theme_color_override("font_color", Color("#FFD93D") if crit else (Color("#FF8A4D") if dot else Color.WHITE))
	n.add_theme_color_override("font_outline_color", Color.BLACK)
	n.add_theme_constant_override("outline_size", 8)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.size = Vector2(200, 60)
	n.z_index = 50
	parent.add_child(n)
	n._start = world_pos + Vector2(-100 + randf_range(-30, 30), -30)
	n.global_position = n._start
	return n


func _process(delta: float) -> void:
	_age += delta
	var t := _age / LIFETIME
	global_position = _start + Vector2(0, -RISE_PX * t)
	modulate.a = 1.0 - clampf((t - 0.5) * 2.0, 0.0, 1.0)
	if _age >= LIFETIME:
		queue_free()
