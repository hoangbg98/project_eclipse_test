extends Control
## Màn Boot: logo, thanh tiến độ, phiên bản. Chưa có tài nguyên nặng để nạp,
## nên tiến độ chạy theo thời gian rồi chuyển sang Đăng nhập (nếu bật) hoặc Title.

const BOOT_TIME := 1.0

@onready var _progress: ProgressBar = %Progress
@onready var _version: Label = %Version


func _ready() -> void:
	_version.text = "v%s" % GameConfig.get_version()
	_progress.value = 0.0
	var tween := create_tween()
	tween.tween_property(_progress, "value", 100.0, BOOT_TIME)
	await tween.finished
	SceneRouter.replace(GameConfig.SCENE_LOGIN if show_login() else GameConfig.SCENE_TITLE)


## Màn Đăng nhập sau Boot (M9-1b) khi bật `login_on_start`; chạy headless (test) hoặc có tham số --offline thì bỏ qua.
static func show_login() -> bool:
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().has("--offline"):
		return false
	var online := UiKit.autoload("OnlineService")
	return online != null and online.config != null and online.config.login_on_start
