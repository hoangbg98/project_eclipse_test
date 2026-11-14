class_name StageInfoScreen
extends HubScreen
## Thông tin màn chơi trước khi vào (owner 2026-11-14, theo ảnh tham chiếu): bên trái tên màn, ảnh xem trước, mô tả;
## bên phải tên màn + cấp đề cử, **Mục tiêu chiến đấu** (mỗi mục tiêu đạt khi qua màn thưởng thêm vàng, ghi Đã đạt
## nếu từng đạt), **Có thể rơi** (thưởng thường + lần đầu). Nút Chuẩn bị → màn đội hình (có nút Khai chiến).
## Màn lấy từ GameConfig.selected_stage_id; bố cục ở mục "stage_info" của hub_screens_layout.json.

const STAGE_DATA := "res://data/stages/%s.json"

var stage_id := ""
var stage_data: Dictionary = {}
## Mục tiêu đang hiện (để test đọc).
var objective_rows: Array[Dictionary] = []


func screen_title() -> String:
	return ""


func _ready() -> void:
	var gc := UiKit.autoload("GameConfig")
	if stage_id == "":
		stage_id = str(gc.selected_stage_id) if gc else "stage_01"
	var path := STAGE_DATA % stage_id
	if FileAccess.file_exists(path):
		stage_data = StageMap.load_from(path).data
	super._ready()


func stage_title() -> String:
	return tr(str(stage_data["name_key"])) if stage_data.has("name_key") else stage_id


func achieved_ids() -> Array:
	var st: Variant = profile.data["progress"]["stages"].get(stage_id)
	return st.get("objectives", []) if st is Dictionary and st.get("objectives") is Array else []


func _build_body() -> void:
	var accent := layout.color("accent_blue", Color("#7FD4FF"))
	# ----- Trái: tên, ảnh xem trước, mô tả -----
	_label(layout.rect("stage_info.title", Rect2(120, 120, 640, 84)), stage_title(),
			int(layout.num("stage_info.title.font", 52)))
	var pr := layout.rect("stage_info.preview", Rect2(120, 220, 640, 340))
	var frame := _panel(pr, Color(0, 0, 0, 0), "Preview")
	frame.add_theme_stylebox_override("panel", _style(layout.color("panel_light", Color(0.16, 0.2, 0.31)), accent, 8))
	var tex := load(str(stage_data.get("preview", ""))) as Texture2D \
			if ResourceLoader.exists(str(stage_data.get("preview", ""))) else null
	if tex:
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(t, pr.grow(-8))
	else:
		_icon(Rect2(pr.get_center() - Vector2(90, 110), Vector2(180, 180)), "story", Color(1, 1, 1, 0.5))
		_label(Rect2(pr.position + Vector2(0, pr.size.y - 70), Vector2(pr.size.x, 50)), tr("STAGE_INFO_NO_PREVIEW"), 24,
				layout.color("text_dim", Color.GRAY), HORIZONTAL_ALIGNMENT_CENTER)
	if stage_data.has("desc_key"):
		var dr := layout.rect("stage_info.desc", Rect2(120, 590, 640, 220))
		var d := _label(dr, tr(str(stage_data["desc_key"])), int(layout.num("stage_info.desc.font", 28)),
				layout.color("text_dim", Color.LIGHT_GRAY))
		d.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var st: Variant = profile.data["progress"]["stages"].get(stage_id)
	if st is Dictionary and bool(st.get("cleared", false)):
		_label(layout.rect("stage_info.best", Rect2(120, 840, 640, 50)),
				tr("BATTLE_STAGE_BEST") % StageHud.format_time(float(st.get("best_time_sec", 0.0))), 26, accent)

	# ----- Phải: tên + cấp đề cử -----
	var font := int(layout.num("stage_info.font", 30))
	var loc := layout.rect("stage_info.location", Rect2(800, 120, 1080, 60))
	_label(Rect2(loc.position + Vector2(16, 0), Vector2(loc.size.x * 0.6, loc.size.y)), "◆ " + stage_title(), font + 2, accent)
	_label(Rect2(loc.position + Vector2(loc.size.x * 0.4, 0), Vector2(loc.size.x * 0.6 - 16, loc.size.y)),
			tr("STAGE_INFO_RECOMMENDED") % int(stage_data.get("recommended_level", 1)), font, accent, HORIZONTAL_ALIGNMENT_RIGHT)

	# ----- Mục tiêu -----
	var y := _header(layout.rect("stage_info.objectives_header", Rect2(800, 192, 1080, 56)), tr("STAGE_INFO_OBJECTIVES"),
			tr("STAGE_INFO_OBJECTIVE_REWARD"))
	var row_h := layout.num("stage_info.row_height", 64.0)
	var done := achieved_ids()
	objective_rows.clear()
	var objs := BattleObjectives.list_of(stage_data)
	if objs.is_empty():
		_label(Rect2(loc.position.x + 24, y, loc.size.x - 48, row_h), tr("STAGE_INFO_NO_OBJECTIVES"), font - 2,
				layout.color("text_dim", Color.GRAY))
		y += row_h + 8
	for o in objs:
		var met := done.has(str(o["id"]))
		objective_rows.append({"id": str(o["id"]), "text": BattleObjectives.describe(o), "achieved": met})
		var r := Rect2(loc.position.x, y, loc.size.x, row_h)
		var p := _panel(r, Color(0, 0, 0, 0), "Objective_" + str(o["id"]))
		p.add_theme_stylebox_override("panel", _style(layout.color("objective_row", Color("#2A5C8ACC")), Color(0, 0, 0, 0), 8))
		_label(Rect2(r.position + Vector2(18, 0), Vector2(56, row_h)), "★" if met else "☆", font + 6,
				layout.color("star", Color.GOLD), HORIZONTAL_ALIGNMENT_CENTER)
		_label(Rect2(r.position + Vector2(90, 0), Vector2(r.size.x * 0.58, row_h)), BattleObjectives.describe(o), font)
		_label(Rect2(r.position + Vector2(r.size.x * 0.62, 0), Vector2(r.size.x * 0.2, row_h)),
				"+%d %s" % [int(o.get("gold", 0)), tr("CURRENCY_GOLD")], font - 4, layout.color("gold", Color.GOLD),
				HORIZONTAL_ALIGNMENT_RIGHT)
		_label(Rect2(r.position + Vector2(r.size.x * 0.82, 0), Vector2(r.size.x * 0.18 - 18, row_h)),
				tr("STAGE_INFO_DONE") if met else tr("STAGE_INFO_NOT_DONE"), font - 4,
				accent if met else layout.color("text_dim", Color.GRAY), HORIZONTAL_ALIGNMENT_RIGHT)
		y += row_h + 8

	# ----- Có thể rơi -----
	y = _header(Rect2(loc.position.x, y + 12, loc.size.x, 56), tr("STAGE_INFO_DROPS"), "")
	var card := layout.num("stage_info.drop_size", 150.0)
	var x := loc.position.x
	for d in drops():
		_drop_card(Rect2(x, y, card, card + 40), d)
		x += card + 18

	# ----- Nút Chuẩn bị -----
	_yellow_button(layout.rect("stage_info.prepare", Rect2(1480, 950, 400, 100)), tr("STAGE_INFO_PREPARE"),
			int(layout.num("stage_info.prepare.font", 40)), prepare, "PrepareButton")


## Dải tiêu đề mục (trái tiêu đề, phải chữ phụ). Trả về y bắt đầu nội dung bên dưới.
func _header(r: Rect2, title: String, right: String) -> float:
	var p := _panel(r, Color(0, 0, 0, 0))
	p.add_theme_stylebox_override("panel", _style(layout.color("objective_header", Color("#4F86B8E6")), Color(0, 0, 0, 0), 6))
	_label(Rect2(r.position + Vector2(20, 0), Vector2(r.size.x * 0.5, r.size.y)), title, 30)
	if right != "":
		_label(Rect2(r.position + Vector2(r.size.x * 0.4, 0), Vector2(r.size.x * 0.6 - 20, r.size.y)), right, 24,
				layout.color("accent_blue", Color.SKY_BLUE), HORIZONTAL_ALIGNMENT_RIGHT)
	return r.end.y + 10


## Vật phẩm có thể nhận: [{kind: gold|gems|material|equipment, id, rarity}] (thưởng thường trước, rồi lần đầu).
func drops() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen := {}
	for key in ["rewards", "first_clear_rewards"]:
		var r: Dictionary = stage_data.get(key, {})
		for cur in ["gold", "gems"]:
			if int(r.get(cur, 0)) > 0 and not seen.has(cur):
				seen[cur] = true
				out.append({"kind": cur, "id": cur, "rarity": 2 if cur == "gold" else 4})
		for id in (r.get("materials", {}) as Dictionary):
			if not seen.has(id):
				seen[id] = true
				var d := PlayerProfile.item_defs().get_def(str(id)) as ItemDef
				out.append({"kind": "material", "id": str(id), "rarity": d.rarity if d else 1})
		for id in (r.get("equipment", []) as Array):
			if not seen.has(id):
				seen[id] = true
				var e := PlayerProfile.equipment_defs().get_def(str(id)) as EquipmentDef
				out.append({"kind": "equipment", "id": str(id), "rarity": e.rarity if e else 1})
	return out


func _drop_card(r: Rect2, d: Dictionary) -> void:
	var rar := clampi(int(d["rarity"]), 1, 5)
	var p := _panel(r, Color(0, 0, 0, 0), "Drop_" + str(d["id"]))
	p.add_theme_stylebox_override("panel", _style(layout.color("rarity_%d" % rar, Color.STEEL_BLUE), Color.WHITE, 10))
	var icon: String = {"gold": "supply", "gems": "gacha", "material": "material", "equipment": "bag"}[str(d["kind"])]
	_icon(Rect2(r.position + Vector2(r.size.x * 0.18, 10), Vector2(r.size.x * 0.64, r.size.x * 0.64)), icon)
	_label(Rect2(r.position + Vector2(6, r.size.x * 0.68), Vector2(r.size.x - 12, 40)), _drop_name(d), 20, Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER)
	_label(Rect2(r.position + Vector2(0, r.size.y - 40), Vector2(r.size.x, 36)), "★".repeat(rar), 22,
			layout.color("star", Color.GOLD), HORIZONTAL_ALIGNMENT_CENTER)


func _drop_name(d: Dictionary) -> String:
	match str(d["kind"]):
		"gold":
			return tr("CURRENCY_GOLD")
		"gems":
			return tr("CURRENCY_GEMS")
		"material":
			var i := PlayerProfile.item_defs().get_def(str(d["id"])) as ItemDef
			return tr(i.name_key) if i else str(d["id"])
		"equipment":
			var e := PlayerProfile.equipment_defs().get_def(str(d["id"])) as EquipmentDef
			return tr(e.name_key) if e else str(d["id"])
	return str(d["id"])


## Chuẩn bị: sang màn đội hình có nút Khai chiến vào màn này.
func prepare() -> void:
	var gc := UiKit.autoload("GameConfig")
	if gc:
		gc.selected_stage_id = stage_id
		gc.prep_launch_stage = true
	open_scene("SCENE_PARTY_PREP")
