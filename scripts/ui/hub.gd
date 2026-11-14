extends Control
## Hub (README 15): thanh tab Home / Chiến đấu / Chiêu mộ / Cài đặt và nút Back. Tab Nhân vật đã thay bằng nút
## lục giác Nhân vật ở tab Trang chủ (owner 2026-11-14); các màn Trang bị / Xuất kích / Tiếp tế / Người cộng tác /
## Thông tin người chơi cũng mở từ tab Trang chủ (HubHomePanel).
## Nội dung mỗi tab là một bảng dựng bằng code (HubPanel, SettingsPanel, CreditsPanel) đặt vào vùng nội dung.
## Hai nút vào màn (Màn 1, Màn thử nghiệm) nằm sẵn trong hub.tscn, chỉ hiện ở tab Chiến đấu.

const TABS := {
	"HomeTab": "HUB_TAB_HOME",
	"BattleTab": "HUB_TAB_BATTLE",
	"RecruitTab": "HUB_TAB_RECRUIT",
	"SettingsTab": "HUB_TAB_SETTINGS",
}

const RECRUIT_TAB := "RecruitTab"

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
		if tab_name == RECRUIT_TAB:
			button.pressed.connect(open_recruit)
		else:
			button.pressed.connect(show_tab.bind(tab_name))
	var start := GameConfig.hub_start_tab if TABS.has(GameConfig.hub_start_tab) else "HomeTab"
	GameConfig.hub_start_tab = ""
	show_tab(start)
	(_tab_bar.get_node(start) as Button).grab_focus()


## Tab Chiêu mộ mở màn riêng RecruitScreen (theo ảnh tham chiếu màn Wish của owner).
func open_recruit() -> void:
	(_tab_bar.get_node(RECRUIT_TAB) as Button).set_pressed_no_signal(current_tab == RECRUIT_TAB)
	SceneRouter.push(GameConfig.SCENE_RECRUIT)


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
		"SettingsTab":
			var box := UiKit.hbox(64)
			var settings := SettingsPanel.new()
			settings.changed.connect(_on_language_maybe_changed)
			box.add_child(settings)
			var credits := CreditsPanel.new()
			credits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_child(credits)
			# Công cụ gửi quà thử nghiệm: chỉ bản debug (DebugGiftScreen.available()).
			if DebugGiftScreen.available():
				var gift_button := UiKit.button(tr("DEBUG_GIFT_OPEN"), 380.0, 28)
				gift_button.name = "DebugGiftButton"
				gift_button.pressed.connect(func() -> void: SceneRouter.push(GameConfig.SCENE_DEBUG_GIFT))
				box.add_child(gift_button)
			return box
	return HubHomePanel.new()


## Đổi ngôn ngữ: cập nhật chữ trên thanh tab (nút trong .tscn dùng khóa dịch nên tự đổi; nhãn dựng bằng code thì không).
func _on_language_maybe_changed() -> void:
	if current_tab == "SettingsTab":
		show_tab.call_deferred("SettingsTab")
