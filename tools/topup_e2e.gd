extends SceneTree
## Kiểm tra thật vòng nạp (M9-2): game ↔ máy chủ Nakama đang chạy (không nằm trong run_tests vì cần máy chủ). Chạy:
##   <godot> --headless --path . --script res://tools/topup_e2e.gd [-- --server=<địa chỉ>]
## Cần server\.runtime\secrets.json (khóa QTV, chỉ có trên máy chủ thử). Tài khoản tạm te<số>; dùng thư mục save riêng.
## Các bước: tạo tài khoản + thế giới → QTV phát gói (thưởng lần đầu) → game tự cộng Ngọc vào save → thẻ tháng nhận hằng ngày.

const SERVICE_SCRIPT := preload("res://scripts/online/online_service.gd")

var _fails := 0
var _svc: Node
var _secrets: Dictionary


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String, detail := "") -> void:
	print(("  ĐẠT  " if ok else "  LỖI  ") + what + ("" if ok else "  (" + detail + ")"))
	if not ok:
		_fails += 1


## Gọi RPC của QTV bằng http_key (như server\grant.ps1). Trả về Dictionary đã parse ({} nếu lỗi).
func _admin(rpc_id: String, payload: Dictionary) -> Dictionary:
	var req := {"method": HTTPClient.METHOD_POST,
			"url": "%s/v2/rpc/%s?http_key=%s&unwrap" % [_svc.config.server_url, rpc_id, str(_secrets["http_key"])],
			"headers": PackedStringArray(["Content-Type: application/json"]), "body": JSON.stringify(payload)}
	var res: Dictionary = await _svc.transport.call(req)
	var d: Variant = JSON.parse_string(str(res.get("body", "")))
	if int(res.get("code", 0)) != 200:
		print("    admin ", rpc_id, " lỗi: ", str(res.get("body", "")).left(200))
		return {}
	return d if d is Dictionary else {}


func _gems() -> int:
	return int(_svc.current_saves().data["currencies"]["gems"])


func _run() -> void:
	var server := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--server="):
			server = a.trim_prefix("--server=")
	_secrets = JSON.parse_string(FileAccess.get_file_as_string("res://server/.runtime/secrets.json"))
	_svc = SERVICE_SCRIPT.new()
	_svc.config = OnlineConfig.load_from()
	if not server.is_empty():
		_svc.config.server_url = NakamaApi.normalize_url(server)
	_svc.session_file = "user://topup_e2e_session.cfg"
	_svc.cloud_root = "user://topup_e2e_cloud"
	_svc.chat_auto_start = false
	root.add_child(_svc)
	var saves: Node = root.get_node("SaveService")
	saves.offline_dir = "user://topup_e2e_offline"
	saves.use_store(saves.offline_store())
	_svc.save_service = saves
	print("Máy chủ: ", _svc.config.server_url)

	var stamp := str(int(Time.get_unix_time_from_system()) % 1000000)
	var name_ := "te%s" % stamp
	_check(await _svc.register(name_, name_ + "@example.com", "matkhau123", "matkhau123", false), "tạo tài khoản " + name_, str(_svc.last_error))
	_check(await _svc.open_cloud_world() == "ok", "mở thế giới của tài khoản")
	saves.new_game()
	var code := str(_svc.profile["code"])
	var info: Dictionary = await _svc.topup_info()
	_check(info["ok"] and info["data"]["catalog"] != null, "đọc được bảng giá từ máy chủ", str(info.get("error", "")))
	var packs: Array = info["data"]["catalog"]["packs"]
	_check(packs.size() >= 11 and str(info["data"]["catalog"]["payment"]["account_number"]) != "", "bảng giá + thông tin nhận tiền", str(packs.size()))
	_check(_gems() == 0, "Ngọc ban đầu 0")

	# QTV phát gói 330 lần đầu: 330 + 330 thưởng
	var ref := "TE-%s-1" % stamp
	var g := await _admin("admin_topup", {"code": code, "pack": "gems_330", "paid": 70000, "ref": ref, "operator": "e2e"})
	_check(not g.is_empty() and int(g["granted"]["bonus"]) == 330, "QTV phát gói 330: có thưởng lần đầu", str(g).left(120))
	var got: Array[int] = []
	_svc.purchased_applied.connect(func(d: int) -> void: got.append(d))
	_check(await _svc.refresh_profile(), "người chơi làm mới")
	_check(_gems() == 660 and got == [660], "game tự cộng 660 Ngọc vào save và báo", "gems=%d got=%s" % [_gems(), str(got)])
	await _svc.refresh_profile()
	_check(_gems() == 660, "làm mới lại không cộng thêm")
	var ref2 := "TE-%s-2" % stamp
	g = await _admin("admin_topup", {"code": code, "pack": "gems_330", "paid": 70000, "ref": ref2, "operator": "e2e"})
	_check(not g.is_empty() and int(g["granted"]["bonus"]) == 0, "nạp lần hai cùng gói: không thưởng")
	await _svc.refresh_profile()
	_check(_gems() == 990, "Ngọc 990 sau lần hai", str(_gems()))
	info = await _svc.topup_info()
	_check(info["data"]["eligible"]["gems_330"] == false and info["data"]["eligible"]["gems_660"] == true, "gói đã dùng hết thưởng, gói khác còn")
	_check(info["data"]["log"].size() == 2, "lịch sử nạp có 2 lần")

	# thẻ tháng: bảng giá thật chưa có giá thẻ → QTV cấp lượt bằng admin_card_set
	var c: Dictionary = await _svc.card_claim()
	_check(not c["ok"] and str(c["error"]).contains("card_none"), "chưa có thẻ thì không nhận được")
	await _admin("admin_card_set", {"code": code, "claims_left": 30, "operator": "e2e"})
	c = await _svc.card_claim()
	_check(c["ok"] and int(c["data"]["gems"]) == 30, "nhận thẻ tháng ngày đầu +30", str(c))
	_check(_gems() == 1020, "Ngọc 1020 sau khi nhận thẻ", str(_gems()))
	c = await _svc.card_claim()
	_check(not c["ok"] and str(c["error"]).contains("card_claimed_today"), "một ngày một lần")

	# thu hồi
	var r := await _admin("admin_grant", {"code": code, "changes": {"gems": -20}, "ref": "TE-%s-3" % stamp, "operator": "e2e"})
	_check(not r.is_empty(), "QTV thu hồi 20 Ngọc")
	await _svc.refresh_profile()
	_check(_gems() == 1000, "game trừ đúng 20 Ngọc bị thu hồi", str(_gems()))
	_svc.logout()
	print("ĐẠT" if _fails == 0 else "CÓ %d BƯỚC LỖI" % _fails)
	quit(0 if _fails == 0 else 1)
