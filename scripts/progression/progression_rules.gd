class_name ProgressionRules
extends Resource
## Luật tăng trưởng nhân vật (README "RPG progression"). Giá trị ở data/config/progression.tres.
## Số do Claude đặt làm khởi điểm (README chưa có); owner chỉnh trong data.

@export_group("Cấp")
@export var max_level := 50
## EXP cần để từ cấp L lên L + 1 = round(exp_base × L ^ exp_exponent).
@export var exp_base := 100.0
@export var exp_exponent := 1.5

@export_group("Cấp đội trưởng")
## Cấp nhân vật không vượt quá cấp đội trưởng (owner, 2026-11-12: "không được vượt quá cấp người chơi").
@export var captain_max_level := 50
## EXP đội trưởng để từ cấp L lên L + 1 = round(captain_exp_base × L ^ exp_exponent).
@export var captain_exp_base := 50.0

@export_group("Tiến cấp (mảnh nhân vật)")
## Số mảnh cho mỗi bước tiến cấp: phần tử i = từ bậc i lên i + 1 (S → S1 → S2 → S3).
@export var promotion_fragments: PackedInt32Array = PackedInt32Array([10, 20, 25])
## Mỗi bước tiến cấp tăng bấy nhiêu % HP / ATK / DEF gốc.
@export var promotion_stat_bonus := 0.05

@export_group("Chỉ số theo cấp")
## Chỉ số ở cấp L = gốc × (1 + growth × (L − 1)).
@export var hp_growth_per_level := 0.06
@export var atk_growth_per_level := 0.06
@export var def_growth_per_level := 0.05

@export_group("Cấp kỹ năng")
## Cấp tối đa của một nhóm kỹ năng (mỗi cấp +6% sát thương: CombatRules.skill_level_scaling).
@export var skill_max_level := 10
## Vàng để nâng từ cấp L lên L + 1 = skill_upgrade_gold_base × L.
@export var skill_upgrade_gold_base := 500

@export_group("Nâng bậc vũ khí")
## Nâng bậc (owner 2026-11-15, cơ chế do Claude chọn): vũ khí đạt giới hạn cường hóa thì nâng bậc để mở thêm cấp.
## Giới hạn cấp = EquipmentDef.max_level + bậc × weapon_ascend_level_step. Chỉ vũ khí; vết thánh không có bậc.
## Bậc tối đa theo độ hiếm: phần tử i = vũ khí (i + 1)★.
@export var weapon_ascend_max_tier: PackedInt32Array = PackedInt32Array([0, 0, 1, 2, 3])
@export var weapon_ascend_level_step := 5
## Nguyên liệu nâng bậc (ItemDef) và số lượng / vàng cho từng bước: phần tử i = từ bậc i lên i + 1.
@export var weapon_ascend_material := "mat_weapon_ascend"
@export var weapon_ascend_material_count: PackedInt32Array = PackedInt32Array([2, 4, 6])
@export var weapon_ascend_gold: PackedInt32Array = PackedInt32Array([5000, 10000, 20000])

@export_group("Chi phí")
## Vàng tốn cho mỗi điểm EXP nạp bằng nguyên liệu.
@export var gold_per_exp := 0.2


func exp_to_next(level: int) -> int:
	if level >= max_level:
		return 0
	return int(round(exp_base * pow(float(maxi(level, 1)), exp_exponent)))


## Tổng EXP từ cấp 1 tới đúng đầu cấp `level`.
func total_exp_for(level: int) -> int:
	var t := 0
	for l in range(1, mini(level, max_level)):
		t += exp_to_next(l)
	return t


func captain_exp_to_next(level: int) -> int:
	if level >= captain_max_level:
		return 0
	return int(round(captain_exp_base * pow(float(maxi(level, 1)), exp_exponent)))


func max_promotion() -> int:
	return promotion_fragments.size()


func skill_upgrade_gold(level: int) -> int:
	return skill_upgrade_gold_base * maxi(level, 1)


## Bậc tối đa của vũ khí `rarity`★ (0 = không nâng bậc được).
func weapon_max_tier(rarity: int) -> int:
	var i := rarity - 1
	if i < 0 or i >= weapon_ascend_max_tier.size():
		return 0
	return mini(weapon_ascend_max_tier[i], mini(weapon_ascend_material_count.size(), weapon_ascend_gold.size()))


func stat_multiplier(growth: float, level: int) -> float:
	return 1.0 + growth * float(clampi(level, 1, max_level) - 1)


func validate() -> PackedStringArray:
	var e := PackedStringArray()
	if max_level < 1:
		e.append("max_level phải >= 1")
	if exp_base <= 0.0 or exp_exponent < 0.0:
		e.append("exp_base phải > 0, exp_exponent >= 0")
	for v in [hp_growth_per_level, atk_growth_per_level, def_growth_per_level, gold_per_exp]:
		if v < 0.0:
			e.append("growth / chi phí không được âm")
	if weapon_ascend_level_step < 0:
		e.append("weapon_ascend_level_step không được âm")
	for t in weapon_ascend_max_tier:
		if t > mini(weapon_ascend_material_count.size(), weapon_ascend_gold.size()):
			e.append("weapon_ascend_max_tier vượt số bước có giá (material_count / gold)")
			break
	return e
