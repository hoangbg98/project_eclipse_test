extends Node
## Cấu hình toàn cục chỉ-đọc. Sau này nạp combat_rules.tres / link_rules.tres.
## Không giữ state của trận (xem docs/ARCHITECTURE.md mục 3).

const BASE_RESOLUTION := Vector2i(1920, 1080)
const SCENE_BOOT := "res://scenes/main/boot.tscn"
const SCENE_TITLE := "res://scenes/main/title.tscn"
const SCENE_HUB := "res://scenes/main/hub.tscn"

## Thời gian chuyển cảnh (giây), trong khoảng 150-250 ms theo UI_UX_SPEC.
const TRANSITION_TIME := 0.2


func get_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "dev"))
