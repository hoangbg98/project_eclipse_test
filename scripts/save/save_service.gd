extends Node
## Autoload `SaveService`: giữ dữ liệu người chơi đang dùng và đọc / ghi qua SaveStore (ARCHITECTURE mục 8).
## Không chứa luật gameplay; các hệ thống khác (tiến trình, kho đồ, chiêu mộ) sửa `data` rồi gọi `save_game()`.

signal loaded(status: SaveStore.Status)
signal saved

const HEADLESS_DIR := "user://saves_headless"

var store := SaveStore.new()
## Dữ liệu người chơi hiện tại (theo SaveSchema); luôn hợp lệ.
var data: Dictionary = SaveSchema.default_data()
var last_status := SaveStore.Status.NO_SAVE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Chạy headless (test tự động, build máy chủ) dùng thư mục riêng để không đụng save thật của người chơi.
	if DisplayServer.get_name() == "headless":
		store = SaveStore.new(HEADLESS_DIR)
	load_game()
	# Áp cài đặt đã lưu (ngôn ngữ, âm lượng, toàn màn hình); tham số --lang trên dòng lệnh được ưu tiên.
	var lang_arg := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang="):
			lang_arg = true
	SettingsPanel.apply_settings(data["settings"], has_save() and not lang_arg)


## Đổi nơi lưu (M9-3: save ngoại tuyến `user://saves` ↔ bản đệm cloud save của tài khoản) rồi đọc lại và áp cài đặt.
func use_store(s: SaveStore) -> SaveStore.Status:
	store = s
	var status := load_game()
	SettingsPanel.apply_settings(data["settings"], has_save())
	return status


## Thư mục save ngoại tuyến; rỗng = mặc định (test đặt thư mục riêng).
var offline_dir := ""


## Nơi lưu ngoại tuyến của máy này.
func offline_store() -> SaveStore:
	if not offline_dir.is_empty():
		return SaveStore.new(offline_dir)
	return SaveStore.new(HEADLESS_DIR if DisplayServer.get_name() == "headless" else SaveStore.new().dir)


func has_save() -> bool:
	return store.has_save()


## Đọc save (hoặc mặc định nếu chưa có / hỏng). Không ghi gì ra đĩa.
func load_game() -> SaveStore.Status:
	data = store.read()
	last_status = store.last_status
	for m in store.last_messages:
		push_warning("SaveService: %s" % m)
	loaded.emit(last_status)
	return last_status


func save_game() -> bool:
	var err := store.write(data)
	if err != OK:
		push_error("SaveService: không ghi được save (lỗi %d)" % err)
		return false
	saved.emit()
	return true


## Bắt đầu game mới: dữ liệu mặc định (giữ cài đặt hiện tại) và ghi ngay.
func new_game() -> bool:
	var settings: Dictionary = data.get("settings", {})
	data = SaveSchema.default_data()
	if not settings.is_empty():
		data["settings"] = SaveSchema.sanitize({"settings": settings})["settings"]
	return save_game()


func delete_save() -> void:
	store.delete_all()
	data = SaveSchema.default_data()
	last_status = SaveStore.Status.NO_SAVE


# ---------- Tiện ích đọc / ghi theo đường dẫn "a.b.c" ----------

func get_value(path: String, fallback: Variant = null) -> Variant:
	var cur: Variant = data
	for k in path.split("."):
		if not (cur is Dictionary) or not cur.has(k):
			return fallback
		cur = cur[k]
	return cur


func set_value(path: String, value: Variant) -> void:
	var keys := path.split(".")
	var cur: Dictionary = data
	for i in keys.size() - 1:
		if not (cur.get(keys[i]) is Dictionary):
			cur[keys[i]] = {}
		cur = cur[keys[i]]
	cur[keys[keys.size() - 1]] = value
