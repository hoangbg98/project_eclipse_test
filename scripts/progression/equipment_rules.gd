class_name EquipmentRules
extends Resource
## Trần của hiệu ứng trang bị (EQUIPMENT_5STAR mục 3.4, owner xác nhận 2026-11-14, mục 5.4).
## Dữ liệu: data/config/equipment_rules.tres. Mọi trần áp ở EquipmentResolver (và chỗ gộp lúc chạy gọi tới nó).
## Giảm ST nhận dùng CombatRules.damage_taken_reduction_cap (0.80 = nhận tối thiểu 20%).

## CD Kĩ năng vũ khí thực tế không dưới tỉ lệ này × CD sau khi vũ khí độc quyền giảm (dòng 1).
@export_range(0.0, 1.0) var cd_floor_ratio := 0.5
## Tổng % tốc độ tấn công (trạng thái + trang bị) tối đa (dòng 3).
@export var atk_speed_cap := 0.6
## Tổng % hút máu (kit + trang bị) tối đa (dòng 5).
@export var lifesteal_cap := 0.3
## Tổng % hiệu quả hồi máu tối đa (dòng 6).
@export var heal_bonus_cap := 0.5
## Khiên từ hồi thừa (Hikarine) tối đa tỉ lệ HP tối đa (dòng 7).
@export var overflow_shield_cap := 0.12
## Khiên Đá (khiên của Giáp Địa, Kĩ năng thường Iwagane; owner 2026-11-15) tối đa tỉ lệ HP tối đa (dòng 7).
## Áp qua param_caps của "skill:skill:self_statuses@shield.magnitude".
@export var stone_shield_cap := 0.25
## Tổng % sát thương từ trang bị (nhóm "tất cả ST" + "ST nguyên tố", kể cả theo điều kiện mục tiêu)
## tối đa: 1.0 = ×2.0 (dòng 8). Không tính % ATK và giảm DEF.
@export var equip_damage_cap := 1.0
## Ngưỡng "kẻ địch dưới X% HP" của điều kiện VS_TARGET "low_hp".
@export_range(0.0, 1.0) var low_hp_ratio := 0.3
## Ngưỡng "hồi máu cho đồng đội dưới X% HP" của kích hoạt heal_low.
@export_range(0.0, 1.0) var heal_low_ratio := 0.5
## Đệm ngưỡng HP của hiệu ứng liên tục (bật khi < ngưỡng, tắt khi > ngưỡng + đệm), mục 3.4 dòng 9.
@export_range(0.0, 0.5) var hp_threshold_buffer := 0.05
## Bán kính tìm kẻ địch gần nhất khi lan trạng thái (Dấu Sét, Nguyền).
@export var spread_radius_px := 600.0
## Tham số kit có trần riêng: "kit:<thuộc tính>" → giá trị tối đa sau khi cộng.
@export var param_caps: Dictionary = {"kit:shield_max_ratio": 0.12,
		"skill:skill:self_statuses@shield.magnitude": 0.25}


func validate() -> PackedStringArray:
	var e := PackedStringArray()
	for pair in [["cd_floor_ratio", cd_floor_ratio], ["atk_speed_cap", atk_speed_cap], ["lifesteal_cap", lifesteal_cap],
			["heal_bonus_cap", heal_bonus_cap], ["equip_damage_cap", equip_damage_cap]]:
		if float(pair[1]) < 0.0:
			e.append("%s không được âm" % pair[0])
	return e
