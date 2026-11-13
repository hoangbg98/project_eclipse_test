class_name LightKitConfig
extends Resource
## Số liệu kit Hikarine (CHARACTER_SKILLS mục 4).

@export_group("Ân Huệ Ánh Sáng (hồi thừa → khiên)")
@export var overflow_to_shield := 0.5
@export var shield_max_ratio := 0.08
@export var shield_sec := 6.0
@export var shield_icd_sec := 2.0

@export_group("Hồi cho đồng đội dưới 50% HP")
@export var low_hp_ratio := 0.5
@export var skill_cd_per_low_heal_sec := 1.0
@export var skill_cd_icd_sec := 3.0
@export var ug_boost_multiplier := 1.3
@export var ug_boost_sec := 5.0

@export_group("Thái Dương Phán Xét")
@export var weapon_cd_per_target_sec := 0.5
@export var weapon_cd_max_per_cycle_sec := 2.5

@export_group("Né hoàn hảo — Hào Quang")
@export var perfect_dodge_heal_max_hp := 0.03
@export var perfect_dodge_en := 10.0
