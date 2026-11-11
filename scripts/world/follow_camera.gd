class_name FollowCamera
extends Camera2D
## Camera bám theo nhân vật (README 15.7): mượt, nhìn trước theo hướng mặt,
## giữ độ cao khi nhảy nhỏ để màn hình không giật lên xuống, khóa trong biên màn.
## Thông số chỉnh trong Inspector của scene stage.

## Khoảng nhìn trước theo hướng nhân vật quay mặt (px).
@export var look_ahead := 220.0
## Tốc độ chuyển khoảng nhìn trước khi đổi hướng (1/s, càng lớn càng nhanh).
@export var look_ahead_rate := 3.0
## Tốc độ bám ngang / dọc (1/s).
@export var follow_rate_x := 8.0
@export var follow_rate_y := 5.0
## Tâm camera cao hơn chân nhân vật bao nhiêu (px).
@export var height_offset := 160.0
## Đang trên không: chỉ đổi độ cao camera khi lên cao hơn mặt đất gần nhất quá mức này (px).
## Lớn hơn độ cao nhảy tối đa (320) để nhảy trên đất bằng không làm camera nhấp nhô.
@export var deadzone_up := 360.0
## Đang trên không: rơi thấp hơn mặt đất gần nhất quá mức này thì camera theo xuống ngay (px).
@export var deadzone_down := 64.0

var target: PlayerController

var _look := 0.0
var _ground_y := 0.0


func _ready() -> void:
	# Tự xử lý mượt; tắt làm mượt sẵn có của Camera2D để không làm hai lần.
	position_smoothing_enabled = false
	limit_smoothed = true
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS


## Đặt mục tiêu và nhảy ngay tới vị trí (không trượt từ chỗ cũ).
func follow(p: PlayerController) -> void:
	target = p
	_ground_y = p.global_position.y
	_look = look_ahead * p.facing
	global_position = desired_position()
	reset_smoothing()


func set_bounds(rect: Rect2i) -> void:
	limit_left = rect.position.x
	limit_top = rect.position.y
	limit_right = rect.end.x
	limit_bottom = rect.end.y


func _physics_process(delta: float) -> void:
	update_camera(delta)


## Một bước camera; tách riêng để test gọi với delta cố định.
func update_camera(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	_look = lerpf(_look, look_ahead * target.facing, 1.0 - exp(-look_ahead_rate * delta))
	var y := target.global_position.y
	if target.is_on_floor() or y < _ground_y - deadzone_up or y > _ground_y + deadzone_down:
		_ground_y = y
	var goal := desired_position()
	global_position.x = lerpf(global_position.x, goal.x, 1.0 - exp(-follow_rate_x * delta))
	global_position.y = lerpf(global_position.y, goal.y, 1.0 - exp(-follow_rate_y * delta))


func desired_position() -> Vector2:
	return Vector2(target.global_position.x + _look, _ground_y - height_offset)
