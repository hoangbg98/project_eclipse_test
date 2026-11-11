class_name SkillDef
extends Resource
## Định nghĩa một kỹ năng / một đòn (CHARACTER_SKILLS mục 1-6). Dữ liệu ở data/skills/{id nhân vật}/.
## Thời gian (ms) tính từ lúc bắt đầu: khởi động → hiệu lực → hồi phục (mục 0).

## Khóa dữ liệu, vd "char_fire_01.normal_1".
@export var id := ""
## Khóa loại (normal, dodge, hold, air, landing, skill, weapon, ultimate).
@export var key := ""
## Tên animation sprite (frames_manifest), vd "attack_1".
@export var animation := ""
## Loại đòn để cộng EN/UG (ResourceComponent.HitKind).
@export var hit_kind := 0

@export_group("Tiêu hao")
@export var en_cost := 0.0
@export var cooldown_sec := 0.0
@export var cooldown_uses_cdr := true

@export_group("Pha (ms)")
@export var startup_ms := 100.0
@export var active_ms := 100.0
@export var recovery_ms := 200.0

@export_group("Vùng gây sát thương")
@export var hits: Array[HitDef] = []

@export_group("Di chuyển")
## Dịch chuyển về phía trước (px) trong khoảng [move_from_ms, move_to_ms).
@export var move_px := 0.0
@export var move_from_ms := 0.0
@export var move_to_ms := 0.0
## Không chịu trọng lực suốt kỹ năng (lướt, treo trên không).
@export var suspend_gravity := false

@export_group("Phòng thủ")
## Bất tử trong [invuln_from_ms, invuln_to_ms); âm = không.
@export var invuln_from_ms := -1.0
@export var invuln_to_ms := -1.0
## Kháng khựng suốt kỹ năng.
@export var super_armor := false

@export_group("Nối đòn")
## Bấm trong bấy nhiêu ms CUỐI ĐÒN thì đòn `next_skill` chạy ngay khi đòn này kết thúc.
## (Tài liệu ghi "260 ms cuối pha hồi phục" nhưng đòn 1-2 chỉ hồi phục 160 ms → tính trên cả đòn.)
@export var chain_window_ms := 0.0
## Khóa của đòn kế tiếp trong chuỗi (vd "normal_2"); rỗng = hết chuỗi.
@export var next_skill := ""


func total_ms() -> float:
	return startup_ms + active_ms + recovery_ms


func active_start_ms() -> float:
	return startup_ms


func recovery_start_ms() -> float:
	return startup_ms + active_ms


## Mục 0: nửa sau pha hồi phục có thể huỷ bằng né.
func dodge_cancel_from_ms() -> float:
	return recovery_start_ms() + recovery_ms * 0.5


func chain_from_ms() -> float:
	return total_ms() - chain_window_ms


func is_invulnerable_at(ms: float) -> bool:
	return invuln_from_ms >= 0.0 and ms >= invuln_from_ms and ms < invuln_to_ms


## Tổng % ATK của mọi vùng (để đối chiếu với tài liệu).
func total_atk_ratio() -> float:
	var s := 0.0
	for h in hits:
		var ticks := 1
		if h.detached and h.tick_interval_ms > 0.0:
			ticks = int(floor(h.duration_ms / h.tick_interval_ms + 0.0001))
		s += h.atk_ratio * ticks
	return s


func validate() -> PackedStringArray:
	var e := PackedStringArray()
	if id.is_empty() or key.is_empty():
		e.append("thiếu id/key")
	if startup_ms < 0.0 or active_ms < 0.0 or recovery_ms < 0.0:
		e.append("%s: pha âm" % id)
	if chain_window_ms > total_ms():
		e.append("%s: chain_window_ms dài hơn cả đòn" % id)
	for h in hits:
		if not h.detached and h.end_ms() > total_ms() + 0.001:
			e.append("%s: vùng gắn nhân vật vượt quá thời lượng kỹ năng" % id)
		if h.duration_ms <= 0.0:
			e.append("%s: vùng có thời lượng 0" % id)
	return e
