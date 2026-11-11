class_name DamageCalculator
extends RefCounted
## Tính sát thương và hồi máu (ARCHITECTURE mục 5, quyết định Q1-Q3). Hàm thuần: không node, không state.
##
##   raw     = ATK × %đòn × (1 + skill_level_scaling × (cấp − 1))
##   bonus   = 1 + Σ%tăng sát thương của người đánh + Σ%nhận thêm của mục tiêu (vd Phán quyết)
##   dealt   = 1 − min(Σ%giảm sát thương gây ra của người đánh, 1)        (vd Mù cát; bổ sung, xem nhật ký M3-3)
##   def_eff = DEF × (1 − min(Σ%giảm DEF, def_reduction_cap))           (Q3: khác tên cộng dồn, trần 40%)
##   mitig   = K / (K + def_eff)                                         (K = 500)
##   crit    = roll < tỉ lệ chí mạng ? 1 + sát thương chí mạng : 1        (Q2: 5% / +50%)
##   taken   = 1 − min(Σ%giảm sát thương nhận, damage_taken_reduction_cap)
##   damage  = round(raw × bonus × dealt × mitig × crit × taken)


## Chỉ số của người đánh tại thời điểm đánh.
class Attacker:
	extends RefCounted
	var atk := 0.0
	var crit_rate := 0.05
	var crit_damage := 0.5
	## Các % tăng sát thương, khóa theo nguồn (buff, nội tại...): cộng dồn.
	var damage_bonus: Dictionary = {}
	## Các % giảm sát thương gây ra, khóa theo tên trạng thái (vd "sand_blind": 0.2).
	var damage_dealt_down: Dictionary = {}

	## Lấy tỉ lệ chí mạng mặc định từ CombatRules.
	static func from_rules(rules: CombatRules, atk_value: float) -> Attacker:
		var a := Attacker.new()
		a.atk = atk_value
		a.crit_rate = rules.base_crit_rate
		a.crit_damage = rules.base_crit_damage
		return a


## Chỉ số của mục tiêu tại thời điểm trúng.
class Target:
	extends RefCounted
	var def := 0.0
	## % giảm DEF khóa theo TÊN trạng thái: cùng tên chỉ một mục (Q3: làm mới, không cộng), khác tên cộng dồn.
	var def_reduction: Dictionary = {}
	## % nhận thêm sát thương (vd "judgment": 0.08).
	var damage_taken_up: Dictionary = {}
	## % giảm sát thương nhận (vd "earth_guard": 0.35).
	var damage_taken_down: Dictionary = {}


## Kết quả kèm từng hệ số để gỡ lỗi / hiện số.
class Result:
	extends RefCounted
	var amount := 0
	var is_crit := false
	var raw := 0.0
	var bonus := 1.0
	var dealt := 1.0
	var mitigation := 1.0
	var crit_multiplier := 1.0
	var taken := 1.0


static func compute(rules: CombatRules, attacker: Attacker, target: Target, atk_ratio: float,
		skill_level: int, rng: RandomSource) -> Result:
	var r := Result.new()
	r.raw = attacker.atk * atk_ratio * level_multiplier(rules, skill_level)
	r.bonus = 1.0 + _sum(attacker.damage_bonus) + _sum(target.damage_taken_up)
	r.dealt = 1.0 - clampf(_sum(attacker.damage_dealt_down), 0.0, 1.0)
	r.mitigation = mitigation(rules, target)
	r.is_crit = rng.chance(attacker.crit_rate)
	r.crit_multiplier = 1.0 + attacker.crit_damage if r.is_crit else 1.0
	r.taken = 1.0 - minf(_sum(target.damage_taken_down), rules.damage_taken_reduction_cap)
	var value := r.raw * maxf(r.bonus, 0.0) * r.dealt * r.mitigation * r.crit_multiplier * r.taken
	r.amount = int(round(maxf(value, 0.0)))
	return r


## Hệ số theo cấp kỹ năng (cấp 1 = 1.0).
static func level_multiplier(rules: CombatRules, skill_level: int) -> float:
	return 1.0 + rules.skill_level_scaling * float(maxi(skill_level, 1) - 1)


## Tổng % giảm DEF sau trần Q3.
static func total_def_reduction(rules: CombatRules, target: Target) -> float:
	return minf(_sum(target.def_reduction), rules.def_reduction_cap)


## K / (K + DEF hiệu dụng).
static func mitigation(rules: CombatRules, target: Target) -> float:
	var def_eff := maxf(target.def, 0.0) * (1.0 - total_def_reduction(rules, target))
	return rules.def_constant_k / (rules.def_constant_k + def_eff)


## Hồi máu (mục 0): (ATK × %ATK + HP tối đa mục tiêu × %HP) × hệ số cấp. Không chí mạng, không bị DEF.
static func heal(rules: CombatRules, healer_atk: float, atk_ratio: float, target_max_hp: float,
		max_hp_ratio: float, skill_level: int) -> int:
	var value := (healer_atk * atk_ratio + target_max_hp * max_hp_ratio) * level_multiplier(rules, skill_level)
	return int(round(maxf(value, 0.0)))


static func _sum(d: Dictionary) -> float:
	var s := 0.0
	for v in d.values():
		s += float(v)
	return s
