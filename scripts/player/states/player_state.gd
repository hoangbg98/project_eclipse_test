class_name PlayerState
extends RefCounted
## Lớp cơ sở cho state người chơi. Controller giữ vật lý; state quyết định ý định và chuyển state.

var name: StringName = &""
var player: PlayerController


func _init(p: PlayerController) -> void:
	player = p


func enter(_from: StringName) -> void:
	pass


func exit(_to: StringName) -> void:
	pass


## Gọi mỗi tick vật lý. Trả về tên state kế tiếp hoặc &"".
func physics_update(_delta: float) -> StringName:
	return check_transitions()


## Điều kiện chuyển state, không thay đổi vật lý (dùng cả khi vừa vào state).
func check_transitions() -> StringName:
	return &""
