class_name PauseMenu
extends CanvasLayer
## Menu Tạm dừng trong màn chơi (README 15: Tiếp tục, Cài đặt, Thoát có xác nhận).
## Mở bằng action `pause`, Esc / phím Back (chặn trước SceneRouter), nút Pause trên HUD, hoặc khi cửa sổ mất focus.
## Dừng cả cây scene (`get_tree().paused`); node này chạy ở chế độ ALWAYS.

signal opened
signal resumed
signal quit_requested

## Nhóm để SceneRouter hỏi trước khi quay lại scene trước (phím Back Android).
const BACK_GROUP := &"back_interceptor"

enum View { MAIN, SETTINGS, CONFIRM_QUIT }

var view := View.MAIN
## false: không mở được (vd đang hiện màn kết quả).
var enabled := true

var _root: Control
var _main: VBoxContainer
var _settings_box: VBoxContainer
var _confirm: VBoxContainer
var _settings: SettingsPanel
var _resume: Button


func _ready() -> void:
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(BACK_GROUP)
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_root = CenterContainer.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_main = UiKit.vbox(20)
	_main.add_child(UiKit.label(tr("PAUSE_TITLE"), 64, HORIZONTAL_ALIGNMENT_CENTER))
	_resume = _add(_main, "PAUSE_RESUME", resume)
	_add(_main, "PAUSE_SETTINGS", show_view.bind(View.SETTINGS))
	_add(_main, "PAUSE_QUIT", show_view.bind(View.CONFIRM_QUIT))
	_root.add_child(_main)

	_settings_box = UiKit.vbox(20)
	_settings = SettingsPanel.new()
	_settings_box.add_child(_settings)
	_add(_settings_box, "UI_BACK", show_view.bind(View.MAIN))
	_root.add_child(_settings_box)

	_confirm = UiKit.vbox(20)
	_confirm.add_child(UiKit.label(tr("PAUSE_QUIT_CONFIRM"), 40, HORIZONTAL_ALIGNMENT_CENTER))
	_add(_confirm, "PAUSE_QUIT_YES", confirm_quit)
	_add(_confirm, "PAUSE_QUIT_NO", show_view.bind(View.MAIN))
	_root.add_child(_confirm)
	show_view(View.MAIN)


func _add(box: VBoxContainer, key: String, action: Callable) -> Button:
	var b := UiKit.button(tr(key), 520.0)
	b.pressed.connect(action)
	box.add_child(b)
	return b


func is_open() -> bool:
	return visible


func open() -> void:
	if not enabled or visible:
		return
	visible = true
	get_tree().paused = true
	show_view(View.MAIN)
	_resume.grab_focus()
	opened.emit()


func resume() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	resumed.emit()


func show_view(v: View) -> void:
	view = v
	_main.visible = v == View.MAIN
	_settings_box.visible = v == View.SETTINGS
	_confirm.visible = v == View.CONFIRM_QUIT


## Thoát màn chơi về scene trước (Hub); tiến độ màn đang chơi không được lưu.
func confirm_quit() -> void:
	visible = false
	get_tree().paused = false
	quit_requested.emit()
	var router := get_tree().root.get_node_or_null("SceneRouter")
	var gc := get_tree().root.get_node_or_null("GameConfig")
	if router and gc and not router.can_go_back():
		router.replace(gc.SCENE_HUB)
	elif router:
		router.go_back()


## Nút Back / Esc: đang mở thì lùi một bước (xác nhận / cài đặt → menu chính → tiếp tục); chưa mở thì mở.
## Trả về true nếu đã xử lý (SceneRouter không quay lại scene trước).
func intercept_back() -> bool:
	if not enabled:
		return false
	if not visible:
		open()
	elif view != View.MAIN:
		show_view(View.MAIN)
	else:
		resume()
	return true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_back"):
		if intercept_back():
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# Mất focus (Alt-Tab, cuộc gọi đến trên điện thoại): tự tạm dừng.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_inside_tree() and enabled and not visible:
			open()
