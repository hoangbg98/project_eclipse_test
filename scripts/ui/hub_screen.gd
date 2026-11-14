class_name HubScreen
extends LayoutScreen
## Lớp nền cho các màn mở từ tab Trang chủ (Túi đồ, Tiếp tế, Xuất kích, Người cộng tác, Thông tin người chơi):
## thanh trên gồm nút "Trở về", nút "Menu" (về Hub), tiêu đề và ô vàng / ngọc. Bố cục chung ở
## data/ui/hub_screens_layout.json (mục "common" + mục riêng từng màn).

const LAYOUT_PATH := "res://data/ui/hub_screens_layout.json"
const ICON_DIR := "res://assets/ui/hub/icons/%s.png"

## Scene vừa yêu cầu mở (để test khi chạy không có SceneRouter / không đổi scene thật).
var last_target := ""
## false: không đổi scene thật (test).
var navigate_enabled := true


func _layout_path() -> String:
	return LAYOUT_PATH


func _ready() -> void:
	_setup_layout()
	refresh()


## Tiêu đề trên thanh trên (lớp con ghi đè).
func screen_title() -> String:
	return ""


func _build() -> void:
	_top_bar()
	_build_body()


## Lớp con: nội dung chính.
func _build_body() -> void:
	pass


func _top_bar() -> void:
	_yellow_button(layout.rect("common.back", Rect2(48, 16, 190, 76)), "‹ " + layout.label("common.back", tr("UI_BACK")),
			int(layout.num("common.back.font", 30)), on_back_button, "BackButton")
	_yellow_button(layout.rect("common.menu", Rect2(258, 16, 220, 76)), layout.label("common.menu", tr("UI_MENU")),
			int(layout.num("common.menu.font", 30)), go_menu, "MenuButton")
	if screen_title() != "":
		_label(layout.rect("common.title", Rect2(500, 16, 600, 76)), screen_title(), int(layout.num("common.title.font", 36)))
	for cur: String in ["gold", "gems"]:
		var r := layout.rect("common." + cur, Rect2())
		if r.size == Vector2.ZERO:
			continue
		var p := _panel(r, layout.color("panel", Color(0.08, 0.09, 0.12, 0.85)), "Pill_" + cur)
		p.add_theme_stylebox_override("panel", _style(layout.color("panel", Color(0.08, 0.09, 0.12, 0.85)),
				Color(1, 1, 1, 0.15), int(r.size.y * 0.5)))
		var dot := _panel(Rect2(r.position + Vector2(12, r.size.y * 0.2), Vector2(r.size.y * 0.6, r.size.y * 0.6)),
				layout.color(cur, Color.YELLOW))
		dot.add_theme_stylebox_override("panel", _style(layout.color(cur, Color.YELLOW), Color(0, 0, 0, 0), int(r.size.y * 0.3)))
		_label(Rect2(r.position + Vector2(r.size.y * 0.8 + 12, 0), Vector2(r.size.x - r.size.y * 0.8 - 32, r.size.y)),
				"%d" % profile.inventory.currency(cur), int(layout.num("common.%s.font" % cur, 28)), Color.WHITE,
				HORIZONTAL_ALIGNMENT_RIGHT)


## Nút vàng (Trở về / Menu / nút hành động trên thẻ).
func _yellow_button(r: Rect2, text: String, font_size: int, cb: Callable, name_ := "") -> Button:
	var b := _button(r, text, font_size, cb, false, name_)
	var bg := layout.color("yellow", Color("#FFD84D"))
	var fg := layout.color("yellow_text", Color("#1B1E2B"))
	b.add_theme_stylebox_override("normal", _style(bg, bg.darkened(0.2), 10))
	b.add_theme_stylebox_override("hover", _style(bg.lightened(0.1), bg.darkened(0.2), 10))
	b.add_theme_stylebox_override("pressed", _style(bg.darkened(0.15), bg.darkened(0.3), 10))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, fg)
	return b


func _icon(r: Rect2, icon_name: String, tint := Color.WHITE) -> TextureRect:
	var t := TextureRect.new()
	var p := ICON_DIR % icon_name
	t.texture = load(p) as Texture2D if ResourceLoader.exists(p) else null
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.modulate = tint
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(t, r)
	return t


## Về Hub (xóa lịch sử như mở Hub từ đầu).
func go_menu() -> void:
	open_scene("SCENE_HUB", true)


## Mở scene theo tên hằng trong GameConfig. `replace_` = xóa lịch sử (về Hub).
func open_scene(scene_const: String, replace_ := false) -> void:
	var gc := UiKit.autoload("GameConfig")
	last_target = str(gc.get(scene_const)) if gc else scene_const
	var router := UiKit.autoload("SceneRouter")
	if not navigate_enabled or router == null or last_target == "":
		return
	if replace_:
		router.replace(last_target)
	else:
		router.push(last_target)


## Hiện thông báo ngắn (tính năng chưa có...).
func say(text: String) -> void:
	notice = text
	refresh()
