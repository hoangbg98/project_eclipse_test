class_name ChapterMapScreen
extends HubScreen
## Map chương (owner 2026-11-14, theo ảnh tham chiếu): một tranh dài làm nền, người chơi kéo ngang liền mạch (chuột /
## chạm, có quán tính, lăn chuột). Trên tranh: tên phần, nút ải lục giác (mã ải, 3 huy chương = mục tiêu đã đạt,
## dấu truyện tranh, khóa / Sắp ra mắt), đường nối các ải, rương "Quà khiêu chiến" cuối mỗi phần (% huy chương,
## đủ 100% thì nhận một lần). Chạm ải mở được → (clip mở chương lần đầu) → Thông tin màn.
## Dữ liệu: ChapterBook. Kéo không dựng lại màn; chỉ thông báo / nhận quà mới gọi refresh().

const NODE_R := 74.0
const DRAG_THRESHOLD := 14.0

var chapter_num := 1
var book: ChapterBook
## Độ cuộn (px khung tranh, 0 = mép trái).
var scroll_x := 0.0
var stage_nodes: Dictionary = {}
var chest_buttons: Dictionary = {}
## Đang kéo trong lần chạm này (nút ải không nhận bấm khi vừa kéo).
var dragged := false

var _content: Control
var _press_x := 0.0
var _pressing := false
var _velocity := 0.0
var _scale := 1.0
var _width := 1920.0
var _initial_scroll_done := false


func screen_title() -> String:
	return ""


func _ready() -> void:
	_setup_layout()
	var gc := UiKit.autoload("GameConfig")
	if gc:
		chapter_num = int(gc.selected_chapter)
	book = ChapterBook.new(profile.data)
	refresh()


func chapter() -> Dictionary:
	return ChapterBook.chapter(chapter_num)


func max_scroll() -> float:
	return maxf(_width * _scale - layout.view_size.x, 0.0)


func set_scroll(x: float) -> void:
	scroll_x = clampf(x, 0.0, max_scroll())
	if _content:
		_content.position.x = -scroll_x


## Cuộn để `map_x` (tọa độ tranh) nằm giữa màn.
func center_on(map_x: float) -> void:
	set_scroll(map_x * _scale - layout.view_size.x * 0.5)


func _build() -> void:
	_build_body()
	_top_bar()


func _build_body() -> void:
	stage_nodes.clear()
	chest_buttons.clear()
	var ch := chapter()
	if ch.is_empty():
		return
	_width = float(ch.get("map_width", 1920))
	_scale = layout.view_size.y / float(ChapterBook.data().get("map_height", 1080))
	var area := Control.new()
	area.name = "MapArea"
	area.mouse_filter = Control.MOUSE_FILTER_STOP
	area.gui_input.connect(_on_area_input)
	area.clip_contents = true
	_place(area, Rect2(Vector2.ZERO, layout.view_size))
	_content = Control.new()
	_content.name = "Content"
	_content.mouse_filter = Control.MOUSE_FILTER_PASS
	_content.size = Vector2(_width, layout.view_size.y / _scale)
	_content.scale = Vector2(_scale, _scale)
	area.add_child(_content)
	var bg := TextureRect.new()
	bg.name = "MapArt"
	var path := ChapterBook.art_path(str(ch.get("map_image", "")))
	bg.texture = load(path) as Texture2D if path != "" else null
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = _content.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(bg)
	var paths := PathLines.new()
	paths.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paths.size = _content.size
	_content.add_child(paths)
	for p: Dictionary in ch["parts"]:
		var pl := _map_label(Vector2(float(p["x"]), 236), "✕ " + tr(str(p["title"])), 40, Color("#7FE3FF"))
		pl.name = "PartTitle_" + str(p["id"])
		var pts := PackedVector2Array()
		for s: Dictionary in p["stages"]:
			var pos := Vector2(float(s["pos"][0]), float(s["pos"][1]))
			pts.append(pos)
			var n := StageNode.new()
			n.name = "Stage_" + str(s["code"])
			n.setup(s, book.state_of(s), book.medals(s), self)
			n.position = pos - Vector2(NODE_R, NODE_R)
			n.pressed.connect(press_stage.bind(str(s["code"])))
			_content.add_child(n)
			stage_nodes[str(s["code"])] = n
		paths.lines.append(pts)
		_chest(p)
	# Tiêu đề chương, đường dẫn vị trí.
	_label(Rect2(34, 110, 1300, 100), tr("MAP_TITLE") % [chapter_num, tr(str(ch["title"]))], 58, Color.WHITE).name = "MapTitle"
	_label(Rect2(layout.view_size.x - 1260, layout.view_size.y - 70, 1220, 50),
			tr("MAP_BREADCRUMB") % (tr("MAP_TITLE") % [chapter_num, tr(str(ch["title"]))]), 30,
			layout.color("yellow", Color("#FFD84D")), HORIZONTAL_ALIGNMENT_RIGHT)
	if not _initial_scroll_done:
		_initial_scroll_done = true
		var gc := UiKit.autoload("GameConfig")
		var part_no := int(gc.selected_part) if gc else 0
		var parts: Array = ch["parts"]
		if part_no > 0 and part_no <= parts.size():
			set_scroll(float(parts[part_no - 1]["x"]) * _scale - 120.0)
		else:
			center_on(float(book.current_stage(chapter_num).get("pos", [0, 0])[0]))
	else:
		set_scroll(scroll_x)


func _map_label(pos: Vector2, text: String, size_: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size_)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(l)
	return l


func _chest(p: Dictionary) -> void:
	var pct := book.part_percent(p)
	var claimed := book.part_claimed(str(p["id"]))
	var at := Vector2(float(p["chest_x"]) - 70, 820)
	var b := Button.new()
	b.name = "Chest_" + str(p["id"])
	b.focus_mode = Control.FOCUS_NONE
	b.position = at
	b.size = Vector2(110, 110)
	b.text = "✓" if claimed else ("!" if pct >= 100 else "◆")
	b.add_theme_font_size_override("font_size", 44)
	var col := Color("#3BC9E8") if not claimed else Color(0.5, 0.5, 0.55)
	var sb := _style(Color(0.05, 0.1, 0.18, 0.85), col, 55)
	sb.set_border_width_all(8)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.pressed.connect(claim_chest.bind(str(p["id"])))
	_content.add_child(b)
	chest_buttons[str(p["id"])] = b
	_map_label(at + Vector2(130, 6), tr("MAP_CHEST"), 36, Color(1, 1, 1, 0.9))
	_map_label(at + Vector2(130, 56), (tr("MAP_CHEST_DONE") if claimed else "%d.0%%" % pct), 30, Color(1, 1, 1, 0.8))


# ---------- Kéo ----------

func _on_area_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pressing = true
				dragged = false
				_press_x = mb.position.x
				_velocity = 0.0
			else:
				_pressing = false
		elif mb.pressed and mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT]:
			set_scroll(scroll_x - 160.0)
		elif mb.pressed and mb.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT]:
			set_scroll(scroll_x + 160.0)
	elif event is InputEventMouseMotion and _pressing:
		var mm := event as InputEventMouseMotion
		if not dragged and absf(mm.position.x - _press_x) > DRAG_THRESHOLD:
			dragged = true
		if dragged:
			set_scroll(scroll_x - mm.relative.x)
			_velocity = -mm.relative.x / maxf(get_process_delta_time(), 0.001)


func _process(delta: float) -> void:
	if not _pressing and absf(_velocity) > 5.0:
		set_scroll(scroll_x + _velocity * delta)
		_velocity = move_toward(_velocity, 0.0, absf(_velocity) * 5.0 * delta + 40.0 * delta)


# ---------- Bấm ----------

func press_stage(code: String) -> void:
	var s := ChapterBook.stage(code)
	match book.state_of(s):
		ChapterBook.STATE_SOON:
			say(tr("MAP_STAGE_SOON") % code)
		ChapterBook.STATE_LOCKED:
			say(tr("MAP_STAGE_LOCKED") % code)
		_:
			var gc := UiKit.autoload("GameConfig")
			if gc:
				gc.selected_stage_id = str(s["stage_id"])
			var clip := str(StageInfoScreen.stage_data_of(str(s["stage_id"])).get("open_clip", ""))
			if gc and StoryClip.should_play(clip, profile.data):
				gc.story_clip_id = clip
				gc.story_clip_next = gc.SCENE_STAGE_INFO
				open_scene("SCENE_STORY_CLIP")
			else:
				open_scene("SCENE_STAGE_INFO")


func claim_chest(id: String) -> void:
	if dragged:
		return
	var r := book.claim_part(id, profile)
	match r:
		ChapterBook.CLAIM_OK:
			notice = tr("MAP_CHEST_GOT") % tr(str(ChapterBook.part(id)["title"]))
			commit()
		ChapterBook.CLAIM_DONE:
			say(tr("MAP_CHEST_ALREADY"))
		_:
			say(tr("MAP_CHEST_NOT_READY"))


## Nút ải lục giác: ảnh nền cắt từ màu chương, mã ải phía trên, 3 huy chương phía dưới, dấu truyện, khóa.
class StageNode extends Control:
	signal pressed

	var stage: Dictionary
	var state := ""
	var medals := 0
	var screen: ChapterMapScreen
	var _down := false

	func setup(s: Dictionary, st: String, m: int, owner_screen: ChapterMapScreen) -> void:
		stage = s
		state = st
		medals = m
		screen = owner_screen
		size = Vector2(ChapterMapScreen.NODE_R * 2, ChapterMapScreen.NODE_R * 2)
		mouse_filter = Control.MOUSE_FILTER_PASS
		tooltip_text = str(s["code"])

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_down = true
			elif _down:
				_down = false
				if screen == null or not screen.dragged:
					pressed.emit()

	func _hex(r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var c := size * 0.5
		for i in 6:
			var a := deg_to_rad(60.0 * i - 90.0)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		return pts

	func _draw() -> void:
		var r := ChapterMapScreen.NODE_R
		var f := ThemeDB.fallback_font
		var playable := state in [ChapterBook.STATE_OPEN, ChapterBook.STATE_CLEARED]
		var glow := Color("#5CE1FF") if playable else Color(0.5, 0.55, 0.65)
		draw_colored_polygon(_hex(r + 8), Color(glow, 0.35))
		var fill := Color(0.14, 0.22, 0.36) if playable else Color(0.2, 0.22, 0.27)
		if bool(stage.get("boss", false)):
			fill = Color(0.36, 0.16, 0.16) if playable else Color(0.28, 0.2, 0.2)
		draw_colored_polygon(_hex(r), fill)
		var outline := _hex(r)
		outline.append(outline[0])
		draw_polyline(outline, Color.WHITE if playable else Color(0.7, 0.72, 0.78), 5.0, true)
		var code := str(stage["code"])
		draw_string(f, Vector2(0, -16), code, HORIZONTAL_ALIGNMENT_CENTER, size.x, 40, Color.WHITE)
		var mid := size * 0.5
		if state == ChapterBook.STATE_SOON:
			draw_string(f, Vector2(0, mid.y + 10), TranslationServer.translate("CHAPTER_SOON"),
					HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color(1, 0.75, 0.35))
		elif state == ChapterBook.STATE_LOCKED:
			draw_arc(mid + Vector2(0, -8), 14, PI, TAU, 16, Color.WHITE, 5.0, true)     # ổ khóa
			draw_rect(Rect2(mid + Vector2(-20, -8), Vector2(40, 30)), Color.WHITE)
		else:
			draw_string(f, Vector2(0, mid.y + 16), "BOSS" if bool(stage.get("boss", false)) else "▶",
					HORIZONTAL_ALIGNMENT_CENTER, size.x, 40 if not bool(stage.get("boss", false)) else 30, Color.WHITE)
		for i in ChapterBook.MEDALS_PER_STAGE:      # huy chương
			var p := Vector2(mid.x + (i - 1) * 40.0, size.y - 6)
			var on := i < medals
			draw_circle(p, 17, Color(0.1, 0.1, 0.12))
			draw_circle(p, 13, Color("#F2C230") if on else Color(0.4, 0.42, 0.48))
		if bool(stage.get("clip", false)):            # dấu truyện tranh
			var c := Vector2(14, 22)
			draw_colored_polygon(_hex_at(c, 26), Color("#FFB23E"))
			draw_rect(Rect2(c - Vector2(12, 8), Vector2(16, 16)), Color.WHITE)
			draw_colored_polygon(PackedVector2Array([c + Vector2(4, 0), c + Vector2(13, -7), c + Vector2(13, 7)]), Color.WHITE)

	func _hex_at(c: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 6:
			var a := deg_to_rad(60.0 * i)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		return pts


## Đường nối các ải trong mỗi phần (vạch sáng xanh).
class PathLines extends Control:
	var lines: Array = []

	func _draw() -> void:
		for pts: PackedVector2Array in lines:
			if pts.size() >= 2:
				draw_polyline(pts, Color(0.36, 0.88, 1.0, 0.35), 16.0, true)
				draw_polyline(pts, Color(0.36, 0.88, 1.0, 0.95), 6.0, true)
