extends GdUnitTestSuite
## Test ChatService (M9-6) với máy chủ giả + socket giả: kết nối, phòng thế giới, nhắn riêng, chưa đọc / thông báo,
## bạn bè, chặn, báo cáo, lỗi máy chủ, tự nối lại.

const SERVICE_SCRIPT := preload("res://scripts/online/online_service.gd")
const ROOT := "user://test_chat"
const WORLD := "2...world"

var fake: FakeNakama
var _now := 100.0


func before_test() -> void:
	fake = FakeNakama.new()
	fake.add_account("alice", "a@example.com", "matkhau123", "11110001")
	fake.add_account("bob", "b@example.com", "matkhau123", "11110002")
	_now = 100.0
	OnlineTestKit.remove_tree(ROOT)


func after_test() -> void:
	OnlineTestKit.remove_tree(ROOT)


## Một người chơi đã đăng nhập (chưa bật chat).
func _player(name_: String) -> Node:
	var s: Node = auto_free(SERVICE_SCRIPT.new())
	s.config = OnlineConfig.load_from(OnlineConfig.DATA_PATH, ROOT.path_join(name_ + ".cfg"))
	s.config.server_key = FakeNakama.SERVER_KEY
	s.device_file = ROOT.path_join(name_ + "_device.cfg")
	s.session_file = ROOT.path_join(name_ + "_session.cfg")
	s.chat_auto_start = false
	s.transport = fake.handle
	add_child(s)
	assert_bool(await s.login_account(name_, "matkhau123", false)).is_true()
	s.chat.socket_factory = fake.socket_factory
	s.chat.clock = func() -> float: return _now
	return s


## Người chơi đã đăng nhập, chat đã vào phòng thế giới và tải xong bạn bè.
func _online(name_: String) -> ChatService:
	var s := await _player(name_)
	s.chat.start()
	await _until(func() -> bool: return s.chat.world_id != "" and s.chat.state == ChatService.State.ONLINE)
	await await_idle_frame()
	await await_idle_frame()
	return s.chat


func _until(cond: Callable, frames := 240) -> void:
	for i in frames:
		if cond.call():
			return
		await await_idle_frame()
	fail("hết thời gian chờ")


func _advance() -> void:
	_now += 2.0


func _texts(chat: ChatService, channel: String) -> Array:
	return chat.messages(channel).map(func(m: Dictionary) -> String: return m["text"])


func test_connects_joins_world_and_loads_history() -> void:
	fake.channel_log[WORLD] = [
		{"channel_id": WORLD, "message_id": "h1", "code": 0, "sender_id": "x", "username": "cu", "content": '{"text":"tin cũ"}',
				"create_time": "2026-11-16T08:00:00.000000000Z"},
		{"channel_id": WORLD, "message_id": "h2", "code": 0, "sender_id": "x", "username": "cu", "content": '{"text":"tin mới hơn"}',
				"create_time": "2026-11-16T08:01:00.000000000Z"}]
	var chat := await _online("alice")
	assert_str(chat.world_id).is_equal(WORLD)
	assert_array(_texts(chat, WORLD)).is_equal(["tin cũ", "tin mới hơn"])
	assert_bool(chat.is_connected_to_chat()).is_true()
	assert_str((fake.sockets[0] as FakeSocket).url).starts_with("ws://127.0.0.1:7360/ws?format=json&token=")


func test_world_message_reaches_everyone_including_sender() -> void:
	var a := await _online("alice")
	var b := await _online("bob")
	assert_str(await a.send_world("xin chào cả nhà")).is_empty()
	await _until(func() -> bool: return b.messages(WORLD).size() == 1 and a.messages(WORLD).size() == 1)
	assert_str(b.messages(WORLD)[0]["text"]).is_equal("xin chào cả nhà")
	assert_str(b.messages(WORLD)[0]["username"]).is_equal("alice")
	assert_str(a.messages(WORLD)[0]["sender_id"]).is_equal(a.me())


func test_send_validation_and_server_errors() -> void:
	var a := await _online("alice")
	assert_str(await a.send_world("   ")).is_equal("CHAT_ERR_EMPTY")
	assert_str(await a.send_world("x".repeat(201))).is_equal("CHAT_ERR_TOO_LONG")
	assert_str(await a.send_world("một")).is_empty()
	assert_str(await a.send_world("hai ngay sau")).is_equal("CHAT_ERR_RATE")   # chưa đủ giãn cách
	_advance()
	fake.chat_error_next = "chat_rate"
	assert_str(await a.send_world("ba")).is_equal("CHAT_ERR_RATE")   # máy chủ chặn
	_advance()
	fake.muted["alice"] = 1794780000000
	assert_str(await a.send_world("bốn")).is_equal("CHAT_ERR_MUTED")
	assert_int(a.muted_until).is_equal(1794780000000)
	fake.muted.erase("alice")
	_advance()
	assert_str(await a.send_world("năm")).is_empty()


func test_dm_notification_unread_and_open() -> void:
	var a := await _online("alice")
	var b := await _online("bob")
	var bob_id := b.me()
	var alice_id := a.me()
	assert_str(await a.send_dm(bob_id, "chào bob")).is_empty()
	await _until(func() -> bool: return b.total_unread() == 1)
	assert_int(b.unread[alice_id]).is_equal(1)
	assert_str(b.names[alice_id]).is_equal("alice")
	# bob tự vào kênh nhắn riêng nên tin kế tiếp tới trực tiếp và tính chưa đọc
	_advance()
	assert_str(await a.send_dm(bob_id, "tin thứ hai")).is_empty()
	await _until(func() -> bool: return b.total_unread() == 2)
	# bob mở cuộc nhắn: tải lịch sử, hết chưa đọc, thông báo trên máy chủ bị xóa
	var channel := await b.open_dm(alice_id)
	assert_str(channel).is_not_empty()
	assert_array(_texts(b, channel)).is_equal(["chào bob", "tin thứ hai"])
	assert_int(b.total_unread()).is_equal(0)
	await _until(func() -> bool: return fake.counters["note_deleted"] >= 1)
	# trả lời; alice đang mở cuộc nhắn với bob nên không tính chưa đọc
	a.active_peer = bob_id
	_advance()
	assert_str(await b.send_dm(alice_id, "chào alice")).is_empty()
	await _until(func() -> bool: return a.messages(channel).size() == 3)
	assert_int(a.total_unread()).is_equal(0)


func test_unread_from_offline_notifications_on_login() -> void:
	var a := await _online("alice")
	var bob := await _player("bob")   # bob chưa bật chat
	assert_str(await a.send_dm(bob.user_id(), "bob ơi")).is_empty()
	_advance()
	assert_str(await a.send_dm(bob.user_id(), "bob ơi 2")).is_empty()
	bob.chat.start()
	await _until(func() -> bool: return bob.chat.total_unread() > 0)
	assert_str(bob.chat.names[a.me()]).is_equal("alice")
	assert_bool(bob.chat.dm_peers().any(func(p: Dictionary) -> bool: return p["id"] == a.me())).is_true()
	# nhắn riêng "muốn nhắn" (mã -1) không được tính thành tin chưa đọc
	assert_int(bob.chat.unread[a.me()]).is_equal(2)


func test_friend_flow() -> void:
	var a := await _online("alice")
	var b := await _online("bob")
	assert_str(await a.add_friend_by_code("1111 0002")).is_empty()
	assert_int(a.friend_state(b.me())).is_equal(NakamaApi.FRIEND_INVITE_SENT)
	await b.refresh_friends()
	assert_int(b.friend_state(a.me())).is_equal(NakamaApi.FRIEND_INVITE_RECEIVED)
	assert_str(await b.add_friend(a.me())).is_empty()   # chấp nhận
	assert_int(b.friend_state(a.me())).is_equal(NakamaApi.FRIEND_MUTUAL)
	await a.refresh_friends()
	assert_int(a.friend_state(b.me())).is_equal(NakamaApi.FRIEND_MUTUAL)
	assert_bool(a.dm_peers().any(func(p: Dictionary) -> bool: return p["id"] == b.me() and p["online"])).is_true()
	assert_str(await a.remove_friend(b.me())).is_empty()
	assert_int(a.friend_state(b.me())).is_equal(-1)
	assert_str(await a.add_friend_by_code("99999999")).is_equal("CHAT_ERR_NOT_FOUND")
	assert_str(await a.add_friend_by_code("11110001")).is_equal("CHAT_ERR_SELF")


func test_block_hides_world_messages_and_blocks_dm() -> void:
	var a := await _online("alice")
	var b := await _online("bob")
	assert_str(await a.send_world("trước khi chặn")).is_empty()
	await _until(func() -> bool: return b.messages(WORLD).size() == 1)
	assert_str(await b.block(a.me())).is_empty()
	assert_bool(b.blocked.has(a.me())).is_true()
	assert_array(_texts(b, WORLD)).is_empty()   # tin cũ của người bị chặn bị ẩn
	_advance()
	assert_str(await a.send_world("sau khi chặn")).is_empty()
	await _until(func() -> bool: return a.messages(WORLD).size() == 2)
	assert_array(_texts(b, WORLD)).is_empty()
	# nhắn riêng: máy chủ từ chối
	_advance()
	assert_str(await a.send_dm(b.me(), "nhắn riêng")).is_equal("CHAT_ERR_BLOCKED")
	# bỏ chặn: Nakama đã đẩy alice khỏi kênh, game tự vào lại và gửi lại
	assert_str(await b.remove_friend(a.me())).is_empty()
	assert_bool(b.blocked.is_empty()).is_true()
	_advance()
	assert_str(await a.send_dm(b.me(), "làm lành nhé")).is_empty()
	await _until(func() -> bool: return b.total_unread() >= 1)


func test_report() -> void:
	var a := await _online("alice")
	var b := await _online("bob")
	assert_str(await a.send_world("lời lẽ không hay")).is_empty()
	await _until(func() -> bool: return b.messages(WORLD).size() == 1)
	assert_str(await b.report(b.messages(WORLD)[0], "abuse")).is_empty()
	assert_int(fake.reports.size()).is_equal(1)
	assert_str(fake.reports[0]["target_id"]).is_equal(a.me())
	assert_str(fake.reports[0]["reason"]).is_equal("abuse")
	assert_str(fake.reports[0]["text"]).is_equal("lời lẽ không hay")


func test_reconnects_after_drop_and_stops_on_logout() -> void:
	var a := await _online("alice")
	var attempts := fake.socket_attempts
	(fake.sockets[0] as FakeSocket).drop()
	await _until(func() -> bool: return a.state == ChatService.State.OFF)
	assert_str(await a.send_world("mất mạng")).is_equal("CHAT_ERR_OFFLINE")
	a._retry_in = 0.05
	await _until(func() -> bool: return a.state == ChatService.State.ONLINE and a.world_id != "")
	assert_int(fake.socket_attempts).is_greater(attempts)
	a.stop()
	assert_int(a.state).is_equal(ChatService.State.OFF)
	assert_array(a.history.keys()).is_empty()
	assert_int(fake.sockets.size()).is_equal(0)
	await await_idle_frame()
	assert_int(a.state).is_equal(ChatService.State.OFF)   # không tự nối lại sau khi dừng


func test_logout_stops_chat() -> void:
	var s := await _player("alice")
	s.chat.start()
	await _until(func() -> bool: return s.chat.state == ChatService.State.ONLINE)
	s.logout()
	assert_int(s.chat.state).is_equal(ChatService.State.OFF)
	assert_int(fake.sockets.size()).is_equal(0)
