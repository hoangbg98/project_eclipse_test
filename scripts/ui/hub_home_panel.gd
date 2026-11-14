class_name HubHomePanel
extends HubPanel
## Tab Trang chủ (owner 2026-11-14, theo ảnh tham chiếu sảnh chính):
## - góc trên-trái: thẻ người chơi (ảnh đội trưởng, LV đội trưởng, tên, thanh EXP) → màn Thông tin người chơi;
## - bên trái: dòng tóm tắt cũ (giữ nguyên, owner chỉnh sau);
## - giữa: ảnh nhân vật đầu đội;
## - bên phải: ô vàng / ngọc và cụm nút lục giác Trang bị, Người cộng tác, Xuất kích, Nhân vật, Tiếp tế.
## Vị trí, màu đọc từ data/ui/hub_home_layout.json. Bảng chỉ điều hướng, không chứa luật.

const LAYOUT_PATH := "res://data/ui/hub_home_layout.json"
const ICON_DIR := "res://assets/ui/hub/icons/%s.png"
const PORTRAIT_PATH := "res://assets/characters/%s/portrait/%s_portrait_full.png"
## Nút lục giác → hằng scene trong GameConfig.
const HEX_TARGETS := {
	"equipment": "SCENE_BAG", "companion": "SCENE_COMPANION", "sortie": "SCENE_SORTIE",
	"character": "SCENE_CHARACTER", "supply": "SCENE_SUPPLY",
}

var layout: UiLayout
## Nút lục giác theo khóa (equipment, companion, sortie, character, supply) — để test.
var hex_buttons: Dictionary = {}
var player_card: Button
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
	# Lớp phủ đặt theo tọa độ màn hình (top_level), phần tóm tắt vẫn nằm trong bảng như cũ.
	_overlay = Control.new()
	_overlay.name = "HomeOverlay"
	_overlay.top_level = true
	_overlay.position = Vector2.ZERO
	_overlay.size = view
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_build_leader_art()
	_build_player_card()
	_build_summary()
	_build_pills()
	hex_buttons.clear()
	for key: String in HEX_TARGETS:
		_build_hex(key)


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


func leader_id() -> String:
	var party := profile.party_ids()
	return party[0] if party.size() > 0 else ""


static func portrait(id: String) -> Texture2D:
	var p := PORTRAIT_PATH % [id, id]
	return load(p) as Texture2D if id != "" and ResourceLoader.exists(p) else null


## Tên hiển thị của người chơi (chưa đặt thì tên mặc định).
func display_name() -> String:
	var n := profile.player_name()
	return n if n != "" else tr("PLAYER_DEFAULT_NAME")


func _build_leader_art() -> void:
	var r := layout.rect("leader_art", Rect2(780, 250, 520, 790))
	var glow := Panel.new()
	glow.add_theme_stylebox_override("panel", _style(layout.color("art_glow", Color(0.5, 0.83, 1, 0.15)), Color(0, 0, 0, 0), 260))
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(glow, Rect2(r.position + Vector2(20, r.size.y * 0.25), Vector2(r.size.x - 40, r.size.y * 0.7)))
	var art := PlaceholderArt.new()
	art.name = "LeaderArt"
	art.texture = portrait(leader_id())
	art.label_text = char_name(leader_id()) if leader_id() != "" else ""
	art.border_color = Color(0, 0, 0, 0)
	art.fill_color = Color(0, 0, 0, 0) if art.texture else art.fill_color
	_place(art, r)


func _build_player_card() -> void:
	var r := layout.rect("player_card", Rect2(64, 196, 600, 124))
	player_card = Button.new()
	player_card.name = "PlayerCard"
	player_card.focus_mode = Control.FOCUS_NONE
	var bg := layout.color("card", Color(0.08, 0.09, 0.12, 0.85))
	var border := layout.color("card_border", Color("#7FD4FF"))
	player_card.add_theme_stylebox_override("normal", _style(bg, border))
	player_card.add_theme_stylebox_override("hover", _style(bg.lightened(0.1), border))
	player_card.add_theme_stylebox_override("pressed", _style(bg.darkened(0.2), border))
	player_card.pressed.connect(open.bind("SCENE_PLAYER"))
	_place(player_card, r)
	var av := layout.get_value("player_card.avatar", [76, 206, 104, 104]) as Array
	var art := PlaceholderArt.new()
	art.texture = portrait(leader_id())
	art.crop = Rect2(0.2, 0.02, 0.6, 0.36)
	art.label_text = ""
	art.border_color = border
	art.position = Vector2(float(av[0]), float(av[1])) - r.position
	art.size = Vector2(float(av[2]), float(av[3]))
	player_card.add_child(art)
	var x := art.position.x + art.size.x + 22.0
	var big := int(layout.num("player_card.font", 34))
	var small := int(layout.num("player_card.font_small", 24))
	var lv := UiKit.label("LV.%d  %s" % [profile.progression.captain_level(), display_name()], big)
	lv.name = "NameLabel"
	lv.autowrap_mode = TextServer.AUTOWRAP_OFF
	lv.clip_text = true
	lv.position = Vector2(x, 12)
	lv.size = Vector2(r.size.x - x - 16, big * 1.4)
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_card.add_child(lv)
	var need := profile.rules.captain_exp_to_next(profile.progression.captain_level())
	var ratio := clampf(float(profile.progression.captain_exp()) / float(need), 0.0, 1.0) if need > 0 else 1.0
	var bar_y := 12.0 + big * 1.5
	var back := ColorRect.new()
	back.color = layout.color("exp_back", Color(0, 0, 0, 0.6))
	back.position = Vector2(x, bar_y)
	back.size = Vector2(r.size.x - x - 24, 14)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_card.add_child(back)
	var fill_ := ColorRect.new()
	fill_.name = "ExpFill"
	fill_.color = layout.color("exp_fill", Color("#7FD4FF"))
	fill_.position = back.position
	fill_.size = Vector2(back.size.x * ratio, back.size.y)
	fill_.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_card.add_child(fill_)
	var hint := UiKit.label(tr("HUB_PLAYER_CARD_HINT"), small)
	hint.add_theme_color_override("font_color", layout.color("text_dim", Color(0.72, 0.74, 0.8)))
	hint.position = Vector2(x, bar_y + 20)
	hint.size = Vector2(r.size.x - x - 16, small * 1.4)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_card.add_child(hint)


## Phần bên trái giữ nguyên nội dung cũ (tiêu đề + dòng tóm tắt), chỉ dời xuống dưới thẻ người chơi.
func _build_summary() -> void:
	var r := layout.rect("summary", Rect2(64, 340, 760, 400))
	var box := UiKit.vbox(14)
	box.name = "Summary"
	box.add_child(UiKit.label("PROJECT ECLIPSE", 64))
	for line in summary_lines():
		box.add_child(UiKit.label(line, 30))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(box, r)


func _build_pills() -> void:
	for cur: String in ["gold", "gems"]:
		var r := layout.rect("pills." + cur, Rect2())
		if r.size == Vector2.ZERO:
			continue
		var p := Panel.new()
		p.name = "Pill_" + cur
		p.add_theme_stylebox_override("panel", _style(layout.color("pill", Color(0.08, 0.09, 0.12, 0.85)),
				Color(1, 1, 1, 0.15), int(r.size.y * 0.5)))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(p, r)
		var dot := Panel.new()
		dot.add_theme_stylebox_override("panel", _style(layout.color(cur, Color.YELLOW), Color(0, 0, 0, 0), int(r.size.y * 0.3)))
		dot.position = Vector2(12, r.size.y * 0.2)
		dot.size = Vector2(r.size.y * 0.6, r.size.y * 0.6)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(dot)
		var l := UiKit.label("%s  %d" % [tr("CURRENCY_GOLD" if cur == "gold" else "CURRENCY_GEMS"),
				profile.inventory.currency(cur)], int(layout.num("pills.%s.font" % cur, 30)), HORIZONTAL_ALIGNMENT_RIGHT)
		l.name = "Amount"
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.position = Vector2(r.size.y * 0.8 + 12, 0)
		l.size = Vector2(r.size.x - r.size.y * 0.8 - 32, r.size.y)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(l)


func _build_hex(key: String) -> void:
	var path := "hex." + key
	var c := layout.point(path, "center", Vector2(1700, 500))
	var rad := layout.num(path + ".radius", 112.0)
	var b := HexButton.new()
	b.name = "Hex_" + key
	b.label_text = layout.label(path, key)
	var icon_path := ICON_DIR % layout.text(path + ".icon", key)
	b.icon = load(icon_path) as Texture2D if ResourceLoader.exists(icon_path) else null
	var badge_key := layout.text(path + ".badge_key", "")
	b.badge_text = tr(badge_key) if badge_key != "" else ""
	b.font_size = int(layout.num(path + ".font", layout.num("hex.font", 30)))
	b.fill = layout.color("hex_fill", b.fill)
	b.fill_hover = layout.color("hex_fill_hover", b.fill_hover)
	b.rim = layout.color("hex_rim", b.rim)
	b.glow = layout.color("hex_glow", b.glow)
	b.text_color = layout.color("text", b.text_color)
	b.badge_color = layout.color("badge", b.badge_color)
	b.pressed.connect(open.bind(HEX_TARGETS[key]))
	_place(b, Rect2(c - Vector2(rad * sqrt(3.0) * 0.5, rad), Vector2(rad * sqrt(3.0), rad * 2.0)))
	hex_buttons[key] = b


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


func summary_lines() -> PackedStringArray:
	var out := PackedStringArray([wallet_text()])
	var names := PackedStringArray()
	for id in profile.party_ids():
		names.append("%s Lv.%d" % [char_name(id), profile.progression.level_of(id)])
	out.append("%s: %s" % [tr("BATTLE_PARTY_TITLE"), " · ".join(names)])
	var cleared := 0
	for id in profile.data["progress"]["stages"]:
		var st: Variant = profile.data["progress"]["stages"][id]
		if st is Dictionary and bool(st.get("cleared", false)):
			cleared += 1
	out.append(tr("HOME_STAGES_CLEARED") % cleared)
	return out
