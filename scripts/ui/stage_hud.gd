class_name StageHud
extends CanvasLayer
## HUD của màn chơi (README 15.5): dòng mục tiêu, đồng hồ, thông báo checkpoint, và thanh máu boss ở giữa-trên
## có vạch pha. Chỉ đọc state từ StageController.

const BAR_SIZE := Vector2(720.0, 26.0)
const BAR_TOP := 92.0

var stage: StageController

var _objective: Label
var _timer: Label
var _notice: Label
var _notice_left := 0.0
var _boss_bar: Control


func _ready() -> void:
	layer = 61
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_objective = _label(root, 30, Vector2(0, 176))
	_timer = _label(root, 24, Vector2(0, 14))
	_notice = _label(root, 40, Vector2(0, 260))
	_notice.modulate.a = 0.0
	_boss_bar = Control.new()
	_boss_bar.anchor_left = 0.5
	_boss_bar.anchor_right = 0.5
	_boss_bar.offset_left = -BAR_SIZE.x * 0.5
	_boss_bar.offset_right = BAR_SIZE.x * 0.5
	_boss_bar.offset_top = BAR_TOP
	_boss_bar.offset_bottom = BAR_TOP + 70.0
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar.draw.connect(_draw_boss_bar)
	root.add_child(_boss_bar)
	if stage == null:
		stage = get_parent() as StageController
	if stage:
		bind(stage)


func _label(root: Control, font_size: int, at: Vector2) -> Label:
	var l := Label.new()
	l.anchor_right = 1.0
	l.offset_top = at.y
	l.offset_bottom = at.y + font_size * 1.6
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l


func bind(s: StageController) -> void:
	stage = s
	s.checkpoint_reached.connect(func(_p: Vector2) -> void: notify(tr("STAGE_CHECKPOINT")))
	s.wave_cleared.connect(func(_i: int) -> void: notify(tr("STAGE_WAVE_CLEARED")))
	s.boss_started.connect(func(b: BossController) -> void:
		notify(tr(b.def.name_key))
		b.phase_changed.connect(func(p: int) -> void: notify(tr("STAGE_BOSS_PHASE") % p)))


## Thông báo ngắn giữa màn hình (2 s).
func notify(text: String) -> void:
	_notice.text = text
	_notice_left = 2.0


func objective_text() -> String:
	if stage == null or stage.map == null:
		return ""
	match stage.phase:
		StageController.Phase.WAVE:
			return tr("STAGE_OBJ_WAVE") % [stage.waves_cleared + 1, stage.wave_count(), stage.enemies_alive()]
		StageController.Phase.BOSS:
			return tr("STAGE_OBJ_BOSS")
		StageController.Phase.CLEARED, StageController.Phase.FAILED:
			return ""
	return tr("STAGE_OBJ_ADVANCE")


static func format_time(sec: float) -> String:
	var s := int(sec)
	return "%d:%02d" % [s / 60, s % 60]


func _process(delta: float) -> void:
	if stage == null or not is_instance_valid(stage):
		return
	_objective.text = objective_text()
	_timer.text = format_time(stage.elapsed_sec)
	_notice_left = maxf(_notice_left - delta, 0.0)
	_notice.modulate.a = clampf(_notice_left / 0.4, 0.0, 1.0)
	_boss_bar.visible = boss_bar_visible()
	_boss_bar.queue_redraw()


func boss_bar_visible() -> bool:
	return stage != null and stage.boss != null and is_instance_valid(stage.boss) and not stage.boss.is_dead()


func _draw_boss_bar() -> void:
	if not boss_bar_visible():
		return
	var b := stage.boss
	var font := ThemeDB.fallback_font
	_boss_bar.draw_string(font, Vector2(0, -6), tr(b.def.name_key), HORIZONTAL_ALIGNMENT_CENTER, BAR_SIZE.x, 26, Color.WHITE)
	var bar := Rect2(Vector2.ZERO, BAR_SIZE)
	_boss_bar.draw_rect(bar.grow(3.0), Color(0, 0, 0, 0.75))
	var ratio := b.combatant.resources.hp_ratio()
	_boss_bar.draw_rect(Rect2(Vector2.ZERO, Vector2(BAR_SIZE.x * ratio, BAR_SIZE.y)),
			Color(1.0, 0.55, 0.2) if b.is_transitioning() else HudTheme.COLOR_HP)
	# Vạch pha.
	for m in b.phase_markers():
		var x := BAR_SIZE.x * m
		_boss_bar.draw_line(Vector2(x, -4), Vector2(x, BAR_SIZE.y + 4), Color.WHITE, 3.0)
	# Thanh choáng (SC) mảnh bên dưới.
	if b.def.sc_max > 0.0:
		_boss_bar.draw_rect(Rect2(Vector2(0, BAR_SIZE.y + 6), Vector2(BAR_SIZE.x, 6)), Color(0, 0, 0, 0.6))
		_boss_bar.draw_rect(Rect2(Vector2(0, BAR_SIZE.y + 6), Vector2(BAR_SIZE.x * clampf(b.sc / b.def.sc_max, 0.0, 1.0), 6)),
				Color(1.0, 0.85, 0.2))
