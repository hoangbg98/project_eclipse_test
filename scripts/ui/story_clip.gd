class_name StoryClip
extends Control
## Clip dẫn truyện dạng truyện tranh (owner 2026-11-14): mỗi trang 1–4 ô hình đa giác (vuông, thang, tam giác...)
## hiện dần từng ô kèm thoại; hết trang thì xóa để sang trang mới; trang "card" là thẻ tiêu đề chương.
## Hộp thoại dưới màn: tên người nói, chữ hiện dần; nút Tự động / Lịch sử / Ẩn / Bỏ qua (hỏi xác nhận rồi hiện
## tóm tắt để người chơi vẫn biết mục tiêu). Chạm bất kỳ đâu / Enter / A: hiện hết câu rồi sang câu kế.
## Dữ liệu: data/story/<id>.json (sinh bằng tools/story/gen_story_clips.py). Ảnh ô: <image_dir>/<image>.png, không có thì
## placeholder, không có nữa thì vẽ ô xám có số. Xem xong ghi `tutorial.seen` "clip:<id>" rồi sang scene kế
## (GameConfig.story_clip_next). Không có luật gameplay.

signal finished(skipped: bool)

const DATA_DIR := "res://data/story/%s.json"
const DESIGN := Vector2(1920, 1080)
const ACCENT := Color("#5CE1FF")
const TYPE_SPEED := 45.0
const ENTER_SEC := 0.35
const PAGE_OUT_SEC := 0.3

enum State { PANEL_IN, LINE, WAIT, PAGE_OUT, CARD, CONFIRM, SUMMARY, DONE }

var clip_id := ""
var data: Dictionary = {}
var state := State.PANEL_IN
var page_index := 0
var panel_index := 0          # ô đang hiện trên trang (0-based)
var line_index := 0
var auto := false
var hidden_box := false
## Các câu đã đọc: [{name, text}] (bảng Lịch sử).
var history: Array = []
## false: không đổi scene khi xong (test).
var navigate_enabled := true

var _typed := 0.0
var _timer := 0.0
var _root: Control
var _page: Control
var _box: PanelContainer
var _portrait: Control
var _core: AiCore
var _face: TextureRect
var _name: Label
var _text: Label
var _tap: Label
var _buttons: Dictionary = {}
var _card: Control
var _overlay: Control
var _page_tween: Tween


static func clip_path(id: String) -> String:
	return DATA_DIR % id


static func load_clip(id: String) -> Dictionary:
	var p := clip_path(id)
	if id == "" or not FileAccess.file_exists(p):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	return parsed if parsed is Dictionary else {}


## Có nên phát clip `id` (có dữ liệu, chưa xem) theo save `save_data`.
static func should_play(id: String, save_data: Dictionary) -> bool:
	return id != "" and FileAccess.file_exists(clip_path(id)) and not TutorialFlow.has_seen(save_data, "clip:" + id)


func _ready() -> void:
	add_to_group(&"back_interceptor")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if clip_id == "":
		var gc := UiKit.autoload("GameConfig")
		clip_id = str(gc.story_clip_id) if gc else ""
	data = load_clip(clip_id)
	_build()
	resized.connect(_fit)
	_fit()
	start()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0B0D14")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_tap)
	add_child(bg)
	_root = Control.new()
	_root.name = "Root"
	_root.size = DESIGN
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_page = Control.new()
	_page.name = "Page"
	_page.size = DESIGN
	_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_page)
	_build_box()
	_card = Control.new()
	_card.name = "Card"
	_card.size = DESIGN
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.visible = false
	_root.add_child(_card)
	_overlay = Control.new()
	_overlay.name = "Overlay"
	_overlay.size = DESIGN
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_overlay)


func _box_style(bg: Color, border: Color, radius := 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(18)
	return sb


func _build_box() -> void:
	_box = PanelContainer.new()
	_box.name = "DialogBox"
	_box.position = Vector2(40, 828)
	_box.custom_minimum_size = Vector2(1840, 224)
	_box.size = Vector2(1840, 224)
	_box.add_theme_stylebox_override("panel", _box_style(Color(0.04, 0.06, 0.1, 0.94), Color(1, 1, 1, 0.25)))
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(row)
	_portrait = Control.new()
	_portrait.custom_minimum_size = Vector2(150, 150)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_portrait)
	_core = AiCore.new()
	_core.name = "AiCore"
	_core.size = Vector2(150, 150)
	_core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.add_child(_core)
	_face = TextureRect.new()
	_face.name = "Face"
	_face.size = Vector2(150, 150)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.add_child(_face)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	_name = Label.new()
	_name.name = "Speaker"
	_name.add_theme_font_size_override("font_size", 30)
	_name.add_theme_color_override("font_color", ACCENT)
	col.add_child(_name)
	_text = Label.new()
	_text.name = "Line"
	_text.add_theme_font_size_override("font_size", 34)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(1280, 110)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_text)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 8)
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(side)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	side.add_child(grid)
	for k in ["auto", "history", "hide", "skip"]:
		var b := Button.new()
		b.name = "Btn_" + k
		b.focus_mode = Control.FOCUS_NONE
		b.toggle_mode = k == "auto"
		b.custom_minimum_size = Vector2(150, 64)
		b.add_theme_font_size_override("font_size", 24)
		b.text = tr("STORY_UI_" + k.to_upper())
		grid.add_child(b)
		_buttons[k] = b
	_buttons["auto"].toggled.connect(func(on: bool) -> void: auto = on)
	_buttons["history"].pressed.connect(open_history)
	_buttons["hide"].pressed.connect(func() -> void: set_hidden(true))
	_buttons["skip"].pressed.connect(ask_skip)
	_tap = Label.new()
	_tap.name = "TapNext"
	_tap.text = tr("STORY_UI_TAP") + "  ▼"
	_tap.add_theme_font_size_override("font_size", 22)
	_tap.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	side.add_child(_tap)


## Khung thiết kế 1920x1080 co vừa màn, giữ tỉ lệ, căn giữa.
func _fit() -> void:
	var view := size if size.x > 0.0 else DESIGN
	var s := minf(view.x / DESIGN.x, view.y / DESIGN.y)
	_root.scale = Vector2(s, s)
	_root.position = (view - DESIGN * s) * 0.5


# ---------- Luồng ----------

func pages() -> Array:
	return data.get("pages", [])


func current_page() -> Dictionary:
	return pages()[page_index] if page_index < pages().size() else {}


func current_panel() -> Dictionary:
	var ps: Array = current_page().get("panels", [])
	return ps[panel_index] if panel_index < ps.size() else {}


func current_lines() -> Array:
	return current_panel().get("lines", [])


func start() -> void:
	page_index = 0
	if pages().is_empty():
		finish(false)
		return
	_open_page()


func _open_page() -> void:
	for c in _page.get_children():
		c.queue_free()
	panel_index = 0
	line_index = 0
	var pg := current_page()
	if pg.is_empty():
		finish(false)
		return
	if pg.has("card"):
		_show_card(pg["card"])
		return
	_card.visible = false
	_box.visible = not hidden_box
	_show_panel()


func _show_panel() -> void:
	var p := current_panel()
	var view := PanelView.new()
	view.name = "Panel_%d" % panel_index
	view.setup(p, data, panel_index + 1)
	_page.add_child(view)
	var dir := {"left": Vector2(-60, 0), "right": Vector2(60, 0), "up": Vector2(0, -60), "down": Vector2(0, 60)}
	var off: Vector2 = dir.get(str(p.get("enter", "left")), Vector2.ZERO)
	view.modulate.a = 0.0
	view.position = off
	var tw := create_tween().set_parallel(true)
	tw.tween_property(view, "modulate:a", 1.0, ENTER_SEC)
	tw.tween_property(view, "position", Vector2.ZERO, ENTER_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	state = State.PANEL_IN
	_timer = ENTER_SEC
	line_index = 0
	_set_line()


func _set_line() -> void:
	var lines := current_lines()
	if line_index >= lines.size():
		_name.text = ""
		_text.text = ""
		_core.visible = false
		_face.visible = false
		return
	var l: Dictionary = lines[line_index]
	var spk := str(l.get("speaker", "narration"))
	_name.text = speaker_name(spk)
	_text.text = tr(str(l.get("text", "")))
	_text.add_theme_color_override("font_color", Color(0.85, 0.87, 0.95) if spk == "narration" else Color.WHITE)
	_core.visible = spk == "neo"
	_face.visible = spk.begins_with("char_")
	if _face.visible:
		_face.texture = portrait_of(spk)
	_typed = 0.0
	history.append({"name": _name.text, "text": _text.text})


## Chân dung nhân vật cho hộp thoại: ảnh chân dung, chưa có thì frame idle đầu tiên, không có nữa thì null.
static func portrait_of(id: String) -> Texture2D:
	for path: String in [ReserveIcon.PORTRAIT_PATH % [id, id],
			"res://assets/characters/%s/frames/idle/%s_idle_000.png" % [id, id]]:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


static func speaker_name(spk: String) -> String:
	match spk:
		"neo":
			return TranslationServer.translate("TUTORIAL_AI_NAME")
		"narration":
			return ""
		"unknown":
			return "???"
	var p := PlayerProfile.CHARACTER_DATA % spk
	return TranslationServer.translate((load(p) as CharacterDef).name_key) if ResourceLoader.exists(p) else spk


func line_done() -> bool:
	return _typed >= _text.text.length()


## Chạm / Enter: hiện hết câu đang gõ, rồi sang câu / ô / trang kế.
func advance() -> void:
	match state:
		State.PANEL_IN:
			_finish_enter()
		State.LINE:
			if not line_done():
				_typed = 1e6
				return
			_next_line()
		State.WAIT:
			_next_line()
		State.CARD:
			finish(false)


func _finish_enter() -> void:
	for v in _page.get_children():
		v.modulate.a = 1.0
		v.position = Vector2.ZERO
	state = State.LINE if not current_lines().is_empty() else State.WAIT
	_timer = 0.0


func _next_line() -> void:
	line_index += 1
	if line_index < current_lines().size():
		state = State.LINE
		_set_line()
		return
	var ps: Array = current_page().get("panels", [])
	if panel_index + 1 < ps.size():
		panel_index += 1
		_show_panel()
		return
	state = State.PAGE_OUT
	_timer = PAGE_OUT_SEC
	_page_tween = create_tween()
	_page_tween.tween_property(_page, "modulate:a", 0.0, PAGE_OUT_SEC)


func _show_card(card: Dictionary) -> void:
	state = State.CARD
	_box.visible = false
	_card.visible = true
	for c in _card.get_children():
		c.queue_free()
	var t := Label.new()
	t.name = "CardTitle"
	t.text = tr(str(card.get("title", "")))
	t.add_theme_font_size_override("font_size", 72)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(0, 420)
	t.size = Vector2(DESIGN.x, 100)
	_card.add_child(t)
	var s := Label.new()
	s.name = "CardSub"
	s.text = tr(str(card.get("sub", "")))
	s.add_theme_font_size_override("font_size", 34)
	s.add_theme_color_override("font_color", ACCENT)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.position = Vector2(200, 540)
	s.size = Vector2(DESIGN.x - 400, 120)
	_card.add_child(s)
	_card.modulate.a = 0.0
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.6)
	_timer = 3.0


func _process(delta: float) -> void:
	_typed += delta * TYPE_SPEED
	if state == State.LINE and _text.visible_characters != -1 or state == State.LINE:
		_text.visible_characters = -1 if line_done() else int(_typed)
	_tap.visible = state in [State.LINE, State.WAIT, State.CARD] and (state != State.LINE or line_done())
	match state:
		State.PANEL_IN:
			_timer -= delta
			if _timer <= 0.0:
				_finish_enter()
		State.LINE:
			if auto and line_done():
				_timer += delta
				if _timer >= 1.4 + _text.text.length() * 0.03:
					_timer = 0.0
					_next_line()
			else:
				_timer = 0.0
		State.WAIT:
			_timer += delta
			if auto and _timer >= 1.2:
				_next_line()
		State.PAGE_OUT:
			_timer -= delta
			if _timer <= 0.0:
				if _page_tween:
					_page_tween.kill()
				_page.modulate.a = 1.0
				page_index += 1
				_open_page()
		State.CARD:
			_timer -= delta
			if auto and _timer <= 0.0:
				finish(false)


# ---------- Nút ----------

func set_hidden(on: bool) -> void:
	hidden_box = on
	_box.visible = not on and state != State.CARD


func open_history() -> void:
	_clear_overlay()
	_overlay.visible = true
	_dim()
	var panel := PanelContainer.new()
	panel.name = "History"
	panel.position = Vector2(260, 90)
	panel.size = Vector2(1400, 900)
	panel.add_theme_stylebox_override("panel", _box_style(Color(0.05, 0.07, 0.12, 0.98), ACCENT))
	_overlay.add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)
	var title := Label.new()
	title.text = tr("STORY_UI_HISTORY_TITLE")
	title.add_theme_font_size_override("font_size", 36)
	col.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1360, 700)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var body := Label.new()
	body.name = "HistoryText"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 1320
	body.add_theme_font_size_override("font_size", 28)
	var parts := PackedStringArray()
	for h: Dictionary in history:
		parts.append(("%s: %s" % [h["name"], h["text"]]) if str(h["name"]) != "" else str(h["text"]))
	body.text = "\n\n".join(parts)
	scroll.add_child(body)
	_overlay_button(col, "STORY_UI_CLOSE", "HistoryClose", close_overlay)


func ask_skip() -> void:
	if state in [State.SUMMARY, State.DONE]:
		return
	_clear_overlay()
	_overlay.visible = true
	_dim()
	var panel := _center_panel("SkipConfirm", tr("STORY_UI_SKIP_CONFIRM"))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	panel.get_child(0).add_child(row)
	_overlay_button(row, "STORY_UI_YES", "SkipYes", show_summary)
	_overlay_button(row, "STORY_UI_NO", "SkipNo", close_overlay)


## Bỏ qua: tóm tắt 2 dòng rồi Tiếp tục.
func show_summary() -> void:
	state = State.SUMMARY
	_clear_overlay()
	_overlay.visible = true
	_dim()
	var panel := _center_panel("Summary", tr(str(data.get("summary", ""))))
	_overlay_button(panel.get_child(0), "STORY_UI_CONTINUE", "SummaryContinue", func() -> void: finish(true))


func close_overlay() -> void:
	_clear_overlay()
	_overlay.visible = false


func _clear_overlay() -> void:
	for c in _overlay.get_children():
		_overlay.remove_child(c)
		c.queue_free()


func _dim() -> void:
	var d := ColorRect.new()
	d.color = Color(0, 0, 0, 0.7)
	d.size = DESIGN
	_overlay.add_child(d)


func _center_panel(name_: String, text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = name_
	panel.position = Vector2(460, 360)
	panel.custom_minimum_size = Vector2(1000, 0)
	panel.add_theme_stylebox_override("panel", _box_style(Color(0.05, 0.07, 0.12, 0.98), ACCENT))
	_overlay.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	panel.add_child(col)
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 960
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 32)
	col.add_child(l)
	return panel


func _overlay_button(parent: Control, key: String, name_: String, cb: Callable) -> Button:
	var b := Button.new()
	b.name = name_
	b.text = tr(key)
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(240, 72)
	b.add_theme_font_size_override("font_size", 28)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


# ---------- Input ----------

func _on_tap(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed):
		if hidden_box:
			set_hidden(false)
		else:
			advance()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not _overlay.visible:
		get_viewport().set_input_as_handled()
		if hidden_box:
			set_hidden(false)
		else:
			advance()


## Esc / Back: đóng bảng đang mở, không thì hỏi Bỏ qua (không quay lại scene trước giữa chừng).
func intercept_back() -> bool:
	if state == State.SUMMARY:
		return true
	if _overlay.visible:
		close_overlay()
	elif hidden_box:
		set_hidden(false)
	else:
		ask_skip()
	return true


# ---------- Xong ----------

func finish(skipped: bool) -> void:
	if state == State.DONE:
		return
	state = State.DONE
	var save := UiKit.autoload("SaveService")
	if save and save.data is Dictionary and not save.data.is_empty() and clip_id != "":
		TutorialFlow.mark_seen(save.data, "clip:" + clip_id)
		save.save_game()
	finished.emit(skipped)
	if not navigate_enabled:
		return
	var gc := UiKit.autoload("GameConfig")
	var router := UiKit.autoload("SceneRouter")
	var next := str(gc.story_clip_next) if gc else ""
	if router and next != "":
		router.swap(next)


## Một ô truyện: ảnh cắt theo đa giác (UV theo khung bao), viền kiểu truyện tranh; thiếu ảnh thì vẽ ô xám có số.
class PanelView extends Control:
	var poly := PackedVector2Array()
	var tex: Texture2D
	var number := 0
	var image_name := ""
	## Diễn biến cảnh (tiếng Việt, dành cho người làm art): hiện trên ô khi chưa có ảnh.
	var desc := ""

	func setup(p: Dictionary, clip: Dictionary, n: int) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(1920, 1080)
		number = n
		image_name = str(p.get("image", ""))
		desc = str(p.get("desc", ""))
		for q: Variant in p.get("poly", []):
			poly.append(Vector2(float(q[0]), float(q[1])))
		for path: String in [str(clip.get("image_dir", "")).path_join(image_name + ".png"),
				str(clip.get("placeholder_dir", "")).path_join("placeholder_" + image_name + ".png")]:
			if ResourceLoader.exists(path):
				tex = load(path) as Texture2D
				break

	func bounds() -> Rect2:
		var r := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			r = r.expand(q)
		return r

	func _draw() -> void:
		if poly.size() < 3:
			return
		var b := bounds()
		if tex:
			var uvs := PackedVector2Array()
			for q in poly:
				uvs.append((q - b.position) / b.size)
			draw_colored_polygon(poly, Color.WHITE, uvs, tex)
		else:
			draw_colored_polygon(poly, Color(0.36, 0.39, 0.46))
			var f := ThemeDB.fallback_font
			var c := b.get_center()
			var tw := b.size.x * 0.55
			draw_string(f, Vector2(c.x - 60, c.y - 40), "%02d" % number, HORIZONTAL_ALIGNMENT_CENTER, 120, 64, Color.WHITE)
			draw_multiline_string(f, Vector2(c.x - tw * 0.5, c.y + 10), desc, HORIZONTAL_ALIGNMENT_CENTER, tw, 26, 5,
					Color(0.94, 0.95, 0.98))
		var closed := poly.duplicate()
		closed.append(poly[0])
		draw_polyline(closed, Color.BLACK, 12.0, true)
		draw_polyline(closed, Color.WHITE, 5.0, true)
