class_name PlayerController
extends CharacterBody2D
## Điều khiển nhân vật trên sân: vật lý di chuyển + state machine + chiến đấu + animation.
## Gốc node là chân nhân vật (pivot đáy giữa, README 2.2).
## Thông số di chuyển, chỉ số, kỹ năng lấy từ CharacterDef (data/characters/{id}.tres).

signal state_changed(from: StringName, to: StringName)
signal jumped
signal landed

const DEFAULT_CONFIG := preload("res://data/config/movement_default.tres")
const CHARACTER_DATA := "res://data/characters/%s.tres"

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
var character: CharacterDef
## Kỹ năng state Attack sẽ chạy (rỗng = đòn thường kế tiếp).
var pending_skill := ""
## Kỹ năng vừa bị từ chối; state Attack trả về ngay.
var skill_failed := false

var _coyote_left := 0.0
var _jumped_this_tick := false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var combatant: Combatant = $Combatant
@onready var runner: SkillRunner = $Skills
@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	_load_character()
	if config == null:
		config = DEFAULT_CONFIG
	_setup_sprite()
	combatant.setup()
	runner.setup(self, combatant, character.load_skills() if character else {}, hurtbox)
	runner.skill_started.connect(func(_k: String, s: SkillDef) -> void: _play(StringName(s.animation)))
	MovementStates.register(fsm, self)
	CombatStates.register(fsm, self)
	fsm.state_changed.connect(_on_state_changed)
	fsm.start(MovementStates.FALL)
	_play(MovementStates.FALL)


func _load_character() -> void:
	var path := CHARACTER_DATA % character_id
	if not ResourceLoader.exists(path):
		push_warning("PlayerController: không có %s" % path)
		return
	character = load(path)
	if character.movement:
		config = character.movement
	if character.stats:
		combatant.stats = character.stats


func _physics_process(delta: float) -> void:
	if use_player_input:
		intent.read_from_input(config.jump_buffer_time)
	step(delta)


## Một tick vật lý. Tách riêng để test gọi với delta cố định.
func step(delta: float) -> void:
	_jumped_this_tick = false
	var was_on_floor := is_on_floor()

	combatant.tick(delta)
	fsm.physics_update(delta)
	runner.advance(delta)
	_apply_horizontal(delta)
	if runner.suspends_gravity():
		velocity.y = 0.0
		move_and_slide()
	else:
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


# ---------- Chiến đấu ----------

## State di chuyển gọi đầu tiên: có cần chuyển sang né / đánh không.
func combat_transition() -> StringName:
	if intent.has(PlayerIntent.DODGE) and can_dodge():
		return CombatStates.DODGE
	if intent.has(PlayerIntent.ATTACK) and is_on_floor() and runner.has_skill(SkillRunner.NORMAL_FIRST):
		intent.consume(PlayerIntent.ATTACK)
		pending_skill = ""
		return CombatStates.ATTACK
	return &""


func can_dodge() -> bool:
	return runner.has_skill("dodge") and combatant.resources.dodge_charges > 0 \
			and runner.check("dodge") == ""


## Hướng cho hành động mới: theo nút hướng đang giữ, không thì hướng đang nhìn.
func facing_for_action() -> int:
	if intent.move_x > MovementStates.MOVE_EPSILON:
		facing = 1
	elif intent.move_x < -MovementStates.MOVE_EPSILON:
		facing = -1
	return facing


func idle_or_air_state() -> StringName:
	if not is_on_floor():
		return MovementStates.FALL
	if absf(intent.move_x) > MovementStates.MOVE_EPSILON:
		return MovementStates.RUN
	return MovementStates.IDLE


# ---------- Vật lý ----------

func _apply_horizontal(delta: float) -> void:
	if runner.is_running():
		velocity.x = runner.velocity_x()
		return
	var speed := config.run_speed * (1.0 - combatant.statuses.move_slow())
	if combatant.statuses.blocks_movement():
		speed = 0.0
	var target := intent.move_x * speed
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
	# Hướng khóa trong lúc ra đòn (SkillRunner giữ hướng lúc bắt đầu).
	if not runner.is_running():
		if intent.move_x > MovementStates.MOVE_EPSILON:
			facing = 1
		elif intent.move_x < -MovementStates.MOVE_EPSILON:
			facing = -1
	else:
		facing = runner.facing
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
	if to not in [CombatStates.ATTACK, CombatStates.DODGE]:
		_play(to)
	if to == MovementStates.LAND:
		landed.emit()
	state_changed.emit(from, to)


func _play(anim: StringName) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
