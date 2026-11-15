class_name OnlineScreen
extends Control
## Màn "Trực tuyến (thử nghiệm)" (M9-1): nhập địa chỉ máy chủ, đăng nhập, xem mã người chơi và ví trên máy chủ.
## Mã người chơi là thứ người chơi ghi vào nội dung chuyển khoản khi nạp (QTV phát quà bằng server\grant.ps1).
## Màn chỉ gọi OnlineService; không chứa luật.

## Test gán service giả; null = autoload OnlineService.
var service: Node

var _url_edit: LineEdit
var _status: Label
var _profile_box: VBoxContainer
var _code_label: Label
var _wallet_label: Label
var _connect_btn: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if service == null:
		service = UiKit.autoload("OnlineService")
	_build()
	if service:
		service.state_changed.connect(func(_s: int) -> void: refresh_view())
		service.profile_changed.connect(func(_p: Dictionary) -> void: refresh_view())
	refresh_view()


## Bấm Kết nối: lưu địa chỉ rồi đăng nhập.
func connect_server() -> bool:
	if service == null:
		return false
	_url_edit.text = service.config.set_server_url(_url_edit.text)
	return await service.login()


func status_text() -> String:
	if service == null:
		return tr("ONLINE_ERR_NO_SERVICE")
	match service.state:
		service.State.CONNECTING:
			return tr("ONLINE_STATUS_CONNECTING")
		service.State.ONLINE:
			return tr("ONLINE_STATUS_ONLINE")
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
	_connect_btn.disabled = service == null or service.state == service.State.CONNECTING
	if online:
		_code_label.text = NakamaApi.format_code(str(service.profile.get("code", "")))
		_wallet_label.text = wallet_text()


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
	root.add_child(UiKit.label(tr("ONLINE_SERVER"), 30))
	var row := UiKit.hbox(12)
	_url_edit = LineEdit.new()
	_url_edit.name = "ServerUrl"
	_url_edit.text = service.config.server_url if service else ""
	_url_edit.placeholder_text = "https://....trycloudflare.com"
	_url_edit.custom_minimum_size = Vector2(0, 84)
	_url_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_url_edit.add_theme_font_size_override("font_size", 28)
	_url_edit.text_submitted.connect(func(_t: String) -> void: connect_server())
	row.add_child(_url_edit)
	_connect_btn = UiKit.button(tr("ONLINE_CONNECT"), 260.0, 30)
	_connect_btn.name = "ConnectButton"
	_connect_btn.custom_minimum_size.y = 84.0
	_connect_btn.pressed.connect(connect_server)
	row.add_child(_connect_btn)
	root.add_child(row)
	root.add_child(UiKit.label(tr("ONLINE_SERVER_HINT"), 22))
	_status = UiKit.label("", 28)
	_status.name = "Status"
	root.add_child(_status)

	_profile_box = UiKit.vbox(16)
	_profile_box.name = "Profile"
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
	var refresh := UiKit.button(tr("ONLINE_REFRESH"), 320.0, 30)
	refresh.name = "RefreshButton"
	refresh.custom_minimum_size.y = 84.0
	refresh.pressed.connect(func() -> void: service.refresh_profile())
	_profile_box.add_child(refresh)
	root.add_child(_profile_box)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var back := UiKit.button(tr("UI_BACK"), 320.0, 30)
	back.name = "BackButton"
	back.custom_minimum_size.y = 84.0
	back.pressed.connect(_go_back)
	root.add_child(back)
