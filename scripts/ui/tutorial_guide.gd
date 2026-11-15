extends CanvasLayer
## Lớp hướng dẫn người mới (autoload `TutorialGuide`, owner 2026-11-14): trợ lý AI NEO trò chuyện với Quản lý (người
## chơi) từng bước. Hai chế độ:
## - **Trò chuyện**: tối toàn màn, khung hội thoại (lõi AI phát sáng, tên NEO, chữ hiện dần, nút đáp của Quản lý).
##   Chạm bất kỳ đâu / Enter / A: hiện hết câu, rồi sang câu kế. "Bỏ qua thoại" nhảy tới câu chỉ dẫn.
## - **Chỉ dẫn** (câu cuối của bước): chừa ô sáng quanh nút cần bấm, khung nhấp nháy, mũi tên; chặn chuột / chạm ngoài
##   ô, chặn phím (Enter / A bấm đúng nút), chặn Back.
## Luật bước và kịch bản ở TutorialFlow + data/tutorial/tutorial_dialogue.json. Không có luật gameplay.
## Không tìm thấy nút của bước (đổi bố cục, đang chuyển scene) thì không khóa gì.

const PAD := 10.0
const DIM := Color(0.02, 0.04, 0.08, 0.72)
const ACCENT := Color("#5CE1FF")          # màu giao diện AI
const FRAME_COLOR := Color("#FFD84D")      # khung ô sáng quanh nút
const TYPE_SPEED := 48.0                   # ký tự / giây
const PANEL_W := 1120.0

## false: tắt hẳn (test, công cụ chụp ảnh).
var enabled := true
## Test: dùng node này thay cho SaveService (cần thuộc tính `data`) / thay cho scene hiện tại.
var save_override: Node = null
var scene_override: Node = null
## Nút đang được chỉ (null = không khóa).
var target: Control = null
var hint_key := ""
## Bước đang chạy và các câu của nó ({"text", "reply"}); `line_index` = câu đang hiện.
var step_id := ""
var lines: Array = []
var line_index := 0

var _typed := 0.0
var _shown := false
var _dims: Array[ColorRect] = []
var _frame: Panel
var _arrow: Label
var _panel: PanelContainer
var _core: Control
var _name: Label
var _text: Label
var _reply: Button
var _next: Label
var _skip: Button
var _t := 0.0


func _ready() -> void:
	layer = 99                       # trên màn kết quả (95), dưới lớp mờ chuyển scene (100)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"back_interceptor")
	for i in 4:
		var d := ColorRect.new()
		d.name = "Dim%d" % i
		d.color = DIM
		d.mouse_filter = Control.MOUSE_FILTER_STOP
		d.gui_input.connect(_on_dim_input)
		add_child(d)
		_dims.append(d)
	_frame = Panel.new()
	_frame.name = "Frame"
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0), FRAME_COLOR, 6, 14))
	add_child(_frame)
	_arrow = Label.new()
	_arrow.name = "Arrow"
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.add_theme_font_size_override("font_size", 56)
	_arrow.add_theme_color_override("font_color", FRAME_COLOR)
	add_child(_arrow)
	_build_panel()
	_set_shown(false)


func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	return sb


## Khung hội thoại: [lõi AI] [tên + chữ] ; dưới: bỏ qua thoại (trái) · câu đáp của Quản lý / "chạm để tiếp tục" (phải).
func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "DialogPanel"
	_panel.custom_minimum_size.x = PANEL_W
	var sb := _box(Color(0.03, 0.07, 0.13, 0.94), ACCENT, 2, 16)
	sb.set_content_margin_all(22)
	sb.shadow_color = Color(ACCENT, 0.35)
	sb.shadow_size = 14
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.gui_input.connect(_on_dim_input)
	add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(row)
	_core = AiCore.new()
	_core.name = "AiCore"
	_core.custom_minimum_size = Vector2(132, 132)
	_core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_core)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)
	_name = Label.new()
	_name.name = "Speaker"
	_name.add_theme_font_size_override("font_size", 28)
	_name.add_theme_color_override("font_color", ACCENT)
	texts.add_child(_name)
	_text = Label.new()
	_text.name = "Line"
	_text.add_theme_font_size_override("font_size", 32)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(PANEL_W - 220, 96)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(_text)
	var bottom := HBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(bottom)
	_skip = Button.new()
	_skip.name = "SkipTalk"
	_skip.flat = true
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.add_theme_font_size_override("font_size", 24)
	_skip.add_theme_color_override("font_color", Color(ACCENT, 0.7))
	_skip.pressed.connect(skip_talk)
	bottom.add_child(_skip)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(spacer)
	_next = Label.new()
	_next.name = "TapNext"
	_next.add_theme_font_size_override("font_size", 24)
	_next.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_next.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(_next)
	_reply = Button.new()
	_reply.name = "Reply"
	_reply.focus_mode = Control.FOCUS_NONE
	_reply.custom_minimum_size = Vector2(360, 72)
	_reply.add_theme_font_size_override("font_size", 28)
	var rb := _box(Color(ACCENT, 0.16), ACCENT, 2, 36)
	rb.set_content_margin_all(14)
	_reply.add_theme_stylebox_override("normal", rb)
	var rh := rb.duplicate() as StyleBoxFlat
	rh.bg_color = Color(ACCENT, 0.32)
	_reply.add_theme_stylebox_override("hover", rh)
	_reply.add_theme_stylebox_override("pressed", rh)
	_reply.add_theme_color_override("font_color", Color.WHITE)
	_reply.pressed.connect(advance)
	bottom.add_child(_reply)


func is_active() -> bool:
	return _shown and target != null and is_instance_valid(target)


## Đang trò chuyện (chưa tới câu chỉ dẫn): cả màn bị che, nút của bước chưa bấm được.
func is_talking() -> bool:
	return is_active() and line_index < lines.size() - 1


func _process(delta: float) -> void:
	_t += delta
	_typed += delta * TYPE_SPEED
	refresh()


## Tính lại bước theo save và scene hiện tại, tìm nút, cập nhật khung (gọi mỗi frame; test gọi trực tiếp).
func refresh() -> void:
	target = null
	var tree := get_tree()
	var save: Node = save_override if save_override else (tree.root.get_node_or_null("SaveService") if tree else null)
	var scene: Node = scene_override if scene_override else (tree.current_scene if tree else null)
	if not enabled or save == null or scene == null or not (save.data is Dictionary) or save.data.is_empty():
		_set_shown(false)
		return
	var s := TutorialFlow.step(save.data, scene.scene_file_path)
	if bool(s.get("finish", false)):
		_finish(save)
		return
	var names: Array = s.get("targets", [])
	for i in names.size():
		var c := scene.find_child(str(names[i]), true, false) as Control
		if c and c.is_visible_in_tree():
			target = c
			s = TutorialFlow.pick(s, i)
			break
	if target == null:
		if bool(s.get("finish_if_missing", false)) and step_id == str(s.get("id", "")):
			_finish(save)
			return
		_set_shown(false)
		return
	if str(s.get("id", "")) != step_id or lines.is_empty():
		_start_step(save.data, s)
	hint_key = str(s.get("hint", ""))
	_shown = true                    # is_talking() cần biết đang hiện trước khi đặt khung
	_update_panel()
	_place()
	_set_shown(true)


func _start_step(data: Dictionary, s: Dictionary) -> void:
	step_id = str(s.get("id", ""))
	lines = TutorialFlow.lines_for(data, s)
	line_index = 0
	_typed = 0.0
	if lines.size() == 1:
		_mark_seen()


## Sang câu kế. Đang hiện chữ dở thì hiện hết câu trước.
func advance() -> void:
	if lines.is_empty():
		return
	if not line_done():
		_typed = 1e6
		return
	if line_index < lines.size() - 1:
		line_index += 1
		_typed = 0.0
		if line_index == lines.size() - 1:
			_mark_seen()


## Nhảy thẳng tới câu chỉ dẫn (nút "Bỏ qua thoại").
func skip_talk() -> void:
	if lines.is_empty():
		return
	line_index = lines.size() - 1
	_typed = 1e6
	_mark_seen()


func line_done() -> bool:
	return _typed >= current_text().length()


func current_text() -> String:
	return tr(str(lines[line_index]["text"])) if line_index < lines.size() else ""


func current_reply() -> String:
	var k := str(lines[line_index]["reply"]) if line_index < lines.size() else ""
	return tr(k) if k != "" else ""


func _mark_seen() -> void:
	var save: Node = save_override if save_override else get_tree().root.get_node_or_null("SaveService")
	if save == null or step_id == "":
		return
	if not TutorialFlow.has_seen(save.data, step_id):
		TutorialFlow.mark_seen(save.data, step_id)
		if save.has_method("save_game"):
			save.save_game()


func _finish(save: Node) -> void:
	TutorialFlow.finish(save.data)
	if save.has_method("save_game"):
		save.save_game()
	step_id = ""
	lines = []
	_set_shown(false)


func _set_shown(on: bool) -> void:
	_shown = on
	for d in _dims:
		d.visible = on
	_panel.visible = on
	var acting := on and not is_talking()
	_frame.visible = acting
	_arrow.visible = acting


func _update_panel() -> void:
	var full := current_text()
	var dlg := TutorialFlow.dialogue()
	_name.text = "%s  ·  %s" % [tr(str(dlg.get("speaker_key", "TUTORIAL_AI_NAME"))),
			tr(str(dlg.get("speaker_title_key", "TUTORIAL_AI_TITLE")))]
	_text.text = full
	_text.visible_characters = mini(int(_typed), full.length()) if not line_done() else -1
	var reply := current_reply()
	var talking := is_talking()
	_reply.visible = talking and line_done() and reply != ""
	_reply.text = "%s:  %s" % [tr(str(dlg.get("player_key", "TUTORIAL_PLAYER_NAME"))), reply]
	_next.visible = talking and not _reply.visible
	_next.text = tr("TUTORIAL_TAP_NEXT") + "  ▼"
	_next.modulate.a = 0.5 + 0.5 * sin(_t * TAU / 1.2)
	_skip.visible = talking
	_skip.text = tr("TUTORIAL_SKIP_TALK")


## Ô sáng = khung của nút (theo tọa độ màn, kể cả nút nằm trong CanvasLayer khác) nới PAD.
func hole_rect() -> Rect2:
	if target == null or not is_instance_valid(target):
		return Rect2()
	var xf := target.get_global_transform_with_canvas()
	return Rect2(xf.origin, target.size * xf.get_scale()).grow(PAD)


func _place() -> void:
	var view := get_viewport().get_visible_rect().size
	var talking := is_talking()
	# Lúc trò chuyện: không có ô sáng, cả màn tối.
	var h := Rect2(view * 0.5, Vector2.ZERO) if talking else hole_rect()
	var top := clampf(h.position.y, 0.0, view.y)
	var bottom := clampf(h.end.y, 0.0, view.y)
	_dims[0].position = Vector2.ZERO
	_dims[0].size = Vector2(view.x, top if not talking else view.y)
	_dims[1].position = Vector2(0, bottom)
	_dims[1].size = Vector2(view.x, maxf(view.y - bottom, 0.0))
	_dims[2].position = Vector2(0, top)
	_dims[2].size = Vector2(maxf(h.position.x, 0.0), bottom - top)
	_dims[3].position = Vector2(h.end.x, top)
	_dims[3].size = Vector2(maxf(view.x - h.end.x, 0.0), bottom - top)
	if talking:
		for i in range(1, 4):
			_dims[i].size = Vector2.ZERO
	# Khung hội thoại: dưới màn; khi chỉ dẫn mà nút nằm ở nửa dưới thì đưa lên trên.
	_panel.reset_size()
	var ps := _panel.get_combined_minimum_size()
	var on_top := not talking and h.get_center().y > view.y * 0.5
	var px := clampf((view.x - ps.x) * 0.5, 16.0, maxf(view.x - ps.x - 16.0, 16.0))
	_panel.position = Vector2(px, 24.0 if on_top else view.y - ps.y - 24.0)
	if talking:
		return
	var pulse := 0.5 + 0.5 * sin(_t * TAU / 0.9)
	var grow := 4.0 * pulse
	_frame.position = h.position - Vector2(grow, grow)
	_frame.size = h.size + Vector2(grow, grow) * 2.0
	_frame.modulate.a = 0.6 + 0.4 * pulse
	# Mũi tên ngay ngoài nút, phía còn chỗ: nút ở nửa dưới thì mũi tên ở trên (chỉ xuống), ngược lại ở dưới (chỉ lên).
	var bob := 8.0 * sin(_t * TAU / 0.7)
	var above := h.get_center().y > view.y * 0.5
	_arrow.text = "▼" if above else "▲"
	_arrow.reset_size()
	var asz := _arrow.get_combined_minimum_size()
	if above:
		_arrow.position = Vector2(h.get_center().x - asz.x * 0.5, h.position.y - asz.y - 6.0 + bob)
	else:
		_arrow.position = Vector2(h.get_center().x - asz.x * 0.5, h.end.y + 6.0 + bob)


func _on_dim_input(event: InputEvent) -> void:
	if not is_talking():
		return
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed):
		advance()


## Bàn phím / tay cầm: Enter / A sang câu kế (trò chuyện) hoặc bấm đúng nút được chỉ; mọi phím khác bị chặn.
## Chuột / chạm do các ô tối và khung hội thoại xử lý.
func _input(event: InputEvent) -> void:
	if not is_active():
		return
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		if is_talking():
			advance()
		else:
			press_target()


## Bấm nút đang chỉ (Enter / A ở câu chỉ dẫn, và test).
func press_target() -> void:
	if target == null or not is_instance_valid(target):
		return
	if target is BaseButton and (target as BaseButton).disabled:
		return
	if target.has_signal("pressed"):
		target.emit_signal("pressed")


## SceneRouter hỏi trước khi lùi (Esc / Back Android): đang hướng dẫn thì không cho lùi.
func intercept_back() -> bool:
	return is_active()
