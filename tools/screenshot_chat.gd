extends SceneTree
## Chụp bảng Chat trong Hub với máy chủ thật (cần cửa sổ + máy chủ chạy):  <godot> --path . -s tools/screenshot_chat.gd
## Tạo hai tài khoản tạm (người xem + một người bạn "bob"), gửi vài tin, chụp: sảnh có biểu tượng Chat, phòng thế giới,
## chọn tên, bạn bè, nhắn riêng, chưa đăng nhập. Ảnh ra build/screenshots/chat_<n>.png. Không ghi save / phiên thật.

const SERVICE_SCRIPT := preload("res://scripts/online/online_service.gd")

var _hub: Control
var _bob: Node
var _me: Node


func _initialize() -> void:
	_run.call_deferred()


func _until(cond: Callable, secs := 8.0) -> void:
	var t := 0.0
	while t < secs and not cond.call():
		await create_timer(0.05).timeout
		t += 0.05


func _frames(n := 4) -> void:
	for i in n:
		await process_frame
	await create_timer(0.15).timeout


func _shot(name_: String) -> void:
	var out := "res://build/screenshots/chat_%s.png" % name_
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	root.get_texture().get_image().save_png(out)
	print("saved ", out)


func _run() -> void:
	var stamp := str(int(Time.get_unix_time_from_system()) % 1000000)
	_me = root.get_node("OnlineService")
	_me.session_file = "user://shot_chat_session.cfg"
	_me.chat_auto_start = false
	_bob = SERVICE_SCRIPT.new()
	_bob.config = OnlineConfig.load_from()
	_bob.session_file = "user://shot_chat_bob_session.cfg"
	_bob.chat_auto_start = false
	root.add_child(_bob)
	await _me.register("moi%s" % stamp, "moi%s@example.com" % stamp, "matkhau123", "matkhau123", false)
	await _bob.register("bob%s" % stamp, "bob%s@example.com" % stamp, "matkhau123", "matkhau123", false)
	_me.chat.start()
	_bob.chat.start()
	await _until(func() -> bool: return _me.chat.world_id != "" and _bob.chat.world_id != "")
	await create_timer(0.6).timeout
	await _bob.chat.send_world("Chào mọi người, mình mới vào game!")
	await create_timer(1.0).timeout
	await _me.chat.send_world("Chào bob, mình ở Màn 1-1 rồi.")
	await create_timer(1.0).timeout
	await _bob.chat.send_world("Màn 1-2 khó hơn nhiều, nhớ né đòn boss nhé.")
	# bob mời kết bạn và nhắn riêng cho người xem
	await _bob.chat.add_friend_by_code(str(_me.profile["code"]))
	await create_timer(1.0).timeout
	await _bob.chat.open_dm(_me.user_id(), _me.username())
	await _bob.chat.send_dm(_me.user_id(), "Kết bạn đi, mình rủ nhau đánh boss!")
	await create_timer(1.0).timeout
	await _me.chat.refresh_friends()

	_hub = (load("res://scenes/main/hub.tscn") as PackedScene).instantiate()
	root.add_child(_hub)
	await _frames(6)
	_shot("0_hub")
	_hub.show_tab("ChatTab")
	await _frames(8)
	_shot("1_world")
	var panel := _hub.panel as ChatPanel
	var from_bob: Array = _me.chat.messages(_me.chat.world_id).filter(func(m: Dictionary) -> bool: return m["sender_id"] == _bob.user_id())
	panel.select_message(from_bob.back())
	await _frames(8)
	_shot("2_actions")
	panel.show_friends()
	await _frames(10)
	_shot("3_friends")
	panel.open_dm(_bob.user_id(), _bob.username())
	await _frames(12)
	_shot("4_dm")
	# chưa đăng nhập
	_hub.show_tab("HomeTab")
	var out_service: Node = SERVICE_SCRIPT.new()
	out_service.config = OnlineConfig.load_from()
	root.add_child(out_service)
	var locked := ChatPanel.new()
	locked.service = out_service
	locked.navigate = false
	locked.position = Vector2(140, 70)
	locked.size = Vector2(1640, 600)
	root.add_child(locked)
	await _frames(6)
	_shot("5_locked")
	_me.logout()
	_bob.logout()
	quit()
