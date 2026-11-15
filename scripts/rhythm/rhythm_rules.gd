class_name RhythmRules
extends Resource
## Thông số chế độ nhịp điệu (M10, docs/design/RHYTHM_MODE.md). Dữ liệu: data/rhythm/rhythm_rules.tres.

@export_group("Cửa sổ chấm (giây, lệch so với thời điểm nốt)")
## |lệch| ≤ giá trị này = Hoàn hảo.
@export var perfect_window := 0.05
## |lệch| ≤ giá trị này = Tốt; trễ hơn = Trượt.
@export var great_window := 0.12
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
@export var score_great := 100
## Mỗi lần ấn trong nốt ấn liên tục.
@export var score_mash_hit := 30
## Cộng thêm theo combo: điểm × (1 + min(combo, combo_bonus_cap) × combo_bonus_step).
@export var combo_bonus_step := 0.002
@export var combo_bonus_cap := 100

@export_group("Fever")
@export var fever_max := 100.0
@export var fever_gain_perfect := 2.0
@export var fever_gain_great := 1.0
@export var fever_duration := 8.0
@export var fever_score_multiplier := 1.5

@export_group("Nốt ấn liên tục")
## Đạt tỉ lệ số lần ấn / yêu cầu này = Hoàn hảo; ≥ mash_great_ratio = Tốt; thấp hơn = Trượt.
@export var mash_perfect_ratio := 1.0
@export var mash_great_ratio := 0.5

@export_group("Hạng (độ chính xác = (Hoàn hảo + Tốt / 2) / tổng)")
@export var rank_s := 0.95
@export var rank_a := 0.9
@export var rank_b := 0.8
@export var rank_c := 0.7

@export_group("Hiển thị")
## Số giây nốt bay từ mép phải tới vạch chấm ở tốc độ 1.
@export var approach_sec := 1.6
## Đếm ngược trước khi nhạc phát (giây).
@export var lead_in_sec := 2.0
## Sau nốt cuối bấy nhiêu giây thì kết thúc nếu nhạc còn dài.
@export var tail_sec := 2.5
