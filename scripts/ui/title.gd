extends Control
## Màn Title: Tiếp tục, Game mới, Thoát.
## Tiếp tục chỉ bật khi có save (SaveService, M5-1). Game mới tạo save mới. Cài đặt thêm ở M7.

@onready var _continue: Button = %ContinueButton
@onready var _new_game: Button = %NewGameButton
@onready var _quit: Button = %QuitButton


func _ready() -> void:
	_continue.disabled = not SaveService.has_save()
	_continue.pressed.connect(_on_continue)
	_new_game.pressed.connect(_on_new_game)
	_quit.pressed.connect(_on_quit)
	(_new_game if _continue.disabled else _continue).grab_focus()
	_build_online()
	_build_settings()


## Nút "Trực tuyến (thử nghiệm)" (M9-1): mở màn đăng nhập máy chủ Nakama.
func _build_online() -> void:
	var b := Button.new()
	b.name = "OnlineButton"
	b.text = tr("TITLE_ONLINE")
	b.custom_minimum_size = _quit.custom_minimum_size
	b.add_theme_font_size_override("font_size", _quit.get_theme_font_size("font_size"))
	_quit.get_parent().add_child(b)
	_quit.get_parent().move_child(b, _quit.get_index())
	b.pressed.connect(func() -> void: SceneRouter.push(GameConfig.SCENE_ONLINE))


var _settings_layer: CanvasLayer


## Nút Cài đặt + lớp phủ Cài đặt (README 15: Title có Settings).
func _build_settings() -> void:
	var b := Button.new()
	b.name = "SettingsButton"
	b.text = tr("HUB_TAB_SETTINGS")
	b.custom_minimum_size = _quit.custom_minimum_size
	b.add_theme_font_size_override("font_size", _quit.get_theme_font_size("font_size"))
	_quit.get_parent().add_child(b)
	_quit.get_parent().move_child(b, _quit.get_index())
	b.pressed.connect(func() -> void: _settings_layer.visible = true)
	_settings_layer = CanvasLayer.new()
	_settings_layer.layer = 20
	_settings_layer.visible = false
	add_child(_settings_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.06, 0.1, 0.96)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_layer.add_child(center)
	var box := UiKit.vbox(20)
	center.add_child(box)
	box.add_child(SettingsPanel.new())
	var close := UiKit.button(tr("UI_BACK"), 520.0)
	close.pressed.connect(func() -> void:
		_settings_layer.visible = false
		get_tree().reload_current_scene())   # dựng lại để chữ theo ngôn ngữ mới
	box.add_child(close)


func _on_continue() -> void:
	SaveService.load_game()
	SceneRouter.push(GameConfig.SCENE_HUB)


func _on_new_game() -> void:
	SaveService.new_game()
	SceneRouter.push(GameConfig.SCENE_HUB)


func _on_quit() -> void:
	get_tree().quit()
