class_name PlayerController
extends CharacterBody2D
## Điều khiển nhân vật trên sân: vật lý di chuyển + state machine + animation.
## Gốc node là chân nhân vật (pivot đáy giữa, README 2.2).
## Thông số trong MovementConfig (.tres); không có số cân bằng trong script.

signal state_changed(from: StringName, to: StringName)
signal jumped
signal landed

const DEFAULT_CONFIG := preload("res://data/config/movement_default.tres")

## Màu tạm tô lên placeholder theo nguyên tố (token vòng Liên kết, README 17.5).
## Chỉ dùng khi nhân vật chưa có hình thật.
const PLACEHOLDER_TINT := {
	"fire": Color("#FF6A3D"), "wind": Color("#3DDBB5"), "lightning": Color("#FFD93D"),
	"light": Color("#FFF2B8"), "dark": Color("#A855F7"), "earth": Color("#D99A3E"),
}

@export var character_id := "char_fire_01"
@export var config: MovementConfig = DEFAULT_CONFIG
## Tắt để test tự cấp input qua `intent` và tự gọi `step()`.
@export var use_player_input := true

var intent := PlayerIntent.new()
var fsm := StateMachine.new()
## 1 = phải, -1 = trái.
var facing := 1

var _coyote_left := 0.0
var _jumped_this_tick := false

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	if config == null:
		config = DEFAULT_CONFIG
	_setup_sprite()
	MovementStates.register(fsm, self)
	fsm.state_changed.connect(_on_state_changed)
	fsm.start(MovementStates.FALL)
	_play(MovementStates.FALL)


func _physics_process(delta: float) -> void:
	if use_player_input:
		intent.read_from_input(config.jump_buffer_time)
	step(delta)


## Một tick vật lý. Tách riêng để test gọi với delta cố định.
func step(delta: float) -> void:
	_jumped_this_tick = false
	var was_on_floor := is_on_floor()

	fsm.physics_update(delta)
	_apply_horizontal(delta)
	# Chia trọng lực hai nửa quanh bước di chuyển (tích phân điểm giữa): đỉnh nhảy đúng
	# jump_height ở mọi tốc độ khung hình, thay vì thấp hơn ~v·dt/2.
	_apply_gravity(delta * 0.5)
	move_and_slide()
	_apply_gravity(delta * 0.5)

	# Coyote: rời mặt đất mà không phải do nhảy thì còn được nhảy trong coyote_time.
	if was_on_floor and not is_on_floor() and not _jumped_this_tick:
		_coyote_left = config.coyote_time
	elif is_on_floor():
		_coyote_left = 0.0
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)

	intent.tick(delta)
	_update_facing()


func start_jump() -> void:
	velocity.y = -config.jump_velocity()
	intent.consume_jump()
	_coyote_left = 0.0
	_jumped_this_tick = true
	jumped.emit()


func can_coyote_jump() -> bool:
	return _coyote_left > 0.0


func current_state() -> StringName:
	return fsm.current_name


func _apply_horizontal(delta: float) -> void:
	var target := intent.move_x * config.run_speed
	var on_floor := is_on_floor()
	var speeding_up := absf(target) > 0.0 and (signf(target) == signf(velocity.x) or is_zero_approx(velocity.x))
	var rate: float
	if on_floor:
		rate = config.ground_accel if speeding_up else config.ground_decel
	else:
		rate = config.air_accel if speeding_up else config.air_decel
	velocity.x = move_toward(velocity.x, target, rate * delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		return
	var g := config.rise_gravity() if velocity.y < 0.0 else config.fall_gravity()
	velocity.y = minf(velocity.y + g * delta, config.max_fall_speed)


func _update_facing() -> void:
	if intent.move_x > MovementStates.MOVE_EPSILON:
		facing = 1
	elif intent.move_x < -MovementStates.MOVE_EPSILON:
		facing = -1
	if sprite:
		sprite.flip_h = facing < 0


func _setup_sprite() -> void:
	var result := AnimationSetBuilder.build_for_character(character_id)
	for e in result.errors:
		push_warning("PlayerController %s: %s" % [character_id, e])
	sprite.sprite_frames = result.sprite_frames
	sprite.centered = true
	sprite.offset = result.sprite_offset
	var element := str(result.manifest.get("element", ""))
	var all_placeholder := result.placeholder_animations.size() == result.sprite_frames.get_animation_names().size()
	sprite.modulate = PLACEHOLDER_TINT.get(element, Color.WHITE) if all_placeholder else Color.WHITE


func _on_state_changed(from: StringName, to: StringName) -> void:
	_play(to)
	if to == MovementStates.LAND:
		landed.emit()
	state_changed.emit(from, to)


func _play(anim: StringName) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
