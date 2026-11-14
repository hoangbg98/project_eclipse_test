class_name PartyPrepScreen
extends HubScreen
## Đội hình ra trận (owner 2026-11-14, theo ảnh tham chiếu): ảnh splash của 3 giáp trong đội (ô trống có dấu +).
## Chạm vào một ảnh → màn chọn giáp (PartySelectScreen) để chọn lại. Mở từ thông tin màn (Chuẩn bị) thì có nút
## Khai chiến vào GameConfig.selected_stage_id; mở từ thẻ Đội hình ở Xuất kích thì nút là Xác nhận (quay lại).
## Bố cục ở mục "party_prep" của hub_screens_layout.json.

const SLOTS := 3

## true: có nút Khai chiến (GameConfig.prep_launch_stage lúc mở màn).
var launch_stage := false
var slot_buttons: Array[Button] = []


func _ready() -> void:
	var gc := UiKit.autoload("GameConfig")
	if gc:
		launch_stage = bool(gc.prep_launch_stage)
	super._ready()


func screen_title() -> String:
	return tr("PARTY_PREP_TITLE")


func _build_body() -> void:
	slot_buttons.clear()
	var party := profile.party_ids()
	var origin := layout.rect("party_prep.cards", Rect2(100, 150, 340, 560))
	var step := layout.num("party_prep.cards.step", 370.0)
	for i in SLOTS:
		var r := Rect2(origin.position + Vector2(step * i, 0), origin.size)
		slot_buttons.append(_slot_card(r, party[i] if i < party.size() else "", i))
	_label(layout.rect("party_prep.hint", Rect2(100, 780, 1080, 50)), tr("PARTY_PREP_HINT"), 26,
			layout.color("text_dim", Color.LIGHT_GRAY))
	# Thông tin màn sẽ vào (chỉ khi có Khai chiến).
	var info := layout.rect("party_prep.info", Rect2(1240, 150, 640, 560))
	if launch_stage:
		var bg := _panel(info, Color(0, 0, 0, 0), "StagePanel")
		bg.add_theme_stylebox_override("panel", _style(layout.color("panel", Color(0.08, 0.09, 0.12, 0.88)),
				layout.color("accent_blue", Color.SKY_BLUE), 12))
		info = info.grow(-28)
		var gc := UiKit.autoload("GameConfig")
		var sid := str(gc.selected_stage_id) if gc else "stage_01"
		var data: Dictionary = {}
		if FileAccess.file_exists(StageInfoScreen.STAGE_DATA % sid):
			data = StageMap.load_from(StageInfoScreen.STAGE_DATA % sid).data
		var title := tr(str(data["name_key"])) if data.has("name_key") else sid
		var objs := BattleObjectives.list_of(data)
		_label(Rect2(info.position, Vector2(info.size.x, 60)), tr("PARTY_PREP_STAGE") % title, 34,
				layout.color("accent_blue", Color.SKY_BLUE))
		_label(Rect2(info.position + Vector2(0, 76), Vector2(info.size.x, 44)), tr("STAGE_INFO_OBJECTIVES"), 28,
				layout.color("text_dim", Color.LIGHT_GRAY))
		var y := info.position.y + 128
		for o in objs:
			_label(Rect2(info.position.x, y, info.size.x * 0.72, 70), "☆ " + BattleObjectives.describe(o), 26)
			_label(Rect2(info.position.x + info.size.x * 0.72, y, info.size.x * 0.28, 70),
					"+%d" % int(o.get("gold", 0)), 26, layout.color("gold", Color.GOLD), HORIZONTAL_ALIGNMENT_RIGHT)
			y += 78
	var br := layout.rect("party_prep.go", Rect2(1480, 950, 400, 100))
	if launch_stage:
		_yellow_button(br, tr("PARTY_PREP_GO"), int(layout.num("party_prep.go.font", 42)), go, "GoButton")
	else:
		_yellow_button(br, tr("PARTY_PREP_CONFIRM"), int(layout.num("party_prep.go.font", 42)), leave, "GoButton")


func _slot_card(r: Rect2, id: String, index: int) -> Button:
	var b := _button(r, "", 30, edit_party, false, "Slot_%d" % index)
	var def := CharacterArt.def_of(id) if id != "" else null
	var border := layout.color("element_" + (def.element if def else ""), layout.color("button_border", Color.GRAY))
	b.add_theme_stylebox_override("normal", _style(layout.color("panel_light", Color(0.16, 0.2, 0.31)), border, 12))
	b.add_theme_stylebox_override("hover", _style(layout.color("panel_light", Color(0.16, 0.2, 0.31)).lightened(0.1), border, 12))
	if id == "":
		_label(Rect2(r.position, r.size), "+", 120, layout.color("text_dim", Color.GRAY), HORIZONTAL_ALIGNMENT_CENTER)
		_label(Rect2(r.position + Vector2(0, r.size.y - 80), Vector2(r.size.x, 60)), tr("PARTY_PREP_EMPTY"), 26,
				layout.color("text_dim", Color.GRAY), HORIZONTAL_ALIGNMENT_CENTER)
		return b
	var art := Rect2(r.position + Vector2(6, 6), r.size - Vector2(12, 80))
	var tex := CharacterArt.top_crop(CharacterArt.splash(id), art.size.x / art.size.y)
	if tex:
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# Ảnh vuông (frame idle) để nguyên cả người; splash cao thì phủ kín thẻ.
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if tex.get_width() >= tex.get_height() 				else TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.clip_contents = true
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(t, art)
	# Dải dưới: hạng + LV; trên: đội trưởng / số thứ tự.
	var strip := Rect2(r.position + Vector2(0, r.size.y - 76), Vector2(r.size.x, 76))
	var p := _panel(strip, Color.WHITE)
	p.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.95), Color(0, 0, 0, 0), 10))
	_label(Rect2(strip.position + Vector2(14, 0), Vector2(90, 76)), def.rank if def and def.rank != "" else "?", 44,
			layout.color("star", Color.GOLD))
	_label(Rect2(strip.position + Vector2(100, 0), Vector2(strip.size.x - 114, 76)),
			"LV.%d" % profile.progression.level_of(id), 36, layout.color("text_dark", Color.BLACK), HORIZONTAL_ALIGNMENT_RIGHT)
	_label(Rect2(r.position + Vector2(12, 8), Vector2(r.size.x - 24, 44)),
			("♛ " + tr("PARTY_LEADER")) if index == 0 else str(index + 1), 26, Color.WHITE)
	_label(Rect2(r.position + Vector2(0, r.size.y + 6), Vector2(r.size.x, 40)), _name(def, id), 24, Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER)
	return b


func _name(def: CharacterDef, id: String) -> String:
	if def == null:
		return id
	return "%s · %s" % [tr(def.name_key), tr(def.suit_key)] if def.suit_key != "" else tr(def.name_key)


## Chạm vào ảnh: sang màn chọn giáp.
func edit_party() -> void:
	open_scene("SCENE_PARTY_SELECT")


## Khai chiến: vào màn đã chọn.
func go() -> void:
	open_scene("SCENE_STAGE")
