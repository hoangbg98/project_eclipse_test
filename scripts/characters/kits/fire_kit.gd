class_name FireKit
extends Node
## Logic riêng của Aether (char_fire_01), CHARACTER_SKILLS mục 1:
## - Nội tại Lửa Bùng Cháy: tầng Nhiệt (+4% ATK/tầng), đủ 5 tầng → Kĩ năng thường/vũ khí +25% và tiêu tầng,
##   đạt 5 tầng → −1.0 s CD Kĩ năng thường (ICD 6 s); ≥ 3 tầng → nạp UG +20%.
## - Rút CD Kĩ năng thường khi đòn cơ bản trúng mục tiêu đang Cháy; rút CD Kĩ năng vũ khí khi hạ gục mục tiêu đang Cháy.
## - Né hoàn hảo → Hơi Nóng: đòn thường kế tiếp +30% và áp Cháy 3 s.
## - Hỏa Hoàng (sau tuyệt kỹ): đòn thường thêm sóng lửa.

const BASIC_KINDS := [ResourceComponent.HitKind.NORMAL, ResourceComponent.HitKind.HOLD,
		ResourceComponent.HitKind.AIR, ResourceComponent.HitKind.LANDING]

var player: PlayerController
var config: FireKitConfig
var combatant: Combatant

var _heat_icd := 0.0
var _full_cd_icd := 0.0
## Đòn thường đang chạy có Hơi Nóng (áp Cháy khi trúng).
var _hot_breath_skill := ""
var _counted_hits: Dictionary = {}  # hit_id → true (rút CD một lần mỗi nhát)


func attach(p: PlayerController, cfg: Resource) -> void:
	player = p
	config = cfg as FireKitConfig
	combatant = p.combatant
	combatant.hit_dealt.connect(_on_hit_dealt)
	combatant.statuses.max_stacks_reached.connect(_on_max_stacks)
	p.runner.bonus_provider = _bonus_for
	p.runner.skill_started.connect(_on_skill_started)
	p.runner.skill_finished.connect(_on_skill_finished)
	p.perfect_dodged.connect(_on_perfect_dodge)


func tick(delta: float) -> void:
	_heat_icd = maxf(_heat_icd - delta, 0.0)
	_full_cd_icd = maxf(_full_cd_icd - delta, 0.0)
	var stacks := heat()
	combatant.atk_bonus["heat"] = config.heat_atk_per_stack * stacks
	combatant.resources.ug_gain_multiplier = \
			config.ug_bonus_multiplier if stacks >= config.ug_bonus_heat_threshold else 1.0


func heat() -> int:
	return combatant.statuses.stacks("heat")


func heat_max() -> int:
	var def := combatant.statuses.library.get_status("heat")
	return def.max_stacks if def else 5


## % tăng sát thương riêng cho kỹ năng sắp chạy (SkillRunner gọi lúc bắt đầu).
func _bonus_for(skill: SkillDef) -> Dictionary:
	var bonus := {}
	if skill.key in ["skill", "weapon"] and heat() >= heat_max():
		bonus["heat_full"] = config.heat_full_bonus
		combatant.statuses.remove("heat")  # tiêu hết tầng
		combatant.atk_bonus["heat"] = 0.0
	if skill.key == "normal" and combatant.statuses.has("hot_breath"):
		bonus["hot_breath"] = combatant.statuses.magnitude("hot_breath")
		combatant.statuses.remove("hot_breath")
		_hot_breath_skill = skill.id
	elif skill.key == "normal":
		_hot_breath_skill = ""
	return bonus


func _on_skill_started(_key: String, skill: SkillDef) -> void:
	if skill.key == "normal" and combatant.statuses.has("phoenix") and config.phoenix_wave:
		DetachedHit.spawn(player.get_parent(), config.phoenix_wave, player, combatant.team, player.runner.facing,
				player.global_position, {}, ResourceComponent.HitKind.NORMAL, skill.id + ".phoenix")


## Tuyệt kỹ kết thúc → Hỏa Hoàng 8 s (dù có trúng hay không).
func _on_skill_finished(_key: String, skill: SkillDef) -> void:
	if skill.key == "ultimate":
		combatant.statuses.apply("phoenix", -1.0, -1.0, combatant)


func _on_hit_dealt(target: Combatant, _result: DamageCalculator.Result, hit: HitInfo) -> void:
	var was_burning := hit.target_statuses_before.has("burn")
	# Hơi Nóng: đòn thường mang buff áp Cháy 3 s.
	if _hot_breath_skill != "" and hit.skill_id == _hot_breath_skill:
		target.statuses.apply("burn", config.hot_breath_burn_sec, -1.0, combatant)
	if not was_burning:
		return
	# Nội tại: +1 Nhiệt (ICD 0.3 s), chỉ đòn đánh trực tiếp (nhịp Cháy không đi qua đây).
	if _heat_icd <= 0.0:
		_heat_icd = config.heat_icd_sec
		combatant.statuses.apply("heat", -1.0, -1.0, combatant)
	if hit.hit_kind in BASIC_KINDS and not _counted_hits.has(hit.hit_id):
		_counted_hits[hit.hit_id] = true
		if _counted_hits.size() > 256:
			_counted_hits.clear()
		combatant.cooldowns.reduce(&"skill", config.skill_cd_per_hit_sec, config.skill_cd_max_per_cycle_sec)
	if hit.killed_target:
		combatant.cooldowns.reduce(&"weapon", config.weapon_cd_per_kill_sec, config.weapon_cd_max_per_cycle_sec)


func _on_max_stacks(status_id: String, _source: Object) -> void:
	if status_id == "heat" and _full_cd_icd <= 0.0:
		_full_cd_icd = config.heat_full_skill_cd_icd_sec
		combatant.cooldowns.reduce(&"skill", config.heat_full_skill_cd_reduce_sec)


func _on_perfect_dodge(_hit: HitInfo) -> void:
	combatant.statuses.apply("hot_breath", -1.0, -1.0, combatant)
