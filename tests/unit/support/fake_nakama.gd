class_name FakeNakama
extends RefCounted
## Máy chủ Nakama giả cho test trực tuyến (M9): nhận request của NakamaApi, trả {code, body} giống Nakama thật
## (đã đối chiếu bằng curl với Nakama 3.42 + server/modules/index.js). Không dùng mạng.

const SERVER_KEY := "k"

var sent: Array = []
## true: mọi request như mất mạng (code 0).
var down := false
## Lần RPC hồ sơ kế tiếp trả 401 (token hết hạn).
var expire_once := false
## username -> {email, password, code, user_id}
var accounts := {}
## user_id -> {version, envelope}
var saves := {}
var _next_version := 1


func _init() -> void:
	add_account("tester1", "t1@example.com", "matkhau123", "32354120")


func add_account(user: String, email: String, password: String, code: String) -> void:
	accounts[user] = {"email": email, "password": password, "code": code, "user_id": "uid-" + user}


func handle(req: Dictionary) -> Dictionary:
	sent.append(req)
	if down:
		return {"code": 0, "body": ""}
	var url: String = req["url"]
	var headers: PackedStringArray = req["headers"]
	var body: Variant = JSON.parse_string(req["body"])
	if url.contains("/authenticate/") or url.ends_with("/session/refresh"):
		if not headers.has("Authorization: " + NakamaApi.basic_auth(SERVER_KEY)):
			return _err(401, "Server key invalid")
	if url.contains("/authenticate/device"):
		if not accounts.has("device"):
			add_account("device", "", "", "55009391")
		return _session("device", true)
	if url.contains("/authenticate/email"):
		return _email(url, body)
	if url.ends_with("/session/refresh"):
		var rt := str(body["token"])
		if not rt.begins_with("R:"):
			return _err(401, "Refresh token invalid or expired.")
		return _session(rt.trim_prefix("R:"))
	if url.contains("/v2/rpc/"):
		var user := ""
		for h in headers:
			if h.begins_with("Authorization: Bearer T:"):
				user = h.trim_prefix("Authorization: Bearer T:")
		if not accounts.has(user):
			return _err(401, "Auth token invalid")
		var payload: Variant = JSON.parse_string(str(body)) if body is String else {}
		return _rpc(url.get_file(), accounts[user], payload if payload is Dictionary else {})
	return {"code": 404, "body": ""}


func requests_to(suffix: String) -> int:
	var n := 0
	for r in sent:
		if (r["url"] as String).ends_with(suffix):
			n += 1
	return n


func _email(url: String, body: Dictionary) -> Dictionary:
	var q := url.split("?")[1]
	var user := ""
	for part in q.split("&"):
		if part.begins_with("username="):
			user = part.trim_prefix("username=").uri_decode()
	if q.contains("create=true"):
		if accounts.has(user):
			return _err(409, "Username is already in use.")
		add_account(user, body["email"], body["password"], "1111%04d" % accounts.size())
		return _session(user, true)
	if user.is_empty():
		for u in accounts:
			if accounts[u]["email"] == body.get("email", ""):
				user = u
	if not accounts.has(user):
		return _err(404, "User account not found.")
	if str(body["password"]).length() < 8:
		return _err(400, "Password must be at least 8 characters long.")
	if accounts[user]["password"] != body["password"]:
		return _err(401, "Invalid credentials.")
	return _session(user)


func _rpc(id: String, acc: Dictionary, payload: Dictionary) -> Dictionary:
	match id:
		"eclipse_profile":
			if expire_once:
				expire_once = false
				return _err(401, "Auth token invalid")
			var user := ""
			for u in accounts:
				if accounts[u] == acc:
					user = u
			return _ok({"user_id": acc["user_id"], "code": acc["code"], "username": user, "wallet": {"gems": 600}})
		"save_get":
			var row: Variant = saves.get(acc["user_id"])
			if row == null:
				return _ok({"exists": false})
			return _ok({"exists": true, "version": row["version"], "envelope": row["envelope"]})
		"save_put":
			var row: Variant = saves.get(acc["user_id"])
			var current: String = row["version"] if row != null else ""
			if str(payload.get("base_version", "")) != current:
				return _err(500, "Error: save_conflict at rpcSavePut (index.js:255:11(51))")
			var v := "v%d" % _next_version
			_next_version += 1
			saves[acc["user_id"]] = {"version": v, "envelope": payload["envelope"]}
			return _ok({"version": v})
	return _err(404, "RPC function not found")


## Thiết bị khác ghi save cho tài khoản (để thử xung đột).
func write_from_other_device(user: String, envelope: Dictionary) -> void:
	saves[accounts[user]["user_id"]] = {"version": "v%d" % _next_version, "envelope": envelope}
	_next_version += 1


func _session(user: String, created := false) -> Dictionary:
	return {"code": 200, "body": JSON.stringify({"created": created, "token": "T:" + user, "refresh_token": "R:" + user})}


func _ok(data: Dictionary) -> Dictionary:
	return {"code": 200, "body": JSON.stringify({"payload": JSON.stringify(data)})}


func _err(code: int, message: String) -> Dictionary:
	return {"code": code, "body": JSON.stringify({"message": message})}
