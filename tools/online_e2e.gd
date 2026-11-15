extends SceneTree
## Kiểm tra thật (M9-1): game → máy chủ Nakama đang chạy (không nằm trong run_tests vì cần máy chủ).
## Chạy: <godot> --headless --path . --script res://tools/online_e2e.gd -- --server=https://xxx.trycloudflare.com
## Không có --server thì dùng địa chỉ mặc định trong data/config/online_config.json. Mã thoát 0 = đạt.
## Các bước: đăng nhập thiết bị; tạo tài khoản ngẫu nhiên e2e_xxxx; đăng xuất; đăng nhập bằng tên; bằng email;
## vào lại bằng phiên đã ghi nhớ (refresh token); đăng ký trùng tên phải bị từ chối.

var _fails := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String, service: Node) -> void:
	print(("  ĐẠT  " if ok else "  LỖI  ") + what + ("" if ok else "  (" + str(service.last_error) + ")"))
	if not ok:
		_fails += 1


func _remove_tree(path: String) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	for sub in d.get_directories():
		_remove_tree(path.path_join(sub))
	for f in d.get_files():
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)


func _run() -> void:
	var service: Node = root.get_node("OnlineService")
	service.device_file = "user://online_e2e_device.cfg"
	service.session_file = "user://online_e2e_session.cfg"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--server="):
			service.config.server_url = NakamaApi.normalize_url(a.trim_prefix("--server="))
	print("Máy chủ: ", service.config.server_url)

	var t := Time.get_ticks_msec()
	_check(await service.login_device(), "đăng nhập thiết bị (%d ms)" % (Time.get_ticks_msec() - t), service)
	print("  mã %s, ví gems %d gold %d" % [NakamaApi.format_code(str(service.profile.get("code", ""))),
			service.wallet_amount("gems"), service.wallet_amount("gold")])
	service.logout()

	var user := "e2e_%d" % (Time.get_unix_time_from_system() as int % 1000000)
	var email := user + "@example.com"
	t = Time.get_ticks_msec()
	_check(await service.register(user, email, "matkhau123", "matkhau123", true),
			"tạo tài khoản %s (%d ms)" % [user, Time.get_ticks_msec() - t], service)
	var code := str(service.profile.get("code", ""))
	_check(code.length() == 8, "có mã người chơi " + NakamaApi.format_code(code), service)
	service.logout()
	_check(not service.has_saved_session(), "đăng xuất xóa phiên đã nhớ", service)
	_check(await service.login_account(user, "matkhau123", true), "đăng nhập bằng tên", service)
	service.token = ""
	service.profile = {}
	_check(await service.resume(), "vào lại bằng phiên đã nhớ", service)
	_check(str(service.profile.get("code", "")) == code, "cùng mã người chơi sau khi vào lại", service)
	service.logout()
	_check(await service.login_account(email, "matkhau123", false), "đăng nhập bằng email", service)
	service.logout()
	_check(not await service.login_account(user, "sai_mat_khau", false), "sai mật khẩu bị từ chối", service)
	_check(not await service.register(user, "khac@example.com", "matkhau123", "matkhau123", false)
			and service.last_error == "LOGIN_ERR_USERNAME_TAKEN", "trùng tên bị từ chối", service)
	service.logout()

	# Cloud save (M9-3): thư mục riêng cho lần kiểm tra, không đụng save thật.
	var saves: Node = root.get_node("SaveService")
	var e2e_root := "user://online_e2e"
	saves.offline_dir = e2e_root.path_join("offline")
	saves.use_store(saves.offline_store())
	service.cloud_root = e2e_root.path_join("cloud")
	service.push_delay = 0.0
	_check(await service.login_account(user, "matkhau123", false), "đăng nhập để thử cloud save", service)
	_check(await service.open_cloud_world() == "ok", "mở thế giới mới của tài khoản", service)
	saves.new_game()
	saves.data["currencies"]["gold"] = 4321
	t = Time.get_ticks_msec()
	saves.save_game()
	_check(await service.push_now(), "gửi save lên máy chủ (%d ms, %d byte)" % [Time.get_ticks_msec() - t,
			JSON.stringify(SaveStore.envelope_of(saves.data)).length()], service)
	service.logout()
	_remove_tree(ProjectSettings.globalize_path(service.cloud_root))   # như một máy khác chưa từng chơi
	_check(await service.login_account(user, "matkhau123", false), "đăng nhập lại (máy trống)", service)
	t = Time.get_ticks_msec()
	_check(await service.open_cloud_world() == "ok", "tải thế giới từ máy chủ (%d ms)" % (Time.get_ticks_msec() - t), service)
	_check(int(saves.data["currencies"]["gold"]) == 4321, "dữ liệu tải về đúng (vàng 4321)", service)
	service.logout()
	_remove_tree(ProjectSettings.globalize_path(e2e_root))
	print("ĐẠT" if _fails == 0 else "CÓ %d BƯỚC LỖI" % _fails)
	quit(0 if _fails == 0 else 1)
