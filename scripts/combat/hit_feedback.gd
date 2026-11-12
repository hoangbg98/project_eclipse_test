class_name HitFeedback
extends Node
## Phản hồi đòn (README 15.7, M3-7): hit-stop, rung camera, số sát thương, đếm combo,
## dừng thời gian + cut-in khi tuyệt kỹ. Chỉ nghe EventBus; logic combat không phụ thuộc node này.
## Đặt một node trong mỗi màn chơi, gán `camera` và `player`.

const DEFAULT_CONFIG := preload("res://data/config/hit_feedback.tres")
## Node trong nhóm này có hàm freeze(giây) để dừng thời gian khi tuyệt kỹ.
const TIME_STOP_GROUP := &"time_stoppable"

@export var config: HitFeedbackConfig = DEFAULT_CONFIG

var camera: FollowCamera
var player: PlayerController
var combo := 0

var _combo_timer := 0.0
var _stopping := false
var _stop_until_usec := 0
var _saved_time_scale := 1.0
var _last_usec := 0
var _cutin_left := 0.0
var _cutin_total := 0.0

var _hud: CanvasLayer
var _combo_label: Label
var _cutin: Control
var _cutin_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_usec = Time.get_ticks_usec()
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus:
		bus.hit_landed.connect(_on_hit_landed)
		bus.dot_landed.connect(_on_dot_landed)
		bus.ultimate_started.connect(_on_ultimate_started)
		bus.reaction_triggered.connect(_on_reaction_triggered)
	_build_hud()


func _exit_tree() -> void:
	if _stopping:
		_end_hitstop()


func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_delta := (now - _last_usec) / 1_000_000.0
	_last_usec = now
	if _stopping and now >= _stop_until_usec:
		_end_hitstop()
	if camera:
		camera.update_shake(real_delta)
	if combo > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			reset_combo()
	_update_cutin(delta)


# ---------- Hit-stop ----------

## Thời lượng hit-stop cho một đòn (ms).
func hitstop_ms_for(hit: HitInfo, result: DamageCalculator.Result) -> float:
	var ms := config.hitstop_heavy_ms if is_heavy(hit) else config.hitstop_light_ms
	if result and result.is_crit:
		ms += config.hitstop_crit_bonus_ms
	return minf(ms, config.hitstop_max_ms)


func is_heavy(hit: HitInfo) -> bool:
	var sc_mult := hit.sc_ratio / hit.atk_ratio if hit.atk_ratio > 0.0 else 1.0
	return hit.atk_ratio >= config.heavy_atk_ratio or sc_mult >= config.heavy_sc_multiplier - 0.0001


## Dừng thời gian game `ms` mili-giây (thời gian thật). Nhiều đòn cùng lúc: lấy mức dài nhất, không cộng.
func hitstop(ms: float) -> void:
	if not config.hitstop_enabled or ms <= 0.0:
		return
	var until := Time.get_ticks_usec() + int(ms * 1000.0)
	if not _stopping:
		_saved_time_scale = Engine.time_scale
		Engine.time_scale = 0.0
		_stopping = true
		_stop_until_usec = until
	else:
		_stop_until_usec = maxi(_stop_until_usec, until)


func is_hitstopping() -> bool:
	return _stopping


func _end_hitstop() -> void:
	Engine.time_scale = _saved_time_scale if _saved_time_scale > 0.0 else 1.0
	_stopping = false


# ---------- Sự kiện ----------

func _on_hit_landed(attacker: Object, target: Object, result: Object, hit: Object) -> void:
	var tgt := target as Combatant
	var res := result as DamageCalculator.Result
	var h := hit as HitInfo
	if tgt == null or res == null or h == null:
		return
	var player_c := player.combatant if player else null
	var tnode := tgt.get_parent() as Node2D
	if tgt == player_c:
		_spawn_number(tnode, res.amount, FloatingNumber.Kind.PLAYER_HURT)
		hitstop(config.hitstop_player_hurt_ms)
		_shake(config.shake_player_hurt_px, config.shake_player_hurt_sec)
		reset_combo()
		return
	_spawn_number(tnode, res.amount, FloatingNumber.Kind.CRIT if res.is_crit else FloatingNumber.Kind.NORMAL)
	if attacker != null and attacker == player_c:
		add_combo()
		hitstop(hitstop_ms_for(h, res))
		if is_heavy(h):
			_shake(config.shake_heavy_px, config.shake_heavy_sec)
		else:
			_shake(config.shake_light_px, config.shake_light_sec)


func _on_dot_landed(target: Object, amount: int, _status_id: String) -> void:
	var tgt := target as Combatant
	if tgt:
		_spawn_number(tgt.get_parent() as Node2D, amount, FloatingNumber.Kind.DOT)


func _spawn_number(at: Node2D, amount: int, kind: FloatingNumber.Kind) -> void:
	if at == null or not at.is_inside_tree():
		return
	var parent := at.get_parent()
	var y := -150.0 if at is EnemyController else -260.0
	FloatingNumber.spawn(parent, at.global_position + Vector2(0, y), amount, kind)


func _shake(px: float, sec: float) -> void:
	if camera:
		camera.add_shake(px, sec)


# ---------- Combo ----------

func add_combo() -> void:
	combo += 1
	_combo_timer = config.combo_window_sec
	_combo_label.visible = combo >= config.combo_min_display
	_combo_label.text = tr("HUD_COMBO") % combo
	_combo_label.scale = Vector2.ONE * 1.25


func reset_combo() -> void:
	combo = 0
	_combo_label.visible = false


# ---------- Tuyệt kỹ: dừng thời gian + cut-in ----------

func _on_ultimate_started(actor: Node, skill: Resource) -> void:
	var s := skill as SkillDef
	var ms := s.time_stop_ms if s and s.time_stop_ms > 0.0 else config.cut_in_default_ms
	var sec := ms / 1000.0
	for n in get_tree().get_nodes_in_group(TIME_STOP_GROUP):
		if n != actor and n.has_method("freeze"):
			n.freeze(sec)
	_cutin_total = sec
	_cutin_left = sec
	_cutin_label.text = tr(s.name_key) if s and s.name_key != "" else ""
	_cutin.visible = true


func is_cut_in_showing() -> bool:
	return _cutin.visible


func _update_cutin(delta: float) -> void:
	if _combo_label.visible:
		_combo_label.scale = _combo_label.scale.lerp(Vector2.ONE, clampf(delta * 12.0, 0.0, 1.0))
	if not _cutin.visible:
		return
	_cutin_left -= delta
	var t := 1.0 - _cutin_left / maxf(_cutin_total, 0.0001)
	# Trượt vào từ phải trong 20% đầu, đứng yên, mờ ra ở 20% cuối.
	_cutin.position.x = lerpf(1920.0, 0.0, clampf(t / 0.2, 0.0, 1.0))
	_cutin.modulate.a = 1.0 - clampf((t - 0.8) / 0.2, 0.0, 1.0)
	if _cutin_left <= 0.0:
		_cutin.visible = false


# ---------- Phản ứng nguyên tố (mục 8.4) ----------

## Màu quả cầu theo nguyên tố (token vòng Liên kết, README 17.5).
const ELEMENT_COLOR := {
	"fire": Color("#FF6A3D"), "wind": Color("#3DDBB5"), "lightning": Color("#FFD93D"),
	"light": Color("#FFF2B8"), "dark": Color("#A855F7"), "earth": Color("#D99A3E"),
}
var last_reaction_id := ""


## Hit-stop 60 ms, hai quả cầu màu va vào nhau 300 ms, tên phản ứng hiện 0.8 s.
func _on_reaction_triggered(reaction: Resource, center: Vector2, by: Node) -> void:
	var def := reaction as ReactionDef
	if def == null:
		return
	last_reaction_id = def.id
	hitstop(config.reaction_hitstop_ms)
	_shake(config.shake_heavy_px, config.shake_heavy_sec)
	var parent := by.get_parent() if by and by.get_parent() else get_parent()
	if parent == null:
		return
	var fx := ReactionFx.new()
	fx.setup(tr(def.name_key), ELEMENT_COLOR.get(def.elements[0], Color.WHITE),
			ELEMENT_COLOR.get(def.elements[1], Color.WHITE), config.reaction_orb_sec, config.reaction_name_sec)
	parent.add_child(fx)
	fx.global_position = center + Vector2(0, -140)


# ---------- HUD tạm ----------

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 80
	add_child(_hud)
	_combo_label = Label.new()
	_combo_label.add_theme_font_size_override("font_size", 54)
	_combo_label.add_theme_color_override("font_color", Color("#FFD93D"))
	_combo_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_combo_label.add_theme_constant_override("outline_size", 10)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_combo_label.position = Vector2(1460, 300)
	_combo_label.size = Vector2(400, 80)
	_combo_label.pivot_offset = Vector2(400, 40)
	_combo_label.visible = false
	_hud.add_child(_combo_label)

	_cutin = Control.new()
	_cutin.size = Vector2(1920, 1080)
	_cutin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cutin.visible = false
	_hud.add_child(_cutin)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.size = Vector2(1920, 1080)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cutin.add_child(dim)
	var band := ColorRect.new()
	band.color = Color(1.0, 0.42, 0.24, 0.85)
	band.position = Vector2(0, 430)
	band.size = Vector2(1920, 220)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cutin.add_child(band)
	_cutin_label = Label.new()
	_cutin_label.add_theme_font_size_override("font_size", 88)
	_cutin_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_cutin_label.add_theme_constant_override("outline_size", 12)
	_cutin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cutin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cutin_label.position = Vector2(0, 430)
	_cutin_label.size = Vector2(1920, 220)
	_cutin.add_child(_cutin_label)
