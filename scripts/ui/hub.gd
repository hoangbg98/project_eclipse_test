extends Control
## Sảnh chính (README 15; owner 2026-11-14 bản 2): không còn thanh tab. Nội dung chính là HubHomePanel (nền, splash,
## thẻ người chơi, ô ghép mở các màn). Ba bảng nổi đè lên sảnh, đóng bằng nút ✕ hoặc Back / Esc:
## - "BattleTab": chọn đội + danh sách màn (HubBattlePanel) và hai nút vào màn (Màn 1, Màn thử nghiệm trong hub.tscn);
## - "ChatTab": Chat (ChatPanel, M9-6), mở bằng biểu tượng bong bóng góc phải;
##   mở từ thẻ Đội hình ở màn Xuất kích (GameConfig.hub_start_tab);
## - "SettingsTab": Cài đặt + Credits (+ nút quà thử nghiệm bản debug), mở bằng nút bánh răng góc phải;
## - "BackgroundTab": đổi nền sảnh (HubBackgroundPanel), mở bằng nút khung tranh góc phải.
## Back / Esc khi không có bảng nổi: về Title như trước.

const TABS := {
	"HomeTab": "HUB_TAB_HOME",
	"BattleTab": "HUB_TAB_BATTLE",
	"SettingsTab": "HUB_TAB_SETTINGS",
	"BackgroundTab": "HUB_TAB_BACKGROUND",
	"ChatTab": "HUB_TAB_CHAT",
}
const BACK_GROUP := &"back_interceptor"
const POPUP_RECT := Rect2(140, 70, 1640, 940)

var current_tab := ""
## Bảng đang hiện: sảnh (HubHomePanel) hoặc bảng trong bảng nổi (để test truy cập).
var panel: Control
var home: HubHomePanel

var _content: Control
var _popup: Control

@onready var _test_stage: Button = %TestStageButton
@onready var _stage_01: Button = %Stage01Button


func _ready() -> void:
	add_to_group(BACK_GROUP)
	_test_stage.pressed.connect(func() -> void: SceneRouter.push(GameConfig.SCENE_TEST_STAGE))
	_stage_01.pressed.connect(func() -> void:
		GameConfig.selected_stage_id = "stage_01"
		SceneRouter.push(GameConfig.SCENE_STAGE))
	_content = Control.new()
	_content.name = "Content"
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	move_child(_content, 1)
	_build_home()
	var start := GameConfig.hub_start_tab if TABS.has(GameConfig.hub_start_tab) else "HomeTab"
	GameConfig.hub_start_tab = ""
	show_tab(start)


func _build_home() -> void:
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	home = HubHomePanel.new()
	home.request_tab.connect(show_tab)
	_content.add_child(home)
	home.set_anchors_preset(Control.PRESET_FULL_RECT)
	home.add_theme_constant_override("separation", 0)


## Mở bảng nổi theo tên ("HomeTab" = đóng bảng nổi, chỉ còn sảnh).
func show_tab(tab_name: String) -> void:
	current_tab = tab_name
	_close_popup()
	var battle := tab_name == "BattleTab"
	_test_stage.visible = battle
	_stage_01.visible = battle
	if tab_name == "HomeTab" or not TABS.has(tab_name):
		current_tab = "HomeTab"
		panel = home
		return
	panel = _make_panel(tab_name)
	_open_popup(tr(TABS[tab_name]), panel)
	if battle:
		# Nút vào màn nằm trên bảng nổi.
		move_child(_stage_01, get_child_count() - 1)
		move_child(_test_stage, get_child_count() - 1)


func popup_open() -> bool:
	return _popup != null


## Back / Esc: đóng bảng nổi trước, rồi mới để SceneRouter quay lại Title.
func intercept_back() -> bool:
	if popup_open():
		show_tab("HomeTab")
		return true
	return false


func _open_popup(title: String, body: Control) -> void:
	_popup = Control.new()
	_popup.name = "Popup"
	_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_popup)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup.add_child(dim)
	var frame := Panel.new()
	frame.name = "Frame"
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.1, 0.16, 0.96)
	st.border_color = Color(0.5, 0.83, 1.0, 0.6)
	st.set_border_width_all(2)
	st.set_corner_radius_all(14)
	frame.add_theme_stylebox_override("panel", st)
	frame.position = POPUP_RECT.position
	frame.size = POPUP_RECT.size
	_popup.add_child(frame)
	var t := UiKit.label(title, 44)
	t.position = POPUP_RECT.position + Vector2(40, 22)
	t.size = Vector2(POPUP_RECT.size.x - 240, 64)
	_popup.add_child(t)
	var close := UiKit.button("✕", 128.0, 40)
	close.name = "CloseButton"
	close.custom_minimum_size = Vector2(128, 96)
	close.position = POPUP_RECT.position + Vector2(POPUP_RECT.size.x - 152, 16)
	close.size = Vector2(128, 96)
	close.pressed.connect(show_tab.bind("HomeTab"))
	_popup.add_child(close)
	var margin := MarginContainer.new()
	margin.name = "PopupBody"
	margin.position = POPUP_RECT.position + Vector2(40, 124)
	margin.size = POPUP_RECT.size - Vector2(80, 160)
	_popup.add_child(margin)
	margin.add_child(body)


func _close_popup() -> void:
	if _popup:
		remove_child(_popup)
		_popup.queue_free()
		_popup = null


func _make_panel(tab_name: String) -> Control:
	match tab_name:
		"BattleTab":
			var b := HubBattlePanel.new()
			b.changed.connect(_build_home_deferred)
			return b
		"ChatTab":
			return ChatPanel.new()
		"BackgroundTab":
			var bgp := HubBackgroundPanel.new()
			bgp.changed.connect(_build_home_deferred)
			return bgp
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
	return home


## Đội / nền đổi: dựng lại sảnh phía sau (ảnh đầu đội, nền) mà không đóng bảng nổi.
func _build_home_deferred() -> void:
	_rebuild_home.call_deferred()


func _rebuild_home() -> void:
	if home and is_instance_valid(home):
		home.refresh()


## Đổi ngôn ngữ: dựng lại sảnh (chữ dựng bằng code) và bảng Cài đặt.
func _on_language_maybe_changed() -> void:
	_rebuild_home.call_deferred()
	if current_tab == "SettingsTab":
		show_tab.call_deferred("SettingsTab")
