class_name SaveStore
extends RefCounted
## Đọc / ghi file save JSON có version, checksum, backup (ARCHITECTURE mục 8). Không biết gì về UI hay scene.
##
## File: `<dir>/save.json` (chính), `save.bak.json` (bản ghi tốt trước đó), `save.tmp.json` (đang ghi),
## `save.corrupt.json` / `save.newer.json` (bản hỏng / bản của phiên bản game mới hơn, giữ lại để tra cứu).
## Định dạng: {"schema_version": n, "checksum": "<sha256 của chuỗi data>", "saved_at": "...", "data": "<chuỗi JSON>"}.
## `data` lưu ở dạng chuỗi để checksum không phụ thuộc cách sắp khóa / in số của trình ghi JSON.

enum Status {
	OK,              ## Đọc file chính thành công.
	NO_SAVE,         ## Chưa có file nào: dùng mặc định.
	RECOVERED,       ## File chính hỏng, đã lấy từ backup.
	RESET_CORRUPT,   ## Cả hai đều hỏng: dùng mặc định (bản hỏng được giữ lại).
	RESET_NEWER,     ## Save của bản game mới hơn: dùng mặc định, không ghi đè bản đó cho tới khi lưu.
}

const MAIN := "save.json"
const BACKUP := "save.bak.json"
const TEMP := "save.tmp.json"
const CORRUPT := "save.corrupt.json"
const NEWER := "save.newer.json"

var dir := "user://saves"
var last_status := Status.NO_SAVE
## Thông báo của lần đọc gần nhất (để ghi log / hiện cho người chơi).
var last_messages := PackedStringArray()


func _init(save_dir := "user://saves") -> void:
	dir = save_dir


func path_of(file: String) -> String:
	return dir.path_join(file)


func has_save() -> bool:
	return FileAccess.file_exists(path_of(MAIN)) or FileAccess.file_exists(path_of(BACKUP))


# ---------- Ghi ----------

## Ghi `data` ra file. Ghi vào file tạm trước, rồi chuyển file chính hiện tại thành backup. Trả về OK hoặc mã lỗi.
func write(data: Dictionary) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(dir)
	if err != OK and not DirAccess.dir_exists_absolute(dir):
		return err
	var text := encode(data, SaveSchema.VERSION)
	var f := FileAccess.open(path_of(TEMP), FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(text)
	f.close()
	# Chỉ giữ file chính làm backup nếu nó còn đọc được (không để bản hỏng đè lên backup tốt).
	if FileAccess.file_exists(path_of(MAIN)):
		if _read_valid(path_of(MAIN)) != null:
			DirAccess.rename_absolute(path_of(MAIN), path_of(BACKUP))
		else:
			DirAccess.remove_absolute(path_of(MAIN))
	return DirAccess.rename_absolute(path_of(TEMP), path_of(MAIN))


## Đóng gói thành chuỗi file (dùng cả trong test để tạo save phiên bản cũ).
static func encode(data: Dictionary, version: int) -> String:
	var body := JSON.stringify(data)
	return JSON.stringify({
		"schema_version": version,
		"checksum": body.sha256_text(),
		"saved_at": Time.get_datetime_string_from_system(true),
		"data": body,
	}, "\t")


# ---------- Đọc ----------

## Đọc save: file chính → backup → mặc định. Luôn trả về dữ liệu đã migrate + làm sạch; không bao giờ ném lỗi.
func read() -> Dictionary:
	last_messages = PackedStringArray()
	var main_exists := FileAccess.file_exists(path_of(MAIN))
	var bak_exists := FileAccess.file_exists(path_of(BACKUP))
	if not main_exists and not bak_exists:
		last_status = Status.NO_SAVE
		return SaveSchema.default_data()
	var newer := false
	if main_exists:
		var r: Variant = _read_valid(path_of(MAIN))
		if r != null:
			last_status = Status.OK
			return r
		newer = _last_was_newer
		last_messages.append("save chính không đọc được: %s" % _last_error)
	if bak_exists:
		var b: Variant = _read_valid(path_of(BACKUP))
		if b != null:
			last_status = Status.RECOVERED
			last_messages.append("đã khôi phục từ backup")
			return b
		newer = newer or _last_was_newer
		last_messages.append("backup không đọc được: %s" % _last_error)
	# Giữ bản không đọc được để tra cứu, rồi dùng mặc định.
	if main_exists:
		var keep := path_of(NEWER if newer else CORRUPT)
		DirAccess.remove_absolute(keep)
		DirAccess.rename_absolute(path_of(MAIN), keep)
	last_status = Status.RESET_NEWER if newer else Status.RESET_CORRUPT
	return SaveSchema.default_data()


func delete_all() -> void:
	for f in [MAIN, BACKUP, TEMP, CORRUPT, NEWER]:
		if FileAccess.file_exists(path_of(f)):
			DirAccess.remove_absolute(path_of(f))


var _last_error := ""
var _last_was_newer := false


## Đọc một file: kiểm tra định dạng, checksum, version; migrate + làm sạch. null nếu không dùng được.
func _read_valid(path: String) -> Variant:
	_last_error = ""
	_last_was_newer = false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_last_error = "không mở được file"
		return null
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		_last_error = "không phải JSON hợp lệ"
		return null
	var env: Dictionary = json.data
	var ver: Variant = env.get("schema_version")
	var body: Variant = env.get("data")
	if not (ver is float or ver is int) or not (body is String) or not (env.get("checksum") is String):
		_last_error = "thiếu schema_version / checksum / data"
		return null
	if (body as String).sha256_text() != env["checksum"]:
		_last_error = "sai checksum"
		return null
	if int(ver) > SaveSchema.VERSION:
		_last_error = "save của phiên bản mới hơn (v%d > v%d)" % [int(ver), SaveSchema.VERSION]
		_last_was_newer = true
		return null
	var inner := JSON.new()
	if inner.parse(body) != OK or not (inner.data is Dictionary):
		_last_error = "phần data không hợp lệ"
		return null
	var migrated: Variant = SaveSchema.migrate(inner.data, int(ver))
	if migrated == null:
		_last_error = "version không hỗ trợ (v%d)" % int(ver)
		return null
	return SaveSchema.sanitize(migrated)
