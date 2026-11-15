class_name OnlineConfig
extends RefCounted
## Cấu hình kết nối máy chủ (M9-1): giá trị mặc định đọc từ data/config/online_config.json, địa chỉ máy chủ
## người chơi tự nhập (vd đường hầm trycloudflare.com đổi mỗi lần chạy) lưu riêng ở user://online.cfg.

const DATA_PATH := "res://data/config/online_config.json"
const USER_PATH := "user://online.cfg"

var default_server_url := "http://127.0.0.1:7350"
var server_key := ""
var timeout_sec := 12.0
var currencies_shown: Array = ["gems", "gold"]
## Địa chỉ đang dùng (người chơi nhập, hoặc mặc định).
var server_url := ""
var user_path := USER_PATH


static func load_from(data_path := DATA_PATH, user_cfg_path := USER_PATH) -> OnlineConfig:
	var c := OnlineConfig.new()
	c.user_path = user_cfg_path
	var f := FileAccess.open(data_path, FileAccess.READ)
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			c.default_server_url = NakamaApi.normalize_url(str(d.get("default_server_url", c.default_server_url)))
			c.server_key = str(d.get("server_key", ""))
			c.timeout_sec = float(d.get("timeout_sec", c.timeout_sec))
			if d.get("currencies_shown") is Array:
				c.currencies_shown = d["currencies_shown"]
	else:
		push_warning("OnlineConfig: không đọc được %s" % data_path)
	c.server_url = c.default_server_url
	var cfg := ConfigFile.new()
	if cfg.load(user_cfg_path) == OK:
		var saved := NakamaApi.normalize_url(str(cfg.get_value("server", "url", "")))
		if not saved.is_empty():
			c.server_url = saved
	return c


## Đổi địa chỉ máy chủ và lưu lại; chuỗi rỗng = về mặc định. Trả về địa chỉ đã chuẩn hóa.
func set_server_url(raw: String) -> String:
	var url := NakamaApi.normalize_url(raw)
	server_url = url if not url.is_empty() else default_server_url
	var cfg := ConfigFile.new()
	cfg.load(user_path)
	cfg.set_value("server", "url", "" if server_url == default_server_url else server_url)
	cfg.save(user_path)
	return server_url
