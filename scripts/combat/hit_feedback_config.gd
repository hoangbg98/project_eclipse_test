class_name HitFeedbackConfig
extends Resource
## Thông số phản hồi đòn (README 15.7). Dữ liệu: data/config/hit_feedback.tres.

@export_group("Hit-stop (ms)")
@export var hitstop_enabled := true
## Đòn thường.
@export var hitstop_light_ms := 45.0
## Đòn nặng: % ATK ≥ heavy_atk_ratio hoặc hệ số SC ≥ heavy_sc_multiplier.
@export var hitstop_heavy_ms := 70.0
@export var hitstop_crit_bonus_ms := 10.0
## Trần (đặc tả 40-80 ms).
@export var hitstop_max_ms := 80.0
## Người chơi bị đánh.
@export var hitstop_player_hurt_ms := 60.0
@export var heavy_atk_ratio := 1.2
@export var heavy_sc_multiplier := 1.5

@export_group("Rung camera")
@export var shake_light_px := 4.0
@export var shake_light_sec := 0.08
@export var shake_heavy_px := 10.0
@export var shake_heavy_sec := 0.15
@export var shake_player_hurt_px := 9.0
@export var shake_player_hurt_sec := 0.14

@export_group("Combo")
## Không trúng thêm trong bấy nhiêu giây thì combo về 0.
@export var combo_window_sec := 2.0
## Hiện bộ đếm từ số đòn này.
@export var combo_min_display := 2

@export_group("Tuyệt kỹ")
## Dừng thời gian kẻ địch + cut-in (CHARACTER_SKILLS mục 1: 600 ms). Kỹ năng có thể ghi riêng (SkillDef.time_stop_ms).
@export var cut_in_default_ms := 600.0

@export_group("Phản ứng nguyên tố (mục 8.4)")
@export var reaction_hitstop_ms := 60.0
## Tên phản ứng hiện bao lâu (s).
@export var reaction_name_sec := 0.8
## Hai quả cầu nguyên tố va vào nhau (s).
@export var reaction_orb_sec := 0.3
