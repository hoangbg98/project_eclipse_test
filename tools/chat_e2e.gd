extends SceneTree
## Kiểm tra thật chat (M9-6): hai tài khoản tạo mới chat với nhau qua websocket tới máy chủ đang chạy (không nằm trong
## run_tests vì cần máy chủ). Chạy:
##   <godot> --headless --path . --script res://tools/chat_e2e.gd -- --server=https://xxx.trycloudflare.com
## Không có --server thì dùng địa chỉ mặc định trong data/config/online_config.json. Mã thoát 0 = đạt.
## Kiểm: kết nối + vào phòng thế giới, gửi / nhận, lọc từ, kết bạn (mời → chấp nhận), nhắn riêng + chưa đọc + trả lời,
## chặn (hết nhận tin ở phòng chung, nhắn riêng bị từ chối), báo cáo.

const SERVICE_SCRIPT := preload("res://scripts/online/online_service.gd")

var _fails := 0
var _server := ""


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String, detail := "") -> void:
	print(("  ĐẠT  " if ok else "  LỖI  ") + what + ("" if ok else "  (" + detail + ")"))
	if not ok:
		_fails += 1


## Phòng thế giới có lịch sử chung (tin của các lần chạy trước): kiểm theo nội dung, không đếm số tin.
func _has_text(chat: ChatService, channel: String, text: String) -> bool:
	return chat.messages(channel).any(func(m: Dictionary) -> bool: return m["text"] == text)


func _from(chat: ChatService, channel: String, sender: String) -> int:
	return chat.messages(channel).filter(func(m: Dictionary) -> bool: return m["sender_id"] == sender).size()


func _until(cond: Callable, secs := 8.0) -> bool:
	var t := 0.0
	while t < secs:
		if cond.call():
			return true
		await create_timer(0.05).timeout
		t += 0.05
	return cond.call()


func _player(label: String, stamp: String) -> Node:
	var s: Node = SERVICE_SCRIPT.new()
	s.config = OnlineConfig.load_from(OnlineConfig.DATA_PATH, "user://chat_e2e_%s.cfg" % label)
	if not _server.is_empty():
		s.config.server_url = NakamaApi.normalize_url(_server)
	s.device_file = "user://chat_e2e_%s_device.cfg" % label
	s.session_file = "user://chat_e2e_%s_session.cfg" % label
	s.chat_auto_start = false
	root.add_child(s)
	var name_ := "ce%s%s" % [label, stamp]
	var ok: bool = await s.register(name_, name_ + "@example.com", "matkhau123", "matkhau123", false)
	_check(ok, "tạo tài khoản %s" % name_, str(s.last_error))
	s.chat.start()
	var online: bool = await _until(func() -> bool: return s.chat.state == ChatService.State.ONLINE and s.chat.world_id != "")
	_check(online, "%s: kết nối chat (websocket) và vào phòng world" % name_)
	await create_timer(0.5).timeout   # chờ tải bạn bè + thông báo
	return s


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--server="):
			_server = a.trim_prefix("--server=")
	var stamp := str(int(Time.get_unix_time_from_system()) % 1000000)
	print("Máy chủ: ", _server if not _server.is_empty() else "(mặc định)")
	var a: Node = await _player("a", stamp)
	var b: Node = await _player("b", stamp)
	var ca: ChatService = a.chat
	var cb: ChatService = b.chat
	var world := ca.world_id
	_check(world == "2...world", "id phòng thế giới", world)

	# --- phòng thế giới
	_check(await ca.send_world("xin chào cả nhà " + stamp) == "", "A gửi vào phòng thế giới")
	_check(await _until(func() -> bool: return _has_text(cb, world, "xin chào cả nhà " + stamp)), "B nhận được tin của A")
	await create_timer(1.0).timeout
	_check(await ca.send_world("đm lớn quá " + stamp) == "", "A gửi tin có từ cấm")
	_check(await _until(func() -> bool: return _has_text(cb, world, "** lớn quá " + stamp)), "máy chủ che từ cấm (giữ nguyên 'lớn')")
	_check(await ca.send_world("gửi liền tay") == "CHAT_ERR_RATE", "gửi quá nhanh bị chặn ở máy")

	# --- bạn bè
	var code_b := str(b.profile.get("code", ""))
	_check(await ca.add_friend_by_code(code_b) == "", "A kết bạn với B theo mã " + NakamaApi.format_code(code_b))
	await cb.refresh_friends()
	_check(cb.friend_state(ca.me()) == NakamaApi.FRIEND_INVITE_RECEIVED, "B thấy lời mời của A")
	_check(await cb.add_friend(ca.me()) == "", "B chấp nhận")
	await ca.refresh_friends()
	_check(ca.friend_state(cb.me()) == NakamaApi.FRIEND_MUTUAL, "hai người đã là bạn")

	# --- nhắn riêng
	await create_timer(1.0).timeout
	var dm := await ca.open_dm(cb.me(), b.username())
	_check(dm.begins_with("4."), "A mở kênh nhắn riêng", dm)
	_check(await ca.send_dm(cb.me(), "chào B, nhắn riêng nè") == "", "A gửi nhắn riêng")
	_check(await _until(func() -> bool: return cb.total_unread() == 1), "B thấy 1 tin chưa đọc (thông báo)", str(cb.unread))
	var dmb := await cb.open_dm(ca.me())
	_check(dmb == dm, "B vào cùng kênh nhắn riêng")
	_check(cb.messages(dmb).size() == 1 and cb.messages(dmb)[0]["text"] == "chào B, nhắn riêng nè", "B đọc được tin (lịch sử)")
	_check(cb.total_unread() == 0, "mở cuộc nhắn thì hết chưa đọc")
	await create_timer(1.0).timeout
	_check(await cb.send_dm(ca.me(), "B trả lời") == "", "B trả lời")
	_check(await _until(func() -> bool: return ca.messages(dm).size() == 2), "A nhận trả lời trực tiếp")

	# --- chặn + báo cáo
	await create_timer(1.0).timeout
	_check(await ca.send_world("tin sau cùng của A " + stamp) == "", "A gửi thêm vào phòng chung")
	await _until(func() -> bool: return _has_text(cb, world, "tin sau cùng của A " + stamp))
	var last_a: Dictionary = cb.messages(world).filter(func(m: Dictionary) -> bool: return m["sender_id"] == ca.me()).back()
	_check(await cb.report(last_a, "abuse") == "", "B báo cáo A")
	_check(await cb.block(ca.me()) == "", "B chặn A")
	_check(_from(cb, world, ca.me()) == 0, "tin của A biến mất khỏi phòng chung của B")
	await create_timer(1.0).timeout
	_check(await ca.send_world("A nói tiếp " + stamp) == "", "A vẫn gửi được vào phòng chung")
	await create_timer(0.6).timeout
	_check(_from(cb, world, ca.me()) == 0 and not _has_text(cb, world, "A nói tiếp " + stamp), "B không nhận tin của A nữa",
			"blocked=%s, từ A=%d, gồm 'A nói tiếp'=%s" % [cb.blocked, _from(cb, world, ca.me()), _has_text(cb, world, "A nói tiếp " + stamp)])
	await create_timer(1.0).timeout
	_check(await ca.send_dm(cb.me(), "nhắn riêng khi bị chặn") == "CHAT_ERR_BLOCKED", "A không nhắn riêng được cho B")

	a.logout()
	b.logout()
	print("ĐẠT" if _fails == 0 else "CÓ %d BƯỚC LỖI" % _fails)
	quit(0 if _fails == 0 else 1)
