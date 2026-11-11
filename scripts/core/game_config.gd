extends Node
## Cấu hình toàn cục chỉ-đọc. Sau này nạp combat_rules.tres / link_rules.tres.
## Không giữ state của trận (xem docs/ARCHITECTURE.md mục 3).

const BASE_RESOLUTION := Vector2i(1920, 1080)
const SCENE_BOOT := "res://scenes/main/boot.tscn"
const SCENE_TITLE := "res://scenes/main/title.tscn"
const SCENE_HUB := "res://scenes/main/hub.tscn"
const SCENE_TEST_STAGE := "res://scenes/stages/test_stage.tscn"

## Thời gian chuyển cảnh (giây), trong khoảng 150-250 ms theo UI_UX_SPEC.
const TRANSITION_TIME := 0.2


## Ngôn ngữ hỗ trợ (mã locale). Màn Cài đặt (M7) sẽ gọi set_language.
const LANGUAGES: Array[String] = ["vi", "en"]
## Mặc định tiếng Việt, không theo ngôn ngữ của hệ điều hành (owner quyết định 2026-11-11).
const DEFAULT_LANGUAGE := "vi"
## Đổi khi chạy để thử: godot --path . -- --lang=en
const LANG_ARG_PREFIX := "--lang="


func _ready() -> void:
	set_language(startup_language(OS.get_cmdline_user_args()))


## Ngôn ngữ lúc khởi động: tham số `--lang=xx` nếu hợp lệ, không thì mặc định.
## Sau này: ngôn ngữ đã lưu trong cài đặt (M5-1 SaveService / M7 Settings).
static func startup_language(user_args: PackedStringArray) -> String:
	for a in user_args:
		if a.begins_with(LANG_ARG_PREFIX):
			var code := a.trim_prefix(LANG_ARG_PREFIX)
			if code in LANGUAGES:
				return code
	return DEFAULT_LANGUAGE


func set_language(code: String) -> bool:
	if code not in LANGUAGES:
		return false
	TranslationServer.set_locale(code)
	return true


func get_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "dev"))
