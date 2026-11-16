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


## Chat (M9-6): tạo sẵn khi vào cây; tự kết nối sau khi mở thế giới của tài khoản (`open_cloud_world`).
var chat: ChatService
## false: không tự kết nối chat (test).
var chat_auto_start := true


func _ready() -> void:
	if config == null:
		config = OnlineConfig.load_from()
	if not transport.is_valid():
		transport = _http_send
	chat = ChatService.new()
	chat.name = "Chat"
	chat.online = self
	add_child(chat)


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
	if chat:
		chat.stop()
	_detach_cloud()
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


func user_id() -> String:
	return str(profile.get("user_id", ""))


# ---------- Cloud save (M9-3) ----------
# Sau khi đăng nhập, `open_cloud_world()` chọn thế giới của tài khoản (CloudSave.decide) và chuyển SaveService sang
# bản đệm của tài khoản. Từ đó mỗi lần SaveService.saved, save được gửi lên (gom trong `push_delay` giây).
# Gửi lỗi mạng → PENDING, thử lại mỗi `RETRY_SEC` và ở lần lưu sau. Máy chủ báo bản đã đổi từ thiết bị khác → CONFLICT,
# ngừng gửi (không ghi đè); đăng nhập lại sẽ lấy bản trên máy chủ.

signal cloud_state_changed(state: Cloud)

enum Cloud { OFF, SYNCING, SYNCED, PENDING, CONFLICT, ERROR }

const SAVE_GET_RPC := "save_get"
const SAVE_PUT_RPC := "save_put"
const PUSH_DELAY := 2.0
const RETRY_SEC := 30.0

var cloud_state := Cloud.OFF
var cloud_error := ""
## Thời điểm (unix) gửi lên thành công gần nhất.
var cloud_synced_at := 0
var cloud_root := CloudSave.ROOT_DIR
## SaveService (test gán bản riêng); null = autoload.
var save_service: Node
var push_delay := PUSH_DELAY

var _cloud_dir := ""
var _pushing := false
var _push_again := false
var _push_timer: Timer
var _retry_timer: Timer


## Mở thế giới của tài khoản vừa đăng nhập. Trả về "ok", "ask" (máy chủ chưa có save mà máy này có save ngoại tuyến:
## gọi lại với import_offline = true để mang lên, false để bắt đầu mới) hoặc "error" (`cloud_error` là khóa dịch).
func open_cloud_world(import_offline: Variant = null) -> String:
	var saves := _saves()
	if saves == null or user_id().is_empty():
		cloud_error = "CLOUD_ERR_NOT_READY"
		return "error"
	_cloud_set(Cloud.SYNCING)
	var dir := CloudSave.dir_for(user_id(), cloud_root)
	var local := SaveStore.new(dir)
	var meta := CloudSave.read_meta(dir)
	var got := await _call_rpc(SAVE_GET_RPC, {})
	if not got["ok"]:
		cloud_error = got["error"]
		_cloud_set(Cloud.ERROR)
		return "error"
	var data: Dictionary = got["data"]
	var cloud_version := str(data.get("version", "")) if data.get("exists", false) else ""
	var offline: SaveStore = saves.offline_store()
	var action := CloudSave.decide(cloud_version, local.has_save(), meta, offline.has_save())
	var push := false
	match action:
		CloudSave.Action.ASK_IMPORT:
			if import_offline == null:
				_cloud_set(Cloud.OFF)
				return "ask"
			CloudSave.write_meta(dir, "", false)
			if import_offline:
				local.import_envelope(SaveStore.envelope_of(offline.read()))
				push = true
		CloudSave.Action.USE_CLOUD:
			var env: Variant = data.get("envelope")
			if not (env is Dictionary) or local.import_envelope(env) != OK:
				cloud_error = "CLOUD_ERR_NEWER" if local.last_import_newer else "CLOUD_ERR_BAD_DATA"
				_cloud_set(Cloud.ERROR)
				return "error"
			CloudSave.write_meta(dir, cloud_version, false)
		CloudSave.Action.PUSH_LOCAL:
			CloudSave.write_meta(dir, cloud_version, true)
			push = true
		CloudSave.Action.NEW_WORLD:
			CloudSave.write_meta(dir, "", false)
	_attach_cloud(dir)
	if push:
		await push_now()
	else:
		cloud_error = ""
		_cloud_set(Cloud.SYNCED)
	if chat_auto_start and chat:
		chat.start()
	return "ok"


## Gửi save hiện tại lên ngay (không chờ gom). Đang gửi thì gửi thêm một lần sau khi xong.
func push_now() -> bool:
	if _cloud_dir.is_empty() or cloud_state == Cloud.CONFLICT:
		return false
	if _pushing:
		_push_again = true
		return false
	_pushing = true
	var meta := CloudSave.read_meta(_cloud_dir)
	CloudSave.write_meta(_cloud_dir, meta["version"], true)
	_cloud_set(Cloud.SYNCING)
	var r := await _call_rpc(SAVE_PUT_RPC, {"envelope": SaveStore.envelope_of(_saves().data), "base_version": meta["version"]})
	var ok: bool = r["ok"]
	if ok:
		CloudSave.write_meta(_cloud_dir, str(r["data"].get("version", "")), false)
		cloud_synced_at = int(Time.get_unix_time_from_system())
		cloud_error = ""
		_cloud_set(Cloud.SYNCED)
	elif str(r["error"]).contains("save_conflict"):
		cloud_error = "CLOUD_ERR_CONFLICT"
		_cloud_set(Cloud.CONFLICT)
	else:
		cloud_error = r["error"]
		_cloud_set(Cloud.PENDING)
		_retry_timer.start(RETRY_SEC)
	_pushing = false
	if _push_again and cloud_state != Cloud.CONFLICT:
		_push_again = false
		return await push_now()
	return ok


func _saves() -> Node:
	if save_service == null:
		save_service = get_tree().root.get_node_or_null("SaveService") if is_inside_tree() else null
	return save_service


func _attach_cloud(dir: String) -> void:
	_cloud_dir = dir
	var saves := _saves()
	saves.use_store(SaveStore.new(dir))
	if not saves.saved.is_connected(_on_saved):
		saves.saved.connect(_on_saved)
	if _push_timer == null:
		_push_timer = Timer.new()
		_push_timer.one_shot = true
		_push_timer.timeout.connect(push_now)
		add_child(_push_timer)
		_retry_timer = Timer.new()
		_retry_timer.one_shot = true
		_retry_timer.timeout.connect(func() -> void:
			if cloud_state == Cloud.PENDING:
				push_now())
		add_child(_retry_timer)


## Thoát thế giới tài khoản: SaveService về save ngoại tuyến. Tiến độ chưa gửi vẫn ở bản đệm (dirty), gửi ở lần sau.
func _detach_cloud() -> void:
	if _cloud_dir.is_empty():
		return
	if _push_timer:
		_push_timer.stop()
		_retry_timer.stop()
	var saves := _saves()
	if saves.saved.is_connected(_on_saved):
		saves.saved.disconnect(_on_saved)
	_cloud_dir = ""
	saves.use_store(saves.offline_store())
	_cloud_set(Cloud.OFF)


func _on_saved() -> void:
	if _cloud_dir.is_empty() or cloud_state == Cloud.CONFLICT:
		return
	CloudSave.write_meta(_cloud_dir, CloudSave.read_meta(_cloud_dir)["version"], true)
	if push_delay <= 0.0:
		push_now.call_deferred()
	else:
		_push_timer.start(push_delay)


func _cloud_set(s: Cloud) -> void:
	if cloud_state == s:
		return
	cloud_state = s
	cloud_state_changed.emit(s)


## Gọi RPC có token; 401 (phiên hết hạn) thì làm mới phiên một lần rồi gọi lại. {ok, code, data, error}.
func _call_rpc(rpc_id: String, payload: Dictionary, retry := true) -> Dictionary:
	if token.is_empty():
		return {"ok": false, "code": 401, "data": {}, "error": "ONLINE_ERR_NOT_LOGGED_IN"}
	var res: Dictionary = await transport.call(NakamaApi.rpc(config.server_url, token, rpc_id, payload))
	var code := int(res.get("code", 0))
	if code == 401 and retry and await _renew_token():
		return await _call_rpc(rpc_id, payload, false)
	var r := NakamaApi.parse_rpc(code, str(res.get("body", "")))
	r["code"] = code
	if not r["ok"]:
		r["error"] = "ONLINE_ERR_UNREACHABLE" if code == 0 else r["error"]
	return r


## Token còn dùng được: sắp hết hạn (dưới 2 phút) thì làm mới trước. Rỗng nếu chưa đăng nhập.
func fresh_token() -> String:
	if token.is_empty():
		return ""
	var exp := NakamaApi.token_expiry(token)
	if exp > 0 and exp - int(Time.get_unix_time_from_system()) < 120:
		await _renew_token()
	return token


## Gọi một API REST có token. `make.call(server_url, token)` dựng request; gặp 401 thì làm mới phiên và gọi lại một lần.
## Trả về {code, body}.
func call_api(make: Callable) -> Dictionary:
	if token.is_empty():
		return {"code": 401, "body": ""}
	var res: Dictionary = await transport.call(make.call(config.server_url, await fresh_token()))
	if int(res.get("code", 0)) == 401 and await _renew_token():
		res = await transport.call(make.call(config.server_url, token))
	return res


## Gọi RPC của module máy chủ: {ok, code, data, error}.
func call_rpc(rpc_id: String, payload: Dictionary) -> Dictionary:
	return await _call_rpc(rpc_id, payload)


## Chỉ làm mới token (không đổi trạng thái / hồ sơ).
func _renew_token() -> bool:
	var req: Dictionary
	if _mode == "device":
		req = NakamaApi.authenticate_device(config.server_url, config.server_key, device_id())
	elif not refresh_token.is_empty():
		req = NakamaApi.refresh_session(config.server_url, config.server_key, refresh_token)
	else:
		return false
	var res: Dictionary = await transport.call(req)
	var s := NakamaApi.parse_session(int(res.get("code", 0)), str(res.get("body", "")))
	if not s["ok"]:
		return false
	token = s["token"]
	if not s["refresh_token"].is_empty():
		refresh_token = s["refresh_token"]
	return true


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
