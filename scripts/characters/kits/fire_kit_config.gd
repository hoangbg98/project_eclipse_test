class_name FireKitConfig
extends Resource
## Số liệu riêng của Aether (CHARACTER_SKILLS mục 1). Dữ liệu: data/characters/char_fire_01_kit.tres.

@export_group("Nội tại — Lửa Bùng Cháy")
## Mỗi lần gây sát thương (đòn trực tiếp) lên mục tiêu đang Cháy: +1 Nhiệt; ICD giữa hai lần cộng.
@export var heat_icd_sec := 0.3
## +ATK mỗi tầng Nhiệt (tối đa theo StatusDef heat: 5 tầng).
@export var heat_atk_per_stack := 0.04
## Ở đủ tầng: Kĩ năng thường / vũ khí kế tiếp +% sát thương và tiêu hết tầng.
@export var heat_full_bonus := 0.25
## Số tầng Nhiệt bị tiêu khi dùng bonus đủ tầng (0 = tiêu hết). Vũ khí 5★ của Enkiba: 3 (EQUIPMENT_5STAR Q2).
@export var heat_full_consume := 0
## Đạt đủ tầng: rút CD Kĩ năng thường (ICD riêng).
@export var heat_full_skill_cd_reduce_sec := 1.0
@export var heat_full_skill_cd_icd_sec := 6.0

@export_group("Rút hồi chiêu")
## Kĩ năng thường: mỗi đòn thường/giữ/trên không/đáp đất trúng mục tiêu đang Cháy.
@export var skill_cd_per_hit_sec := 0.2
@export var skill_cd_max_per_cycle_sec := 2.0
## Kĩ năng vũ khí: hạ gục kẻ địch đang Cháy.
@export var weapon_cd_per_kill_sec := 2.0
@export var weapon_cd_max_per_cycle_sec := 4.0
## Tuyệt kỹ: nạp UG nhanh hơn khi có đủ số tầng Nhiệt.
@export var ug_bonus_heat_threshold := 3
@export var ug_bonus_multiplier := 1.2

@export_group("Né hoàn hảo — Hơi Nóng")
## Đòn thường kế tiếp trong thời hạn trạng thái hot_breath: +% sát thương (độ mạnh lấy từ StatusDef) và áp Cháy.
@export var hot_breath_burn_sec := 3.0

@export_group("Hỏa Hoàng (sau tuyệt kỹ)")
## Đòn thường thêm sóng lửa trong lúc có trạng thái phoenix. Tài liệu không ghi %; dùng sóng của đòn 4 (40%).
@export var phoenix_wave: HitDef
