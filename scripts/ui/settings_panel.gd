class_name SettingsPanel
extends VBoxContainer
## Bảng Cài đặt (README 15: âm thanh, ngôn ngữ, đồ họa): dùng trong Hub, Title và menu Tạm dừng.
## Đổi là áp ngay và ghi vào save (`settings`). Logic áp cài đặt nằm ở `apply_settings` (dùng cả lúc khởi động).

signal changed

const VOLUME_KEYS := {"master_volume": &"Master", "music_volume": &"Music", "sfx_volume": &"SFX"}
const VOLUME_LABELS := {"master_volume": "SETTINGS_VOLUME_MASTER", "music_volume": "SETTINGS_VOLUME_MUSIC",
		"sfx_volume": "SETTINGS_VOLUME_SFX"}

var _lang_buttons: Dictionary = {}   # code -> Button
var _sliders: Dictionary = {}        # key -> HSlider
var _fullscreen: CheckButton
var _labels: Dictionary = {}         # khóa dịch -> Label (đổi ngôn ngữ thì cập nhật lại)
var _title: Label


func _ready() -> void:
	add_theme_constant_override("separation", 18)
	_title = UiKit.label("", UiKit.FONT_TITLE)
	add_child(_title)
	# Ngôn ngữ.
	var lang_row := UiKit.hbox()
	lang_row.add_child(_keyed_label("SETTINGS_LANGUAGE", 300))
	for code: String in languages():
		var b := UiKit.button(tr("LANGUAGE_" + code.to_upper()), 240.0)
		b.toggle_mode = true
		b.pressed.connect(set_language.bind(code))
		lang_row.add_child(b)
		_lang_buttons[code] = b
	add_child(lang_row)
	# Âm lượng.
	for key: String in VOLUME_KEYS:
		var row := UiKit.hbox()
		row.add_child(_keyed_label(VOLUME_LABELS[key], 300))
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.custom_minimum_size = Vector2(520, UiKit.TOUCH_MIN)
		s.value_changed.connect(set_volume.bind(key))
		row.add_child(s)
		add_child(row)
		_sliders[key] = s
	# Đồ họa.
	_fullscreen = CheckButton.new()
	_fullscreen.custom_minimum_size = Vector2(0, UiKit.TOUCH_MIN)
	_fullscreen.add_theme_font_size_override("font_size", UiKit.FONT_BODY)
	_fullscreen.toggled.connect(set_fullscreen)
	add_child(_fullscreen)
	refresh()


func _keyed_label(key: String, width: float) -> Label:
	var l := UiKit.label(tr(key))
	l.custom_minimum_size.x = width
	_labels[key] = l
	return l


## Đồng bộ control theo save và ngôn ngữ hiện tại.
func refresh() -> void:
	var s := settings()
	_title.text = tr("SETTINGS_TITLE")
	for key: String in _labels:
		(_labels[key] as Label).text = tr(key)
	for code: String in _lang_buttons:
		(_lang_buttons[code] as Button).set_pressed_no_signal(code == str(s.get("language", "vi")))
		(_lang_buttons[code] as Button).text = tr("LANGUAGE_" + code.to_upper())
	for key: String in _sliders:
		(_sliders[key] as HSlider).set_value_no_signal(float(s.get(key, 1.0)))
	_fullscreen.text = tr("SETTINGS_FULLSCREEN")
	_fullscreen.set_pressed_no_signal(bool(s.get("fullscreen", false)))


static func settings() -> Dictionary:
	var save := UiKit.autoload("SaveService")
	return save.data["settings"] if save else {}


static func languages() -> Array:
	var gc := UiKit.autoload("GameConfig")
	return gc.LANGUAGES if gc else ["vi", "en"]


func set_language(code: String) -> void:
	if code not in languages():
		return
	settings()["language"] = code
	_commit()


func set_volume(value: float, key: String) -> void:
	if not VOLUME_KEYS.has(key):
		return
	settings()[key] = clampf(value, 0.0, 1.0)
	_commit()


func set_fullscreen(on: bool) -> void:
	settings()["fullscreen"] = on
	_commit()


func _commit() -> void:
	apply_settings(settings())
	var save := UiKit.autoload("SaveService")
	if save:
		save.save_game()
	refresh()
	changed.emit()


## Áp cài đặt vào game: ngôn ngữ, âm lượng 3 bus, toàn màn hình. `apply_language = false` khi dòng lệnh có --lang.
static func apply_settings(s: Dictionary, apply_language := true) -> void:
	var gc := UiKit.autoload("GameConfig")
	if apply_language and gc:
		gc.set_language(str(s.get("language", gc.DEFAULT_LANGUAGE)))
	var audio := UiKit.autoload("AudioRouter")
	if audio:
		audio.ensure_buses()
		for key: String in VOLUME_KEYS:
			audio.set_volume(VOLUME_KEYS[key], float(s.get(key, 1.0)))
	if DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(s.get("fullscreen", false)) else DisplayServer.WINDOW_MODE_WINDOWED
		var cur := DisplayServer.window_get_mode()
		var is_full := cur in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
		if is_full != bool(s.get("fullscreen", false)):
			DisplayServer.window_set_mode(want)
