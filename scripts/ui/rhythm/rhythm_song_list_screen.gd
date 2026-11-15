class_name RhythmSongListScreen
extends RhythmMaterialScreen
## Chế độ Vô tận (M10): danh sách bài từ danh mục máy chủ, chọn độ khó (Dễ / Thường / Khó) hoặc lọc Yêu thích.
## Mỗi dòng (theo ảnh tham chiếu của owner): số thứ tự + vương miện mờ, tên bài, tác giả, vương miện theo hạng tốt
## nhất (S = 3, A = 2, B = 1), mức độ khó, tim yêu thích, nút Chơi.

const ROW_H := 200.0

var difficulty := "normal"
var favorites_only := false
var scroll_value := 0
var row_buttons: Dictionary = {}


func screen_title() -> String:
	return tr("RHYTHM_ENDLESS_TITLE")


func _difficulties() -> Array:
	var d: Array = _progress().defs.get("endless", {}).get("difficulties", ["easy", "normal", "hard"])
	return d


func visible_songs() -> Array:
	var out: Array = []
	for s in (library.songs() if library else []):
		if favorites_only and not _progress().is_favorite(str(s["id"])):
			continue
		if s.get("charts", {}).has(difficulty):
			out.append(s)
	return out


func _build_body() -> void:
	row_buttons.clear()
	var prog := _progress()
	# Thanh chọn độ khó + Yêu thích.
	var tabs: Array = _difficulties() + ["fav"]
	var tw := 230.0
	var tx := (layout.view_size.x - tw * tabs.size()) * 0.5
	for i in tabs.size():
		var key: String = tabs[i]
		var sel := (key == "fav" and favorites_only) or (key == difficulty and not favorites_only)
		var text := tr("RHYTHM_FAVORITES") if key == "fav" else tr("RHYTHM_DIFF_" + key.to_upper())
		_button(Rect2(tx + i * tw, 104, tw - 10, 70), text, 28, _select_tab.bind(key), sel, "Tab_" + key)
	var status := ""
	match catalog_state:
		"loading":
			status = tr("RHYTHM_CATALOG_LOADING")
		"cache":
			status = tr("RHYTHM_CATALOG_OFFLINE")
		"none":
			status = tr("RHYTHM_CATALOG_NONE")
	if status != "":
		_label(Rect2(1300, 104, 560, 70), status, 24, layout.color("soon", Color.ORANGE), HORIZONTAL_ALIGNMENT_RIGHT)
	var list_rect := Rect2(140, 190, layout.view_size.x - 280, layout.view_size.y - 210)
	var scroll := ScrollContainer.new()
	scroll.name = "SongScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_place(scroll, list_rect)
	var content := Control.new()
	content.name = "Rows"
	var songs := visible_songs()
	content.custom_minimum_size = Vector2(list_rect.size.x - 24, maxf(songs.size() * ROW_H, 10.0))
	scroll.add_child(content)
	if songs.is_empty():
		var empty := Label.new()
		empty.text = tr("RHYTHM_NO_SONGS")
		empty.position = Vector2(0, 40)
		empty.size = Vector2(list_rect.size.x, 60)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 30)
		content.add_child(empty)
	var all_songs: Array = library.songs() if library else []
	for i in songs.size():
		_row(content, Rect2(0, i * ROW_H, content.custom_minimum_size.x, ROW_H - 18), songs[i], all_songs.find(songs[i]) + 1, prog)
	scroll.scroll_vertical = scroll_value
	scroll.get_v_scroll_bar().value_changed.connect(func(v: float) -> void: scroll_value = int(v))


func _select_tab(key: String) -> void:
	if key == "fav":
		favorites_only = not favorites_only
	else:
		difficulty = key
		favorites_only = false
	scroll_value = 0
	refresh()


func _row_style(bg: Color, radius := 18) -> StyleBoxFlat:
	var s := _style(bg, Color(0, 0, 0, 0), radius)
	s.shadow_color = Color(0, 0, 0, 0.25)
	s.shadow_size = 6
	return s


func _row(parent: Control, r: Rect2, song: Dictionary, number: int, prog: RhythmProgress) -> void:
	var id := str(song["id"])
	var key := RhythmProgress.endless_key(id, difficulty)
	var row := Panel.new()
	row.name = "Row_" + id
	row.position = r.position
	row.size = r.size
	row.add_theme_stylebox_override("panel", _row_style(Color("#FFFFFF")))
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(row)
	# Khối số thứ tự (vàng) bên trái.
	var badge := Panel.new()
	badge.position = Vector2.ZERO
	badge.size = Vector2(170, r.size.y)
	var bs := _row_style(Color("#F7B23B"))
	bs.corner_radius_top_right = 0
	bs.corner_radius_bottom_right = 0
	bs.shadow_size = 0
	badge.add_theme_stylebox_override("panel", bs)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(badge)
	_row_label(row, "♛", Vector2(30, 40), Vector2(150, 140), 110, Color(1, 1, 1, 0.35))
	_row_label(row, "%d" % number, Vector2(16, 6), Vector2(100, 64), 46, Color.WHITE)
	_row_label(row, str(song.get("title", id)), Vector2(200, 8), Vector2(r.size.x - 760, 66), 46, Color("#3B4A63"))
	_row_label(row, str(song.get("artist", "")), Vector2(200, 72), Vector2(r.size.x - 760, 44), 28, Color("#8FA0BC"))
	var crowns := RhythmJudge.crowns_of(prog.best_rank(key))
	var crown_text := ""
	for c in 3:
		crown_text += "♛" if c < crowns else "♔"
	_row_label(row, crown_text, Vector2(200, 116), Vector2(260, 60), 48, Color("#F7B23B") if crowns > 0 else Color("#D5DCE8"))
	var level := int(song.get("charts", {}).get(difficulty, {}).get("level", 0))
	var lvl := Panel.new()
	lvl.position = Vector2(480, 124)
	lvl.size = Vector2(120, 48)
	lvl.add_theme_stylebox_override("panel", _style(Color("#EEF3FA"), Color("#C9D4E5"), 24))
	lvl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lvl)
	_row_label(row, "▮ %d" % level, Vector2(480, 124), Vector2(120, 48), 28, Color("#7D8DA8"), HORIZONTAL_ALIGNMENT_CENTER)
	var best := int(prog.record(key).get("best_score", 0))
	if best > 0:
		_row_label(row, tr("RHYTHM_BEST_SCORE") % best, Vector2(620, 128), Vector2(360, 44), 26, Color("#8FA0BC"))
	var fav := prog.is_favorite(id)
	var heart := Button.new()
	heart.name = "Fav_" + id
	heart.text = "♥" if fav else "♡"
	heart.flat = true
	heart.focus_mode = Control.FOCUS_NONE
	heart.position = Vector2(r.size.x - 520, 40)
	heart.size = Vector2(128, 128)
	heart.add_theme_font_size_override("font_size", 64)
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		heart.add_theme_color_override(k, Color("#FF5C8A") if fav else Color("#C9D4E5"))
	heart.pressed.connect(toggle_favorite.bind(id))
	row.add_child(heart)
	var play := Button.new()
	play.name = "Play_" + id
	play.text = tr("RHYTHM_PLAY")
	play.focus_mode = Control.FOCUS_NONE
	play.position = Vector2(r.size.x - 360, 34)
	play.size = Vector2(320, 128)
	play.add_theme_font_size_override("font_size", 52)
	var blue := Color("#1DA1E2")
	play.add_theme_stylebox_override("normal", _style(blue, Color(0, 0, 0, 0), 64))
	play.add_theme_stylebox_override("hover", _style(blue.lightened(0.1), Color(0, 0, 0, 0), 64))
	play.add_theme_stylebox_override("pressed", _style(blue.darkened(0.15), Color(0, 0, 0, 0), 64))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		play.add_theme_color_override(k, Color.WHITE)
	play.pressed.connect(play_song.bind(id))
	row.add_child(play)
	row_buttons[id] = play


func _row_label(parent: Control, text: String, pos: Vector2, size_: Vector2, font_size: int, col: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size_
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func toggle_favorite(song_id: String) -> void:
	_progress().toggle_favorite(song_id)
	commit()


func play_song(song_id: String) -> void:
	await start_play(song_id, difficulty, RhythmProgress.endless_key(song_id, difficulty), false)
