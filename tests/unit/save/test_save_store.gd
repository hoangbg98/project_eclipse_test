extends GdUnitTestSuite
## Test M5-1: SaveStore / SaveSchema — version, migration, backup, checksum, dữ liệu hỏng không làm crash.

const DIR := "user://test_saves_m5_1"

var _store: SaveStore


func before_test() -> void:
	_store = SaveStore.new(DIR)
	_store.delete_all()


func after_test() -> void:
	_store.delete_all()
	DirAccess.remove_absolute(DIR)


func _write_raw(file: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open(_store.path_of(file), FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _read_raw(file: String) -> String:
	return FileAccess.get_file_as_string(_store.path_of(file))


func _sample() -> Dictionary:
	var d := SaveSchema.default_data()
	d["characters"]["char_fire_01"] = {"level": 7, "exp": 120, "equipment": {"weapon": "3"}}
	d["currencies"]["gold"] = 4321
	d["inventory"]["materials"]["mat_exp_small"] = 12
	d["inventory"]["equipment"]["3"] = {"def_id": "eq_sword_01", "level": 2}
	d["inventory"]["next_uid"] = 4
	d["gacha"]["pity"]["banner_std"] = 17
	d["gacha"]["history"].append({"banner": "banner_std", "result": "char_wind_01"})
	d["progress"]["stages"]["stage_01"] = {"cleared": true, "best_time_sec": 212.5}
	d["settings"]["language"] = "en"
	return d


# ---------- Chưa có save ----------

func test_no_save_returns_defaults() -> void:
	assert_bool(_store.has_save()).is_false()
	var d := _store.read()
	assert_int(_store.last_status).is_equal(SaveStore.Status.NO_SAVE)
	assert_array(d["party"]).is_equal(SaveSchema.STARTER_CHARACTERS)
	assert_int(d["characters"]["char_fire_01"]["level"]).is_equal(1)
	assert_bool(_store.has_save()).is_false()                       # đọc không tạo file


# ---------- Ghi / đọc ----------

func test_round_trip_preserves_player_state() -> void:
	assert_int(_store.write(_sample())).is_equal(OK)
	assert_bool(_store.has_save()).is_true()
	var d := SaveStore.new(DIR).read()
	assert_int(_store.last_status).is_equal(SaveStore.Status.NO_SAVE)   # store cũ chưa đọc
	assert_int(d["characters"]["char_fire_01"]["level"]).is_equal(7)
	assert_int(d["characters"]["char_fire_01"]["exp"]).is_equal(120)
	assert_str(d["characters"]["char_fire_01"]["equipment"]["weapon"]).is_equal("3")
	assert_int(d["currencies"]["gold"]).is_equal(4321)
	assert_int(int(d["inventory"]["materials"]["mat_exp_small"])).is_equal(12)
	assert_str(d["inventory"]["equipment"]["3"]["def_id"]).is_equal("eq_sword_01")
	assert_int(d["inventory"]["next_uid"]).is_equal(4)
	assert_int(int(d["gacha"]["pity"]["banner_std"])).is_equal(17)
	assert_str(d["gacha"]["history"][0]["result"]).is_equal("char_wind_01")
	assert_bool(d["progress"]["stages"]["stage_01"]["cleared"]).is_true()
	assert_str(d["settings"]["language"]).is_equal("en")


func test_file_has_version_and_checksum() -> void:
	_store.write(_sample())
	var env: Dictionary = JSON.parse_string(_read_raw(SaveStore.MAIN))
	assert_int(int(env["schema_version"])).is_equal(SaveSchema.VERSION)
	assert_str(env["checksum"]).is_equal((env["data"] as String).sha256_text())
	assert_bool(FileAccess.file_exists(_store.path_of(SaveStore.TEMP))).is_false()   # không để lại file tạm


func test_second_write_keeps_previous_as_backup() -> void:
	var a := _sample()
	_store.write(a)
	a["currencies"]["gold"] = 9999
	_store.write(a)
	assert_bool(FileAccess.file_exists(_store.path_of(SaveStore.BACKUP))).is_true()
	assert_int(_store.read()["currencies"]["gold"]).is_equal(9999)
	var bak: Dictionary = JSON.parse_string(_read_raw(SaveStore.BACKUP))
	assert_int(int(JSON.parse_string(bak["data"])["currencies"]["gold"])).is_equal(4321)


# ---------- Hỏng / sai ----------

func test_corrupt_main_recovers_from_backup() -> void:
	var a := _sample()
	_store.write(a)
	a["currencies"]["gold"] = 9999
	_store.write(a)
	_write_raw(SaveStore.MAIN, "{ not json at all")
	var d := _store.read()
	assert_int(_store.last_status).is_equal(SaveStore.Status.RECOVERED)
	assert_int(d["currencies"]["gold"]).is_equal(4321)               # bản ghi trước đó
	assert_bool(_store.last_messages.size() >= 1).is_true()


func test_tampered_data_fails_checksum() -> void:
	_store.write(_sample())
	var env: Dictionary = JSON.parse_string(_read_raw(SaveStore.MAIN))
	env["data"] = (env["data"] as String).replace("4321", "999999")   # sửa tay số vàng
	_write_raw(SaveStore.MAIN, JSON.stringify(env))
	var d := _store.read()
	assert_int(_store.last_status).is_equal(SaveStore.Status.RESET_CORRUPT)
	assert_int(d["currencies"]["gold"]).is_equal(0)
	assert_bool(FileAccess.file_exists(_store.path_of(SaveStore.CORRUPT))).is_true()   # giữ bản hỏng
	assert_bool(FileAccess.file_exists(_store.path_of(SaveStore.MAIN))).is_false()


func test_garbage_files_never_crash() -> void:
	for text in ["", "null", "[]", "42", "{}", "{\"schema_version\": \"x\"}", "{\"schema_version\":1,\"checksum\":\"a\",\"data\":5}",
			"\u0000\u0001\u0002", "{\"schema_version\":1,\"checksum\":\"%s\",\"data\":\"[1,2]\"}" % "[1,2]".sha256_text()]:
		_store.delete_all()
		_write_raw(SaveStore.MAIN, text)
		var d := _store.read()
		assert_int(_store.last_status).override_failure_message(text).is_equal(SaveStore.Status.RESET_CORRUPT)
		assert_array(d["party"]).is_equal(SaveSchema.STARTER_CHARACTERS)


func test_corrupt_main_is_not_promoted_to_backup_on_next_write() -> void:
	_store.write(_sample())                                           # A (tốt) là file chính
	var b := _sample()
	b["currencies"]["gold"] = 5555
	_store.write(b)                                                   # backup = A, chính = B
	_write_raw(SaveStore.MAIN, "hỏng")
	var c := _sample()
	c["currencies"]["gold"] = 7777
	_store.write(c)                                                   # chính hỏng không được đè lên backup tốt
	var bak: Dictionary = JSON.parse_string(_read_raw(SaveStore.BACKUP))
	assert_int(int(JSON.parse_string(bak["data"])["currencies"]["gold"])).is_equal(4321)
	assert_int(_store.read()["currencies"]["gold"]).is_equal(7777)


# ---------- Version / migration ----------

func test_v1_save_migrates_to_current() -> void:
	# v1: vàng và ngọc nằm ở gốc, chưa có "stats".
	var v1 := {"characters": {"char_fire_01": {"level": 5, "exp": 40, "equipment": {}}}, "party": ["char_fire_01"],
			"gold": 250, "gems": 30}
	_write_raw(SaveStore.MAIN, SaveStore.encode(v1, 1))
	var d := _store.read()
	assert_int(_store.last_status).is_equal(SaveStore.Status.OK)
	assert_int(d["currencies"]["gold"]).is_equal(250)
	assert_int(d["currencies"]["gems"]).is_equal(30)
	assert_bool(d.has("gold")).is_false()
	assert_float(d["stats"]["play_time_sec"]).is_equal(0.0)
	assert_int(d["characters"]["char_fire_01"]["level"]).is_equal(5)
	assert_array(d["party"]).is_equal(["char_fire_01"])
	# Lưu lại thì file mang version hiện tại.
	_store.write(d)
	assert_int(int(JSON.parse_string(_read_raw(SaveStore.MAIN))["schema_version"])).is_equal(SaveSchema.VERSION)


func test_migration_chain_covers_every_version() -> void:
	assert_int(SaveSchema.migrations().size()).is_equal(SaveSchema.VERSION - 1)
	assert_object(SaveSchema.migrate({}, 0)).is_null()
	assert_object(SaveSchema.migrate({}, SaveSchema.VERSION + 1)).is_null()
	assert_bool(SaveSchema.migrate({}, SaveSchema.VERSION) is Dictionary).is_true()


func test_newer_version_is_kept_aside_not_destroyed() -> void:
	var raw := SaveStore.encode(_sample(), SaveSchema.VERSION + 3)
	_write_raw(SaveStore.MAIN, raw)
	var d := _store.read()
	assert_int(_store.last_status).is_equal(SaveStore.Status.RESET_NEWER)
	assert_int(d["currencies"]["gold"]).is_equal(0)
	assert_str(_read_raw(SaveStore.NEWER)).is_equal(raw)             # còn nguyên để bản game mới đọc lại


# ---------- Làm sạch ----------

func test_sanitize_fills_missing_and_fixes_types() -> void:
	var d := SaveSchema.sanitize({
		"characters": {"char_fire_01": {"level": "abc", "exp": -5}, "char_dark_01": 7},
		"party": ["char_dark_01", "char_dark_01", "ghost", "char_fire_01"],
		"currencies": {"gold": -10, "gems": "x", "hack": 1},
		"inventory": "oops",
		"settings": {"language": 5, "master_volume": 0.5},
		"unknown_key": true,
	})
	assert_int(d["characters"]["char_fire_01"]["level"]).is_equal(1)
	assert_int(d["characters"]["char_fire_01"]["exp"]).is_equal(0)
	assert_int(d["characters"]["char_dark_01"]["level"]).is_equal(1)
	assert_array(d["party"]).is_equal(["char_dark_01", "char_fire_01"])   # bỏ trùng, bỏ nhân vật không sở hữu
	assert_int(d["currencies"]["gold"]).is_equal(0)
	assert_int(d["currencies"]["gems"]).is_equal(0)
	assert_bool(d["currencies"].has("hack")).is_false()
	assert_int(d["inventory"]["next_uid"]).is_equal(1)
	assert_str(d["settings"]["language"]).is_equal("vi")
	assert_float(d["settings"]["master_volume"]).is_equal(0.5)
	assert_bool(d.has("unknown_key")).is_false()
	for junk in [null, 5, "text", [], {}]:
		assert_array(SaveSchema.sanitize(junk)["party"]).is_equal(SaveSchema.STARTER_CHARACTERS)


func test_history_is_capped() -> void:
	var d := SaveSchema.default_data()
	for i in SaveSchema.HISTORY_LIMIT + 50:
		d["gacha"]["history"].append({"n": i})
	var out := SaveSchema.sanitize(d)
	assert_int(out["gacha"]["history"].size()).is_equal(SaveSchema.HISTORY_LIMIT)
	assert_int(int(out["gacha"]["history"][-1]["n"])).is_equal(SaveSchema.HISTORY_LIMIT + 49)   # giữ mục mới nhất


# ---------- SaveService (autoload) ----------

func test_service_uses_isolated_dir_when_headless_and_new_game_keeps_settings() -> void:
	var svc := get_tree().root.get_node("SaveService")
	if DisplayServer.get_name() == "headless":
		assert_str(svc.store.dir).is_equal(svc.HEADLESS_DIR)
	var old_store: SaveStore = svc.store
	svc.store = _store
	svc.data = _sample()
	assert_bool(svc.new_game()).is_true()
	assert_int(svc.data["currencies"]["gold"]).is_equal(0)
	assert_str(svc.data["settings"]["language"]).is_equal("en")       # cài đặt được giữ
	assert_bool(svc.has_save()).is_true()
	svc.set_value("currencies.gold", 77)
	svc.save_game()
	svc.data = {}
	assert_int(svc.load_game()).is_equal(SaveStore.Status.OK)
	assert_int(svc.get_value("currencies.gold")).is_equal(77)
	assert_object(svc.get_value("no.such.path", null)).is_null()
	svc.delete_save()
	assert_bool(svc.has_save()).is_false()
	svc.store = old_store
	svc.load_game()
