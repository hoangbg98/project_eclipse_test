extends Node
## Cấu hình toàn cục chỉ-đọc. Sau này nạp combat_rules.tres / link_rules.tres.
## Không giữ state của trận (xem docs/ARCHITECTURE.md mục 3).

const BASE_RESOLUTION := Vector2i(1920, 1080)
const SCENE_BOOT := "res://scenes/main/boot.tscn"
const SCENE_TITLE := "res://scenes/main/title.tscn"
const SCENE_HUB := "res://scenes/main/hub.tscn"
const SCENE_TEST_STAGE := "res://scenes/stages/test_stage.tscn"
const SCENE_STAGE := "res://scenes/stages/stage.tscn"
const SCENE_CHARACTER := "res://scenes/main/character_screen.tscn"
const SCENE_RECRUIT := "res://scenes/main/recruit_screen.tscn"
const SCENE_DEBUG_GIFT := "res://scenes/main/debug_gift_screen.tscn"
## Màn mở từ cụm nút lục giác của Hub (owner 2026-11-14).
const SCENE_BAG := "res://scenes/main/bag_screen.tscn"
const SCENE_SUPPLY := "res://scenes/main/supply_screen.tscn"
const SCENE_SORTIE := "res://scenes/main/sortie_screen.tscn"
const SCENE_COMPANION := "res://scenes/main/companion_screen.tscn"
const SCENE_PLAYER := "res://scenes/main/player_screen.tscn"
## Chuỗi vào màn (owner 2026-11-14): thông tin màn + mục tiêu → đội hình (splash) → chọn giáp.
const SCENE_STAGE_INFO := "res://scenes/main/stage_info_screen.tscn"
const SCENE_PARTY_PREP := "res://scenes/main/party_prep_screen.tscn"
const SCENE_PARTY_SELECT := "res://scenes/main/party_select_screen.tscn"
## Clip dẫn truyện dạng truyện tranh (owner 2026-11-14): phát `story_clip_id`, xong thì sang `story_clip_next`.
const SCENE_STORY_CLIP := "res://scenes/main/story_clip.tscn"

## Màn sẽ chơi khi mở SCENE_STAGE (data/stages/{id}.json).
var selected_stage_id := "stage_01"
## Nhân vật mở sẵn khi vào màn Nhân vật (rỗng = nhân vật đầu đội).
var selected_character_id := ""
## Tab Hub mở sẵn lần vào Hub kế tiếp (vd "BattleTab" từ thẻ Đội hình ở màn Xuất kích); rỗng = Trang chủ. Hub đọc rồi xóa.
var hub_start_tab := ""
## Màn đội hình: true = có nút Khai chiến vào `selected_stage_id` (mở từ thông tin màn); false = chỉ sửa đội.
var prep_launch_stage := false
## Clip truyện sẽ phát khi mở SCENE_STORY_CLIP (data/story/{id}.json) và scene mở khi clip xong.
var story_clip_id := ""
var story_clip_next := ""

## Thời gian chuyển cảnh (giây), trong khoảng 150-250 ms theo UI_UX_SPEC.
const TRANSITION_TIME := 0.2


## Ngôn ngữ hỗ trợ (mã locale). Màn Cài đặt (M7) sẽ gọi set_language.
const LANGUAGES: Array[String] = ["vi", "en"]
## Mặc định tiếng Việt, không theo ngôn ngữ của hệ điều hành (owner quyết định 2026-11-11).
const DEFAULT_LANGUAGE := "vi"
## Đổi khi chạy để thử: godot --path . -- --lang=en
const LANG_ARG_PREFIX := "--lang="


const COMBAT_RULES_PATH := "res://data/config/combat_rules.tres"

## Luật chiến đấu chung (chỉ đọc).
var combat_rules: CombatRules
## Các StatusDef trong data/statuses/.
var statuses: StatusLibrary


func _ready() -> void:
	set_language(startup_language(OS.get_cmdline_user_args()))
	load_data()


## Nạp dữ liệu tĩnh; lỗi được báo ra log, không chặn game.
func load_data() -> void:
	combat_rules = load(COMBAT_RULES_PATH) as CombatRules
	if combat_rules == null:
		push_error("GameConfig: không nạp được %s" % COMBAT_RULES_PATH)
	else:
		for e in combat_rules.validate():
			push_error("GameConfig combat_rules: %s" % e)
	statuses = StatusLibrary.load_dir()
	for e in statuses.errors:
		push_error("GameConfig statuses: %s" % e)


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
