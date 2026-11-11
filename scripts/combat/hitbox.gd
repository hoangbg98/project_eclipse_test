class_name Hitbox
extends Area2D
## Vùng gây đòn. Tắt mặc định; AnimationPlayer bật trong pha Hiệu lực (README 2.2, CHARACTER_SKILLS mục 0).
## Mỗi lần activate() là một hit_id mới, nên một Hurtbox trúng tối đa một lần mỗi lần bật.
## Đòn nhiều nhịp muốn chỉ trúng một lần: activate(true) giữ hit_id cũ.

signal hit_landed(hurtbox: Hurtbox, hit: HitInfo)

@export var team := PhysicsLayers.Team.PLAYER
@export var skill_id := ""
## % ATK của đòn (1.0 = 100%).
@export var atk_ratio := 1.0
## Hệ số sức choáng so với atk_ratio (mục 0: ×1 mặc định; ghi ×1.5, ×2 ở từng kỹ năng).
@export var sc_multiplier := 1.0
@export var knockback_px := 0.0

## Bộ đếm toàn cục để hit_id không trùng giữa các Hitbox.
static var _next_hit_id := 0

var active := false
var hit_id := 0
## Node gây đòn; mặc định là cha của Hitbox.
var attacker: Node


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = PhysicsLayers.hitbox_layer(team)
	collision_mask = PhysicsLayers.hitbox_mask(team)
	if attacker == null:
		attacker = get_parent()
	_set_shapes_enabled(false)


## Bật vùng gây đòn. keep_hit_id = true: nhịp sau của cùng một đòn không trúng lại.
func activate(keep_hit_id := false) -> void:
	if not keep_hit_id or hit_id == 0:
		_next_hit_id += 1
		hit_id = _next_hit_id
	active = true
	_set_shapes_enabled(true)


func deactivate() -> void:
	active = false
	_set_shapes_enabled(false)


func _physics_process(_delta: float) -> void:
	if not active:
		return
	for area in get_overlapping_areas():
		if area is Hurtbox:
			try_hit(area)


## Gửi đòn cho một Hurtbox. Trả về true nếu Hurtbox nhận (trúng thật).
func try_hit(hurtbox: Hurtbox) -> bool:
	if not active:
		return false
	var hit := make_hit_info()
	var accepted := hurtbox.receive(hit)
	if accepted:
		hit_landed.emit(hurtbox, hit)
	return accepted


func make_hit_info() -> HitInfo:
	var hit := HitInfo.new()
	hit.hit_id = hit_id
	hit.team = team
	hit.attacker = attacker
	hit.skill_id = skill_id
	hit.atk_ratio = atk_ratio
	hit.sc_ratio = atk_ratio * sc_multiplier
	hit.origin = global_position
	var facing := 1.0
	if attacker != null and "facing" in attacker:
		facing = float(attacker.facing)
	hit.knockback_dir = Vector2(signf(facing), 0.0)
	hit.knockback_px = knockback_px
	return hit


func _set_shapes_enabled(on: bool) -> void:
	for c in get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			c.set_deferred("disabled", not on)
