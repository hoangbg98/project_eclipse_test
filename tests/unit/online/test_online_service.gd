extends GdUnitTestSuite
## Test OnlineService + OnlineConfig + màn Đăng nhập + màn Tài khoản (M9-1) với máy chủ giả (không dùng mạng).
## Máy chủ giả mô phỏng Nakama: đăng ký email (+ tên), đăng nhập bằng tên hoặc email, làm mới phiên, RPC hồ sơ.

const SERVICE_SCRIPT := preload("res://scripts/online/online_service.gd")
const LOGIN_SCENE := preload("res://scenes/main/login_screen.tscn")
const ONLINE_SCENE := preload("res://scenes/main/online_screen.tscn")
const DEVICE_FILE := "user://test_online_device.cfg"
const SESSION_FILE := "user://test_online_session.cfg"
const USER_CFG := "user://test_online.cfg"

var _sent: Array = []
var _down := false
var _expire_once := false
## Tài khoản trên máy chủ giả: username -> {email, password, code}
var _accounts := {}


func before_test() -> void:
	_sent = []
	_down = false
	_expire_once = false
	_accounts = {"tester1": {"email": "t1@example.com", "password": "matkhau123", "code": "32354120"}}
	for f in [DEVICE_FILE, SESSION_FILE, USER_CFG]:
		DirAccess.remove_absolute(f)


func after_test() -> void:
	for f in [DEVICE_FILE, SESSION_FILE, USER_CFG]:
		DirAccess.remove_absolute(f)


func _session(user: String, created := false) -> Dictionary:
	return {"code": 200, "body": JSON.stringify({"created": created, "token": "T:" + user, "refresh_token": "R:" + user})}


func _fake_server(req: Dictionary) -> Dictionary:
	_sent.append(req)
	if _down:
		return {"code": 0, "body": ""}
	var url: String = req["url"]
	var headers: PackedStringArray = req["headers"]
	var body: Variant = JSON.parse_string(req["body"])
	if url.contains("/authenticate/") or url.ends_with("/session/refresh"):
		if not headers.has("Authorization: " + NakamaApi.basic_auth("k")):
			return {"code": 401, "body": '{"message":"Server key invalid"}'}
	if url.contains("/authenticate/device"):
		return _session("device", true)
	if url.contains("/authenticate/email"):
		var q := url.split("?")[1]
		var create := q.contains("create=true")
		var user := ""
		for part in q.split("&"):
			if part.begins_with("username="):
				user = part.trim_prefix("username=").uri_decode()
		if create:
			if _accounts.has(user):
				return {"code": 409, "body": '{"message":"Username is already in use."}'}
			_accounts[user] = {"email": body["email"], "password": body["password"], "code": "11112222"}
			return _session(user, true)
		if user.is_empty():
			for u in _accounts:
				if _accounts[u]["email"] == body.get("email", ""):
					user = u
		if not _accounts.has(user):
			return {"code": 404, "body": '{"message":"User account not found."}'}
		if str(body["password"]).length() < 8:
			return {"code": 400, "body": '{"message":"Password must be at least 8 characters long."}'}
		if _accounts[user]["password"] != body["password"]:
			return {"code": 401, "body": '{"message":"Invalid credentials."}'}
		return _session(user)
	if url.ends_with("/session/refresh"):
		var rt := str(body["token"])
		if not rt.begins_with("R:"):
			return {"code": 401, "body": '{"message":"Refresh token invalid or expired."}'}
		return _session(rt.trim_prefix("R:"))
	if url.ends_with("/v2/rpc/eclipse_profile"):
		if _expire_once:
			_expire_once = false
			return {"code": 401, "body": '{"message":"Auth token invalid"}'}
		var user := ""
		for h in headers:
			if h.begins_with("Authorization: Bearer T:"):
				user = h.trim_prefix("Authorization: Bearer T:")
		var code: String = _accounts[user]["code"] if _accounts.has(user) else "55009391"
		var profile := {"code": code, "username": user, "wallet": {"gems": 600}}
		return {"code": 200, "body": JSON.stringify({"payload": JSON.stringify(profile)})}
	return {"code": 404, "body": ""}


func _make_service(key := "k") -> Node:
	var s: Node = auto_free(SERVICE_SCRIPT.new())
	s.config = OnlineConfig.load_from(OnlineConfig.DATA_PATH, USER_CFG)
	s.config.server_key = key
	s.device_file = DEVICE_FILE
	s.session_file = SESSION_FILE
	s.transport = _fake_server
	add_child(s)
	return s


func test_config_reads_data_and_saves_user_url() -> void:
	var c := OnlineConfig.load_from(OnlineConfig.DATA_PATH, USER_CFG)
	assert_str(c.server_url).is_equal("http://127.0.0.1:7350")
	assert_str(c.server_key).is_not_empty()
	assert_bool(c.login_on_start).is_true()
	assert_str(c.set_server_url("abc.trycloudflare.com/")).is_equal("https://abc.trycloudflare.com")
	assert_str(OnlineConfig.load_from(OnlineConfig.DATA_PATH, USER_CFG).server_url).is_equal("https://abc.trycloudflare.com")
	c.set_server_url("")
	assert_str(OnlineConfig.load_from(OnlineConfig.DATA_PATH, USER_CFG).server_url).is_equal(c.default_server_url)


func test_register_validates_before_sending() -> void:
	var s := _make_service()
	assert_bool(await s.register("a b", "x@example.com", "matkhau123", "matkhau123")).is_false()
	assert_str(s.last_error).is_equal("LOGIN_ERR_USERNAME")
	assert_bool(await s.register("newbie", "khong-phai-email", "matkhau123", "matkhau123")).is_false()
	assert_str(s.last_error).is_equal("LOGIN_ERR_EMAIL")
	assert_bool(await s.register("newbie", "n@example.com", "1234567", "1234567")).is_false()
	assert_str(s.last_error).is_equal("LOGIN_ERR_PASSWORD_SHORT")
	assert_bool(await s.register("newbie", "n@example.com", "matkhau123", "matkhau124")).is_false()
	assert_str(s.last_error).is_equal("LOGIN_ERR_PASSWORD_MISMATCH")
	assert_int(_sent.size()).is_equal(0)


func test_register_then_login_by_name_and_email() -> void:
	var s := _make_service()
	assert_bool(await s.register("newbie", "n@example.com", "matkhau123", "matkhau123")).is_true()
	assert_bool(s.is_online()).is_true()
	assert_str(s.username()).is_equal("newbie")
	assert_str(s.profile["code"]).is_equal("11112222")
	assert_str(_sent[0]["url"]).contains("create=true&username=newbie")
	s.logout()
	assert_bool(s.is_online()).is_false()
	assert_bool(await s.login_account("newbie", "matkhau123")).is_true()
	s.logout()
	assert_bool(await s.login_account("n@example.com", "matkhau123")).is_true()
	assert_str(s.username()).is_equal("newbie")


func test_login_and_register_errors() -> void:
	var s := _make_service()
	assert_bool(await s.login_account("tester1", "sai_mat_khau")).is_false()
	assert_str(s.last_error).is_equal("LOGIN_ERR_BAD_CREDENTIALS")
	assert_bool(await s.login_account("tester1", "sai")).is_false()
	assert_str(s.last_error).is_equal("LOGIN_ERR_BAD_CREDENTIALS")
	assert_bool(await s.login_account("khongco", "matkhau123")).is_false()
	assert_str(s.last_error).is_equal("LOGIN_ERR_BAD_CREDENTIALS")
	assert_bool(await s.login_account("", "")).is_false()
	assert_str(s.last_error).is_equal("LOGIN_ERR_EMPTY")
	assert_bool(await s.register("tester1", "z@example.com", "matkhau123", "matkhau123")).is_false()
	assert_str(s.last_error).is_equal("LOGIN_ERR_USERNAME_TAKEN")
	var wrong := _make_service("sai")
	assert_bool(await wrong.login_account("tester1", "matkhau123")).is_false()
	assert_str(wrong.last_error).is_equal("ONLINE_ERR_AUTH")
	_down = true
	assert_bool(await s.login_account("tester1", "matkhau123")).is_false()
	assert_str(s.last_error).is_equal("ONLINE_ERR_UNREACHABLE")


func test_remember_resume_and_logout() -> void:
	var s := _make_service()
	assert_bool(await s.login_account("tester1", "matkhau123", true)).is_true()
	assert_bool(s.has_saved_session()).is_true()
	assert_str(s.saved_username()).is_equal("tester1")
	# lần mở game sau: service mới, vào lại bằng refresh token
	var s2 := _make_service()
	assert_bool(await s2.resume()).is_true()
	assert_str(s2.username()).is_equal("tester1")
	assert_str((_sent[-2]["url"] as String)).ends_with("/v2/account/session/refresh")
	s2.logout()
	assert_bool(s2.has_saved_session()).is_false()
	# không ghi nhớ thì không lưu phiên
	assert_bool(await s.login_account("tester1", "matkhau123", false)).is_true()
	assert_bool(s.has_saved_session()).is_false()


func test_resume_other_server_is_dropped() -> void:
	var s := _make_service()
	assert_bool(await s.login_account("tester1", "matkhau123", true)).is_true()
	var s2 := _make_service()
	s2.config.server_url = "https://khac.trycloudflare.com"
	assert_bool(await s2.resume()).is_false()
	assert_bool(s2.has_saved_session()).is_false()


func test_expired_token_refreshes_in_memory() -> void:
	var s := _make_service()
	assert_bool(await s.login_account("tester1", "matkhau123", false)).is_true()
	_expire_once = true
	_sent.clear()
	assert_bool(await s.refresh_profile()).is_true()
	# RPC 401 → refresh → RPC
	assert_int(_sent.size()).is_equal(3)
	assert_str(_sent[1]["url"]).ends_with("/v2/account/session/refresh")


func test_device_login_still_works() -> void:
	var s := _make_service()
	var a: String = s.device_id()
	assert_int(a.length()).is_equal(32)
	assert_str(s.device_id()).is_equal(a)
	assert_bool(await s.login_device()).is_true()
	assert_int(s.wallet_amount("gems")).is_equal(600)
	assert_int(s.wallet_amount("gold")).is_equal(0)


func _make_login(s: Node) -> Control:
	var screen: Control = LOGIN_SCENE.instantiate()
	screen.service = s
	screen.navigate = false
	add_child(screen)
	auto_free(screen)
	return screen


func test_login_screen_register_and_login() -> void:
	var s := _make_service()
	var screen := _make_login(s)
	assert_bool((screen.find_child("TabLogin", true, false) as Button).button_pressed).is_true()
	screen.set_mode(LoginScreen.Mode.REGISTER)
	screen.field("reg_name").text = "newbie"
	screen.field("reg_email").text = "n@example.com"
	screen.field("reg_password").text = "matkhau123"
	screen.field("reg_confirm").text = "khac"
	assert_bool(await screen.submit()).is_false()
	assert_str(screen.status_text()).is_equal(tr("LOGIN_ERR_PASSWORD_MISMATCH"))
	assert_int(screen.entered).is_equal(0)
	screen.field("reg_confirm").text = "matkhau123"
	assert_bool(await screen.submit()).is_true()
	assert_int(screen.entered).is_equal(1)
	s.logout()
	screen.set_mode(LoginScreen.Mode.LOGIN)
	screen.field("login_name").text = "newbie"
	screen.field("login_password").text = "matkhau123"
	assert_bool(await screen.submit()).is_true()
	assert_int(screen.entered).is_equal(2)


func test_login_screen_resumes_saved_session_and_offline() -> void:
	var s := _make_service()
	assert_bool(await s.login_account("tester1", "matkhau123", true)).is_true()
	var s2 := _make_service()
	var screen := _make_login(s2)
	await await_millis(50)
	assert_int(screen.entered).is_equal(1)
	assert_bool(s2.is_online()).is_true()
	var s3 := _make_service()
	s3.logout()
	var screen2 := _make_login(s3)
	screen2.play_offline()
	assert_int(screen2.entered).is_equal(1)
	assert_bool(s3.is_online()).is_false()


func test_login_screen_changes_server() -> void:
	var s := _make_service()
	var screen := _make_login(s)
	screen.apply_server("abc.trycloudflare.com")
	assert_str(s.config.server_url).is_equal("https://abc.trycloudflare.com")
	assert_str((screen.find_child("ServerLabel", true, false) as Label).text).contains("abc.trycloudflare.com")


func test_online_screen_shows_account_code_and_wallet() -> void:
	var s := _make_service()
	var screen: Control = ONLINE_SCENE.instantiate()
	screen.service = s
	add_child(screen)
	auto_free(screen)
	var profile_box: Control = screen.find_child("Profile", true, false)
	assert_bool(profile_box.visible).is_false()
	assert_bool((screen.find_child("LoginButton", true, false) as Control).visible).is_true()
	assert_bool(await s.login_account("tester1", "matkhau123", false)).is_true()
	assert_bool(profile_box.visible).is_true()
	assert_str((screen.find_child("Account", true, false) as Label).text).contains("tester1")
	assert_str((screen.find_child("Code", true, false) as Label).text).is_equal("3235 4120")
	assert_str((screen.find_child("Wallet", true, false) as Label).text).contains("600")
