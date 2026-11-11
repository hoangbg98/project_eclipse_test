class_name StateMachine
extends RefCounted
## State machine tối giản: mỗi state là một PlayerState, khóa bằng StringName.
## Mỗi tick, state hiện tại trả về tên state kế tiếp (hoặc &"" để ở lại).

signal state_changed(from: StringName, to: StringName)

var states: Dictionary = {}  # StringName -> PlayerState
var current: PlayerState
var current_name: StringName = &""
## Số lần chuyển state tối đa trong một tick (chặn vòng lặp vô hạn khi state trả về nhau).
const MAX_CHAIN := 4


func add(state_name: StringName, state: PlayerState) -> void:
	state.name = state_name
	states[state_name] = state


func start(state_name: StringName) -> void:
	current_name = state_name
	current = states[state_name]
	current.enter(&"")


func physics_update(delta: float) -> void:
	var next := current.physics_update(delta)
	var chain := 0
	while next != &"" and next != current_name and chain < MAX_CHAIN:
		transition(next)
		# State mới được kiểm tra ngay (delta 0) để không trễ một frame.
		next = current.check_transitions()
		chain += 1


func transition(to: StringName) -> void:
	if not states.has(to):
		push_error("StateMachine: không có state %s" % to)
		return
	var from := current_name
	current.exit(to)
	current_name = to
	current = states[to]
	current.enter(from)
	state_changed.emit(from, to)
