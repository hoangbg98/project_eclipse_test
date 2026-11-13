class_name LightningKitConfig
extends Resource
## Số liệu kit Kael (CHARACTER_SKILLS mục 3): Bùng nổ Sét và Sét Phản.

@export_group("Bùng nổ Sét (đủ 3 Dấu Sét)")
## Vùng nổ quanh mục tiêu: 150% ATK, bán kính 140, SC ×2.
@export var burst: HitDef
## ICD mỗi mục tiêu (s).
@export var burst_icd_per_target_sec := 4.0
## Sau mỗi Bùng nổ: + tốc độ tấn công trong bấy nhiêu giây.
@export var burst_attack_speed := 0.10
@export var burst_attack_speed_sec := 3.0
## Mỗi Bùng nổ rút CD Kĩ năng vũ khí (tối đa mỗi chu kỳ).
@export var weapon_cd_per_burst_sec := 1.0
@export var weapon_cd_max_per_cycle_sec := 3.0
## Mỗi Bùng nổ rút CD Kĩ năng thường (Chớp Giật Liên Hoàn: −1.0 s, tối đa −3.0 s mỗi chu kỳ).
@export var skill_cd_per_burst_sec := 1.0
@export var skill_cd_max_per_cycle_sec := 3.0
## Mỗi Bùng nổ cộng thêm UG (Tuyệt kỹ Lôi Thần Quyết: +5).
@export var ug_per_burst := 5.0

@export_group("Né hoàn hảo — Sét Phản")
## Nổ điện tại điểm xuất phát: 80% ATK, bán kính 150, 2 Dấu Sét.
@export var counter: HitDef
