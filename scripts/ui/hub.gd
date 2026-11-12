extends Control
## Hub tối thiểu: thanh tab Home / Battle / Characters / Recruit / Settings và nút Back.
## Nội dung từng tab là placeholder; màn thật làm ở M7.

const TABS := {
	"HomeTab": "HUB_TAB_HOME",
	"BattleTab": "HUB_TAB_BATTLE",
	"CharactersTab": "HUB_TAB_CHARACTERS",
	"RecruitTab": "HUB_TAB_RECRUIT",
	"SettingsTab": "HUB_TAB_SETTINGS",
}

@onready var _back: Button = %BackButton
@onready var _tab_bar: HBoxContainer = %TabBar
@onready var _content: Label = %ContentLabel
@onready var _test_stage: Button = %TestStageButton
@onready var _stage_01: Button = %Stage01Button


func _ready() -> void:
	_back.pressed.connect(func() -> void: SceneRouter.go_back())
	# Tạm thời (M2-3): tab Battle có nút vào màn thử nghiệm. Thay bằng màn chọn màn ở M7.
	_test_stage.pressed.connect(func() -> void: SceneRouter.push(GameConfig.SCENE_TEST_STAGE))
	# Tạm thời (M6): nút vào Màn 1. Màn chọn màn / chọn đội làm ở M7.
	_stage_01.pressed.connect(func() -> void:
		GameConfig.selected_stage_id = "stage_01"
		SceneRouter.push(GameConfig.SCENE_STAGE))
	for tab_name: String in TABS:
		var button: Button = _tab_bar.get_node(tab_name)
		button.pressed.connect(_show_tab.bind(tab_name))
	_show_tab("HomeTab")
	(_tab_bar.get_node("HomeTab") as Button).grab_focus()


func _show_tab(tab_name: String) -> void:
	_content.text = "%s\n%s" % [tr(TABS[tab_name]), tr("HUB_WIP")]
	_test_stage.visible = tab_name == "BattleTab"
	_stage_01.visible = tab_name == "BattleTab"
