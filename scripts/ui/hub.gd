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


func _ready() -> void:
	_back.pressed.connect(func() -> void: SceneRouter.go_back())
	for tab_name: String in TABS:
		var button: Button = _tab_bar.get_node(tab_name)
		button.pressed.connect(_show_tab.bind(tab_name))
	_show_tab("HomeTab")
	(_tab_bar.get_node("HomeTab") as Button).grab_focus()


func _show_tab(tab_name: String) -> void:
	_content.text = "%s\n%s" % [tr(TABS[tab_name]), tr("HUB_WIP")]
