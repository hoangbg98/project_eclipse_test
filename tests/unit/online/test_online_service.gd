extends GdUnitTestSuite
## Test OnlineService + OnlineConfig + màn Trực tuyến (M9-1) với máy chủ giả (không dùng mạng).

const SERVICE_SCRIPT := preload("res://scripts/online/online_service.gd")
const SCREEN_SCENE := preload("res://scenes/main/online_screen.tscn")
const DEVICE_FILE := "user://test_online_device.cfg"
const USER_CFG := "user://test_online.cfg"

## Các request đã gửi tới máy chủ giả.
var _sent: Array = []
## Lần gọi RPC hồ sơ đầu tiên trả 401 (phiên hết hạn) khi true.
var _expire_once := false
var _down := false


func before_test() -> void:
	_sent = []
	_expire_once = false
	_down = false
	DirAccess.remove_absolute(DEVICE_FILE)
	DirAccess.remove_absolute(USER_CFG)


func after_test() -> void:
	DirAccess.remove_absolute(DEVICE_FILE)
	DirAccess.remove_absolute(USER_CFG)


func _fake_server(req: Dictionary) -> Dictionary:
	_sent.append(req)
	if _down:
		return {"code": 0, "body": ""}
	var url: String = req["url"]
	if url.contains("/authenticate/device"):
		var key_ok := (req["headers"] as PackedStringArray).has("Authorization: " + NakamaApi.basic_auth("k"))
		if not key_ok:
			return {"code": 401, "body": '{"message":"Server key invalid"}'}
		return {"code": 200, "body": '{"created":true,"token":"T1","refresh_token":"R1"}'}
	if url.ends_with("/v2/rpc/eclipse_profile"):
		if _expire_once:
			_expire_once = false
			return {"code": 401, "body": '{"message":"Auth token invalid"}'}
		var profile := {"code": "32354120", "username": "abc", "wallet": {"gems": 600}}
		return {"code": 200, "body": JSON.stringify({"payload": JSON.stringify(profile)})}
	return {"code": 404, "body": ""}


func _make_service(key := "k") -> Node:
	var s: Node = auto_free(SERVICE_SCRIPT.new())
	s.config = OnlineConfig.load_from(OnlineConfig.DATA_PATH, USER_CFG)
	s.config.server_key = key
	s.device_file = DEVICE_FILE
	s.transport = _fake_server
	add_child(s)
	return s


func test_config_reads_data_and_saves_user_url() -> void:
	var c := OnlineConfig.load_from(OnlineConfig.DATA_PATH, USER_CFG)
	assert_str(c.server_url).is_equal("http://127.0.0.1:7350")
	assert_str(c.server_key).is_not_empty()
	assert_str(c.set_server_url("abc.trycloudflare.com/")).is_equal("https://abc.trycloudflare.com")
	assert_str(OnlineConfig.load_from(OnlineConfig.DATA_PATH, USER_CFG).server_url).is_equal("https://abc.trycloudflare.com")
	c.set_server_url("")
	assert_str(OnlineConfig.load_from(OnlineConfig.DATA_PATH, USER_CFG).server_url).is_equal(c.default_server_url)


func test_device_id_is_stable() -> void:
	var s := _make_service()
	var a: String = s.device_id()
	assert_int(a.length()).is_equal(32)
	assert_str(s.device_id()).is_equal(a)


func test_login_loads_profile() -> void:
	var s := _make_service()
	var ok: bool = await s.login()
	assert_bool(ok).is_true()
	assert_bool(s.is_online()).is_true()
	assert_str(s.profile["code"]).is_equal("32354120")
	assert_int(s.wallet_amount("gems")).is_equal(600)
	assert_int(s.wallet_amount("gold")).is_equal(0)
	assert_int(_sent.size()).is_equal(2)


func test_wrong_key_and_unreachable_errors() -> void:
	var s := _make_service("wrong")
	assert_bool(await s.login()).is_false()
	assert_int(s.state).is_equal(s.State.ERROR)
	assert_str(s.last_error).is_equal("ONLINE_ERR_AUTH")
	var s2 := _make_service()
	_down = true
	assert_bool(await s2.login()).is_false()
	assert_str(s2.last_error).is_equal("ONLINE_ERR_UNREACHABLE")


func test_expired_token_relogs_once() -> void:
	var s := _make_service()
	assert_bool(await s.login()).is_true()
	_expire_once = true
	_sent.clear()
	assert_bool(await s.refresh_profile()).is_true()
	# RPC 401 → đăng nhập lại → RPC
	assert_int(_sent.size()).is_equal(3)


func test_online_screen_shows_code_and_wallet() -> void:
	var s := _make_service()
	var screen: Control = SCREEN_SCENE.instantiate()
	screen.service = s
	add_child(screen)
	auto_free(screen)
	var profile_box: Control = screen.find_child("Profile", true, false)
	assert_bool(profile_box.visible).is_false()
	(screen.find_child("ServerUrl", true, false) as LineEdit).text = "127.0.0.1:7350"
	assert_bool(await screen.connect_server()).is_true()
	assert_bool(profile_box.visible).is_true()
	assert_str((screen.find_child("Code", true, false) as Label).text).is_equal("3235 4120")
	assert_str((screen.find_child("Wallet", true, false) as Label).text).contains("600")
	assert_str((screen.find_child("ServerUrl", true, false) as LineEdit).text).is_equal("http://127.0.0.1:7350")
