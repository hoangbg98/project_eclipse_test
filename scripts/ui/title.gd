extends Control
## Màn Title: Tiếp tục, Game mới, Thoát.
## Tiếp tục bị khóa cho tới khi có SaveService (M5-1). Cài đặt thêm ở M7.

@onready var _continue: Button = %ContinueButton
@onready var _new_game: Button = %NewGameButton
@onready var _quit: Button = %QuitButton


func _ready() -> void:
	_continue.disabled = true
	_new_game.pressed.connect(_on_new_game)
	_quit.pressed.connect(_on_quit)
	_new_game.grab_focus()


func _on_new_game() -> void:
	SceneRouter.push(GameConfig.SCENE_HUB)


func _on_quit() -> void:
	get_tree().quit()
