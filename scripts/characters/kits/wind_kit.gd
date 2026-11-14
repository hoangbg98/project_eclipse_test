class_name WindKit
extends Node
## Logic riêng của Kazeyumi (char_wind_01), CHARACTER_SKILLS mục 2:
## - Né hoàn hảo — Gió Trợ Bước: +25% tốc độ di chuyển 3 s, hồi 5 EN.
## - Nội tại Gió Thuận: bắn trúng 3 kẻ địch khác nhau trong 4 s → cả đội +10% tốc độ di chuyển, +8% tốc độ nạp EN
##   trong 5 s (ICD 10 s). Chỉ một người trên sân (mục 8) nên "trong 800 px" là cả đội.
## - Rút CD Phong Vực: mỗi mũi tên (đòn cơ bản) trúng kẻ địch đang bị Chậm: −0.3 s (tối đa −3.0 s mỗi chu kỳ).
## - Phong Vực: người đang trên sân (Kazeyumi hoặc đồng đội vừa vào sân) đứng trong vùng: +15% tốc độ tấn công,
##   +10% tốc độ di chuyển; Kazeyumi đứng trong vùng: UG từ đòn thường +20%.

const BASIC_KINDS := [ResourceComponent.HitKind.NORMAL, ResourceComponent.HitKind.HOLD,
		ResourceComponent.HitKind.AIR, ResourceComponent.HitKind.LANDING]

## Buff trang bị: đồng đội trong Phong Vực +% sát thương (data/statuses/eqb_wind_zone_dmg.tres).
const ZONE_ALLY_DAMAGE := "eqb_wind_zone_dmg"

var player: PlayerController
var config: WindKitConfig
var combatant: Combatant

## Gió Thuận: instance id mục tiêu → giây còn tính (cửa sổ 4 s).
var _recent_targets: Dictionary = {}
var _fair_wind_icd := 0.0
var fair_wind_triggers := 0           # đếm để test / HUD
## Phong Vực đang tồn tại: tâm (chân, mặt đất) và thời gian còn lại.
var zone_center := Vector2.ZERO
var zone_left := 0.0
var _ug_counted: Dictionary = {}      # hit_id → true (cộng UG thêm một lần mỗi nhát)


func attach(p: PlayerController, cfg: Resource) -> void:
	player = p
	config = cfg as WindKitConfig
	combatant = p.combatant
	p.perfect_dodged.connect(_on_perfect_dodge)
	p.runner.skill_started.connect(_on_skill_started)
	combatant.hit_dealt.connect(_on_hit_dealt)


func tick(delta: float) -> void:
	if config == null:
		return
	_fair_wind_icd = maxf(_fair_wind_icd - delta, 0.0)
	for k in _recent_targets.keys():
		_recent_targets[k] = float(_recent_targets[k]) - delta
		if float(_recent_targets[k]) <= 0.0:
			_recent_targets.erase(k)
	if zone_left > 0.0:
		zone_left -= delta
		for c in _team():
			if c.resources.on_field and _in_zone(c):
				# Thời gian ngắn, làm mới mỗi tick: rời vùng thì hết sau ~0.3 s.
				c.statuses.apply("attack_speed_up", config.zone_buff_refresh_sec, config.zone_attack_speed, combatant)
				c.statuses.apply("wind_domain_haste", config.zone_buff_refresh_sec, config.zone_move_speed, combatant)
				if config.zone_ally_damage > 0.0:
					c.statuses.apply(ZONE_ALLY_DAMAGE, config.zone_buff_refresh_sec, config.zone_ally_damage, combatant)


## Combatant `c` đang đứng trong Phong Vực.
func _in_zone(c: Combatant) -> bool:
	var node := c.get_parent() as Node2D
	if zone_left <= 0.0 or node == null or not node.is_inside_tree():
		return false
	return node.global_position.distance_to(zone_center) <= config.zone_radius_px


func in_zone() -> bool:
	return _in_zone(combatant)


func _team() -> Array[Combatant]:
	if player.team_combatants.is_empty():
		return [combatant] as Array[Combatant]
	return player.team_combatants


func _on_skill_started(_key: String, skill: SkillDef) -> void:
	if skill.key != "skill" or config == null:
		return
	zone_center = player.global_position + Vector2(config.zone_forward_px * player.runner.facing, 0.0)
	zone_left = config.zone_duration_sec


func _on_perfect_dodge(_hit: HitInfo) -> void:
	if config == null:
		return
	combatant.statuses.apply("wind_step", config.perfect_dodge_speed_sec, config.perfect_dodge_speed, combatant)
	combatant.resources.add_en(config.perfect_dodge_en)


func _on_hit_dealt(target: Combatant, _result: DamageCalculator.Result, hit: HitInfo) -> void:
	if config == null:
		return
	if hit.hit_kind in BASIC_KINDS and "slow" in hit.target_statuses_before:
		combatant.cooldowns.reduce(&"skill", config.skill_cd_per_slowed_hit_sec, config.skill_cd_max_per_cycle_sec)
	if hit.hit_kind == ResourceComponent.HitKind.NORMAL and in_zone() and not _ug_counted.has(hit.hit_id):
		_ug_counted[hit.hit_id] = true
		if _ug_counted.size() > 256:
			_ug_counted.clear()
		combatant.resources.add_ug(combatant.rules.ug_per_normal_hit * config.zone_normal_ug_bonus)
	if target:
		_recent_targets[target.get_instance_id()] = config.fair_wind_window_sec
		if _recent_targets.size() >= config.fair_wind_targets and _fair_wind_icd <= 0.0:
			_fair_wind()


func _fair_wind() -> void:
	_fair_wind_icd = config.fair_wind_icd_sec
	_recent_targets.clear()
	fair_wind_triggers += 1
	for c in _team():
		c.statuses.apply("fair_wind_haste", config.fair_wind_sec, config.fair_wind_move_speed, combatant)
		c.statuses.apply("fair_wind", config.fair_wind_sec, config.fair_wind_en_regen, combatant)
