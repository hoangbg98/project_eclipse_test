class_name MovementStates
extends RefCounted
## Các state di chuyển: idle, run, jump_up, fall, land (ARCHITECTURE mục 7).
## Tên state trùng tên animation trong frames_manifest.json.

const IDLE := &"idle"
const RUN := &"run"
const JUMP_UP := &"jump_up"
const FALL := &"fall"
const LAND := &"land"

## Dưới ngưỡng này coi như không bấm hướng.
const MOVE_EPSILON := 0.01


static func register(fsm: StateMachine, player: PlayerController) -> void:
	fsm.add(IDLE, Idle.new(player))
	fsm.add(RUN, Run.new(player))
	fsm.add(JUMP_UP, JumpUp.new(player))
	fsm.add(FALL, Fall.new(player))
	fsm.add(LAND, Land.new(player))


class Idle:
	extends PlayerState

	func check_transitions() -> StringName:
		if not player.is_on_floor():
			return FALL
		if player.intent.has_jump():
			return JUMP_UP
		if absf(player.intent.move_x) > MOVE_EPSILON:
			return RUN
		return &""


class Run:
	extends PlayerState

	func check_transitions() -> StringName:
		if not player.is_on_floor():
			return FALL
		if player.intent.has_jump():
			return JUMP_UP
		if absf(player.intent.move_x) <= MOVE_EPSILON:
			return IDLE
		return &""


class JumpUp:
	extends PlayerState
	var _cut_done := false

	func enter(_from: StringName) -> void:
		_cut_done = false
		player.start_jump()

	func physics_update(_delta: float) -> StringName:
		# Nhảy cao/thấp: thả nút khi còn đang lên thì cắt vận tốc một lần.
		if not _cut_done and not player.intent.jump_held and player.velocity.y < 0.0:
			player.velocity.y *= player.config.jump_cut_multiplier
			_cut_done = true
		return check_transitions()

	func check_transitions() -> StringName:
		if player.velocity.y >= 0.0:
			return FALL
		return &""


class Fall:
	extends PlayerState

	func check_transitions() -> StringName:
		if player.is_on_floor():
			return LAND
		if player.intent.has_jump() and player.can_coyote_jump():
			return JUMP_UP
		return &""


class Land:
	extends PlayerState
	var _time_left := 0.0

	func enter(_from: StringName) -> void:
		_time_left = player.config.land_duration

	func physics_update(delta: float) -> StringName:
		_time_left -= delta
		return check_transitions()

	func check_transitions() -> StringName:
		if not player.is_on_floor():
			return FALL
		# Nhảy hoặc chạy đều huỷ ngay pha đáp.
		if player.intent.has_jump():
			return JUMP_UP
		if absf(player.intent.move_x) > MOVE_EPSILON:
			return RUN
		if _time_left <= 0.0:
			return IDLE
		return &""
