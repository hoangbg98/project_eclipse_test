class_name FloatingNumber
extends Label
## Số sát thương nảy lên rồi mờ dần (README 15.7).

enum Kind { NORMAL, CRIT, DOT, PLAYER_HURT }

const LIFETIME := 0.8
const RISE_PX := 90.0
const STYLE := {
	Kind.NORMAL: [38, Color.WHITE],
	Kind.CRIT: [56, Color("#FFD93D")],
	Kind.DOT: [28, Color("#FF8A4D")],
	Kind.PLAYER_HURT: [40, Color("#FF4D5E")],
}

var _age := 0.0
var _start := Vector2.ZERO
var kind := Kind.NORMAL


static func spawn(parent: Node, world_pos: Vector2, amount: int, p_kind: Kind = Kind.NORMAL) -> FloatingNumber:
	var n := FloatingNumber.new()
	n.kind = p_kind
	n.text = str(amount) + ("!" if p_kind == Kind.CRIT else "")
	n.add_theme_font_size_override("font_size", STYLE[p_kind][0])
	n.add_theme_color_override("font_color", STYLE[p_kind][1])
	n.add_theme_color_override("font_outline_color", Color.BLACK)
	n.add_theme_constant_override("outline_size", 8)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.size = Vector2(240, 70)
	n.pivot_offset = n.size * 0.5
	n.z_index = 50
	parent.add_child(n)
	# Lệch ngang nhẹ theo số để các số liền nhau không chồng (không dùng ngẫu nhiên).
	var jitter := float((amount * 37) % 60) - 30.0
	n._start = world_pos + Vector2(-120 + jitter, -35)
	n.global_position = n._start
	return n


func _process(delta: float) -> void:
	_age += delta
	var t := _age / LIFETIME
	global_position = _start + Vector2(0, -RISE_PX * t)
	# Nảy: phóng 1.35 → 1.0 trong 0.12 s đầu (chí mạng nảy mạnh hơn).
	var pop := 1.6 if kind == Kind.CRIT else 1.35
	scale = Vector2.ONE * lerpf(pop, 1.0, clampf(_age / 0.12, 0.0, 1.0))
	modulate.a = 1.0 - clampf((t - 0.55) / 0.45, 0.0, 1.0)
	if _age >= LIFETIME:
		queue_free()
