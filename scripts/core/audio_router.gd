extends Node
## Autoload `AudioRouter`: bus âm thanh (Master / Music / SFX), âm lượng, phát nhạc và hiệu ứng theo ID.
## File âm thanh do owner giao (OWNER_ASSET_CHECKLIST mục D): `assets/audio/music/{id}.ogg`, `assets/audio/sfx/{id}.wav|ogg`.
## Thiếu file thì bỏ qua trong im lặng (ghi nhận một lần vào `missing`), không chặn game.

const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const MUSIC_PATHS := ["res://assets/audio/music/%s.ogg", "res://assets/audio/music/%s.mp3"]
## File của owner trước; chưa có thì âm thanh tạm `assets/placeholders/placeholder_{id}.wav` (tools/gen_placeholder_sfx.py,
## bản Release loại placeholder nên vẫn im lặng tới khi có file thật).
const SFX_PATHS := ["res://assets/audio/sfx/%s.wav", "res://assets/audio/sfx/%s.ogg",
		"res://assets/placeholders/placeholder_%s.wav"]
const SFX_VOICES := 8
const EVENTS_PATH := "res://data/config/audio_events.json"
## Cùng một hiệu ứng không phát lại trong khoảng này (đòn trúng nhiều mục tiêu cùng lúc).
const SFX_MIN_GAP_MS := 40

## ID đã được yêu cầu nhưng chưa có file (để owner biết cần giao gì).
var missing: Dictionary = {}
var current_music := ""

var _music: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _cache: Dictionary = {}
## Bảng sự kiện → ID (data/config/audio_events.json).
var events: Dictionary = {"sfx": {}, "music": {}}
## ID đã được yêu cầu phát, theo thứ tự (giữ 64 mục gần nhất; để test và soát lỗi).
var requested: Array[String] = []
var _last_played_ms: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_buses()
	_music = AudioStreamPlayer.new()
	_music.bus = BUS_MUSIC
	add_child(_music)
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx.append(p)
	load_events()
	_connect_bus()


func load_events() -> void:
	if not FileAccess.file_exists(EVENTS_PATH):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	if d is Dictionary:
		for k in ["sfx", "music"]:
			if d.get(k) is Dictionary:
				events[k] = d[k]


## Nghe EventBus để phát âm thanh theo sự kiện; logic game không gọi thẳng vào đây.
func _connect_bus() -> void:
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus == null:
		return
	bus.hit_landed.connect(_on_hit_landed)
	bus.enemy_defeated.connect(func(_e: Node, _by: Object) -> void: play_event("enemy_down"))
	bus.enemy_stunned.connect(func(_e: Node, _by: Object) -> void: play_event("enemy_stunned"))
	bus.character_switched.connect(func(_f: String, _t: String, mode: String) -> void:
		play_event("switch_linked" if mode == "linked" else "switch"))
	bus.link_window_opened.connect(func(_id: String, _sec: float) -> void: play_event("link_ready"))
	bus.reaction_triggered.connect(func(_r: Resource, _c: Vector2, _by: Node) -> void: play_event("reaction"))
	bus.ultimate_started.connect(func(_a: Node, _s: Resource) -> void: play_event("ultimate"))
	bus.scene_changed.connect(_on_scene_changed)


func _on_hit_landed(_attacker: Object, target: Object, result: Object, _hit: Object) -> void:
	var t := target as Combatant
	if t and t.team == PhysicsLayers.Team.PLAYER:
		play_event("player_hurt")
	else:
		var r := result as DamageCalculator.Result
		play_event("hit_crit" if r and r.is_crit else "hit")


## Nhạc theo scene: tên file scene (title, hub, stage, test_stage) tra trong bảng `music`.
func _on_scene_changed(scene_path: String) -> void:
	play_event_music(scene_path.get_file().get_basename())


## Phát hiệu ứng của một sự kiện (khóa trong bảng `sfx`). Trả về false nếu sự kiện chưa gán hoặc chưa có file.
func play_event(event: String) -> bool:
	var id := str(events["sfx"].get(event, ""))
	if id == "":
		return false
	var now := Time.get_ticks_msec()
	if now - int(_last_played_ms.get(id, -100000)) < SFX_MIN_GAP_MS:
		return false
	_last_played_ms[id] = now
	return play_sfx(id)


## Phát nhạc của một sự kiện / scene (khóa trong bảng `music`); khóa lạ thì giữ nhạc đang phát.
func play_event_music(event: String) -> bool:
	var id := str(events["music"].get(event, ""))
	if id == "":
		return false
	return play_music(id)


func _note(id: String) -> void:
	requested.append(id)
	if requested.size() > 64:
		requested.pop_front()


## Tạo bus Music và SFX (con của Master) nếu chưa có.
static func ensure_buses() -> void:
	for bus in [BUS_MUSIC, BUS_SFX]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, &"Master")


## Âm lượng tuyến tính 0..1 cho "Master" / "Music" / "SFX"; 0 = tắt tiếng.
static func set_volume(bus: StringName, linear: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	var v := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(i, v <= 0.0)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))


static func get_volume(bus: StringName) -> float:
	var i := AudioServer.get_bus_index(bus)
	if i < 0 or AudioServer.is_bus_mute(i):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(i))


## Phát hiệu ứng; trả về false nếu chưa có file.
func play_sfx(id: String) -> bool:
	_note(id)
	var stream := _load(id, SFX_PATHS)
	if stream == null:
		return false
	var p := _sfx[_next_voice]
	_next_voice = (_next_voice + 1) % _sfx.size()
	p.stream = stream
	p.play()
	return true


## Phát nhạc nền (lặp do file quy định); cùng bài đang phát thì giữ nguyên. Trả về false nếu chưa có file.
func play_music(id: String) -> bool:
	_note(id)
	if id == current_music and _music.playing:
		return true
	var stream := _load(id, MUSIC_PATHS)
	if stream == null:
		stop_music()
		return false
	current_music = id
	_music.stream = stream
	_music.play()
	return true


func stop_music() -> void:
	current_music = ""
	_music.stop()


func _load(id: String, patterns: Array) -> AudioStream:
	if _cache.has(id):
		return _cache[id]
	for pat: String in patterns:
		var path := pat % id
		if ResourceLoader.exists(path):
			_cache[id] = load(path)
			return _cache[id]
	missing[id] = true
	_cache[id] = null
	return null
