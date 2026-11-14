class_name AiCore
extends Control
## Chân dung trợ lý AI NEO vẽ bằng code (chưa có art): lõi sáng, hai vòng quay ngược chiều, sóng âm khi đang nói.
## Dùng ở khung hướng dẫn (TutorialGuide) và băng thoại trong trận (NeoBark).

var t := 0.0

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	var col := Color("#5CE1FF")
	draw_circle(c, r * 0.98, Color(0.02, 0.1, 0.18, 0.95))
	draw_arc(c, r * 0.94, 0.0, TAU, 64, Color(col, 0.35), 2.0, true)
	draw_arc(c, r * 0.82, t * 1.6, t * 1.6 + TAU * 0.65, 48, Color(col, 0.9), 4.0, true)
	draw_arc(c, r * 0.68, -t * 2.3, -t * 2.3 + TAU * 0.4, 40, Color(col, 0.6), 3.0, true)
	var pulse := 0.5 + 0.5 * sin(t * TAU / 1.4)
	draw_circle(c, r * (0.30 + 0.05 * pulse), Color(col, 0.25 + 0.15 * pulse))
	draw_circle(c, r * 0.20, Color(0.85, 0.98, 1.0, 0.95))
	for i in 5:   # sóng âm nhỏ dưới lõi
		var x := c.x + (i - 2) * r * 0.14
		var hgt := r * (0.06 + 0.08 * absf(sin(t * 7.0 + i * 1.3)))
		draw_line(Vector2(x, c.y + r * 0.5 - hgt), Vector2(x, c.y + r * 0.5 + hgt), Color(col, 0.8), 3.0, true)
