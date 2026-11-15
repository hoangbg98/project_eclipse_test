class_name DetachedHit
extends Node2D
## Vùng gây đòn tồn tại độc lập trong thế giới (sóng bay, vệt lửa, vết nổ chậm, đòn tại mục tiêu).
## Vẫn còn sau khi người đánh rời đi (mục 8.1: hiệu ứng đã tạo là node độc lập).

var hitbox: Hitbox
## Hình đạn (HitDef.projectile_sprite), null nếu không có.
var sprite: Sprite2D
var lifetime := 0.3
var velocity := Vector2.ZERO
## 0 = chỉ bật một lần; > 0 = bật lại (hit_id mới) mỗi khoảng này.
var tick_interval := 0.0
## Chờ bấy nhiêu giây rồi mới bật (vết chém nổ chậm).
var delay := 0.0
## Tốc độ xoay hình đạn (rad / giây), từ HitDef.projectile_spin_deg.
var spin := 0.0

var _age := 0.0
var _next_tick := 0.0
var _started := false


## Tạo từ HitDef. `facing` 1/-1; `pos` là điểm gốc (chân người đánh, hoặc chân mục tiêu nếu at_target).
static func spawn(parent: Node, def: HitDef, attacker: Node, team: PhysicsLayers.Team, facing: int,
		pos: Vector2, damage_bonus: Dictionary, hit_kind: int, skill_id: String, extra_en := 0.0,
		extra_delay_sec := 0.0) -> DetachedHit:
	var d := DetachedHit.new()
	d.name = "DetachedHit"
	d.lifetime = def.duration_ms / 1000.0
	d.tick_interval = def.tick_interval_ms / 1000.0
	d.delay = def.delay_ms / 1000.0 + extra_delay_sec
	if def.travel_px != 0.0 and d.lifetime > 0.0:
		var a := deg_to_rad(def.travel_angle_deg)
		d.velocity = Vector2(cos(a) * facing, sin(a)) * (def.travel_px / d.lifetime)
		d.rotation = a * facing
	d.scale.x = facing
	d.hitbox = SkillRunner.make_hitbox(def, team, skill_id, hit_kind)
	d.hitbox.attacker = attacker
	d.hitbox.damage_bonus = damage_bonus
	d.hitbox.extra_en = extra_en
	d.add_child(d.hitbox)
	d.sprite = _make_sprite(def)
	if d.sprite:
		d.hitbox.show_shape = false
		d.sprite.visible = d.delay <= 0.0
		d.spin = deg_to_rad(def.projectile_spin_deg)
		d.add_child(d.sprite)
	parent.add_child(d)
	d.global_position = pos + Vector2(def.offset.x * facing, def.offset.y)
	if d.delay <= 0.0:
		d._start()
	return d


## Hình đạn từ HitDef.projectile_sprite; thiếu file thì không vẽ (không crash).
static func _make_sprite(def: HitDef) -> Sprite2D:
	if def.projectile_sprite.is_empty() or not ResourceLoader.exists(def.projectile_sprite):
		return null
	var tex := load(def.projectile_sprite) as Texture2D
	if tex == null:
		return null
	var s := Sprite2D.new()
	s.name = "Projectile"
	s.texture = tex
	s.scale = Vector2.ONE * def.projectile_scale
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return s


func _start() -> void:
	_started = true
	if sprite:
		sprite.visible = true
	_age = 0.0
	_next_tick = tick_interval
	hitbox.activate()


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	if not _started:
		delay -= delta
		if delay <= 0.000001:
			_start()
		return
	_age += delta
	position += velocity * delta
	if sprite and spin != 0.0:
		sprite.rotation += spin * delta
	if tick_interval > 0.0 and _age >= _next_tick - 0.000001 and _age < lifetime:
		_next_tick += tick_interval
		hitbox.activate()
	if _age >= lifetime - 0.000001:
		hitbox.deactivate()
		queue_free()
