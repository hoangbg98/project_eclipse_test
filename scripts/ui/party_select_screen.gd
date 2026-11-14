class_name PartySelectScreen
extends HubScreen
## Chọn giáp ra trận (owner 2026-11-14, theo ảnh tham chiếu): bên trái lưới các giáp đang sở hữu (số thứ tự trong đội
## ở góc), bên phải sân khấu 3 vị trí, nhân vật đứng tư thế idle (vị trí 1 giữa, 2 trái, 3 phải). Logic giữ như trước
## (PlayerProfile.toggle_party): chạm giáp chưa có trong đội = thêm xuống cuối, chạm giáp đang trong đội = bỏ ra;
## không bỏ người cuối, đội tối đa 3, không hai giáp cùng nhân vật. Xác nhận đội ngũ = quay lại màn đội hình.
## Bố cục ở mục "party_select" của hub_screens_layout.json.

const NOTICE_KEYS := {
	PlayerProfile.PARTY_LAST: "PARTY_ERR_LAST",
	PlayerProfile.PARTY_FULL: "PARTY_ERR_FULL",
	PlayerProfile.PARTY_SAME_PERSON: "PARTY_ERR_SAME_PERSON",
	PlayerProfile.PARTY_NOT_OWNED: "PARTY_ERR_NOT_OWNED",
}

## id giáp -> nút trong lưới (để test).
var suit_buttons: Dictionary = {}
## Nút / sprite trên sân khấu theo vị trí (để test).
var stage_nodes: Array[Control] = []
var last_reason := ""


func screen_title() -> String:
	return tr("PARTY_SELECT_TITLE")


## Giáp đang sở hữu, theo thứ tự trong save.
func owned_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in profile.data["characters"]:
		out.append(id)
	return out


func _build_body() -> void:
	suit_buttons.clear()
	stage_nodes.clear()
	_build_grid()
	_build_stage()
	_button(layout.rect("party_select.detail", Rect2(1110, 960, 360, 96)), tr("PARTY_SELECT_DETAIL"),
			int(layout.num("party_select.detail.font", 30)), open_detail, false, "DetailButton")
	_yellow_button(layout.rect("party_select.confirm", Rect2(1490, 960, 390, 96)), tr("PARTY_SELECT_CONFIRM"),
			int(layout.num("party_select.confirm.font", 32)), leave, "ConfirmButton")


# ---------- Lưới giáp ----------

func _build_grid() -> void:
	var area := layout.rect("party_select.grid", Rect2(60, 112, 700, 950))
	var card := layout.point("party_select.grid", "card", Vector2(160, 200))
	var gap := layout.num("party_select.grid.gap", 14.0)
	var cols := maxi(int((area.size.x + gap) / (card.x + gap)), 1)
	var scroll := ScrollContainer.new()
	scroll.name = "GridScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_place(scroll, area)
	var inner := Control.new()
	var ids := owned_ids()
	var rows := ceili(float(ids.size()) / cols)
	inner.custom_minimum_size = Vector2(area.size.x - 20, rows * (card.y + gap))
	scroll.add_child(inner)
	var party := Array(profile.party_ids())
	for i in ids.size():
		var r := Rect2(Vector2((i % cols) * (card.x + gap), floorf(float(i) / cols) * (card.y + gap)), card)
		suit_buttons[ids[i]] = _suit_card(inner, r, ids[i], party.find(ids[i]))


func _suit_card(parent: Control, r: Rect2, id: String, slot: int) -> Button:
	var def := CharacterArt.def_of(id)
	var el := layout.color("element_" + (def.element if def else ""), Color.GRAY)
	var b := Button.new()
	b.name = "Suit_" + id
	b.focus_mode = Control.FOCUS_NONE
	b.position = r.position
	b.size = r.size
	var bg := layout.color("panel_light", Color(0.16, 0.2, 0.31))
	var border := Color.WHITE if slot >= 0 else el
	for k in ["normal", "hover", "pressed"]:
		var s := _style(bg.lightened(0.08) if k == "hover" else bg, border, 8)
		s.set_border_width_all(5 if slot >= 0 else 3)
		b.add_theme_stylebox_override(k, s)
	b.pressed.connect(toggle.bind(id))
	parent.add_child(b)
	var tex := CharacterArt.top_crop(CharacterArt.figure(id), (r.size.x - 12) / (r.size.y - 56))
	if tex:
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.position = Vector2(6, 6)
		t.size = r.size - Vector2(12, 56)
		b.add_child(t)
	else:
		var c := ColorRect.new()
		c.color = el.darkened(0.45)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.position = Vector2(6, 6)
		c.size = r.size - Vector2(12, 56)
		b.add_child(c)
		b.add_child(_small_label(Rect2(Vector2(6, 6), r.size - Vector2(12, 56)), tr(def.name_key) if def else id, 22,
				Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	b.add_child(_small_label(Rect2(8, r.size.y - 50, 50, 44), def.rank if def and def.rank != "" else "?", 30,
			layout.color("star", Color.GOLD)))
	b.add_child(_small_label(Rect2(50, r.size.y - 50, r.size.x - 58, 44), "Lv.%d" % profile.progression.level_of(id), 26,
			Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT))
	if slot >= 0:
		var badge := Panel.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_theme_stylebox_override("panel", _style(Color.WHITE, Color(0, 0, 0, 0), 4))
		badge.position = Vector2(r.size.x - 44, 0)
		badge.size = Vector2(44, 44)
		b.add_child(badge)
		b.add_child(_small_label(Rect2(r.size.x - 44, 0, 44, 44), str(slot + 1), 28, Color.BLACK,
				HORIZONTAL_ALIGNMENT_CENTER))
	return b


func _small_label(r: Rect2, text: String, font: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.position = r.position
	l.size = r.size
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 5)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# ---------- Sân khấu 3 vị trí ----------

## Chân nhân vật (tọa độ khung thiết kế) và tỉ lệ cho vị trí 1 (giữa), 2 (trái), 3 (phải).
func _spot(i: int) -> Dictionary:
	var raw: Variant = layout.get_value("party_select.spots", [])
	var feet: Array = raw if raw is Array else []
	var defaults := [[1330.0, 860.0, 1.55], [1000.0, 720.0, 1.2], [1680.0, 720.0, 1.2]]
	var v: Array = feet[i] if i < feet.size() and feet[i] is Array and (feet[i] as Array).size() >= 3 else defaults[i]
	return {"feet": Vector2(float(v[0]), float(v[1])), "scale": float(v[2])}


func _build_stage() -> void:
	var party := profile.party_ids()
	# Vẽ vị trí sau (2, 3) trước để vị trí 1 đứng trên.
	for i in [1, 2, 0]:
		var sp := _spot(i)
		var feet: Vector2 = sp["feet"]
		var sc: float = sp["scale"]
		var ring := Panel.new()
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(0.5, 0.83, 1.0, 0.08)
		rs.border_color = Color(0.85, 0.95, 1.0, 0.85)
		rs.set_border_width_all(4)
		rs.set_corner_radius_all(200)
		ring.add_theme_stylebox_override("panel", rs)
		_place(ring, Rect2(feet - Vector2(150 * sc, 26 * sc), Vector2(300 * sc, 52 * sc)))
		var id := party[i] if i < party.size() else ""
		var holder := Control.new()
		holder.name = "Spot_%d" % (i + 1)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(holder, Rect2(feet, Vector2.ONE))
		stage_nodes.append(holder)
		if id == "":
			_label(Rect2(feet - Vector2(150, 140), Vector2(300, 120)), "+", 90, Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_CENTER)
		else:
			_figure(holder, id, sc)
		var def := CharacterArt.def_of(id) if id != "" else null
		var nm := (tr(def.name_key) if def else id) if id != "" else tr("PARTY_PREP_EMPTY")
		_label(Rect2(feet + Vector2(-220, 30 * sc), Vector2(440, 50)), "%d  %s" % [i + 1, nm], 30, Color.WHITE,
				HORIZONTAL_ALIGNMENT_CENTER)


## Nhân vật đứng idle (frame idle); chưa có frame thì ảnh chibi đặt trên vòng.
func _figure(holder: Control, id: String, sc: float) -> void:
	var idle := CharacterArt.idle(id)
	if not idle.is_empty():
		var spr := AnimatedSprite2D.new()
		spr.name = "Idle"
		spr.sprite_frames = idle["frames"]
		spr.offset = idle["offset"]
		spr.scale = Vector2(sc, sc)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		holder.add_child(spr)
		spr.play(&"idle")
		return
	var tex := CharacterArt.portrait(id)
	if tex:
		var t := TextureRect.new()
		t.name = "Portrait"
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.position = Vector2(-140, -300) * sc
		t.size = Vector2(280, 300) * sc
		holder.add_child(t)


# ---------- Thao tác ----------

## Thêm / bỏ giáp khỏi đội (logic như trước). Trả về PlayerProfile.PARTY_*.
func toggle(id: String) -> String:
	last_reason = profile.toggle_party(id)
	if last_reason == PlayerProfile.PARTY_OK:
		notice = ""
		commit()
	else:
		say(tr(NOTICE_KEYS.get(last_reason, "PARTY_ERR_NOT_OWNED")))
	return last_reason


func open_detail() -> void:
	var gc := UiKit.autoload("GameConfig")
	var party := profile.party_ids()
	if gc and party.size() > 0:
		gc.selected_character_id = party[0]
	open_scene("SCENE_CHARACTER")
