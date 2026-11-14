extends CanvasLayer
## Lớp hướng dẫn người mới (autoload `TutorialGuide`, owner 2026-11-14): làm tối cả màn, chừa một ô sáng quanh nút
## cần bấm kèm khung nhấp nháy và dòng gợi ý; chặn chuột / chạm ngoài ô sáng, chặn phím và nút tay cầm (Enter / A
## bấm đúng nút được chỉ), chặn Back. Luật bước nằm ở TutorialFlow; lớp này chỉ tìm node và vẽ.
## Không có luật gameplay. Không tìm thấy nút của bước (đổi bố cục, đang chuyển scene) thì không khóa gì.

const PAD := 10.0
const DIM := Color(0, 0, 0, 0.68)
const FRAME_COLOR := Color("#FFD84D")

## false: tắt hẳn (test, công cụ chụp ảnh).
var enabled := true
## Test: dùng node này thay cho SaveService (cần thuộc tính `data`) / thay cho scene hiện tại.
var save_override: Node = null
var scene_override: Node = null
## Nút đang được chỉ (null = không khóa).
var target: Control = null
var hint_key := ""

var _dims: Array[ColorRect] = []
var _frame: Panel
var _hint_box: PanelContainer
var _hint: Label
var _arrow: Label
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
		add_child(d)
		_dims.append(d)
	_frame = Panel.new()
	_frame.name = "Frame"
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = FRAME_COLOR
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(14)
	_frame.add_theme_stylebox_override("panel", sb)
	add_child(_frame)
	_hint_box = PanelContainer.new()
	_hint_box.name = "HintBox"
	_hint_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := StyleBoxFlat.new()
	hb.bg_color = Color(0.08, 0.09, 0.14, 0.95)
	hb.border_color = FRAME_COLOR
	hb.set_border_width_all(3)
	hb.set_corner_radius_all(12)
	hb.set_content_margin_all(18)
	_hint_box.add_theme_stylebox_override("panel", hb)
	_hint = Label.new()
	_hint.name = "Hint"
	_hint.add_theme_font_size_override("font_size", 32)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.custom_minimum_size.x = 560
	_hint_box.add_child(_hint)
	add_child(_hint_box)
	_arrow = Label.new()
	_arrow.name = "Arrow"
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.add_theme_font_size_override("font_size", 56)
	_arrow.add_theme_color_override("font_color", FRAME_COLOR)
	add_child(_arrow)
	_set_shown(false)


func is_active() -> bool:
	return target != null and is_instance_valid(target) and _frame.visible


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Tính lại bước theo save và scene hiện tại, tìm nút, đặt ô sáng (gọi mỗi frame; test gọi trực tiếp).
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
	for n: String in s.get("targets", []):
		var c := scene.find_child(n, true, false) as Control
		if c and c.is_visible_in_tree():
			target = c
			break
	if target == null:
		if bool(s.get("finish_if_missing", false)):
			_finish(save)
			return
		_set_shown(false)
		return
	hint_key = str(s.get("hint", ""))
	_hint.text = tr(hint_key)
	_place()
	_set_shown(true)


func _finish(save: Node) -> void:
	TutorialFlow.finish(save.data)
	if save.has_method("save_game"):
		save.save_game()
	_set_shown(false)


func _set_shown(on: bool) -> void:
	for d in _dims:
		d.visible = on
	_frame.visible = on
	_hint_box.visible = on
	_arrow.visible = on


## Ô sáng = khung của nút (theo tọa độ màn, kể cả nút nằm trong CanvasLayer khác) nới PAD.
func hole_rect() -> Rect2:
	if target == null or not is_instance_valid(target):
		return Rect2()
	var xf := target.get_global_transform_with_canvas()
	return Rect2(xf.origin, target.size * xf.get_scale()).grow(PAD)


func _place() -> void:
	var view := get_viewport().get_visible_rect().size
	var h := hole_rect()
	var top := maxf(h.position.y, 0.0)
	var bottom := minf(h.end.y, view.y)
	_dims[0].position = Vector2.ZERO
	_dims[0].size = Vector2(view.x, top)
	_dims[1].position = Vector2(0, bottom)
	_dims[1].size = Vector2(view.x, maxf(view.y - bottom, 0.0))
	_dims[2].position = Vector2(0, top)
	_dims[2].size = Vector2(maxf(h.position.x, 0.0), bottom - top)
	_dims[3].position = Vector2(h.end.x, top)
	_dims[3].size = Vector2(maxf(view.x - h.end.x, 0.0), bottom - top)
	var pulse := 0.5 + 0.5 * sin(_t * TAU / 0.9)
	var grow := 4.0 * pulse
	_frame.position = h.position - Vector2(grow, grow)
	_frame.size = h.size + Vector2(grow, grow) * 2.0
	_frame.modulate.a = 0.6 + 0.4 * pulse
	# Gợi ý dưới nút nếu đủ chỗ, không thì phía trên; mũi tên giữa gợi ý và nút, nảy nhẹ.
	_hint_box.reset_size()
	var hs := _hint_box.get_combined_minimum_size()
	var below := h.end.y + 70.0 + hs.y <= view.y
	var hx := clampf(h.get_center().x - hs.x * 0.5, 16.0, view.x - hs.x - 16.0)
	var hy := h.end.y + 70.0 if below else h.position.y - 70.0 - hs.y
	_hint_box.position = Vector2(hx, clampf(hy, 16.0, view.y - hs.y - 16.0))
	var bob := 8.0 * sin(_t * TAU / 0.7)
	_arrow.text = "▲" if below else "▼"
	_arrow.reset_size()
	var asz := _arrow.get_combined_minimum_size()
	_arrow.position = Vector2(h.get_center().x - asz.x * 0.5,
			(h.end.y + 6.0 + bob) if below else (h.position.y - asz.y - 6.0 + bob))


## Bàn phím / tay cầm: Enter / A bấm đúng nút đang chỉ, mọi phím khác bị chặn. Chuột / chạm do các ô tối chặn.
func _input(event: InputEvent) -> void:
	if not is_active():
		return
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		press_target()


## Bấm nút đang chỉ (dùng cho Enter / A và test).
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
