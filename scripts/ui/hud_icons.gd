class_name HudIcons
extends RefCounted
## Icon cụm nút kỹ năng trên HUD trận đấu, chọn theo giáp (Data ID).
## Tìm `assets/ui/hud/skill_icons/{data_id}/{slot}.png` trước, không có thì `default/{slot}.png`.
## Owner thay icon cho một giáp chỉ cần đặt PNG vào thư mục của Data ID đó (icon tạm sinh bởi
## `tools/ui/gen_hud_icons.py`).

const DIR := "res://assets/ui/hud/skill_icons"
const DEFAULT_SET := "default"
const SLOTS: Array[String] = ["attack", "jump", "dodge", "skill", "weapon", "ultimate"]

static var _cache: Dictionary = {}


## Đường dẫn icon của `slot` cho giáp `data_id` (rỗng nếu cả bộ riêng lẫn bộ mặc định đều không có).
static func path_for(data_id: String, slot: String) -> String:
	for folder in [data_id, DEFAULT_SET]:
		if folder.is_empty():
			continue
		var p := "%s/%s/%s.png" % [DIR, folder, slot]
		if ResourceLoader.exists(p):
			return p
	return ""


static func icon(data_id: String, slot: String) -> Texture2D:
	var p := path_for(data_id, slot)
	if p.is_empty():
		return null
	if not _cache.has(p):
		_cache[p] = load(p)
	return _cache[p]
