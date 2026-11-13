class_name DarkKitConfig
extends Resource
## Số liệu kit Yomigari (CHARACTER_SKILLS mục 5).

@export_group("Khế Ước Bóng")
@export var cursed_lifesteal := 0.04
@export var cursed_lifesteal_boss := 0.02
@export var cursed_kill_skill_cd_sec := 1.5
@export var cursed_kill_en := 10.0
@export var cursed_kill_icd_sec := 1.0
## Tuyệt kỹ: +UG mỗi lần hạ gục kẻ địch mang Nguyền.
@export var cursed_kill_ug := 10.0

@export_group("Hút máu theo kỹ năng")
## Khóa kỹ năng (phần sau dấu chấm của skill_id) → % hút máu.
@export var skill_lifesteal := {"weapon": 0.06, "ultimate": 0.10, "switch_in_linked": 0.06}

@export_group("Liêm Phá Hồn Trảm")
@export var weapon_cd_per_root_sec := 0.5
@export var weapon_cd_max_per_cycle_sec := 2.0

@export_group("Tuyệt kỹ")
@export var execute_hp_ratio := 0.2
@export var night_king_lifesteal := 0.08
@export var night_king_normal_bonus := 0.15

@export_group("Né hoàn hảo — Phân Thân Bóng")
## Nổ tại điểm xuất phát sau 0.8 s (delay_ms trong HitDef), 120% bán kính 150, Nguyền 3 s.
@export var shadow_clone: HitDef
