class_name CombatStates
extends RefCounted
## State chiến đấu của người chơi. Kỹ năng chạy bằng SkillRunner; state chỉ quyết định nối/huỷ/kết thúc.

const ATTACK := &"attack"
const DODGE := &"dodge"
const CHARGE := &"charge"
const PLUNGE := &"plunge"
const HURT := &"hurt"
const DOWN := &"down"


static func register(fsm: StateMachine, player: PlayerController) -> void:
	fsm.add(ATTACK, Attack.new(player))
	fsm.add(DODGE, Dodge.new(player))
	fsm.add(CHARGE, Charge.new(player))
	fsm.add(PLUNGE, Plunge.new(player))
	fsm.add(HURT, Hurt.new(player))
	fsm.add(DOWN, Down.new(player))


## Bị khựng sau khi trúng đòn: không điều khiển được trong player_stagger_sec.
class Hurt:
	extends PlayerState
	var _t := 0.0

	func enter(_from: StringName) -> void:
		_t = player.combatant.rules.player_stagger_sec
		player.intent.clear()

	func physics_update(delta: float) -> StringName:
		_t -= delta
		if _t <= 0.0:
			return player.idle_or_air_state()
		return &""


## Gục (HP 0). Không điều khiển; hồi sinh tắt (Q6) — màn thử nghiệm tự hồi sinh.
class Down:
	extends PlayerState

	func enter(_from: StringName) -> void:
		player.runner.cancel()
		player.intent.clear()

	func check_transitions() -> StringName:
		if not player.combatant.resources.is_dead():
			return player.idle_or_air_state()
		return &""


## Đang giữ nút đánh để nạp (chỉ trên mặt đất). Nhả: chọn cấp theo thời gian đã giữ.
class Charge:
	extends PlayerState

	func enter(_from: StringName) -> void:
		player.charging = true

	func exit(_to: StringName) -> void:
		player.charging = false

	func physics_update(_delta: float) -> StringName:
		if player.intent.has(PlayerIntent.DODGE) and player.can_dodge():
			return DODGE
		if not player.is_on_floor():
			return MovementStates.FALL
		if player.intent.attack_held:
			# Đòn giữ tự chạy khi đủ thời gian nạp (không chờ nhả).
			var auto := player.auto_hold_skill_for(player.intent.attack_hold_time * 1000.0)
			if auto != "":
				player.pending_skill = auto
				return ATTACK
			return &""
		# Đã nhả: cấp cao nhất đạt được; chưa tới cấp 1 thì là đòn thường.
		player.pending_skill = player.hold_skill_for(player.intent.released_hold_time * 1000.0)
		return ATTACK


## Đáp đất: treo ngắn, lao thẳng xuống, chạm đất thì chạy kỹ năng "landing" (nổ).
class Plunge:
	extends PlayerState
	var _t := 0.0
	var _skill: SkillDef

	func enter(_from: StringName) -> void:
		_t = 0.0
		_skill = player.runner.skills.get("landing")
		player.velocity_override_active = true
		player.velocity_override = Vector2.ZERO
		player.plunging = true

	func exit(_to: StringName) -> void:
		player.velocity_override_active = false
		player.plunging = false

	func physics_update(delta: float) -> StringName:
		_t += delta * 1000.0
		if _t < _skill.pre_dive_ms:
			player.velocity_override = Vector2.ZERO
		else:
			# Góc 0 = thẳng xuống; nghiêng về hướng mặt (Raikiba lao chéo 45°).
			var a := deg_to_rad(_skill.dive_angle_deg)
			player.velocity_override = Vector2(sin(a) * player.facing, cos(a)) * _skill.dive_speed_px
		if player.is_on_floor() and _t >= _skill.pre_dive_ms:
			player.pending_skill = "landing"
			return ATTACK
		return &""


## Đòn thường (chuỗi 4 đòn của Aether); sau này thêm kỹ năng / vũ khí / tuyệt kỹ dùng chung state này.
class Attack:
	extends PlayerState

	func enter(_from: StringName) -> void:
		var key := player.pending_skill
		player.pending_skill = ""
		if key == "":
			key = player.runner.next_normal_key()
		if not player.runner.run(key, player.facing_for_action()):
			player.skill_failed = true

	func physics_update(_delta: float) -> StringName:
		var r := player.runner
		# Đòn giữ kéo dài: nhả nút, hết EN hoặc hết giờ thì dừng, có thể nối đòn kết (release_skill).
		if r.current and r.current.release_ends and (not player.intent.attack_held or r.en_ran_out
				or r.elapsed_ms >= r.current.total_ms() - 20.0):
			var nxt := player.release_skill_for(r.current)
			r.cancel()
			if nxt != "" and r.run(nxt, r.facing):
				return &""
			return player.idle_or_air_state()
		# Bấm đánh trong cửa sổ nối đòn: đòn kế tiếp chạy ngay khi đòn này hết.
		if player.intent.has(PlayerIntent.ATTACK) and r.can_queue_chain():
			r.queue_chain()
			player.intent.consume(PlayerIntent.ATTACK)
		# Né huỷ nửa sau pha hồi phục (mục 0).
		if player.intent.has(PlayerIntent.DODGE) and r.can_dodge_cancel() and player.can_dodge():
			r.cancel()
			return DODGE
		return check_transitions()

	func check_transitions() -> StringName:
		if player.skill_failed:
			player.skill_failed = false
			return player.idle_or_air_state()
		if not player.runner.is_running():
			return player.idle_or_air_state()
		return &""


class Dodge:
	extends PlayerState

	func enter(_from: StringName) -> void:
		player.intent.consume(PlayerIntent.DODGE)
		player.combatant.resources.try_dodge()
		player.runner.run("dodge", player.facing_for_action())

	func check_transitions() -> StringName:
		if not player.runner.is_running():
			return player.idle_or_air_state()
		return &""
