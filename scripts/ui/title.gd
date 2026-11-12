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


func _on_continue() -> void:
	SaveService.load_game()
	SceneRouter.push(GameConfig.SCENE_HUB)


func _on_new_game() -> void:
	SaveService.new_game()
	SceneRouter.push(GameConfig.SCENE_HUB)


func _on_quit() -> void:
	get_tree().quit()
