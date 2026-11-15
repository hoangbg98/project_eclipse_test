extends GdUnitTestSuite
## Test cloud save (M9-3): quy tắc chọn thế giới (CloudSave.decide), mở thế giới khi đăng nhập, gửi save sau mỗi lần lưu,
## mất mạng thì gửi lại, xung đột giữa hai thiết bị, mang save ngoại tuyến lên tài khoản, màn Đăng nhập hỏi mang lên.

const SERVICE_SCRIPT := preload("res://scripts/online/online_service.gd")
const SAVE_SCRIPT := preload("res://scripts/save/save_service.gd")
const LOGIN_SCENE := preload("res://scenes/main/login_screen.tscn")
const ROOT := "user://test_cloud"

var fake: FakeNakama


func before_test() -> void:
	fake = FakeNakama.new()
	OnlineTestKit.remove_tree(ROOT)


func after_test() -> void:
	OnlineTestKit.remove_tree(ROOT)


## Một "thiết bị": SaveService + OnlineService riêng (thư mục riêng), cùng máy chủ giả.
func _device(name_: String) -> Node:
	var saves: Node = auto_free(SAVE_SCRIPT.new())
	add_child(saves)
	saves.offline_dir = ROOT.path_join(name_ + "_offline")
	saves.use_store(SaveStore.new(saves.offline_dir))
	var s: Node = auto_free(SERVICE_SCRIPT.new())
	s.config = OnlineConfig.load_from(OnlineConfig.DATA_PATH, ROOT.path_join(name_ + "_online.cfg"))
	s.config.server_key = FakeNakama.SERVER_KEY
	s.device_file = ROOT.path_join(name_ + "_device.cfg")
	s.session_file = ROOT.path_join(name_ + "_session.cfg")
	s.cloud_root = ROOT.path_join(name_ + "_cloud")
	s.save_service = saves
	s.push_delay = 0.0
	s.transport = fake.handle
	add_child(s)
	return s


func _gold(s: Node) -> int:
	return int(s.save_service.data["currencies"]["gold"])


func _play(s: Node, gold: int) -> void:
	s.save_service.data["currencies"]["gold"] = gold
	s.save_service.save_game()
	await await_millis(30)   # push_delay = 0: gửi ở khung kế tiếp
	await s.push_now()       # chờ lần gửi (nếu đang gửi thì gửi tiếp)


func test_decide_rules() -> void:
	var clean := {"version": "v1", "dirty": false}
	var unsent := {"version": "v1", "dirty": true}
	assert_int(CloudSave.decide("v1", true, clean, false)).is_equal(CloudSave.Action.USE_CLOUD)
	assert_int(CloudSave.decide("v1", false, {}, true)).is_equal(CloudSave.Action.USE_CLOUD)
	assert_int(CloudSave.decide("v1", true, unsent, false)).is_equal(CloudSave.Action.PUSH_LOCAL)
	# chưa gửi nhưng máy chủ đã có bản mới hơn từ thiết bị khác: lấy bản máy chủ
	assert_int(CloudSave.decide("v2", true, unsent, false)).is_equal(CloudSave.Action.USE_CLOUD)
	assert_int(CloudSave.decide("", true, clean, true)).is_equal(CloudSave.Action.PUSH_LOCAL)
	assert_int(CloudSave.decide("", false, {}, true)).is_equal(CloudSave.Action.ASK_IMPORT)
	assert_int(CloudSave.decide("", false, {}, false)).is_equal(CloudSave.Action.NEW_WORLD)
	assert_str(CloudSave.dir_for("uid-a/b")).is_equal("user://saves_online/uid-a_b")


func test_new_world_is_saved_to_server_and_loaded_on_other_device() -> void:
	var a := _device("a")
	assert_bool(await a.login_account("tester1", "matkhau123", false)).is_true()
	assert_str(await a.open_cloud_world()).is_equal("ok")
	assert_bool(a.save_service.has_save()).is_false()          # thế giới mới: Title chỉ có Game mới
	assert_str(a.save_service.store.dir).is_equal(ROOT.path_join("a_cloud/uid-tester1"))
	a.save_service.new_game()
	await _play(a, 1234)
	assert_int(a.cloud_state).is_equal(a.Cloud.SYNCED)
	assert_bool(fake.saves.has("uid-tester1")).is_true()
	assert_bool(SaveStore.new(a.save_service.offline_dir).has_save()).is_false()   # save ngoại tuyến không bị đụng

	var b := _device("b")
	assert_bool(await b.login_account("tester1", "matkhau123", false)).is_true()
	assert_str(await b.open_cloud_world()).is_equal("ok")
	assert_bool(b.save_service.has_save()).is_true()
	assert_int(_gold(b)).is_equal(1234)


func test_offline_progress_is_pushed_later() -> void:
	var a := _device("a")
	assert_bool(await a.login_account("tester1", "matkhau123", false)).is_true()
	assert_str(await a.open_cloud_world()).is_equal("ok")
	a.save_service.new_game()
	await _play(a, 10)
	fake.down = true
	await _play(a, 20)
	assert_int(a.cloud_state).is_equal(a.Cloud.PENDING)
	assert_bool(CloudSave.read_meta(a._cloud_dir)["dirty"]).is_true()
	fake.down = false
	assert_bool(await a.push_now()).is_true()
	assert_int(a.cloud_state).is_equal(a.Cloud.SYNCED)
	# tắt game khi chưa gửi được, lần đăng nhập sau gửi tiếp
	fake.down = true
	await _play(a, 30)
	a.logout()
	assert_str(a.save_service.store.dir).is_equal(a.save_service.offline_dir)
	fake.down = false
	var a2 := _device("a")
	assert_bool(await a2.login_account("tester1", "matkhau123", false)).is_true()
	assert_str(await a2.open_cloud_world()).is_equal("ok")
	assert_int(_gold(a2)).is_equal(30)
	var env: Dictionary = fake.saves["uid-tester1"]["envelope"]
	assert_int(int(JSON.parse_string(env["data"])["currencies"]["gold"])).is_equal(30)


func test_conflict_between_devices_does_not_overwrite() -> void:
	var a := _device("a")
	assert_bool(await a.login_account("tester1", "matkhau123", false)).is_true()
	assert_str(await a.open_cloud_world()).is_equal("ok")
	a.save_service.new_game()
	await _play(a, 100)
	var other := SaveSchema.default_data()
	other["currencies"]["gold"] = 999
	fake.write_from_other_device("tester1", SaveStore.envelope_of(other))
	await _play(a, 200)
	assert_int(a.cloud_state).is_equal(a.Cloud.CONFLICT)
	assert_str(a.cloud_error).is_equal("CLOUD_ERR_CONFLICT")
	var env: Dictionary = fake.saves["uid-tester1"]["envelope"]
	assert_int(int(JSON.parse_string(env["data"])["currencies"]["gold"])).is_equal(999)
	# đăng nhập lại: lấy bản trên máy chủ
	a.logout()
	assert_bool(await a.login_account("tester1", "matkhau123", false)).is_true()
	assert_str(await a.open_cloud_world()).is_equal("ok")
	assert_int(_gold(a)).is_equal(999)


func test_import_offline_save_or_start_new() -> void:
	var a := _device("a")
	var offline := SaveSchema.default_data()
	offline["currencies"]["gold"] = 777
	SaveStore.new(a.save_service.offline_dir).write(offline)
	assert_bool(await a.login_account("tester1", "matkhau123", false)).is_true()
	assert_str(await a.open_cloud_world()).is_equal("ask")
	assert_str(await a.open_cloud_world(true)).is_equal("ok")
	assert_int(_gold(a)).is_equal(777)
	assert_bool(fake.saves.has("uid-tester1")).is_true()
	assert_bool(SaveStore.new(a.save_service.offline_dir).has_save()).is_true()   # bản ngoại tuyến vẫn giữ

	var b := _device("b")
	SaveStore.new(b.save_service.offline_dir).write(offline)
	fake.add_account("tester2", "t2@example.com", "matkhau123", "22223333")
	assert_bool(await b.login_account("tester2", "matkhau123", false)).is_true()
	assert_str(await b.open_cloud_world()).is_equal("ask")
	assert_str(await b.open_cloud_world(false)).is_equal("ok")
	assert_bool(b.save_service.has_save()).is_false()
	assert_bool(fake.saves.has("uid-tester2")).is_false()


func test_bad_cloud_data_is_refused() -> void:
	var a := _device("a")
	fake.saves["uid-tester1"] = {"version": "v9", "envelope": {"schema_version": 6, "checksum": "a".repeat(64),
			"saved_at": "x", "data": "{}"}}
	assert_bool(await a.login_account("tester1", "matkhau123", false)).is_true()
	assert_str(await a.open_cloud_world()).is_equal("error")
	assert_str(a.cloud_error).is_equal("CLOUD_ERR_BAD_DATA")
	var newer := SaveStore.envelope_of(SaveSchema.default_data())
	newer["schema_version"] = SaveSchema.VERSION + 1
	fake.saves["uid-tester1"] = {"version": "v10", "envelope": newer}
	assert_str(await a.open_cloud_world()).is_equal("error")
	assert_str(a.cloud_error).is_equal("CLOUD_ERR_NEWER")


func test_login_screen_asks_to_import() -> void:
	var a := _device("a")
	SaveStore.new(a.save_service.offline_dir).write(SaveSchema.default_data())
	var screen: Control = LOGIN_SCENE.instantiate()
	screen.service = a
	screen.navigate = false
	add_child(screen)
	auto_free(screen)
	screen.field("login_name").text = "tester1"
	screen.field("login_password").text = "matkhau123"
	assert_bool(await screen.submit()).is_false()
	assert_bool(screen.is_asking_import()).is_true()
	assert_int(screen.entered).is_equal(0)
	assert_bool(await screen.answer_import(true)).is_true()
	assert_int(screen.entered).is_equal(1)
	assert_bool(screen.is_asking_import()).is_false()
