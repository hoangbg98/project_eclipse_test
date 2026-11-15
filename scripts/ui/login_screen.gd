class_name LoginScreen
extends Control
## Màn Đăng nhập (M9-1b, owner 2026-11-16): hiện sau Boot khi bật `login_on_start` (data/config/online_config.json).
## Hai thẻ: Đăng nhập (tên hoặc email + mật khẩu) và Tạo tài khoản (tên, email, mật khẩu, nhập lại).
## Có phiên đã ghi nhớ thì tự vào lại. "Chơi ngoại tuyến" vào game không cần máy chủ.
## Máy chủ coi như dịch vụ ngoài dự án: chỉ biết địa chỉ (mặc định trong data, đổi ở dòng "Máy chủ").
## Màn chỉ gọi OnlineService; không chứa luật.

enum Mode { LOGIN, REGISTER }

## Test gán service giả; null = autoload OnlineService.
var service: Node
## false: không chuyển màn khi vào game (test).
var navigate := true
## Số lần đã vào game (test đọc).
var entered := 0
var mode := Mode.LOGIN

var _fields := {}
var _status: Label
var _login_box: VBoxContainer
var _register_box: GridContainer
var _tab_login: Button
var _tab_register: Button
var _submit: Button
var _remember: CheckBox
var _server_label: Label
var _server_row: HBoxContainer
var _busy := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if service == null:
		service = UiKit.autoload("OnlineService")
	_build()
	set_mode(Mode.LOGIN)
	if service and service.has_saved_session():
		_try_resume()


func set_mode(m: Mode) -> void:
	mode = m
	_login_box.visible = m == Mode.LOGIN
	_register_box.visible = m == Mode.REGISTER
	_tab_login.button_pressed = m == Mode.LOGIN
	_tab_register.button_pressed = m == Mode.REGISTER
	_submit.text = tr("LOGIN_SUBMIT") if m == Mode.LOGIN else tr("LOGIN_REGISTER_SUBMIT")
	_set_status("")


func field(key: String) -> LineEdit:
	return _fields[key]


## Bấm nút chính của thẻ đang mở. Trả về true nếu đã vào game.
func submit() -> bool:
	if _busy or service == null:
		return false
	_busy = true
	_submit.disabled = true
	_set_status(tr("ONLINE_STATUS_CONNECTING"))
	var ok: bool
	if mode == Mode.LOGIN:
		ok = await service.login_account(field("login_name").text, field("login_password").text, _remember.button_pressed)
	else:
		ok = await service.register(field("reg_name").text, field("reg_email").text, field("reg_password").text,
				field("reg_confirm").text, _remember.button_pressed)
	_busy = false
	_submit.disabled = false
	if ok:
		_enter_game()
	else:
		_set_status(tr(service.last_error), true)
	return ok


func play_offline() -> void:
	_enter_game()


## Lưu địa chỉ máy chủ mới (chuỗi rỗng = mặc định).
func apply_server(raw: String) -> void:
	service.config.set_server_url(raw)
	_server_label.text = tr("LOGIN_SERVER") % service.config.server_url
	_server_row.visible = false


func status_text() -> String:
	return _status.text


func _try_resume() -> void:
	_busy = true
	_submit.disabled = true
	_set_status(tr("LOGIN_RESUMING") % service.saved_username())
	var ok: bool = await service.resume()
	_busy = false
	_submit.disabled = false
	if ok:
		_enter_game()
	else:
		field("login_name").text = service.saved_username()
		_set_status(tr(service.last_error) if not service.last_error.is_empty() else "", true)


func _enter_game() -> void:
	entered += 1
	if not navigate:
		return
	var router := UiKit.autoload("SceneRouter")
	if router:
		router.replace(GameConfig.SCENE_TITLE)


func _set_status(text: String, is_error := false) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", Color("#FF8A80") if is_error else Color("#C8D0E0"))


# ---------- Dựng giao diện ----------

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.09, 0.16, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := UiKit.vbox(24)
	col.custom_minimum_size.x = 960.0
	center.add_child(col)

	col.add_child(UiKit.label("PROJECT ECLIPSE", 88, HORIZONTAL_ALIGNMENT_CENTER))

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1B1E2B")
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(40)
	panel.add_theme_stylebox_override("panel", sb)
	col.add_child(panel)
	var box := UiKit.vbox(20)
	panel.add_child(box)

	var tabs := UiKit.hbox(12)
	var group := ButtonGroup.new()
	_tab_login = _tab_button(tr("LOGIN_TAB_LOGIN"), group, "TabLogin")
	_tab_login.pressed.connect(func() -> void: set_mode(Mode.LOGIN))
	_tab_register = _tab_button(tr("LOGIN_TAB_REGISTER"), group, "TabRegister")
	_tab_register.pressed.connect(func() -> void: set_mode(Mode.REGISTER))
	tabs.add_child(_tab_login)
	tabs.add_child(_tab_register)
	box.add_child(tabs)

	_login_box = UiKit.vbox(14)
	_add_field(_login_box, "login_name", tr("LOGIN_NAME_OR_EMAIL"), false)
	_add_field(_login_box, "login_password", tr("LOGIN_PASSWORD"), true)
	box.add_child(_login_box)

	_register_box = GridContainer.new()
	_register_box.columns = 2
	_register_box.add_theme_constant_override("h_separation", 20)
	_register_box.add_theme_constant_override("v_separation", 14)
	_add_field(_register_box, "reg_name", tr("LOGIN_USERNAME"), false, tr("LOGIN_USERNAME_HINT"))
	_add_field(_register_box, "reg_email", tr("LOGIN_EMAIL"), false)
	_add_field(_register_box, "reg_password", tr("LOGIN_PASSWORD"), true, tr("LOGIN_PASSWORD_HINT"))
	_add_field(_register_box, "reg_confirm", tr("LOGIN_PASSWORD_CONFIRM"), true)
	box.add_child(_register_box)

	_remember = CheckBox.new()
	_remember.name = "Remember"
	_remember.text = tr("LOGIN_REMEMBER")
	_remember.button_pressed = true
	_remember.add_theme_font_size_override("font_size", 26)
	box.add_child(_remember)

	_status = UiKit.label("", 26)
	_status.name = "Status"
	box.add_child(_status)

	_submit = UiKit.button(tr("LOGIN_SUBMIT"), 320.0, 34)
	_submit.name = "SubmitButton"
	_submit.custom_minimum_size.y = 96.0
	_submit.pressed.connect(submit)
	box.add_child(_submit)

	var bottom := UiKit.hbox(16)
	var offline := UiKit.button(tr("LOGIN_PLAY_OFFLINE"), 320.0, 28)
	offline.name = "OfflineButton"
	offline.custom_minimum_size.y = 72.0
	offline.pressed.connect(play_offline)
	bottom.add_child(offline)
	_server_label = UiKit.label(tr("LOGIN_SERVER") % (service.config.server_url if service else ""), 22)
	_server_label.name = "ServerLabel"
	_server_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_server_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_server_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bottom.add_child(_server_label)
	var change := UiKit.button(tr("LOGIN_SERVER_CHANGE"), 160.0, 24)
	change.name = "ServerChange"
	change.custom_minimum_size.y = 72.0
	change.pressed.connect(func() -> void: _server_row.visible = not _server_row.visible)
	bottom.add_child(change)
	col.add_child(bottom)

	_server_row = UiKit.hbox(12)
	_server_row.name = "ServerRow"
	_server_row.visible = false
	var url := LineEdit.new()
	url.name = "ServerUrl"
	url.text = service.config.server_url if service else ""
	url.placeholder_text = "https://..."
	url.custom_minimum_size = Vector2(0, 72)
	url.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	url.add_theme_font_size_override("font_size", 24)
	url.text_submitted.connect(apply_server)
	_server_row.add_child(url)
	var save := UiKit.button(tr("LOGIN_SERVER_SAVE"), 160.0, 24)
	save.custom_minimum_size.y = 72.0
	save.pressed.connect(func() -> void: apply_server(url.text))
	_server_row.add_child(save)
	col.add_child(_server_row)


func _tab_button(text: String, group: ButtonGroup, node_name: String) -> Button:
	var b := UiKit.button(text, 0.0, 30)
	b.name = node_name
	b.toggle_mode = true
	b.button_group = group
	b.custom_minimum_size.y = 80.0
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


func _add_field(parent: Control, key: String, caption: String, secret: bool, hint := "") -> void:
	var row := UiKit.vbox(6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(UiKit.label(caption, 24))
	var e := LineEdit.new()
	e.name = key.to_pascal_case()
	e.secret = secret
	e.placeholder_text = hint
	e.custom_minimum_size = Vector2(0, 72)
	e.add_theme_font_size_override("font_size", 28)
	e.text_submitted.connect(func(_t: String) -> void: submit())
	row.add_child(e)
	parent.add_child(row)
	_fields[key] = e
