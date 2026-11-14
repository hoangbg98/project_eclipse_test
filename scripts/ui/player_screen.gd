class_name PlayerScreen
extends HubScreen
## Thông tin người chơi (thẻ góc trên-trái Hub, owner 2026-11-14, theo ảnh tham chiếu màn Chỉ Huy):
## ảnh nhân vật đầu đội, thẻ Chỉ huy (LV, thanh EXP, tên, nhân vật đầu đội, số màn đã qua), nút Đổi tên / Bộ sưu tập,
## dải dưới: Nhân vật / Kho vũ khí / Kho vết thánh (đã có / tổng) — chạm để xem danh sách đã có và chưa sở hữu.
## Đổi tên qua PlayerProfile.set_player_name (save v4 `account.name`).

enum Overlay { NONE, RENAME, COLLECTION }

const COLLECTIONS: Array[String] = ["character", "weapon", "stigma"]
const COLLECTION_KEYS := {"character": "PLAYER_COLL_CHARACTER", "weapon": "PLAYER_COLL_WEAPON", "stigma": "PLAYER_COLL_STIGMA"}
const CHAR_DIR := "res://data/characters"

var overlay := Overlay.NONE
var collection := "weapon"
var name_edit: LineEdit
var bottom_buttons: Dictionary = {}


func screen_title() -> String:
	return ""


func intercept_back() -> bool:
	if overlay != Overlay.NONE:
		overlay = Overlay.NONE
		refresh()
		return true
	return false


# ---------- Dữ liệu ----------

## Mọi giáp nhân vật có trong data (Data ID), sắp xếp.
static func all_character_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for f in ResourceLoader.list_directory(CHAR_DIR):
		if f.ends_with(".tres") and not f.ends_with("_kit.tres"):
			out.append(f.get_basename())
	out.sort()
	return out


## Danh sách bộ sưu tập: mảng {id, name, owned, rarity}. Vũ khí / vết thánh tính theo loại (định nghĩa), đã có = có
## ít nhất một món loại đó trong kho.
func collection_entries(kind: String) -> Array:
	var out: Array = []
	if kind == "character":
		for id in all_character_ids():
			var d := load(PlayerProfile.CHARACTER_DATA % id) as CharacterDef
			out.append({"id": id, "name": tr(d.name_key) if d else id, "owned": profile.progression.owns(id),
					"rarity": BagScreen.RANK_RARITY.get(d.rank, 4) if d else 4})
		return out
	var owned_defs := {}
	for uid in profile.inventory.equipment_uids():
		var ed := profile.inventory.equipment_def_of(uid)
		if ed:
			owned_defs[ed.id] = true
	var lib := PlayerProfile.equipment_defs()
	var ids := Array(lib.ids())
	ids.sort()
	for id: String in ids:
		var d := lib.get_def(id) as EquipmentDef
		if d == null or (kind == "weapon") != (d.slot == "weapon"):
			continue
		out.append({"id": id, "name": tr(d.name_key), "owned": owned_defs.has(id), "rarity": d.rarity})
	return out


func count_text(kind: String) -> String:
	var list := collection_entries(kind)
	var owned := list.filter(func(e: Dictionary) -> bool: return e["owned"]).size()
	return "%d/%d" % [owned, list.size()]


func cleared_stages() -> int:
	var n := 0
	for id in profile.data["progress"]["stages"]:
		var st: Variant = profile.data["progress"]["stages"][id]
		if st is Dictionary and bool(st.get("cleared", false)):
			n += 1
	return n


func display_name() -> String:
	var n := profile.player_name()
	return n if n != "" else tr("PLAYER_DEFAULT_NAME")


# ---------- Thao tác ----------

func open_rename() -> void:
	overlay = Overlay.RENAME
	notice = ""
	refresh()


func open_collection(kind: String) -> void:
	collection = kind
	overlay = Overlay.COLLECTION
	notice = ""
	refresh()


func close_overlay() -> void:
	overlay = Overlay.NONE
	refresh()


## Đổi tên; trả về lý do ("" = được).
func rename(raw: String) -> String:
	var reason := profile.set_player_name(raw)
	if reason == PlayerProfile.NAME_OK:
		overlay = Overlay.NONE
		notice = tr("PLAYER_RENAMED")
		commit()
	else:
		notice = tr("PLAYER_NAME_ERR_" + reason.to_upper())
		refresh()
	return reason


# ---------- Dựng ----------

func _build_body() -> void:
	var leader := ""
	if profile.party_ids().size() > 0:
		leader = profile.party_ids()[0]
	_art(layout.rect("player.art", Rect2(40, 110, 640, 800)), HubHomePanel.portrait(leader),
			_char_name(leader), Rect2(0, 0, 1, 1), "LeaderArt")
	_card()
	_side_buttons()
	_bottom()
	match overlay:
		Overlay.RENAME:
			_rename_box()
		Overlay.COLLECTION:
			_collection_box()


func _char_name(id: String) -> String:
	var p := PlayerProfile.CHARACTER_DATA % id
	var d := load(p) as CharacterDef if id != "" and ResourceLoader.exists(p) else null
	return tr(d.name_key) if d else id


func _card() -> void:
	var r := layout.rect("player.card", Rect2(720, 120, 840, 520))
	_panel(r, layout.color("panel", Color(0.08, 0.09, 0.12, 0.85)), "CommanderCard")
	var lv := profile.progression.captain_level()
	var xp := profile.progression.captain_exp()
	var need := profile.rules.captain_exp_to_next(lv)
	_label(Rect2(r.position + Vector2(32, 16), Vector2(380, 80)), tr("PLAYER_COMMANDER"), 56,
			layout.color("accent_blue", Color("#7FD4FF")))
	_label(Rect2(r.position + Vector2(r.size.x - 360, 16), Vector2(328, 50)),
			"EXP %d/%d" % [xp, need] if need > 0 else "EXP MAX", 30, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	var bar := Rect2(r.position + Vector2(r.size.x - 360, 70), Vector2(328, 16))
	_panel(bar, Color(0, 0, 0, 0.6))
	_panel(Rect2(bar.position, Vector2(bar.size.x * (clampf(float(xp) / need, 0, 1) if need > 0 else 1.0), bar.size.y)),
			layout.color("accent_blue", Color("#7FD4FF")), "ExpFill")
	var box := Rect2(r.position + Vector2(32, 120), Vector2(r.size.x - 64, 300))
	_panel(box, layout.color("panel_light", Color(0.16, 0.2, 0.31, 0.9)))
	_label(Rect2(box.position + Vector2(box.size.x - 220, 10), Vector2(200, 70)), "LV.%d" % lv, 52, Color.WHITE,
			HORIZONTAL_ALIGNMENT_RIGHT).name = "Level"
	var leader := profile.party_ids()[0] if profile.party_ids().size() > 0 else ""
	_art(Rect2(box.position + Vector2(20, 90), Vector2(170, 170)), HubHomePanel.portrait(leader), "",
			Rect2(0.2, 0.02, 0.6, 0.36), "Avatar")
	_label(Rect2(box.position + Vector2(220, 90), Vector2(box.size.x - 240, 70)), display_name(), 44).name = "PlayerName"
	_label(Rect2(box.position + Vector2(220, 170), Vector2(box.size.x - 240, 90)),
			tr("PLAYER_INFO_LINE") % [_char_name(leader), cleared_stages()], 26, layout.color("text_dim", Color(0.72, 0.74, 0.8)))


func _side_buttons() -> void:
	var origin := layout.point("player.buttons", "origin", Vector2(1620, 120))
	var sz := layout.point("player.buttons", "size", Vector2(250, 96))
	var step := layout.num("player.buttons.step", 112.0)
	var f := int(layout.num("player.buttons.font", 30))
	_yellow_button(Rect2(origin, sz), tr("PLAYER_RENAME"), f, open_rename, "RenameButton")
	_button(Rect2(origin + Vector2(0, step), sz), tr("PLAYER_COLLECTION"), f, open_collection.bind("weapon"), false, "CollectionButton")


func _bottom() -> void:
	var r := layout.rect("player.bottom", Rect2(0, 920, 1920, 150))
	_panel(r, layout.color("panel", Color(0.08, 0.09, 0.12, 0.85)))
	var f := int(layout.num("player.bottom.font", 30))
	bottom_buttons.clear()
	var w := 420.0
	var x0 := (r.size.x - w * COLLECTIONS.size() - 40 * (COLLECTIONS.size() - 1)) * 0.5
	for i in COLLECTIONS.size():
		var k := COLLECTIONS[i]
		var b := _button(Rect2(r.position + Vector2(x0 + i * (w + 40), 20), Vector2(w, r.size.y - 40)),
				"%s ▶\n%s" % [tr(COLLECTION_KEYS[k]), count_text(k)], f, open_collection.bind(k), false, "Coll_" + k)
		bottom_buttons[k] = b


func _rename_box() -> void:
	var r := Rect2(560, 300, 800, 420)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	_place(dim, Rect2(Vector2.ZERO, layout.view_size))
	_panel(r, layout.color("panel_light", Color(0.16, 0.2, 0.31, 0.95)), "RenameBox")
	_label(Rect2(r.position + Vector2(40, 24), Vector2(r.size.x - 80, 60)), tr("PLAYER_RENAME"), 40)
	_label(Rect2(r.position + Vector2(40, 90), Vector2(r.size.x - 80, 40)), tr("PLAYER_RENAME_HINT") % SaveSchema.NAME_MAX, 24,
			layout.color("text_dim", Color(0.72, 0.74, 0.8)))
	name_edit = LineEdit.new()
	name_edit.name = "NameEdit"
	name_edit.text = profile.player_name()
	name_edit.max_length = SaveSchema.NAME_MAX
	name_edit.placeholder_text = tr("PLAYER_DEFAULT_NAME")
	name_edit.add_theme_font_size_override("font_size", 36)
	name_edit.text_submitted.connect(func(t: String) -> void: rename(t))
	_place(name_edit, Rect2(r.position + Vector2(40, 150), Vector2(r.size.x - 80, 96)))
	_button(Rect2(r.position + Vector2(40, r.size.y - 136), Vector2(320, 104)), tr("UI_CANCEL"), 32, close_overlay, false, "Cancel")
	_yellow_button(Rect2(r.position + Vector2(r.size.x - 360, r.size.y - 136), Vector2(320, 104)), tr("UI_OK"), 32,
			func() -> void: rename(name_edit.text), "Confirm")
	name_edit.grab_focus.call_deferred()


func _collection_box() -> void:
	var r := layout.rect("player.list", Rect2(300, 120, 1320, 760))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	_place(dim, Rect2(Vector2.ZERO, layout.view_size))
	_panel(r, layout.color("panel_light", Color(0.16, 0.2, 0.31, 0.97)), "CollectionBox")
	var tw := 300.0
	for i in COLLECTIONS.size():
		var k := COLLECTIONS[i]
		_button(Rect2(r.position + Vector2(24 + i * (tw + 16), 20), Vector2(tw, 80)), "%s %s" % [tr(COLLECTION_KEYS[k]), count_text(k)],
				26, open_collection.bind(k), k == collection, "CollTab_" + k)
	_button(Rect2(r.position + Vector2(r.size.x - 104, 20), Vector2(80, 80)), "✕", 34, close_overlay, false, "Close")
	var list := collection_entries(collection)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["owned"] != b["owned"]:
			return a["owned"]
		return str(a["name"]) < str(b["name"]))
	var f := int(layout.num("player.list.font", 26))
	var col_w := (r.size.x - 72) / 2.0
	var y := 124.0
	for i in list.size():
		var e: Dictionary = list[i]
		var x := 24.0 + (i % 2) * (col_w + 24)
		if i > 0 and i % 2 == 0:
			y += f * 1.7
		var mark := "✓" if e["owned"] else "—"
		var text := "%s  %s  %s" % [mark, e["name"], "★".repeat(int(e["rarity"]))]
		var colr := Color.WHITE if e["owned"] else layout.color("text_dim", Color(0.72, 0.74, 0.8)).darkened(0.25)
		var l := _label(Rect2(r.position + Vector2(x, y), Vector2(col_w, f * 1.5)), text, f, colr)
		l.name = ("Owned_" if e["owned"] else "Missing_") + str(e["id"])
	_label(Rect2(r.position + Vector2(24, r.size.y - 60), Vector2(r.size.x - 48, 44)), tr("PLAYER_COLL_HINT"), 22,
			layout.color("text_dim", Color(0.72, 0.74, 0.8)))
