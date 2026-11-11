class_name CombatStates
extends RefCounted
## State chiến đấu của người chơi. Kỹ năng chạy bằng SkillRunner; state chỉ quyết định nối/huỷ/kết thúc.

const ATTACK := &"attack"
const DODGE := &"dodge"


static func register(fsm: StateMachine, player: PlayerController) -> void:
	fsm.add(ATTACK, Attack.new(player))
	fsm.add(DODGE, Dodge.new(player))


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
