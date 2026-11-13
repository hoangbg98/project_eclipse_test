class_name WindKitConfig
extends Resource
## Số liệu kit Kazeyumi (CHARACTER_SKILLS mục 2).

@export_group("Né hoàn hảo — Gió Trợ Bước")
@export var perfect_dodge_speed := 0.25
@export var perfect_dodge_speed_sec := 3.0
@export var perfect_dodge_en := 5.0

@export_group("Nội tại — Gió Thuận")
## Trúng bấy nhiêu kẻ địch khác nhau trong cửa sổ thì kích hoạt.
@export var fair_wind_targets := 3
@export var fair_wind_window_sec := 4.0
@export var fair_wind_sec := 5.0
@export var fair_wind_move_speed := 0.10
@export var fair_wind_en_regen := 0.08
@export var fair_wind_icd_sec := 10.0

@export_group("Rút CD Kĩ năng thường (Phong Vực)")
## Mỗi mũi tên trúng kẻ địch đang bị Chậm.
@export var skill_cd_per_slowed_hit_sec := 0.3
@export var skill_cd_max_per_cycle_sec := 3.0

@export_group("Phong Vực (vùng)")
## Tâm vùng cách người bắn (px), bán kính, thời gian — khớp vùng gây sát thương trong data/skills/char_wind_01/skill.tres.
@export var zone_forward_px := 400.0
@export var zone_radius_px := 300.0
@export var zone_duration_sec := 6.0
## Buff cho người trên sân đứng trong vùng (làm mới mỗi tick, hết sau bấy nhiêu giây khi rời vùng).
@export var zone_attack_speed := 0.15
@export var zone_move_speed := 0.10
@export var zone_buff_refresh_sec := 0.3
## UG từ đòn thường khi Kazeyumi đứng trong vùng (+20% của mức mỗi đòn).
@export var zone_normal_ug_bonus := 0.2
