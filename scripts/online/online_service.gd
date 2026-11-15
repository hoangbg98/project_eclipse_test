extends Node
## Autoload `OnlineService` (M9-1): giữ phiên đăng nhập Nakama và hồ sơ người chơi trên máy chủ (mã người chơi, ví).
## Không chứa luật gameplay. Giai đoạn 1: ví máy chủ chỉ để xem, chưa gộp với save trên máy.
##
## Đăng nhập bằng mã thiết bị ngẫu nhiên lưu ở user://online_device.cfg (mỗi bản cài một tài khoản).
## Mạng gửi qua `transport` (Callable(request: Dictionary) -> {code: int, body: String}); test thay bằng hàm giả.

signal state_changed(state: State)
signal profile_changed(profile: Dictionary)

enum State { OFFLINE, CONNECTING, ONLINE, ERROR }

const DEVICE_FILE := "user://online_device.cfg"
const PROFILE_RPC := "eclipse_profile"

var config: OnlineConfig
var state := State.OFFLINE
var last_error := ""
var token := ""
## {user_id, code, username, display_name, wallet: {gems, gold}, server_time}
var profile: Dictionary = {}
var device_file := DEVICE_FILE
var transport: Callable


func _ready() -> void:
	if config == null:
		config = OnlineConfig.load_from()
	if not transport.is_valid():
		transport = _http_send


func is_online() -> bool:
	return state == State.ONLINE


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


## Đăng nhập rồi lấy hồ sơ. Trả về true nếu thành công; lỗi ở `last_error`.
func login() -> bool:
	if config.server_url.is_empty():
		return _fail("ONLINE_ERR_NO_SERVER")
	_set_state(State.CONNECTING)
	var res: Dictionary = await transport.call(
			NakamaApi.authenticate_device(config.server_url, config.server_key, device_id()))
	var s := NakamaApi.parse_session(int(res.get("code", 0)), str(res.get("body", "")))
	if not s["ok"]:
		token = ""
		return _fail(_explain(int(res.get("code", 0)), s["error"]))
	token = s["token"]
	return await refresh_profile()


## Lấy lại hồ sơ (ví) từ máy chủ. Phiên hết hạn (401) thì đăng nhập lại một lần.
func refresh_profile(retry := true) -> bool:
	if token.is_empty():
		return await login()
	_set_state(State.CONNECTING)
	var res: Dictionary = await transport.call(NakamaApi.rpc(config.server_url, token, PROFILE_RPC))
	var code := int(res.get("code", 0))
	if code == 401 and retry:
		token = ""
		return await login()
	var r := NakamaApi.parse_rpc(code, str(res.get("body", "")))
	if not r["ok"]:
		return _fail(_explain(code, r["error"]))
	profile = r["data"]
	last_error = ""
	_set_state(State.ONLINE)
	profile_changed.emit(profile)
	return true


func logout() -> void:
	token = ""
	profile = {}
	last_error = ""
	_set_state(State.OFFLINE)


func wallet_amount(currency: String) -> int:
	var w: Variant = profile.get("wallet", {})
	return int(w.get(currency, 0)) if w is Dictionary else 0


func _fail(message: String) -> bool:
	last_error = message
	_set_state(State.ERROR)
	return false


## Lỗi mạng (code 0) → khóa dịch dễ hiểu; còn lại giữ câu lỗi của máy chủ.
func _explain(code: int, error: String) -> String:
	if code == 0:
		return "ONLINE_ERR_UNREACHABLE"
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
