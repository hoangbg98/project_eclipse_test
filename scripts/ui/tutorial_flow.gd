class_name TutorialFlow
extends RefCounted
## Luật của hướng dẫn người mới (owner 2026-11-14), tách khỏi phần vẽ (TutorialGuide) để test không cần UI.
## Bước hiện tại suy ra từ save, không lưu số bước riêng, nên thoát game giữa chừng vẫn tiếp tục đúng chỗ:
##
## 1. STORY — chưa qua ải 1-1: Sảnh → Xuất kích → Cốt truyện chính → thẻ Chương 1 → ải 1-1 trên map → (clip)
##    → Chuẩn bị → Khai chiến.
##    Trong trận không khóa gì; thua thì chỉ cho Chơi lại.
## 2. PULL — đã qua 1-1, còn vé x10 và chưa dùng lượt miễn phí: màn kết quả → Về Hub → (Menu) → Tiếp tế →
##    Chiêu mộ → Chiêu mộ ×10 miễn phí.
## 3. FINISH — đã dùng lượt miễn phí: đóng bảng kết quả quay → hướng dẫn xong (`tutorial.done = true`).
##
## Mỗi bước trả về tên node cần bấm (theo thứ tự ưu tiên, lấy node đầu tiên đang hiện), khóa chữ của câu chỉ dẫn
## cuối và `id` bước. Trước câu chỉ dẫn, trợ lý AI NEO trò chuyện với Quản lý theo data/tutorial/tutorial_dialogue.json
## (mỗi câu có một câu đáp của Quản lý); đoạn trò chuyện của một bước chỉ phát một lần (`tutorial.seen`).

const GC := preload("res://scripts/core/game_config.gd")

const STORY_STAGE := "stage_01"
const STARTER_BANNER := "starter_pull"
const TICKET := "ticket_starter_x10"
const DIALOGUE_PATH := "res://data/tutorial/tutorial_dialogue.json"

const PHASE_DONE := "done"
const PHASE_STORY := "story"
const PHASE_PULL := "pull"
const PHASE_FINISH := "finish"

## Màn mở từ sảnh có nút Menu (về sảnh) — dùng khi người chơi lạc sang màn không thuộc bước hiện tại.
const MENU_SCENES: Array[String] = [GC.SCENE_SORTIE, GC.SCENE_CHAPTERS, GC.SCENE_CHAPTER_MAP, GC.SCENE_STAGE_INFO, GC.SCENE_PARTY_PREP, GC.SCENE_PARTY_SELECT,
		GC.SCENE_SUPPLY, GC.SCENE_BAG, GC.SCENE_COMPANION, GC.SCENE_PLAYER]


static func is_done(data: Dictionary) -> bool:
	var t: Variant = data.get("tutorial")
	return t is Dictionary and bool(t.get("done", false))


static func phase(data: Dictionary) -> String:
	if is_done(data):
		return PHASE_DONE
	var st: Variant = data.get("progress", {}).get("stages", {}).get(STORY_STAGE)
	if not (st is Dictionary and bool(st.get("cleared", false))):
		return PHASE_STORY
	var used: Array = data.get("gacha", {}).get("starter_used", [])
	var tickets := int(data.get("inventory", {}).get("materials", {}).get(TICKET, 0))
	if STARTER_BANNER not in used and tickets > 0:
		return PHASE_PULL
	return PHASE_FINISH


## Bước cho scene đang mở: {"id", "targets": [tên node], "hint": khóa chữ} | {"finish": true} | {} (không khóa gì).
static func step(data: Dictionary, scene_path: String) -> Dictionary:
	match phase(data):
		PHASE_STORY:
			match scene_path:
				GC.SCENE_HUB:
					return _s(["Tile_sortie"], "TUTORIAL_HUB_SORTIE")
				GC.SCENE_SORTIE:
					return _s(["Card_story"], "TUTORIAL_SORTIE_STORY")
				GC.SCENE_CHAPTERS:
					return _s(["ChapterCard_1"], "TUTORIAL_CHAPTER_CARD")
				GC.SCENE_CHAPTER_MAP:
					return _s(["Stage_1-1"], "TUTORIAL_MAP_STAGE")
				GC.SCENE_STAGE_INFO:
					return _s(["PrepareButton"], "TUTORIAL_STAGE_PREPARE")
				GC.SCENE_PARTY_PREP:
					return _s(["GoButton"], "TUTORIAL_PARTY_GO")
				GC.SCENE_STAGE:
					return _s(["RetryButton"], "TUTORIAL_RETRY")    # chỉ hiện khi màn kết quả (thua) mở
		PHASE_PULL:
			match scene_path:
				GC.SCENE_STAGE:
					return _s(["HubButton"], "TUTORIAL_RESULT_HUB")
				GC.SCENE_HUB:
					return _s(["Tile_supply"], "TUTORIAL_HUB_SUPPLY")
				GC.SCENE_SUPPLY:
					return _s(["Go_gacha"], "TUTORIAL_SUPPLY_GACHA")
				GC.SCENE_RECRUIT:
					return _s(["Wish_starter"], "TUTORIAL_RECRUIT_STARTER")
		PHASE_FINISH:
			if scene_path == GC.SCENE_RECRUIT:
				var f := _s(["ResultClose"], "TUTORIAL_RECRUIT_DONE")
				f["finish_if_missing"] = true
				return f
			if scene_path == GC.SCENE_HUB or scene_path in MENU_SCENES:
				return {"finish": true}
			return {}
		_:
			return {}
	if scene_path in MENU_SCENES:
		return _s(["MenuButton"], "TUTORIAL_MENU")
	return {}


static func _s(targets: Array, hint: String) -> Dictionary:
	return {"id": hint.trim_prefix("TUTORIAL_").to_lower(), "targets": targets, "hint": hint}


# ---------- Hội thoại với trợ lý AI ----------

static var _dialogue: Dictionary = {}


## Toàn bộ file hội thoại {"speaker_key", "player_key", "steps": {id: [{"text", "reply"}]}} (đọc một lần).
static func dialogue() -> Dictionary:
	if _dialogue.is_empty() and FileAccess.file_exists(DIALOGUE_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIALOGUE_PATH))
		if parsed is Dictionary:
			_dialogue = parsed
	return _dialogue


## Các câu của một bước: đoạn trò chuyện (nếu chưa xem) rồi câu chỉ dẫn cuối {"text": hint, "reply": ""}.
## Mỗi câu: {"text": khóa chữ của NEO, "reply": khóa câu đáp của Quản lý ("" = không có, là câu chỉ dẫn)}.
static func lines_for(data: Dictionary, step_: Dictionary) -> Array:
	var out: Array = []
	var id := str(step_.get("id", ""))
	if id != "" and not has_seen(data, id):
		var steps: Dictionary = dialogue().get("steps", {})
		for l: Variant in steps.get(id, []):
			if l is Dictionary and str(l.get("text", "")) != "":
				out.append({"text": str(l["text"]), "reply": str(l.get("reply", ""))})
	out.append({"text": str(step_.get("hint", "")), "reply": ""})
	return out


static func has_seen(data: Dictionary, id: String) -> bool:
	var t: Variant = data.get("tutorial")
	return t is Dictionary and t.get("seen") is Array and id in t["seen"]


static func mark_seen(data: Dictionary, id: String) -> void:
	if not (data.get("tutorial") is Dictionary):
		data["tutorial"] = {"done": false, "seen": []}
	if not (data["tutorial"].get("seen") is Array):
		data["tutorial"]["seen"] = []
	if id not in data["tutorial"]["seen"]:
		data["tutorial"]["seen"].append(id)


static func finish(data: Dictionary) -> void:
	if not (data.get("tutorial") is Dictionary):
		data["tutorial"] = {}
	data["tutorial"]["done"] = true
