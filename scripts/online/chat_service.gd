class_name ChatService
extends Node
## Chat trong game (M9-6): phòng "Thế giới", nhắn riêng, bạn bè, chặn, báo cáo. Do OnlineService tạo (`OnlineService.chat`),
## tự kết nối sau khi đăng nhập. Không chứa luật gameplay; UI (ChatPanel) chỉ đọc state và nghe signal.
##
## Mạng: websocket tới Nakama (Nakama đẩy tin cho người đã vào kênh) + REST cho bạn bè / lịch sử / thông báo.
## `socket_factory` trả về đối tượng có giao diện của WebSocketPeer (test thay bằng bản giả); REST đi qua
## `online.call_api` nên dùng chung token, tự làm mới phiên và `transport` giả của test.
##
## Máy chủ lọc từ, giãn cách tin, cấm chat, chặn nhắn riêng (xem server/modules/index.js). Tin của người bị chặn
## được ẩn ở phòng thế giới ngay tại máy (Nakama không lọc theo người nhận ở phòng chung).

signal state_changed(state: State)
signal message_received(channel_id: String, message: Dictionary)
signal history_loaded(channel_id: String)
signal friends_changed
signal unread_changed
## Thông báo ngắn cho UI (khóa dịch), vd lời mời kết bạn mới.
signal notice(key: String)

enum State { OFF, CONNECTING, ONLINE }

const HISTORY_LIMIT := 50
const KEEP_MESSAGES := 200
const RETRY_FIRST := 2.0
const RETRY_MAX := 30.0
## Giãn cách tối thiểu giữa hai tin (giây); máy chủ cũng chặn 0,8 giây.
const SEND_INTERVAL := 0.9

var online: Node
var state := State.OFF
## Tạo socket mới; mặc định là WebSocketPeer thật.
var socket_factory: Callable = func() -> Object: return WebSocketPeer.new()
## Giờ hiện tại theo giây (test thay để không phải chờ).
var clock: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0

var world_id := ""
## channel_id → danh sách tin (cũ → mới).
var history: Dictionary = {}
## Bạn bè: [{id, username, state, online}] (state theo NakamaApi.FRIEND_*).
var friends: Array = []
## id → tên người đã chặn.
var blocked: Dictionary = {}
## id người gửi → số tin / thông báo chưa đọc.
var unread: Dictionary = {}
## id → tên của người từng nhắn / được nhắn (bạn bè, tin nhắn, thông báo).
var names: Dictionary = {}
## Cuộc nhắn riêng đang mở trong UI (để không tính chưa đọc); "" = không có.
var active_peer := ""
## Hạn cấm chat (ms unix) của lần gửi bị từ chối gần nhất.
var muted_until := 0

var _socket: Object
var _want := false
var _opened := false
var _next_cid := 1
var _pending: Dictionary = {}
var _dm_channels: Dictionary = {}   # peer id → channel id
var _note_ids: Dictionary = {}      # peer id → [id thông báo] (xóa khi đã đọc)
var _retry_in := 0.0
var _retry_gap := RETRY_FIRST
var _last_send := -100.0


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	poll()


func me() -> String:
	return online.user_id() if online else ""


func is_connected_to_chat() -> bool:
	return state == State.ONLINE


# ---------- Kết nối ----------

## Bắt đầu kết nối (và tự nối lại khi rớt) cho tới khi gọi `stop()`.
func start() -> void:
	if _want:
		return
	_want = true
	_retry_gap = RETRY_FIRST
	_connect()


func stop() -> void:
	_want = false
	_close_socket()
	history.clear()
	friends.clear()
	blocked.clear()
	unread.clear()
	names.clear()
	_dm_channels.clear()
	_note_ids.clear()
	world_id = ""
	active_peer = ""
	muted_until = 0
	_set_state(State.OFF)
	friends_changed.emit()
	unread_changed.emit()


func _connect() -> void:
	if not _want or online == null or online.token.is_empty():
		return
	_set_state(State.CONNECTING)
	var token: String = await online.fresh_token()
	if not _want or token.is_empty():
		_set_state(State.OFF)
		return
	_close_socket()
	_socket = socket_factory.call()
	_opened = false
	var err: int = _socket.connect_to_url(NakamaApi.ws_url(online.config.server_url, token))
	if err != OK:
		_on_closed()


func _close_socket() -> void:
	if _socket:
		_socket.close()
		_socket = null
	for cid in _pending.keys():
		_pending[cid].done.emit({"error": {"message": "closed"}})
	_pending.clear()
	_dm_channels.clear()
	_opened = false


## Đọc gói tin đã tới và xử lý rớt kết nối. Gọi mỗi khung hình (và trực tiếp trong test).
func poll() -> void:
	if _socket == null:
		if _want and state == State.OFF and _retry_in > 0.0:
			_retry_in -= get_process_delta_time() if is_inside_tree() else 0.0
			if _retry_in <= 0.0:
				_connect()
		return
	_socket.poll()
	var st: int = _socket.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN:
		if not _opened:
			_opened = true
			_on_open()
		while _socket and _socket.get_available_packet_count() > 0:
			var text: String = _socket.get_packet().get_string_from_utf8()
			var env: Variant = JSON.parse_string(text)
			if env is Dictionary:
				_on_packet(env)
	elif st == WebSocketPeer.STATE_CLOSED:
		_on_closed()


func _on_closed() -> void:
	_close_socket()
	_set_state(State.OFF)
	if _want:
		_retry_in = _retry_gap
		_retry_gap = minf(_retry_gap * 2.0, RETRY_MAX)


func _on_open() -> void:
	_retry_gap = RETRY_FIRST
	_set_state(State.ONLINE)
	_after_open()


func _after_open() -> void:
	var env: Dictionary = await _call(NakamaApi.socket_join_room, [NakamaApi.WORLD_ROOM])
	if env.has("channel"):
		world_id = str(env["channel"].get("id", ""))
		await _load_history(world_id)
	await refresh_friends()
	await _load_notifications()


# ---------- Gói tin ----------

## Gửi một gói tin có cid và chờ phản hồi cùng cid. `builder.call(cid, ...args)` trả chuỗi JSON.
func _call(builder: Callable, args: Array) -> Dictionary:
	if _socket == null or state != State.ONLINE:
		return {"error": {"message": "offline"}}
	var cid := str(_next_cid)
	_next_cid += 1
	var reply := _Reply.new()
	_pending[cid] = reply
	_socket.send_text(builder.callv([cid] + args))
	var env: Dictionary = await reply.done
	_pending.erase(cid)
	return env


func _on_packet(env: Dictionary) -> void:
	var cid := str(env.get("cid", ""))
	if not cid.is_empty() and _pending.has(cid):
		_pending[cid].done.emit(env)
		return
	if env.has("channel_message"):
		_on_message(env["channel_message"])
	elif env.has("notifications"):
		for n in env["notifications"].get("notifications", []):
			_on_notification(NakamaApi.notification_from(n))


func _on_message(raw: Dictionary) -> void:
	var msg := NakamaApi.message_from(raw)
	if msg.is_empty():
		return
	var channel := str(msg["channel_id"])
	var peer := NakamaApi.dm_peer(channel, me())
	if channel == world_id and blocked.has(msg["sender_id"]):
		return
	_append(channel, msg)
	if not peer.is_empty():
		names[peer] = names.get(peer, msg["username"] if msg["sender_id"] == peer else "")
		if msg["sender_id"] != me() and peer != active_peer:
			unread[peer] = int(unread.get(peer, 0)) + 1
			unread_changed.emit()
	message_received.emit(channel, msg)


func _on_notification(n: Dictionary) -> void:
	var from: String = n["sender_id"]
	if from.is_empty() or from == me() or blocked.has(from):
		return
	if n["code"] == NakamaApi.NOTIFY_DM or n["code"] == NakamaApi.NOTIFY_DM_REQUEST:
		names[from] = str(n["content"].get("from_name", n["content"].get("username", names.get(from, ""))))
		_note_ids[from] = _note_ids.get(from, []) + [n["id"]]
		# Chỉ mã 100 (có tin thật) mới tính chưa đọc; và chỉ khi chưa vào kênh (đã vào thì tin tới trực tiếp, tính ở _on_message).
		var counts: bool = n["code"] == NakamaApi.NOTIFY_DM and not _dm_channels.has(from)
		if from == active_peer:
			_delete_notes(from)
		elif counts:
			unread[from] = int(unread.get(from, 0)) + 1
			unread_changed.emit()
		_ensure_dm(from)   # vào kênh để nhận tin trực tiếp từ giờ
	elif n["code"] == -2:   # có người gửi lời mời kết bạn (mã của Nakama)
		notice.emit("CHAT_NOTICE_FRIEND_INVITE")
		refresh_friends()
	elif n["code"] == -3:   # lời mời được chấp nhận
		refresh_friends()


func _append(channel: String, msg: Dictionary) -> void:
	var list: Array = history.get(channel, [])
	for m in list:
		if m["id"] == msg["id"]:
			return
	list.append(msg)
	if list.size() > KEEP_MESSAGES:
		list = list.slice(list.size() - KEEP_MESSAGES)
	history[channel] = list


func messages(channel: String) -> Array:
	return history.get(channel, [])


# ---------- Phòng thế giới / nhắn riêng ----------

## Vào kênh nhắn riêng với `peer` nếu chưa vào; trả về id kênh ("" nếu lỗi).
func _ensure_dm(peer: String, force := false) -> String:
	if _dm_channels.has(peer) and not force:
		return _dm_channels[peer]
	var env: Dictionary = await _call(NakamaApi.socket_join_dm, [peer])
	if not env.has("channel"):
		return ""
	var id := str(env["channel"].get("id", ""))
	_dm_channels[peer] = id
	return id


## Mở cuộc nhắn riêng: vào kênh, tải lịch sử, đánh dấu đã đọc. Trả về id kênh ("" nếu lỗi).
func open_dm(peer: String, peer_name := "") -> String:
	if peer_name != "":
		names[peer] = peer_name
	active_peer = peer
	var id := await _ensure_dm(peer)
	if id.is_empty():
		return ""
	await _load_history(id)
	mark_read(peer)
	return id


func close_dm() -> void:
	active_peer = ""


func _load_history(channel: String) -> void:
	if online == null or channel.is_empty():
		return
	var res: Dictionary = await online.call_api(
			func(url: String, tok: String) -> Dictionary: return NakamaApi.channel_history(url, tok, channel, HISTORY_LIMIT))
	var r := NakamaApi.parse_history(int(res.get("code", 0)), str(res.get("body", "")))
	if not r["ok"]:
		return
	var world := channel == world_id
	var merged: Array = []
	for m in r["messages"]:
		if world and blocked.has(m["sender_id"]):
			continue
		merged.append(m)
	# Tin tới trong lúc tải (đã có trong history) nằm sau lịch sử.
	for m in history.get(channel, []):
		var dup := false
		for k in merged:
			if k["id"] == m["id"]:
				dup = true
				break
		if not dup:
			merged.append(m)
	history[channel] = merged
	history_loaded.emit(channel)


# ---------- Gửi tin ----------

## Gửi vào phòng thế giới. Trả về "" nếu thành công, hoặc khóa dịch của lỗi.
func send_world(text: String) -> String:
	return await _send(world_id, text, "")


## Gửi nhắn riêng cho `peer`.
func send_dm(peer: String, text: String) -> String:
	var id := await _ensure_dm(peer)
	if id.is_empty():
		return "CHAT_ERR_SEND"
	return await _send(id, text, peer)


func _send(channel: String, raw: String, peer: String, retried := false) -> String:
	var text := raw.strip_edges()
	if text.is_empty():
		return "CHAT_ERR_EMPTY"
	if text.length() > NakamaApi.CHAT_MAX_LEN:
		return "CHAT_ERR_TOO_LONG"
	if state != State.ONLINE or channel.is_empty():
		return "CHAT_ERR_OFFLINE"
	var now: float = clock.call()
	if now - _last_send < SEND_INTERVAL:
		return "CHAT_ERR_RATE"
	_last_send = now
	var env: Dictionary = await _call(NakamaApi.socket_send, [channel, text])
	if env.has("channel_message_ack"):
		return ""
	var msg := str(env.get("error", {}).get("message", ""))
	# Bị chặn rồi được bỏ chặn: Nakama đã đẩy mình khỏi kênh, phải vào lại rồi gửi lại một lần.
	if msg.contains("Must join channel") and not peer.is_empty() and not retried:
		await _ensure_dm(peer, true)
		_last_send = -100.0
		return await _send(channel, text, peer, true)
	if msg.contains("chat_muted:"):
		muted_until = int(msg.get_slice("chat_muted:", 1))
	return NakamaApi.chat_error_key(msg)


# ---------- Bạn bè, chặn ----------

func refresh_friends() -> bool:
	if online == null:
		return false
	var res: Dictionary = await online.call_api(
			func(url: String, tok: String) -> Dictionary: return NakamaApi.friends_list(url, tok))
	var r := NakamaApi.parse_friends(int(res.get("code", 0)), str(res.get("body", "")))
	if not r["ok"]:
		return false
	friends = r["friends"]
	blocked.clear()
	for f in friends:
		names[f["id"]] = f["username"]
		if f["state"] == NakamaApi.FRIEND_BLOCKED:
			blocked[f["id"]] = f["username"]
	friends_changed.emit()
	return true


func friend_state(id: String) -> int:
	for f in friends:
		if f["id"] == id:
			return f["state"]
	return -1


## Kết bạn theo mã người chơi 8 số. "" = đã gửi lời mời (hoặc đã là bạn), ngược lại là khóa dịch của lỗi.
func add_friend_by_code(code: String) -> String:
	var found: Dictionary = await online.call_rpc("chat_find", {"code": code.replace(" ", "")})
	if not found["ok"]:
		return NakamaApi.chat_error_key(str(found["error"]))
	var id := str(found["data"]["user_id"])
	if id == me():
		return "CHAT_ERR_SELF"
	names[id] = str(found["data"]["username"])
	return await add_friend(id)


func add_friend(id: String) -> String:
	return await _friend_cmd(func(url: String, tok: String) -> Dictionary: return NakamaApi.friend_add(url, tok, [id]))


## Xóa bạn / từ chối lời mời / hủy lời mời / bỏ chặn.
func remove_friend(id: String) -> String:
	return await _friend_cmd(func(url: String, tok: String) -> Dictionary: return NakamaApi.friend_remove(url, tok, [id]))


func block(id: String) -> String:
	var err := await _friend_cmd(func(url: String, tok: String) -> Dictionary: return NakamaApi.friend_block(url, tok, [id]))
	if err.is_empty():
		_hide_from_world(id)
	return err


func _friend_cmd(make: Callable) -> String:
	var res: Dictionary = await online.call_api(make)
	var code := int(res.get("code", 0))
	if code != 200:
		return "CHAT_ERR_SEND"
	await refresh_friends()
	return ""


func _hide_from_world(id: String) -> void:
	if world_id.is_empty() or not history.has(world_id):
		return
	history[world_id] = (history[world_id] as Array).filter(func(m: Dictionary) -> bool: return m["sender_id"] != id)
	history_loaded.emit(world_id)


## Báo cáo một tin nhắn cho QTV. "" = đã gửi.
func report(message: Dictionary, reason: String) -> String:
	var r: Dictionary = await online.call_rpc("chat_report", {
		"target_id": message.get("sender_id", ""), "reason": reason, "channel_id": message.get("channel_id", ""),
		"message_id": message.get("id", ""), "text": message.get("text", "")})
	return "" if r["ok"] else "CHAT_ERR_SEND"


# ---------- Chưa đọc ----------

func total_unread() -> int:
	var n := 0
	for k in unread:
		n += int(unread[k])
	return n


func mark_read(peer: String) -> void:
	if not unread.has(peer):
		return
	unread.erase(peer)
	unread_changed.emit()
	_delete_notes(peer)


func _delete_notes(peer: String) -> void:
	var ids: Array = _note_ids.get(peer, [])
	_note_ids.erase(peer)
	if ids.is_empty() or online == null:
		return
	await online.call_api(func(url: String, tok: String) -> Dictionary: return NakamaApi.notifications_delete(url, tok, ids))


## Thông báo còn lưu từ lúc offline: tin nhắn riêng chưa đọc, lời mời kết bạn.
func _load_notifications() -> void:
	var res: Dictionary = await online.call_api(
			func(url: String, tok: String) -> Dictionary: return NakamaApi.notifications_list(url, tok))
	var r := NakamaApi.parse_notifications(int(res.get("code", 0)), str(res.get("body", "")))
	if not r["ok"]:
		return
	for n in r["notifications"]:
		_on_notification(n)


## Những người có thể nhắn riêng: bạn bè, người đang chờ đọc, người từng nhắn (không gồm người bị chặn).
func dm_peers() -> Array:
	var seen := {}
	var out: Array = []
	for f in friends:
		if f["state"] == NakamaApi.FRIEND_MUTUAL:
			seen[f["id"]] = true
			out.append({"id": f["id"], "username": f["username"], "online": f["online"]})
	var extra := unread.keys()
	for ch in history:
		var p := NakamaApi.dm_peer(str(ch), me())
		if not p.is_empty():
			extra.append(p)
	for id in extra:
		if not seen.has(id) and not blocked.has(id):
			seen[id] = true
			out.append({"id": id, "username": str(names.get(id, "?")), "online": false})
	return out


func _set_state(s: State) -> void:
	if state == s:
		return
	state = s
	state_changed.emit(s)


## Phản hồi của một gói tin (chờ bằng `await reply.done`).
class _Reply:
	extends RefCounted
	signal done(env: Dictionary)
