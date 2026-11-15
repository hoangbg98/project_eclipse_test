class_name NakamaApi
extends RefCounted
## Dựng request REST tới Nakama và đọc kết quả (M9-1). Chỉ là hàm thuần: không gửi mạng, không giữ trạng thái,
## để test được. OnlineService gửi request này qua HTTPRequest.
##
## Request là Dictionary {method, url, headers: PackedStringArray, body: String}.
## Kết quả đọc là Dictionary {ok: bool, error: String, ...}.

const DEVICE_ID_MIN := 10
const DEVICE_ID_MAX := 128


## Địa chỉ máy chủ người dùng gõ → dạng chuẩn: bỏ khoảng trắng và "/" cuối; thiếu giao thức thì thêm
## http:// cho máy nội bộ (localhost, 127.x, 192.168.x, 10.x) và https:// cho tên miền (vd trycloudflare.com).
static func normalize_url(raw: String) -> String:
	var s := raw.strip_edges()
	while s.ends_with("/"):
		s = s.substr(0, s.length() - 1)
	if s.is_empty():
		return ""
	if s.contains("://"):
		return s
	var host := s.split("/")[0].split(":")[0]
	var local := host == "localhost" or host.begins_with("127.") or host.begins_with("192.168.") \
			or host.begins_with("10.") or host.ends_with(".local")
	return ("http://" if local else "https://") + s


static func basic_auth(server_key: String) -> String:
	return "Basic " + Marshalls.utf8_to_base64(server_key + ":")


static func valid_device_id(device_id: String) -> bool:
	return device_id.length() >= DEVICE_ID_MIN and device_id.length() <= DEVICE_ID_MAX


## Đăng nhập bằng mã thiết bị (tạo tài khoản nếu chưa có).
static func authenticate_device(server_url: String, server_key: String, device_id: String) -> Dictionary:
	return {
		"method": HTTPClient.METHOD_POST,
		"url": server_url + "/v2/account/authenticate/device?create=true",
		"headers": PackedStringArray(["Authorization: " + basic_auth(server_key), "Content-Type: application/json"]),
		"body": JSON.stringify({"id": device_id}),
	}


## Tạo tài khoản: tên đăng nhập + email + mật khẩu (M9-1b). Email đã có và đúng mật khẩu thì Nakama đăng nhập luôn.
static func register_account(server_url: String, server_key: String, username: String, email: String,
		password: String) -> Dictionary:
	return _email_auth(server_url, server_key, "?create=true&username=" + username.uri_encode(),
			{"email": email, "password": password})


## Đăng nhập bằng tên đăng nhập hoặc email (có "@" thì coi là email).
static func login_account(server_url: String, server_key: String, name_or_email: String, password: String) -> Dictionary:
	var s := name_or_email.strip_edges()
	if s.contains("@"):
		return _email_auth(server_url, server_key, "?create=false", {"email": s, "password": password})
	return _email_auth(server_url, server_key, "?create=false&username=" + s.uri_encode(), {"password": password})


static func _email_auth(server_url: String, server_key: String, query: String, body: Dictionary) -> Dictionary:
	return {
		"method": HTTPClient.METHOD_POST,
		"url": server_url + "/v2/account/authenticate/email" + query,
		"headers": PackedStringArray(["Authorization: " + basic_auth(server_key), "Content-Type: application/json"]),
		"body": JSON.stringify(body),
	}


## Đổi refresh token lấy phiên mới (đăng nhập lại tự động khi mở game).
static func refresh_session(server_url: String, server_key: String, refresh_token: String) -> Dictionary:
	return {
		"method": HTTPClient.METHOD_POST,
		"url": server_url + "/v2/account/session/refresh",
		"headers": PackedStringArray(["Authorization: " + basic_auth(server_key), "Content-Type: application/json"]),
		"body": JSON.stringify({"token": refresh_token}),
	}


# ---------- Kiểm tra ô nhập (trả về khóa dịch lỗi, "" = hợp lệ). Máy chủ kiểm lại tên đăng nhập. ----------

const USERNAME_MIN := 3
const USERNAME_MAX := 20
const PASSWORD_MIN := 8   # Nakama yêu cầu tối thiểu 8


static func username_error(username: String) -> String:
	var re := RegEx.create_from_string("^[A-Za-z0-9_]{%d,%d}$" % [USERNAME_MIN, USERNAME_MAX])
	return "" if re.search(username) else "LOGIN_ERR_USERNAME"


static func email_error(email: String) -> String:
	var re := RegEx.create_from_string("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")
	return "" if re.search(email.strip_edges()) else "LOGIN_ERR_EMAIL"


static func password_error(password: String, confirm: String) -> String:
	if password.length() < PASSWORD_MIN:
		return "LOGIN_ERR_PASSWORD_SHORT"
	if password != confirm:
		return "LOGIN_ERR_PASSWORD_MISMATCH"
	return ""


## Gọi RPC của module máy chủ khi đã đăng nhập. Nakama nhận payload là một chuỗi JSON nằm trong JSON.
static func rpc(server_url: String, token: String, rpc_id: String, payload: Dictionary = {}) -> Dictionary:
	return {
		"method": HTTPClient.METHOD_POST,
		"url": server_url + "/v2/rpc/" + rpc_id.uri_encode(),
		"headers": PackedStringArray(["Authorization: Bearer " + token, "Content-Type: application/json"]),
		"body": JSON.stringify(JSON.stringify(payload)),
	}


## Kết quả đăng nhập: {ok, token, refresh_token, created, error}.
static func parse_session(code: int, body: String) -> Dictionary:
	var d: Variant = JSON.parse_string(body) if not body.is_empty() else null
	if code != 200 or not (d is Dictionary) or str(d.get("token", "")).is_empty():
		return {"ok": false, "error": error_message(code, body)}
	return {"ok": true, "token": str(d["token"]), "refresh_token": str(d.get("refresh_token", "")),
			"created": bool(d.get("created", false)), "error": ""}


## Kết quả RPC: {ok, data: Dictionary, error}.
static func parse_rpc(code: int, body: String) -> Dictionary:
	var d: Variant = JSON.parse_string(body) if not body.is_empty() else null
	if code != 200 or not (d is Dictionary):
		return {"ok": false, "data": {}, "error": error_message(code, body)}
	var payload: Variant = d.get("payload", "")
	var data: Variant = JSON.parse_string(str(payload)) if payload is String and not payload.is_empty() else payload
	if not (data is Dictionary):
		data = {}
	return {"ok": true, "data": data, "error": ""}


## Câu lỗi đọc được từ phản hồi Nakama ({"message": ...}); không có thì "HTTP <mã>".
## code 0 = không kết nối được (sai địa chỉ, máy chủ tắt, mất mạng).
static func error_message(code: int, body: String) -> String:
	var d: Variant = JSON.parse_string(body) if not body.is_empty() else null
	if d is Dictionary and d.has("message"):
		var msg := str(d["message"])
		var at := msg.find(" at ")
		if at > 0 and msg.contains("index.js"):
			msg = msg.substr(0, at)
		return msg.trim_prefix("Error: ")
	return "HTTP %d" % code


## Mã người chơi 8 số hiển thị thành 2 nhóm cho dễ đọc: "32354120" → "3235 4120".
static func format_code(code: String) -> String:
	if code.length() != 8:
		return code
	return code.substr(0, 4) + " " + code.substr(4)
