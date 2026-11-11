class_name PlayerIntent
extends RefCounted
## Ý định điều khiển của người chơi trong một tick vật lý.
## Tách khỏi InputRouter để controller test được bằng input giả và thời gian vật lý cố định.
## Mỗi nút hành động có bộ đệm riêng tính theo thời gian vật lý.

const JUMP := &"jump"
const ATTACK := &"attack"
const DODGE := &"dodge"
const SKILL := &"skill"
const WEAPON := &"weapon"
const ULTIMATE := &"ultimate"
## Nút đọc từ InputRouter theo kiểu "vừa nhấn" (đánh xử lý riêng: tính khi nhả).
const PRESS_ACTIONS: Array[StringName] = [JUMP, DODGE, SKILL, WEAPON, ULTIMATE]

## -1..1
var move_x := 0.0
## Nút nhảy đang được giữ (cho nhảy cao/thấp).
var jump_held := false
## Nút đánh đang được giữ và đã giữ bao lâu (s).
var attack_held := false
var attack_hold_time := 0.0
## Giữ nút đánh ít nhất bấy nhiêu giây thì là đòn giữ, nhả sớm hơn là đòn thường (Aether: 0.4).
var hold_threshold := 0.4

var _buffers: Dictionary = {}  # StringName -> giây còn lại


## Ghi nhận một lần nhấn; giữ trong bộ đệm `buffer_time` giây.
func press(action: StringName, buffer_time: float) -> void:
	_buffers[action] = buffer_time
	if action == JUMP:
		jump_held = true


func has(action: StringName) -> bool:
	return float(_buffers.get(action, 0.0)) > 0.0


func consume(action: StringName) -> void:
	_buffers.erase(action)


func clear() -> void:
	_buffers.clear()


# --- Nhảy (giữ API cũ) ---

func press_jump(buffer_time: float) -> void:
	press(JUMP, buffer_time)


func release_jump() -> void:
	jump_held = false


func has_jump() -> bool:
	return has(JUMP)


func consume_jump() -> void:
	consume(JUMP)


# --- Đánh: nhả trước ngưỡng giữ = đòn thường ---

func attack_down() -> void:
	attack_held = true
	attack_hold_time = 0.0


## Nhả nút đánh; nếu giữ chưa tới ngưỡng thì ghi một lần "đánh" vào bộ đệm.
func attack_up(buffer_time: float) -> void:
	if attack_held and attack_hold_time < hold_threshold:
		press(ATTACK, buffer_time)
	attack_held = false
	attack_hold_time = 0.0


## Bấm nhanh (xuống + lên) — tiện cho test và cảm ứng.
func tap_attack(buffer_time: float) -> void:
	attack_down()
	attack_up(buffer_time)


## Đã giữ đủ lâu để thành đòn giữ.
func is_holding_attack() -> bool:
	return attack_held and attack_hold_time >= hold_threshold


## Gọi mỗi tick vật lý để bộ đệm hết hạn theo thời gian vật lý.
func tick(delta: float) -> void:
	for a in _buffers.keys():
		_buffers[a] = float(_buffers[a]) - delta
		if float(_buffers[a]) <= 0.0:
			_buffers.erase(a)
	if attack_held:
		attack_hold_time += delta


## Đọc từ action chung của InputRouter (bàn phím, tay cầm, cảm ứng).
func read_from_input(buffer_time: float) -> void:
	move_x = Input.get_axis(&"move_left", &"move_right")
	for a in PRESS_ACTIONS:
		if Input.is_action_just_pressed(a):
			press(a, buffer_time)
	jump_held = Input.is_action_pressed(JUMP)
	if Input.is_action_just_pressed(ATTACK):
		attack_down()
	if Input.is_action_just_released(ATTACK):
		attack_up(buffer_time)
