extends GdUnitTestSuite
## Test nạp tiền (M9-2): cộng Ngọc đã nạp vào save (PurchasedCurrency), thẻ tháng, màn Nạp (bảng giá từ máy chủ, thưởng lần đầu,
## QR + thông tin chuyển khoản, nhận thẻ, báo khi nhận Ngọc). Máy chủ giả FakeNakama (logic phản chiếu server/modules/index.js,
## logic thật đã kiểm bằng server/tests/topup_smoke.mjs).

const SERVICE_SCRIPT := preload("res://scripts/online/online_service.gd")
const SAVE_SCRIPT := preload("res://scripts/save/save_service.gd")
const SCREEN_SCENE := preload("res://scenes/main/topup_screen.tscn")
const ROOT := "user://test_topup"

var fake: FakeNakama


func before_test() -> void:
	fake = FakeNakama.new()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/shop/topup_packs.json"))
	fake.catalog = data
	for p: Dictionary in fake.catalog["packs"]:
		if p["id"] == "card_30":
			p["price"] = 99000   # bảng giá thật chưa có giá thẻ; test thẻ cần giá
	fake.accounts["tester1"]["wallet"] = {}   # ví trống (mặc định 600 là của test cũ)
	OnlineTestKit.remove_tree(ROOT)


func after_test() -> void:
	OnlineTestKit.remove_tree(ROOT)


## Người chơi đã đăng nhập, đã mở thế giới cloud và có save (đã "Game mới").
func _player(new_game := true) -> Node:
	var saves: Node = auto_free(SAVE_SCRIPT.new())
	add_child(saves)
	saves.offline_dir = ROOT.path_join("offline")
	saves.use_store(SaveStore.new(saves.offline_dir))
	var s: Node = auto_free(SERVICE_SCRIPT.new())
	s.config = OnlineConfig.load_from(OnlineConfig.DATA_PATH, ROOT.path_join("online.cfg"))
	s.config.server_key = FakeNakama.SERVER_KEY
	s.device_file = ROOT.path_join("device.cfg")
	s.session_file = ROOT.path_join("session.cfg")
	s.cloud_root = ROOT.path_join("cloud")
	s.save_service = saves
	s.push_delay = 0.0
	s.chat_auto_start = false
	s.transport = fake.handle
	add_child(s)
	assert_bool(await s.login_account("tester1", "matkhau123", false)).is_true()
	assert_str(await s.open_cloud_world()).is_equal("ok")
	if new_game:
		saves.new_game()
	return s


func _gems(s: Node) -> int:
	return int(s.save_service.data["currencies"]["gems"])


func _applied(s: Node) -> int:
	return int(s.save_service.data["online"]["applied"]["gems"])


func test_purchased_currency_apply() -> void:
	var data := SaveSchema.default_data()
	assert_int(int(data["online"]["applied"]["gems"])).is_equal(0)
	assert_int(PurchasedCurrency.apply(data, 0)).is_equal(0)
	assert_int(PurchasedCurrency.apply(data, 660)).is_equal(660)
	assert_int(data["currencies"]["gems"]).is_equal(660)
	assert_int(PurchasedCurrency.apply(data, 660)).is_equal(0)          # không cộng hai lần
	data["currencies"]["gems"] = 1000                                    # tiêu / kiếm thêm trong game
	assert_int(PurchasedCurrency.apply(data, 1000)).is_equal(340)
	assert_int(data["currencies"]["gems"]).is_equal(1340)
	assert_int(PurchasedCurrency.apply(data, 800)).is_equal(-200)       # QTV thu hồi
	assert_int(data["currencies"]["gems"]).is_equal(1140)
	data["currencies"]["gems"] = 50
	assert_int(PurchasedCurrency.apply(data, 0)).is_equal(-800)         # thu hồi quá số đang có: về 0, không âm
	assert_int(data["currencies"]["gems"]).is_equal(0)
	# save cũ chưa có mục online
	var old := {"currencies": {"gold": 0, "gems": 5}}
	assert_int(PurchasedCurrency.apply(old, 10)).is_equal(10)
	assert_int(old["currencies"]["gems"]).is_equal(15)
	# làm sạch giữ mục online / bù mục thiếu
	assert_int(int(SaveSchema.sanitize({"online": {"applied": {"gems": 77}}})["online"]["applied"]["gems"])).is_equal(77)
	assert_int(int(SaveSchema.sanitize({})["online"]["applied"]["gems"])).is_equal(0)


func test_wallet_gems_reach_save_once_and_signal() -> void:
	fake.accounts["tester1"]["wallet"] = {"gems": 600}
	var s := await _player(false)
	assert_bool(s.save_service.has_save()).is_false()                   # thế giới mới chưa có save: chưa cộng
	s.save_service.new_game()                                            # save đầu tiên → nhận luôn Ngọc đã nạp
	assert_int(_gems(s)).is_equal(600)
	assert_int(_applied(s)).is_equal(600)
	assert_bool(await s.refresh_profile()).is_true()
	assert_int(_gems(s)).is_equal(600)                                   # làm mới không cộng lại
	var got: Array[int] = []
	s.purchased_applied.connect(func(g: int) -> void: got.append(g))
	fake.give_pack("tester1", "gems_660")                                # lần đầu: 660 + 660
	assert_bool(await s.refresh_profile()).is_true()
	assert_int(_gems(s)).is_equal(600 + 1320)
	assert_array(got).is_equal([1320])
	fake.give_pack("tester1", "gems_660")                                # lần hai: không thưởng
	await s.refresh_profile()
	assert_int(_gems(s)).is_equal(600 + 1320 + 660)
	# tiêu bớt Ngọc trong game rồi nạp: số tiêu không bị hoàn lại
	s.save_service.data["currencies"]["gems"] = 100
	s.save_service.save_game()
	fake.give_pack("tester1", "gems_330")
	await s.refresh_profile()
	assert_int(_gems(s)).is_equal(100 + 660)
	# tiền nạp riêng (corona) chỉ ở ví máy chủ, không vào save
	fake.give_pack("tester1", "corona_330")
	await s.refresh_profile()
	assert_int(s.wallet_amount("corona")).is_equal(330)
	assert_int(_gems(s)).is_equal(100 + 660)


func test_card_claim_flow() -> void:
	var s := await _player()
	var r: Dictionary = await s.card_claim()
	assert_bool(r["ok"]).is_false()
	assert_str(r["error"]).contains("card_none")
	fake.give_pack("tester1", "card_30")
	r = await s.card_claim()
	assert_bool(r["ok"]).is_true()
	assert_int(int(r["data"]["gems"])).is_equal(30)
	assert_int(_gems(s)).is_equal(30)                                    # ví → save ngay sau khi nhận
	r = await s.card_claim()
	assert_str(r["error"]).contains("card_claimed_today")
	fake.today = "2026-11-17"
	r = await s.card_claim()
	assert_bool(r["ok"]).is_true()
	assert_int(_gems(s)).is_equal(60)
	# lượt nhận thứ 15 có thêm 500
	var st: Dictionary = fake.topup_state["uid-tester1"]
	st["card"]["claims_total"] = 14
	fake.today = "2026-12-01"
	r = await s.card_claim()
	assert_int(int(r["data"]["gems"])).is_equal(530)
	assert_int(int(r["data"]["bonus"])).is_equal(500)
	assert_int(_gems(s)).is_equal(60 + 530)


func test_topup_info_shape() -> void:
	var s := await _player()
	var r: Dictionary = await s.topup_info()
	assert_bool(r["ok"]).is_true()
	assert_int(r["data"]["catalog"]["packs"].size()).is_equal(12)
	assert_bool(r["data"]["eligible"]["gems_660"]).is_true()
	assert_bool(r["data"]["eligible"].has("corona_330")).is_false()      # gói corona không có thưởng lần đầu
	assert_str(r["data"]["code"]).is_equal("32354120")


func _screen(s: Node) -> TopupScreen:
	var sc: TopupScreen = SCREEN_SCENE.instantiate()
	sc.service = s
	sc.navigate = false
	add_child(auto_free(sc))
	await await_idle_frame()
	await await_idle_frame()
	await await_idle_frame()
	return sc


func test_screen_locked_when_not_logged_in() -> void:
	var s: Node = auto_free(SERVICE_SCRIPT.new())
	s.config = OnlineConfig.load_from(OnlineConfig.DATA_PATH, ROOT.path_join("x.cfg"))
	s.chat_auto_start = false
	s.transport = fake.handle
	add_child(s)
	var sc := await _screen(s)
	assert_bool((sc.find_child("LockedBox", true, false) as Control).visible).is_true()
	assert_object(sc.find_child("Pack_gems_330", true, false)).is_null()


func test_screen_packs_prices_and_first_bonus() -> void:
	var s := await _player()
	var sc := await _screen(s)
	assert_bool((sc.find_child("LockedBox", true, false) as Control).visible).is_false()
	for id in ["gems_330", "gems_660", "gems_1320", "gems_3300", "gems_6600", "corona_330", "corona_990", "corona_1320",
			"corona_1980", "corona_3300", "corona_6600"]:
		assert_object(sc.find_child("Pack_" + id, true, false)).override_failure_message("thiếu gói " + id).is_not_null()
	var b660 := sc.find_child("Pack_gems_660", true, false) as Button
	assert_str(b660.text).contains("660")
	assert_str(b660.text).contains("140.000đ")
	assert_str(b660.text).contains(tr("TOPUP_FIRST_BONUS") % 660)        # còn thưởng nạp lần đầu
	assert_str((sc.find_child("Pack_corona_330", true, false) as Button).text).not_contains(tr("TOPUP_FIRST_BONUS") % 330)
	# nạp xong gói 660: hết thưởng lần đầu ở lần mở sau
	fake.give_pack("tester1", "gems_660")
	await sc.refresh()
	await await_idle_frame()
	assert_str((sc.find_child("Pack_gems_660", true, false) as Button).text).not_contains(tr("TOPUP_FIRST_BONUS") % 660)
	assert_str((sc.find_child("Pack_gems_330", true, false) as Button).text).contains(tr("TOPUP_FIRST_BONUS") % 330)


func test_screen_payment_qr_and_bank_info() -> void:
	var s := await _player()
	var sc := await _screen(s)
	sc.select_pack("gems_660")
	await await_idle_frame()
	var pay := sc.payment_for("gems_660")
	assert_int(pay["amount"]).is_equal(140000)
	assert_str(pay["memo"]).is_equal("ECL 32354120")                      # mã người chơi 8 số
	assert_str(pay["account"]).is_equal("15324121998")
	assert_str((sc.find_child("PayAmount", true, false) as Label).text).is_equal("140.000đ")
	assert_str((sc.find_child("PayMemo", true, false) as Label).text).is_equal("ECL 32354120")
	assert_str((sc.find_child("PayAccount", true, false) as Label).text).is_equal("15324121998")
	assert_str((sc.find_child("PayOwner", true, false) as Label).text).is_equal("TRẦN VIỆT HOÀNG")
	assert_str((sc.find_child("PayBank", true, false) as Label).text).is_equal("TPBank")
	for n in ["CopyAccount", "CopyAmount", "CopyMemo"]:
		assert_object(sc.find_child(n, true, false)).is_not_null()
	# mã QR: đọc ngược ra đúng chuỗi VietQR (số tiền + nội dung + tài khoản) với CRC đúng
	var qr := QrCode.encode_text(pay["payload"], QrCode.Ecc.MEDIUM)
	var r := QrReader.read(qr)
	assert_bool(r["ok"]).is_true()
	assert_str(r["text"]).is_equal(pay["payload"])
	var top := VietQr.parse(pay["payload"])
	assert_str(top["54"]).is_equal("140000")
	assert_str(VietQr.parse(top["62"])["08"]).is_equal("ECL 32354120")
	assert_str(String(pay["payload"]).right(4)).is_equal(VietQr.crc16(String(pay["payload"]).left(pay["payload"].length() - 4)))
	var tex := (sc.find_child("QrImage", true, false) as TextureRect).texture
	assert_object(tex).is_not_null()
	# chọn gói khác → số tiền đổi; gói chưa có giá không chọn được
	sc.select_pack("gems_6600")
	await await_idle_frame()
	assert_str((sc.find_child("PayAmount", true, false) as Label).text).is_equal("1.400.000đ")
	assert_str(sc.selected_pack).is_equal("gems_6600")
	assert_dict(sc.payment_for("khong_co")).is_empty()


func test_screen_card_claim_button_and_received_toast() -> void:
	var s := await _player()
	var sc := await _screen(s)
	var claim := sc.find_child("ClaimButton", true, false) as Button
	assert_bool(claim.disabled).is_true()                                 # chưa có thẻ
	# QTV phát thẻ → màn làm mới thấy nhận được hôm nay
	fake.give_pack("tester1", "card_30")
	await sc.refresh()
	await await_idle_frame()
	claim = sc.find_child("ClaimButton", true, false) as Button
	assert_bool(claim.disabled).is_false()
	assert_str(claim.text).is_equal(tr("TOPUP_CARD_CLAIM") % 30)
	assert_str(await sc.claim_card()).is_empty()
	await await_idle_frame()
	assert_int(_gems(s)).is_equal(30)
	assert_str((sc.find_child("Toast", true, false) as Label).text).is_equal(tr("TOPUP_CARD_CLAIMED") % 30)
	claim = sc.find_child("ClaimButton", true, false) as Button
	assert_bool(claim.disabled).is_true()
	assert_str(claim.text).is_equal(tr("TOPUP_CARD_DONE_TODAY"))
	assert_str(await sc.claim_card()).contains("card_claimed_today")
	assert_str((sc.find_child("Toast", true, false) as Label).text).is_equal(tr("TOPUP_ERR_CARD_TODAY"))
	# nạp gói: tự cộng vào kho và báo "đã nhận"
	fake.give_pack("tester1", "gems_330")                                  # 330 + 330 thưởng
	await sc.refresh()
	assert_int(_gems(s)).is_equal(30 + 660)
	assert_str((sc.find_child("Toast", true, false) as Label).text).is_equal(tr("TOPUP_RECEIVED") % 660)
	assert_str((sc.find_child("Wallet", true, false) as Label).text).contains(str(30 + 660))
	# lịch sử nạp
	assert_int((sc.find_child("Log", true, false) as Control).get_child_count()).is_greater_equal(1)


func test_money_format() -> void:
	assert_str(TopupScreen.money(70000)).is_equal("70.000đ")
	assert_str(TopupScreen.money(1400000)).is_equal("1.400.000đ")
	assert_str(TopupScreen.money(999)).is_equal("999đ")
