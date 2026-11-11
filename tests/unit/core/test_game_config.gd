extends GdUnitTestSuite
## Unit test cho GameConfig (scripts/core/game_config.gd).
## Tạo instance riêng, không phụ thuộc autoload.

const GameConfigScript := preload("res://scripts/core/game_config.gd")

var _config: Node
var _saved_locale: String


func before_test() -> void:
	_config = auto_free(GameConfigScript.new())
	_saved_locale = TranslationServer.get_locale()


func after_test() -> void:
	TranslationServer.set_locale(_saved_locale)


func test_base_resolution_is_1920x1080() -> void:
	assert_that(GameConfigScript.BASE_RESOLUTION).is_equal(Vector2i(1920, 1080))


func test_transition_time_within_spec() -> void:
	# UI_UX_SPEC: chuyển cảnh 150-250 ms
	assert_float(GameConfigScript.TRANSITION_TIME).is_between(0.15, 0.25)


func test_version_comes_from_project_settings() -> void:
	assert_str(_config.get_version()).is_equal(
			str(ProjectSettings.get_setting("application/config/version")))


func test_set_language_accepts_supported() -> void:
	for code in GameConfigScript.LANGUAGES:
		assert_bool(_config.set_language(code)).is_true()
		assert_str(TranslationServer.get_locale()).starts_with(code)


func test_set_language_rejects_unsupported_and_keeps_locale() -> void:
	_config.set_language("vi")
	assert_bool(_config.set_language("xx")).is_false()
	assert_str(TranslationServer.get_locale()).starts_with("vi")


func test_default_language_is_vietnamese_regardless_of_os() -> void:
	TranslationServer.set_locale("en_US")  # giả lập Windows tiếng Anh
	add_child(_config)  # _ready đặt ngôn ngữ khởi động
	assert_str(TranslationServer.get_locale()).starts_with("vi")
	assert_str(TranslationServer.translate("TITLE_NEW_GAME")).is_equal("Game mới")


func test_startup_language_from_argument() -> void:
	assert_str(GameConfigScript.startup_language(PackedStringArray())).is_equal("vi")
	assert_str(GameConfigScript.startup_language(PackedStringArray(["--lang=en"]))).is_equal("en")
	assert_str(GameConfigScript.startup_language(PackedStringArray(["--lang=xx"]))).is_equal("vi")
	assert_str(GameConfigScript.startup_language(PackedStringArray(["--foo", "--lang=en"]))).is_equal("en")


func test_translation_switches_with_language() -> void:
	_config.set_language("vi")
	assert_str(TranslationServer.translate("TITLE_NEW_GAME")).is_equal("Game mới")
	_config.set_language("en")
	assert_str(TranslationServer.translate("TITLE_NEW_GAME")).is_equal("New Game")
