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

# ---- Chat (M9-6) ----
## Socket đang mở (FakeSocket).
var sockets: Array = []
var socket_attempts := 0
## user_id → {user_id khác → trạng thái bạn bè (NakamaApi.FRIEND_*)}.
var friend_edges := {}
## user_id → thông báo [{id, code, sender_id, subject, content}].
var notes := {}
## channel_id → tin thô (cũ → mới), channel_id → user_id đã vào kênh.
var channel_log := {}
var members := {}
## username → hạn cấm chat (ms); lỗi máy chủ giả cho tin kế tiếp (vd "chat_rate").
var muted := {}
var chat_error_next := ""
## Số tin / thông báo / kết bạn / REST đã xử lý (để test đếm).
var counters := {"note_deleted": 0}
var reports: Array = []

# ---- Nạp tiền (M9-2): bảng giá + thẻ tháng giả, phản chiếu logic của server/modules/index.js ----
## Bảng giá (test nạp từ data/shop/topup_packs.json); rỗng = máy chủ chưa có bảng giá.
var catalog: Dictionary = {}
var topup_epoch := 1
## user_id → {bought: {gói: kỳ}, log: [], card: {claims_left, claims_total, last_day}}.
var topup_state := {}
## Ngày hiện tại của máy chủ giả (yyyy-mm-dd) để thử "một ngày một lần".
var today := "2026-11-16"
var _msg_counter := 0
var _note_counter := 0


func _init() -> void:
	add_account("tester1", "t1@example.com", "matkhau123", "32354120")


func add_account(user: String, email: String, password: String, code: String) -> void:
	accounts[user] = {"email": email, "password": password, "code": code, "user_id": "uid-" + user, "wallet": {"gems": 600}}


func handle(req: Dictionary) -> Dictionary:
	sent.append(req)
	if down:
		return {"code": 0, "body": ""}
	var url: String = req["url"]
	var headers: PackedStringArray = req["headers"]
	var body: Variant = JSON.parse_string(req["body"]) if not str(req["body"]).is_empty() else null
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
	if url.contains("/v2/rpc/") or url.contains("/v2/friend") or url.contains("/v2/notification") \
			or url.contains("/v2/channel/"):
		var user := ""
		for h in headers:
			if h.begins_with("Authorization: Bearer T:"):
				user = h.trim_prefix("Authorization: Bearer T:")
		if not accounts.has(user):
			return _err(401, "Auth token invalid")
		if url.contains("/v2/friend"):
			return _friend_rest(user, int(req["method"]), url)
		if url.contains("/v2/notification"):
			return _notification_rest(user, int(req["method"]), url)
		if url.contains("/v2/channel/"):
			return _history_rest(url)
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
			return _ok({"user_id": acc["user_id"], "code": acc["code"], "username": user, "wallet": acc["wallet"].duplicate()})
		"topup_info":
			return _ok(topup_info_for(acc))
		"card_claim":
			return card_claim_for(acc)
		"chat_find":
			var code := str(payload.get("code", ""))
			for u in accounts:
				if accounts[u]["code"] == code:
					return _ok({"user_id": accounts[u]["user_id"], "username": u, "code": code})
			return _err(500, "Error: chat_not_found at rpcChatFind (index.js:1:1(1))")
		"chat_report":
			reports.append(payload.duplicate())
			return _ok({"id": "r%d" % reports.size()})
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


# ---------- Chat giả: bạn bè, thông báo, lịch sử, websocket ----------

func uid_of(user: String) -> String:
	return accounts[user]["user_id"]


func user_of_uid(uid: String) -> String:
	for u in accounts:
		if accounts[u]["user_id"] == uid:
			return u
	return ""


func user_from_ws_url(url: String) -> String:
	for part in url.split("?")[1].split("&"):
		if part.begins_with("token="):
			var t := part.trim_prefix("token=").uri_decode()
			return t.trim_prefix("T:") if t.begins_with("T:") and accounts.has(t.trim_prefix("T:")) else ""
	return ""


func socket_factory() -> FakeSocket:
	var sock := FakeSocket.new()
	sock.hub = self
	return sock


func _ids_of(url: String) -> Array:
	var out: Array = []
	if not url.contains("?"):
		return out
	for part in url.split("?")[1].split("&"):
		if part.begins_with("ids="):
			out.append(part.trim_prefix("ids=").uri_decode())
	return out


func edge(a: String, b: String) -> int:
	return int(friend_edges.get(a, {}).get(b, -1))


func _set_edge(a: String, b: String, state: int) -> void:
	if state < 0:
		if friend_edges.has(a):
			friend_edges[a].erase(b)
		return
	if not friend_edges.has(a):
		friend_edges[a] = {}
	friend_edges[a][b] = state


func _friend_rest(user: String, method: int, url: String) -> Dictionary:
	var me := uid_of(user)
	var path := url.split("?")[0]
	if method == HTTPClient.METHOD_GET:
		var list: Array = []
		for other in friend_edges.get(me, {}):
			var name_ := user_of_uid(other)
			list.append({"user": {"id": other, "username": name_, "online": _is_online(other)}, "state": friend_edges[me][other]})
		return {"code": 200, "body": JSON.stringify({"friends": list})}
	for other in _ids_of(url):
		if path.ends_with("/block"):
			_set_edge(me, other, NakamaApi.FRIEND_BLOCKED)
			_set_edge(other, me, -1)
			for ch in members:   # Nakama đẩy người bị chặn khỏi kênh nhắn riêng
				if str(ch).begins_with("4.") and str(ch).contains(me) and str(ch).contains(other):
					members[ch].erase(other)
		elif method == HTTPClient.METHOD_POST:
			if edge(other, me) == NakamaApi.FRIEND_BLOCKED:
				continue
			if edge(other, me) == NakamaApi.FRIEND_INVITE_SENT:
				_set_edge(me, other, NakamaApi.FRIEND_MUTUAL)
				_set_edge(other, me, NakamaApi.FRIEND_MUTUAL)
			elif edge(me, other) < 0:
				_set_edge(me, other, NakamaApi.FRIEND_INVITE_SENT)
				_set_edge(other, me, NakamaApi.FRIEND_INVITE_RECEIVED)
		else:
			_set_edge(me, other, -1)
			if edge(other, me) != NakamaApi.FRIEND_BLOCKED:
				_set_edge(other, me, -1)
	return {"code": 200, "body": "{}"}


func _is_online(uid: String) -> bool:
	for sock in sockets:
		if uid_of(sock.user) == uid:
			return true
	return false


func _notification_rest(user: String, method: int, url: String) -> Dictionary:
	var me := uid_of(user)
	if method == HTTPClient.METHOD_DELETE:
		var ids := _ids_of(url)
		var keep: Array = []
		for n in notes.get(me, []):
			if ids.has(n["id"]):
				counters["note_deleted"] += 1
			else:
				keep.append(n)
		notes[me] = keep
		return {"code": 200, "body": "{}"}
	var out: Array = []
	for n in notes.get(me, []):
		out.append({"id": n["id"], "subject": n["subject"], "content": JSON.stringify(n["content"]), "code": n["code"],
				"sender_id": n["sender_id"]})
	return {"code": 200, "body": JSON.stringify({"notifications": out})}


func _history_rest(url: String) -> Dictionary:
	var id := url.split("?")[0].get_slice("/v2/channel/", 1).uri_decode()
	var log: Array = channel_log.get(id, [])
	var limit := 50
	for part in url.split("?")[1].split("&"):
		if part.begins_with("limit="):
			limit = int(part.trim_prefix("limit="))
	var out: Array = log.duplicate()
	out.reverse()   # mới nhất trước, như Nakama
	return {"code": 200, "body": JSON.stringify({"messages": out.slice(0, limit)})}


func _push_note(to_uid: String, code: int, sender_uid: String, subject: String, content: Dictionary) -> void:
	_note_counter += 1
	var n := {"id": "n%d" % _note_counter, "code": code, "sender_id": sender_uid, "subject": subject, "content": content}
	if not notes.has(to_uid):
		notes[to_uid] = []
	notes[to_uid].append(n)
	for sock in sockets:
		if uid_of(sock.user) == to_uid:
			sock.push({"notifications": {"notifications": [{"id": n["id"], "subject": subject,
					"content": JSON.stringify(content), "code": code, "sender_id": sender_uid, "persistent": true}]}})


func _sock_err(sock: FakeSocket, cid: String, message: String) -> void:
	sock.push({"cid": cid, "error": {"code": 13, "message": message}})


func on_socket_text(sock: FakeSocket, text: String) -> void:
	var env: Dictionary = JSON.parse_string(text)
	var cid := str(env.get("cid", ""))
	var me := uid_of(sock.user)
	if env.has("channel_join"):
		var j: Dictionary = env["channel_join"]
		var id := ""
		if int(j["type"]) == 1:
			if j["target"] != NakamaApi.WORLD_ROOM:
				_sock_err(sock, cid, "Error: chat_channel_not_allowed at beforeChannelJoin (index.js:1:1(1))")
				return
			id = "2...world"
		else:
			var ids := [me, str(j["target"])]
			ids.sort()
			id = "4.%s.%s." % ids
			if not members.has(id) or not members[id].has(me):
				_push_note(str(j["target"]), NakamaApi.NOTIFY_DM_REQUEST, me, sock.user + " wants to chat", {"username": sock.user})
		if not members.has(id):
			members[id] = []
		if not members[id].has(me):
			members[id].append(me)
		sock.push({"cid": cid, "channel": {"id": id}})
	elif env.has("channel_message_send"):
		var m: Dictionary = env["channel_message_send"]
		var id := str(m["channel_id"])
		if chat_error_next != "":
			var e := chat_error_next
			chat_error_next = ""
			_sock_err(sock, cid, "Error: %s at beforeChannelMessageSend (index.js:1:1(1))" % e)
			return
		if muted.get(sock.user, 0) > 0:
			_sock_err(sock, cid, "Error: chat_muted:%d at beforeChannelMessageSend (index.js:1:1(1))" % muted[sock.user])
			return
		if not members.has(id) or not members[id].has(me):
			_sock_err(sock, cid, "Must join channel before sending messages")
			return
		var peer := NakamaApi.dm_peer(id, me)
		if not peer.is_empty() and edge(peer, me) == NakamaApi.FRIEND_BLOCKED:
			_sock_err(sock, cid, "Error: chat_blocked at beforeChannelMessageSend (index.js:1:1(1))")
			return
		_msg_counter += 1
		var raw := {"channel_id": id, "message_id": "m%d" % _msg_counter, "code": 0, "sender_id": me, "username": sock.user,
				"content": m["content"], "create_time": "2026-11-16T08:%02d:00.000000000Z" % (_msg_counter % 60), "persistent": true}
		if not channel_log.has(id):
			channel_log[id] = []
		channel_log[id].append(raw)
		sock.push({"cid": cid, "channel_message_ack": {"channel_id": id, "message_id": raw["message_id"]}})
		for other in sockets:
			if members[id].has(uid_of(other.user)):
				other.push({"channel_message": raw})
		if not peer.is_empty():
			var body: Variant = JSON.parse_string(str(m["content"]))
			_push_note(peer, NakamaApi.NOTIFY_DM, me, sock.user, {"from_id": me, "from_name": sock.user, "text": str(body["text"])})


## Test: một người gửi tin trực tiếp vào kênh (không qua socket của game), như người khác đang chat.
func inject_message(from_user: String, channel_id: String, text: String) -> void:
	var fake_sock: FakeSocket
	for s in sockets:
		if s.user == from_user:
			fake_sock = s
	assert(fake_sock != null, "người gửi cần có socket")
	fake_sock.send_text(NakamaApi.socket_send("x%d" % _msg_counter, channel_id, text))


# ---------- Nạp tiền giả ----------

func _state_of(uid: String) -> Dictionary:
	if not topup_state.has(uid):
		topup_state[uid] = {"bought": {}, "log": [], "card": {"claims_left": 0, "claims_total": 0, "last_day": ""}}
	return topup_state[uid]


func _card_view(st: Dictionary) -> Dictionary:
	var c: Dictionary = st["card"]
	var cd: Dictionary = catalog.get("card", {"daily": 0, "milestone_every": 1, "milestone_bonus": 0})
	var nxt: int = int(c["claims_total"]) + 1
	return {"claims_left": c["claims_left"], "claims_total": c["claims_total"],
			"can_claim": int(c["claims_left"]) > 0 and c["last_day"] != today,
			"next_gems": int(cd["daily"]) + (int(cd["milestone_bonus"]) if nxt % int(cd["milestone_every"]) == 0 else 0),
			"until_milestone": int(cd["milestone_every"]) - int(c["claims_total"]) % int(cd["milestone_every"])}


func topup_info_for(acc: Dictionary) -> Dictionary:
	var st := _state_of(acc["user_id"])
	var eligible := {}
	for p: Dictionary in catalog.get("packs", []):
		if p.get("first_bonus", false):
			eligible[p["id"]] = int(st["bought"].get(p["id"], 0)) < topup_epoch
	return {"catalog": catalog if not catalog.is_empty() else null, "eligible": eligible, "card": _card_view(st),
			"log": (st["log"] as Array).slice(0, 10), "code": acc["code"]}


func card_claim_for(acc: Dictionary) -> Dictionary:
	var st := _state_of(acc["user_id"])
	var c: Dictionary = st["card"]
	if catalog.is_empty() or int(c["claims_left"]) <= 0:
		return _err(500, "Error: card_none at rpcCardClaim (index.js:1:1(1))")
	if c["last_day"] == today:
		return _err(500, "Error: card_claimed_today at rpcCardClaim (index.js:1:1(1))")
	c["claims_left"] = int(c["claims_left"]) - 1
	c["claims_total"] = int(c["claims_total"]) + 1
	c["last_day"] = today
	var cd: Dictionary = catalog["card"]
	var bonus: int = int(cd["milestone_bonus"]) if int(c["claims_total"]) % int(cd["milestone_every"]) == 0 else 0
	acc["wallet"]["gems"] = int(acc["wallet"].get("gems", 0)) + int(cd["daily"]) + bonus
	return _ok({"gems": int(cd["daily"]) + bonus, "daily": cd["daily"], "bonus": bonus, "card": _card_view(st)})


## Test: QTV phát gói (như admin_topup). Trả về {base, bonus, card_days}.
func give_pack(user: String, pack_id: String) -> Dictionary:
	var acc: Dictionary = accounts[user]
	var st := _state_of(acc["user_id"])
	var pack := {}
	for p: Dictionary in catalog.get("packs", []):
		if p["id"] == pack_id:
			pack = p
	assert(not pack.is_empty(), "không có gói " + pack_id)
	var out := {"base": 0, "bonus": 0, "card_days": 0}
	if pack["kind"] == "card":
		st["card"]["claims_left"] = int(st["card"]["claims_left"]) + int(catalog["card"]["days"])
		out["card_days"] = int(catalog["card"]["days"])
	else:
		var bonus: int = int(pack["amount"]) if pack.get("first_bonus", false) and int(st["bought"].get(pack_id, 0)) < topup_epoch else 0
		acc["wallet"][pack["currency"]] = int(acc["wallet"].get(pack["currency"], 0)) + int(pack["amount"]) + bonus
		st["bought"][pack_id] = topup_epoch
		out["base"] = int(pack["amount"])
		out["bonus"] = bonus
	(st["log"] as Array).push_front({"t": 1794800000, "pack": pack_id, "base": out["base"], "bonus": out["bonus"],
			"card_days": out["card_days"], "paid": pack.get("price", 0), "ref": "T%d" % (st["log"] as Array).size()})
	return out
