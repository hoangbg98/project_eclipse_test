class_name CombatRules
extends Resource
## Luật chiến đấu chung (CHARACTER_SKILLS mục 0, ghi đè mục 8.1, quyết định Q1-Q3, Q6).
## Giá trị ở data/config/combat_rules.tres. Đơn vị: giây, tỉ lệ 0..1 (0.06 = 6%).

@export_group("Sát thương (Q1, Q2, Q3)")
## Sát thương tăng mỗi cấp kỹ năng: × (1 + skill_level_scaling × (cấp − 1)).
@export var skill_level_scaling := 0.06
## Hằng số giảm sát thương theo DEF: K / (K + DEF).
@export var def_constant_k := 500.0
## Chí mạng mặc định.
@export_range(0.0, 1.0) var base_crit_rate := 0.05
@export var base_crit_damage := 0.5
## Tổng % giảm DEF tối đa (nhiều debuff khác tên cộng dồn tới mức này).
@export_range(0.0, 1.0) var def_reduction_cap := 0.40
## Tổng % giảm sát thương nhận tối đa. Đặc tả chỉ ghi "cap đặt trong config":
## 0.80 là giá trị Claude đặt tạm, owner chỉnh sau khi chơi thử.
@export_range(0.0, 1.0) var damage_taken_reduction_cap := 0.80

@export_group("Năng lượng EN")
@export var en_max := 100.0
@export var en_regen_per_sec := 2.0
## +EN mỗi đòn thường / giữ / trên không / đáp đất trúng.
@export var en_per_basic_hit := 3.0
## Mục 8.1: dự bị +1/s (thay vì +2).
@export var reserve_en_regen_per_sec := 1.0

@export_group("Tuyệt kỹ UG")
@export var ug_max := 100.0
@export var ug_per_normal_hit := 2.0
@export var ug_per_skill_hit := 10.0
@export var ug_per_weapon_hit := 15.0
## +UG cho mỗi 1% HP tối đa bị mất.
@export var ug_per_hp_percent_lost := 0.3
## Mục 8.1: dự bị nhận 30% UG mà nhân vật trên sân nhận (thay vì 50%).
@export_range(0.0, 1.0) var reserve_ug_share := 0.30

@export_group("Né")
@export var dodge_charges := 2
@export var dodge_recharge_sec := 4.0
## Né hoàn hảo: né trong cửa sổ này trước khi đòn trúng.
@export var perfect_dodge_window_sec := 0.15
@export_range(0.0, 1.0) var perfect_dodge_enemy_slow := 0.30
@export var perfect_dodge_slow_sec := 0.6
@export var perfect_dodge_refund_charges := 1
@export var perfect_dodge_icd_sec := 1.0

@export_group("Hồi chiêu")
## Trần CDR; áp cho Kĩ năng thường, Kĩ năng vũ khí, hồi lượt né, SI-CD. Không áp cho Tuyệt kỹ.
@export_range(0.0, 1.0) var cdr_cap := 0.40

@export_group("Phản ứng khi trúng đòn (người chơi)")
## Người chơi bị khựng bao lâu khi trúng đòn (kỹ năng có kháng khựng thì không).
@export var player_stagger_sec := 0.3
## Thời gian đẩy lùi diễn ra (s): quãng đẩy chia đều trong khoảng này.
@export var knockback_time_sec := 0.15
## Sức choáng = tỉ lệ SC của đòn × hệ số này (mục 0: "SC bằng % ATK của đòn" → 0.7 → 70).
@export var sc_points_per_ratio := 100.0

@export_group("Đội (mục 8.2)")
## Khoảng chờ chung giữa hai lần chuyển nhân vật.
@export var switch_cooldown_sec := 1.0
## Bấm chuyển khi còn chờ / đang bị khóa: giữ lệnh bấy nhiêu giây rồi thử lại (mục 8.11: 150 ms).
@export var switch_input_buffer_sec := 0.15
## Nhân vật trên sân gục: sau bấy nhiêu giây tự đưa nhân vật dự bị còn sống đầu tiên vào sân
## (vào sân mặc định, không kỹ năng). Đặc tả chưa ghi; Claude chọn, owner chỉnh.
@export var down_auto_switch_sec := 1.0

@export_group("Cờ chế độ")
## Q6: hồi sinh mặc định tắt.
@export var revive_enabled := false


## Kiểm tra giá trị hợp lệ; trả về danh sách lỗi (rỗng = ổn).
func validate() -> PackedStringArray:
	var e := PackedStringArray()
	if def_constant_k <= 0.0:
		e.append("def_constant_k phải > 0")
	for pair in [["en_max", en_max], ["ug_max", ug_max], ["dodge_recharge_sec", dodge_recharge_sec]]:
		if float(pair[1]) <= 0.0:
			e.append("%s phải > 0" % pair[0])
	if dodge_charges < 1:
		e.append("dodge_charges phải >= 1")
	for pair in [["def_reduction_cap", def_reduction_cap], ["damage_taken_reduction_cap", damage_taken_reduction_cap],
			["cdr_cap", cdr_cap], ["reserve_ug_share", reserve_ug_share], ["base_crit_rate", base_crit_rate]]:
		if float(pair[1]) < 0.0 or float(pair[1]) > 1.0:
			e.append("%s phải trong 0..1" % pair[0])
	return e
