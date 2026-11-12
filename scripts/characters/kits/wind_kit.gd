class_name WindKit
extends Node
## Logic riêng của Lyra (char_wind_01), CHARACTER_SKILLS mục 2 (phạm vi Q5):
## né hoàn hảo — Gió Trợ Bước: +25% tốc độ di chuyển 3 s, hồi 5 EN.
## Nội tại Gió Thuận và các kỹ năng khác ngoài slice.

var player: PlayerController
var config: WindKitConfig
var combatant: Combatant


func attach(p: PlayerController, cfg: Resource) -> void:
	player = p
	config = cfg as WindKitConfig
	combatant = p.combatant
	p.perfect_dodged.connect(_on_perfect_dodge)


func tick(_delta: float) -> void:
	pass


func _on_perfect_dodge(_hit: HitInfo) -> void:
	if config == null:
		return
	combatant.statuses.apply("wind_step", config.perfect_dodge_speed_sec, config.perfect_dodge_speed, combatant)
	combatant.resources.add_en(config.perfect_dodge_en)
