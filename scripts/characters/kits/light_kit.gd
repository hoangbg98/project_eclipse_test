class_name LightKit
extends Node
## Logic riêng của Hikarine (char_light_01), CHARACTER_SKILLS mục 4:
## - Nội tại Ân Huệ Ánh Sáng: hồi thừa vượt HP tối đa → 50% thành Khiên (tối đa 8% HP tối đa, 6 s), ICD 2 s mỗi mục tiêu.
## - Hồi cho đồng đội dưới 50% HP: −1.0 s CD Kĩ năng thường (ICD 3 s); báo PartyManager giảm SI-CD (mục 8.8);
##   nạp UG +30% trong 5 s (cách hiểu "nạp UG +30% từ việc hồi máu cho đồng đội dưới 50% HP": Claude chọn).
## - Né hoàn hảo — Hào Quang: hồi 3% HP tối đa cho cả đội, +10 EN.
## - Thái Dương Phán Xét: mỗi mục tiêu trúng −0.5 s CD (tối đa −2.5 s mỗi chu kỳ).

var player: PlayerController
var config: LightKitConfig
var combatant: Combatant

var _shield_icd: Dictionary = {}   # instance id mục tiêu → giây
var _skill_cd_icd := 0.0
var _ug_boost_left := 0.0


func attach(p: PlayerController, cfg: Resource) -> void:
	player = p
	config = cfg as LightKitConfig
	combatant = p.combatant
	combatant.heal_done.connect(_on_heal_done)
	combatant.hit_dealt.connect(_on_hit_dealt)
	p.perfect_dodged.connect(_on_perfect_dodge)


func tick(delta: float) -> void:
	_skill_cd_icd = maxf(_skill_cd_icd - delta, 0.0)
	for k in _shield_icd.keys():
		_shield_icd[k] = float(_shield_icd[k]) - delta
		if float(_shield_icd[k]) <= 0.0:
			_shield_icd.erase(k)
	if _ug_boost_left > 0.0:
		_ug_boost_left -= delta
		combatant.resources.ug_gain_multiplier = config.ug_boost_multiplier if _ug_boost_left > 0.0 else 1.0


func _team() -> Array[Combatant]:
	if player.team_combatants.is_empty():
		return [combatant] as Array[Combatant]
	return player.team_combatants


func _on_heal_done(target: Combatant, _healed: float, overflow: float, ratio_before: float) -> void:
	if config == null:
		return
	# Ân Huệ Ánh Sáng: phần thừa thành khiên.
	if overflow > 0.0 and not _shield_icd.has(target.get_instance_id()):
		var amount := minf(overflow * config.overflow_to_shield, target.resources.max_hp * config.shield_max_ratio)
		if amount > 0.0:
			_shield_icd[target.get_instance_id()] = config.shield_icd_sec
			target.statuses.apply("shield", config.shield_sec, amount / target.resources.max_hp, combatant)
	if ratio_before < config.low_hp_ratio:
		if _skill_cd_icd <= 0.0:
			_skill_cd_icd = config.skill_cd_icd_sec
			combatant.cooldowns.reduce(&"skill", config.skill_cd_per_low_heal_sec)
		_ug_boost_left = config.ug_boost_sec
		combatant.resources.ug_gain_multiplier = config.ug_boost_multiplier
		player.kit_event.emit(SwitchInDef.REDUCE_HEAL_LOW)


func _on_hit_dealt(_target: Combatant, _result: DamageCalculator.Result, hit: HitInfo) -> void:
	if config and hit.skill_id == player.character_id + ".weapon":
		combatant.cooldowns.reduce(&"weapon", config.weapon_cd_per_target_sec, config.weapon_cd_max_per_cycle_sec)


func _on_perfect_dodge(_hit: HitInfo) -> void:
	if config == null:
		return
	for c in _team():
		if not c.resources.is_dead():
			combatant.heal_target(c, c.resources.max_hp * config.perfect_dodge_heal_max_hp)
	combatant.resources.add_en(config.perfect_dodge_en)
