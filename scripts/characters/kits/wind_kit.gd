class_name WindKit
extends Node
## Logic riêng của Kazeyumi (char_wind_01), CHARACTER_SKILLS mục 2:
## - Né hoàn hảo — Gió Trợ Bước: +25% tốc độ di chuyển 3 s, hồi 5 EN.
## - Rút CD Kĩ năng thường: mỗi mũi tên (đòn cơ bản) trúng kẻ địch đang bị Chậm: −0.3 s (tối đa −3.0 s mỗi chu kỳ).
## Nội tại Gió Thuận (buff cả đội) chưa làm.

const BASIC_KINDS := [ResourceComponent.HitKind.NORMAL, ResourceComponent.HitKind.HOLD,
		ResourceComponent.HitKind.AIR, ResourceComponent.HitKind.LANDING]

var player: PlayerController
var config: WindKitConfig
var combatant: Combatant


func attach(p: PlayerController, cfg: Resource) -> void:
	player = p
	config = cfg as WindKitConfig
	combatant = p.combatant
	p.perfect_dodged.connect(_on_perfect_dodge)
	combatant.hit_dealt.connect(_on_hit_dealt)


func tick(_delta: float) -> void:
	pass


func _on_perfect_dodge(_hit: HitInfo) -> void:
	if config == null:
		return
	combatant.statuses.apply("wind_step", config.perfect_dodge_speed_sec, config.perfect_dodge_speed, combatant)
	combatant.resources.add_en(config.perfect_dodge_en)


func _on_hit_dealt(_target: Combatant, _result: DamageCalculator.Result, hit: HitInfo) -> void:
	if config == null or hit.hit_kind not in BASIC_KINDS:
		return
	if "slow" in hit.target_statuses_before:
		combatant.cooldowns.reduce(&"skill", config.skill_cd_per_slowed_hit_sec, config.skill_cd_max_per_cycle_sec)
