class_name BagScreen
extends HubScreen
## Túi đồ (nút lục giác Trang bị, owner 2026-11-14, theo ảnh tham chiếu kho vũ khí): cột mục bên trái
## (Vũ khí, Vết thánh, Nguyên liệu, Mảnh) và lưới thẻ cuộn được: màu theo độ hiếm, ảnh (hoặc icon tạm), sao, cấp
## cường hóa / số lượng, nhãn "Đang dùng" + người đang mặc. Chạm thẻ vũ khí / vết thánh: mở bảng thông tin món ở màn Nhân
## vật (owner 2026-11-15); thẻ nguyên liệu / mảnh: dải chi tiết bên dưới.
## Đồ nhận từ Tiếp tế (chiêu mộ), sự kiện, phần thưởng màn. Màn chỉ đọc Inventory / Progression.

const CATEGORIES: Array[String] = ["weapon", "stigma", "material", "fragment"]
const CATEGORY_KEYS := {"weapon": "BAG_TAB_WEAPON", "stigma": "BAG_TAB_STIGMA", "material": "BAG_TAB_MATERIAL",
		"fragment": "BAG_TAB_FRAGMENT"}
const STAT_KEYS := {"atk": "STAT_ATK", "max_hp": "STAT_HP", "def": "STAT_DEF", "crit_rate": "STAT_CRIT",
		"crit_damage": "STAT_CRIT_DAMAGE", "cdr": "STAT_CDR"}
const RANK_RARITY := {"S": 5, "A": 4, "B": 3}
const SLOT_KEYS := {"weapon": "BAG_SLOT_WEAPON", "stigma_top": "BAG_SLOT_STIGMA_TOP", "stigma_mid": "BAG_SLOT_STIGMA_MID",
		"stigma_bot": "BAG_SLOT_STIGMA_BOT"}

var category := "weapon"
## Món đang chọn: {"kind": "equipment"|"material"|"fragment", "id": uid / item id / character id}.
var selected := {}
var cards: Array[Button] = []


func screen_title() -> String:
	return tr("BAG_TITLE")


func set_category(c: String) -> void:
	if c in CATEGORIES:
		category = c
		selected = {}
		notice = ""
		refresh()


## Danh sách món của mục `c`: mảng {kind, id, name, rarity, level_text, in_use_by, art, icon, count}.
func entries(c: String) -> Array:
	var out: Array = []
	var inv := profile.inventory
	match c:
		"weapon", "stigma":
			for uid in inv.equipment_uids():
				var d := inv.equipment_def_of(uid)
				if d == null or (c == "weapon") != (d.slot == "weapon"):
					continue
				out.append({"kind": "equipment", "id": uid, "name": tr(d.name_key), "rarity": d.rarity,
						"level_text": "LV.%d" % inv.equipment_level(uid), "in_use_by": inv.equipped_by(uid),
						"art": d.art, "icon": "attack" if d.slot == "weapon" else "stigma", "slot": d.slot})
		"material":
			var mats: Dictionary = profile.data["inventory"]["materials"]
			for id in mats:
				var n := inv.material_count(str(id))
				var d := PlayerProfile.item_defs().get_def(str(id)) as ItemDef
				if n > 0 and d:
					out.append({"kind": "material", "id": str(id), "name": tr(d.name_key), "rarity": d.rarity,
							"level_text": "×%d" % n, "in_use_by": "", "art": "", "icon": "material"})
		"fragment":
			for id in profile.data["characters"]:
				var n := profile.progression.fragments_of(str(id))
				if n > 0:
					var cd := _char_def(str(id))
					out.append({"kind": "fragment", "id": str(id), "name": tr(cd.name_key) if cd else str(id),
							"rarity": RANK_RARITY.get(cd.rank, 4) if cd else 4, "level_text": "×%d" % n,
							"in_use_by": "", "art": HubHomePanel.PORTRAIT_PATH % [id, id], "icon": "character"})
	# Đang dùng trước, rồi độ hiếm giảm dần, rồi tên.
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if (a["in_use_by"] != "") != (b["in_use_by"] != ""):
			return a["in_use_by"] != ""
		if a["rarity"] != b["rarity"]:
			return a["rarity"] > b["rarity"]
		return str(a["name"]) < str(b["name"]))
	return out


func _char_def(id: String) -> CharacterDef:
	var p := PlayerProfile.CHARACTER_DATA % id
	return load(p) as CharacterDef if ResourceLoader.exists(p) else null


func _char_name(id: String) -> String:
	var d := _char_def(id)
	return tr(d.name_key) if d else id


func _build_body() -> void:
	var origin := layout.point("bag.tabs", "origin", Vector2(76, 112))
	var tab_size := layout.point("bag.tabs", "size", Vector2(214, 98))
	var step := layout.num("bag.tabs.step", 104.0)
	for i in CATEGORIES.size():
		var c := CATEGORIES[i]
		var b := _button(Rect2(origin + Vector2(0, step * i), tab_size), "%s (%d)" % [tr(CATEGORY_KEYS[c]), entries(c).size()],
				int(layout.num("bag.tabs.font", 30)), set_category.bind(c), c == category, "Tab_" + c)
		if c != category:
			var bg := layout.color("tab", Color("#1F2A44"))
			b.add_theme_stylebox_override("normal", _style(bg, Color(0, 0, 0, 0)))
	var list := entries(category)
	var grid_r := layout.rect("bag.grid", Rect2(330, 112, 1440, 830))
	cards.clear()
	if list.is_empty():
		_label(grid_r, tr("BAG_EMPTY") % tr(CATEGORY_KEYS[category]), int(layout.num("bag.empty.font", 30)),
				layout.color("text_dim", Color(0.72, 0.74, 0.8)), HORIZONTAL_ALIGNMENT_CENTER).name = "Empty"
	else:
		var card_size := layout.point("bag.grid", "card", Vector2(190, 236))
		var gap := layout.num("bag.grid.gap", 16.0)
		var scroll := ScrollContainer.new()
		scroll.name = "Scroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var grid := GridContainer.new()
		grid.name = "Grid"
		grid.columns = maxi(int((grid_r.size.x + gap) / (card_size.x + gap)), 1)
		grid.add_theme_constant_override("h_separation", int(gap))
		grid.add_theme_constant_override("v_separation", int(gap))
		scroll.add_child(grid)
		_place(scroll, grid_r)
		for e: Dictionary in list:
			var card := _card(e, card_size)
			grid.add_child(card)
			cards.append(card)
	_detail()


func _card(e: Dictionary, sz: Vector2) -> Button:
	var b := Button.new()
	b.name = "Card_" + str(e["id"])
	b.custom_minimum_size = sz
	b.focus_mode = Control.FOCUS_NONE
	var rar := clampi(int(e["rarity"]), 1, 5)
	var col := layout.color("rarity_%d" % rar, Color("#6B7280"))
	var is_sel: bool = selected.get("id", "") == e["id"] and selected.get("kind", "") == e["kind"]
	var border := Color.WHITE if is_sel else col.lightened(0.35)
	b.add_theme_stylebox_override("normal", _style(col.darkened(0.15), border, 10))
	b.add_theme_stylebox_override("hover", _style(col, border, 10))
	b.add_theme_stylebox_override("pressed", _style(col.darkened(0.3), border, 10))
	if str(e["kind"]) == "equipment":
		b.pressed.connect(open_equipment.bind(str(e["id"])))
	else:
		b.pressed.connect(select.bind(str(e["kind"]), str(e["id"])))
	var font := int(layout.num("bag.grid.font", 22))
	# Ảnh: art của định nghĩa nếu có, không thì icon tạm.
	var tex: Texture2D = null
	var art_path := str(e["art"])
	if art_path != "" and ResourceLoader.exists(art_path):
		tex = load(art_path)
	var pic := TextureRect.new()
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if tex and tex.get_height() > tex.get_width():
		# Ảnh dọc (vết thánh): lấy phần vuông phía trên cho ô ảnh ngang của thẻ.
		var at := AtlasTexture.new()
		at.atlas = tex
		var c := PlaceholderArt.center_square(tex)
		at.region = Rect2(c.position * tex.get_size(), c.size * tex.get_size())
		pic.texture = at
	elif tex:
		pic.texture = tex
	elif e["icon"] == "attack":
		pic.texture = HudIcons.icon("", "attack")
	else:
		var p := ICON_DIR % ("gacha" if e["icon"] == "stigma" else str(e["icon"]))
		pic.texture = load(p) as Texture2D if ResourceLoader.exists(p) else null
	# Hàng dọc của thẻ (tỉ lệ chiều cao): ảnh 0–0.42, Đang dùng 0.44, sao 0.6, tên 0.72, cấp / số lượng 0.84.
	pic.position = Vector2(14, 8)
	pic.size = Vector2(sz.x - 28, sz.y * 0.42 - 8)
	b.add_child(pic)
	if str(e["in_use_by"]) != "":
		var strip := ColorRect.new()
		strip.color = Color(0, 0, 0, 0.55)
		strip.position = Vector2(0, sz.y * 0.44)
		strip.size = Vector2(sz.x, sz.y * 0.14)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(strip)
		var use := _mini_label(tr("BAG_IN_USE") + " · " + _char_name(str(e["in_use_by"])), font - 2,
				layout.color("in_use", Color("#FFD84D")))
		use.name = "InUse"
		use.position = strip.position + Vector2(6, 0)
		use.size = Vector2(sz.x - 12, strip.size.y)
		b.add_child(use)
	var stars := _mini_label("★".repeat(rar), font, layout.color("star", Color("#FFD23F")))
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.position = Vector2(0, sz.y * 0.59)
	stars.size = Vector2(sz.x, sz.y * 0.12)
	b.add_child(stars)
	var name_l := _mini_label(str(e["name"]), font - 2, Color.WHITE)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.position = Vector2(4, sz.y * 0.71)
	name_l.size = Vector2(sz.x - 8, sz.y * 0.12)
	b.add_child(name_l)
	var lv := _mini_label(str(e["level_text"]), font + 6, Color.WHITE)
	lv.name = "Level"
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.position = Vector2(0, sz.y * 0.83)
	lv.size = Vector2(sz.x, sz.y * 0.15)
	b.add_child(lv)
	return b


func _mini_label(text: String, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 5)
	l.clip_text = true
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func select(kind: String, id: String) -> void:
	selected = {"kind": kind, "id": id}
	refresh()


## Bấm thẻ vũ khí / vết thánh (owner 2026-11-15): mở bảng thông tin món ở màn Nhân vật (như Nhân vật → Vũ khí).
func open_equipment(uid: String) -> void:
	selected = {"kind": "equipment", "id": uid}
	var gc := UiKit.autoload("GameConfig")
	if gc:
		gc.inspect_equipment_uid = uid
	open_scene("SCENE_CHARACTER")


## Dòng chi tiết của món đang chọn.
func detail_text() -> String:
	if selected.is_empty():
		return tr("BAG_DETAIL_HINT")
	var inv := profile.inventory
	match str(selected["kind"]):
		"equipment":
			var uid := str(selected["id"])
			var d := inv.equipment_def_of(uid)
			if d == null:
				return ""
			var parts := PackedStringArray([tr(d.name_key) + (" +%d" % inv.equipment_level(uid) if inv.equipment_level(uid) > 0 else ""),
					tr(SLOT_KEYS.get(d.slot, "BAG_SLOT_WEAPON"))])
			for st: String in ["atk", "max_hp", "def"]:
				var v: float = d.get(st)
				if v != 0.0:
					parts.append("%s +%d" % [tr(STAT_KEYS[st]), int(v)])
			for st: String in ["crit_rate", "crit_damage", "cdr"]:
				var v: float = d.get(st)
				if v != 0.0:
					parts.append("%s +%d%%" % [tr(STAT_KEYS[st]), int(round(v * 100.0))])
			var who := inv.equipped_by(uid)
			parts.append(tr("BAG_IN_USE") + " · " + _char_name(who) if who != "" else tr("BAG_NOT_IN_USE"))
			return "   ·   ".join(parts)
		"material":
			var d := PlayerProfile.item_defs().get_def(str(selected["id"])) as ItemDef
			return "%s   ·   ×%d" % [tr(d.name_key) if d else str(selected["id"]), inv.material_count(str(selected["id"]))]
		"fragment":
			var id := str(selected["id"])
			return tr("BAG_FRAGMENT_DETAIL") % [_char_name(id), profile.progression.fragments_of(id),
					profile.progression.fragments_to_promote(id)]
	return ""


func _detail() -> void:
	var r := layout.rect("bag.detail", Rect2(330, 958, 1440, 104))
	_panel(r, layout.color("panel", Color(0.08, 0.09, 0.12, 0.85)), "Detail")
	_label(Rect2(r.position + Vector2(24, 0), r.size - Vector2(48, 0)), detail_text(), int(layout.num("bag.detail.font", 26))).name = "DetailText"
