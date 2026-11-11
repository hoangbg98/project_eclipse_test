extends Control
## Màn Boot: logo, thanh tiến độ, phiên bản. Chưa có tài nguyên nặng để nạp,
## nên tiến độ chạy theo thời gian rồi chuyển sang Title.

const BOOT_TIME := 1.0

@onready var _progress: ProgressBar = %Progress
@onready var _version: Label = %Version


func _ready() -> void:
	_version.text = "v%s" % GameConfig.get_version()
	_progress.value = 0.0
	var tween := create_tween()
	tween.tween_property(_progress, "value", 100.0, BOOT_TIME)
	await tween.finished
	SceneRouter.replace(GameConfig.SCENE_TITLE)
