class_name RhythmRules
extends Resource
## Thông số chế độ nhịp điệu (M10, docs/design/RHYTHM_MODE.md). Dữ liệu: data/rhythm/rhythm_rules.tres.

@export_group("Chấm theo độ khớp hitbox với vòng chấm (owner 2026-11-16)")
## Bán kính vòng chấm cạnh nhân vật (px khung 1920x1080). Hitbox vàng giữa thân quái cùng bán kính: vào giữa vòng là khít.
@export var ring_radius := 72.0
## Độ dày viền ngoài vòng chấm (px): hitbox chỉ chạm phần viền này = Miss.
@export var ring_rim := 10.0
## Tốc độ quái chạy về vòng chấm (px / giây, khung 1920x1080). Đổi khoảng cách thành thời gian lệch.
@export var note_speed := 800.0
## Tỉ lệ diện tích hitbox nằm trong vòng: ≥ perfect = Perfect (khít), ≥ great = Great, ≥ good = Good,
## > 0 (đã qua viền vào trong vòng) = Normal, chỉ chạm viền ngoài = Miss.
@export var perfect_overlap := 0.85
@export var great_overlap := 0.75
@export var good_overlap := 0.5
## Hai phím ấn cách nhau ≤ giá trị này tính là ấn cùng lúc (nốt "cả hai"). Nốt một làn cũng chờ chừng này
## để biết người chơi có ấn thêm làn kia (chọn nhầm) hay không.
@export var chord_window := 0.06
## Nốt giữ: thả sớm hơn cuối thanh quá giá trị này = gãy.
@export var hold_release_tolerance := 0.12

@export_group("HP")
@export var max_hp := 250
## Để nốt trôi qua (không ấn).
@export var miss_damage := 20
## Chọn sai (trên / dưới / cả hai).
@export var wrong_damage := 25
## Nốt giữ thả sớm.
@export var hold_break_damage := 10

@export_group("Điểm")
@export var score_perfect := 200
@export var score_great := 150
@export var score_good := 100
@export var score_normal := 50
## Mỗi lần ấn trong nốt ấn liên tục.
@export var score_mash_hit := 30
## Cộng thêm theo combo: điểm × (1 + min(combo, combo_bonus_cap) × combo_bonus_step).
@export var combo_bonus_step := 0.002
@export var combo_bonus_cap := 100

@export_group("Fever")
@export var fever_max := 100.0
@export var fever_gain_perfect := 2.0
@export var fever_gain_great := 1.5
@export var fever_gain_good := 1.0
@export var fever_duration := 8.0
@export var fever_score_multiplier := 1.5

@export_group("Nốt ấn liên tục")
## Đạt tỉ lệ số lần ấn / yêu cầu này = Hoàn hảo; ≥ mash_great_ratio = Tốt; thấp hơn = Trượt.
@export var mash_perfect_ratio := 1.0
@export var mash_great_ratio := 0.5

@export_group("Hạng (độ chính xác = (Perfect + Great × 0.75 + Good × 0.5 + Normal × 0.25) / tổng)")
@export var rank_s := 0.95
@export var rank_a := 0.9
@export var rank_b := 0.8
@export var rank_c := 0.7

@export_group("Hiển thị")
## Đếm ngược trước khi nhạc phát (giây).
@export var lead_in_sec := 2.0
## Sau nốt cuối bấy nhiêu giây thì kết thúc nếu nhạc còn dài.
@export var tail_sec := 2.5


## Tỉ lệ diện tích chồng nhau của hai hình tròn cùng bán kính r, tâm cách nhau d (0..1).
static func overlap_fraction(d: float, r: float) -> float:
	if r <= 0.0:
		return 0.0
	var x := absf(d) / r
	if x >= 2.0:
		return 0.0
	return (2.0 * acos(x / 2.0) - (x / 2.0) * sqrt(4.0 - x * x)) / PI


## Khoảng cách tâm hitbox - tâm vòng khi lệch `offset_sec` giây so với nhịp.
func distance_at(offset_sec: float) -> float:
	return absf(offset_sec) * note_speed


## Chấm một lần ấn lệch `offset_sec` giây: "perfect" | "great" | "good" | "normal" | "miss" | "" (quá xa, chưa chạm vòng).
func grade(offset_sec: float) -> String:
	var d := distance_at(offset_sec)
	if d > 2.0 * ring_radius + ring_rim:
		return ""
	if d >= 2.0 * ring_radius:
		return "miss"
	var f := overlap_fraction(d, ring_radius)
	if f >= perfect_overlap:
		return "perfect"
	if f >= great_overlap:
		return "great"
	if f >= good_overlap:
		return "good"
	return "normal"


## Lệch tối đa (giây) còn chạm được vòng (kể cả viền ngoài): ấn sớm hơn = vung trống, trễ hơn = nốt đã trôi qua.
func reach_sec() -> float:
	return (2.0 * ring_radius + ring_rim) / maxf(note_speed, 1.0)


## Lệch (giây) mà độ chồng đúng bằng `fraction` (để hiển thị / test). Tìm nhị phân.
func offset_for_overlap(fraction: float) -> float:
	var lo := 0.0
	var hi := 2.0 * ring_radius
	for i in 40:
		var mid := (lo + hi) * 0.5
		if overlap_fraction(mid, ring_radius) > fraction:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5 / maxf(note_speed, 1.0)
