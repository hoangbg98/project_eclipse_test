class_name HitDef
extends Resource
## Một vùng gây sát thương trong kỹ năng (CHARACTER_SKILLS: tầm & phạm vi, sát thương, hiệu ứng).
## Toạ độ theo nhân vật quay PHẢI, gốc ở chân; hệ thống tự lật khi quay trái.

enum Shape { ARC, CIRCLE, RECT }

## Bật lúc nào, tính từ đầu kỹ năng (ms) và kéo dài bao lâu (ms).
@export var at_ms := 0.0
@export var duration_ms := 60.0
@export var atk_ratio := 1.0
## Hệ số sức choáng (mục 0: mặc định ×1).
@export var sc_multiplier := 1.0

@export_group("Hình dạng")
@export var shape := Shape.ARC
## ARC/CIRCLE: bán kính. RECT: bỏ qua.
@export var radius_px := 140.0
## ARC: góc mở (độ), tâm hướng phải; hướng nghiêng (độ, dương = chếch xuống).
@export var arc_deg := 120.0
@export var arc_tilt_deg := 0.0
## RECT: kích thước.
@export var rect_size := Vector2(100, 100)
## Tâm vùng so với chân nhân vật (x dương = phía trước).
@export var offset := Vector2(0, -120)

@export_group("Hiệu ứng")
@export var knockback_px := 0.0
@export var statuses: Array[StatusApplication] = []
## Mục tiêu đang mang trạng thái này (trước đòn) thì đòn gây thêm `bonus_vs_status_ratio` sát thương
## (vd vào sân Liên kết Aether: kẻ địch đang Choáng +30%).
@export var bonus_vs_status := ""
@export var bonus_vs_status_ratio := 0.0

@export_group("Tách khỏi nhân vật")
## true: vùng nằm lại trong thế giới (sóng bay, vệt lửa, vết nổ) thay vì đi theo nhân vật.
@export var detached := false
## Vùng tách: bay về phía trước bao xa trong thời gian tồn tại (px).
@export var travel_px := 0.0
## Vùng tách: góc bay so với phương ngang (độ; dương = chếch xuống), lật theo hướng nhìn (tên hình quạt).
@export var travel_angle_deg := 0.0
## Vùng tách: gây lại sát thương mỗi khoảng này (ms); 0 = chỉ một lần.
@export var tick_interval_ms := 0.0
## Vùng tách: đặt xuống lúc at_ms nhưng chỉ bật sau bấy nhiêu ms (vết chém nổ chậm).
@export var delay_ms := 0.0
## Vùng tách: đặt tại mục tiêu kỹ năng đã chọn (tuyệt kỹ) thay vì tại người đánh.
@export var at_target := false


func end_ms() -> float:
	return at_ms + duration_ms


## Đa giác va chạm theo nhân vật quay phải (gốc tại `offset`).
func build_polygon() -> PackedVector2Array:
	var pts := PackedVector2Array()
	match shape:
		Shape.ARC:
			pts.append(Vector2.ZERO)
			var steps := 12
			var half := deg_to_rad(arc_deg) * 0.5
			var tilt := deg_to_rad(arc_tilt_deg)
			for i in steps + 1:
				var a := -half + (2.0 * half) * float(i) / steps + tilt
				pts.append(Vector2(cos(a), sin(a)) * radius_px)
		Shape.CIRCLE:
			for i in 16:
				var a := TAU * float(i) / 16.0
				pts.append(Vector2(cos(a), sin(a)) * radius_px)
		Shape.RECT:
			var h := rect_size * 0.5
			pts.append_array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	return pts
