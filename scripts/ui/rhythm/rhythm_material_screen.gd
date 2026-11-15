class_name RhythmMaterialScreen
extends HubScreen
## Ải nguyên liệu nhịp điệu (M10): 5 ải con mở lần lượt (ải 5 là boss, bản nốt cố định), thẻ Vô tận mở khi qua
## ải 5 (chọn bài ở RhythmSongListScreen). Nhạc + bản nốt tải từ máy chủ lần đầu rồi lưu cache (RhythmLibrary).

var library: RhythmLibrary
var progress: RhythmProgress
## "" | "loading" | "online" | "cache" | "none"
var catalog_state := ""
var busy := false
var card_buttons: Dictionary = {}


func screen_title() -> String:
	return tr("RHYTHM_MATERIAL_TITLE")


func _ready() -> void:
	super._ready()
	if library == null:
		library = RhythmLibrary.create(self)
	load_catalog()


func load_catalog() -> void:
	catalog_state = "loading"
	refresh()
	var ok: bool = await library.refresh_catalog()
	catalog_state = ("cache" if library.from_cache else "online") if ok else "none"
	refresh()


func _progress() -> RhythmProgress:
	if progress == null or progress.profile != profile:
		progress = RhythmProgress.new(profile)
	return progress


func _build_body() -> void:
	card_buttons.clear()
	var prog := _progress()
	var status := ""
	match catalog_state:
		"loading":
			status = tr("RHYTHM_CATALOG_LOADING")
		"cache":
			status = tr("RHYTHM_CATALOG_OFFLINE")
		"none":
			status = tr("RHYTHM_CATALOG_NONE")
	_label(Rect2(260, 104, 1400, 50), status if status != "" else tr("RHYTHM_MATERIAL_SUB"), 26,
			layout.color("soon", Color.ORANGE) if status != "" else Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER).name = "Status"
	var stages := prog.stages()
	var cw := 320.0
	var gap := 28.0
	var x0 := (layout.view_size.x - (cw * stages.size() + gap * (stages.size() - 1))) * 0.5
	for i in stages.size():
		var s: Dictionary = stages[i]
		_stage_card(Rect2(x0 + i * (cw + gap), 170, cw, 520), s, prog)
	_endless_card(Rect2(x0, 720, cw * stages.size() + gap * (stages.size() - 1), 200), prog)


func _stage_card(r: Rect2, s: Dictionary, prog: RhythmProgress) -> void:
	var id := str(s["id"])
	var unlocked := prog.is_unlocked(id)
	var cleared := prog.is_cleared(id)
	var is_boss := bool(s.get("boss", false))
	var b := _button(r, "", 30, start_stage.bind(id), false, "Stage_" + id)
	var border := Color("#FF6B6B") if is_boss else layout.color("accent_blue", Color("#7FD4FF"))
	var bg := Color("#3A1730", 0.92) if is_boss else layout.color("panel_light", Color(0.16, 0.2, 0.31, 0.9))
	b.add_theme_stylebox_override("normal", _style(bg if unlocked else bg.darkened(0.5), border if unlocked else border.darkened(0.6), 10))
	b.add_theme_stylebox_override("hover", _style(bg.lightened(0.08), border, 10))
	card_buttons[id] = b
	var p := r.position
	_label(Rect2(p + Vector2(20, 14), Vector2(r.size.x - 40, 56)), str(s.get("code", "")), 44,
			Color("#FFD84D") if not is_boss else Color("#FF8A8A"))
	_label(Rect2(p + Vector2(20, 74), Vector2(r.size.x - 40, 90)), tr(str(s.get("name_key", id))), 30)
	var song := library.song(str(s.get("song", ""))) if library else {}
	var chart := library.chart_info(str(s.get("song", "")), str(s.get("chart", ""))) if library else {}
	_label(Rect2(p + Vector2(20, 168), Vector2(r.size.x - 40, 76)), "♪ " + str(song.get("title", "—")), 24, Color("#9FE3FF"))
	var lvl := tr("RHYTHM_LEVEL") % int(chart.get("level", 0)) if not chart.is_empty() else ""
	_label(Rect2(p + Vector2(20, 246), Vector2(r.size.x - 40, 40)), lvl, 24, Color(1, 1, 1, 0.8))
	_label(Rect2(p + Vector2(20, 290), Vector2(r.size.x - 40, 150)), _reward_preview(prog.base_rewards(id)), 22,
			Color(1, 1, 1, 0.7))
	var tag := tr("RHYTHM_LOCKED")
	var tag_col := Color(1, 1, 1, 0.5)
	if cleared:
		tag = tr("RHYTHM_CLEARED") + ("  " + prog.best_rank(id) if prog.best_rank(id) != "" else "")
		tag_col = Color("#7DFFB0")
	elif unlocked:
		tag = tr("RHYTHM_BOSS") if is_boss else tr("SORTIE_STORY_NEW")
		tag_col = Color("#FFD84D")
	_label(Rect2(p + Vector2(20, r.size.y - 60), Vector2(r.size.x - 40, 48)), tag, 28, tag_col, HORIZONTAL_ALIGNMENT_CENTER)


func _endless_card(r: Rect2, prog: RhythmProgress) -> void:
	var open := prog.endless_unlocked()
	var b := _button(r, "", 30, open_endless, false, "Card_endless")
	var col := Color("#5B2BC2", 0.92)
	b.add_theme_stylebox_override("normal", _style(col if open else col.darkened(0.55), Color("#C9A2FF"), 12))
	b.add_theme_stylebox_override("hover", _style(col.lightened(0.1), Color("#C9A2FF"), 12))
	card_buttons["endless"] = b
	_label(Rect2(r.position + Vector2(40, 20), Vector2(r.size.x - 80, 70)), tr("RHYTHM_ENDLESS_TITLE"), 48, Color("#FFE14D"))
	_label(Rect2(r.position + Vector2(40, 100), Vector2(r.size.x - 80, 70)),
			tr("RHYTHM_ENDLESS_SUB") if open else tr("RHYTHM_ENDLESS_LOCKED"), 28, Color(1, 1, 1, 0.85))


func _reward_preview(rew: Dictionary) -> String:
	var parts := PackedStringArray()
	var items := PlayerProfile.item_defs()
	var mats: Dictionary = rew.get("materials", {})
	for id in mats:
		var d: Resource = items.get_def(str(id)) if items else null
		parts.append("%s ×%d" % [tr(str(d.get("name_key"))) if d else str(id), int(mats[id])])
	if int(rew.get("gold", 0)) > 0:
		parts.append("%s ×%d" % [tr("CURRENCY_GOLD"), int(rew["gold"])])
	return "\n".join(parts)


func start_stage(id: String) -> void:
	var prog := _progress()
	if not prog.is_unlocked(id):
		say(tr("RHYTHM_LOCKED_HINT"))
		return
	var s := prog.stage(id)
	await start_play(str(s["song"]), str(s["chart"]), id, bool(s.get("boss", false)))


func open_endless() -> void:
	if not _progress().endless_unlocked():
		say(tr("RHYTHM_ENDLESS_LOCKED"))
		return
	open_scene("SCENE_RHYTHM_SONGS")


## Tải (nếu cần) rồi mở màn chơi. Dùng chung với danh sách bài.
func start_play(song_id: String, chart_key: String, record_key: String, boss_ := false) -> void:
	if busy:
		return
	if library.song(song_id).is_empty():
		say(tr("RHYTHM_CATALOG_NONE"))
		return
	if not library.is_cached(song_id, chart_key):
		busy = true
		say(tr("RHYTHM_DOWNLOADING") % (float(library.missing_bytes(song_id, chart_key)) / 1048576.0))
		var res: Dictionary = await library.ensure(song_id, chart_key)
		busy = false
		if not bool(res.get("ok", false)):
			say(tr("RHYTHM_DOWNLOAD_FAILED") % str(res.get("error", "")))
			return
		notice = ""
	var gc := UiKit.autoload("GameConfig")
	if gc:
		gc.rhythm_song_id = song_id
		gc.rhythm_chart_key = chart_key
		gc.rhythm_record_key = record_key
		gc.rhythm_boss = boss_
	open_scene("SCENE_RHYTHM_STAGE")
