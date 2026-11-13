class_name EarthKit
extends Node
## Logic riêng của Iwagane (char_earth_01), CHARACTER_SKILLS mục 6:
## - Nội tại Cốt Đá Bất Khuất: mỗi lần nhận sát thương +1 Cốt Đá (ICD 0.5 s, tối đa 5, 8 s), mỗi tầng −3% sát thương nhận;
##   mỗi lần nhận đòn −0.5 s CD Kĩ năng thường (ICD 2 s, tối đa −3.0 s mỗi chu kỳ).
##   Đủ 5 tầng: Kĩ năng vũ khí kế tiếp +40% và nổ thêm 130% bán kính 200 ở cuối sóng đá, rồi tiêu hết tầng.
## - Thủ Thế Đại Địa (giữ TC): đếm đòn chặn được (+1 Cốt Đá mỗi đòn); chặn hoàn hảo (200 ms đầu khi chắn) phản 120%
##   bán kính 180 và báo giảm SI-CD (8.10). Nhả: đã chặn ≥ 1 đòn → chém 170% (hold_slash), chưa → 90% (hold_slash_weak).
## - Nạp UG +20% khi đang có Giáp Địa hoặc ≥ 3 Cốt Đá. Thạch Thần (sau Tuyệt kỹ): +20% ATK.
## - Né hoàn hảo — Phản Chấn: sóng đá 100% bán kính 160, +1 Cốt Đá.

const BONE := "stone_bone"
const GUARD := "guard"
const STONE_GOD := "stone_god"
const GUARD_SKILL := "hold_1"

var player: PlayerController
var config: EarthKitConfig
var combatant: Combatant

var _bone_icd := 0.0
var _hit_cd_icd := 0.0
var blocked := 0                   # đòn chặn được trong lần chắn hiện tại
var perfect_blocks := 0            # đếm để test


func attach(p: PlayerController, cfg: Resource) -> void:
	player = p
	config = cfg as EarthKitConfig
	combatant = p.combatant
	combatant.damaged.connect(_on_damaged)
	p.runner.skill_started.connect(_on_skill_started)
	p.runner.skill_finished.connect(_on_skill_finished)
	p.runner.bonus_provider = _bonus_for
	p.perfect_dodged.connect(_on_perfect_dodge)


func tick(delta: float) -> void:
	if config == null:
		return
	_bone_icd = maxf(_bone_icd - delta, 0.0)
	_hit_cd_icd = maxf(_hit_cd_icd - delta, 0.0)
	var st := combatant.statuses
	# Tầng có thể đến từ Kĩ năng vào sân (SwitchInDef áp nhiều lần): luôn giữ độ lớn = 3% × số tầng.
	st.set_magnitude(BONE, config.bone_damage_reduction * bones())
	combatant.resources.ug_gain_multiplier = config.ug_bonus_multiplier \
			if st.has("earth_guard") or bones() >= config.ug_bonus_bones else 1.0
	combatant.atk_bonus[STONE_GOD] = config.stone_god_atk if st.has(STONE_GOD) else 0.0


func bones() -> int:
	return combatant.statuses.stacks(BONE)


func add_bone() -> void:
	combatant.statuses.apply(BONE, -1.0, -1.0, combatant)
	combatant.statuses.set_magnitude(BONE, config.bone_damage_reduction * bones())


func release_skill_for(s: SkillDef) -> String:
	if s.id.ends_with("." + GUARD_SKILL):
		return config.release_blocked if blocked > 0 else config.release_unblocked
	return s.release_skill


func _bonus_for(skill: SkillDef) -> Dictionary:
	if config == null or skill.key != "weapon" or bones() < config.full_bones:
		return {}
	# Đủ Cốt Đá: +40% và nổ thêm ở cuối sóng đá, rồi tiêu hết tầng.
	combatant.statuses.remove(BONE)
	if config.bone_burst and player.is_inside_tree():
		DetachedHit.spawn(player.get_parent(), config.bone_burst, player, combatant.team, player.runner.facing,
				player.global_position, {}, ResourceComponent.HitKind.WEAPON, player.character_id + ".bone_burst")
	return {"stone_bone_full": config.full_bones_weapon_bonus}


func _on_skill_started(_key: String, skill: SkillDef) -> void:
	if skill.id.ends_with("." + GUARD_SKILL):
		blocked = 0


func _on_skill_finished(_key: String, skill: SkillDef) -> void:
	if skill.id.ends_with("." + GUARD_SKILL):
		combatant.statuses.remove(GUARD)


func _on_damaged(_result: DamageCalculator.Result, _hit: HitInfo) -> void:
	if config == null or combatant.resources.is_dead():
		return
	if _bone_icd <= 0.0:
		_bone_icd = config.bone_icd_sec
		add_bone()
	if _hit_cd_icd <= 0.0:
		_hit_cd_icd = config.hit_skill_cd_icd_sec
		combatant.cooldowns.reduce(&"skill", config.hit_skill_cd_sec, config.hit_skill_cd_max_per_cycle_sec)
	var r := player.runner
	if r.current and r.current.id.ends_with("." + GUARD_SKILL) and r.elapsed_ms >= r.current.startup_ms:
		blocked += 1
		add_bone()
		if r.elapsed_ms - r.current.startup_ms <= config.perfect_block_window_ms and config.block_reflect:
			perfect_blocks += 1
			DetachedHit.spawn(player.get_parent(), config.block_reflect, player, combatant.team, player.facing,
					player.global_position, {}, ResourceComponent.HitKind.HOLD, player.character_id + ".block_reflect")
			player.kit_event.emit(SwitchInDef.REDUCE_PERFECT_BLOCK)


func _on_perfect_dodge(_hit: HitInfo) -> void:
	if config == null or config.counter_wave == null or not player.is_inside_tree():
		return
	add_bone()
	DetachedHit.spawn(player.get_parent(), config.counter_wave, player, combatant.team, player.facing,
			player.global_position, {}, ResourceComponent.HitKind.NONE, player.character_id + ".dodge_counter")
