class_name DarkKit
extends Node
## Logic riêng của Yomigari (char_dark_01), CHARACTER_SKILLS mục 5:
## - Nội tại Khế Ước Bóng: sát thương lên mục tiêu mang Nguyền hồi 4% (boss 2%) lượng sát thương;
##   hạ gục kẻ địch mang Nguyền: −1.5 s CD Kĩ năng thường, +10 EN (ICD 1 s), +10 UG (Tuyệt kỹ), báo giảm SI-CD (8.9).
## - Hút máu theo kỹ năng: Liêm Phá Hồn Trảm 6%, Tuyệt kỹ 10%, vào sân Liên kết 6%; Dạ Vương +8%.
## - Liêm Phá Hồn Trảm: mỗi mục tiêu bị Trói −0.5 s CD (tối đa −2.0 s mỗi chu kỳ).
## - Tuyệt kỹ: Thu hoạch — kẻ địch thường dưới 20% HP bị xử tử (boss: +25% sát thương, ghi trong dữ liệu đòn);
##   Dạ Vương 8 s: +15% sát thương đòn thường.
## - Né hoàn hảo — Phân Thân Bóng: bóng tại điểm xuất phát nổ sau 0.8 s, 120% bán kính 150, Nguyền 3 s.

const CURSE := "curse"
const NIGHT_KING := "night_king"

var player: PlayerController
var config: DarkKitConfig
var combatant: Combatant

var _kill_icd := 0.0
var _dodge_origin := Vector2.ZERO
var executions := 0                 # đếm để test


func attach(p: PlayerController, cfg: Resource) -> void:
	player = p
	config = cfg as DarkKitConfig
	combatant = p.combatant
	combatant.hit_dealt.connect(_on_hit_dealt)
	p.runner.skill_started.connect(_on_skill_started)
	p.runner.bonus_provider = _bonus_for
	p.perfect_dodged.connect(_on_perfect_dodge)


func tick(delta: float) -> void:
	_kill_icd = maxf(_kill_icd - delta, 0.0)


func _bonus_for(skill: SkillDef) -> Dictionary:
	if config and skill.key == "normal" and combatant.statuses.has(NIGHT_KING):
		return {"night_king": config.night_king_normal_bonus}
	return {}


func _on_skill_started(_key: String, skill: SkillDef) -> void:
	if skill.key == "dodge":
		_dodge_origin = player.global_position


func lifesteal_rate(hit: HitInfo, target: Combatant) -> float:
	var r := 0.0
	if CURSE in hit.target_statuses_before:
		r += config.cursed_lifesteal_boss if target.is_boss else config.cursed_lifesteal
	var key := hit.skill_id.get_slice(".", 1)
	r += float(config.skill_lifesteal.get(key, 0.0))
	if combatant.statuses.has(NIGHT_KING):
		r += config.night_king_lifesteal
	return r


func _on_hit_dealt(target: Combatant, result: DamageCalculator.Result, hit: HitInfo) -> void:
	if config == null or target == null:
		return
	var rate := lifesteal_rate(hit, target)
	if rate > 0.0 and result.amount > 0:
		combatant.heal_target(combatant, float(result.amount) * rate)
	var key := hit.skill_id.get_slice(".", 1)
	# Thu hoạch: đòn tuyệt kỹ, kẻ địch thường còn sống dưới 20% HP.
	if key == "ultimate" and not target.is_boss and not target.resources.is_dead() \
			and target.resources.hp_ratio() < config.execute_hp_ratio:
		executions += 1
		hit.killed_target = true
		target.resources.take_damage(target.resources.hp + target.resources.shield + 1.0)
	if key == "weapon" and target.statuses.has("root"):
		combatant.cooldowns.reduce(&"weapon", config.weapon_cd_per_root_sec, config.weapon_cd_max_per_cycle_sec)
	if (hit.killed_target or target.resources.is_dead()) and CURSE in hit.target_statuses_before:
		_on_cursed_kill()


func _on_cursed_kill() -> void:
	combatant.resources.add_ug(config.cursed_kill_ug)
	player.kit_event.emit(SwitchInDef.REDUCE_CURSED_KILL)
	if _kill_icd > 0.0:
		return
	_kill_icd = config.cursed_kill_icd_sec
	combatant.cooldowns.reduce(&"skill", config.cursed_kill_skill_cd_sec)
	combatant.resources.add_en(config.cursed_kill_en)


func _on_perfect_dodge(_hit: HitInfo) -> void:
	if config == null or config.shadow_clone == null or not player.is_inside_tree():
		return
	DetachedHit.spawn(player.get_parent(), config.shadow_clone, player, combatant.team, player.facing,
			_dodge_origin, {}, ResourceComponent.HitKind.NONE, player.character_id + ".dodge_clone")
