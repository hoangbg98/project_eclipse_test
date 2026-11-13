class_name LightningKit
extends Node
## Logic riêng của Kael (char_lightning_01), CHARACTER_SKILLS mục 3 (phạm vi Q5 + nội tại cần cho Dấu Sét):
## - Bùng nổ Sét: mục tiêu đủ 3 Dấu Sét do Kael gây → nổ 150% ATK bán kính 140 (SC ×2), xóa dấu,
##   ICD 4 s mỗi mục tiêu; Kael +10% tốc độ tấn công 3 s; −1.0 s CD Kĩ năng vũ khí (tối đa −3.0 s mỗi chu kỳ).
## - Né hoàn hảo — Sét Phản: nổ điện 80% ATK bán kính 150 tại điểm xuất phát, áp 2 Dấu Sét.

const MARK := "lightning_mark"
const BURST_ID_SUFFIX := ".burst"
const OVERLOAD := "overload"

var player: PlayerController
var config: LightningKitConfig
var combatant: Combatant

var _icd: Dictionary = {}       # instance id mục tiêu -> giây còn lại
var _dodge_origin := Vector2.ZERO
var bursts := 0                 # đếm để test / HUD


func attach(p: PlayerController, cfg: Resource) -> void:
	player = p
	config = cfg as LightningKitConfig
	combatant = p.combatant
	p.runner.skill_started.connect(_on_skill_started)
	p.perfect_dodged.connect(_on_perfect_dodge)
	combatant.hit_dealt.connect(_on_hit_dealt)
	var bus := p.get_tree().root.get_node_or_null("EventBus") if p.is_inside_tree() else null
	if bus:
		bus.status_max_stacks.connect(_on_status_max_stacks)


func tick(delta: float) -> void:
	for k in _icd.keys():
		_icd[k] = float(_icd[k]) - delta
		if float(_icd[k]) <= 0.0:
			_icd.erase(k)


func _on_skill_started(_key: String, skill: SkillDef) -> void:
	if skill.key == "dodge":
		_dodge_origin = player.global_position


func _on_status_max_stacks(target: Object, status_id: String, source: Object) -> void:
	if status_id != MARK or source != combatant or config == null or config.burst == null:
		return
	var t := target as Combatant
	if t == null or not is_instance_valid(t):
		return
	var key := t.get_instance_id()
	if _icd.has(key):
		return
	_icd[key] = config.burst_icd_per_target_sec
	var node := t.get_parent() as Node2D
	if node == null or not node.is_inside_tree():
		return
	bursts += 1
	# Xóa dấu sau khi đòn hiện tại xử lý xong (đang ở giữa lúc áp trạng thái).
	t.statuses.remove.call_deferred(MARK)
	DetachedHit.spawn(node.get_parent(), config.burst, player, combatant.team, player.facing,
			node.global_position, {}, ResourceComponent.HitKind.NONE, player.character_id + BURST_ID_SUFFIX)
	combatant.statuses.apply("attack_speed_up", config.burst_attack_speed_sec, config.burst_attack_speed, combatant)
	combatant.cooldowns.reduce(&"weapon", config.weapon_cd_per_burst_sec, config.weapon_cd_max_per_cycle_sec)
	combatant.cooldowns.reduce(&"skill", config.skill_cd_per_burst_sec, config.skill_cd_max_per_cycle_sec)
	if config.ug_per_burst > 0.0:
		combatant.resources.add_ug(config.ug_per_burst)


## Quá Tải (sau Tuyệt kỹ, 8 s): mọi đòn thường áp Dấu Sét (đòn đã có Dấu Sét thì không áp thêm).
func _on_hit_dealt(target: Combatant, _result: DamageCalculator.Result, hit: HitInfo) -> void:
	if target == null or hit.hit_kind != ResourceComponent.HitKind.NORMAL:
		return
	if not combatant.statuses.has(OVERLOAD):
		return
	for s in hit.statuses:
		if s.status_id == MARK:
			return
	target.statuses.apply(MARK, -1.0, -1.0, combatant)


func _on_perfect_dodge(_hit: HitInfo) -> void:
	if config == null or config.counter == null or not player.is_inside_tree():
		return
	DetachedHit.spawn(player.get_parent(), config.counter, player, combatant.team, player.facing,
			_dodge_origin, {}, ResourceComponent.HitKind.NONE, player.character_id + ".dodge_counter")
