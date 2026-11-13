class_name LayoutScreen
extends Control
## Lớp nền cho màn đặt vị trí theo file bố cục JSON (UiLayout): dựng lại toàn bộ từ dữ liệu bằng `refresh()`,
## hàm dựng control tại tọa độ khung thiết kế (nhãn, nút, panel, ảnh / placeholder), nút Back / Esc qua nhóm
## `back_interceptor` (SceneRouter hỏi trước khi lùi). Lớp con ghi đè `_layout_path()` và `_build()`.
## (CharacterScreen có bản dựng riêng cũ; có thể chuyển sang lớp này sau.)

signal changed

const BACK_GROUP := &"back_interceptor"

var layout: UiLayout
var profile: PlayerProfile
## Thông báo ngắn (lý do thao tác bị từ chối...) hiện giữa trên màn.
var notice := ""
## false: không ghi file save (test dùng dữ liệu riêng).
var save_enabled := true

var _root: Control


## Lớp con: đường dẫn file bố cục.
func _layout_path() -> String:
	return ""


## Lớp con: dựng nội dung vào `_root` (đã có nền).
func _build() -> void:
	pass


## Lớp con: lùi một bước trong màn; trả về true nếu đã xử lý (false = để SceneRouter quay lại scene trước).
func intercept_back() -> bool:
	return false


func _setup_layout() -> void:
	add_to_group(BACK_GROUP)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	layout = UiLayout.load_from(_layout_path())
	for e in layout.errors:
		push_warning("%s: %s" % [name, e])
	if profile == null:
		var save := UiKit.autoload("SaveService")
		profile = PlayerProfile.new(save.data if save else SaveSchema.default_data())
	resized.connect(refresh)


func refresh() -> void:
	if layout == null:
		return
	layout.view_size = size if size.x > 0.0 and size.y > 0.0 else layout.design_size
	if _root:
		remove_child(_root)
		_root.queue_free()
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = layout.color("background", Color("#1B1E2B"))
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)
	_build()
	if notice != "":
		_label(Rect2(layout.view_size.x * 0.5 - 500, 100, 1000, 50), notice, 28,
				layout.color("accent", Color.ORANGE), HORIZONTAL_ALIGNMENT_CENTER).name = "Notice"


## Ghi save (nếu màn đang giữ đúng dữ liệu của SaveService), dựng lại, báo thay đổi.
func commit() -> void:
	var save := UiKit.autoload("SaveService")
	if save_enabled and save and is_same(save.data, profile.data):
		save.save_game()
	refresh()
	changed.emit()


## Rời màn: quay lại scene trước, hoặc về Hub nếu không còn lịch sử.
func leave() -> void:
	var router := UiKit.autoload("SceneRouter")
	var gc := UiKit.autoload("GameConfig")
	if router == null:
		return
	if router.can_go_back():
		router.go_back()
	elif gc:
		router.replace(gc.SCENE_HUB)


func on_back_button() -> void:
	if not intercept_back():
		leave()


# ---------- Hàm dựng control ----------

func _place(c: Control, r: Rect2) -> void:
	c.position = r.position
	c.size = r.size
	_root.add_child(c)


func _style(bg: Color, border := Color(0, 0, 0, 0), radius := 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2 if border.a > 0.0 else 0)
	s.set_corner_radius_all(radius)
	return s


func _panel(r: Rect2, col := Color(0, 0, 0, 0), name_ := "") -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", _style(col if col.a > 0.0 else layout.color("panel", Color(0.08, 0.09, 0.12, 0.88))))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if name_ != "":
		p.name = name_
	_place(p, r)
	return p


func _label(r: Rect2, text: String, font_size: int, col := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(l, r)
	return l


## Nút. `selected_` vẽ nền sáng chữ tối. `cb` không hợp lệ = nút chưa có chức năng: bấm hiện thông báo `not_yet_text`.
func _button(r: Rect2, text: String, font_size: int, cb: Callable, selected_ := false, name_ := "",
		not_yet_text := "") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	var bg := layout.color("button_selected", Color.WHITE) if selected_ else layout.color("button", Color(0.12, 0.13, 0.19))
	var fg := layout.color("text_dark", Color.BLACK) if selected_ else layout.color("text", Color.WHITE)
	var border := layout.color("button_border", Color(0.36, 0.39, 0.5))
	b.add_theme_stylebox_override("normal", _style(bg, border))
	b.add_theme_stylebox_override("hover", _style(bg.lightened(0.12), border))
	b.add_theme_stylebox_override("pressed", _style(bg.darkened(0.15), border))
	b.add_theme_stylebox_override("disabled", _style(bg.darkened(0.3), border.darkened(0.3)))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, fg)
	b.add_theme_color_override("font_disabled_color", fg.darkened(0.5))
	if cb.is_valid():
		b.pressed.connect(cb)
	else:
		b.pressed.connect(func() -> void:
			notice = not_yet_text if not_yet_text != "" else tr("CHAR_UI_NOT_YET")
			refresh())
	if name_ != "":
		b.name = name_
	_place(b, r)
	return b


## Vùng ảnh: có `tex` thì vẽ ảnh, chưa có thì vẽ hình người placeholder kèm `placeholder_label`.
func _art(r: Rect2, tex: Texture2D, placeholder_label: String, crop := Rect2(0, 0, 1, 1), name_ := "") -> PlaceholderArt:
	var a := PlaceholderArt.new()
	a.texture = tex
	a.label_text = placeholder_label
	a.crop = crop
	a.fill_color = layout.color("placeholder_fill", a.fill_color)
	a.figure_color = layout.color("placeholder_figure", a.figure_color)
	a.text_color = layout.color("placeholder_text", a.text_color)
	if name_ != "":
		a.name = name_
	_place(a, r)
	return a
