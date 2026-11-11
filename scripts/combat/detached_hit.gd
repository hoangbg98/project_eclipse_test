class_name DetachedHit
extends Node2D
## Vùng gây đòn tồn tại độc lập trong thế giới (sóng bay, vệt lửa, vết nổ chậm).
## Vẫn còn sau khi người đánh rời đi (mục 8.1: hiệu ứng đã tạo là node độc lập).

var hitbox: Hitbox
var lifetime := 0.3
var velocity := Vector2.ZERO
## 0 = chỉ bật một lần; > 0 = bật lại (hit_id mới) mỗi khoảng này.
var tick_interval := 0.0

var _age := 0.0
var _next_tick := 0.0


## Tạo từ HitDef. `facing` 1/-1; `pos` là chân người đánh lúc tạo.
static func spawn(parent: Node, def: HitDef, attacker: Node, team: PhysicsLayers.Team, facing: int,
		pos: Vector2, damage_bonus: Dictionary, hit_kind: int, skill_id: String) -> DetachedHit:
	var d := DetachedHit.new()
	d.name = "DetachedHit"
	d.lifetime = def.duration_ms / 1000.0
	d.tick_interval = def.tick_interval_ms / 1000.0
	if def.travel_px != 0.0 and d.lifetime > 0.0:
		d.velocity = Vector2(def.travel_px / d.lifetime * facing, 0.0)
	d.global_position = pos + Vector2(def.offset.x * facing, def.offset.y)
	d.scale.x = facing
	d.hitbox = SkillRunner.make_hitbox(def, team, skill_id, hit_kind)
	d.hitbox.position = Vector2.ZERO
	d.hitbox.attacker = attacker
	d.hitbox.damage_bonus = damage_bonus
	d.add_child(d.hitbox)
	parent.add_child(d)
	d.global_position = pos + Vector2(def.offset.x * facing, def.offset.y)
	d.hitbox.activate()
	d._next_tick = d.tick_interval
	return d


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	_age += delta
	position += velocity * delta
	if tick_interval > 0.0 and _age >= _next_tick - 0.000001 and _age < lifetime:
		_next_tick += tick_interval
		hitbox.activate()
	if _age >= lifetime - 0.000001:
		hitbox.deactivate()
		queue_free()
