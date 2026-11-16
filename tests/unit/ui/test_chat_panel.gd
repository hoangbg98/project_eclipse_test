extends GdUnitTestSuite
## Test bảng Chat (M9-6) và biểu tượng Chat ở sảnh: khóa khi chưa đăng nhập, tin nhắn, gửi, chọn tên → nhắn riêng / kết bạn /
## chặn / báo cáo, quản lý bạn bè, chấm chưa đọc. Máy chủ + socket giả (không dùng mạng).

const SERVICE_SCRIPT := preload("res://scripts/online/online_service.gd")
const HUB_SCENE := preload("res://scenes/main/hub.tscn")
const ROOT := "user://test_chat_panel"
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


func _service(name_: String, login := true) -> Node:
	var s: Node = auto_free(SERVICE_SCRIPT.new())
	s.config = OnlineConfig.load_from(OnlineConfig.DATA_PATH, ROOT.path_join(name_ + ".cfg"))
	s.config.server_key = FakeNakama.SERVER_KEY
	s.device_file = ROOT.path_join(name_ + "_device.cfg")
	s.session_file = ROOT.path_join(name_ + "_session.cfg")
	s.chat_auto_start = false
	s.transport = fake.handle
	add_child(s)
	s.chat.socket_factory = fake.socket_factory
	s.chat.clock = func() -> float: return _now
	if login:
		assert_bool(await s.login_account(name_, "matkhau123", false)).is_true()
		s.chat.start()
		await _until(func() -> bool: return s.chat.world_id != "" and s.chat.state == ChatService.State.ONLINE)
		await await_idle_frame()
		await await_idle_frame()
	return s


func _panel(service: Node) -> ChatPanel:
	var p := ChatPanel.new()
	p.service = service
	p.navigate = false
	add_child(auto_free(p))
	await await_idle_frame()
	await await_idle_frame()
	return p


func _until(cond: Callable, frames := 240) -> void:
	for i in frames:
		if cond.call():
			return
		await await_idle_frame()
	fail("hết thời gian chờ")


## Các dòng tin nhắn (không tính dòng "chưa có tin nhắn").
func _rows(p: ChatPanel) -> Array:
	return p.find_child("Messages", true, false).get_children().filter(func(c: Node) -> bool: return c is HBoxContainer)


func test_locked_when_not_logged_in() -> void:
	var s := await _service("alice", false)
	var p := await _panel(s)
	assert_bool((p.find_child("LockedBox", true, false) as Control).visible).is_true()
	assert_bool((p.find_child("TabWorld", true, false) as Control).is_visible_in_tree()).is_false()
	p.find_child("LoginButton", true, false).pressed.emit()   # navigate = false: không đổi màn


func test_world_messages_and_send() -> void:
	var a := await _service("alice")
	var b := await _service("bob")
	var pa := await _panel(a)
	assert_bool((pa.find_child("LockedBox", true, false) as Control).visible).is_false()
	assert_bool((pa.find_child("Input", true, false) as LineEdit).editable).is_true()
	(pa.find_child("Input", true, false) as LineEdit).text = "xin chào mọi người"
	assert_str(await pa.send_text("xin chào mọi người")).is_empty()
	assert_str((pa.find_child("Input", true, false) as LineEdit).text).is_empty()
	await _until(func() -> bool: return b.chat.messages(WORLD).size() == 1 and _rows(pa).size() == 1)
	var row: Node = _rows(pa)[0]
	assert_str((row.find_child("Name", true, false) as Button).text).is_equal("alice")
	assert_str((row.find_child("Text", true, false) as Label).text).is_equal("xin chào mọi người")
	assert_bool((row.find_child("Name", true, false) as Button).disabled).is_true()   # tên của chính mình không bấm được
	assert_str(await pa.send_text("")).is_equal("CHAT_ERR_EMPTY")
	assert_str((pa.find_child("Status", true, false) as Label).text).is_equal(tr("CHAT_ERR_EMPTY"))


func test_select_name_actions_dm_friend_block_report() -> void:
	var a := await _service("alice")
	var b := await _service("bob")
	assert_str(await a.chat.send_world("tin của alice")).is_empty()
	var pb := await _panel(b)
	await _until(func() -> bool: return _rows(pb).size() == 1)
	var name_btn := (_rows(pb)[0].find_child("Name", true, false) as Button)
	assert_bool(name_btn.disabled).is_false()
	name_btn.pressed.emit()
	await await_idle_frame()
	await await_idle_frame()
	var bar: Control = pb.find_child("ActionBar", true, false)
	assert_bool(bar.visible).is_true()
	for n in ["ActDm", "ActFriend", "ActBlock", "ActReport"]:
		assert_object(bar.find_child(n, true, false)).is_not_null()
	# báo cáo
	bar.find_child("ActReport", true, false).pressed.emit()
	await await_idle_frame()
	assert_object(bar.find_child("Reason_abuse", true, false)).is_not_null()
	assert_str(await pb.report_selected("abuse")).is_empty()
	assert_int(fake.reports.size()).is_equal(1)
	assert_str((pb.find_child("Status", true, false) as Label).text).is_equal(tr("CHAT_REPORTED"))
	# kết bạn từ thanh hành động
	name_btn = (_rows(pb)[0].find_child("Name", true, false) as Button)
	name_btn.pressed.emit()
	await await_idle_frame()
	await await_idle_frame()
	pb.find_child("ActFriend", true, false).pressed.emit()
	await _until(func() -> bool: return b.chat.friend_state(a.user_id()) == NakamaApi.FRIEND_INVITE_SENT)
	# nhắn riêng từ thanh hành động
	name_btn = (_rows(pb)[0].find_child("Name", true, false) as Button)
	name_btn.pressed.emit()
	await await_idle_frame()
	await await_idle_frame()
	pb.find_child("ActDm", true, false).pressed.emit()
	await _until(func() -> bool: return pb.tab == ChatPanel.Tab.DM and pb.dm_peer == a.user_id())
	await _until(func() -> bool: return (pb.find_child("Title", true, false) as Label).text.contains("alice"))
	# chặn
	pb.show_world()
	await await_idle_frame()
	await await_idle_frame()
	(_rows(pb)[0].find_child("Name", true, false) as Button).pressed.emit()
	await await_idle_frame()
	await await_idle_frame()
	pb.find_child("ActBlock", true, false).pressed.emit()
	await _until(func() -> bool: return b.chat.blocked.has(a.user_id()))
	await await_idle_frame()
	await await_idle_frame()
	assert_array(_rows(pb)).is_empty()   # tin của người bị chặn biến mất


func test_direct_message_via_panel_and_unread_in_list() -> void:
	var a := await _service("alice")
	var b := await _service("bob")
	var pa := await _panel(a)
	var pb := await _panel(b)
	await pa.open_dm(b.user_id(), "bob")
	assert_str(await pa.send_text("chào bob")).is_empty()
	await _until(func() -> bool: return b.chat.total_unread() == 1)
	await await_idle_frame()
	await await_idle_frame()
	var peer_btn := pb.find_child("Peer_" + a.user_id(), true, false) as Button
	assert_object(peer_btn).is_not_null()
	assert_str(peer_btn.text).contains("[1]")
	peer_btn.pressed.emit()
	await _until(func() -> bool: return pb.tab == ChatPanel.Tab.DM and _rows(pb).size() == 1)
	assert_int(b.chat.total_unread()).is_equal(0)
	assert_str((_rows(pb)[0].find_child("Text", true, false) as Label).text).is_equal("chào bob")


func test_friends_tab_add_accept_remove() -> void:
	var a := await _service("alice")
	var b := await _service("bob")
	var pa := await _panel(a)
	var pb := await _panel(b)
	pa.show_friends()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool((pa.find_child("AddFriendButton", true, false) as Control).is_visible_in_tree()).is_true()
	(pa.find_child("FriendCode", true, false) as LineEdit).text = "11110002"
	assert_str(await pa.add_friend_from_input()).is_empty()
	assert_str((pa.find_child("FriendResult", true, false) as Label).text).is_equal(tr("CHAT_FRIEND_SENT"))
	(pa.find_child("FriendCode", true, false) as LineEdit).text = "00000000"
	assert_str(await pa.add_friend_from_input()).is_equal("CHAT_ERR_NOT_FOUND")
	await await_idle_frame()
	await await_idle_frame()
	assert_object(pa.find_child("Friend_" + b.user_id(), true, false)).is_not_null()
	assert_object(pa.find_child("Cancel", true, false)).is_not_null()
	# bob thấy lời mời và chấp nhận
	await b.chat.refresh_friends()
	pb.show_friends()
	await await_idle_frame()
	await await_idle_frame()
	assert_str((pb.find_child("TabFriends", true, false) as Button).text).contains("(1)")
	pb.find_child("Accept", true, false).pressed.emit()
	await _until(func() -> bool: return b.chat.friend_state(a.user_id()) == NakamaApi.FRIEND_MUTUAL)
	await await_idle_frame()
	await await_idle_frame()
	assert_object(pb.find_child("Message", true, false)).is_not_null()
	pb.find_child("Remove", true, false).pressed.emit()
	await _until(func() -> bool: return b.chat.friend_state(a.user_id()) == -1)


func test_hub_has_chat_icon_tab_and_unread_badge() -> void:
	var hub := HUB_SCENE.instantiate()
	add_child(auto_free(hub))
	await get_tree().process_frame
	var home := hub.panel as HubHomePanel
	var icon := home.icon_buttons.get("chat") as Button
	assert_object(icon).is_not_null()
	assert_float(icon.get_global_rect().end.x).is_less(1700.0)   # nằm bên trái nút đổi nền
	icon.pressed.emit()
	assert_str(hub.current_tab).is_equal("ChatTab")
	assert_bool(hub.panel is ChatPanel).is_true()
	assert_bool(hub.intercept_back()).is_true()
	# chấm đỏ theo chat của autoload OnlineService
	var online: Node = get_tree().root.get_node("OnlineService")
	assert_object(home.chat_badge).is_not_null()
	var old: Dictionary = online.chat.unread
	online.chat.unread = {"someone": 2}
	home.update_chat_badge()
	assert_bool(home.chat_badge.visible).is_true()
	online.chat.unread = {}
	home.update_chat_badge()
	assert_bool(home.chat_badge.visible).is_false()
	online.chat.unread = old
