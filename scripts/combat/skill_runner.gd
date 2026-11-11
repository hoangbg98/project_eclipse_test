class_name SkillRunner
extends Node2D
## Chạy kỹ năng theo SkillDef: tiêu EN, hồi chiêu, pha khởi động/hiệu lực/hồi phục,
## bật Hitbox theo track AnimationPlayer (HitboxTrack), di chuyển, bất tử, nối đòn.
## Đặt làm con của nhân vật (tên "Skills"). Chạy thủ công bằng advance(delta) từ controller
## để đồng bộ với vật lý và test được.

signal skill_started(key: String, skill: SkillDef)
signal skill_finished(key: String, skill: SkillDef)
## Bị từ chối (thiếu EN, đang hồi, bị khống chế...). reason để hiện HUD.
signal skill_rejected(key: String, reason: String)

## Chuỗi đòn thường reset nếu không bấm tiếp trong khoảng này sau khi đòn kết thúc (s).
const COMBO_RESET_SEC := 0.8
const NORMAL_FIRST := "normal_1"

var actor: Node2D
var combatant: Combatant
var hurtbox: Hurtbox
var skills: Dictionary = {}  # key -> SkillDef
## Hàm trả % tăng sát thương riêng cho một kỹ năng sắp chạy (nội tại, buff). (SkillDef) -> Dictionary
var bonus_provider: Callable

var current: SkillDef
var current_key := ""
var elapsed_ms := 0.0
var facing := 1

var _player: AnimationPlayer
var _attached: Node2D
var _hitboxes: Dictionary = {}  # key -> Array[Hitbox]
var _queued_key := ""
var _combo_next := ""
var _combo_timer := 0.0


func setup(p_actor: Node2D, p_combatant: Combatant, p_skills: Dictionary, p_hurtbox: Hurtbox = null) -> void:
	actor = p_actor
	combatant = p_combatant
	hurtbox = p_hurtbox
	skills = p_skills
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_attached = Node2D.new()
	_attached.name = "Attached"
	add_child(_attached)
	_player = AnimationPlayer.new()
	_player.name = "Timeline"
	add_child(_player)
	_player.root_node = ^".."
	_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_player.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	var lib := AnimationLibrary.new()
	for key: String in skills:
		var s: SkillDef = skills[key]
		for e in s.validate():
			push_warning("SkillRunner: %s" % e)
		var cd := StringName(s.cooldown_key())
		if combatant and s.cooldown_sec > 0.0 and not combatant.cooldowns.has(cd):
			combatant.cooldowns.register(cd, s.cooldown_sec, s.cooldown_uses_cdr)
		lib.add_animation(StringName(key), _build_animation(key, s))
	_player.add_animation_library(&"", lib)


func _build_animation(key: String, s: SkillDef) -> Animation:
	var anim := Animation.new()
	anim.length = maxf(s.total_ms(), 1.0) / 1000.0
	var list: Array[Hitbox] = []
	var detached_track := -1
	for i in s.hits.size():
		var h: HitDef = s.hits[i]
		if h.detached:
			if detached_track < 0:
				detached_track = anim.add_track(Animation.TYPE_METHOD)
				anim.track_set_path(detached_track, ^".")
			anim.track_insert_key(detached_track, h.at_ms / 1000.0, {"method": &"_spawn_detached", "args": [key, i]})
			continue
		var hb := make_hitbox(h, combatant.team if combatant else PhysicsLayers.Team.PLAYER, s.id, s.hit_kind)
		hb.name = "%s_%d" % [key, i]
		hb.attacker = actor
		hb.extra_en = s.extra_en_on_hit
		_attached.add_child(hb)
		list.append(hb)
		HitboxTrack.add(anim, NodePath("Attached/%s" % hb.name),
				[HitboxTrack.HitWindow.new(h.at_ms / 1000.0, minf(h.end_ms(), s.total_ms()) / 1000.0)])
	_hitboxes[key] = list
	return anim


## Tạo Hitbox từ HitDef (dùng cả cho vùng tách).
static func make_hitbox(h: HitDef, team: PhysicsLayers.Team, skill_id: String, hit_kind: int) -> Hitbox:
	var hb := Hitbox.new()
	hb.team = team
	hb.skill_id = skill_id
	hb.atk_ratio = h.atk_ratio
	hb.sc_multiplier = h.sc_multiplier
	hb.knockback_px = h.knockback_px
	hb.hit_kind = hit_kind
	hb.statuses = h.statuses
	var poly := CollisionPolygon2D.new()
	poly.polygon = h.build_polygon()
	if not h.detached:
		poly.position = h.offset
	hb.add_child(poly)
	return hb


# ---------- Điều khiển ----------

func has_skill(key: String) -> bool:
	return skills.has(key)


func is_running() -> bool:
	return current != null


## Kiểm tra có dùng được không (không đổi trạng thái). Trả về "" nếu được, hoặc lý do.
func check(key: String) -> String:
	if not skills.has(key):
		return "missing"
	var s: SkillDef = skills[key]
	if combatant:
		if combatant.resources.is_dead():
			return "dead"
		if combatant.statuses.blocks_actions():
			return "control"
		if s.cooldown_sec > 0.0 and not combatant.cooldowns.is_ready(StringName(s.cooldown_key())):
			return "cooldown"
		if s.en_cost > 0.0 and not combatant.resources.can_spend_en(s.en_cost):
			return "energy"
		if s.ug_cost > 0.0 and not combatant.resources.is_ultimate_ready():
			return "ultimate"
	return ""


## Vị trí chân của mục tiêu đã chọn khi bắt đầu kỹ năng hiện tại (nếu kỹ năng nhắm mục tiêu).
var target_position := Vector2.ZERO
var has_target := false


## Kẻ địch còn sống gần nhất trong bán kính (đo từ chân), hoặc null.
func find_nearest_enemy(radius: float) -> Node2D:
	if actor == null or not actor.is_inside_tree():
		return null
	var own_team: int = combatant.team if combatant else PhysicsLayers.Team.PLAYER
	var best: Node2D = null
	var best_d := radius
	for n in actor.get_tree().get_nodes_in_group(Combatant.GROUP):
		var c := Combatant.of(n)
		if c == null or c.team == own_team or c.resources == null or c.resources.is_dead():
			continue
		var d := (n as Node2D).global_position.distance_to(actor.global_position)
		if d <= best_d:
			best_d = d
			best = n
	return best


## Bắt đầu kỹ năng (ngắt kỹ năng đang chạy). Trả về false nếu bị từ chối.
func run(key: String, p_facing: int = 0) -> bool:
	var reason := check(key)
	if reason != "":
		skill_rejected.emit(key, reason)
		return false
	var s: SkillDef = skills[key]
	if combatant:
		if s.en_cost > 0.0:
			combatant.resources.spend_en(s.en_cost)
		if s.cooldown_sec > 0.0 and not s.cooldown_starts_on_end:
			combatant.cooldowns.trigger(StringName(s.cooldown_key()))
		if s.ug_cost > 0.0:
			combatant.resources.use_ultimate()
	_stop_current()
	has_target = false
	if s.target_range_px > 0.0:
		var t := find_nearest_enemy(s.target_range_px)
		if t:
			has_target = true
			target_position = t.global_position
	current = s
	current_key = key
	elapsed_ms = 0.0
	_queued_key = ""
	if p_facing != 0:
		facing = p_facing
	elif actor and "facing" in actor:
		facing = int(actor.facing)
	_attached.scale.x = facing
	var bonus: Dictionary = bonus_provider.call(s) if bonus_provider.is_valid() else {}
	for hb: Hitbox in _hitboxes.get(key, []):
		hb.damage_bonus = bonus
	_current_bonus = bonus
	if s.key == "normal":
		_combo_next = s.next_skill
		_combo_timer = 0.0
	_player.play(StringName(key))
	_player.advance(0.0)
	_update_invuln()
	skill_started.emit(key, s)
	return true


var _current_bonus: Dictionary = {}


## Gọi mỗi tick vật lý.
func advance(delta: float) -> void:
	if current == null:
		if _combo_timer > 0.0:
			_combo_timer -= delta
			if _combo_timer <= 0.0:
				_combo_next = ""
		return
	elapsed_ms += delta * 1000.0
	_player.advance(delta)
	_update_invuln()
	if elapsed_ms >= current.total_ms() - 0.001:
		var done := current
		var done_key := current_key
		var queued := _queued_key  # đọc trước: _stop_current() xoá hàng đợi
		_stop_current()
		if done.key == "normal":
			_combo_timer = COMBO_RESET_SEC if _combo_next != "" else 0.0
		skill_finished.emit(done_key, done)
		if queued != "":
			run(queued)


## Huỷ kỹ năng đang chạy (vd né huỷ nửa sau hồi phục, bị khống chế).
func cancel() -> void:
	if current == null:
		return
	var done := current
	var done_key := current_key
	_stop_current()
	skill_finished.emit(done_key, done)


func _stop_current() -> void:
	if current == null:
		return
	if combatant and current.cooldown_sec > 0.0 and current.cooldown_starts_on_end:
		combatant.cooldowns.trigger(StringName(current.cooldown_key()))
	for hb: Hitbox in _hitboxes.get(current_key, []):
		hb.deactivate()
	_player.stop()
	current = null
	current_key = ""
	_queued_key = ""
	if hurtbox:
		hurtbox.invulnerable = false


func _update_invuln() -> void:
	if hurtbox and current:
		hurtbox.invulnerable = current.is_invulnerable_at(elapsed_ms)


# ---------- Đòn thường ----------

## Đòn thường kế tiếp trong chuỗi (hoặc đòn 1 nếu chuỗi đã reset).
func next_normal_key() -> String:
	return _combo_next if _combo_next != "" and skills.has(_combo_next) else NORMAL_FIRST


## Đang trong cửa sổ nhận nút nối đòn của đòn thường hiện tại.
func can_queue_chain() -> bool:
	return current != null and current.next_skill != "" and skills.has(current.next_skill) \
			and elapsed_ms >= current.chain_from_ms()


## Ghi nhận nút nối đòn: đòn kế tiếp chạy ngay khi đòn hiện tại kết thúc.
func queue_chain() -> bool:
	if not can_queue_chain():
		return false
	_queued_key = current.next_skill
	return true


func has_queued() -> bool:
	return _queued_key != ""


func can_dodge_cancel() -> bool:
	return current != null and elapsed_ms >= current.dodge_cancel_from_ms()


# ---------- Di chuyển ----------

## Vận tốc ngang mong muốn khi đang chạy kỹ năng (px/s).
func velocity_x() -> float:
	if current == null or current.move_px == 0.0:
		return 0.0
	var span := current.move_to_ms - current.move_from_ms
	if span <= 0.0 or elapsed_ms < current.move_from_ms or elapsed_ms >= current.move_to_ms:
		return 0.0
	return current.move_px / (span / 1000.0) * facing


func suspends_gravity() -> bool:
	return current != null and current.gravity_off_at(elapsed_ms)


func keeps_momentum() -> bool:
	return current != null and current.keep_momentum


func has_super_armor() -> bool:
	return current != null and current.super_armor


func _spawn_detached(key: String, index: int) -> void:
	var s: SkillDef = skills.get(key)
	if s == null or actor == null or actor.get_parent() == null:
		return
	var h: HitDef = s.hits[index]
	var origin := actor.global_position
	if h.at_target:
		# Không có mục tiêu: đặt trước mặt (200 px).
		origin = target_position if has_target else actor.global_position + Vector2(200.0 * facing, 0.0)
	DetachedHit.spawn(actor.get_parent(), h, actor,
			combatant.team if combatant else PhysicsLayers.Team.PLAYER, facing,
			origin, _current_bonus, s.hit_kind, s.id, s.extra_en_on_hit)
