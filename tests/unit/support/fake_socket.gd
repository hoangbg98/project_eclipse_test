class_name FakeSocket
extends RefCounted
## WebSocket giả cho test chat (M9-6): cùng giao diện với WebSocketPeer (phần ChatService dùng). Gói tin đi qua
## FakeNakama (máy chủ giả); phản hồi được xếp hàng và chỉ tới khi `poll()` như socket thật.

var hub: FakeNakama
var user := ""
var url := ""
var state := WebSocketPeer.STATE_CLOSED
var inbox: Array[String] = []
## Các gói tin game đã gửi (đã parse).
var sent: Array = []
var _drop := false


func connect_to_url(u: String) -> int:
	url = u
	user = hub.user_from_ws_url(u)
	hub.socket_attempts += 1
	if user.is_empty() or hub.down:
		return ERR_CANT_CONNECT
	state = WebSocketPeer.STATE_CONNECTING
	hub.sockets.append(self)
	return OK


func poll() -> void:
	if state == WebSocketPeer.STATE_CONNECTING:
		state = WebSocketPeer.STATE_OPEN
	elif _drop and state == WebSocketPeer.STATE_OPEN:
		state = WebSocketPeer.STATE_CLOSED
		hub.sockets.erase(self)


func get_ready_state() -> int:
	return state


func get_available_packet_count() -> int:
	return inbox.size()


func get_packet() -> PackedByteArray:
	return inbox.pop_front().to_utf8_buffer()


func send_text(text: String) -> int:
	sent.append(JSON.parse_string(text))
	hub.on_socket_text(self, text)
	return OK


func close(_code := 1000, _reason := "") -> void:
	state = WebSocketPeer.STATE_CLOSED
	hub.sockets.erase(self)


## Test: mô phỏng rớt mạng (lần poll kế tiếp socket đóng).
func drop() -> void:
	_drop = true


func push(env: Dictionary) -> void:
	inbox.append(JSON.stringify(env))
