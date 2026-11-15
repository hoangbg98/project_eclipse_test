class_name CloudSave
extends RefCounted
## Quy tắc cloud save (M9-3): khi đăng nhập thì lấy bản nào làm thế giới của tài khoản. Hàm thuần, test được.
##
## Máy chủ giữ bản gốc. Trên máy có "bản đệm" riêng từng tài khoản (user://saves_online/<user_id>/) kèm `cloud.cfg`:
##   version = version trên máy chủ của lần đồng bộ cuối; dirty = có tiến độ chưa gửi được (mất mạng khi đang chơi).

enum Action {
	USE_CLOUD,     ## Tải bản trên máy chủ về bản đệm.
	PUSH_LOCAL,    ## Gửi bản đệm lên (tiến độ chưa gửi, hoặc máy chủ chưa có save).
	ASK_IMPORT,    ## Máy chủ chưa có, máy này có save ngoại tuyến: hỏi người chơi có mang lên không.
	NEW_WORLD,     ## Chưa có gì: thế giới mới (Title chỉ có Game mới).
}

const ROOT_DIR := "user://saves_online"
const META_FILE := "cloud.cfg"


static func dir_for(user_id: String, root := ROOT_DIR) -> String:
	return root.path_join(user_id.validate_filename())


## cloud_version = "" khi máy chủ chưa có save. local_meta = {version, dirty} của bản đệm.
static func decide(cloud_version: String, local_exists: bool, local_meta: Dictionary, offline_exists: bool) -> Action:
	if not cloud_version.is_empty():
		var unsent := local_exists and bool(local_meta.get("dirty", false)) \
				and str(local_meta.get("version", "")) == cloud_version
		return Action.PUSH_LOCAL if unsent else Action.USE_CLOUD
	if local_exists:
		return Action.PUSH_LOCAL
	return Action.ASK_IMPORT if offline_exists else Action.NEW_WORLD


static func read_meta(dir: String) -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(dir.path_join(META_FILE))
	return {"version": str(cfg.get_value("cloud", "version", "")), "dirty": bool(cfg.get_value("cloud", "dirty", false))}


static func write_meta(dir: String, version: String, dirty: bool) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var cfg := ConfigFile.new()
	cfg.set_value("cloud", "version", version)
	cfg.set_value("cloud", "dirty", dirty)
	cfg.save(dir.path_join(META_FILE))
