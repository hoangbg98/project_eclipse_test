class_name EnemyController
extends CharacterBody2D
## Quái thường (M3-6): tuần tra → thấy người chơi thì đuổi → vào tầm thì đánh (pha khởi động = báo hiệu)
## → hồi → đuổi tiếp. Trúng đòn: khựng (ngắt pha khởi động), bị đẩy lùi, tích sức choáng (SC);
## SC đầy → Choáng. Hết máu → mờ dần rồi biến mất. Số liệu trong EnemyDef (data/enemies/).

signal died(enemy: EnemyController)

enum State { PATROL, CHASE, ATTACK, STAGGER, STUNNED, DEAD }

const ENEMY_DATA := "res://data/enemies/%s.tres"
const GROUP := &"enemies"
const PLAYER_GROUP := &"player"

@export var enemy_id := "enemy_slime_01"

var def: EnemyDef
var state := State.PATROL
## 1 = phải, -1 = trái.
var facing := -1
var target: Node2D
var home := Vector2.ZERO
## Sức choáng hiện tại (0..def.sc_max).
var sc := 0.0

var _sc_idle := 0.0
var _timer := 0.0
var _attack_cd := 0.0
var _patrol_dir := -1
var _knock_v := 0.0
var _knock_t := 0.0
var _fade := 0.0
var _flash := 0.0
var _last_attacker: Object
var _frozen := 0.0

@onready var combatant: Combatant = $Combatant
@onready var runner: SkillRunner = $Skills
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var body: Polygon2D = $Body


func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(HitFeedback.TIME_STOP_GROUP)
	def = load(ENEMY_DATA % enemy_id)
	combatant.stats = def.stats
	combatant.setup()
	runner.setup(self, combatant, {"attack": def.attack} if def.attack else {}, hurtbox)
	combatant.damaged.connect(_on_damaged)
	combatant.resources.died.connect(_on_died)
	body.color = def.placeholder_color
	home = global_position


func _physics_process(delta: float) -> void:
	step(delta)


## Dừng thời gian (cut-in tuyệt kỹ): đứng yên hoàn toàn, trạng thái và hồi chiêu cũng không chạy.
func freeze(seconds: float) -> void:
	_frozen = maxf(_frozen, seconds)


func is_frozen() -> bool:
	return _frozen > 0.0


## Một tick; tách riêng để test bước với delta cố định.
func step(delta: float) -> void:
	if _frozen > 0.0:
		_frozen -= delta
		velocity = Vector2.ZERO
		return
	combatant.tick(delta)
	_flash = maxf(_flash - delta, 0.0)
	if state == State.DEAD:
		_fade += delta
		modulate.a = 1.0 - clampf(_fade / def.death_fade_sec, 0.0, 1.0)
		if _fade >= def.death_fade_sec:
			queue_free()
		return
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_tick_sc(delta)
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(PLAYER_GROUP) as Node2D if is_inside_tree() else null

	if combatant.statuses.blocks_actions():
		if state != State.STUNNED:
			runner.cancel()
			state = State.STUNNED
	match state:
		State.PATROL:
			if _sees_target():
				state = State.CHASE
		State.CHASE:
			if not _target_alive() or _dist_to_target() > def.lose_range:
				state = State.PATROL
			else:
				var dx := target.global_position.x - global_position.x
				if absf(dx) > 4.0:
					facing = 1 if dx > 0.0 else -1
				if absf(dx) <= def.attack_range and _attack_cd <= 0.0 and is_on_floor():
					if runner.run("attack", facing):
						state = State.ATTACK
		State.ATTACK:
			if not runner.is_running():
				_attack_cd = def.attack_cooldown_sec
				state = State.CHASE
		State.STAGGER:
			_timer -= delta
			if _timer <= 0.0:
				state = State.CHASE
		State.STUNNED:
			if not combatant.statuses.blocks_actions():
				sc = 0.0
				state = State.CHASE

	runner.advance(delta)
	velocity.x = _desired_velocity_x(delta)
	velocity.y = minf(velocity.y + def.gravity * delta, 2000.0)
	move_and_slide()
	_update_look()
	queue_redraw()


func is_dead() -> bool:
	return state == State.DEAD


func is_telegraphing() -> bool:
	return state == State.ATTACK and runner.is_running() and runner.elapsed_ms < runner.current.active_start_ms()


# ---------- Di chuyển ----------

func _desired_velocity_x(delta: float) -> float:
	if _knock_t > 0.0:
		_knock_t -= delta
		return _knock_v
	if combatant.statuses.blocks_movement():
		return 0.0
	var speed := def.move_speed * (1.0 - combatant.statuses.move_slow())
	match state:
		State.ATTACK:
			return runner.velocity_x()
		State.CHASE:
			var dx := target.global_position.x - global_position.x if _target_alive() else 0.0
			# Dừng lại khi đã vào tầm đánh (chờ hồi đòn).
			return 0.0 if absf(dx) <= def.attack_range * 0.8 else speed * signf(dx)
		State.PATROL:
			return _patrol_velocity(delta, speed)
	return 0.0


func _patrol_velocity(delta: float, speed: float) -> float:
	if _timer > 0.0:
		_timer -= delta
		return 0.0
	var offset := global_position.x - home.x
	if (_patrol_dir < 0 and offset <= -def.patrol_radius) or (_patrol_dir > 0 and offset >= def.patrol_radius):
		_patrol_dir = -_patrol_dir
		_timer = def.patrol_pause_sec
		return 0.0
	facing = _patrol_dir
	return speed * 0.5 * _patrol_dir


# ---------- Nhận đòn ----------

func _on_damaged(_result: DamageCalculator.Result, hit: HitInfo) -> void:
	if state == State.DEAD:
		return
	_last_attacker = Combatant.of(hit.attacker)
	_flash = 0.08
	if hit.attacker is Node2D:
		target = hit.attacker  # bị đánh thì quay sang đánh lại
	_add_sc(hit.sc_ratio * combatant.rules.sc_points_per_ratio)
	if state == State.DEAD or state == State.STUNNED:
		_apply_knockback(hit, 0.0)
		return
	var can_stagger := def.stagger_sec > 0.0 and not combatant.statuses.stagger_immune() \
			and not runner.has_super_armor()
	# Đã qua pha khởi động (đòn đang có hiệu lực) thì không ngắt được.
	if state == State.ATTACK and runner.is_running() and runner.elapsed_ms >= runner.current.active_start_ms():
		can_stagger = false
	_apply_knockback(hit, def.stagger_push_px if can_stagger else 0.0)
	if can_stagger:
		runner.cancel()
		state = State.STAGGER
		_timer = def.stagger_sec
	elif state == State.PATROL:
		state = State.CHASE


func _apply_knockback(hit: HitInfo, extra_px: float) -> void:
	var px := hit.knockback_px + extra_px
	if px <= 0.0:
		return
	var t := combatant.rules.knockback_time_sec
	_knock_v = signf(hit.knockback_dir.x) * px / t
	_knock_t = t


func _add_sc(points: float) -> void:
	if points <= 0.0 or combatant.statuses.has("stun") or combatant.statuses.is_resisting("stun"):
		return
	sc += points
	_sc_idle = 0.0
	if sc >= def.sc_max:
		sc = 0.0
		if combatant.statuses.apply("stun", -1.0, -1.0, _last_attacker):
			runner.cancel()
			state = State.STUNNED
			_knock_t = 0.0
			var bus := _bus()
			if bus:
				bus.enemy_stunned.emit(self, _last_attacker)


func _tick_sc(delta: float) -> void:
	if sc <= 0.0:
		return
	_sc_idle += delta
	if _sc_idle >= def.sc_decay_delay_sec:
		sc = maxf(sc - def.sc_decay_per_sec * delta, 0.0)


func _on_died() -> void:
	state = State.DEAD
	runner.cancel()
	_knock_t = 0.0
	hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	var bus := _bus()
	if bus:
		bus.enemy_defeated.emit(self, _last_attacker)
	died.emit(self)


## Autoload EventBus qua đường dẫn (tên autoload không có khi chạy script bằng --script).
func _bus() -> Node:
	return get_tree().root.get_node_or_null("EventBus") if is_inside_tree() else null


# ---------- AI ----------

func _target_alive() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var c := Combatant.of(target)
	return c == null or c.resources == null or not c.resources.is_dead()


func _dist_to_target() -> float:
	return global_position.distance_to(target.global_position) if _target_alive() else INF


func _sees_target() -> bool:
	return _target_alive() and _dist_to_target() <= def.detect_range


# ---------- Hiển thị tạm ----------

func _update_look() -> void:
	body.scale.x = facing
	if _flash > 0.0:
		body.modulate = Color(2, 2, 2)
	elif state == State.STUNNED:
		body.modulate = Color(0.6, 0.8, 1.6)
	elif is_telegraphing():
		body.modulate = Color(1.8, 0.9, 0.3)  # báo hiệu sắp đánh
	else:
		body.modulate = Color.WHITE


func _draw() -> void:
	if state == State.DEAD or combatant == null or combatant.resources == null:
		return
	var r := combatant.resources
	var w := 120.0
	var y := -150.0
	# UI_UX_SPEC: quái thường hiện thanh HP nhỏ khi bị đánh.
	if r.hp < r.max_hp:
		draw_rect(Rect2(-w / 2, y, w, 10), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w / 2, y, w * r.hp_ratio(), 10), Color(0.9, 0.2, 0.2))
	if sc > 0.0:
		draw_rect(Rect2(-w / 2, y + 12, w, 6), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w / 2, y + 12, w * clampf(sc / def.sc_max, 0.0, 1.0), 6), Color(1.0, 0.85, 0.2))
	if state == State.STUNNED:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-60, y - 10), tr("STATUS_STUN"), HORIZONTAL_ALIGNMENT_CENTER, 120, 26,
				Color(0.7, 0.85, 1.0))
