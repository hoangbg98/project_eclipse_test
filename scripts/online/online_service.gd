extends Node
## Autoload `OnlineService` (M9-1): phiên đăng nhập Nakama và hồ sơ người chơi trên máy chủ (mã người chơi, ví).
## Không chứa luật gameplay. Giai đoạn 1: ví máy chủ chỉ để xem, chưa gộp với save trên máy.
##
## Tài khoản (màn Đăng nhập): đăng ký tên + email + mật khẩu, đăng nhập bằng tên hoặc email. "Ghi nhớ đăng nhập" lưu
## refresh token ở user://online_session.cfg để lần sau `resume()` tự vào. Đăng nhập bằng thiết bị (`login_device`)
## còn giữ cho công cụ kiểm tra (tools/online_e2e.gd).
## Mạng gửi qua `transport` (Callable(request: Dictionary) -> {code: int, body: String}); test thay bằng hàm giả.

signal state_changed(state: State)
signal profile_changed(profile: Dictionary)

enum State { OFFLINE, CONNECTING, ONLINE, ERROR }

const DEVICE_FILE := "user://online_device.cfg"
const SESSION_FILE := "user://online_session.cfg"
const PROFILE_RPC := "eclipse_profile"

var config: OnlineConfig
var state := State.OFFLINE
var last_error := ""
var token := ""
var refresh_token := ""
## {user_id, code, username, display_name, wallet: {gems, gold}, server_time}
var profile: Dictionary = {}
var device_file := DEVICE_FILE
var session_file := SESSION_FILE
var transport: Callable

## Cách đăng nhập của phiên hiện tại: "" | "account" | "device" (phiên hết hạn thì đăng nhập lại theo cách này).
var _mode := ""


func _ready() -> void:
	if config == null:
		config = OnlineConfig.load_from()
	if not transport.is_valid():
		transport = _http_send


func is_online() -> bool:
	return state == State.ONLINE


func username() -> String:
	return str(profile.get("username", ""))


# ---------- Tài khoản ----------

## Tạo tài khoản rồi vào luôn. Kiểm tra ô nhập trước khi gửi (lỗi ở `last_error`, là khóa dịch).
func register(user: String, email: String, password: String, confirm: String, remember := true) -> bool:
	var err := NakamaApi.username_error(user)
	if err.is_empty():
		err = NakamaApi.email_error(email)
	if err.is_empty():
		err = NakamaApi.password_error(password, confirm)
	if not err.is_empty():
		return _fail(err)
	return await _authenticate(NakamaApi.register_account(config.server_url, config.server_key, user,
			email.strip_edges(), password), "register", remember)


## Đăng nhập bằng tên đăng nhập hoặc email.
func login_account(name_or_email: String, password: String, remember := true) -> bool:
	if name_or_email.strip_edges().is_empty() or password.is_empty():
		return _fail("LOGIN_ERR_EMPTY")
	return await _authenticate(NakamaApi.login_account(config.server_url, config.server_key, name_or_email, password),
			"login", remember)


## Có phiên đã ghi nhớ không (màn Đăng nhập thử `resume()` khi mở).
func has_saved_session() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(session_file) == OK and not str(cfg.get_value("session", "refresh_token", "")).is_empty()


func saved_username() -> String:
	var cfg := ConfigFile.new()
	cfg.load(session_file)
	return str(cfg.get_value("session", "username", ""))


## Vào lại bằng phiên đã ghi nhớ. Hết hạn / bị thu hồi thì xóa phiên đã lưu, trả về false.
func resume() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(session_file) != OK:
		return false
	var rt := str(cfg.get_value("session", "refresh_token", ""))
	if rt.is_empty():
		return false
	if str(cfg.get_value("session", "server", "")) != config.server_url:
		_forget_session()   # phiên của máy chủ khác
		return false
	_set_state(State.CONNECTING)
	var res: Dictionary = await transport.call(NakamaApi.refresh_session(config.server_url, config.server_key, rt))
	var code := int(res.get("code", 0))
	var s := NakamaApi.parse_session(code, str(res.get("body", "")))
	if not s["ok"]:
		if code != 0:
			_forget_session()
		return _fail(_explain(code, s["error"], "resume"))
	token = s["token"]
	refresh_token = s["refresh_token"] if not s["refresh_token"].is_empty() else rt
	_mode = "account"
	if await refresh_profile(false):
		_remember_session()
		return true
	return false


## Đăng xuất: xóa phiên trong bộ nhớ và phiên đã ghi nhớ.
func logout() -> void:
	token = ""
	refresh_token = ""
	profile = {}
	last_error = ""
	_mode = ""
	_forget_session()
	_set_state(State.OFFLINE)


# ---------- Thiết bị (công cụ kiểm tra) ----------

## Mã thiết bị của bản cài này; chưa có thì tạo ngẫu nhiên (32 ký tự hex) và lưu lại.
func device_id() -> String:
	var cfg := ConfigFile.new()
	cfg.load(device_file)
	var id := str(cfg.get_value("device", "id", ""))
	if not NakamaApi.valid_device_id(id):
		id = Crypto.new().generate_random_bytes(16).hex_encode()
		cfg.set_value("device", "id", id)
		cfg.save(device_file)
	return id


func login_device() -> bool:
	_mode = "device"
	return await _authenticate(NakamaApi.authenticate_device(config.server_url, config.server_key, device_id()),
			"device", false)


# ---------- Hồ sơ ----------

## Lấy lại hồ sơ (ví) từ máy chủ. Phiên hết hạn (401) thì vào lại một lần theo cách đã đăng nhập.
func refresh_profile(retry := true) -> bool:
	if token.is_empty():
		return _fail("ONLINE_ERR_NOT_LOGGED_IN")
	_set_state(State.CONNECTING)
	var res: Dictionary = await transport.call(NakamaApi.rpc(config.server_url, token, PROFILE_RPC))
	var code := int(res.get("code", 0))
	if code == 401 and retry:
		token = ""
		if _mode == "device":
			return await login_device()
		if not refresh_token.is_empty():
			return await _refresh_in_memory()
		return _fail("ONLINE_ERR_SESSION_EXPIRED")
	var r := NakamaApi.parse_rpc(code, str(res.get("body", "")))
	if not r["ok"]:
		return _fail(_explain(code, r["error"], "rpc"))
	profile = r["data"]
	last_error = ""
	_set_state(State.ONLINE)
	profile_changed.emit(profile)
	return true


func wallet_amount(currency: String) -> int:
	var w: Variant = profile.get("wallet", {})
	return int(w.get(currency, 0)) if w is Dictionary else 0


# ---------- Nội bộ ----------

func _authenticate(req: Dictionary, action: String, remember: bool) -> bool:
	if config.server_url.is_empty():
		return _fail("ONLINE_ERR_NO_SERVER")
	_set_state(State.CONNECTING)
	var res: Dictionary = await transport.call(req)
	var code := int(res.get("code", 0))
	var s := NakamaApi.parse_session(code, str(res.get("body", "")))
	if not s["ok"]:
		token = ""
		return _fail(_explain(code, s["error"], action))
	token = s["token"]
	refresh_token = s["refresh_token"]
	if action != "device":
		_mode = "account"
	if not await refresh_profile(false):
		return false
	if remember:
		_remember_session()
	else:
		_forget_session()
	return true


## Phiên trong bộ nhớ hết hạn khi đang chơi: đổi refresh token lấy phiên mới.
func _refresh_in_memory() -> bool:
	var res: Dictionary = await transport.call(
			NakamaApi.refresh_session(config.server_url, config.server_key, refresh_token))
	var s := NakamaApi.parse_session(int(res.get("code", 0)), str(res.get("body", "")))
	if not s["ok"]:
		refresh_token = ""
		return _fail("ONLINE_ERR_SESSION_EXPIRED")
	token = s["token"]
	if not s["refresh_token"].is_empty():
		refresh_token = s["refresh_token"]
	return await refresh_profile(false)


func _remember_session() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("session", "refresh_token", refresh_token)
	cfg.set_value("session", "username", username())
	cfg.set_value("session", "server", config.server_url)
	cfg.save(session_file)


func _forget_session() -> void:
	if FileAccess.file_exists(session_file):
		DirAccess.remove_absolute(session_file)


func _fail(message: String) -> bool:
	last_error = message
	_set_state(State.ERROR)
	return false


## Mã lỗi HTTP → khóa dịch dễ hiểu theo việc đang làm; còn lại giữ câu lỗi của máy chủ.
func _explain(code: int, error: String, action: String) -> String:
	if code == 0:
		return "ONLINE_ERR_UNREACHABLE"
	if error.contains("Server key"):
		return "ONLINE_ERR_AUTH"
	match action:
		"login":
			if code == 400 or code == 401 or code == 404:   # 400: mật khẩu ngắn hơn 8 (Nakama kiểm cả khi đăng nhập)
				return "LOGIN_ERR_BAD_CREDENTIALS"
		"register":
			if code == 409:
				return "LOGIN_ERR_USERNAME_TAKEN"
			if code == 401:
				return "LOGIN_ERR_EMAIL_TAKEN"
		"resume":
			if code == 401:
				return "ONLINE_ERR_SESSION_EXPIRED"
	if code == 401:
		return "ONLINE_ERR_AUTH"
	return error


func _set_state(s: State) -> void:
	if state == s:
		return
	state = s
	state_changed.emit(s)


func _http_send(req: Dictionary) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = config.timeout_sec
	add_child(http)
	var err := http.request(req["url"], req["headers"], req["method"], req["body"])
	if err != OK:
		http.queue_free()
		return {"code": 0, "body": ""}
	var out: Array = await http.request_completed
	http.queue_free()
	var result: int = out[0]
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"code": 0, "body": ""}
	return {"code": int(out[1]), "body": (out[3] as PackedByteArray).get_string_from_utf8()}
