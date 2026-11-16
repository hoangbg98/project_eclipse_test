class_name ChatPanel
extends HBoxContainer
## Bảng Chat (M9-6), mở từ biểu tượng bong bóng ở sảnh (bảng nổi "ChatTab" của Hub). Cột trái: Thế giới, danh sách nhắn riêng
## (có chấm chưa đọc), Bạn bè. Cột phải: tin nhắn + ô nhập, hoặc quản lý bạn bè (thêm theo mã, chấp nhận, chặn...).
## Bấm tên người gửi để Nhắn riêng / Kết bạn / Chặn / Báo cáo. Panel chỉ đọc state của ChatService và nghe signal.

enum Tab { WORLD, DM, FRIENDS }

const SHOW_MESSAGES := 100
const REPORT_REASONS := ["spam", "abuse", "inappropriate", "cheat", "other"]

## Test gán OnlineService giả; null = autoload.
var service: Node
var tab := Tab.WORLD
var dm_peer := ""
## Tin đang được chọn để Nhắn riêng / Kết bạn / Chặn / Báo cáo.
var selected: Dictionary = {}
## false: không chuyển scene thật (test).
var navigate := true

var chat: ChatService
var _dirty := false
var _title: Label
var _status: Label
var _peer_box: VBoxContainer
var _friends_btn: Button
var _world_btn: Button
var _messages_pane: VBoxContainer
var _scroll: ScrollContainer
var _list: VBoxContainer
var _action_bar: VBoxContainer
var _input: LineEdit
var _send: Button
var _friends_pane: VBoxContainer
var _friend_list: VBoxContainer
var _friend_code: LineEdit
var _friend_result: Label
var _lock_msg: VBoxContainer
var _left: VBoxContainer
var _right: VBoxContainer


func _ready() -> void:
	if service == null:
		service = UiKit.autoload("OnlineService")
	add_theme_constant_override("separation", 24)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build()
	if service and service.chat:
		chat = service.chat
		for sig: Signal in [chat.state_changed, chat.friends_changed, chat.unread_changed, chat.history_loaded]:
			sig.connect(func(_a: Variant = null) -> void: queue_refresh())
		chat.message_received.connect(func(_c: String, _m: Dictionary) -> void: queue_refresh())
		chat.notice.connect(func(key: String) -> void: _status.text = tr(key))
		if chat.is_connected_to_chat():
			chat.refresh_friends()
	show_world()


# ---------- Điều hướng ----------

func show_world() -> void:
	tab = Tab.WORLD
	dm_peer = ""
	selected = {}
	if chat:
		chat.close_dm()
	queue_refresh()


func show_friends() -> void:
	tab = Tab.FRIENDS
	dm_peer = ""
	selected = {}
	if chat:
		chat.close_dm()
		chat.refresh_friends()
	queue_refresh()


## Mở cuộc nhắn riêng với `peer` (tải lịch sử, đánh dấu đã đọc).
func open_dm(peer: String, peer_name := "") -> void:
	tab = Tab.DM
	dm_peer = peer
	selected = {}
	if chat:
		await chat.open_dm(peer, peer_name)
	queue_refresh()


func select_message(msg: Dictionary) -> void:
	selected = msg if str(msg.get("sender_id", "")) != chat.me() else {}
	queue_refresh()


# ---------- Hành động ----------

## Gửi nội dung ô nhập (Enter / nút Gửi). Trả về khóa dịch của lỗi, "" nếu thành công.
func send_text(text: String) -> String:
	if chat == null:
		return "CHAT_ERR_OFFLINE"
	var err: String
	if tab == Tab.DM:
		err = await chat.send_dm(dm_peer, text)
	else:
		err = await chat.send_world(text)
	if err.is_empty():
		_input.text = ""
		_status.text = ""
	else:
		_status.text = _error_text(err)
	return err


func _error_text(key: String) -> String:
	if key == "CHAT_ERR_MUTED" and chat.muted_until > 0:
		var t := Time.get_datetime_dict_from_unix_time(int(chat.muted_until / 1000) + _tz_offset_sec())
		return tr("CHAT_ERR_MUTED_UNTIL") % ("%02d:%02d %02d/%02d" % [t.hour, t.minute, t.day, t.month])
	return tr(key)


func report_selected(reason: String) -> String:
	if selected.is_empty():
		return "CHAT_ERR_SEND"
	var err: String = await chat.report(selected, reason)
	_status.text = tr("CHAT_REPORTED") if err.is_empty() else tr(err)
	if err.is_empty():
		selected = {}
		queue_refresh()
	return err


func add_friend_from_input() -> String:
	var code := _friend_code.text.strip_edges()
	var err: String = await chat.add_friend_by_code(code)
	_friend_result.text = tr("CHAT_FRIEND_SENT") if err.is_empty() else tr(err)
	if err.is_empty():
		_friend_code.text = ""
	return err


func _login() -> void:
	var router := UiKit.autoload("SceneRouter")
	if navigate and router:
		router.replace(GameConfig.SCENE_LOGIN)


# ---------- Vẽ ----------

func queue_refresh() -> void:
	if _dirty or not is_inside_tree():
		return
	_dirty = true
	_refresh.call_deferred()


func _refresh() -> void:
	_dirty = false
	if not is_inside_tree():
		return
	var usable: bool = service != null and service.is_online() and chat != null
	_lock_msg.visible = not usable
	_left.visible = usable
	_right.visible = usable
	_messages_pane.visible = false
	_friends_pane.visible = false
	if not usable:
		return
	_world_btn.button_pressed = tab == Tab.WORLD
	_friends_btn.button_pressed = tab == Tab.FRIENDS
	var invites := _count_state(NakamaApi.FRIEND_INVITE_RECEIVED)
	_friends_btn.text = tr("CHAT_TAB_FRIENDS") + ("  (%d)" % invites if invites > 0 else "")
	_rebuild_peers()
	var live: bool = chat.is_connected_to_chat()
	match tab:
		Tab.FRIENDS:
			_title.text = tr("CHAT_TAB_FRIENDS")
			_friends_pane.visible = true
			_rebuild_friends()
		Tab.DM:
			_title.text = tr("CHAT_DM_TITLE") % str(chat.names.get(dm_peer, "?"))
			_show_messages(_dm_channel(), live)
		_:
			_title.text = tr("CHAT_TAB_WORLD")
			_show_messages(chat.world_id, live)
	if not live and _status.text.is_empty():
		_status.text = tr("CHAT_CONNECTING")
	elif live and _status.text == tr("CHAT_CONNECTING"):
		_status.text = ""


func _dm_channel() -> String:
	for ch: String in chat.history:
		if NakamaApi.dm_peer(ch, chat.me()) == dm_peer:
			return ch
	return ""


func _count_state(state: int) -> int:
	var n := 0
	for f: Dictionary in chat.friends:
		if f["state"] == state:
			n += 1
	return n


func _rebuild_peers() -> void:
	for c in _peer_box.get_children():
		_peer_box.remove_child(c)
		c.queue_free()
	for p: Dictionary in chat.dm_peers():
		var n := int(chat.unread.get(p["id"], 0))
		var b := UiKit.button("%s%s%s" % ["● " if p["online"] else "", p["username"], "   [%d]" % n if n > 0 else ""], 0.0, 28)
		b.name = "Peer_" + str(p["id"])
		b.custom_minimum_size.y = 72.0
		b.toggle_mode = true
		b.button_pressed = tab == Tab.DM and dm_peer == p["id"]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.pressed.connect(open_dm.bind(p["id"], p["username"]))
		_peer_box.add_child(b)


func _show_messages(channel: String, live: bool) -> void:
	_messages_pane.visible = true
	_input.editable = live
	_send.disabled = not live
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var list: Array = chat.messages(channel)
	for m: Dictionary in list.slice(maxi(0, list.size() - SHOW_MESSAGES)):
		_list.add_child(_message_row(m))
	if list.is_empty():
		_list.add_child(UiKit.label(tr("CHAT_EMPTY"), 26))
	_rebuild_action_bar()
	_scroll_to_end.call_deferred()


func _scroll_to_end() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _message_row(m: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var mine: bool = m["sender_id"] == chat.me()
	var t := Label.new()
	t.text = _clock_text(int(m["time"]))
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", Color("#7F8AA3"))
	t.custom_minimum_size.x = 64
	row.add_child(t)
	var who := Button.new()
	who.name = "Name"
	who.flat = true
	who.text = str(m["username"])
	who.focus_mode = Control.FOCUS_NONE
	who.add_theme_font_size_override("font_size", 26)
	var color := Color("#7FD6FF") if mine else Color("#FFD27F")
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		who.add_theme_color_override(state, color)
	who.disabled = mine
	who.add_theme_color_override("font_disabled_color", color)
	who.pressed.connect(select_message.bind(m))
	row.add_child(who)
	var text := UiKit.label(str(m["text"]), 28)
	text.name = "Text"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	return row


func _clock_text(unix: int) -> String:
	if unix <= 0:
		return "--:--"
	var d := Time.get_datetime_dict_from_unix_time(unix + _tz_offset_sec())
	return "%02d:%02d" % [d.hour, d.minute]


static func _tz_offset_sec() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


func _rebuild_action_bar() -> void:
	for c in _action_bar.get_children():
		_action_bar.remove_child(c)
		c.queue_free()
	_action_bar.visible = not selected.is_empty()
	if selected.is_empty():
		return
	var id := str(selected["sender_id"])
	var row := UiKit.hbox(12)
	var who := UiKit.label(str(selected["username"]), 28)
	who.autowrap_mode = TextServer.AUTOWRAP_OFF
	who.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(who)
	if tab == Tab.WORLD:
		row.add_child(_action_button("ActDm", tr("CHAT_ACT_DM"), open_dm.bind(id, str(selected["username"]))))
	var st: int = chat.friend_state(id)
	if st < 0:
		row.add_child(_action_button("ActFriend", tr("CHAT_ACT_FRIEND"), func() -> void:
			var err: String = await chat.add_friend(id)
			_status.text = tr("CHAT_FRIEND_SENT") if err.is_empty() else tr(err)))
	row.add_child(_action_button("ActBlock", tr("CHAT_ACT_BLOCK"), func() -> void:
		await chat.block(id)
		selected = {}
		queue_refresh()))
	row.add_child(_action_button("ActReport", tr("CHAT_ACT_REPORT"), func() -> void: _show_report_reasons()))
	_action_bar.add_child(row)


func _action_button(node_name: String, text: String, cb: Callable) -> Button:
	var b := UiKit.button(text, 0.0, 24)
	b.name = node_name
	b.custom_minimum_size = Vector2(180, 64)
	b.pressed.connect(cb)
	return b


func _show_report_reasons() -> void:
	if _action_bar.get_node_or_null("ReportRow"):
		return
	var row := UiKit.hbox(10)
	row.name = "ReportRow"
	var lbl := UiKit.label(tr("CHAT_REPORT_REASON"), 24)
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	for r: String in REPORT_REASONS:
		var b := UiKit.button(tr("CHAT_REASON_" + r.to_upper()), 0.0, 22)
		b.name = "Reason_" + r
		b.custom_minimum_size = Vector2(150, 60)
		b.pressed.connect(report_selected.bind(r))
		row.add_child(b)
	_action_bar.add_child(row)


func _rebuild_friends() -> void:
	for c in _friend_list.get_children():
		_friend_list.remove_child(c)
		c.queue_free()
	var order := [NakamaApi.FRIEND_INVITE_RECEIVED, NakamaApi.FRIEND_MUTUAL, NakamaApi.FRIEND_INVITE_SENT, NakamaApi.FRIEND_BLOCKED]
	var heads := {NakamaApi.FRIEND_INVITE_RECEIVED: "CHAT_FRIENDS_INVITES", NakamaApi.FRIEND_MUTUAL: "CHAT_FRIENDS_LIST",
			NakamaApi.FRIEND_INVITE_SENT: "CHAT_FRIENDS_SENT", NakamaApi.FRIEND_BLOCKED: "CHAT_FRIENDS_BLOCKED"}
	for st: int in order:
		var group: Array = chat.friends.filter(func(f: Dictionary) -> bool: return f["state"] == st)
		if group.is_empty():
			continue
		_friend_list.add_child(UiKit.label(tr(heads[st]), 26))
		for f: Dictionary in group:
			_friend_list.add_child(_friend_row(f))
	if chat.friends.is_empty():
		_friend_list.add_child(UiKit.label(tr("CHAT_FRIENDS_EMPTY"), 26))


func _friend_row(f: Dictionary) -> Control:
	var id := str(f["id"])
	var row := UiKit.hbox(12)
	row.name = "Friend_" + id
	var name_label := UiKit.label(("● " if f["online"] else "") + str(f["username"]), 30)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	match int(f["state"]):
		NakamaApi.FRIEND_INVITE_RECEIVED:
			row.add_child(_action_button("Accept", tr("CHAT_FRIEND_ACCEPT"), func() -> void: chat.add_friend(id)))
			row.add_child(_action_button("Decline", tr("CHAT_FRIEND_DECLINE"), func() -> void: chat.remove_friend(id)))
		NakamaApi.FRIEND_MUTUAL:
			row.add_child(_action_button("Message", tr("CHAT_ACT_DM"), open_dm.bind(id, str(f["username"]))))
			row.add_child(_action_button("Remove", tr("CHAT_FRIEND_REMOVE"), func() -> void: chat.remove_friend(id)))
			row.add_child(_action_button("Block", tr("CHAT_ACT_BLOCK"), func() -> void: chat.block(id)))
		NakamaApi.FRIEND_INVITE_SENT:
			row.add_child(_action_button("Cancel", tr("CHAT_FRIEND_CANCEL"), func() -> void: chat.remove_friend(id)))
		NakamaApi.FRIEND_BLOCKED:
			row.add_child(_action_button("Unblock", tr("CHAT_FRIEND_UNBLOCK"), func() -> void: chat.remove_friend(id)))
	return row


# ---------- Dựng khung ----------

func _build() -> void:
	# Chưa đăng nhập.
	_lock_msg = UiKit.vbox(24)
	_lock_msg.name = "LockedBox"
	_lock_msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lock_msg.add_child(UiKit.label(tr("CHAT_NEED_LOGIN"), 34))
	var login := UiKit.button(tr("ONLINE_OPEN_LOGIN"), 480.0, 30)
	login.name = "LoginButton"
	login.custom_minimum_size.y = 96.0
	login.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	login.pressed.connect(_login)
	_lock_msg.add_child(login)
	add_child(_lock_msg)

	# Cột trái.
	var left := UiKit.vbox(12)
	_left = left
	left.custom_minimum_size.x = 420
	_world_btn = UiKit.button(tr("CHAT_TAB_WORLD"), 0.0, 30)
	_world_btn.name = "TabWorld"
	_world_btn.toggle_mode = true
	_world_btn.custom_minimum_size.y = 84.0
	_world_btn.pressed.connect(show_world)
	left.add_child(_world_btn)
	left.add_child(UiKit.label(tr("CHAT_DM_LIST"), 24))
	_peer_box = UiKit.vbox(8)
	_peer_box.name = "Peers"
	left.add_child(UiKit.scroll(_peer_box))
	_friends_btn = UiKit.button(tr("CHAT_TAB_FRIENDS"), 0.0, 30)
	_friends_btn.name = "TabFriends"
	_friends_btn.toggle_mode = true
	_friends_btn.custom_minimum_size.y = 84.0
	_friends_btn.pressed.connect(show_friends)
	left.add_child(_friends_btn)
	add_child(left)

	# Cột phải.
	var right := UiKit.vbox(12)
	_right = right
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title = UiKit.label("", 36)
	_title.name = "Title"
	right.add_child(_title)
	_status = UiKit.label("", 24)
	_status.name = "Status"
	_status.add_theme_color_override("font_color", Color("#FF9E80"))
	right.add_child(_status)

	_messages_pane = UiKit.vbox(10)
	_messages_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list = UiKit.vbox(10)
	_list.name = "Messages"
	_scroll = UiKit.scroll(_list)
	_messages_pane.add_child(_scroll)
	_action_bar = UiKit.vbox(8)
	_action_bar.name = "ActionBar"
	_messages_pane.add_child(_action_bar)
	var input_row := UiKit.hbox(12)
	_input = LineEdit.new()
	_input.name = "Input"
	_input.max_length = NakamaApi.CHAT_MAX_LEN
	_input.placeholder_text = tr("CHAT_INPUT_HINT")
	_input.custom_minimum_size = Vector2(0, 80)
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.add_theme_font_size_override("font_size", 28)
	_input.text_submitted.connect(func(t: String) -> void:
		await send_text(t)
		_input.grab_focus())
	input_row.add_child(_input)
	_send = UiKit.button(tr("CHAT_SEND"), 200.0, 30)
	_send.name = "SendButton"
	_send.custom_minimum_size.y = 80.0
	_send.pressed.connect(func() -> void: send_text(_input.text))
	input_row.add_child(_send)
	_messages_pane.add_child(input_row)
	right.add_child(_messages_pane)

	_friends_pane = UiKit.vbox(12)
	_friends_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_friends_pane.add_child(UiKit.label(tr("CHAT_ADD_BY_CODE"), 26))
	var add_row := UiKit.hbox(12)
	_friend_code = LineEdit.new()
	_friend_code.name = "FriendCode"
	_friend_code.placeholder_text = tr("CHAT_CODE_HINT")
	_friend_code.custom_minimum_size = Vector2(0, 72)
	_friend_code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_friend_code.add_theme_font_size_override("font_size", 28)
	_friend_code.text_submitted.connect(func(_t: String) -> void: add_friend_from_input())
	add_row.add_child(_friend_code)
	var add_btn := UiKit.button(tr("CHAT_ADD_FRIEND"), 220.0, 28)
	add_btn.name = "AddFriendButton"
	add_btn.custom_minimum_size.y = 72.0
	add_btn.pressed.connect(add_friend_from_input)
	add_row.add_child(add_btn)
	_friends_pane.add_child(add_row)
	_friend_result = UiKit.label("", 24)
	_friend_result.name = "FriendResult"
	_friends_pane.add_child(_friend_result)
	_friend_list = UiKit.vbox(10)
	_friend_list.name = "Friends"
	_friends_pane.add_child(UiKit.scroll(_friend_list))
	right.add_child(_friends_pane)
	add_child(right)
