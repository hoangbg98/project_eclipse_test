extends Control
## Hub (README 15): thanh tab Home / Chiến đấu / Nhân vật / Chiêu mộ / Cài đặt và nút Back.
## Nội dung mỗi tab là một bảng dựng bằng code (HubPanel, SettingsPanel, CreditsPanel) đặt vào vùng nội dung.
## Hai nút vào màn (Màn 1, Màn thử nghiệm) nằm sẵn trong hub.tscn, chỉ hiện ở tab Chiến đấu.

const TABS := {
	"HomeTab": "HUB_TAB_HOME",
	"BattleTab": "HUB_TAB_BATTLE",
	"CharactersTab": "HUB_TAB_CHARACTERS",
	"RecruitTab": "HUB_TAB_RECRUIT",
	"SettingsTab": "HUB_TAB_SETTINGS",
}

var current_tab := ""
## Bảng đang hiện (để test truy cập).
var panel: Control

var _content: MarginContainer

@onready var _back: Button = %BackButton
@onready var _tab_bar: HBoxContainer = %TabBar
@onready var _content_label: Label = %ContentLabel
@onready var _test_stage: Button = %TestStageButton
@onready var _stage_01: Button = %Stage01Button


func _ready() -> void:
	_back.pressed.connect(func() -> void: SceneRouter.go_back())
	_test_stage.pressed.connect(func() -> void: SceneRouter.push(GameConfig.SCENE_TEST_STAGE))
	_stage_01.pressed.connect(func() -> void:
		GameConfig.selected_stage_id = "stage_01"
		SceneRouter.push(GameConfig.SCENE_STAGE))
	_content_label.visible = false
	_content = MarginContainer.new()
	_content.name = "Content"
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.offset_top = 190.0
	_content.offset_bottom = -40.0
	for side in ["left", "right"]:
		_content.add_theme_constant_override("margin_" + side, 64)
	add_child(_content)
	move_child(_content, _content_label.get_index())
	for tab_name: String in TABS:
		var button: Button = _tab_bar.get_node(tab_name)
		button.toggle_mode = true
		button.pressed.connect(show_tab.bind(tab_name))
	show_tab("HomeTab")
	(_tab_bar.get_node("HomeTab") as Button).grab_focus()


func show_tab(tab_name: String) -> void:
	current_tab = tab_name
	# Tab đang mở giữ trạng thái nhấn để người chơi biết mình đang ở đâu.
	for t: String in TABS:
		(_tab_bar.get_node(t) as Button).set_pressed_no_signal(t == tab_name)
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	panel = _make_panel(tab_name)
	_content.add_child(panel)
	var battle := tab_name == "BattleTab"
	_test_stage.visible = battle
	_stage_01.visible = battle
	# Chừa chỗ cho hai nút vào màn ở tab Chiến đấu.
	_content.offset_bottom = -560.0 if battle else -40.0


func _make_panel(tab_name: String) -> Control:
	match tab_name:
		"BattleTab":
			return HubBattlePanel.new()
		"CharactersTab":
			return HubCharactersPanel.new()
		"RecruitTab":
			return HubRecruitPanel.new()
		"SettingsTab":
			var box := UiKit.hbox(64)
			var settings := SettingsPanel.new()
			settings.changed.connect(_on_language_maybe_changed)
			box.add_child(settings)
			var credits := CreditsPanel.new()
			credits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_child(credits)
			return box
	return HubHomePanel.new()


## Đổi ngôn ngữ: cập nhật chữ trên thanh tab (nút trong .tscn dùng khóa dịch nên tự đổi; nhãn dựng bằng code thì không).
func _on_language_maybe_changed() -> void:
	if current_tab == "SettingsTab":
		show_tab.call_deferred("SettingsTab")
