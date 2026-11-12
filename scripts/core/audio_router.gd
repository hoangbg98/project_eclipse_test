extends Node
## Autoload `AudioRouter`: bus âm thanh (Master / Music / SFX), âm lượng, phát nhạc và hiệu ứng theo ID.
## File âm thanh do owner giao (OWNER_ASSET_CHECKLIST mục D): `assets/audio/music/{id}.ogg`, `assets/audio/sfx/{id}.wav|ogg`.
## Thiếu file thì bỏ qua trong im lặng (ghi nhận một lần vào `missing`), không chặn game.

const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const MUSIC_PATHS := ["res://assets/audio/music/%s.ogg", "res://assets/audio/music/%s.mp3"]
const SFX_PATHS := ["res://assets/audio/sfx/%s.wav", "res://assets/audio/sfx/%s.ogg"]
const SFX_VOICES := 8

## ID đã được yêu cầu nhưng chưa có file (để owner biết cần giao gì).
var missing: Dictionary = {}
var current_music := ""

var _music: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _cache: Dictionary = {}


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
