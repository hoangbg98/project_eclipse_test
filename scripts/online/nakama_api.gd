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


# ---------- Chat, bạn bè, thông báo (M9-6) ----------

const WORLD_ROOM := "world"
const CHAT_MAX_LEN := 200
## Trạng thái bạn bè của Nakama.
const FRIEND_MUTUAL := 0
const FRIEND_INVITE_SENT := 1
const FRIEND_INVITE_RECEIVED := 2
const FRIEND_BLOCKED := 3
## Mã thông báo "có tin nhắn riêng" (server/modules/index.js, NOTIFY_CODE_DM) và "muốn nhắn" của Nakama.
const NOTIFY_DM := 100
const NOTIFY_DM_REQUEST := -1


## Địa chỉ websocket chat: http→ws, https→wss; token đi trong query (cách Nakama quy định).
static func ws_url(server_url: String, token: String) -> String:
	var base := server_url
	if base.begins_with("https://"):
		base = "wss://" + base.substr(8)
	elif base.begins_with("http://"):
		base = "ws://" + base.substr(7)
	return base + "/ws?format=json&token=" + token.uri_encode()


static func _authed(method: int, url: String, token: String, body := "") -> Dictionary:
	return {"method": method, "url": url, "body": body,
			"headers": PackedStringArray(["Authorization: Bearer " + token, "Content-Type: application/json"])}


static func _ids_query(ids: Array) -> String:
	var parts: PackedStringArray = []
	for id in ids:
		parts.append("ids=" + str(id).uri_encode())
	return "&".join(parts)


static func friends_list(server_url: String, token: String) -> Dictionary:
	return _authed(HTTPClient.METHOD_GET, server_url + "/v2/friend?limit=100", token)


## Kết bạn; nếu đối phương đã mời mình thì là chấp nhận.
static func friend_add(server_url: String, token: String, ids: Array) -> Dictionary:
	return _authed(HTTPClient.METHOD_POST, server_url + "/v2/friend?" + _ids_query(ids), token)


## Xóa bạn / từ chối lời mời / hủy lời mời đã gửi / bỏ chặn (Nakama dùng chung một lệnh).
static func friend_remove(server_url: String, token: String, ids: Array) -> Dictionary:
	return _authed(HTTPClient.METHOD_DELETE, server_url + "/v2/friend?" + _ids_query(ids), token)


static func friend_block(server_url: String, token: String, ids: Array) -> Dictionary:
	return _authed(HTTPClient.METHOD_POST, server_url + "/v2/friend/block?" + _ids_query(ids), token)


static func notifications_list(server_url: String, token: String) -> Dictionary:
	return _authed(HTTPClient.METHOD_GET, server_url + "/v2/notification?limit=50", token)


static func notifications_delete(server_url: String, token: String, ids: Array) -> Dictionary:
	return _authed(HTTPClient.METHOD_DELETE, server_url + "/v2/notification?" + _ids_query(ids), token)


static func channel_history(server_url: String, token: String, channel_id: String, limit := 50) -> Dictionary:
	return _authed(HTTPClient.METHOD_GET,
			server_url + "/v2/channel/%s?limit=%d&forward=false" % [channel_id.uri_encode(), limit], token)


## Danh sách bạn: {ok, friends: [{id, username, state, online}], error}.
static func parse_friends(code: int, body: String) -> Dictionary:
	var d: Variant = JSON.parse_string(body) if not body.is_empty() else null
	if code != 200 or not (d is Dictionary):
		return {"ok": false, "friends": [], "error": error_message(code, body)}
	var out: Array = []
	for f in d.get("friends", []):
		var u: Dictionary = f.get("user", {})
		out.append({"id": str(u.get("id", "")), "username": str(u.get("username", "")),
				"state": int(f.get("state", 0)), "online": bool(u.get("online", false))})
	return {"ok": true, "friends": out, "error": ""}


## Lịch sử kênh: {ok, messages (cũ → mới), error}.
static func parse_history(code: int, body: String) -> Dictionary:
	var d: Variant = JSON.parse_string(body) if not body.is_empty() else null
	if code != 200 or not (d is Dictionary):
		return {"ok": false, "messages": [], "error": error_message(code, body)}
	var out: Array = []
	for m in d.get("messages", []):
		var msg := message_from(m)
		if not msg.is_empty():
			out.push_front(msg)   # API trả mới nhất trước
	return {"ok": true, "messages": out, "error": ""}


## Thông báo: {ok, notifications: [{id, code, sender_id, content: Dictionary}], error}.
static func parse_notifications(code: int, body: String) -> Dictionary:
	var d: Variant = JSON.parse_string(body) if not body.is_empty() else null
	if code != 200 or not (d is Dictionary):
		return {"ok": false, "notifications": [], "error": error_message(code, body)}
	var out: Array = []
	for n in d.get("notifications", []):
		out.append(notification_from(n))
	return {"ok": true, "notifications": out, "error": ""}


## Một thông báo (REST hoặc websocket) → {id, code, sender_id, content: Dictionary}.
static func notification_from(n: Dictionary) -> Dictionary:
	var content: Variant = quiet_json(str(n.get("content", "")))
	return {"id": str(n.get("id", "")), "code": int(n.get("code", 0)), "sender_id": str(n.get("sender_id", "")),
			"content": content if content is Dictionary else {}}


## Đọc JSON không in lỗi của engine khi chuỗi hỏng (nội dung tin nhắn do người chơi khác gửi); hỏng thì trả null.
static func quiet_json(text: String) -> Variant:
	var j := JSON.new()
	return j.data if j.parse(text) == OK else null


## Tin nhắn Nakama (REST hoặc websocket) → {id, channel_id, sender_id, username, text, time}; {} nếu không phải tin chữ.
static func message_from(m: Dictionary) -> Dictionary:
	if int(m.get("code", 0)) != 0:
		return {}   # tin hệ thống của Nakama (vào / rời nhóm...)
	var content: Variant = quiet_json(str(m.get("content", "")))
	if not (content is Dictionary) or str(content.get("text", "")).is_empty():
		return {}
	return {"id": str(m.get("message_id", "")), "channel_id": str(m.get("channel_id", "")),
			"sender_id": str(m.get("sender_id", "")), "username": str(m.get("username", "")),
			"text": str(content["text"]), "time": parse_time(str(m.get("create_time", "")))}


## "2026-11-16T08:48:50.088925200Z" → giây unix (UTC); 0 nếu không đọc được.
static func parse_time(rfc3339: String) -> int:
	if rfc3339.is_empty():
		return 0
	return int(Time.get_unix_time_from_datetime_string(rfc3339.split(".")[0].trim_suffix("Z")))


## Kênh nhắn riêng "4.<id1>.<id2>." → id người còn lại ("" nếu không phải kênh nhắn riêng của `me`).
static func dm_peer(channel_id: String, me: String) -> String:
	var p := channel_id.split(".")
	if p.size() < 3 or p[0] != "4":
		return ""
	if p[1] == me:
		return p[2]
	return p[1] if p[2] == me else ""


## Hạn dùng (giây unix) của token JWT; 0 nếu không đọc được (token giả trong test).
static func token_expiry(token: String) -> int:
	var parts := token.split(".")
	if parts.size() != 3:
		return 0
	var b64 := parts[1].replace("-", "+").replace("_", "/")
	while b64.length() % 4 != 0:
		b64 += "="
	if RegEx.create_from_string("^[A-Za-z0-9+/]*=*$").search(b64) == null:
		return 0
	var d: Variant = quiet_json(Marshalls.base64_to_raw(b64).get_string_from_utf8())
	return int(d.get("exp", 0)) if d is Dictionary else 0


# ---- Gói tin websocket (mỗi gói có cid để nhận phản hồi) ----

static func socket_join_room(cid: String, room: String) -> String:
	return JSON.stringify({"cid": cid, "channel_join": {"target": room, "type": 1, "persistence": true, "hidden": false}})


static func socket_join_dm(cid: String, user_id: String) -> String:
	return JSON.stringify({"cid": cid, "channel_join": {"target": user_id, "type": 2, "persistence": true, "hidden": false}})


static func socket_send(cid: String, channel_id: String, text: String) -> String:
	return JSON.stringify({"cid": cid, "channel_message_send": {"channel_id": channel_id, "content": JSON.stringify({"text": text})}})


## Lỗi từ máy chủ ("chat_rate", "chat_muted:<ms>", ...) → khóa dịch.
static func chat_error_key(message: String) -> String:
	if message.contains("chat_rate"):
		return "CHAT_ERR_RATE"
	if message.contains("chat_muted"):
		return "CHAT_ERR_MUTED"
	if message.contains("chat_blocked"):
		return "CHAT_ERR_BLOCKED"
	if message.contains("chat_too_long"):
		return "CHAT_ERR_TOO_LONG"
	if message.contains("chat_empty"):
		return "CHAT_ERR_EMPTY"
	if message.contains("chat_not_found"):
		return "CHAT_ERR_NOT_FOUND"
	return "CHAT_ERR_SEND"
