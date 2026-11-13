class_name WindKitConfig
extends Resource
## Số liệu kit Kazeyumi (CHARACTER_SKILLS mục 2).

@export_group("Né hoàn hảo — Gió Trợ Bước")
@export var perfect_dodge_speed := 0.25
@export var perfect_dodge_speed_sec := 3.0
@export var perfect_dodge_en := 5.0

@export_group("Rút CD Kĩ năng thường (Phong Vực)")
## Mỗi mũi tên trúng kẻ địch đang bị Chậm.
@export var skill_cd_per_slowed_hit_sec := 0.3
@export var skill_cd_max_per_cycle_sec := 3.0
