class_name HubHomePanel
extends HubPanel
## Sảnh chính (owner 2026-11-14, bản 2 — kiểu ô ghép theo dự án cũ của owner):
## - nền phía sau: nền người chơi đang chọn (data/backgrounds/, đổi được);
## - bên trái: ảnh splash nhân vật đầu đội; góc trên-trái: thẻ người chơi → Thông tin người chơi;
## - góc trên-phải: ô vàng / ngọc, nút Đổi nền (khung tranh), nút Cài đặt (bánh răng);
## - bên phải: ô ghép nghiêng Nhân vật, Xuất kích (hàng trên), Trang bị, Tiếp tế, Người cộng tác (hàng dưới).
## Không còn thanh tab và dòng tóm tắt. Vị trí, màu, ảnh ô đọc từ data/ui/hub_home_layout.json.
## Bảng chỉ điều hướng; Cài đặt / Đổi nền / Đội hình là bảng nổi của Hub (tín hiệu `request_tab`).

signal request_tab(tab_name: String)

const LAYOUT_PATH := "res://data/ui/hub_home_layout.json"
const ICON_DIR := "res://assets/ui/hub/icons/%s.png"
const PORTRAIT_PATH := "res://assets/characters/%s/portrait/%s_portrait_full.png"
## Ô ghép → hằng scene trong GameConfig.
const TILE_TARGETS := {
	"character": "SCENE_CHARACTER", "sortie": "SCENE_SORTIE", "equipment": "SCENE_BAG",
	"supply": "SCENE_SUPPLY", "companion": "SCENE_COMPANION",
}
## Nút biểu tượng góc phải → bảng nổi của Hub.
const ICON_TABS := {"background": "BackgroundTab", "settings": "SettingsTab", "chat": "ChatTab"}

var layout: UiLayout
## Ô ghép theo khóa — để test.
var tiles: Dictionary = {}
var icon_buttons: Dictionary = {}
var player_card: Button
## Chấm đỏ trên biểu tượng Chat khi có tin nhắn riêng / lời mời chưa đọc (M9-6).
var chat_badge: Panel
## Scene vừa yêu cầu mở (để test).
var last_target := ""
## false: không đổi scene thật (test).
var navigate_enabled := true

var _overlay: Control


func build() -> void:
	if layout == null:
		layout = UiLayout.load_from(LAYOUT_PATH)
	var view := get_viewport_rect().size if is_inside_tree() else layout.design_size
	layout.view_size = view
	# Lớp đặt theo tọa độ màn hình: Hub đặt bảng này phủ kín màn hình (vẽ theo thứ tự cây, bảng nổi của Hub đè lên).
	_overlay = Control.new()
	_overlay.name = "HomeOverlay"
	_overlay.custom_minimum_size = view
	_overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_build_background(view)
	_build_splash()
	_build_player_card()
	_build_pills()
	icon_buttons.clear()
	for key: String in ICON_TABS:
		_build_icon_button(key)
	_build_chat_badge()
	tiles.clear()
	for key: String in TILE_TARGETS:
		_build_tile(key)


func _place(c: Control, r: Rect2) -> Control:
	c.position = r.position
	c.size = r.size
	_overlay.add_child(c)
	return c


func _style(bg: Color, border := Color(0, 0, 0, 0), radius := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2 if border.a > 0.0 else 0)
	s.set_corner_radius_all(radius)
	return s


static func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D if path != "" and ResourceLoader.exists(path) else null


func leader_id() -> String:
	var party := profile.party_ids()
	return party[0] if party.size() > 0 else ""


static func portrait(id: String) -> Texture2D:
	return _tex(PORTRAIT_PATH % [id, id]) if id != "" else null


## Ảnh nền đang dùng (null nếu nền thiếu ảnh, vd bản Release đã loại ảnh placeholder).
func background_texture() -> Texture2D:
	var b := PlayerProfile.background_defs().get_def(profile.hub_background()) as BackgroundDef
	return _tex(b.image) if b else null


func display_name() -> String:
	var n := profile.player_name()
	return n if n != "" else tr("PLAYER_DEFAULT_NAME")


func _build_background(view: Vector2) -> void:
	var col := ColorRect.new()
	col.name = "BackgroundColor"
	col.color = layout.color("fallback_background", Color("#1A2238"))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(col, Rect2(Vector2.ZERO, view))
	var tex := background_texture()
	if tex:
		var bg := TextureRect.new()
		bg.name = "BackgroundArt"
		bg.texture = tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(bg, Rect2(Vector2.ZERO, view))
	var shade := ColorRect.new()
	shade.color = layout.color("shade", Color(0, 0, 0, 0.25))
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(shade, Rect2(Vector2.ZERO, view))


func splash_texture() -> Texture2D:
	var id := leader_id()
	if id == "":
		return null
	var t := _tex(layout.text("splash.path", "").replace("{id}", id))
	return t if t else portrait(id)


func _build_splash() -> void:
	var tex := splash_texture()
	if tex == null:
		return
	var t := TextureRect.new()
	t.name = "Splash"
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(t, layout.rect("splash", Rect2(40, 40, 640, 1040)))


func _build_player_card() -> void:
	var r := layout.rect("player_card", Rect2(40, 24, 520, 108))
	player_card = Button.new()
	player_card.name = "PlayerCard"
	player_card.focus_mode = Control.FOCUS_NONE
	var bg := layout.color("card", Color(0.08, 0.09, 0.12, 0.8))
	var border := layout.color("card_border", Color(1, 1, 1, 0.5))
	player_card.add_theme_stylebox_override("normal", _style(bg, border, int(r.size.y * 0.5)))
	player_card.add_theme_stylebox_override("hover", _style(bg.lightened(0.1), border, int(r.size.y * 0.5)))
	player_card.add_theme_stylebox_override("pressed", _style(bg.darkened(0.2), border, int(r.size.y * 0.5)))
	player_card.pressed.connect(open.bind("SCENE_PLAYER"))
	_place(player_card, r)
	var av := layout.get_value("player_card.avatar", [52, 32, 92, 92]) as Array
	var art := PlaceholderArt.new()
	art.texture = portrait(leader_id())
	art.crop = Rect2(0.2, 0.02, 0.6, 0.36)
	art.border_color = border
	art.position = Vector2(float(av[0]), float(av[1])) - r.position
	art.size = Vector2(float(av[2]), float(av[3]))
	player_card.add_child(art)
	var x := art.position.x + art.size.x + 18.0
	var big := int(layout.num("player_card.font", 32))
	var small := int(layout.num("player_card.font_small", 22))
	var lv := UiKit.label("LV.%d  %s" % [profile.progression.captain_level(), display_name()], big)
	lv.name = "NameLabel"
	lv.autowrap_mode = TextServer.AUTOWRAP_OFF
	lv.clip_text = true
	lv.position = Vector2(x, 10)
	lv.size = Vector2(r.size.x - x - 30, big * 1.4)
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_card.add_child(lv)
	var need := profile.rules.captain_exp_to_next(profile.progression.captain_level())
	var ratio := clampf(float(profile.progression.captain_exp()) / float(need), 0.0, 1.0) if need > 0 else 1.0
	var bar_y := 10.0 + big * 1.45
	for i in 2:
		var c := ColorRect.new()
		c.name = "ExpBack" if i == 0 else "ExpFill"
		c.color = layout.color("exp_back" if i == 0 else "exp_fill", Color(0, 0, 0, 0.6) if i == 0 else Color("#7FD4FF"))
		c.position = Vector2(x, bar_y)
		c.size = Vector2((r.size.x - x - 40) * (1.0 if i == 0 else ratio), 12)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		player_card.add_child(c)
	var hint := UiKit.label(tr("HUB_PLAYER_CARD_HINT"), small)
	hint.add_theme_color_override("font_color", layout.color("text_dim", Color(0.85, 0.86, 0.92)))
	hint.position = Vector2(x, bar_y + 16)
	hint.size = Vector2(r.size.x - x - 30, small * 1.4)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_card.add_child(hint)


func _build_pills() -> void:
	for cur: String in ["gold", "gems"]:
		var r := layout.rect("pills." + cur, Rect2())
		if r.size == Vector2.ZERO:
			continue
		var p := Panel.new()
		p.name = "Pill_" + cur
		p.add_theme_stylebox_override("panel", _style(layout.color("pill", Color(0.08, 0.09, 0.12, 0.8)),
				Color(1, 1, 1, 0.2), int(r.size.y * 0.5)))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(p, r)
		var dot := Panel.new()
		dot.add_theme_stylebox_override("panel", _style(layout.color(cur, Color.YELLOW), Color(0, 0, 0, 0), int(r.size.y * 0.3)))
		dot.position = Vector2(12, r.size.y * 0.2)
		dot.size = Vector2(r.size.y * 0.6, r.size.y * 0.6)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(dot)
		var l := UiKit.label("%d" % profile.inventory.currency(cur), int(layout.num("pills.%s.font" % cur, 28)),
				HORIZONTAL_ALIGNMENT_RIGHT)
		l.name = "Amount"
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.position = Vector2(r.size.y * 0.8 + 12, 0)
		l.size = Vector2(r.size.x - r.size.y * 0.8 - 32, r.size.y)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(l)


func _build_chat_badge() -> void:
	var button: Button = icon_buttons.get("chat")
	var online := UiKit.autoload("OnlineService")
	if button == null or online == null or online.chat == null:
		return
	var d := 26.0
	chat_badge = Panel.new()
	chat_badge.name = "ChatBadge"
	chat_badge.add_theme_stylebox_override("panel", _style(Color("#FF4A4A"), Color.WHITE, int(d / 2)))
	chat_badge.size = Vector2(d, d)
	chat_badge.position = Vector2(button.size.x - d - 2.0, 2.0)
	chat_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(chat_badge)
	# Nối bằng hàm của đối tượng này (tự ngắt khi bảng bị xóa).
	online.chat.unread_changed.connect(update_chat_badge)
	online.chat.friends_changed.connect(update_chat_badge)
	update_chat_badge()


func update_chat_badge() -> void:
	var online := UiKit.autoload("OnlineService")
	if chat_badge == null or online == null or online.chat == null:
		return
	var invites := 0
	for f: Dictionary in online.chat.friends:
		if f["state"] == NakamaApi.FRIEND_INVITE_RECEIVED:
			invites += 1
	chat_badge.visible = online.chat.total_unread() > 0 or invites > 0


func _build_icon_button(key: String) -> void:
	var path := "icon_buttons." + key
	var r := layout.rect(path, Rect2())
	if r.size == Vector2.ZERO:
		return
	var b := Button.new()
	b.name = "Icon_" + key
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tr("HUB_ICON_" + key.to_upper())
	var bg := layout.color("icon_button", Color(0.08, 0.09, 0.12, 0.7))
	b.add_theme_stylebox_override("normal", _style(bg, Color(1, 1, 1, 0.3), int(r.size.y * 0.5)))
	b.add_theme_stylebox_override("hover", _style(bg.lightened(0.15), Color(1, 1, 1, 0.5), int(r.size.y * 0.5)))
	b.add_theme_stylebox_override("pressed", _style(bg.darkened(0.2), Color(1, 1, 1, 0.5), int(r.size.y * 0.5)))
	b.icon = _tex(ICON_DIR % layout.text(path + ".icon", key))
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", int(r.size.x * 0.62))
	b.pressed.connect(func() -> void: request_tab.emit(ICON_TABS[key]))
	_place(b, r)
	icon_buttons[key] = b


func _build_tile(key: String) -> void:
	var path := "tiles." + key
	var t := TileButton.new()
	t.name = "Tile_" + key
	t.label_text = layout.label(path, key)
	t.art = _tex(layout.text(path + ".art", ""))
	var crop := layout.get_value(path + ".art_crop", [0, 0, 1, 1]) as Array
	if crop.size() == 4:
		t.art_crop = Rect2(float(crop[0]), float(crop[1]), float(crop[2]), float(crop[3]))
	t.icon = _tex(ICON_DIR % layout.text(path + ".icon", key))
	var badge_key := layout.text(path + ".badge_key", "")
	t.badge_text = tr(badge_key) if badge_key != "" else ""
	t.bar_color = Color(layout.text(path + ".bar", "#C8324A"))
	t.fill = layout.color("tile_fill", t.fill)
	t.text_color = layout.color("text", t.text_color)
	t.badge_color = layout.color("badge", t.badge_color)
	t.font_size = int(layout.num(path + ".font", layout.num("tiles.font", 40)))
	t.skew = layout.num("tiles.skew", 34.0)
	t.pressed.connect(open.bind(TILE_TARGETS[key]))
	_place(t, layout.rect(path, Rect2(800, 200, 400, 300)))
	tiles[key] = t


## Mở màn theo tên hằng trong GameConfig (SCENE_*).
func open(scene_const: String) -> void:
	var gc := UiKit.autoload("GameConfig")
	var path: String = gc.get(scene_const) if gc else ""
	last_target = path
	if scene_const == "SCENE_CHARACTER" and gc:
		gc.selected_character_id = ""
	var router := UiKit.autoload("SceneRouter")
	if navigate_enabled and router and path != "":
		router.push(path)
