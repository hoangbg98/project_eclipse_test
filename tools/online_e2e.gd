extends SceneTree
## Kiểm tra thật (M9-1): game → máy chủ Nakama đang chạy (không nằm trong run_tests vì cần máy chủ).
## Chạy: <godot> --headless --path . --script res://tools/online_e2e.gd -- --server=https://xxx.trycloudflare.com
## Không có --server thì dùng địa chỉ mặc định trong data/config/online_config.json. Mã thoát 0 = đạt.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var service: Node = root.get_node("OnlineService")
	service.device_file = "user://online_e2e_device.cfg"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--server="):
			service.config.server_url = NakamaApi.normalize_url(a.trim_prefix("--server="))
	print("Máy chủ: ", service.config.server_url)
	var t := Time.get_ticks_msec()
	var ok: bool = await service.login()
	if not ok:
		print("LỖI: ", service.last_error)
		quit(1)
		return
	print("Đăng nhập + hồ sơ: %d ms" % (Time.get_ticks_msec() - t))
	print("Mã người chơi: ", NakamaApi.format_code(str(service.profile.get("code", ""))))
	print("Ví: gems %d, gold %d" % [service.wallet_amount("gems"), service.wallet_amount("gold")])
	print("ĐẠT")
	quit(0)
