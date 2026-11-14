class_name NeoBark
extends Control
## Băng thoại trong trận (owner 2026-11-14): một dòng chữ kèm chân dung người nói, không dừng trận.
## - Câu cốt truyện theo sự kiện màn (bắt đầu màn, đợt, điểm neo, boss, chuyển pha).
## - NEO gợi ý cách dùng chiêu khi điều kiện xảy ra lần đầu (EN đủ, vũ khí sẵn sàng, UG đầy, bị trúng đòn,
##   kẻ địch sắp Choáng, chân dung dự bị sáng, phản ứng nguyên tố...).
## Kịch bản ở data/tutorial/battle_barks.json; mỗi câu phát một lần mỗi save (`tutorial.seen`, id "bark:<id>").
## Nhân vật không có trong đội thì NEO nói thay (câu `neo_text`). Chỉ đọc state, không có luật gameplay.

const DATA_PATH := "res://data/tutorial/battle_barks.json"
const ACCENT := Color("#5CE1FF")
const PORTRAIT_SIZE := 84.0
const SKILL_ACTIONS: Array[String] = ["skill", "weapon", "ultimate"]

var stage: StageController
## Câu đang hiện: {speaker, name, text}; rỗng = không hiện.
var current: Dictionary = {}
## Câu chờ: [{at: giây, line}] (theo đồng hồ của băng thoại).
var pending: Array = []
## Dùng khi không có save (test): id đã phát.
var local_seen: Dictionary = {}
## Test (không có StageController): đội và id màn giả lập.
var test_party := PackedStringArray()
var test_stage_id := ""

var _data: Dictionary = {}
var _settings: Dictionary = {}
var _clock := 0.0
var _left := 0.0
var _poll := 0.0
var _started := false
var _checkpoints := 0
var _last_hp := {}
var _panel: PanelContainer
var _portrait_box: Control
var _core: AiCore
var _face: TextureRect
var _name: Label
var _text: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_data = load_data()
	_settings = _data.get("settings", {})
	_build()
	_panel.modulate.a = 0.0


static func load_data() -> Dictionary:
	if not FileAccess.file_exists(DATA_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return parsed if parsed is Dictionary else {}


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.name = "BarkPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.07, 0.13, 0.86)
	sb.border_color = Color(ACCENT, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", sb)
	# Góc trên-trái, dưới thẻ nhân vật đang chơi; không đè cụm icon dự bị (trên-phải) và nút (dưới).
	_panel.position = Vector2(24, 380)
	add_child(_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(row)
	_portrait_box = Control.new()
	_portrait_box.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	_portrait_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_portrait_box)
	_core = AiCore.new()
	_core.name = "AiCore"
	_core.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	_core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_box.add_child(_core)
	_face = TextureRect.new()
	_face.name = "Face"
	_face.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_box.add_child(_face)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	_name = Label.new()
	_name.name = "Speaker"
	_name.add_theme_font_size_override("font_size", 22)
	_name.add_theme_color_override("font_color", ACCENT)
	col.add_child(_name)
	_text = Label.new()
	_text.name = "Line"
	_text.add_theme_font_size_override("font_size", 26)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = 560
	col.add_child(_text)


## Gắn vào màn chơi: nghe các signal của StageController (StageHud gọi).
func bind(s: StageController) -> void:
	stage = s
	s.wave_started.connect(func(i: int) -> void: fire("wave_started", i))
	s.wave_cleared.connect(func(i: int) -> void: fire("wave_cleared", i))
	s.checkpoint_reached.connect(func(_p: Vector2) -> void:
		_checkpoints += 1
		fire("checkpoint", _checkpoints))
	s.boss_started.connect(func(b: BossController) -> void:
		fire("boss_started")
		b.phase_changed.connect(func(p: int) -> void: fire("boss_phase", p)))
	var bus := UiKit.autoload("EventBus")
	if bus:
		bus.reaction_triggered.connect(func(_r: Resource, _c: Vector2, _by: Node) -> void: fire("reaction"))


# ---------- Sự kiện → câu ----------

func _seen_store() -> Variant:
	var save := UiKit.autoload("SaveService")
	if stage and stage.use_save and save and save.data is Dictionary and not save.data.is_empty():
		return save.data
	return null


func was_seen(id: String) -> bool:
	var d: Variant = _seen_store()
	return TutorialFlow.has_seen(d, "bark:" + id) if d != null else local_seen.has(id)


func _mark(id: String) -> void:
	var d: Variant = _seen_store()
	if d != null:
		TutorialFlow.mark_seen(d, "bark:" + id)
	else:
		local_seen[id] = true


## Sự kiện `on` (tham số `arg` tùy loại): đưa các câu khớp, chưa phát, vào hàng chờ.
func fire(on: String, arg: Variant = null) -> void:
	var stage_id := stage.stage_id if stage else test_stage_id
	for l: Variant in _data.get("lines", []):
		if not (l is Dictionary) or str(l.get("on", "")) != on:
			continue
		if l.has("arg") and (arg == null or int(l["arg"]) != int(arg)):
			continue
		if l.has("action") and on == "skill_ready" and str(l["action"]) != str(arg):
			continue
		if str(l.get("stage", "")) != "" and str(l["stage"]) != stage_id:
			continue
		var id := str(l.get("id", ""))
		if id == "" or was_seen(id):
			continue
		_mark(id)
		if pending.size() >= int(_settings.get("queue_max", 4)):
			pending.pop_front()
		pending.append({"at": _clock + float(l.get("delay", 0.0)), "line": resolve(l)})


## Người nói và chữ thật của một câu: nhân vật không có trong đội thì NEO nói câu `neo_text` (hoặc `text`).
func resolve(l: Dictionary) -> Dictionary:
	var spk := str(l.get("speaker", "neo"))
	var key := str(l.get("text", ""))
	if spk != "neo" and not _in_party(spk):
		spk = "neo"
		key = str(l.get("neo_text", key))
	var text := tr(key)
	if text.contains("%s"):
		text = text % key_label(str(l.get("action", "attack")))
	var name_ := tr("TUTORIAL_AI_NAME")
	if spk != "neo":
		var p := PlayerProfile.CHARACTER_DATA % spk
		name_ = tr((load(p) as CharacterDef).name_key) if ResourceLoader.exists(p) else spk
	return {"speaker": spk, "name": name_, "text": text}


func _in_party(id: String) -> bool:
	return id in (stage.party_ids if stage else test_party)


## "phím U" trên máy tính; "nút Kĩ năng" trên thiết bị cảm ứng.
static func key_label(action: String) -> String:
	if OS.has_feature("mobile") and DisplayServer.is_touchscreen_available():
		return TranslationServer.translate("NEO_BTN_" + action.to_upper())
	if InputMap.has_action(action):
		for e in InputMap.action_get_events(action):
			if e is InputEventKey:
				var k := e as InputEventKey
				var code := k.keycode if k.keycode != KEY_NONE else k.physical_keycode
				return TranslationServer.translate("NEO_KEY_FMT") % OS.get_keycode_string(code)
	return TranslationServer.translate("NEO_BTN_" + action.to_upper())


# ---------- Theo dõi điều kiện gợi ý ----------

func _poll_state() -> void:
	if not _started or stage == null or not is_instance_valid(stage) or stage.party == null:
		return
	if stage.phase in [StageController.Phase.CLEARED, StageController.Phase.FAILED]:
		return
	var p := stage.party.active_controller()
	if p and is_instance_valid(p):
		for a in SKILL_ACTIONS:
			var st := TouchControls.button_state(StringName(a), p)
			if not bool(st["dimmed"]) and float(st["cooldown_ratio"]) <= 0.0 and p.runner.has_skill(a):
				fire("skill_ready", a)
	var active := stage.party.active()
	if active:
		var hp := active.resources().hp
		if _last_hp.has(active.id) and hp < float(_last_hp[active.id]) - 0.5:
			fire("hit_taken")
		_last_hp[active.id] = hp
		if stage.party.links:
			for r in stage.party.reserves():
				if stage.party.links.is_glowing(r):
					fire("link_glow")
	var ratio := float(_settings.get("sc_high_ratio", 0.7))
	var foes: Array = stage.enemies.duplicate()
	if stage.boss and is_instance_valid(stage.boss):
		foes.append(stage.boss)
	for e: Variant in foes:
		if e is EnemyController and is_instance_valid(e) and not (e as EnemyController).is_dead():
			var ec := e as EnemyController
			if ec.def and ec.def.sc_max > 0.0 and ec.sc / ec.def.sc_max >= ratio:
				fire("sc_high")
				break


# ---------- Hiển thị ----------

func _process(delta: float) -> void:
	_clock += delta
	if not _started and stage and _clock >= float(_settings.get("start_delay_sec", 1.0)):
		_started = true
		fire("stage_start")
	_poll -= delta
	if _poll <= 0.0:
		_poll = float(_settings.get("poll_sec", 0.25))
		_poll_state()
	if not current.is_empty():
		_left -= delta
		if _left <= 0.0:
			current = {}
			_left = -float(_settings.get("gap_sec", 0.35))
	elif _left < 0.0:
		_left = minf(_left + delta, 0.0)
	elif not pending.is_empty() and float(pending[0]["at"]) <= _clock:
		show_line(pending.pop_front()["line"])
	var target := 1.0 if not current.is_empty() and _left > 0.25 else 0.0
	_panel.modulate.a = move_toward(_panel.modulate.a, target, delta / 0.25)


func show_line(line: Dictionary) -> void:
	current = line
	_left = float(_settings.get("show_sec", 3.0)) + str(line["text"]).length() * float(_settings.get("per_char_sec", 0.04))
	_name.text = str(line["name"])
	_text.text = str(line["text"])
	var is_neo := str(line["speaker"]) == "neo"
	_core.visible = is_neo
	_face.visible = not is_neo
	if not is_neo:
		var id := str(line["speaker"])
		_face.texture = StoryClip.portrait_of(id)
	_panel.reset_size()
