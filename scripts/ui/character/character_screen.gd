class_name CharacterScreen
extends Control
## Màn Nhân vật (owner 2026-11-12, theo 6 ảnh tham chiếu): tổng quan (ảnh 1) → chi tiết với 4 tab Tăng cấp (ảnh 4),
## Vũ khí (ảnh 2), Vết thánh (ảnh 3), Skill (ảnh 5) → chi tiết một kỹ năng (ảnh 6).
## Vị trí, kích thước, cỡ chữ, màu đọc từ data/ui/character_screen_layout.json (UiLayout); vùng chưa có ảnh vẽ
## hình người placeholder có tên vùng. Màn chỉ gọi PlayerProfile / Progression / Inventory; không tự chứa luật.

signal changed

const LAYOUT_PATH := "res://data/ui/character_screen_layout.json"
const PORTRAIT_PATH := "res://assets/characters/%s/portrait/%s_portrait_full.png"
const SPLASH_PATH := "res://assets/characters/{id}/splash/{id}_splash_{name}.png"
const CHARACTER_PATH := "res://data/characters/%s.tres"
const COMBAT_RULES_PATH := "res://data/config/combat_rules.tres"
## Nút Back / Esc được hỏi trước SceneRouter (giống PauseMenu).
const BACK_GROUP := &"back_interceptor"

## WEAPON_DETAIL: bảng thông tin một món trang bị `detail_uid` (owner 2026-11-15): vũ khí (chỉ số, kĩ năng chủ động /
## bị động) hoặc vết thánh (3 tab Skill vết thánh / Skill phụ tố / Skill set), cường hóa, nâng bậc.
enum View { OVERVIEW, DETAIL, SKILL_DETAIL, WEAPON_DETAIL }

var layout: UiLayout
var profile: PlayerProfile
var selected := ""
var view := View.OVERVIEW
var tab := "level"
var skill_group := ""
var brief := false
var glossary_open := false
var detail_stats_open := false
## Bảng giai thoại của món đang xem (khóa <name_key>_LORE, owner 2026-11-15).
var lore_open := false
## Bảng chọn đang mở: "" (không), "exp", "weapon", "stigma_top", "stigma_mid", "stigma_bot", "enhance" (cường hóa
## món `detail_uid`), "ascend" (nâng bậc), "reroll" (tẩy phụ tố vết thánh).
var picker := ""
## Món đang xem ở View.WEAPON_DETAIL.
var detail_uid := ""
## Tab chi tiết quay về khi bấm Trở về ("weapon" / "stigma"); "" = rời màn (mở từ Túi đồ).
var detail_return := "weapon"
## Tab bên phải của chi tiết vết thánh: "skill", "affix", "set".
var detail_tab := "skill"
## Bộ lọc danh sách giáp (owner 2026-11-13): mỗi nhóm rỗng = không lọc theo nhóm đó; trong nhóm là "hoặc", giữa các
## nhóm là "và". Chỉ giữ trong phiên.
var filter := {"rank": [], "element": [], "person": []}
var filter_open := false
## Lý do thao tác gần nhất bị từ chối, hoặc thông báo ngắn; hiện ở giữa trên màn.
var notice := ""
## false: không ghi file save (test dùng dữ liệu riêng).
var save_enabled := true

var _root: Control
var _rules: CombatRules
var _skills_cache: Dictionary = {}   # character_id -> {file_key: SkillDef}


func _ready() -> void:
	add_to_group(BACK_GROUP)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	layout = UiLayout.load_from(LAYOUT_PATH)
	for e in layout.errors:
		push_warning("CharacterScreen: %s" % e)
	_rules = load(COMBAT_RULES_PATH) as CombatRules
	if profile == null:
		var save := UiKit.autoload("SaveService")
		profile = PlayerProfile.new(save.data if save else SaveSchema.default_data())
	var gcfg := UiKit.autoload("GameConfig")
	if detail_uid == "" and gcfg and "inspect_equipment_uid" in gcfg and str(gcfg.inspect_equipment_uid) != "":
		# Mở từ Túi đồ (owner 2026-11-15): xem thẳng bảng thông tin món, Trở về là rời màn.
		detail_uid = str(gcfg.inspect_equipment_uid)
		gcfg.inspect_equipment_uid = ""
	if detail_uid != "" and profile.inventory.owns(detail_uid):
		view = View.WEAPON_DETAIL
		detail_return = ""
		var wearer := profile.inventory.equipped_by(detail_uid)
		if wearer != "":
			selected = wearer
	if selected == "":
		var gc := UiKit.autoload("GameConfig")
		var want := str(gc.selected_character_id) if gc and "selected_character_id" in gc else ""
		selected = want if profile.progression.owns(want) else _owned_ids()[0]
	resized.connect(refresh)
	refresh()


# ---------- Dữ liệu ----------

func _owned_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for id in profile.party_ids():
		out.append(id)
	for id: String in profile.data["characters"]:
		if id not in out:
			out.append(id)
	return out


## Giáp đang sở hữu khớp bộ lọc, theo thứ tự của danh sách.
func filtered_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for id in _owned_ids():
		var d := char_def(id)
		if d == null:
			continue
		if not (filter["rank"] as Array).is_empty() and d.rank not in filter["rank"]:
			continue
		if not (filter["element"] as Array).is_empty() and d.element not in filter["element"]:
			continue
		if not (filter["person"] as Array).is_empty() and d.person() not in filter["person"]:
			continue
		out.append(id)
	return out


func is_filtered() -> bool:
	for k: String in filter:
		if not (filter[k] as Array).is_empty():
			return true
	return false


## Bật / tắt một giá trị trong nhóm lọc ("rank", "element", "person").
func toggle_filter(kind: String, value: String) -> void:
	var arr: Array = filter[kind]
	if value in arr:
		arr.erase(value)
	else:
		arr.append(value)
	refresh()


func clear_filter() -> void:
	for k: String in filter:
		(filter[k] as Array).clear()
	refresh()


func char_def(id: String) -> CharacterDef:
	var p := CHARACTER_PATH % id
	return load(p) as CharacterDef if ResourceLoader.exists(p) else null


func char_name(id: String) -> String:
	var d := char_def(id)
	return tr(d.name_key) if d else id


## Tên giáp (vd "Hỏa Diễm Mãnh Liệt"); chưa có thì rỗng.
func suit_name(id: String) -> String:
	var d := char_def(id)
	return tr(d.suit_key) if d and d.suit_key != "" else ""


func portrait(id: String) -> Texture2D:
	var p := PORTRAIT_PATH % [id, id]
	return load(p) as Texture2D if ResourceLoader.exists(p) else null


## Splash art 2D (không chibi) cho từng màn / tab (owner 2026-11-13): "overview", "level", "weapon", "stigma", "skill".
## Tên file của từng màn đặt ở mục "art" trong file bố cục (đổi ảnh cho từng tab không cần sửa code); đường dẫn mẫu
## "art.path" có {id} và {name}. Thiếu file thì dùng ảnh chân dung chibi (`fallback_portrait`), hoặc null (vẽ placeholder).
func splash(id: String, view_key: String, fallback_portrait := true) -> Texture2D:
	var name_ := layout.text("art." + view_key, view_key)
	var p := layout.text("art.path", SPLASH_PATH).replace("{id}", id).replace("{name}", name_)
	if ResourceLoader.exists(p):
		return load(p) as Texture2D
	return portrait(id) if fallback_portrait else null


func skills_of(id: String) -> Dictionary:
	if not _skills_cache.has(id):
		var d := char_def(id)
		_skills_cache[id] = d.load_skills() if d else {}
	return _skills_cache[id]


func rank_text(id: String) -> String:
	return profile.progression.rank_label(char_def(id))


func _rank_color(label: String) -> Color:
	match label.substr(0, 1):
		"S":
			return layout.color("rank_s", Color("#FFD23F"))
		"A":
			return layout.color("rank_a", Color("#C77DFF"))
		"B":
			return layout.color("rank_b", Color("#4CC9F0"))
	return layout.color("text_dim", Color.GRAY)


## Ghi save, dựng lại.
func commit(reason := "") -> void:
	notice = tr("REASON_" + reason.to_upper()) if reason != "" else ""
	var save := UiKit.autoload("SaveService")
	if save_enabled and save and is_same(save.data, profile.data):
		save.save_game()
	refresh()
	changed.emit()


# ---------- Điều hướng ----------

func select(id: String) -> void:
	if profile.progression.owns(id):
		selected = id
		picker = ""
		refresh()


func open_tab(t: String) -> void:
	view = View.DETAIL
	tab = t
	picker = ""
	notice = ""
	refresh()


func open_skill(group: String) -> void:
	view = View.SKILL_DETAIL
	skill_group = group
	picker = ""
	notice = ""
	refresh()


## Lùi một bước trong màn; trả về true nếu đã xử lý (false = đang ở tổng quan, để SceneRouter về Hub).
func intercept_back() -> bool:
	if picker != "" or glossary_open or detail_stats_open or filter_open or lore_open:
		picker = ""
		lore_open = false
		glossary_open = false
		detail_stats_open = false
		filter_open = false
	elif view == View.SKILL_DETAIL:
		view = View.DETAIL
		tab = "skill"
	elif view == View.WEAPON_DETAIL:
		if detail_return == "":
			return false
		view = View.DETAIL
		tab = detail_return
	elif view == View.DETAIL:
		view = View.OVERVIEW
	else:
		return false
	notice = ""
	refresh()
	return true


func _on_back_button() -> void:
	if not intercept_back():
		_leave()


func _leave() -> void:
	var router := UiKit.autoload("SceneRouter")
	var gc := UiKit.autoload("GameConfig")
	if router == null:
		return
	if router.can_go_back():
		router.go_back()
	elif gc:
		router.replace(gc.SCENE_HUB)


# ---------- Dựng giao diện ----------

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
	var bg_tex := background_texture(background_key())
	if bg_tex:
		var tr_ := TextureRect.new()
		tr_.name = "Background"
		tr_.texture = bg_tex
		tr_.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr_.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr_.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr_.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(tr_)
	match view:
		View.OVERVIEW:
			_build_overview()
		View.DETAIL:
			_build_detail()
		View.SKILL_DETAIL:
			_build_skill_detail()
		View.WEAPON_DETAIL:
			_build_weapon_detail()
	_build_common()
	if detail_stats_open:
		_build_detail_stats()
	if glossary_open:
		_build_glossary()
	if lore_open and view == View.WEAPON_DETAIL:
		_build_lore()
	if picker != "":
		_build_picker()
	if filter_open and view == View.OVERVIEW:
		_build_filter()
	if notice != "":
		var n := _label(Rect2(layout.view_size.x * 0.5 - 500, 960 if view == View.OVERVIEW else 110, 1000, 50), notice, 28,
				layout.color("accent", Color.ORANGE), HORIZONTAL_ALIGNMENT_CENTER)
		n.name = "Notice"


## Khóa ảnh nền của màn đang mở (mục "backgrounds" trong file bố cục).
func background_key() -> String:
	match view:
		View.OVERVIEW:
			return "overview"
		View.SKILL_DETAIL:
			return "skill_detail"
		View.WEAPON_DETAIL:
			return "weapon_detail"
	return tab


## Ảnh nền theo màn; thiếu thì ảnh "default"; vẫn thiếu thì null (nền màu).
func background_texture(key: String) -> Texture2D:
	var pattern := layout.text("backgrounds.path", "")
	if pattern == "":
		return null
	for name_ in [layout.text("backgrounds." + key, ""), layout.text("backgrounds.default", "")]:
		if name_ == "":
			continue
		var p := pattern.replace("{name}", name_)
		if ResourceLoader.exists(p):
			return load(p) as Texture2D
	return null


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


## Nút; `selected` vẽ nền sáng chữ tối (tab đang mở). `cb` rỗng = nút placeholder (chưa có chức năng): bấm hiện thông báo.
func _button(r: Rect2, text: String, font_size: int, cb: Callable, selected_ := false, name_ := "") -> Button:
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
			notice = tr("CHAR_UI_NOT_YET")
			refresh())
	if name_ != "":
		b.name = name_
	_place(b, r)
	return b


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


## Dải chuyển màu từ màu nền sang trong suốt ở mép trái, phải và đáy của vùng `r` (độ rộng `w` px).
func _edge_fade(r: Rect2, w: float) -> void:
	var bg := layout.color("background", Color("#1B1E2B"))
	for side in ["left", "right", "bottom"]:
		var g := Gradient.new()
		g.set_color(0, bg)
		g.set_color(1, Color(bg, 0.0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.width = 64
		gt.height = 64
		var rr := Rect2()
		match side:
			"left":
				gt.fill_from = Vector2(0, 0.5)
				gt.fill_to = Vector2(1, 0.5)
				rr = Rect2(r.position, Vector2(w, r.size.y))
			"right":
				gt.fill_from = Vector2(1, 0.5)
				gt.fill_to = Vector2(0, 0.5)
				rr = Rect2(Vector2(r.end.x - w, r.position.y), Vector2(w, r.size.y))
			_:
				gt.fill_from = Vector2(0.5, 1)
				gt.fill_to = Vector2(0.5, 0)
				rr = Rect2(Vector2(r.position.x, r.end.y - w), Vector2(r.size.x, w))
		var t := TextureRect.new()
		t.texture = gt
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_SCALE
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.name = "EdgeFade_" + side
		_place(t, rr)


## Chữ đè thẳng lên ảnh full art (owner 2026-11-15: bỏ nền ô chữ, chỉ để chữ): viền đen đậm để đọc được trên mọi ảnh.
func _overlay_label(r: Rect2, text: String, font_size: int, col := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := _label(r, text, font_size, col, align)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	l.add_theme_constant_override("outline_size", maxi(8, font_size / 3))
	return l


func _badge(r: Rect2, text: String, font_size: int) -> Label:
	var p := _panel(r, Color(0, 0, 0, 0.0001))
	p.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.35), _rank_color(text), 8))
	return _label(r, text, font_size, _rank_color(text), HORIZONTAL_ALIGNMENT_CENTER)


func _stars(n: int) -> String:
	return "★".repeat(maxi(n, 0))


func _common(path: String) -> Rect2:
	return layout.rect("common." + path)


func _build_common() -> void:
	var c := "common."
	_button(_common("back_button"), "<", 44, _on_back_button, false, "BackButton")
	_label(_common("back_hint"), layout.label(c + "back_hint", "Esc"), layout.font(c + "back_hint", 18),
			layout.color("text_dim", Color.GRAY), HORIZONTAL_ALIGNMENT_CENTER)
	_button(_common("home_button"), "⌂", 40, _leave, false, "HomeButton")
	_label(_common("home_hint"), layout.label(c + "home_hint", "Home"), layout.font(c + "home_hint", 18),
			layout.color("text_dim", Color.GRAY), HORIZONTAL_ALIGNMENT_CENTER)
	if view == View.SKILL_DETAIL:
		return   # ảnh 6: góc trên-phải là Sơ lược / Giải thích từ ngữ
	_button(_common("tutorial_button"), layout.label(c + "tutorial_button"), layout.font(c + "tutorial_button"), Callable())
	_button(_common("strategy_button"), layout.label(c + "strategy_button"), layout.font(c + "strategy_button"), Callable())


# ---------- Ảnh 1: tổng quan ----------

func _build_overview() -> void:
	var o := "overview."
	var def := char_def(selected)
	_art(layout.rect(o + "character_art"), splash(selected, "overview"), layout.text(o + "character_art.placeholder_label", ""),
			Rect2(0, 0, 1, 1), "CharacterArt")
	_button(layout.rect(o + "info_button"), layout.label(o + "info_button", "!"), 40, Callable())
	_label(layout.rect(o + "title"), char_name(selected), layout.font(o + "title", 64), Color.WHITE)
	_badge(layout.rect(o + "rank_badge"), rank_text(selected), layout.font(o + "rank_badge", 40))
	var sub := "%s · %s · %s" % [suit_name(selected), tr("ELEMENT_" + def.element.to_upper()) if def else "?",
			tr("WEAPON_TYPE_" + def.weapon_type.to_upper()) if def and def.weapon_type != "" else "?"]
	_label(layout.rect(o + "subtitle"), sub, layout.font(o + "subtitle", 32), Color.WHITE)
	_panel(layout.rect(o + "level_box"), Color(0.1, 0.1, 0.14, 0.9))
	_label(layout.rect(o + "level_box"), "Lv.%d" % profile.progression.level_of(selected), layout.font(o + "level_box", 34),
			Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_icon_row(o + "icon_row_1", _attribute_icons(def), false)
	_icon_row(o + "icon_row_2", _group_icons(), true)
	_label(layout.rect(o + "skill_header"), layout.label(o + "skill_header"), layout.font(o + "skill_header", 34), Color.WHITE)
	_button(layout.rect(o + "skill_view_button"), layout.label(o + "skill_view_button"), layout.font(o + "skill_view_button", 32),
			open_tab.bind("skill"), false, "SkillViewButton")
	_button(layout.rect(o + "skill_extra_button"), "◇", 32, Callable())
	var keys: Array = layout.get_value(o + "left_icons.label_keys", [])
	var lo := layout.point(o + "left_icons", "origin", Vector2(30, 342))
	var ls := layout.num(o + "left_icons.size", 72)
	var lg := layout.num(o + "left_icons.gap", 36)
	for i in keys.size():
		_button(Rect2(lo + Vector2(0, i * (ls + lg)), Vector2(ls, ls)), tr(str(keys[i])), layout.font(o + "left_icons", 18), Callable())
	_button(layout.rect(o + "inspect_button"), layout.label(o + "inspect_button"), layout.font(o + "inspect_button", 30), Callable())
	# Vũ khí.
	var wuid := profile.inventory.equipped_uid(selected, "weapon")
	var wdef := profile.inventory.equipment_def_of(wuid) if wuid != "" else null
	_label(layout.rect(o + "weapon_title"), tr(wdef.name_key) if wdef else tr("CHAR_UI_EMPTY"), layout.font(o + "weapon_title", 28), Color.WHITE)
	_label(layout.rect(o + "weapon_header"), layout.label(o + "weapon_header"), layout.font(o + "weapon_header", 34), Color.WHITE,
			HORIZONTAL_ALIGNMENT_RIGHT)
	var wr := layout.rect(o + "weapon_card")
	_art(wr, _equip_art(wdef), layout.text(o + "weapon_card.placeholder_label", ""), Rect2(0, 0, 1, 1), "WeaponCard")
	var wb := _button(wr, "", 10, open_tab.bind("weapon"), false, "WeaponCardButton")
	wb.flat = true
	wb.add_theme_stylebox_override("normal", _style(Color(0, 0, 0, 0)))
	# Vết thánh.
	_label(layout.rect(o + "stigma_header"), layout.label(o + "stigma_header"), layout.font(o + "stigma_header", 34), Color.WHITE)
	var so := layout.point(o + "stigma_icons", "origin", Vector2(1428, 648))
	var ss := layout.num(o + "stigma_icons.size", 96)
	var sg := layout.num(o + "stigma_icons.gap", 14)
	for i in EquipmentDef.STIGMA_SLOTS.size():
		var slot := EquipmentDef.STIGMA_SLOTS[i]
		var r := Rect2(so + Vector2(i * (ss + sg), 0), Vector2(ss, ss))
		var uid := profile.inventory.equipped_uid(selected, slot)
		var d := profile.inventory.equipment_def_of(uid) if uid != "" else null
		var tex := _equip_art(d)
		_art(r, tex, tr("SLOT_SHORT_" + slot.to_upper()), PlaceholderArt.center_square(tex))
		var b := _button(r, "", 10, open_tab.bind("stigma"), false, "StigmaIcon%d" % i)
		b.add_theme_stylebox_override("normal", _style(Color(0, 0, 0, 0), Color(1, 1, 1, 0.6 if d else 0.2)))
	_build_roster()


func _attribute_icons(def: CharacterDef) -> Array:
	var el := def.element if def else ""
	return [
		{"text": tr("ELEMENT_" + el.to_upper()).substr(0, 1), "color": HudTheme.ring_color(el)},
		{"text": tr("WEAPON_TYPE_" + def.weapon_type.to_upper()).substr(0, 1) if def and def.weapon_type != "" else "?"},
		{"text": "?"}, {"text": "?"}, {"text": "?"},
	]


func _group_icons() -> Array:
	var out: Array = []
	for g in ["normal", "special", "dodge", "skill", "weapon", "ultimate"]:
		out.append({"text": SkillText.group_abbr(g), "group": g})
	return out


func _icon_row(path: String, icons: Array, clickable: bool) -> void:
	var origin := layout.point(path, "origin", Vector2.ZERO)
	var s := layout.num(path + ".size", 54)
	var gap := layout.num(path + ".gap", 12)
	for i in icons.size():
		var ic: Dictionary = icons[i]
		var r := Rect2(origin + Vector2(i * (s + gap), 0), Vector2(s, s))
		if clickable:
			var b := _button(r, str(ic["text"]), int(s * 0.32), open_skill.bind(str(ic["group"])), i == 0)
			b.tooltip_text = SkillText.group_label(str(ic["group"]))
		else:
			_panel(r, Color(0.1, 0.1, 0.14, 0.9))
			_label(r, str(ic["text"]), int(s * 0.42), ic.get("color", Color.WHITE), HORIZONTAL_ALIGNMENT_CENTER)


func _equip_art(d: EquipmentDef) -> Texture2D:
	if d and d.art != "" and ResourceLoader.exists(d.art):
		return load(d.art) as Texture2D
	return null


func _build_roster() -> void:
	var o := "overview."
	var area := layout.rect(o + "roster")
	var card_v: Variant = layout.get_value(o + "roster.card", [168, 190])
	var card := Vector2(float(card_v[0]), float(card_v[1]))
	var gap := layout.num(o + "roster.gap", 15)
	var ids := filtered_ids()
	if ids.is_empty():
		_label(Rect2(area.position, Vector2(900, card.y)), tr("CHAR_UI_FILTER_EMPTY"), 30, layout.color("text_dim", Color.GRAY)).name = "FilterEmpty"
	for i in ids.size():
		var id := ids[i]
		var r := Rect2(area.position + Vector2(i * (card.x + gap), 0), card)
		if r.end.x > layout.view_size.x:
			break
		var sel := id == selected
		_panel(r, Color(1, 1, 1, 0.9) if sel else Color(0.12, 0.13, 0.19, 0.95))
		# Chừa dải dưới cho hạng + cấp để chữ của hình placeholder không bị đè.
		_art(Rect2(r.position + Vector2(6, 6), r.size - Vector2(12, 64)), portrait(id), char_name(id), Rect2(0.15, 0.0, 0.7, 0.4))
		_badge(Rect2(r.position + Vector2(6, r.size.y - 52), Vector2(54, 46)), rank_text(id), 30)
		_label(Rect2(r.position + Vector2(60, r.size.y - 52), Vector2(r.size.x - 66, 46)), "Lv.%d" % profile.progression.level_of(id),
				layout.font(o + "roster", 34), Color.BLACK if sel else Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
		var b := _button(r, "", 10, select.bind(id), false, "Roster_%s" % id)
		b.add_theme_stylebox_override("normal", _style(Color(0, 0, 0, 0), Color(1, 0.85, 0.3) if sel else Color(1, 1, 1, 0.15)))
	var fb := _button(layout.rect(o + "roster_filter"), layout.label(o + "roster_filter"), layout.font(o + "roster_filter", 18),
			func() -> void:
				filter_open = true
				refresh(), is_filtered(), "FilterButton")
	fb.tooltip_text = tr("CHAR_UI_FILTER_COUNT") % [ids.size(), _owned_ids().size()]
	_button(layout.rect(o + "roster_grid"), layout.label(o + "roster_grid"), layout.font(o + "roster_grid", 18), Callable())


## Bảng lọc: hạng giáp, nguyên tố, nhân vật (chỉ những gì đang sở hữu), nút Bỏ lọc, dòng đếm.
func _build_filter() -> void:
	var r := layout.rect("filter", Rect2(360, 160, 1200, 760))
	var fs := layout.font("filter", 28)
	var bh := layout.num("filter.button_height", 64)
	var dim := _panel(Rect2(Vector2.ZERO, layout.view_size), Color(0, 0, 0, 0.65), "Dim")   # làm tối nền phía sau
	dim.mouse_filter = Control.MOUSE_FILTER_STOP   # chặn bấm xuyên xuống các nút bên dưới
	var bg := layout.color("panel_light", Color(0.16, 0.18, 0.24))
	bg.a = 1.0
	_panel(r, bg, "FilterPanel")
	_label(Rect2(r.position + Vector2(30, 14), Vector2(r.size.x - 260, 60)), tr("CHAR_UI_FILTER_TITLE"), 38, Color.WHITE)
	_button(Rect2(r.position + Vector2(r.size.x - 220, 14), Vector2(200, 60)), tr("UI_BACK"), 28, intercept_back, false, "FilterClose")
	var ranks := PackedStringArray()
	var elements := PackedStringArray()
	var persons := {}
	for id in _owned_ids():
		var d := char_def(id)
		if d == null:
			continue
		if d.rank != "" and d.rank not in ranks:
			ranks.append(d.rank)
		if d.element not in elements:
			elements.append(d.element)
		persons[d.person()] = tr(d.name_key)
	ranks.sort()
	var groups := [
		["rank", "CHAR_UI_FILTER_RANK", Array(ranks).map(func(x: String) -> Array: return [x, x])],
		["element", "CHAR_UI_FILTER_ELEMENT", Array(elements).map(func(x: String) -> Array: return [x, tr("ELEMENT_" + x.to_upper())])],
		["person", "CHAR_UI_FILTER_PERSON", persons.keys().map(func(x: String) -> Array: return [x, persons[x]])],
	]
	var y := r.position.y + 90
	for g: Array in groups:
		_label(Rect2(r.position.x + 30, y, r.size.x - 60, 44), tr(str(g[1])), fs, layout.color("accent_blue", Color.SKY_BLUE))
		y += 50
		var x := r.position.x + 30
		for opt: Array in g[2]:
			var w := maxf(140.0, 24.0 + str(opt[1]).length() * fs * 0.6)
			if x + w > r.end.x - 30:
				x = r.position.x + 30
				y += bh + 10
			var on: bool = str(opt[0]) in filter[str(g[0])]
			_button(Rect2(x, y, w, bh), str(opt[1]), fs, toggle_filter.bind(str(g[0]), str(opt[0])), on,
					"Filter_%s_%s" % [g[0], opt[0]])
			x += w + 12
		y += bh + 24
	_label(Rect2(r.position.x + 30, r.end.y - 84, 600, 64), tr("CHAR_UI_FILTER_COUNT") % [filtered_ids().size(), _owned_ids().size()],
			fs, Color.WHITE).name = "FilterCount"
	_button(Rect2(r.end.x - 250, r.end.y - 84, 220, 64), tr("CHAR_UI_FILTER_CLEAR"), fs, clear_filter, false, "FilterClear")


# ---------- Ảnh 2–5: chi tiết + tab ----------

func _build_detail() -> void:
	if tab == "stigma":
		_build_stigma_art()
	else:
		_art(layout.rect("detail.character_art"), splash(selected, tab), layout.text("detail.character_art.placeholder_label", ""),
				Rect2(0, 0, 1, 1), "CharacterArt")
	match tab:
		"level":
			_build_level_tab()
		"weapon":
			_build_weapon_tab()
		"stigma":
			_build_stigma_tab()
		"skill":
			_build_skill_tab()
	var bar := layout.rect("detail.tab_bar")
	var tabs: Array = layout.get_value("detail.tab_bar.tabs", ["level", "weapon", "stigma", "skill"])
	var keys: Array = layout.get_value("detail.tab_bar.tab_keys", [])
	var w := bar.size.x / maxf(tabs.size(), 1)
	for i in tabs.size():
		var t := str(tabs[i])
		var text := tr(str(keys[i])) if i < keys.size() else t
		_button(Rect2(bar.position + Vector2(i * w, 0), Vector2(w, bar.size.y)), text, layout.font("detail.tab_bar", 34),
				open_tab.bind(t), t == tab, "Tab_%s" % t)


func _build_level_tab() -> void:
	var p := "level_tab."
	var prog := profile.progression
	var stats := profile.stats_of(selected)
	_panel(layout.rect(p + "stats_panel"))
	_badge(layout.rect(p + "rank_badge"), rank_text(selected), layout.font(p + "rank_badge", 40))
	_panel(layout.rect(p + "level_box"), Color(0.05, 0.05, 0.08, 0.95))
	_label(layout.rect(p + "level_box"), "Lv.%d" % prog.level_of(selected), layout.font(p + "level_box", 34), Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER)
	var icons := _attribute_icons(char_def(selected))
	icons.append_array(_group_icons())
	_icon_row(p + "icons", icons.slice(0, 5), false)
	var origin := layout.point(p + "icons", "origin", Vector2(1158, 130))
	var isz := layout.num(p + "icons.size", 52)
	var igap := layout.num(p + "icons.gap", 11)
	var groups := _group_icons()
	for i in groups.size():
		var r := Rect2(origin + Vector2((5 + i) * (isz + igap), 0), Vector2(isz, isz))
		_button(r, str(groups[i]["text"]), int(isz * 0.32), open_skill.bind(str(groups[i]["group"])), i == 0)
	var rows: Array = layout.get_value(p + "stat_rows.rows", [])
	var shift := layout.anchor_shift(layout.text(p + "stat_rows.anchor", "right"))
	for row: Dictionary in rows:
		var rv: Variant = UiLayout._rect_of(row.get("rect"))
		if rv == null:
			continue
		var r: Rect2 = rv
		r.position.x += shift
		_panel(Rect2(r.position + Vector2(0, r.size.y - 2), Vector2(r.size.x, 2)), Color(1, 1, 1, 0.15))
		_label(r, tr(str(row.get("key", ""))), layout.font(p + "stat_rows", 34), layout.color("text_dim", Color.GRAY))
		_label(r, stat_value(str(row.get("stat", "")), stats), layout.font(p + "stat_rows", 34) + 6, Color.WHITE,
				HORIZONTAL_ALIGNMENT_RIGHT).name = "Stat_" + str(row.get("stat", ""))
	_button(layout.rect(p + "detail_button"), layout.label(p + "detail_button"), layout.font(p + "detail_button", 32),
			func() -> void:
				detail_stats_open = true
				refresh(), false, "DetailStatsButton")
	# EXP.
	_panel(layout.rect(p + "exp_panel"))
	_label(layout.rect(p + "exp_label"), "EXP", layout.font(p + "exp_label", 34), Color.WHITE)
	var lv := prog.level_of(selected)
	var need := profile.rules.exp_to_next(lv)
	var xp := prog.exp_of(selected)
	_label(layout.rect(p + "exp_value"), "%d/%d" % [xp, need] if need > 0 else tr("CHAR_MAX_LEVEL"), layout.font(p + "exp_value", 40),
			Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT).name = "ExpValue"
	var bar := layout.rect(p + "exp_bar")
	_panel(bar, Color(1, 1, 1, 0.15))
	_panel(Rect2(bar.position, Vector2(bar.size.x * (float(xp) / need if need > 0 else 1.0), bar.size.y)), layout.color("exp_bar", Color.CYAN))
	_label(layout.rect(p + "captain_label"), tr("CAPTAIN_LEVEL") % prog.captain_level() + ("  ·  " + tr("REASON_LEVEL_CAP") if prog.is_capped(selected) else ""),
			layout.font(p + "captain_label", 24), layout.color("text_dim", Color.GRAY))
	var up := _button(layout.rect(p + "level_up_button"), layout.label(p + "level_up_button"), layout.font(p + "level_up_button", 30),
			open_picker.bind("exp"), false, "LevelUpButton")
	up.disabled = prog.is_max_level(selected)
	# Mảnh.
	_panel(layout.rect(p + "fragment_panel"))
	_label(layout.rect(p + "fragment_title"), layout.label(p + "fragment_title"), layout.font(p + "fragment_title", 34), Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER)
	_art(layout.rect(p + "fragment_icon"), portrait(selected), layout.text(p + "fragment_icon.placeholder_label", ""), Rect2(0.15, 0, 0.7, 0.4))
	var fneed := prog.fragments_to_promote(selected)
	_label(layout.rect(p + "fragment_count"), "%d/%s" % [prog.fragments_of(selected), str(fneed) if fneed > 0 else "MAX"],
			layout.font(p + "fragment_count", 40), Color.WHITE).name = "FragmentCount"
	_button(layout.rect(p + "fragment_convert"), layout.label(p + "fragment_convert"), layout.font(p + "fragment_convert", 30), Callable())
	_button(layout.rect(p + "fragment_source"), layout.label(p + "fragment_source"), layout.font(p + "fragment_source", 30),
			func() -> void:
				notice = tr("CHAR_UI_FRAGMENT_HINT")
				refresh())
	# Tiến cấp.
	_panel(layout.rect(p + "promotion_panel"))
	_label(layout.rect(p + "promotion_title"), layout.label(p + "promotion_title"), layout.font(p + "promotion_title", 34), Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER)
	_badge(layout.rect(p + "promotion_from"), rank_text(selected), layout.font(p + "promotion_from", 40))
	_label(layout.rect(p + "promotion_arrow"), layout.label(p + "promotion_arrow", "»"), layout.font(p + "promotion_arrow", 44),
			Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	var def := char_def(selected)
	var nxt := prog.promotion_of(selected) + 1
	var to_text := (def.rank if def and def.rank != "" else "?") + str(nxt) if fneed > 0 else "MAX"
	_badge(layout.rect(p + "promotion_to"), to_text, layout.font(p + "promotion_to", 40))
	var pb := _button(layout.rect(p + "promote_button"), layout.label(p + "promote_button"), layout.font(p + "promote_button", 30),
			promote, false, "PromoteButton")
	pb.disabled = fneed <= 0


func stat_value(stat: String, s: CombatStats) -> String:
	match stat:
		"max_hp":
			return str(int(s.max_hp))
		"atk":
			return str(int(s.atk))
		"def":
			return str(int(s.def))
		"crit_rate":
			return "%d%%" % roundi(s.crit_rate * 100.0)
		"crit_damage":
			return "+%d%%" % roundi(s.crit_damage * 100.0)
		"cdr":
			return "%d%%" % roundi(s.cdr * 100.0)
		"en_max":
			return str(int(_rules.en_max)) if _rules else "100"
	return "?"


func promote() -> void:
	commit(profile.progression.promote(selected))


func _build_detail_stats() -> void:
	var r := Rect2(layout.view_size.x * 0.5 - 420, 200, 840, 560)
	_panel(r, layout.color("panel_light", Color(0.16, 0.18, 0.24, 0.95)), "DetailStats")
	var s := profile.stats_of(selected)
	var prog := profile.progression
	var lines := PackedStringArray([
		"%s  %s" % [tr("STAT_HP"), stat_value("max_hp", s)], "%s  %s" % [tr("STAT_ATK"), stat_value("atk", s)],
		"%s  %s" % [tr("STAT_DEF"), stat_value("def", s)], "%s  %s" % [tr("STAT_CRIT"), stat_value("crit_rate", s)],
		"%s  %s" % [tr("STAT_CRIT_DAMAGE"), stat_value("crit_damage", s)], "%s  %s" % [tr("STAT_CDR"), stat_value("cdr", s)],
		"%s  %s" % [tr("STAT_EN"), stat_value("en_max", s)],
		tr("CHAR_UI_PROMOTION_BONUS") % roundi(profile.rules.promotion_stat_bonus * 100.0 * prog.promotion_of(selected)),
	])
	for i in lines.size():
		_label(Rect2(r.position + Vector2(40, 30 + i * 58), Vector2(r.size.x - 80, 56)), lines[i], 30, Color.WHITE)
	_button(Rect2(r.position + Vector2(r.size.x - 220, r.size.y - 80), Vector2(200, 64)), tr("UI_BACK"), 28, intercept_back)


# Ảnh 2: vũ khí.
func _build_weapon_tab() -> void:
	var p := "weapon_tab."
	var uid := profile.inventory.equipped_uid(selected, "weapon")
	var d := profile.inventory.equipment_def_of(uid) if uid != "" else null
	_label(layout.rect(p + "name"), tr(d.name_key) if d else tr("CHAR_UI_EMPTY"), layout.font(p + "name", 46), Color.WHITE).name = "WeaponName"
	var cdef := char_def(selected)
	var wt := d.weapon_type if d and d.weapon_type != "" else (cdef.weapon_type if cdef else "")
	_label(layout.rect(p + "type"), "◈ " + tr("WEAPON_TYPE_" + wt.to_upper()) if wt != "" else "", layout.font(p + "type", 34), Color.WHITE)
	if d:
		_panel(layout.rect(p + "level"), Color(0.05, 0.05, 0.08, 0.95))
		_label(layout.rect(p + "level"), "Lv.%d" % profile.inventory.equipment_level(uid), layout.font(p + "level", 30), Color.WHITE,
				HORIZONTAL_ALIGNMENT_CENTER)
		_label(layout.rect(p + "stars"), _stars(d.rarity), layout.font(p + "stars", 40), layout.color("star", Color.GOLD))
	# Chỉ số ẩn ở tab này (owner 2026-11-15): bấm ảnh hoặc nút Chi tiết để xem màn chi tiết vũ khí.
	var art_r := layout.rect(p + "art")
	_art(art_r, _equip_art(d), layout.text(p + "art.placeholder_label", ""), Rect2(0, 0, 1, 1), "WeaponArt")
	if d:
		_badge(layout.rect(p + "badge"), "+%d" % profile.inventory.equipment_level(uid), layout.font(p + "badge", 36))
		var ab := _button(art_r, "", 10, open_weapon_detail, false, "WeaponArtButton")
		ab.add_theme_stylebox_override("normal", _style(Color(0, 0, 0, 0)))
		ab.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.3)))
	var db := _button(layout.rect(p + "detail_button"), layout.label(p + "detail_button"), layout.font(p + "detail_button", 32),
			open_weapon_detail, false, "WeaponDetailButton")
	db.disabled = d == null
	_button(layout.rect(p + "change_button"), "⟳  " + layout.label(p + "change_button"), layout.font(p + "change_button", 32),
			open_picker.bind("weapon"), false, "ChangeWeaponButton")


## Chỉ số cộng của món ở cấp `level` (âm = cấp hiện tại): mảng [tên, giá trị].
func equip_stats(uid: String, level := -1) -> Array:
	var d := profile.inventory.equipment_def_of(uid)
	if d == null:
		return []
	var lv := profile.inventory.equipment_level(uid) if level < 0 else level
	var m := d.flat_multiplier(lv, maxi(profile.inventory.level_cap(uid), lv))
	var out: Array = []
	if d.atk != 0.0:
		out.append([tr("STAT_ATK"), "+%d" % roundi(d.atk * m)])
	if d.max_hp != 0.0:
		out.append([tr("STAT_HP"), "+%d" % roundi(d.max_hp * m)])
	if d.def != 0.0:
		out.append([tr("STAT_DEF"), "+%d" % roundi(d.def * m)])
	if d.crit_rate != 0.0:
		out.append([tr("STAT_CRIT"), "+%d%%" % roundi(d.crit_rate * 100.0)])
	if d.crit_damage != 0.0:
		out.append([tr("STAT_CRIT_DAMAGE"), "+%d%%" % roundi(d.crit_damage * 100.0)])
	if d.cdr != 0.0:
		out.append([tr("STAT_CDR"), "+%d%%" % roundi(d.cdr * 100.0)])
	return out


func _equip_stat_line(uid: String) -> String:
	var parts := PackedStringArray()
	for s: Array in equip_stats(uid):
		parts.append("%s %s" % [s[0], s[1]])
	return " · ".join(parts)


## Mở bảng thông tin vũ khí đang mặc.
func open_weapon_detail() -> void:
	open_equipment_detail(profile.inventory.equipped_uid(selected, "weapon"), "weapon")


## Mở bảng thông tin món `uid`; `return_tab` = tab quay về khi bấm Trở về ("" = rời màn).
func open_equipment_detail(uid: String, return_tab := "weapon") -> void:
	if uid == "" or not profile.inventory.owns(uid):
		return
	detail_uid = uid
	detail_return = return_tab
	detail_tab = "skill"
	view = View.WEAPON_DETAIL
	picker = ""
	notice = ""
	refresh()


func open_lore() -> void:
	lore_open = true
	refresh()


## Bảng giai thoại: tên món + đoạn chuyện dài (cuộn được).
func _build_lore() -> void:
	var d := profile.inventory.equipment_def_of(detail_uid)
	if d == null:
		return
	var r := layout.rect("lore_panel", Rect2(layout.view_size.x * 0.5 - 600, 120, 1200, 840))
	var dim := _panel(Rect2(Vector2.ZERO, layout.view_size), Color(0, 0, 0, 0.6), "LoreDim")
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := layout.color("panel_light", Color(0.16, 0.18, 0.24))
	bg.a = 1.0
	_panel(r, bg, "LorePanel")
	_label(Rect2(r.position + Vector2(30, 14), Vector2(r.size.x - 280, 60)), tr(d.name_key), 38, layout.color("accent", Color.ORANGE))
	_button(Rect2(r.position + Vector2(r.size.x - 220, 14), Vector2(200, 60)), tr("UI_BACK"), 28, intercept_back, false, "LoreClose")
	var t := RichTextLabel.new()
	t.name = "LoreText"
	t.add_theme_font_size_override("normal_font_size", layout.font("lore_panel", 28))
	t.text = tr(d.name_key + "_LORE")
	t.mouse_filter = Control.MOUSE_FILTER_PASS
	_place(t, Rect2(r.position + Vector2(30, 90), r.size - Vector2(60, 110)))


func open_detail_tab(t: String) -> void:
	detail_tab = t
	refresh()


## Số La Mã cho bậc (0 → "0").
static func roman(n: int) -> String:
	var vals := [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
	var out := ""
	for v: Array in vals:
		while n >= int(v[0]):
			out += str(v[1])
			n -= int(v[0])
	return out if out != "" else "0"


# ---------- Chi tiết vũ khí (owner 2026-11-15) ----------

func _build_weapon_detail() -> void:
	var p := "weapon_detail."
	var inv := profile.inventory
	var uid := detail_uid
	var d := inv.equipment_def_of(uid) if inv.owns(uid) else null
	if d == null:
		view = View.DETAIL
		tab = detail_return if detail_return != "" else "weapon"
		_build_detail()
		return
	var is_weapon := d.slot == "weapon"
	var lv := inv.equipment_level(uid)
	var cap := inv.level_cap(uid)
	var mt := inv.max_tier(uid)
	var tier := inv.equipment_tier(uid)
	# Trái: tên, loại, ảnh, người đeo, bậc, sao. Vết thánh (owner 2026-11-15): ảnh full art phủ nửa trái, chữ đè lên ảnh
	# không có ô nền; vũ khí giữ khung cũ.
	var text_fn := _label if is_weapon else _overlay_label
	if is_weapon:
		_panel(layout.rect(p + "left_panel"), Color(0.06, 0.07, 0.1, 0.8))
	else:
		# Cả người (vừa theo chiều cao khung), đặt lệch phải để chữ bên trái đè lên nền ảnh.
		var full_r := layout.rect(p + "stigma_art", Rect2(180, 90, 800, 990))
		_art(full_r, _equip_art(d), tr("CHAR_UI_STIGMA_ART") % tr("SLOT_SHORT_" + d.slot.to_upper()), Rect2(0, 0, 1, 1),
				"WeaponDetailArt")
		if _equip_art(d):
			# Ảnh vết thánh bị xén ở mép (biểu tượng phóng to): mờ dần hai bên và đáy vào màu nền để hòa vào màn.
			var tex := _equip_art(d)
			var k := minf(full_r.size.x / tex.get_width(), full_r.size.y / tex.get_height())
			var shown := Vector2(tex.get_width(), tex.get_height()) * k
			_edge_fade(Rect2(full_r.position + (full_r.size - shown) * 0.5, shown), layout.num(p + "stigma_art.fade", 110))
	text_fn.call(layout.rect(p + "name"), tr(d.name_key), layout.font(p + "name", 42), Color.WHITE).name = "WeaponDetailName"
	var type_text := ""
	if is_weapon:
		var wt := d.weapon_type if d.weapon_type != "" else (char_def(selected).weapon_type if char_def(selected) else "")
		type_text = "◈ " + tr("WEAPON_TYPE_" + wt.to_upper()) if wt != "" else ""
	else:
		type_text = "◈ " + tr("SLOT_" + d.slot.to_upper())
	text_fn.call(layout.rect(p + "type"), type_text, layout.font(p + "type", 28), layout.color("text_dim", Color.GRAY))
	if is_weapon:
		_art(layout.rect(p + "art"), _equip_art(d), layout.text(p + "art.placeholder_label", ""), Rect2(0, 0, 1, 1), "WeaponDetailArt")
	var who := inv.equipped_by(uid)
	text_fn.call(layout.rect(p + "wearer"), tr("WEAPON_UI_WEARER") % suit_label(who) if who != "" else tr("BAG_NOT_IN_USE"),
			layout.font(p + "wearer", 26), Color.WHITE).name = "WeaponWearer"
	if mt > 0:
		text_fn.call(layout.rect(p + "tier"), tr("WEAPON_UI_TIER") % [tier, mt], layout.font(p + "tier", 34),
				layout.color("accent", Color.ORANGE)).name = "WeaponTier"
	text_fn.call(layout.rect(p + "stars"), _stars(d.rarity), layout.font(p + "stars", 44), layout.color("star", Color.GOLD))
	if detail_return != "" and who == selected:
		_button(layout.rect(p + "change_button"), "⟳  " + layout.label(p + "change_button"), layout.font(p + "change_button", 30),
				open_picker.bind(d.slot), false, "WeaponDetailChange")
	# Mô tả ngắn (khóa <name_key>_DESC, owner 2026-11-15: ~25–30 chữ, không bị cắt); có giai thoại (<name_key>_LORE)
	# thì thêm nút "Giai thoại" ở góc ô.
	var lore_r := layout.rect(p + "lore")
	if is_weapon:
		_panel(lore_r, Color(0.06, 0.07, 0.1, 0.8))
	var dk := d.name_key + "_DESC"
	var has_lore := tr(d.name_key + "_LORE") != d.name_key + "_LORE"
	var desc_r := lore_r.grow(-20)
	if has_lore:
		var lb := layout.rect(p + "lore_button")
		_button(lb, "📜 " + layout.label(p + "lore_button"), layout.font(p + "lore_button", 24), open_lore, false, "LoreButton")
		desc_r.size.y -= lb.size.y + 6
	text_fn.call(desc_r, tr(dk) if tr(dk) != dk else tr("WEAPON_UI_NO_LORE"), layout.font(p + "lore", 28), Color.WHITE).name = "WeaponLore"
	# Cấp: LV hiện tại / giới hạn của bậc; gợi ý nâng bậc hoặc vướng cấp người chơi.
	if is_weapon:
		_panel(layout.rect(p + "level_panel"), Color(0.06, 0.07, 0.1, 0.8))
	text_fn.call(layout.rect(p + "level_text"), "LV. %d / %d" % [lv, cap], layout.font(p + "level_text", 44), Color.WHITE).name = "WeaponLevel"
	text_fn.call(layout.rect(p + "level_hint"), level_hint(uid), layout.font(p + "level_hint", 24), layout.color("text_dim", Color.GRAY),
			HORIZONTAL_ALIGNMENT_RIGHT).name = "WeaponLevelHint"
	var bar := layout.rect(p + "level_bar")
	_panel(bar, Color(1, 1, 1, 0.15))
	_panel(Rect2(bar.position, Vector2(bar.size.x * (float(lv) / cap if cap > 0 else 1.0), bar.size.y)), layout.color("exp_bar", Color.CYAN))
	# Phải: chỉ số.
	_panel(layout.rect(p + "stats_panel"), Color(0.06, 0.07, 0.1, 0.8))
	var so := layout.point(p + "stat_rows", "origin", Vector2(1050, 140))
	var cv: Variant = layout.get_value(p + "stat_rows.cell", [400, 56])
	var cell := Vector2(float(cv[0]), float(cv[1]))
	var cols := int(layout.num(p + "stat_rows.columns", 2))
	var stats := equip_stats(uid)
	for i in stats.size():
		var r := Rect2(so + Vector2((i % cols) * cell.x, (i / cols) * cell.y), cell)
		_label(r, str(stats[i][0]), layout.font(p + "stat_rows", 30), layout.color("accent_blue", Color.SKY_BLUE))
		_label(Rect2(r.position, r.size - Vector2(30, 0)), str(stats[i][1]), layout.font(p + "stat_rows", 30) + 6, Color.WHITE,
				HORIZONTAL_ALIGNMENT_RIGHT).name = "WeaponStat%d" % i
	# Phải: kĩ năng. Vũ khí: một tiêu đề; vết thánh: 3 tab (ảnh tham chiếu owner 2026-11-15).
	_panel(layout.rect(p + "skill_panel"), Color(0.06, 0.07, 0.1, 0.8))
	var hr := layout.rect(p + "skill_header")
	var text_r := layout.rect(p + "skill_text")
	var body := ""
	if is_weapon:
		_panel(hr, layout.color("accent_blue", Color.SKY_BLUE).darkened(0.45))
		_label(Rect2(hr.position + Vector2(24, 0), hr.size - Vector2(24, 0)), tr("WEAPON_UI_SKILLS"), layout.font(p + "skill_header", 34), Color.WHITE)
		body = weapon_skill_text(uid)
	else:
		var tabs := ["skill", "affix", "set"]
		var w := (hr.size.x - 20.0) / 3.0
		for i in tabs.size():
			_button(Rect2(hr.position + Vector2(i * (w + 10.0), 0), Vector2(w, hr.size.y)), tr("STIGMA_UI_TAB_" + tabs[i].to_upper()),
					layout.font(p + "skill_header", 34) - 4, open_detail_tab.bind(tabs[i]), detail_tab == tabs[i], "StigmaTab_" + tabs[i])
		match detail_tab:
			"affix":
				body = affix_text(uid)
				var rb := _button(Rect2(text_r.position.x, text_r.end.y - 70, text_r.size.x, 64), tr("STIGMA_UI_REROLL"),
						layout.font(p + "skill_text", 26) + 2, open_picker.bind("reroll"), false, "RerollButton")
				rb.disabled = inv.affixes_of(uid).is_empty()
				text_r.size.y -= 80
			"set":
				body = set_text(uid)
			_:
				body = stigma_skill_text(uid)
	var st := RichTextLabel.new()
	st.name = "WeaponSkills"
	st.bbcode_enabled = true
	st.add_theme_font_size_override("normal_font_size", layout.font(p + "skill_text", 26))
	st.add_theme_font_size_override("bold_font_size", layout.font(p + "skill_text", 26) + 2)
	st.text = body
	st.mouse_filter = Control.MOUSE_FILTER_PASS
	_place(st, text_r)
	# Nút: Cường hóa, Nâng bậc.
	var maxed := lv >= cap and tier >= mt
	var eb := _button(layout.rect(p + "enhance_button"), tr("WEAPON_UI_MAXED") if maxed else layout.label(p + "enhance_button"),
			layout.font(p + "enhance_button", 36), open_picker.bind("enhance"), false, "EnhanceButton")
	eb.disabled = maxed
	var ab := _button(layout.rect(p + "ascend_button"), layout.label(p + "ascend_button"), layout.font(p + "ascend_button", 36),
			open_picker.bind("ascend"), lv >= cap and tier < mt, "AscendButton")
	ab.disabled = tier >= mt


## Dòng gợi ý dưới thanh cấp: đạt giới hạn bậc → nâng bậc mở thêm N cấp; vướng cấp người chơi; đã tối đa.
func level_hint(uid: String) -> String:
	var inv := profile.inventory
	var lv := inv.equipment_level(uid)
	var cap := inv.level_cap(uid)
	if lv >= cap:
		var caps := inv.level_caps(uid)
		var t := inv.equipment_tier(uid)
		return tr("WEAPON_UI_CAP_HINT") % (caps[t + 1] - cap) if t + 1 < caps.size() else tr("WEAPON_UI_MAXED")
	if lv >= inv.captain_level():
		return tr("REASON_LEVEL_CAP")
	return ""


## Tab "Skill vết thánh": hiệu ứng riêng của món (5★), theo cùng cách trình bày với vũ khí.
func stigma_skill_text(uid: String) -> String:
	var d := profile.inventory.equipment_def_of(uid)
	if d == null:
		return ""
	var lines := _effect_lines(d)
	return "\n".join(lines) if not lines.is_empty() else tr("STIGMA_UI_NO_SKILL")


## Tab "Skill phụ tố": các dòng phụ tố hiện tại.
func affix_text(uid: String) -> String:
	var inv := profile.inventory
	var parts := PackedStringArray(["[b][color=#7FD4FF]%s[/color][/b]" % tr("STIGMA_UI_AFFIX_NOW")])
	var rows := affix_lines(inv.affixes_of(uid))
	parts.append_array(rows if not rows.is_empty() else PackedStringArray([tr("STIGMA_UI_NO_AFFIX")]))
	return "\n".join(parts)


## "◆ Tên phụ tố  +giá trị" cho từng dòng.
func affix_lines(arr: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for a: Dictionary in arr:
		var ad := PlayerProfile.affix_defs().get_def(str(a["id"])) as AffixDef
		if ad:
			out.append("◆ %s  [color=#7FD4FF]%s[/color]" % [tr(ad.name_key), ad.value_text(float(a["value"]))])
	return out


## Tab "Skill set": tên bộ, hiệu ứng 2 món và 3 món; dòng đang kích hoạt (theo số món người đeo đang mặc) sáng màu.
func set_text(uid: String) -> String:
	var d := profile.inventory.equipment_def_of(uid)
	if d == null or d.set_id == "":
		return tr("STIGMA_UI_NO_SET")
	var sd := EquipmentResolver.set_defs().get_def(d.set_id) as StigmaSetDef
	if sd == null:
		return tr("STIGMA_UI_NO_SET")
	var who := profile.inventory.equipped_by(uid)
	var worn := 0
	if who != "":
		for slot in EquipmentDef.STIGMA_SLOTS:
			var od := profile.inventory.equipment_def_of(profile.inventory.equipped_uid(who, slot))
			if od and od.set_id == d.set_id:
				worn += 1
	var parts := PackedStringArray()
	for n in [2, 3]:
		var on: bool = worn >= int(n)
		var col: String = "#7FD4FF" if on else "#8A8FA3"
		parts.append("[b][color=%s]%s[/color][/b]" % [col, tr("STIGMA_UI_SET_PIECES") % [tr(sd.name_key), n]])
		var effects: Array[EquipEffect] = sd.bonus_2 if n == 2 else sd.bonus_3
		for e in effects:
			if e and e.note != "":
				parts.append(("• %s" if on else "[color=#8A8FA3]• %s[/color]") % e.note)
		parts.append("")
	if sd.owner_id != "":
		parts.append("[color=#B8BCCB]%s[/color]" % (tr("WEAPON_UI_WHEN_EQUIPPED") % suit_label(sd.owner_id)).trim_suffix(":"))
	return "\n".join(parts).strip_edges()


## BBCode phần kĩ năng: chủ động = Kĩ năng vũ khí của giáp đang mặc (kĩ năng theo giáp, CHARACTER_SKILLS); bị động =
## các dòng hiệu ứng của vũ khí (EquipEffect.note), dòng độc quyền ghi tên giáp chủ.
func weapon_skill_text(uid: String) -> String:
	var d := profile.inventory.equipment_def_of(uid)
	if d == null:
		return ""
	var who := profile.inventory.equipped_by(uid)
	if who == "":
		who = d.owner_id if d.owner_id != "" and profile.progression.owns(d.owner_id) else selected
	var hl := "[color=#FFB347]%s[/color]"
	var parts := PackedStringArray()
	parts.append("[b]" + hl % ("%s — %s" % [tr("WEAPON_UI_ACTIVE"), SkillText.skill_name(who, "weapon")]) + "[/b]")
	var skills := skills_of(who)
	var lv := profile.progression.skill_level(who, "weapon")
	var subs := SkillText.skills_in_group(skills, "weapon")
	for k in subs:
		parts.append(SkillText.describe(skills[k], lv, _rules, true))
	parts.append("[color=#B8BCCB]%s[/color]" % tr("WEAPON_UI_ACTIVE_NOTE"))
	parts.append("")
	parts.append("[b]" + hl % tr("WEAPON_UI_PASSIVE") + "[/b]")
	var lines := _effect_lines(d)
	parts.append_array(lines if not lines.is_empty() else PackedStringArray([tr("WEAPON_UI_NO_PASSIVE")]))
	return "\n".join(parts)


## Dòng hiệu ứng của món (owner 2026-11-15): hiệu ứng chung trước; hiệu ứng độc quyền gom dưới "Khi <tên giáp> trang
## bị:", mỗi dòng một hiệu ứng (không lặp tên nhân vật).
func _effect_lines(d: EquipmentDef) -> PackedStringArray:
	var parts := PackedStringArray()
	var common := PackedStringArray()
	var exclusive := PackedStringArray()
	for e in d.effects:
		if e == null or e.note == "":
			continue
		if e.exclusive and d.owner_id != "":
			exclusive.append("• " + e.note)
		else:
			common.append("• " + e.note)
	parts.append_array(common)
	if not exclusive.is_empty():
		if not common.is_empty():
			parts.append("")
		parts.append("[b][color=#7FD4FF]%s[/color][/b]" % (tr("WEAPON_UI_WHEN_EQUIPPED") % suit_label(d.owner_id)))
		parts.append_array(exclusive)
	return parts


## Tên giáp (vd "Hỏa Diễm Mãnh Liệt"); chưa có tên giáp thì tên nhân vật.
func suit_label(id: String) -> String:
	var s := suit_name(id)
	return s if s != "" else char_name(id)


func enhance_with(material_id: String) -> void:
	commit(profile.inventory.enhance(detail_uid, material_id))


func ascend_weapon() -> void:
	var reason := profile.inventory.ascend(detail_uid)
	if reason == "":
		picker = ""
	commit(reason)


func reroll() -> void:
	commit(profile.inventory.reroll_affixes(detail_uid))


## Chọn kết quả tẩy: giữ phụ tố mới hoặc cũ, rồi đóng bảng.
func confirm_reroll(keep_new: bool) -> void:
	var reason := profile.inventory.confirm_reroll(detail_uid, keep_new)
	if reason == "":
		picker = ""
	commit(reason)


# Ảnh 3: vết thánh.
func _build_stigma_art() -> void:
	var p := "stigma_tab."
	# Ảnh lưng: chỉ nhận splash "stigma" (không dùng chibi nhìn trước thay thế); chưa có thì vẽ placeholder.
	_art(layout.rect(p + "back_art"), splash(selected, "stigma", false), layout.text(p + "back_art.placeholder_label", ""),
			Rect2(0, 0, 1, 1), "BackArt")
	for i in EquipmentDef.STIGMA_SLOTS.size():
		var slot := EquipmentDef.STIGMA_SLOTS[i]
		var r := layout.rect_in(p + "slot_icons.rects", i)
		var uid := profile.inventory.equipped_uid(selected, slot)
		var b := _button(r, tr("SLOT_SHORT_" + slot.to_upper()), int(r.size.x * 0.3), open_picker.bind(slot), uid != "", "StigmaSlot%d" % i)
		b.add_theme_stylebox_override("normal", _style(Color(0.55, 0.45, 0.85, 0.75) if uid != "" else Color(0.2, 0.2, 0.3, 0.6),
				Color.WHITE, int(r.size.x * 0.2)))


func _build_stigma_tab() -> void:
	var p := "stigma_tab."
	var lines := PackedStringArray()
	for slot in EquipmentDef.STIGMA_SLOTS:
		var uid := profile.inventory.equipped_uid(selected, slot)
		if uid != "":
			lines.append("[%s] %s: %s" % [tr("SLOT_SHORT_" + slot.to_upper()), tr(profile.inventory.equipment_def_of(uid).name_key),
					_equip_stat_line(uid)])
	lines.append(tr("CHAR_UI_NO_SET_BONUS"))
	var box := layout.rect(p + "set_text")
	_panel(box, Color(0, 0, 0, 0.6))
	_label(box.grow(-14), "\n".join(lines), layout.font(p + "set_text", 28), Color.WHITE).name = "StigmaText"
	var anchor := layout.text(p + "cards.anchor", "right")
	var art_h := layout.num(p + "cards.art_height", 570)
	var ch := layout.num(p + "cards.change_height", 66)
	for i in EquipmentDef.STIGMA_SLOTS.size():
		var slot := EquipmentDef.STIGMA_SLOTS[i]
		var r := layout.rect_in(p + "cards.rects", i, anchor)
		var uid := profile.inventory.equipped_uid(selected, slot)
		var d := profile.inventory.equipment_def_of(uid) if uid != "" else null
		# Owner 2026-11-15: ảnh full art phủ cả thẻ (trừ nút Đổi); Lv, tên, sao đè lên ảnh, không có nền ô chữ.
		_panel(r, Color(0.1, 0.11, 0.16, 0.95))
		var art_r := Rect2(r.position, Vector2(r.size.x, r.size.y - ch))
		var tex := _equip_art(d)
		_art(art_r, tex, tr("CHAR_UI_STIGMA_ART") % tr("SLOT_SHORT_" + slot.to_upper()),
				PlaceholderArt.cover_crop(tex, art_r.size), "StigmaArt%d" % i)
		var fs := layout.font(p + "cards", 34)
		var bottom := art_r.end.y
		if d:
			_overlay_label(Rect2(art_r.position.x + 10, bottom - 240, art_r.size.x - 20, 44), "Lv.%d" % profile.inventory.equipment_level(uid),
					fs, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
			_overlay_label(Rect2(art_r.position.x + 10, bottom - 56, art_r.size.x - 20, 50), _stars(d.rarity), 40,
					layout.color("star", Color.GOLD))
		# Tên canh đáy, ngay trên hàng sao (tên dài 2–3 dòng mọc lên trên, không đè sao).
		var nl := _overlay_label(Rect2(art_r.position.x + 10, bottom - 196, art_r.size.x - 20, 140), tr(d.name_key) if d else tr("CHAR_UI_EMPTY"),
				fs - 4, Color.WHITE)
		nl.name = "StigmaName%d" % i
		nl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		if d:
			var cb := _button(art_r, "", 10, open_equipment_detail.bind(uid, "stigma"), false, "StigmaCard%d" % i)
			cb.add_theme_stylebox_override("normal", _style(Color(0, 0, 0, 0)))
			cb.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.3)))
		_button(Rect2(r.position + Vector2(0, r.size.y - ch), Vector2(r.size.x, ch)), "⟳  " + tr("CHAR_UI_CHANGE"), 32,
				open_picker.bind(slot), false, "ChangeStigma%d" % i)


# Ảnh 5: cây skill.
func _build_skill_tab() -> void:
	var p := "skill_tab."
	_button(layout.rect(p + "demo_button"), "▶  " + layout.label(p + "demo_button"), layout.font(p + "demo_button", 34), Callable())
	var shift := layout.anchor_shift("right")
	var nr := layout.num(p + "node_radius", 62)
	var cr := layout.num(p + "core_radius", 74)
	for node: Dictionary in layout.get_value(p + "nodes", []):
		var g := str(node.get("group", ""))
		var c: Array = node.get("center", [0, 0])
		var radius := cr if bool(node.get("core", false)) else nr
		var center := Vector2(float(c[0]) + shift, float(c[1]))
		var r := Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
		var b := _button(r, SkillText.group_abbr(g), int(radius * 0.4), open_skill.bind(g), false, "SkillNode_%s" % g)
		b.add_theme_stylebox_override("normal", _style(Color(0.2, 0.21, 0.27, 0.95),
				layout.color("node_ring", Color.ROYAL_BLUE) if bool(node.get("core", false)) else Color(1, 1, 1, 0.5), int(radius)))
		var lr: Variant = UiLayout._rect_of(node.get("label_rect"))
		var align := HORIZONTAL_ALIGNMENT_LEFT
		match str(node.get("align", "left")):
			"right":
				align = HORIZONTAL_ALIGNMENT_RIGHT
			"center":
				align = HORIZONTAL_ALIGNMENT_CENTER
		if lr != null:
			var rr: Rect2 = lr
			rr.position.x += shift
			_label(Rect2(rr.position, Vector2(rr.size.x, 40)), SkillText.group_label(g), int(layout.num(p + "label_font", 26)),
					layout.color("accent_blue", Color.SKY_BLUE), align)
			_label(Rect2(rr.position + Vector2(0, 40), Vector2(rr.size.x, rr.size.y - 40)), SkillText.skill_name(selected, g),
					int(layout.num(p + "name_font", 30)), Color.WHITE, align)
		var lp: Array = node.get("level_pos", [])
		if lp.size() == 2 and g in Progression.SKILL_GROUPS:
			_label(Rect2(Vector2(float(lp[0]) + shift, float(lp[1])), Vector2(220, 40)), level_text(g), int(layout.num(p + "level_font", 30)),
					layout.color("accent", Color.ORANGE)).name = "SkillLevel_%s" % g


## "+N" (số cấp đã nâng) hoặc "Đầy cấp".
func level_text(group: String) -> String:
	var lv := profile.progression.skill_level(selected, group)
	if lv >= profile.rules.skill_max_level:
		return tr("CHAR_UI_MAXED")
	return "+%d" % (lv - 1)


# ---------- Ảnh 6: chi tiết một kỹ năng ----------

func _build_skill_detail() -> void:
	var p := "skill_detail."
	var g := skill_group
	var skills := skills_of(selected)
	var subs := SkillText.skills_in_group(skills, g)
	# Cây bên trái: nút gốc + các kỹ năng con.
	var rc := layout.point(p + "tree_root", "center", Vector2(362, 540))
	var rr := layout.num(p + "tree_root.radius", 72)
	var root_b := _button(Rect2(rc - Vector2(rr, rr), Vector2(rr, rr) * 2.0), SkillText.group_abbr(g), int(rr * 0.4),
			Callable(), true, "TreeRoot")
	root_b.add_theme_stylebox_override("normal", _style(Color(0.85, 0.87, 0.95), Color.WHITE, int(rr)))
	var positions: Array = layout.get_value(p + "tree_children.positions", [])
	var cr := layout.num(p + "tree_children.radius", 62)
	var lw := layout.num(p + "tree_children.label_width", 360)
	for i in mini(subs.size(), positions.size()):
		var pos := Vector2(float(positions[i][0]), float(positions[i][1]))
		var link := Line2D.new()
		link.points = PackedVector2Array([rc, pos])
		link.width = 4.0
		link.default_color = Color(1, 1, 1, 0.4)
		_root.add_child(link)
		var b := _button(Rect2(pos - Vector2(cr, cr), Vector2(cr, cr) * 2.0), str(i + 1), int(cr * 0.5), Callable(), false, "TreeChild%d" % i)
		b.add_theme_stylebox_override("normal", _style(Color(0.2, 0.21, 0.27, 0.95), Color(1, 1, 1, 0.5), int(cr)))
		_label(Rect2(pos + Vector2(cr + 16, -cr), Vector2(lw, cr * 2.0)), SkillText.sub_label(subs[i]),
				layout.font(p + "tree_children", 28), Color.WHITE)
	# Bảng bên phải.
	_panel(layout.rect(p + "panel"), Color(0.06, 0.07, 0.1, 0.92))
	_panel(layout.rect(p + "type_box"), Color(0, 0, 0, 0.9))
	_label(layout.rect(p + "type_box"), SkillText.group_label(g), layout.font(p + "type_box", 32), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_label(layout.rect(p + "name_box"), SkillText.skill_name(selected, g), layout.font(p + "name_box", 26), layout.color("accent", Color.ORANGE))
	var upgradable := g in Progression.SKILL_GROUPS
	var lv := profile.progression.skill_level(selected, g) if upgradable else 1
	if upgradable:
		_badge(layout.rect(p + "level_icon"), str(lv), layout.font(p + "level_icon", 24))
	var desc := RichTextLabel.new()
	desc.name = "Description"
	desc.bbcode_enabled = true
	desc.add_theme_font_size_override("normal_font_size", layout.font(p + "description", 28))
	desc.add_theme_font_size_override("bold_font_size", layout.font(p + "description", 28) + 2)
	desc.text = description(g, lv)
	desc.mouse_filter = Control.MOUSE_FILTER_PASS
	_place(desc, layout.rect(p + "description"))
	if upgradable:
		var maxed := lv >= profile.rules.skill_max_level
		var ub := _button(layout.rect(p + "upgrade_button"), tr("CHAR_UI_MAXED") if maxed else tr("CHAR_UI_UPGRADE_SKILL") % profile.rules.skill_upgrade_gold(lv),
				layout.font(p + "upgrade_button", 30), upgrade_skill, false, "UpgradeSkillButton")
		ub.disabled = maxed
	_button(layout.rect(p + "demo_button"), layout.label(p + "demo_button"), layout.font(p + "demo_button", 34), Callable())
	var bt := _button(layout.rect(p + "brief_toggle"), ("☑  " if brief else "☐  ") + layout.label(p + "brief_toggle"),
			layout.font(p + "brief_toggle", 30), toggle_brief, false, "BriefToggle")
	bt.toggle_mode = false
	_button(layout.rect(p + "glossary_button"), "📖 " + layout.label(p + "glossary_button"), layout.font(p + "glossary_button", 26),
			func() -> void:
				glossary_open = true
				refresh(), false, "GlossaryButton")
	# Điều hướng trước / sau.
	var order := SkillText.GROUP_ORDER
	var idx := order.find(g)
	var prev := order[(idx - 1 + order.size()) % order.size()]
	var next := order[(idx + 1) % order.size()]
	var nav := layout.rect(p + "nav")
	_panel(nav, Color(0.12, 0.13, 0.19, 0.95))
	_button(Rect2(nav.position + Vector2(7, 7), Vector2(nav.size.y - 14, nav.size.y - 14)), "<", 36, open_skill.bind(prev), false, "NavPrev")
	_button(Rect2(nav.end - Vector2(nav.size.y - 7, nav.size.y - 7), Vector2(nav.size.y - 14, nav.size.y - 14)), ">", 36,
			open_skill.bind(next), false, "NavNext")
	_label(nav, SkillText.group_label(g), layout.font(p + "nav", 34), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	var pl := _label(layout.rect(p + "nav_prev_name"), SkillText.group_label(prev), layout.font(p + "nav_prev_name", 30),
			layout.color("text_dim", Color.GRAY), HORIZONTAL_ALIGNMENT_RIGHT)
	var nl := _label(layout.rect(p + "nav_next_name"), SkillText.group_label(next), layout.font(p + "nav_next_name", 30),
			layout.color("text_dim", Color.GRAY))
	for l in [pl, nl]:
		(l as Label).autowrap_mode = TextServer.AUTOWRAP_OFF
		(l as Label).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


## Mô tả nhóm kỹ năng: nội tại lấy câu trong localization; các nhóm khác ghép mô tả từng kỹ năng con.
func description(group: String, level: int) -> String:
	if group == SkillText.STATUS_GROUP_PASSIVE:
		return SkillText.passive_text(char_def(selected))
	var skills := skills_of(selected)
	var subs := SkillText.skills_in_group(skills, group)
	if subs.is_empty():
		return tr("SKILLTXT_NOT_IN_SLICE")
	var parts := PackedStringArray()
	for k in subs:
		parts.append("[b]%s[/b]\n%s" % [SkillText.sub_label(k), SkillText.describe(skills[k], level, _rules, brief)])
	if level < profile.rules.skill_max_level and _rules:
		parts.append(tr("SKILLTXT_NEXT_LEVEL") % [level + 1, roundi(_rules.skill_level_scaling * 100.0)])
	return "\n\n".join(parts)


func upgrade_skill() -> void:
	commit(profile.progression.upgrade_skill(selected, skill_group))


func toggle_brief() -> void:
	brief = not brief
	refresh()


func _build_glossary() -> void:
	var r := Rect2(layout.view_size.x * 0.5 - 520, 140, 1040, 800)
	_panel(r, layout.color("panel_light", Color(0.16, 0.18, 0.24, 0.97)), "Glossary")
	_label(Rect2(r.position + Vector2(30, 16), Vector2(r.size.x - 60, 56)), tr("CHAR_UI_GLOSSARY"), 36, Color.WHITE)
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.add_theme_font_size_override("normal_font_size", 26)
	t.text = "\n".join(SkillText.glossary_lines(StatusLibrary.load_dir()))
	_place(t, Rect2(r.position + Vector2(30, 80), Vector2(r.size.x - 60, r.size.y - 170)))
	_button(Rect2(r.end - Vector2(230, 80), Vector2(200, 64)), tr("UI_BACK"), 28, intercept_back)


# ---------- Bảng chọn: sách EXP, vũ khí, vết thánh ----------

func open_picker(kind: String) -> void:
	picker = kind
	notice = ""
	refresh()


## Danh sách uid trang bị trong kho cho ô `slot` (vũ khí: cùng loại với nhân vật), món đang mặc lên đầu.
func candidates(slot: String) -> PackedStringArray:
	var out := PackedStringArray()
	var cdef := char_def(selected)
	var cur := profile.inventory.equipped_uid(selected, slot)
	if cur != "":
		out.append(cur)
	for uid in profile.inventory.equipment_uids():
		var d := profile.inventory.equipment_def_of(uid)
		if d == null or d.slot != slot or uid == cur:
			continue
		if slot == "weapon" and d.weapon_type != "" and cdef and cdef.weapon_type != "" and d.weapon_type != cdef.weapon_type:
			continue
		out.append(uid)
	return out


func equip(uid: String) -> void:
	var reason := profile.inventory.equip(selected, uid)
	if reason == "":
		picker = ""
	commit(reason)


func unequip(slot: String) -> void:
	profile.inventory.unequip(selected, slot)
	picker = ""
	commit()


func use_exp(material_id: String) -> void:
	commit(profile.progression.use_exp_material(selected, material_id, 1))


func _build_picker() -> void:
	var r := layout.rect("picker", Rect2(460, 140, 1000, 800))
	var fs := layout.font("picker", 30)
	var rh := layout.num("picker.row_height", 96)
	var dim := _panel(Rect2(Vector2.ZERO, layout.view_size), Color(0, 0, 0, 0.6), "PickerDim")   # làm tối, chặn bấm xuyên
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var pbg := layout.color("panel_light", Color(0.16, 0.18, 0.24))
	pbg.a = 1.0
	_panel(r, pbg, "Picker")
	var titles := {"exp": tr("CHAR_UI_LEVEL_UP"), "enhance": tr("CHAR_ENHANCE"), "ascend": tr("WEAPON_UI_ASCEND"),
			"reroll": tr("STIGMA_UI_REROLL")}
	var title: String = titles.get(picker, tr("SLOT_" + picker.to_upper()))
	_label(Rect2(r.position + Vector2(30, 14), Vector2(r.size.x - 260, 60)), title, 38, Color.WHITE)
	_button(Rect2(r.position + Vector2(r.size.x - 220, 14), Vector2(200, 60)), tr("UI_BACK"), 28, intercept_back, false, "PickerClose")
	var y := r.position.y + 90
	var rows := 0
	if picker == "reroll":
		_build_reroll_picker(r, fs)
		return
	if picker == "enhance" or picker == "ascend":
		_build_weapon_upgrade_picker(r, fs, rh)
		return
	if picker == "exp":
		for mat_id in PlayerProfile.item_defs().ids():
			var d := PlayerProfile.item_defs().get_def(mat_id) as ItemDef
			if d.kind != ItemDef.Kind.EXP:
				continue
			var n := profile.inventory.material_count(mat_id)
			_label(Rect2(r.position.x + 30, y, r.size.x - 300, rh - 10), "%s ×%d  (+%d EXP, %d %s)" % [tr(d.name_key), n, d.value,
					profile.progression.exp_material_gold_cost(mat_id, 1), tr("CURRENCY_GOLD")], fs, Color.WHITE)
			var b := _button(Rect2(r.end.x - 250, y + 8, 220, rh - 26), tr("CHAR_UI_USE"), fs, use_exp.bind(mat_id), false, "UseExp_%s" % mat_id)
			b.disabled = n <= 0
			y += rh
			rows += 1
	else:
		var cur := profile.inventory.equipped_uid(selected, picker)
		for uid in candidates(picker):
			if y + rh > r.end.y:
				break
			var d := profile.inventory.equipment_def_of(uid)
			var who := profile.inventory.equipped_by(uid)
			var tail := "" if who == "" else "  (%s)" % char_name(who)
			_label(Rect2(r.position.x + 30, y, r.size.x - 300, rh - 10), "%s  %s  Lv.%d%s\n%s" % [tr(d.name_key), _stars(d.rarity),
					profile.inventory.equipment_level(uid), tail, _equip_stat_line(uid)], fs - 4, Color.WHITE)
			if uid == cur:
				_button(Rect2(r.end.x - 250, y + 8, 220, rh - 26), tr("CHAR_UNEQUIP"), fs, unequip.bind(picker), false, "Unequip")
			else:
				_button(Rect2(r.end.x - 250, y + 8, 220, rh - 26), tr("CHAR_UI_EQUIP"), fs, equip.bind(uid), false, "Equip_%s" % uid)
			y += rh
			rows += 1
	if rows == 0:
		_label(Rect2(r.position + Vector2(30, 100), Vector2(r.size.x - 60, 80)), tr("CHAR_UI_NOTHING"), fs, layout.color("text_dim", Color.GRAY))


## Bảng tẩy phụ tố: phụ tố hiện tại, giá; sau khi tẩy hiện phụ tố mới bên cạnh và hai nút Giữ mới / Giữ cũ.
func _build_reroll_picker(r: Rect2, fs: int) -> void:
	var inv := profile.inventory
	var uid := detail_uid
	var x := r.position.x + 30
	var half := (r.size.x - 90) * 0.5
	var y := r.position.y + 100
	var pending := inv.pending_affixes(uid)
	_label(Rect2(x, y, half, 50), tr("STIGMA_UI_AFFIX_NOW"), fs, layout.color("accent_blue", Color.SKY_BLUE))
	var now_l := _label(Rect2(x, y + 56, half, 220), "\n".join(_plain(affix_lines(inv.affixes_of(uid)))), fs - 2, Color.WHITE)
	now_l.name = "AffixNow"
	now_l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	if not pending.is_empty():
		_label(Rect2(x + half + 30, y, half, 50), tr("STIGMA_UI_AFFIX_NEW"), fs, layout.color("accent", Color.ORANGE))
		var new_l := _label(Rect2(x + half + 30, y + 56, half, 220), "\n".join(_plain(affix_lines(pending))), fs - 2, Color.WHITE)
		new_l.name = "AffixNew"
		new_l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		_button(Rect2(r.position.x + r.size.x * 0.5 - 380, r.end.y - 110, 360, 80), tr("STIGMA_UI_KEEP_OLD"), fs + 2,
				confirm_reroll.bind(false), false, "KeepOld")
		_button(Rect2(r.position.x + r.size.x * 0.5 + 20, r.end.y - 110, 360, 80), tr("STIGMA_UI_KEEP_NEW"), fs + 2,
				confirm_reroll.bind(true), true, "KeepNew")
		return
	var md := PlayerProfile.item_defs().get_def(profile.rules.affix_reroll_material) as ItemDef
	_label(Rect2(x, y + 300, r.size.x - 60, 50), tr("STIGMA_UI_REROLL_COST") % [tr(md.name_key) if md else "?",
			inv.material_count(profile.rules.affix_reroll_material), inv.reroll_cost(uid)], fs, Color.WHITE).name = "RerollCost"
	var reason := inv.check_reroll(uid)
	_label(Rect2(x, y + 360, r.size.x - 60, 50), tr("REASON_" + reason.to_upper()) if reason != "" else "", fs - 2,
			layout.color("text_dim", Color.GRAY)).name = "RerollReason"
	var b := _button(Rect2(r.position.x + r.size.x * 0.5 - 180, r.end.y - 110, 360, 80), tr("STIGMA_UI_REROLL"), fs + 2,
			reroll, reason == "", "RerollConfirm")
	b.disabled = reason != ""


## Bỏ thẻ BBCode (Label không hiểu BBCode).
func _plain(lines: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	var re := RegEx.create_from_string("\\[/?[a-z]+(=[^\\]]*)?\\]")
	for l in lines:
		out.append(re.sub(l, "", true))
	return out


## Bảng cường hóa (chọn nguyên liệu, xem chỉ số cấp kế) hoặc nâng bậc (bậc, giới hạn cấp, giá, xác nhận) của món
## `detail_uid`.
func _build_weapon_upgrade_picker(r: Rect2, fs: int, rh: float) -> void:
	var inv := profile.inventory
	var uid := detail_uid
	if inv.equipment_def_of(uid) == null:
		_label(Rect2(r.position + Vector2(30, 100), Vector2(r.size.x - 60, 80)), tr("CHAR_UI_NOTHING"), fs, layout.color("text_dim", Color.GRAY))
		return
	var lv := inv.equipment_level(uid)
	var cap := inv.level_cap(uid)
	var x := r.position.x + 30
	var w := r.size.x - 60
	var y := r.position.y + 100
	if picker == "enhance":
		var head := tr("WEAPON_UI_NEXT") % [lv, mini(lv + 1, cap)]
		var hint := level_hint(uid)
		if hint != "":
			head = hint
		_label(Rect2(x, y, w, 56), head, fs + 2, layout.color("accent", Color.ORANGE)).name = "EnhanceHead"
		y += 64
		if lv < cap:
			var now := equip_stats(uid)
			var nxt := equip_stats(uid, lv + 1)
			var parts := PackedStringArray()
			for i in now.size():
				if str(now[i][1]) != str(nxt[i][1]):
					parts.append("%s %s → %s" % [now[i][0], now[i][1], nxt[i][1]])
			_label(Rect2(x, y, w, 50), "  ·  ".join(parts), fs - 2, Color.WHITE).name = "EnhancePreview"
		y += 70
		for mat_id in PlayerProfile.item_defs().ids():
			var md := PlayerProfile.item_defs().get_def(mat_id) as ItemDef
			if md.kind != ItemDef.Kind.ENHANCE:
				continue
			var d := inv.equipment_def_of(uid)
			_label(Rect2(x, y, w - 250, rh - 10), tr("WEAPON_UI_ENHANCE_ROW") % [tr(md.name_key), inv.material_count(mat_id),
					inv.materials_to_enhance(uid, mat_id), d.gold_to_enhance(lv), tr("CURRENCY_GOLD")], fs - 2, Color.WHITE)
			var b := _button(Rect2(r.end.x - 250, y + 8, 220, rh - 26), tr("CHAR_UI_USE"), fs, enhance_with.bind(mat_id), false,
					"EnhanceWith_%s" % mat_id)
			b.disabled = inv.check_enhance(uid, mat_id) != ""
			y += rh
		return
	# Nâng bậc.
	var tier := inv.equipment_tier(uid)
	var cost := inv.ascend_cost(uid)
	if cost.is_empty():
		_label(Rect2(x, y, w, 56), tr("WEAPON_UI_MAXED"), fs + 2, layout.color("accent", Color.ORANGE)).name = "AscendHead"
		return
	var next_cap := inv.level_caps(uid)[tier + 1]
	_label(Rect2(x, y, w, 56), tr("WEAPON_UI_ASCEND_TIER") % [tier, tier + 1], fs + 4, layout.color("accent", Color.ORANGE)).name = "AscendHead"
	_label(Rect2(x, y + 70, w, 50), tr("WEAPON_UI_ASCEND_CAP") % [cap, next_cap], fs, Color.WHITE)
	var md := PlayerProfile.item_defs().get_def(str(cost["material"])) as ItemDef
	_label(Rect2(x, y + 130, w, 50), tr("WEAPON_UI_COST") % [tr(md.name_key) if md else str(cost["material"]),
			inv.material_count(str(cost["material"])), int(cost["count"]), tr("CURRENCY_GOLD"), int(cost["gold"])], fs, Color.WHITE).name = "AscendCost"
	var reason := inv.check_ascend(uid)
	var why := ""
	if reason == Inventory.REASON_NEED_LEVEL:
		why = tr("WEAPON_UI_NEED_LEVEL") % cap
	elif reason != "":
		why = tr("REASON_" + reason.to_upper())
	_label(Rect2(x, y + 200, w, 50), why, fs - 2, layout.color("text_dim", Color.GRAY)).name = "AscendReason"
	var b := _button(Rect2(r.position.x + r.size.x * 0.5 - 180, r.end.y - 110, 360, 80), tr("WEAPON_UI_CONFIRM"), fs + 2,
			ascend_weapon, reason == "", "AscendConfirm")
	b.disabled = reason != ""
