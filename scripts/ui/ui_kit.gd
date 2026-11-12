class_name UiKit
extends RefCounted
## Hàm dựng control dùng chung cho các màn UI (README 15: vùng chạm ≥ 128 px, chữ qua tr()).

const TOUCH_MIN := 128.0
const FONT_BODY := 30
const FONT_TITLE := 52


## Autoload theo tên, lấy qua cây scene (scene UI còn được nạp bằng --script, khi đó tên autoload chưa có lúc biên dịch).
static func autoload(node_name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(node_name) if tree else null


static func label(text: String, font_size := FONT_BODY, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, min_width := 320.0, font_size := 34) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, TOUCH_MIN)
	b.add_theme_font_size_override("font_size", font_size)
	return b


static func vbox(separation := 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v


static func hbox(separation := 24) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	return h


static func scroll(content: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(content)
	return s


## Lề an toàn (tai thỏ, bo góc) của thiết bị quy về khung thiết kế: [trái, trên, phải, dưới] px.
static func safe_margins(viewport_size: Vector2, screen_size: Vector2i, safe: Rect2i) -> Array[float]:
	if screen_size.x <= 0 or screen_size.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return [0.0, 0.0, 0.0, 0.0]
	var sx := viewport_size.x / float(screen_size.x)
	var sy := viewport_size.y / float(screen_size.y)
	return [maxf(safe.position.x * sx, 0.0), maxf(safe.position.y * sy, 0.0),
			maxf((screen_size.x - safe.end.x) * sx, 0.0), maxf((screen_size.y - safe.end.y) * sy, 0.0)]


## Đặt lề an toàn của màn hình hiện tại cho một Control phủ kín màn hình (HUD, menu).
static func apply_safe_area(root: Control) -> void:
	if not root.is_inside_tree():
		return
	var m := safe_margins(root.get_viewport_rect().size, DisplayServer.screen_get_size(),
			DisplayServer.get_display_safe_area())
	root.offset_left = m[0]
	root.offset_top = m[1]
	root.offset_right = -m[2]
	root.offset_bottom = -m[3]
