class_name ChapterSelectScreen
extends HubScreen
## Chọn chương cốt truyện (owner 2026-11-14, theo ảnh tham chiếu): cột trái là "Hành trình mới nhất" + các nhóm chương
## (mỗi nhóm gộp 1–2 chương liền mạch nội dung), bên phải là tên nhóm, % tiến độ và thẻ chương (ảnh, thanh %, tên,
## "Chương N"). Nhóm chỉ có một chương nhiều phần thì mỗi phần một thẻ. Chạm thẻ → map chương.
## Dữ liệu: ChapterBook (data/story/chapters.json). Mọi chương xem được map; ải chưa có màn chơi khóa "Sắp ra mắt".

## Nhóm đang chọn (id trong chapters.json); rỗng = nhóm của hành trình mới nhất.
var arc_id := ""
var book: ChapterBook
var card_buttons: Dictionary = {}


func screen_title() -> String:
	return ""


func _ready() -> void:
	_setup_layout()
	book = ChapterBook.new(profile.data)
	if arc_id == "":
		arc_id = str(book.latest_arc().get("id", ""))
	refresh()


func current_arc() -> Dictionary:
	for a: Dictionary in ChapterBook.arcs():
		if str(a["id"]) == arc_id:
			return a
	return {}


## Thẻ của nhóm: [{num, part (0 = cả chương), key}].
func cards_of(arc: Dictionary) -> Array:
	var out: Array = []
	var nums: Array = arc.get("chapters", [])
	for n in nums:
		var ch := ChapterBook.chapter(int(n))
		var parts: Array = ch.get("parts", [])
		if nums.size() == 1 and parts.size() > 1:
			for i in parts.size():
				out.append({"num": int(n), "part": i + 1, "key": "%d_%d" % [int(n), i + 1]})
		else:
			out.append({"num": int(n), "part": 0, "key": str(int(n))})
	return out


func select_arc(id: String) -> void:
	arc_id = id
	notice = ""
	refresh()


## Cỡ chữ lớn nhất (≥ 16) để `text` một dòng vừa `max_w`.
func _fit(text: String, size_: int, max_w: float) -> int:
	while size_ > 16 and get_theme_default_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_).x > max_w:
		size_ -= 1
	return size_


func _range_text(arc: Dictionary) -> String:
	var nums: Array = arc.get("chapters", [])
	if nums.size() == 1:
		var ch := ChapterBook.chapter(int(nums[0]))
		var n_parts: int = (ch.get("parts", []) as Array).size()
		return tr("CHAPTER_RANGE_PARTS") % [int(nums[0]), n_parts] if n_parts > 1 else tr("CHAPTER_NUM") % int(nums[0])
	return tr("CHAPTER_RANGE") % [int(nums[0]), int(nums[nums.size() - 1])]


func _build_body() -> void:
	card_buttons.clear()
	var accent := layout.color("accent_blue", Color("#7FD4FF"))
	# ----- Cột trái -----
	var x := 36.0
	var y := 136.0
	var latest := book.latest_arc()
	var lb := _button(Rect2(x, y, 336, 64), "✦ " + tr("CHAPTER_LATEST") + " ✦", 28,
			select_arc.bind(str(latest.get("id", ""))), false, "LatestButton")
	lb.add_theme_stylebox_override("normal", _style(Color("#8E6FD8"), Color("#B9A2FF"), 6))
	y += 76
	for a: Dictionary in ChapterBook.arcs():
		var on := str(a["id"]) == arc_id
		var b := _button(Rect2(x, y, 336, 92), "", 26, select_arc.bind(str(a["id"])), on, "Arc_" + str(a["id"]))
		var at := tr(str(a["title"]))
		var al := _label(Rect2(x + 14, y + 6, 308, 46), at, _fit(at, 26, 300.0),
				layout.color("text_dark", Color.BLACK) if on else Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
		al.autowrap_mode = TextServer.AUTOWRAP_OFF
		_label(Rect2(x + 14, y + 50, 308, 36), _range_text(a), 22, accent, HORIZONTAL_ALIGNMENT_RIGHT)
		if a == latest and not on:
			_label(Rect2(x + 260, y - 14, 90, 30), tr("CHAPTER_NEW"), 20, layout.color("yellow", Color.YELLOW))
		b.tooltip_text = tr(str(a["title"]))
		y += 104
	# ----- Bên phải -----
	var arc := current_arc()
	if arc.is_empty():
		return
	var right := Rect2(420, 136, layout.view_size.x - 460, 820)
	_label(Rect2(right.position, Vector2(right.size.x * 0.6, 70)), tr(str(arc["title"])), 44, Color.WHITE).name = "ArcTitle"
	_label(Rect2(right.position + Vector2(right.size.x * 0.5, 10), Vector2(right.size.x * 0.5, 60)),
			tr("CHAPTER_PROGRESS") % book.arc_progress(arc), 30, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_RIGHT).name = "ArcProgress"
	_panel(Rect2(right.position + Vector2(0, 78), Vector2(right.size.x, 3)), Color(1, 1, 1, 0.35))
	_panel(Rect2(right.position + Vector2(0, 770), Vector2(right.size.x, 3)), Color(1, 1, 1, 0.35))
	var cards := cards_of(arc)
	var cw := 380.0
	var gap := 54.0
	var total := cards.size() * cw + (cards.size() - 1) * gap
	var cx := right.position.x + (right.size.x - total) * 0.5
	for c: Dictionary in cards:
		_card(Rect2(cx, right.position.y + 120, cw, 600), c)
		cx += cw + gap


func _card(r: Rect2, c: Dictionary) -> void:
	var ch := ChapterBook.chapter(int(c["num"]))
	var b := _button(r, "", 10, open_chapter.bind(int(c["num"]), int(c["part"])), false, "ChapterCard_" + str(c["key"]))
	b.add_theme_stylebox_override("normal", _style(Color(0.1, 0.12, 0.18), Color(1, 1, 1, 0.6), 4))
	var art_h := r.size.y - 130
	var path := ChapterBook.art_path(str(ch.get("card_image", "")))
	var tex := load(path) as Texture2D if path != "" else null
	var art := _art(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, art_h)), tex, tr(str(ch.get("title", ""))))
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pct := book.chapter_progress(int(c["num"]))
	if int(c["part"]) > 0:
		pct = _part_progress(ch, int(c["part"]))
	var bar := Rect2(r.position + Vector2(r.size.x * 0.25, art_h - 30), Vector2(r.size.x * 0.5, 18))
	_panel(bar, Color(0, 0, 0, 0.6))
	if pct > 0:
		_panel(Rect2(bar.position, Vector2(bar.size.x * pct / 100.0, bar.size.y)), Color("#7BD34A"))
	_label(Rect2(bar.position - Vector2(0, 6), Vector2(bar.size.x, 30)), "%d%%" % pct, 22, Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER).name = "Pct_" + str(c["key"])
	var strip := Rect2(r.position + Vector2(2, art_h + 2), Vector2(r.size.x - 4, 126))
	_panel(strip, Color(1, 1, 1, 0.96))
	var title := tr(str(ch.get("title", "")))
	if int(c["part"]) > 0:
		title = tr(str((ch["parts"] as Array)[int(c["part"]) - 1]["title"]))
	_label(Rect2(strip.position + Vector2(10, 4), Vector2(strip.size.x - 20, 70)), title, 32,
			layout.color("text_dark", Color.BLACK), HORIZONTAL_ALIGNMENT_CENTER)
	var sub := tr("CHAPTER_NUM") % int(c["num"]) if int(c["part"]) == 0 \
			else tr("CHAPTER_NUM_PART") % [int(c["num"]), int(c["part"])]
	_label(Rect2(strip.position + Vector2(10, 76), Vector2(strip.size.x - 20, 44)), sub, 28, Color("#2EA8E6"),
			HORIZONTAL_ALIGNMENT_CENTER)
	if not _has_playable(ch):
		_label(Rect2(r.position + Vector2(r.size.x - 220, 10), Vector2(206, 40)), tr("CHAPTER_SOON"), 24,
				layout.color("soon", Color.ORANGE), HORIZONTAL_ALIGNMENT_RIGHT)
	card_buttons[str(c["key"])] = b


func _part_progress(ch: Dictionary, part_no: int) -> int:
	var ss: Array = (ch["parts"] as Array)[part_no - 1]["stages"]
	var done := 0
	for s in ss:
		if book.is_cleared(s):
			done += 1
	return roundi(100.0 * done / ss.size()) if not ss.is_empty() else 0


func _has_playable(ch: Dictionary) -> bool:
	for p: Dictionary in ch.get("parts", []):
		for s: Dictionary in p["stages"]:
			if str(s.get("stage_id", "")) != "":
				return true
	return false


## Mở map chương `num` (part > 0: cuộn tới phần đó).
func open_chapter(num: int, part_no := 0) -> void:
	var gc := UiKit.autoload("GameConfig")
	if gc:
		gc.selected_chapter = num
		gc.selected_part = part_no
	open_scene("SCENE_CHAPTER_MAP")
