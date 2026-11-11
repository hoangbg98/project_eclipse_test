class_name PlayerIntent
extends RefCounted
## Ý định điều khiển của người chơi trong một tick vật lý.
## Tách khỏi InputRouter để controller test được bằng input giả và thời gian vật lý cố định.

## -1..1
var move_x := 0.0
## Nút nhảy đang được giữ (cho nhảy cao/thấp).
var jump_held := false

## Thời gian còn lại của lần nhấn nhảy trong bộ đệm (s); 0 = không có.
var _jump_buffer_left := 0.0


## Ghi nhận một lần nhấn nhảy; giữ trong bộ đệm `buffer_time` giây.
func press_jump(buffer_time: float) -> void:
	_jump_buffer_left = buffer_time
	jump_held = true


func release_jump() -> void:
	jump_held = false


func has_jump() -> bool:
	return _jump_buffer_left > 0.0


func consume_jump() -> void:
	_jump_buffer_left = 0.0


## Gọi mỗi tick vật lý để bộ đệm hết hạn theo thời gian vật lý.
func tick(delta: float) -> void:
	_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)


## Đọc từ action chung của InputRouter (bàn phím, tay cầm, cảm ứng).
func read_from_input(buffer_time: float) -> void:
	move_x = Input.get_axis(&"move_left", &"move_right")
	if Input.is_action_just_pressed(&"jump"):
		press_jump(buffer_time)
	jump_held = Input.is_action_pressed(&"jump")
