class_name EarthKitConfig
extends Resource
## Số liệu kit Iwagane (CHARACTER_SKILLS mục 6).

@export_group("Cốt Đá Bất Khuất")
@export var bone_icd_sec := 0.5
## Mỗi tầng giảm % sát thương nhận (StatusDef stone_bone giữ 5 tầng, 8 s).
@export var bone_damage_reduction := 0.03
@export var hit_skill_cd_sec := 0.5
@export var hit_skill_cd_icd_sec := 2.0
@export var hit_skill_cd_max_per_cycle_sec := 3.0
@export var full_bones := 5
@export var full_bones_weapon_bonus := 0.4
## Nổ thêm ở cuối sóng đá khi đủ tầng: 130% bán kính 200.
@export var bone_burst: HitDef

@export_group("Thủ Thế Đại Địa")
@export var perfect_block_window_ms := 200.0
## Phản 120% bán kính 180.
@export var block_reflect: HitDef
@export var release_blocked := "hold_slash"
@export var release_unblocked := "hold_slash_weak"

@export_group("Nạp UG, Thạch Thần")
@export var ug_bonus_multiplier := 1.2
@export var ug_bonus_bones := 3
@export var stone_god_atk := 0.2

@export_group("Né hoàn hảo — Phản Chấn")
## Sóng đá 100% bán kính 160.
@export var counter_wave: HitDef
