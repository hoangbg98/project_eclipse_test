class_name SortieScreen
extends HubScreen
## Xuất kích (nút lục giác lớn, owner 2026-11-14, theo ảnh tham chiếu): thanh tab (Đề cử, Xuất kích, Khiêu chiến,
## Event — hiện chỉ Xuất kích có nội dung) và các thẻ:
## - Cốt truyện chính (giữa, lớn): vào màn cốt truyện đầu tiên chưa qua (hiện có Màn 1), ghi Đã xong / Mới;
## - Thử đội hình (trái): màn thử nghiệm với bù nhìn, thử kỹ năng và đội hình;
## - Ải nguyên liệu (phải): nhận nguyên liệu cường hóa / EXP — chưa có (Sắp ra mắt);
## - Đội hình (dưới): đội hiện tại; chạm để mở màn đội hình (splash, chạm để chọn giáp).
## Cốt truyện mở màn thông tin màn chơi (mục tiêu chiến đấu) → Chuẩn bị → đội hình → Khai chiến.

const TABS: Array[String] = ["SORTIE_TAB_RECOMMEND", "SORTIE_TAB_SORTIE", "SORTIE_TAB_CHALLENGE", "SORTIE_TAB_EVENT"]
const STORY_STAGES: Array[String] = ["stage_01"]

var card_buttons: Dictionary = {}


func screen_title() -> String:
	return ""


func story_stage() -> String:
	var stages: Dictionary = profile.data["progress"]["stages"]
	for id in STORY_STAGES:
		var st: Variant = stages.get(id)
		if not (st is Dictionary and bool(st.get("cleared", false))):
			return id
	return STORY_STAGES[STORY_STAGES.size() - 1]


func story_cleared() -> bool:
	var st: Variant = profile.data["progress"]["stages"].get(STORY_STAGES[STORY_STAGES.size() - 1])
	return st is Dictionary and bool(st.get("cleared", false))


func _build_body() -> void:
	card_buttons.clear()
	var tr_ := layout.rect("sortie.tabs", Rect2(560, 104, 880, 70))
	var tw := tr_.size.x / TABS.size()
	for i in TABS.size():
		# Chỉ tab Xuất kích có nội dung; tab khác bấm hiện Sắp ra mắt.
		_button(Rect2(tr_.position + Vector2(tw * i, 0), Vector2(tw - 4, tr_.size.y)), tr(TABS[i]),
				int(layout.num("sortie.tabs.font", 30)), (func() -> void: pass) if i == 1 else Callable(), i == 1,
				"Tab_%d" % i, tr("UI_COMING_SOON"))
	var tf := int(layout.num("sortie.title_font", 34))
	var sf := int(layout.num("sortie.sub_font", 24))
	_card("trial", layout.rect("sortie.trial", Rect2(262, 196, 300, 380)), "trial", tr("SORTIE_TRIAL_TITLE"),
			tr("SORTIE_TRIAL_SUB"), "", tf, sf)
	var status := tr("SORTIE_STORY_DONE") if story_cleared() else tr("SORTIE_STORY_NEW")
	_card("story", layout.rect("sortie.story", Rect2(590, 196, 820, 380)), "story", tr("SORTIE_STORY_TITLE"),
			tr("SORTIE_STORY_SUB") % _stage_title(story_stage()), status, tf + 6, sf)
	_card("material", layout.rect("sortie.material", Rect2(1438, 196, 300, 380)), "material", tr("SORTIE_MATERIAL_TITLE"),
			tr("SORTIE_MATERIAL_SUB"), tr("HUB_BADGE_SOON"), tf, sf)
	var names := PackedStringArray()
	for id in profile.party_ids():
		var p := PlayerProfile.CHARACTER_DATA % id
		var d := load(p) as CharacterDef if ResourceLoader.exists(p) else null
		names.append("%s Lv.%d" % [tr(d.name_key) if d else id, profile.progression.level_of(id)])
	_card("party", layout.rect("sortie.party", Rect2(460, 612, 1000, 230)), "character", tr("SORTIE_PARTY_TITLE"),
			" · ".join(names), tr("SORTIE_PARTY_EDIT"), tf, sf)


func _stage_title(id: String) -> String:
	var path := "res://data/stages/%s.json" % id
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		var m := StageMap.load_from(path)
		if m.data.has("name_key"):
			return tr(str(m.data["name_key"]))
	return id


## Thẻ: nền + icon lớn mờ + tiêu đề + dòng phụ + nhãn góc (trạng thái / Sắp ra mắt). Cả thẻ là nút.
func _card(key: String, r: Rect2, icon_name: String, title: String, sub: String, tag: String, tf: int, sf: int) -> void:
	var b := _button(r, "", tf, activate.bind(key), false, "Card_" + key)
	b.add_theme_stylebox_override("normal", _style(layout.color("panel_light", Color(0.16, 0.2, 0.31, 0.9)),
			layout.color("accent_blue", Color("#7FD4FF")), 8))
	card_buttons[key] = b
	var icon_side := minf(r.size.x * 0.5, r.size.y * 0.5)
	_icon(Rect2(r.position + Vector2((r.size.x - icon_side) * 0.5, 24), Vector2(icon_side, icon_side)), icon_name,
			Color(1, 1, 1, 0.85))
	# Dải chữ dưới thẻ: tiêu đề + dòng phụ (cho phép 2 dòng ở thẻ hẹp).
	var sub_lines := 1 if r.size.x > 600.0 else 2
	var strip_h := tf * 1.4 + sf * 1.35 * sub_lines + 10.0
	var strip := Rect2(r.position + Vector2(0, r.size.y - strip_h), Vector2(r.size.x, strip_h))
	_panel(strip, Color(1, 1, 1, 0.92))
	_label(Rect2(strip.position + Vector2(16, 4), Vector2(strip.size.x - 32, tf * 1.3)), title, tf,
			layout.color("text_dark", Color.BLACK))
	_label(Rect2(strip.position + Vector2(16, tf * 1.35), Vector2(strip.size.x - 32, sf * 1.35 * sub_lines)), sub, sf,
			Color("#2E7BD6"))
	if tag != "":
		_label(Rect2(r.position + Vector2(r.size.x - 260, 8), Vector2(244, 40)), tag, sf,
				layout.color("soon", Color.ORANGE) if key == "material" else layout.color("yellow", Color.YELLOW),
				HORIZONTAL_ALIGNMENT_RIGHT)


func activate(key: String) -> void:
	var gc := UiKit.autoload("GameConfig")
	match key:
		"story":
			if gc:
				gc.selected_stage_id = story_stage()
			open_scene("SCENE_STAGE_INFO")
		"trial":
			open_scene("SCENE_TEST_STAGE")
		"party":
			if gc:
				gc.prep_launch_stage = false
			open_scene("SCENE_PARTY_PREP")
		_:
			say(tr("UI_COMING_SOON"))
