class_name RhythmStage
extends Control
## Màn chơi nhịp điệu (M10, docs/design/RHYTHM_MODE.md): nhạc phát từ file đã tải (RhythmLibrary), nốt bay từ phải
## sang trái trên 2 làn (trên / dưới), nhân vật đầu đội đứng ở vạch chấm bên trái.
## Phím: trên = D / F / ↑, dưới = J / K / ↓ (InputRouter `rhythm_up` / `rhythm_down`); cảm ứng: nửa trái = trên,
## nửa phải = dưới. Esc / P / nút ‖ = tạm dừng.
##
## Logic chấm ở RhythmJudge; màn này chỉ đọc đồng hồ nhạc, chuyển input và vẽ. Lượt chơi lấy từ GameConfig
## (rhythm_song_id / rhythm_chart_key / rhythm_record_key / rhythm_boss) hoặc `setup()` (test).

signal finished(result: Dictionary)

const RULES_PATH := "res://data/rhythm/rhythm_rules.tres"
const LAYOUT_PATH := "res://data/ui/rhythm_layout.json"
const BACK_GROUP := &"back_interceptor"
const TUTORIAL_PATH := "res://data/rhythm/tutorial.json"
const INTRO_EXTRA_SEC := 3.0

var rules: RhythmRules
var chart: RhythmChart
var judge: RhythmJudge
var layout: UiLayout
var record_key := ""
var song_title := ""
var boss := false
## Tự ấn đúng mọi nốt (test, xem thử).
var autoplay := false
## true: thời gian chỉ chạy qua `advance()` (test, không có nhạc).
var manual_clock := false
## false: không ghi save / không nhận thưởng thật vào SaveService (test dùng `profile` riêng).
var save_enabled := true
var profile: PlayerProfile
## Kết quả cuối lượt (rỗng khi chưa xong).
var result: Dictionary = {}
var paused := false
var load_error := ""
## Tốc độ quái của lượt (px / giây, 0 = tốc độ chuẩn của luật). Vòng chấm phóng theo (RhythmRules.for_speed).
var note_speed := 0.0
## Số nốt bị bỏ để hitbox cùng làn không đè nhau ở tốc độ này.
var spacing_dropped := 0
## Hướng dẫn trong ải trước khi vào bài (ải N-1 lần đầu, data/rhythm/tutorial.json).
var tutorial := false
## Dòng giới thiệu hiện lúc đếm ngược (vd cơ chế mới của ải); có thì đếm ngược dài thêm INTRO_EXTRA_SEC.
var intro_key := ""
## Chỉ giữ các loại nốt này (RhythmChart.limit_kinds); rỗng = tất cả.
var kinds: Array = []
## "tutorial" khi đang luyện, "play" khi chơi bài thật.
var phase := "play"

var player: AudioStreamPlayer
var now := -2.0

var _elapsed := 0.0
var _audio_started := false
var _field: Control
## Lớp vẽ hitbox vàng (trên ảnh quái, dưới nhân vật).
var _hit_layer: Control
var _hud: Control
var _sprite: AnimatedSprite2D
var _sprite_base := Vector2.ZERO
var _lane_keys := {RhythmChart.LANE_UP: 0, RhythmChart.LANE_DOWN: 0}
var _touch_lane: Dictionary = {}   # chỉ số ngón -> làn
var _popups: Array[Dictionary] = []   # {text, color, lane, born}
var _bursts: Array[Dictionary] = []   # {pos, color, born}
var _auto_done: Dictionary = {}   # chỉ số nốt -> bước autoplay đã làm
var _air_until := -1.0
var _hurt_until := -1.0
var _attack_flip := 0
var _end_at := -1.0
var _pause_layer: Control
var _result_layer: Control
var _labels: Dictionary = {}
const HIT_RESULTS: Array[String] = ["perfect", "great", "good", "normal"]
var _enemy_frames_cache: Dictionary = {}
var _boss_sprite: AnimatedSprite2D
var _lead := 2.0
var _real_chart: RhythmChart
var _tut: Dictionary = {}
var _tut_rules: RhythmRules
var _tut_step := 0
var _tut_msg := ""
var _tut_next_at := -1.0
var _tut_done_at := -1.0
var _tut_panel: Control
var _tut_labels: Dictionary = {}
var _enemy_visuals: Dictionary = {} # note index -> {sprites, chain, dying_until}
## Khung ảnh quái (px). Cỡ hiển thị = đường kính vòng chấm × enemy.ring_ratio (owner 2026-11-16: to hơn gấp đôi vòng).
const ENEMY_FRAME := 256.0


func _ready() -> void:
	add_to_group(BACK_GROUP)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_rules := load(RULES_PATH) as RhythmRules
	rules = base_rules
	layout = UiLayout.load_from(LAYOUT_PATH)
	player = AudioStreamPlayer.new()
	player.name = "Music"
	player.bus = &"Music" if AudioServer.get_bus_index(&"Music") >= 0 else &"Master"
	add_child(player)
	if chart == null:
		_load_from_config()
	rules = base_rules.for_speed(note_speed)
	_lead = rules.lead_in_sec + (INTRO_EXTRA_SEC if intro_key != "" else 0.0)
	if chart:
		chart.limit_kinds(kinds)
		spacing_dropped = chart.enforce_spacing(rules.min_note_gap())
	_build()


## Chuẩn bị lượt chơi trực tiếp (test hoặc màn khác truyền vào). Gọi trước khi thêm vào cây.
func setup(chart_: RhythmChart, stream: AudioStream, record_key_: String, title := "", boss_ := false,
		speed := 0.0) -> void:
	chart = chart_
	note_speed = speed
	record_key = record_key_
	song_title = title
	boss = boss_
	if player == null:
		player = AudioStreamPlayer.new()
		player.name = "Music"
		add_child(player)
	player.stream = stream


func _load_from_config() -> void:
	var gc := UiKit.autoload("GameConfig")
	if gc == null:
		load_error = "no_config"
		return
	var lib := RhythmLibrary.new("", Callable())
	var cached := lib.cache_dir.path_join(RhythmLibrary.CATALOG_FILE)
	if FileAccess.file_exists(cached):
		lib.catalog = RhythmLibrary._parse_catalog(FileAccess.get_file_as_string(cached))
	record_key = str(gc.rhythm_record_key)
	boss = bool(gc.rhythm_boss)
	note_speed = float(gc.rhythm_note_speed)
	tutorial = bool(gc.rhythm_tutorial)
	intro_key = str(gc.rhythm_intro_key)
	kinds = gc.rhythm_kinds.duplicate()
	song_title = str(lib.song(str(gc.rhythm_song_id)).get("title", gc.rhythm_song_id))
	if not lib.is_cached(str(gc.rhythm_song_id), str(gc.rhythm_chart_key)):
		load_error = "not_cached"
		chart = RhythmChart.new()
		return
	chart = lib.load_chart(str(gc.rhythm_song_id), str(gc.rhythm_chart_key))
	player.stream = lib.load_audio(str(gc.rhythm_song_id))
	if player.stream == null:
		load_error = "audio"


func _profile() -> PlayerProfile:
	if profile == null:
		var save := UiKit.autoload("SaveService")
		profile = PlayerProfile.new(save.data if save else SaveSchema.default_data())
	return profile


# ---------- Dựng ----------

func _build() -> void:
	_start_judge(chart if chart else RhythmChart.new(), rules)
	now = -_lead
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = _col("background", Color("#141029"))
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_field = Control.new()
	_field.name = "Field"
	_field.set_anchors_preset(Control.PRESET_FULL_RECT)
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_field.draw.connect(_draw_field)
	add_child(_field)
	if boss:
		_build_boss_visual()
	_hit_layer = Control.new()
	_hit_layer.name = "Hitboxes"
	_hit_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hit_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hit_layer.draw.connect(_draw_hitboxes)
	add_child(_hit_layer)
	_build_character()
	_hud = Control.new()
	_hud.name = "Hud"
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.draw.connect(_draw_hud)
	add_child(_hud)
	_labels["score"] = _label("Score", Vector2(40, 20), 64, Color("#BDF4FF"))
	_labels["score_cap"] = _label("ScoreCaption", Vector2(44, 96), 30, Color("#9C8CFF"))
	_labels["score_cap"].text = tr("RHYTHM_SCORE")
	_labels["combo"] = _label("Combo", Vector2(760, 80), 96, Color("#FFE14D"), 400)
	_labels["combo_cap"] = _label("ComboCaption", Vector2(760, 186), 36, Color("#FF7AD9"), 400)
	_labels["title"] = _label("Title", Vector2(1100, 24), 28, Color(1, 1, 1, 0.85), 640, HORIZONTAL_ALIGNMENT_RIGHT)
	_labels["title"].text = song_title + ("  ·  " + tr("RHYTHM_BOSS") if boss else "")
	_labels["count"] = _label("Countdown", Vector2(760, 420), 120, Color.WHITE, 400)
	_labels["hint_up"] = _label("HintUp", Vector2(40, 990), 26, Color(1, 1, 1, 0.55), 600)
	_labels["hint_up"].text = tr("RHYTHM_HINT_UP")
	_labels["hint_down"] = _label("HintDown", Vector2(1280, 990), 26, Color(1, 1, 1, 0.55), 600, HORIZONTAL_ALIGNMENT_RIGHT)
	_labels["hint_down"].text = tr("RHYTHM_HINT_DOWN")
	var pause_btn := Button.new()
	pause_btn.name = "PauseButton"
	pause_btn.text = "‖"
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.add_theme_font_size_override("font_size", 48)
	pause_btn.position = Vector2(1780, 12)
	pause_btn.size = Vector2(128, 116)
	pause_btn.pressed.connect(set_paused.bind(true))
	add_child(pause_btn)
	if intro_key != "":
		_labels["intro"] = _label("Intro", Vector2(360, 560), 34, Color("#FFE14D"), 1200)
		_labels["intro"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_labels["intro"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_labels["intro"].size = Vector2(1200, 140)
		_labels["intro"].text = tr(intro_key)
	if load_error != "" or not chart.is_valid():
		_show_error()
	elif tutorial:
		_begin_tutorial()


func _start_judge(c: RhythmChart, r: RhythmRules) -> void:
	judge = RhythmJudge.new(r, c)
	judge.judged.connect(_on_judged)
	judge.mash_hit.connect(_on_mash_hit)


# ---------- Hướng dẫn (ải N-1 lần đầu) ----------

func _begin_tutorial() -> void:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(TUTORIAL_PATH)) if FileAccess.file_exists(TUTORIAL_PATH) else null
	if not (d is Dictionary) or not (d.get("steps") is Array) or d["steps"].is_empty():
		return
	_tut = d
	_tut_rules = (load(RULES_PATH) as RhythmRules).for_speed(float(d.get("speed", 0.0)))
	_tut_rules.miss_damage = 0
	_tut_rules.wrong_damage = 0
	_tut_rules.hold_break_damage = 0
	_real_chart = chart
	phase = "tutorial"
	_tut_step = 0
	now = 0.0
	_build_tutorial_ui()
	_tut_load_step()


func _build_tutorial_ui() -> void:
	_tut_panel = Panel.new()
	_tut_panel.name = "TutorialPanel"
	_tut_panel.position = Vector2(440, 14)
	_tut_panel.size = Vector2(1040, 250)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#2A1B4A", 0.9)
	sb.border_color = Color("#FFD84D")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	_tut_panel.add_theme_stylebox_override("panel", sb)
	_tut_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tut_panel)
	var rows := [["title", 6, 38, 28, Color("#FFD84D")], ["text", 44, 96, 27, Color.WHITE],
			["grades", 140, 64, 22, Color(1, 1, 1, 0.7)], ["progress", 206, 36, 26, Color("#7DFFB0")]]
	for r in rows:
		var l := Label.new()
		l.name = "Tut_" + str(r[0])
		l.position = Vector2(24, float(r[1]))
		l.size = Vector2(992, float(r[2]))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", int(r[3]))
		l.add_theme_color_override("font_color", r[4])
		_tut_panel.add_child(l)
		_tut_labels[r[0]] = l
	_tut_labels["grades"].text = tr("RHYTHM_TUT_GRADES")
	var skip := Button.new()
	skip.name = "SkipTutorialButton"
	skip.text = tr("RHYTHM_TUT_SKIP")
	skip.focus_mode = Control.FOCUS_NONE
	skip.position = Vector2(1500, 140)
	skip.size = Vector2(360, 96)
	skip.add_theme_font_size_override("font_size", 30)
	skip.pressed.connect(skip_tutorial)
	add_child(skip)
	_tut_labels["skip"] = skip


func _tut_load_step() -> void:
	var st: Dictionary = _tut["steps"][_tut_step]
	var travel := (get_viewport_rect().size.x - _num("field.judge_x", 380)) / _tut_rules.note_speed
	var notes: Array = []
	for k in int(st.get("count", 3)):
		var lane := str(st.get("lane", "up"))
		if lane == "mix":
			lane = "up" if k % 2 == 0 else "down"
		notes.append({"t": now + travel + 0.4 + k * float(st.get("gap", 1.2)), "lane": lane})
	_clear_enemy_visuals()
	chart = RhythmChart.from_dict({"format": 1, "song_id": "tutorial", "bpm": 100, "notes": notes})
	_auto_done.clear()
	_start_judge(chart, _tut_rules)
	_tut_next_at = -1.0
	_refresh_tutorial_ui()


func _tut_hits() -> int:
	var c: Dictionary = judge.counts
	return int(c[RhythmJudge.PERFECT]) + int(c[RhythmJudge.GREAT]) + int(c[RhythmJudge.GOOD]) + int(c[RhythmJudge.NORMAL])


func _refresh_tutorial_ui() -> void:
	if _tut_panel == null or _tut.is_empty():
		return
	var steps: Array = _tut["steps"]
	var st: Dictionary = steps[mini(_tut_step, steps.size() - 1)]
	_tut_labels["title"].text = tr("RHYTHM_TUT_TITLE") % [mini(_tut_step + 1, steps.size()), steps.size()]
	_tut_labels["text"].text = tr("RHYTHM_TUT_DONE") if _tut_done_at >= 0.0 else tr(str(st.get("text_key", "")))
	var prog := tr("RHYTHM_TUT_PROGRESS") % [_tut_hits(), int(st.get("need", 1))]
	_tut_labels["progress"].text = prog + ("   " + _tut_msg if _tut_msg != "" else "")


func _tick_tutorial(delta: float) -> void:
	now += delta
	if autoplay:
		_autoplay()
	judge.update(now)
	_prepare_enemy_visuals()
	_update_enemy_visuals()
	_update_character()
	if _tut_done_at >= 0.0:
		if now >= _tut_done_at:
			skip_tutorial()
			return
	elif judge.is_finished():
		if _tut_next_at < 0.0:
			_tut_next_at = now + 0.7   # cho hiệu ứng trúng chạy xong
		elif now >= _tut_next_at:
			var st: Dictionary = _tut["steps"][_tut_step]
			if _tut_hits() >= int(st.get("need", 1)):
				_tut_msg = ""
				_tut_step += 1
				if _tut_step >= _tut["steps"].size():
					_tut_done_at = now + float(_tut.get("done_sec", 2.0))
				else:
					_tut_load_step()
			else:
				_tut_msg = tr("RHYTHM_TUT_RETRY")
				_tut_load_step()
	_refresh_tutorial_ui()


## Kết thúc / bỏ qua hướng dẫn: vào bài thật (đếm ngược từ đầu).
func skip_tutorial() -> void:
	if phase != "tutorial":
		return
	phase = "play"
	_clear_enemy_visuals()
	_popups.clear()
	_bursts.clear()
	_auto_done.clear()
	chart = _real_chart
	_start_judge(chart, rules)
	_elapsed = 0.0
	now = -_lead
	for node in [_tut_panel, _tut_labels.get("skip")]:
		if node and is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	_tut_panel = null
	_tut_labels.clear()


func _clear_enemy_visuals() -> void:
	for k in _enemy_visuals.keys():
		_free_enemy_visual(int(k))


func _label(name_: String, pos: Vector2, font_size: int, col: Color, width := 900.0,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.name = name_
	l.position = pos
	l.size = Vector2(width, font_size * 1.3)
	l.horizontal_alignment = align
	if name_ in ["Combo", "ComboCaption", "Countdown"]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.03, 0.2))
	l.add_theme_constant_override("outline_size", maxi(4, font_size / 8))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _build_character() -> void:
	var party := _profile().party_ids()
	var id := party[0] if party.size() > 0 else "char_fire_01"
	var built := AnimationSetBuilder.build_for_character(id)
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Character"
	_sprite.sprite_frames = built.sprite_frames
	_sprite.offset = built.sprite_offset
	_sprite.scale = Vector2.ONE * _num("character.scale", 0.85)
	_sprite_base = Vector2(_num("field.judge_x", 380) + _num("character.offset_x", -200), _num("field.down_y", 760) + 60)
	_sprite.position = _sprite_base
	add_child(_sprite)
	_play_anim("run", "idle")


func _play_anim(name_: String, fallback := "idle") -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var n := StringName(name_)
	if not _sprite.sprite_frames.has_animation(n):
		n = StringName(fallback)
	if _sprite.sprite_frames.has_animation(n) and _sprite.animation != n:
		_sprite.play(n)
	elif _sprite.sprite_frames.has_animation(n) and not _sprite.is_playing():
		_sprite.play(n)


func _num(path: String, def: float) -> float:
	return float(layout.num(path, def)) if layout else def


func _col(name_: String, def: Color) -> Color:
	return layout.color(name_, def) if layout else def


# ---------- Vòng lặp ----------

func _process(delta: float) -> void:
	if manual_clock:
		return
	_tick(delta)


## Test: đẩy đồng hồ thêm `dt` giây (manual_clock).
func advance(dt: float, step := 1.0 / 60.0) -> void:
	var left := dt
	while left > 0.0:
		var d := minf(step, left)
		_tick(d)
		left -= d


func _tick(delta: float) -> void:
	if paused or not result.is_empty() or judge == null or load_error != "":
		return
	if phase == "tutorial":
		_tick_tutorial(delta)
		_refresh_hud()
		_field.queue_redraw()
		_hit_layer.queue_redraw()
		_hud.queue_redraw()
		return
	_elapsed += delta
	var t := _song_time()
	now = maxf(now, t)
	if autoplay:
		_autoplay()
	judge.update(now)
	_prepare_enemy_visuals()
	_update_enemy_visuals()
	_update_character()
	if judge.is_failed:
		_finish()
	elif judge.is_finished() and _end_at < 0.0:
		_end_at = now + 1.0
	if _end_at >= 0.0 and now >= _end_at:
		_finish()
	elif chart and now > chart.last_note_end() + rules.tail_sec and judge.is_finished():
		_finish()
	_refresh_hud()
	_field.queue_redraw()
	_hit_layer.queue_redraw()
	_hud.queue_redraw()


func _song_time() -> float:
	var lead := _lead
	if manual_clock or player.stream == null:
		return _elapsed - lead
	if not _audio_started:
		if _elapsed >= lead:
			player.play()
			_audio_started = true
			return 0.0
		return _elapsed - lead
	if not player.playing:
		return now + 1.0 / 60.0   # nhạc đã hết: đồng hồ chạy tiếp để kết thúc
	return player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()


func _autoplay() -> void:
	if judge.is_finished():
		return
	var i := judge.cursor
	var n: Dictionary = chart.notes[i]
	var step := int(_auto_done.get(i, 0))
	var lane := int(n["lane"])
	if step == 0 and now >= float(n["t"]):
		_auto_done[i] = 1
		for l in [RhythmChart.LANE_UP, RhythmChart.LANE_DOWN]:
			if lane & l:
				press_lane(l)
		if n["kind"] == RhythmChart.KIND_TAP:
			_auto_release(lane)
	elif step == 1 and n["kind"] == RhythmChart.KIND_MASH:
		var gap := float(n["dur"]) / float(maxi(int(n["hits"]), 1)) * 0.8
		var k := int(_auto_done.get(-i - 1, 1))
		if now >= float(n["t"]) + gap * k:
			_auto_done[-i - 1] = k + 1
			_auto_release(lane)
			press_lane(RhythmChart.LANE_UP if lane & RhythmChart.LANE_UP else RhythmChart.LANE_DOWN)
	elif step == 1 and n["kind"] == RhythmChart.KIND_HOLD and now >= float(n["t"]) + float(n["dur"]):
		_auto_done[i] = 2
		_auto_release(lane)


func _auto_release(lane: int) -> void:
	for l in [RhythmChart.LANE_UP, RhythmChart.LANE_DOWN]:
		if lane & l:
			release_lane(l)


# ---------- Input ----------

func _input(event: InputEvent) -> void:
	if not result.is_empty() or judge == null:
		return
	if event.is_echo():
		return
	if event.is_action_pressed(&"pause"):
		set_paused(not paused)
		get_viewport().set_input_as_handled()
		return
	if paused:
		return
	if event.is_action_pressed(&"rhythm_up"):
		press_lane(RhythmChart.LANE_UP)
	elif event.is_action_released(&"rhythm_up"):
		release_lane(RhythmChart.LANE_UP)
	elif event.is_action_pressed(&"rhythm_down"):
		press_lane(RhythmChart.LANE_DOWN)
	elif event.is_action_released(&"rhythm_down"):
		release_lane(RhythmChart.LANE_DOWN)
	elif event is InputEventScreenTouch:
		var te := event as InputEventScreenTouch
		if te.pressed:
			if te.position.y < 140.0:
				return   # thanh trên (nút tạm dừng)
			var lane := RhythmChart.LANE_UP if te.position.x < get_viewport_rect().size.x * 0.5 else RhythmChart.LANE_DOWN
			_touch_lane[te.index] = lane
			press_lane(lane)
		elif _touch_lane.has(te.index):
			release_lane(int(_touch_lane[te.index]))
			_touch_lane.erase(te.index)


## Một phím của làn được ấn (nhiều phím cùng làn: nhả hết mới tính là nhả).
func press_lane(lane: int) -> void:
	_lane_keys[lane] = int(_lane_keys[lane]) + 1
	now = _input_time()
	judge.press(lane, now)
	if lane == RhythmChart.LANE_UP:
		_air_until = now + 0.28
		_play_anim("air_1", "jump_up")
	else:
		_attack_flip = (_attack_flip + 1) % 2
		_play_anim("attack_1" if _attack_flip == 0 else "attack_2", "idle")
	if _sprite:
		_sprite.frame = 0


func release_lane(lane: int) -> void:
	_lane_keys[lane] = maxi(int(_lane_keys[lane]) - 1, 0)
	if int(_lane_keys[lane]) == 0:
		now = _input_time()
		judge.release(lane, now)


## Thời điểm trong bài ngay lúc phím được nhận (đọc lại đồng hồ nhạc thay vì dùng giá trị của frame trước, lệch tới
## ~16 ms ở 60 fps), để Perfect phụ thuộc tay người chơi chứ không phụ thuộc nhịp frame.
func _input_time() -> float:
	if manual_clock or paused or not _audio_started or player == null or not player.playing:
		return now
	return maxf(now, _song_time())


func intercept_back() -> bool:
	if not result.is_empty():
		return false
	set_paused(not paused)
	return true


func set_paused(p: bool) -> void:
	if not result.is_empty() or paused == p:
		return
	paused = p
	if player:
		player.stream_paused = p
	if p:
		_show_pause()
	elif _pause_layer:
		_pause_layer.queue_free()
		_pause_layer = null


# ---------- Phản hồi ----------

func _update_character() -> void:
	if _sprite == null:
		return
	var air := now < _air_until or (_holding_lane() & RhythmChart.LANE_UP != 0)
	var target := _sprite_base + (Vector2(0, _num("field.up_y", 430) - _num("field.down_y", 760)) if air else Vector2.ZERO)
	_sprite.position = _sprite.position.lerp(target, 0.45)
	_sprite.modulate = Color(1, 0.5, 0.5) if now < _hurt_until else Color.WHITE
	if not _sprite.is_playing() or (_sprite.animation in [&"attack_1", &"attack_2", &"air_1", &"jump_up"] and _sprite.frame >= _sprite.sprite_frames.get_frame_count(_sprite.animation) - 1):
		_play_anim("run", "idle")


func _holding_lane() -> int:
	var m := 0
	for l in _lane_keys:
		if int(_lane_keys[l]) > 0:
			m |= int(l)
	return m


func _on_judged(index: int, res: String, unit: String) -> void:
	var lane := int(chart.notes[index]["lane"]) if index < chart.notes.size() else RhythmChart.LANE_DOWN
	if _enemy_visuals.has(index) and bool(_enemy_visuals[index].get("drum", false)):
		var visual: Dictionary = _enemy_visuals[index]
		var drum_sprites: Array = visual["sprites"]
		var actor := drum_sprites[0] as AnimatedSprite2D
		var animation := "burst" if res in HIT_RESULTS else "escape"
		actor.play(animation)
		visual["dying_until"] = now + (0.3 if animation == "burst" else 0.5)
		(visual["crack"] as Sprite2D).hide()
		(visual["count_label"] as Label).hide()
		_enemy_visuals[index] = visual
	elif _enemy_visuals.has(index) and bool(_enemy_visuals[index].get("hold", false)):
		# Rắn Ngân: trúng đầu thì cắn (đứng ở vòng chấm tới hết thân); xong phần cuối hoặc trượt thì biến mất.
		if unit == "head" and res in HIT_RESULTS:
			for actor in _enemy_visuals[index]["sprites"]:
				actor.play("bite")
		else:
			_free_enemy_visual(index)
	elif _enemy_visuals.has(index):
		if res in HIT_RESULTS:
			var visual: Dictionary = _enemy_visuals[index]
			visual["dying_until"] = now + 0.26
			for actor in visual["sprites"]:
				actor.play("die")
			var chain := visual["chain"] as TextureRect
			if chain:
				chain.hide()
			_enemy_visuals[index] = visual
		else:
			_free_enemy_visual(index)
	var col := _col(res, Color.WHITE)
	var key := "RHYTHM_" + res.to_upper()
	_popups.append({"text": tr(key), "color": col, "lane": lane, "born": now})
	if _popups.size() > 6:
		_popups.pop_front()
	if res in HIT_RESULTS and unit != "tail" and boss:
		_boss_play("hurt", true)
	if res in [RhythmJudge.PERFECT, RhythmJudge.GREAT, RhythmJudge.GOOD] and unit != "tail":
		for l in [RhythmChart.LANE_UP, RhythmChart.LANE_DOWN]:
			if lane & l:
				_bursts.append({"pos": Vector2(_num("field.judge_x", 380), _lane_y(l)), "color": col, "born": now})
	if res in [RhythmJudge.MISS, RhythmJudge.WRONG]:
		_hurt_until = now + 0.3
		_play_anim("hurt", "idle")


func _on_mash_hit(index: int, _count: int) -> void:
	if _enemy_visuals.has(index) and bool(_enemy_visuals[index].get("drum", false)):
		var visual: Dictionary = _enemy_visuals[index]
		var drum_sprites: Array = visual["sprites"]
		(drum_sprites[0] as AnimatedSprite2D).play("hit")
		_refresh_drum_cracks(index)
	_bursts.append({"pos": Vector2(_num("field.judge_x", 380) + 60, (_lane_y(1) + _lane_y(2)) * 0.5), "color": Color("#FFE14D"), "born": now})
	if _bursts.size() > 24:
		_bursts.pop_front()


func _refresh_hud() -> void:
	_labels["score"].text = "%d" % judge.score
	var show_combo := judge.combo >= 3 and phase == "play"
	_labels["combo"].text = "%d" % judge.combo if show_combo else ""
	_labels["combo_cap"].text = tr("RHYTHM_COMBO") if show_combo else ""
	if _labels.has("intro"):
		_labels["intro"].visible = phase == "play" and now < 0.0
	if phase == "tutorial":
		_labels["count"].text = ""
	elif now < 0.0:
		_labels["count"].text = "%d" % ceili(-now)
	elif now < 0.6:
		_labels["count"].text = tr("RHYTHM_GO")
	else:
		_labels["count"].text = ""


# ---------- Vẽ ----------

func _lane_y(lane: int) -> float:
	return _num("field.up_y", 430) if lane == RhythmChart.LANE_UP else _num("field.down_y", 760)


func _speed() -> float:
	return rules.note_speed


func _draw_field() -> void:
	var f := _field
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y
	var jx := _num("field.judge_x", 380)
	var up_y := _lane_y(RhythmChart.LANE_UP)
	var dn_y := _lane_y(RhythmChart.LANE_DOWN)
	# Nền: dải trời + mặt đường.
	f.draw_rect(Rect2(0, dn_y + 84, w, h - dn_y - 84), _col("ground", Color("#1F5E63")))
	f.draw_rect(Rect2(0, dn_y + 80, w, 6), _col("ground_edge", Color("#7FF4E0")))
	# Đường làn + vòng chấm.
	for y in [up_y, dn_y]:
		f.draw_line(Vector2(jx, y), Vector2(w, y), Color(1, 1, 1, 0.08), 3.0)
		# Vòng chấm: lòng vòng bán kính R (hitbox vào khít = Perfect), viền ngoài dày ring_rim (chỉ chạm viền = Miss).
		f.draw_circle(Vector2(jx, y), rules.ring_radius, Color(1, 1, 1, 0.06))
		f.draw_arc(Vector2(jx, y), rules.ring_radius * 0.5, 0, TAU, 40, Color(1, 1, 1, 0.18), 2.0)
	if in_fever_visual():
		f.draw_rect(Rect2(0, 0, w, h), Color(1.0, 0.3, 0.8, 0.07))
	var speed := _speed()
	# Nốt (từ xa tới gần để nốt gần vẽ đè).
	for i in range(chart.notes.size() - 1, judge.cursor - 1, -1):
		var n: Dictionary = chart.notes[i]
		var t := float(n["t"])
		var x := jx + (t - now) * speed
		if x > w + 200.0:
			continue
		_draw_note(f, i, n, x, speed)
	# Hiệu ứng trúng.
	for b in _bursts:
		var age := now - float(b["born"])
		if age < 0.0 or age > 0.3:
			continue
		var k := age / 0.3
		var c: Color = b["color"]
		f.draw_arc(b["pos"], 50 + 70 * k, 0, TAU, 32, Color(c, 1.0 - k), 8.0 * (1.0 - k) + 1.0)
		for s in 6:
			var a := TAU * s / 6.0 + k
			f.draw_circle(b["pos"] + Vector2(cos(a), sin(a)) * (40 + 110 * k), 9 * (1.0 - k), Color(c, 1.0 - k))


func in_fever_visual() -> bool:
	return judge != null and judge.in_fever()


func _note_color(lane: int) -> Color:
	if lane == RhythmChart.LANE_BOTH:
		return _col("lane_both", Color("#FFD84D"))
	return _col("lane_up", Color("#5FD7FF")) if lane == RhythmChart.LANE_UP else _col("lane_down", Color("#FF5FA8"))


func _draw_note(f: Control, i: int, n: Dictionary, x: float, speed: float) -> void:
	var lane := int(n["lane"])
	var col := _note_color(lane)
	var st: Dictionary = judge.states[i]
	var active := int(st["state"]) == 1
	var jx := _num("field.judge_x", 380)
	match n["kind"]:
		RhythmChart.KIND_TAP:
			if not _enemy_visuals.has(i):
				for l in [RhythmChart.LANE_UP, RhythmChart.LANE_DOWN]:
					if lane & l:
						_draw_enemy(f, Vector2(x, _lane_y(l)), rules.ring_radius * 1.1, col, l == RhythmChart.LANE_UP)
		RhythmChart.KIND_HOLD:
			var x0 := jx if active else x
			var x1 := jx + (float(n["t"]) + float(n["dur"]) - now) * speed
			for l in [RhythmChart.LANE_UP, RhythmChart.LANE_DOWN]:
				if lane & l and not _enemy_visuals.has(i):
					var y := _lane_y(l)
					f.draw_rect(Rect2(x0, y - 22, maxf(x1 - x0, 0.0), 44), Color(col, 0.45 if not active else 0.75))
					f.draw_rect(Rect2(x0, y - 22, maxf(x1 - x0, 0.0), 44), Color(1, 1, 1, 0.6), false, 3.0)
					f.draw_circle(Vector2(x1, y), 26, col)
					if not _enemy_visuals.has(i) and not active:
						_draw_enemy(f, Vector2(x0, y), rules.ring_radius * 1.1, col, l == RhythmChart.LANE_UP)
					elif active and not _enemy_visuals.has(i):
						f.draw_circle(Vector2(x0, y), 34, Color(1, 1, 1, 0.9))
		RhythmChart.KIND_MASH:
			if not _enemy_visuals.has(i):
				var cx := maxf(x, jx + 80.0) if active else x
				var y := (_lane_y(1) + _lane_y(2)) * 0.5 if lane == RhythmChart.LANE_BOTH else _lane_y(lane)
				var shake := Vector2(sin(now * 60.0) * 6.0, 0) if active else Vector2.ZERO
				f.draw_circle(Vector2(cx, y) + shake, 110, Color(col, 0.9))
				f.draw_circle(Vector2(cx, y) + shake, 92, Color("#2A1B4A"))
				f.draw_arc(Vector2(cx, y) + shake, 110, 0, TAU, 48, Color.WHITE, 5.0)
				var left := maxi(int(n["hits"]) - int(st["count"]), 0)
				var font := get_theme_default_font()
				f.draw_string(font, Vector2(cx - 90, y + 22) + shake, "%d" % left if active else "!!", HORIZONTAL_ALIGNMENT_CENTER, 180, 64, col)


## Kẻ địch (nốt): thân tròn + mắt; làn trên có cánh (bay), làn dưới có chân.
func _draw_enemy(f: Control, p: Vector2, r: float, col: Color, flying: bool) -> void:
	f.draw_circle(p + Vector2(4, 6), r, Color(0, 0, 0, 0.35))
	f.draw_circle(p, r, Color("#2A1B4A"))
	f.draw_arc(p, r, 0, TAU, 40, col, 6.0)
	f.draw_circle(p + Vector2(-r * 0.3, -r * 0.1), r * 0.28, col)
	f.draw_circle(p + Vector2(-r * 0.36, -r * 0.1), r * 0.12, Color.WHITE)
	if flying:
		f.draw_colored_polygon(PackedVector2Array([p + Vector2(r * 0.4, -r * 0.6), p + Vector2(r * 1.3, -r * 1.1), p + Vector2(r * 0.9, -r * 0.2)]), Color(col, 0.8))
	else:
		f.draw_rect(Rect2(p + Vector2(-r * 0.5, r * 0.8), Vector2(r * 0.3, r * 0.4)), col)
		f.draw_rect(Rect2(p + Vector2(r * 0.2, r * 0.8), Vector2(r * 0.3, r * 0.4)), col)


func _ensure_enemy_visual(note_index: int, lane: int) -> bool:
	if _enemy_visuals.has(note_index):
		return true
	var kind := str(chart.notes[note_index]["kind"])
	if kind == RhythmChart.KIND_HOLD:
		return _ensure_serpent(note_index, lane)
	if kind == RhythmChart.KIND_MASH:
		return _ensure_drum(note_index, lane)
	var sprites: Array[AnimatedSprite2D] = []
	var ids: Array[String] = []
	var anims: Array[String] = []
	if lane == RhythmChart.LANE_BOTH:
		ids = ["rh_twin", "rh_twin"]
		anims = ["fly", "run"]
	elif lane == RhythmChart.LANE_UP:
		ids = ["rh_bat"]
		anims = ["fly"]
	else:
		ids = ["rh_slime"]
		anims = ["run"]
	for k in ids.size():
		var sprite_frames := _enemy_sprite_frames(ids[k], anims[k])
		if sprite_frames == null:
			for existing in sprites:
				existing.queue_free()
			return false
		var actor := AnimatedSprite2D.new()
		actor.name = "RhythmEnemy_%d_%d" % [note_index, k]
		actor.sprite_frames = sprite_frames
		actor.centered = true
		actor.scale = Vector2.ONE * _enemy_scale()
		actor.offset = _body_offset(ids[k], anims[k])
		_field.add_child(actor)
		actor.play("move")
		sprites.append(actor)
	if boss:
		_boss_play("throw")
	var chain: TextureRect
	if lane == RhythmChart.LANE_BOTH:
		var chain_texture := load("res://assets/rhythm/rh_twin_chain.png") as Texture2D
		if chain_texture:
			chain = TextureRect.new()
			chain.name = "RhythmTwinChain_%d" % note_index
			chain.texture = chain_texture
			chain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			chain.stretch_mode = TextureRect.STRETCH_SCALE
			chain.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_field.add_child(chain)
			_field.move_child(chain, 0)
	_enemy_visuals[note_index] = {"sprites": sprites, "chain": chain, "dying_until": -1.0, "lane": lane}
	_position_enemy_visual(note_index, float(chart.notes[note_index]["t"]))
	return true


func _enemy_sprite_frames(enemy_id: String, move_anim: String) -> SpriteFrames:
	var cache_key := enemy_id + ":" + move_anim
	if _enemy_frames_cache.has(cache_key):
		return _enemy_frames_cache[cache_key] as SpriteFrames
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("move")
	frames.set_animation_speed("move", 12.0)
	frames.set_animation_loop("move", true)
	var move_dir := "res://assets/rhythm/%s/%s" % [enemy_id, move_anim]
	var move_count := 6
	if enemy_id == "rh_twin":
		move_dir = "res://assets/rhythm/rh_twin/%s" % move_anim
	for frame_index in move_count:
		var path := "%s/%s_%s_%03d.png" % [move_dir, enemy_id, move_anim, frame_index]
		var texture := load(path) as Texture2D
		if texture == null:
			return null
		frames.add_frame("move", texture)
	frames.add_animation("die")
	frames.set_animation_speed("die", 20.0)
	frames.set_animation_loop("die", false)
	var die_dirs: Array[String] = []
	if enemy_id == "rh_twin":
		die_dirs = ["res://assets/rhythm/rh_twin/die/bat", "res://assets/rhythm/rh_twin/die/slime"]
	else:
		die_dirs = ["res://assets/rhythm/%s/die" % enemy_id]
	var die_dir := die_dirs[1] if enemy_id == "rh_twin" and move_anim == "run" else die_dirs[0]
	var die_id := enemy_id if enemy_id != "rh_twin" else "rh_twin"
	for frame_index in 5:
		var texture := load("%s/%s_die_%03d.png" % [die_dir, die_id, frame_index]) as Texture2D
		if texture == null:
			return null
		frames.add_frame("die", texture)
	_enemy_frames_cache[cache_key] = frames
	return frames


func _position_enemy_visual(note_index: int, note_time: float) -> void:
	if not _enemy_visuals.has(note_index):
		return
	var visual: Dictionary = _enemy_visuals[note_index]
	if bool(visual.get("drum", false)):
		_position_drum(note_index, visual, note_time)
		return
	if bool(visual.get("hold", false)):
		_position_serpent(note_index, visual, note_time)
		return
	var lane := int(visual["lane"])
	var x := _num("field.judge_x", 380) + (note_time - now) * _speed()
	var sprites: Array = visual["sprites"]
	if lane == RhythmChart.LANE_BOTH:
		if sprites.size() >= 2:
			sprites[0].position = Vector2(x, _lane_y(RhythmChart.LANE_UP))
			sprites[1].position = Vector2(x, _lane_y(RhythmChart.LANE_DOWN))
		var chain := visual["chain"] as TextureRect
		if chain:
			var y_top := _lane_y(RhythmChart.LANE_UP) + rules.ring_radius
			var y_bottom := _lane_y(RhythmChart.LANE_DOWN) - rules.ring_radius
			chain.position = Vector2(x - 20.0, y_top)
			chain.size = Vector2(40.0, maxf(y_bottom - y_top, 1.0))
	else:
		sprites[0].position = Vector2(x, _lane_y(lane))


func _prepare_enemy_visuals() -> void:
	var width := get_viewport_rect().size.x
	var judge_x := _num("field.judge_x", 380)
	var speed := _speed()
	for note_index in range(judge.cursor, chart.notes.size()):
		var note: Dictionary = chart.notes[note_index]
		if note["kind"] not in [RhythmChart.KIND_TAP, RhythmChart.KIND_HOLD, RhythmChart.KIND_MASH]:
			continue
		var note_x := judge_x + (float(note["t"]) - now) * speed
		if note_x > width + 200.0:
			continue
		if note_x < -200.0 and int(judge.states[note_index]["state"]) != 1:
			continue
		_ensure_enemy_visual(note_index, int(note["lane"]))


func _update_enemy_visuals() -> void:
	for key in _enemy_visuals.keys():
		var note_index := int(key)
		var visual: Dictionary = _enemy_visuals[key]
		if float(visual["dying_until"]) >= 0.0:
			if now >= float(visual["dying_until"]):
				_free_enemy_visual(note_index)
			continue
		if note_index >= 0 and note_index < chart.notes.size():
			var note: Dictionary = chart.notes[note_index]
			var note_time := float(note["t"])
			if note["kind"] in [RhythmChart.KIND_HOLD, RhythmChart.KIND_MASH] and int(judge.states[note_index]["state"]) == 1:
				note_time = now
			_position_enemy_visual(note_index, note_time)


func _enemy_scale() -> float:
	return rules.ring_radius * 2.0 * _num("enemy.ring_ratio", 2.2) / ENEMY_FRAME


## Dời ảnh để tâm thân quái (data/ui/rhythm_layout.json enemy.body, px trong khung 256) nằm đúng tâm hitbox.
func _body_offset(enemy_id: String, anim: String) -> Vector2:
	var key := enemy_id + "_" + anim if enemy_id == "rh_twin" else enemy_id
	var b: Variant = layout.get_value("enemy.body." + key) if layout else null
	if b is Array and b.size() == 2:
		return Vector2(ENEMY_FRAME * 0.5 - float(b[0]), ENEMY_FRAME * 0.5 - float(b[1]))
	return Vector2.ZERO


## Hitbox vàng giữa thân quái: nhấp nháy to / nhỏ theo nhịp khi còn xa; từ lúc chạm vòng chấm thì đúng bằng vòng
## (vào giữa vòng là khít). Độ chồng lúc ấn quyết định Perfect / Great / Good / Normal / Miss (RhythmRules.grade).
func _draw_hitboxes() -> void:
	if judge == null or chart == null:
		return
	var h := _hit_layer
	var w := get_viewport_rect().size.x
	var jx := _num("field.judge_x", 380)
	var r := rules.ring_radius
	var beat := chart.bpm / 60.0
	var yellow := _col("hitbox", Color("#FFD84D"))
	# Viền vòng chấm vẽ ở lớp này để không bị thân quái che.
	for y in [_lane_y(RhythmChart.LANE_UP), _lane_y(RhythmChart.LANE_DOWN)]:
		h.draw_arc(Vector2(jx, y), r + rules.ring_rim * 0.5, 0, TAU, 64, Color(1, 1, 1, 0.75), rules.ring_rim)
	for i in range(judge.cursor, chart.notes.size()):
		var n: Dictionary = chart.notes[i]
		if n["kind"] == RhythmChart.KIND_MASH:
			continue
		if int(judge.states[i]["state"]) != 0:
			continue
		var x := jx + (float(n["t"]) - now) * rules.note_speed
		if x > w + 200.0:
			break
		var d := absf(x - jx)
		var k := clampf((d - 2.0 * r) / (2.0 * r), 0.0, 1.0)
		var pulse := 1.0 + 0.25 * k * sin(now * TAU * beat * 2.0)
		var blink := 1.0 - 0.5 * k * absf(sin(now * TAU * beat))
		for l in [RhythmChart.LANE_UP, RhythmChart.LANE_DOWN]:
			if int(n["lane"]) & l:
				var c := Vector2(x, _lane_y(l))
				h.draw_circle(c, r * pulse, Color(yellow, 0.3 * blink))
				h.draw_arc(c, r * pulse, 0, TAU, 64, Color(yellow, blink), 6.0)
				h.draw_circle(c, 6.0, Color(yellow, blink))


func _free_enemy_visual(note_index: int) -> void:
	if not _enemy_visuals.has(note_index):
		return
	var visual: Dictionary = _enemy_visuals[note_index]
	for actor in visual["sprites"]:
		if is_instance_valid(actor):
			actor.queue_free()
	var chain := visual["chain"] as TextureRect
	if chain and is_instance_valid(chain):
		chain.queue_free()
	for extra in visual.get("bodies", []) + visual.get("tails", []):
		if is_instance_valid(extra):
			extra.queue_free()
	for key in ["crack", "count_label"]:
		var extra_node := visual.get(key) as Node
		if extra_node and is_instance_valid(extra_node):
			extra_node.queue_free()
	_enemy_visuals.erase(note_index)


## Rắn Ngân (nốt giữ): đầu (idle / bite), thân khuông nhạc lặp ngang dài theo thời gian giữ, đuôi dấu lặng.
## Ảnh màu trung tính, tô theo màu làn. Mỗi làn của nốt (cả hai = 2 con) một bộ.
func _ensure_serpent(note_index: int, lane: int) -> bool:
	var frames := _serpent_frames()
	var body_tex := load("res://assets/rhythm/rh_serpent_body.png") as Texture2D
	var tail_tex := load("res://assets/rhythm/rh_serpent_tail.png") as Texture2D
	if frames == null or body_tex == null or tail_tex == null:
		return false
	var heads: Array[AnimatedSprite2D] = []
	var bodies: Array = []
	var tails: Array = []
	for l in [RhythmChart.LANE_UP, RhythmChart.LANE_DOWN]:
		if not (lane & l):
			continue
		var tint := Color.WHITE.lerp(_note_color(l), 0.55)
		var body := TextureRect.new()
		body.name = "RhythmSerpentBody_%d_%d" % [note_index, l]
		body.texture = body_tex
		body.stretch_mode = TextureRect.STRETCH_TILE
		body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.modulate = tint
		_field.add_child(body)
		_field.move_child(body, 0)
		bodies.append(body)
		var tail := TextureRect.new()
		tail.name = "RhythmSerpentTail_%d_%d" % [note_index, l]
		tail.texture = tail_tex
		tail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tail.modulate = tint
		_field.add_child(tail)
		tails.append(tail)
		var head := AnimatedSprite2D.new()
		head.name = "RhythmSerpent_%d_%d" % [note_index, l]
		head.sprite_frames = frames
		head.scale = Vector2.ONE * _enemy_scale()
		head.offset = _body_offset("rh_serpent", "")
		head.modulate = tint
		_field.add_child(head)
		head.play("move")
		heads.append(head)
	var chain: TextureRect
	if lane == RhythmChart.LANE_BOTH:
		var chain_texture := load("res://assets/rhythm/rh_twin_chain.png") as Texture2D
		if chain_texture:
			chain = TextureRect.new()
			chain.name = "RhythmSerpentChain_%d" % note_index
			chain.texture = chain_texture
			chain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			chain.stretch_mode = TextureRect.STRETCH_SCALE
			chain.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_field.add_child(chain)
			_field.move_child(chain, 0)
	if boss:
		_boss_play("throw")
	_enemy_visuals[note_index] = {"sprites": heads, "chain": chain, "dying_until": -1.0, "lane": lane, "hold": true,
			"bodies": bodies, "tails": tails}
	_position_enemy_visual(note_index, float(chart.notes[note_index]["t"]))
	return true


func _serpent_frames() -> SpriteFrames:
	if _enemy_frames_cache.has("rh_serpent"):
		return _enemy_frames_cache["rh_serpent"] as SpriteFrames
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for spec in [["move", "idle", 8.0], ["bite", "bite", 12.0]]:
		frames.add_animation(spec[0])
		frames.set_animation_speed(spec[0], spec[2])
		frames.set_animation_loop(spec[0], true)
		for i in 4:
			var tex := load("res://assets/rhythm/rh_serpent/%s/rh_serpent_%s_%03d.png" % [spec[1], spec[1], i]) as Texture2D
			if tex == null:
				return null
			frames.add_frame(spec[0], tex)
	_enemy_frames_cache["rh_serpent"] = frames
	return frames


func _position_serpent(note_index: int, visual: Dictionary, head_time: float) -> void:
	var n: Dictionary = chart.notes[note_index]
	var jx := _num("field.judge_x", 380)
	var head_x := jx + (head_time - now) * _speed()
	var tail_x := jx + (float(n["t"]) + float(n["dur"]) - now) * _speed()
	var bh := rules.ring_radius * 2.0 * 0.7
	var sb := bh / 96.0
	var tw := rules.ring_radius * 1.6
	var k := 0
	for l in [RhythmChart.LANE_UP, RhythmChart.LANE_DOWN]:
		if not (int(visual["lane"]) & l):
			continue
		var y := _lane_y(l)
		var heads: Array = visual["sprites"]
		heads[k].position = Vector2(head_x, y)
		var body: TextureRect = visual["bodies"][k]
		body.scale = Vector2(sb, sb)
		body.position = Vector2(head_x, y - bh * 0.5)
		body.size = Vector2(maxf(tail_x - head_x, 0.0) / sb, 96.0)
		var tail: TextureRect = visual["tails"][k]
		tail.position = Vector2(tail_x - tw * 0.3, y - tw * 0.5)
		tail.size = Vector2(tw, tw)
		k += 1
	var chain := visual["chain"] as TextureRect
	if chain:
		var y_top := _lane_y(RhythmChart.LANE_UP) + rules.ring_radius
		var y_bottom := _lane_y(RhythmChart.LANE_DOWN) - rules.ring_radius
		chain.position = Vector2(head_x - 20.0, y_top)
		chain.size = Vector2(40.0, maxf(y_bottom - y_top, 1.0))


func _build_boss_visual() -> void:
	var frames := _boss_frames()
	if frames == null:
		return
	_boss_sprite = AnimatedSprite2D.new()
	_boss_sprite.name = "RhythmEclipseBoss"
	_boss_sprite.sprite_frames = frames
	_boss_sprite.centered = true
	_boss_sprite.scale = Vector2.ONE * (480.0 / 768.0)
	_boss_sprite.position = Vector2(get_viewport_rect().size.x - 260.0, (_lane_y(RhythmChart.LANE_UP) + _lane_y(RhythmChart.LANE_DOWN)) * 0.5)
	_boss_sprite.animation_finished.connect(_on_boss_animation_finished)
	_field.add_child(_boss_sprite)
	_field.move_child(_boss_sprite, 0)
	_boss_sprite.play("idle")


func _boss_frames() -> SpriteFrames:
	if _enemy_frames_cache.has("rh_boss_eclipse"):
		return _enemy_frames_cache["rh_boss_eclipse"] as SpriteFrames
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var specs := [["idle", 8, 10.0, true], ["throw", 6, 12.0, false], ["hurt", 3, 12.0, false], ["defeat", 10, 20.0, false]]
	for spec in specs:
		var anim: String = spec[0]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, float(spec[2]))
		frames.set_animation_loop(anim, bool(spec[3]))
		for i in int(spec[1]):
			var texture := load("res://assets/rhythm/rh_boss_eclipse/%s/rh_boss_eclipse_%s_%03d.png" % [anim, anim, i]) as Texture2D
			if texture == null:
				return null
			frames.add_frame(anim, texture)
	_enemy_frames_cache["rh_boss_eclipse"] = frames
	return frames


func _boss_play(anim: String, force := false) -> void:
	if _boss_sprite == null or not is_instance_valid(_boss_sprite) or _boss_sprite.animation == "defeat":
		return
	if not force and _boss_sprite.animation in ["throw", "hurt"] and _boss_sprite.is_playing():
		return
	_boss_sprite.play(anim)


func _on_boss_animation_finished() -> void:
	if is_instance_valid(_boss_sprite) and _boss_sprite.animation != "defeat":
		_boss_sprite.play("idle")


func _drum_frames() -> SpriteFrames:
	if _enemy_frames_cache.has("rh_drum"):
		return _enemy_frames_cache["rh_drum"] as SpriteFrames
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var specs := [["idle", 4, 8.0, true], ["hit", 3, 24.0, false], ["burst", 6, 20.0, false], ["escape", 6, 12.0, false]]
	for spec in specs:
		var anim: String = spec[0]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, float(spec[2]))
		frames.set_animation_loop(anim, bool(spec[3]))
		for i in int(spec[1]):
			var texture := load("res://assets/rhythm/rh_drum/%s/rh_drum_%s_%03d.png" % [anim, anim, i]) as Texture2D
			if texture == null:
				return null
			frames.add_frame(anim, texture)
	_enemy_frames_cache["rh_drum"] = frames
	return frames


func _ensure_drum(note_index: int, lane: int) -> bool:
	var frames := _drum_frames()
	var crack_frames: Array[Texture2D] = []
	for i in 3:
		var crack_texture := load("res://assets/rhythm/rh_drum/crack/rh_drum_crack_%03d.png" % i) as Texture2D
		if crack_texture == null:
			return false
		crack_frames.append(crack_texture)
	if frames == null:
		return false
	var actor := AnimatedSprite2D.new()
	actor.name = "RhythmDrum_%d" % note_index
	actor.sprite_frames = frames
	actor.centered = true
	actor.scale = Vector2.ONE * 0.51
	actor.z_index = 1
	actor.animation_finished.connect(_on_drum_animation_finished.bind(note_index))
	_field.add_child(actor)
	actor.play("idle")
	var crack := Sprite2D.new()
	crack.name = "RhythmDrumCrack_%d" % note_index
	crack.centered = true
	crack.scale = actor.scale
	crack.texture = crack_frames[0]
	crack.z_index = 2
	crack.hide()
	_field.add_child(crack)
	var counter := Label.new()
	counter.name = "RhythmDrumCounter_%d" % note_index
	counter.size = Vector2(100, 54)
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	counter.add_theme_font_size_override("font_size", 42)
	counter.add_theme_color_override("font_color", Color("#2A1B4A"))
	counter.add_theme_color_override("font_outline_color", Color.WHITE)
	counter.add_theme_constant_override("outline_size", 5)
	counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter.z_index = 3
	_field.add_child(counter)
	_enemy_visuals[note_index] = {"sprites": [actor], "chain": null, "dying_until": -1.0, "lane": lane,
			"drum": true, "crack": crack, "crack_frames": crack_frames, "count_label": counter}
	_position_enemy_visual(note_index, float(chart.notes[note_index]["t"]))
	_refresh_drum_cracks(note_index)
	if boss:
		_boss_play("throw")
	return true


func _refresh_drum_cracks(note_index: int) -> void:
	if not _enemy_visuals.has(note_index):
		return
	var visual: Dictionary = _enemy_visuals[note_index]
	var note: Dictionary = chart.notes[note_index]
	var total_hits := maxi(int(note.get("hits", 1)), 1)
	var count := int(judge.states[note_index]["count"])
	var left := maxi(total_hits - count, 0)
	var label := visual["count_label"] as Label
	label.text = str(left)
	label.visible = true
	var crack := visual["crack"] as Sprite2D
	if count > 0:
		var stage := clampi(ceili(float(count) * 3.0 / float(total_hits)) - 1, 0, 2)
		var crack_frames: Array = visual["crack_frames"]
		crack.texture = crack_frames[stage]
		crack.show()


func _position_drum(note_index: int, visual: Dictionary, note_time: float) -> void:
	var note: Dictionary = chart.notes[note_index]
	var jx := _num("field.judge_x", 380)
	var x := jx + maxf(note_time - now, 0.0) * _speed()
	var lane := int(visual["lane"])
	var y := (_lane_y(RhythmChart.LANE_UP) + _lane_y(RhythmChart.LANE_DOWN)) * 0.5 if lane == RhythmChart.LANE_BOTH else _lane_y(lane)
	var pos := Vector2(x, y - 99.0)
	var actor: AnimatedSprite2D = visual["sprites"][0]
	actor.position = pos
	(visual["crack"] as Sprite2D).position = pos
	(visual["count_label"] as Label).position = pos + Vector2(-50, -27)


func _on_drum_animation_finished(note_index: int) -> void:
	if not _enemy_visuals.has(note_index):
		return
	var visual: Dictionary = _enemy_visuals[note_index]
	if float(visual["dying_until"]) >= 0.0:
		return
	var actor: AnimatedSprite2D = visual["sprites"][0]
	if actor.animation == "hit":
		actor.play("idle")


func _draw_hud() -> void:
	var h := _hud
	var w := get_viewport_rect().size.x
	var hh := get_viewport_rect().size.y
	# Tiến độ bài (thanh mảnh trên cùng).
	var dur := maxf(chart.duration_sec, 0.1) if chart else 1.0
	h.draw_rect(Rect2(0, 0, w, 8), Color(1, 1, 1, 0.12))
	h.draw_rect(Rect2(0, 0, w * clampf(now / dur, 0.0, 1.0), 8), Color(1, 1, 1, 0.85))
	# HP + Fever (giữa đáy).
	var bw := 820.0
	var x := (w - bw) * 0.5
	var y := hh - 120.0
	h.draw_rect(Rect2(x - 12, y - 46, bw + 24, 120), Color("#3B1F6B", 0.92))
	var fever_k := 1.0 if judge.in_fever() else judge.fever / rules.fever_max
	h.draw_rect(Rect2(x + 120, y - 34, bw - 240, 22), Color(0, 0, 0, 0.5))
	h.draw_rect(Rect2(x + 120, y - 34, (bw - 240) * fever_k, 22), Color("#38E8FF") if not judge.in_fever() else Color("#FF7AD9"))
	h.draw_rect(Rect2(x, y, bw, 52), Color(0, 0, 0, 0.5))
	h.draw_rect(Rect2(x, y, bw * float(judge.hp) / float(rules.max_hp), 52), Color("#FF2E88"))
	var font := get_theme_default_font()
	h.draw_string(font, Vector2(x, y + 40), "%d/%d" % [judge.hp, rules.max_hp], HORIZONTAL_ALIGNMENT_CENTER, bw, 34, Color.WHITE)
	h.draw_string(font, Vector2(x + bw - 110, y - 14), tr("RHYTHM_FEVER"), HORIZONTAL_ALIGNMENT_LEFT, 120, 28, Color("#38E8FF"))
	# Chữ chấm (vẽ trên nhân vật).
	var jx := _num("field.judge_x", 380)
	var up_y := _lane_y(RhythmChart.LANE_UP)
	var dn_y := _lane_y(RhythmChart.LANE_DOWN)
	for p in _popups:
		var age := now - float(p["born"])
		if age < 0.0 or age > 0.6:
			continue
		var lane := int(p["lane"])
		var py := ((up_y + dn_y) * 0.5 if lane == RhythmChart.LANE_BOTH else _lane_y(lane)) - 90 - age * 60
		var c: Color = p["color"]
		h.draw_string_outline(font, Vector2(jx - 160, py), str(p["text"]), HORIZONTAL_ALIGNMENT_CENTER, 320, 54, 10,
				Color(0.15, 0.02, 0.2, 1.0 - age / 0.6))
		h.draw_string(font, Vector2(jx - 160, py), str(p["text"]), HORIZONTAL_ALIGNMENT_CENTER, 320, 54,
				Color(c, 1.0 - age / 0.6))


# ---------- Kết thúc ----------

func _finish() -> void:
	if not result.is_empty():
		return
	if player and player.playing:
		player.stop()
	var cleared := not judge.is_failed
	if boss and cleared:
		_boss_play("defeat", true)
	result = {
		"cleared": cleared, "score": judge.score, "rank": judge.rank() if cleared else "D",
		"max_combo": judge.max_combo, "accuracy": judge.accuracy(), "counts": judge.counts.duplicate(),
		"record_key": record_key,
	}
	if record_key != "":
		var prog := RhythmProgress.new(_profile())
		result["progress"] = prog.finish(record_key, result)
		var save := UiKit.autoload("SaveService")
		if save_enabled and save and is_same(save.data, _profile().data):
			save.save_game()
	_show_result()
	finished.emit(result)


func _overlay(name_: String) -> Control:
	var layer := Control.new()
	layer.name = name_
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.02, 0.12, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	add_child(layer)
	return layer


func _overlay_button(parent: Control, name_: String, text: String, pos: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.name = name_
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.position = pos
	b.size = Vector2(360, 128)
	b.add_theme_font_size_override("font_size", 38)
	var bg := Color("#FF4FA3") if name_ in ["ResumeButton", "RetryButton"] else Color("#3B2A6B")
	for st in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg.lightened(0.1) if st == "hover" else (bg.darkened(0.15) if st == "pressed" else bg)
		sb.set_corner_radius_all(64)
		sb.border_color = Color(1, 1, 1, 0.8)
		sb.set_border_width_all(3)
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _overlay_label(parent: Control, text: String, pos: Vector2, size_: Vector2, font_size: int, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size_
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.02, 0.2))
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l


func _show_pause() -> void:
	_pause_layer = _overlay("PauseLayer")
	_overlay_label(_pause_layer, tr("RHYTHM_PAUSED"), Vector2(560, 260), Vector2(800, 100), 72)
	_overlay_button(_pause_layer, "ResumeButton", tr("RHYTHM_RESUME"), Vector2(780, 420), set_paused.bind(false))
	_overlay_button(_pause_layer, "RetryButton", tr("RESULT_RETRY"), Vector2(780, 570), retry)
	_overlay_button(_pause_layer, "QuitButton", tr("RHYTHM_QUIT"), Vector2(780, 720), quit)


func _show_error() -> void:
	var layer := _overlay("ErrorLayer")
	_overlay_label(layer, tr("RHYTHM_LOAD_ERROR"), Vector2(360, 380), Vector2(1200, 200), 44)
	_overlay_button(layer, "QuitButton", tr("RHYTHM_QUIT"), Vector2(780, 640), quit)


func _show_result() -> void:
	_result_layer = _overlay("ResultLayer")
	var cleared := bool(result["cleared"])
	_overlay_label(_result_layer, tr("RHYTHM_CLEAR") if cleared else tr("RHYTHM_FAILED"), Vector2(460, 70), Vector2(1000, 110), 88,
			Color("#FFE14D") if cleared else Color("#FF7A7A"))
	if cleared:
		_overlay_label(_result_layer, str(result["rank"]), Vector2(220, 260), Vector2(360, 300), 260, Color("#FF6FD8")).name = "Rank"
	var c: Dictionary = result["counts"]
	var lines := PackedStringArray([
		tr("RHYTHM_RESULT_SCORE") % int(result["score"]),
		tr("RHYTHM_RESULT_COMBO") % int(result["max_combo"]),
		tr("RHYTHM_RESULT_ACCURACY") % (float(result["accuracy"]) * 100.0),
		tr("RHYTHM_RESULT_COUNTS") % [int(c[RhythmJudge.PERFECT]), int(c[RhythmJudge.GREAT]), int(c[RhythmJudge.GOOD]),
				int(c[RhythmJudge.NORMAL]), int(c[RhythmJudge.MISS]), int(c[RhythmJudge.WRONG])],
	])
	var prog: Dictionary = result.get("progress", {})
	if bool(prog.get("new_best", false)):
		lines.append(tr("RHYTHM_NEW_BEST"))
	var rew := _reward_text(prog.get("rewards", {}))
	if rew != "":
		lines.append(tr("RESULT_REWARDS") + ": " + rew)
	var fc := _reward_text(prog.get("first_clear_rewards", {}))
	if fc != "":
		lines.append(tr("RESULT_FIRST_CLEAR") + ": " + fc)
	if not cleared:
		lines.append(tr("RHYTHM_FAILED_HINT"))
	var body := _overlay_label(_result_layer, "\n".join(lines), Vector2(620, 240), Vector2(1100, 560), 36)
	body.name = "ResultBody"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_overlay_button(_result_layer, "RetryButton", tr("RESULT_RETRY"), Vector2(560, 860), retry)
	_overlay_button(_result_layer, "QuitButton", tr("RHYTHM_QUIT"), Vector2(1000, 860), quit)


## Tóm tắt phần thưởng đã nhận (dạng PlayerProfile.grant).
func _reward_text(got: Dictionary) -> String:
	var parts := PackedStringArray()
	if int(got.get("gold", 0)) > 0:
		parts.append("%s ×%d" % [tr("CURRENCY_GOLD"), int(got["gold"])])
	if int(got.get("gems", 0)) > 0:
		parts.append("%s ×%d" % [tr("CURRENCY_GEMS"), int(got["gems"])])
	var mats: Dictionary = got.get("materials", {})
	var items := PlayerProfile.item_defs()
	for id in mats:
		var d: Resource = items.get_def(str(id)) if items else null
		var nm := tr(str(d.get("name_key"))) if d else str(id)
		parts.append("%s ×%d" % [nm, int(mats[id])])
	return ", ".join(parts)


func retry() -> void:
	var router := UiKit.autoload("SceneRouter")
	var gc := UiKit.autoload("GameConfig")
	if router and gc:
		router.swap(gc.SCENE_RHYTHM_STAGE)


func quit() -> void:
	if player:
		player.stop()
	var router := UiKit.autoload("SceneRouter")
	if router and router.can_go_back():
		router.go_back()
	elif router:
		var gc := UiKit.autoload("GameConfig")
		if gc:
			router.replace(gc.SCENE_HUB)
