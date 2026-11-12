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
@export var hit_kind := 0
@export var skill_level := 1
@export var statuses: Array[StatusApplication] = []
## % tăng sát thương riêng của lần bật hiện tại; SkillRunner đặt trước khi bật.
var damage_bonus: Dictionary = {}
## EN cộng thêm cho người đánh khi trúng (ngoài mức theo loại đòn).
var extra_en := 0.0
## Thêm sát thương nếu mục tiêu đang mang trạng thái này (HitDef.bonus_vs_status).
var bonus_vs_status := ""
var bonus_vs_status_ratio := 0.0
## Kéo mục tiêu về tâm vùng đòn thay vì đẩy theo hướng người đánh.
var pull_to_origin := false
## Hệ số thời gian cho trạng thái khống chế / Chậm khi mục tiêu là boss (phản ứng nguyên tố: 0.5).
var boss_control_multiplier := 1.0

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
	hit.hit_kind = hit_kind
	hit.skill_level = skill_level
	hit.statuses = statuses
	hit.damage_bonus = damage_bonus.duplicate()
	hit.extra_en = extra_en
	hit.bonus_vs_status = bonus_vs_status
	hit.bonus_vs_status_ratio = bonus_vs_status_ratio
	hit.pull_to_origin = pull_to_origin
	hit.boss_control_multiplier = boss_control_multiplier
	return hit


func _set_shapes_enabled(on: bool) -> void:
	for c in get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			c.set_deferred("disabled", not on)
	queue_redraw()


## Hiện vùng gây đòn khi bật: tạm thay VFX cho tới khi owner giao hiệu ứng thật.
@export var show_shape := true


func _draw() -> void:
	if not show_shape or not active:
		return
	var col := Color(1.0, 0.45, 0.15, 0.35) if team == PhysicsLayers.Team.PLAYER else Color(0.9, 0.2, 0.3, 0.35)
	for c in get_children():
		if c is CollisionPolygon2D and c.polygon.size() >= 3:
			var pts := PackedVector2Array()
			for p in c.polygon:
				pts.append(p + c.position)
			draw_colored_polygon(pts, col)
