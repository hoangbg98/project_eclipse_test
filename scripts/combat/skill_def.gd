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
## Khóa hồi chiêu dùng chung (vd hold_1 và hold_2 cùng "hold"); rỗng = theo khóa kỹ năng.
@export var cooldown_group := ""
## Hồi chiêu bắt đầu khi kỹ năng KẾT THÚC thay vì lúc dùng (tuyệt kỹ: "khóa 2.0 s sau khi dùng").
@export var cooldown_starts_on_end := false
## EN cộng thêm khi trúng, ngoài mức theo loại đòn (Aether giữ TC: +6 = 3 + 3).
@export var extra_en_on_hit := 0.0
## Cần UG đầy để dùng (tuyệt kỹ); > 0 = tiêu toàn bộ UG.
@export var ug_cost := 0.0
## Tìm kẻ địch gần nhất trong bán kính này khi bắt đầu (px); 0 = không nhắm.
@export var target_range_px := 0.0
## Khóa dịch tên chiêu (cut-in tuyệt kỹ, HUD).
@export var name_key := ""
## Dừng thời gian kẻ địch khi bắt đầu (ms) — cut-in tuyệt kỹ.
@export var time_stop_ms := 0.0

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
## Hoặc chỉ trong cửa sổ [gravity_off_from_ms, gravity_off_to_ms) (vd treo 150 ms sau đòn trên không 2).
@export var gravity_off_from_ms := -1.0
@export var gravity_off_to_ms := -1.0
## Bay lên (px, dương = lên trên) trong [rise_from_ms, rise_to_ms); chỉ có tác dụng khi đang tắt trọng lực
## (suspend_gravity) — tuyệt kỹ Kazeyumi bay lên 300 px.
@export var rise_px := 0.0
@export var rise_from_ms := 0.0
@export var rise_to_ms := 0.0
## Giữ vận tốc ngang đang có (đòn trên không) thay vì đứng lại.
@export var keep_momentum := false

## Có mục tiêu (target_range_px): quay về phía mục tiêu và đi tới nó thay vì đi `move_px` cố định:
## quãng = |khoảng cách| − approach_stop_px, tối đa approach_max_px (Kĩ năng vào sân Aether, Kael).
@export var approach_target := false
@export var approach_max_px := 0.0
@export var approach_stop_px := 60.0
## Tới mục tiêu tức thì lúc bắt đầu (dịch chuyển) thay vì lướt trong [move_from_ms, move_to_ms).
@export var teleport := false
## Ưu tiên mục tiêu: id trạng thái (vd "stun"), hoặc "elemental" = đang mang hiệu ứng nguyên tố. Rỗng = gần nhất.
@export var target_prefer := ""

@export_group("Nạp (đòn giữ)")
## Giữ nút bao lâu thì bắt đầu nạp (ms); nhả sớm hơn là đòn thường.
@export var charge_start_ms := 0.0
## Giữ tới mức này thì nhả ra kỹ năng này (Cấp 1: 700, Cấp 2: 1500).
@export var charge_level_ms := 0.0
## Giảm tốc độ di chuyển khi đang nạp (0.4 = chậm 40%).
@export var charge_move_slow := 0.0
## Giữ tới charge_level_ms thì chạy ngay, không chờ nhả (Lôi Quang Loạn Vũ của Raikiba).
@export var fire_on_charge := false
## Nhả nút đánh trong lúc kỹ năng chạy thì dừng sớm (đòn giữ chém liên tục).
@export var release_ends := false

@export_group("Lao xuống (đáp đất)")
## Tốc độ lao xuống (px/s); > 0 = kỹ năng đáp đất.
@export var dive_speed_px := 0.0
## Phải cao hơn mặt đất ít nhất bấy nhiêu mới dùng được (px).
@export var min_height_px := 0.0
## Treo trên không bấy nhiêu ms trước khi lao.
@export var pre_dive_ms := 0.0
## Góc lao so với phương thẳng đứng (độ), nghiêng về hướng mặt; 0 = lao thẳng xuống (Raikiba: 45).
@export var dive_angle_deg := 0.0

@export_group("Bản thân")
## Trạng thái áp lên chính người dùng khi kỹ năng bắt đầu (buff của vùng, tuyệt kỹ).
@export var self_statuses: Array[StatusApplication] = []
## Không dùng được đòn thường trong bấy nhiêu ms kể từ khi bắt đầu (vẫn di chuyển, né, dùng kỹ năng).
@export var blocks_normal_ms := 0.0

@export_group("Phòng thủ")
## Bất tử trong [invuln_from_ms, invuln_to_ms); âm = không.
@export var invuln_from_ms := -1.0
@export var invuln_to_ms := -1.0
## Kháng khựng suốt kỹ năng.
@export var super_armor := false
## Không cho chuyển nhân vật khi kỹ năng đang chạy (tuyệt kỹ loại chuỗi đòn, mục 0 / 8.1).
@export var locks_switch := false

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


func cooldown_key() -> String:
	return cooldown_group if cooldown_group != "" else id.get_slice(".", 1)


func gravity_off_at(ms: float) -> bool:
	if suspend_gravity:
		return true
	return gravity_off_from_ms >= 0.0 and ms >= gravity_off_from_ms and ms < gravity_off_to_ms


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
