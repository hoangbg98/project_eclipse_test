class_name OnlineScreen
extends Control
## Màn "Tài khoản trực tuyến" (M9-1): tên tài khoản, mã người chơi, ví trên máy chủ, Làm mới, Đăng xuất.
## Mã người chơi là thứ người chơi ghi vào nội dung chuyển khoản khi nạp (QTV phát quà bằng server\grant.ps1).
## Chưa đăng nhập thì có nút mở màn Đăng nhập. Màn chỉ gọi OnlineService; không chứa luật.

## Test gán service giả; null = autoload OnlineService.
var service: Node

var _status: Label
var _profile_box: VBoxContainer
var _account_label: Label
var _code_label: Label
var _wallet_label: Label
var _login_btn: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if service == null:
		service = UiKit.autoload("OnlineService")
	_build()
	if service:
		service.state_changed.connect(func(_s: int) -> void: refresh_view())
		service.profile_changed.connect(func(_p: Dictionary) -> void: refresh_view())
	refresh_view()


func status_text() -> String:
	if service == null:
		return tr("ONLINE_ERR_NO_SERVICE")
	match service.state:
		service.State.CONNECTING:
			return tr("ONLINE_STATUS_CONNECTING")
		service.State.ONLINE:
			return tr("ONLINE_STATUS_ONLINE") + "  " + service.config.server_url
		service.State.ERROR:
			return tr("ONLINE_STATUS_ERROR") % tr(service.last_error)
	return tr("ONLINE_STATUS_OFFLINE")


func wallet_text() -> String:
	var parts: PackedStringArray = []
	for c in service.config.currencies_shown:
		parts.append("%s %d" % [tr("CURRENCY_" + str(c).to_upper()), service.wallet_amount(str(c))])
	return "  ·  ".join(parts)


func refresh_view() -> void:
	_status.text = status_text()
	var online: bool = service != null and service.is_online()
	_profile_box.visible = online
	_login_btn.visible = not online
	if online:
		_account_label.text = tr("ONLINE_ACCOUNT") % service.username()
		_code_label.text = NakamaApi.format_code(str(service.profile.get("code", "")))
		_wallet_label.text = wallet_text()


func logout() -> void:
	service.logout()
	_open_login()


func _open_login() -> void:
	var router := UiKit.autoload("SceneRouter")
	if router:
		router.replace(GameConfig.SCENE_LOGIN)


func _copy_code() -> void:
	DisplayServer.clipboard_set(str(service.profile.get("code", "")))
	_status.text = tr("ONLINE_CODE_COPIED")


func _go_back() -> void:
	var router := UiKit.autoload("SceneRouter")
	if router:
		router.go_back()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#1B1E2B")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 160)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	add_child(margin)
	var root := UiKit.vbox(24)
	margin.add_child(root)

	root.add_child(UiKit.label(tr("ONLINE_TITLE"), UiKit.FONT_TITLE))
	_status = UiKit.label("", 26)
	_status.name = "Status"
	root.add_child(_status)
	_login_btn = UiKit.button(tr("ONLINE_OPEN_LOGIN"), 420.0, 30)
	_login_btn.name = "LoginButton"
	_login_btn.custom_minimum_size.y = 96.0
	_login_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_login_btn.pressed.connect(_open_login)
	root.add_child(_login_btn)

	_profile_box = UiKit.vbox(16)
	_profile_box.name = "Profile"
	_account_label = UiKit.label("", 34)
	_account_label.name = "Account"
	_profile_box.add_child(_account_label)
	_profile_box.add_child(UiKit.label(tr("ONLINE_PLAYER_CODE"), 30))
	var code_row := UiKit.hbox(24)
	_code_label = UiKit.label("", 72)
	_code_label.name = "Code"
	_code_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	code_row.add_child(_code_label)
	var copy := UiKit.button(tr("ONLINE_COPY_CODE"), 260.0, 30)
	copy.name = "CopyButton"
	copy.custom_minimum_size.y = 84.0
	copy.pressed.connect(_copy_code)
	code_row.add_child(copy)
	_profile_box.add_child(code_row)
	_profile_box.add_child(UiKit.label(tr("ONLINE_CODE_HINT"), 24))
	_wallet_label = UiKit.label("", 34)
	_wallet_label.name = "Wallet"
	_profile_box.add_child(_wallet_label)
	_profile_box.add_child(UiKit.label(tr("ONLINE_WALLET_HINT"), 22))
	var actions := UiKit.hbox(16)
	var refresh := UiKit.button(tr("ONLINE_REFRESH"), 320.0, 30)
	refresh.name = "RefreshButton"
	refresh.custom_minimum_size.y = 84.0
	refresh.pressed.connect(func() -> void: service.refresh_profile())
	actions.add_child(refresh)
	var out := UiKit.button(tr("ONLINE_LOGOUT"), 320.0, 30)
	out.name = "LogoutButton"
	out.custom_minimum_size.y = 84.0
	out.pressed.connect(logout)
	actions.add_child(out)
	_profile_box.add_child(actions)
	root.add_child(_profile_box)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var back := UiKit.button(tr("UI_BACK"), 320.0, 30)
	back.name = "BackButton"
	back.custom_minimum_size.y = 84.0
	back.pressed.connect(_go_back)
	root.add_child(back)
