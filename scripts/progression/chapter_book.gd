class_name ChapterBook
extends RefCounted
## Cốt truyện chính theo chương (owner 2026-11-14): nhóm chương → chương → phần → ải, đọc từ data/story/chapters.json
## (sinh bằng tools/story/gen_chapters.py). Chỉ đọc save và trả lời câu hỏi cho UI; nhận quà phần qua PlayerProfile.
##
## - Ải có `stage_id` (có màn chơi) và ải trước đã qua → chơi được; ải chưa có màn → "Sắp ra mắt".
## - Huy chương: mỗi ải 3 = 3 mục tiêu chiến đấu đã từng đạt (`progress.stages[id].objectives`).
## - Quà phần: % huy chương của phần; đủ 100% thì nhận một lần (`progress.parts_claimed`).

const DATA_PATH := "res://data/story/chapters.json"
const MEDALS_PER_STAGE := 3

const STATE_CLEARED := "cleared"
const STATE_OPEN := "open"
const STATE_LOCKED := "locked"
const STATE_SOON := "soon"

const CLAIM_OK := ""
const CLAIM_NOT_READY := "part_not_ready"
const CLAIM_DONE := "part_claimed"
const CLAIM_UNKNOWN := "part_unknown"

static var _data: Dictionary = {}

var save: Dictionary


func _init(save_data: Dictionary) -> void:
	save = save_data


static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(DATA_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_data = parsed
	return _data


static func arcs() -> Array:
	return data().get("arcs", [])


static func chapters() -> Array:
	return data().get("chapters", [])


static func chapter(num: int) -> Dictionary:
	for c: Dictionary in chapters():
		if int(c["num"]) == num:
			return c
	return {}


## Mọi ải của chương theo thứ tự.
static func stages_of(num: int) -> Array:
	var out: Array = []
	for p: Dictionary in chapter(num).get("parts", []):
		out.append_array(p["stages"])
	return out


static func all_stages() -> Array:
	var out: Array = []
	for c: Dictionary in chapters():
		out.append_array(stages_of(int(c["num"])))
	return out


## Ải (theo mã "1-1") hoặc {}.
static func stage(code: String) -> Dictionary:
	for s: Dictionary in all_stages():
		if str(s["code"]) == code:
			return s
	return {}


## Ảnh: ảnh thật trong art_dir, không có thì placeholder, không có nữa thì "".
static func art_path(image: String) -> String:
	for p: String in [str(data().get("art_dir", "")).path_join(image + ".png"),
			str(data().get("placeholder_dir", "")).path_join("placeholder_" + image + ".png")]:
		if ResourceLoader.exists(p):
			return p
	return ""


# ---------- Tiến độ ----------

func _stage_progress(stage_id: String) -> Dictionary:
	var st: Variant = save.get("progress", {}).get("stages", {}).get(stage_id)
	return st if st is Dictionary else {}


func is_cleared(s: Dictionary) -> bool:
	return str(s.get("stage_id", "")) != "" and bool(_stage_progress(str(s["stage_id"])).get("cleared", false))


func medals(s: Dictionary) -> int:
	if str(s.get("stage_id", "")) == "":
		return 0
	var objs: Variant = _stage_progress(str(s["stage_id"])).get("objectives", [])
	return mini((objs as Array).size(), MEDALS_PER_STAGE) if objs is Array else 0


## cleared / open / locked (ải trước chưa qua) / soon (chưa có màn chơi).
func state_of(s: Dictionary) -> String:
	if str(s.get("stage_id", "")) == "":
		return STATE_SOON
	if is_cleared(s):
		return STATE_CLEARED
	var all := all_stages()
	var i := all.find(s)
	if i <= 0 or is_cleared(all[i - 1]):
		return STATE_OPEN
	return STATE_LOCKED


## Ải tiếp theo nên chơi của chương (ải mở đầu tiên), không có thì ải đầu chương.
func current_stage(num: int) -> Dictionary:
	var ss := stages_of(num)
	for s: Dictionary in ss:
		if state_of(s) == STATE_OPEN:
			return s
	return ss[0] if not ss.is_empty() else {}


## Phần trăm ải đã qua của chương (0..100).
func chapter_progress(num: int) -> int:
	var ss := stages_of(num)
	if ss.is_empty():
		return 0
	var done := 0
	for s in ss:
		if is_cleared(s):
			done += 1
	return roundi(100.0 * done / ss.size())


func arc_progress(arc: Dictionary) -> int:
	var total := 0
	var done := 0
	for n in arc.get("chapters", []):
		for s in stages_of(int(n)):
			total += 1
			if is_cleared(s):
				done += 1
	return roundi(100.0 * done / total) if total > 0 else 0


## Nhóm chương chứa ải đang tới (để nút "Hành trình mới nhất"); mặc định nhóm đầu.
func latest_arc() -> Dictionary:
	for a: Dictionary in arcs():
		for n in a["chapters"]:
			for s in stages_of(int(n)):
				if state_of(s) == STATE_OPEN:
					return a
	return arcs()[0] if not arcs().is_empty() else {}


# ---------- Quà phần ----------

static func part(id: String) -> Dictionary:
	for c: Dictionary in chapters():
		for p: Dictionary in c["parts"]:
			if str(p["id"]) == id:
				return p
	return {}


## % huy chương của phần (0..100).
func part_percent(p: Dictionary) -> int:
	var ss: Array = p.get("stages", [])
	if ss.is_empty():
		return 0
	var got := 0
	for s in ss:
		got += medals(s)
	return roundi(100.0 * got / (ss.size() * MEDALS_PER_STAGE))


func part_claimed(id: String) -> bool:
	var c: Variant = save.get("progress", {}).get("parts_claimed", [])
	return c is Array and id in c


## Nhận quà phần (đủ 100% huy chương, chưa nhận). Trả về CLAIM_*; thành công thì `profile.grant` phần thưởng.
func claim_part(id: String, profile: PlayerProfile) -> String:
	var p := part(id)
	if p.is_empty():
		return CLAIM_UNKNOWN
	if part_claimed(id):
		return CLAIM_DONE
	if part_percent(p) < 100:
		return CLAIM_NOT_READY
	if not (save["progress"].get("parts_claimed") is Array):
		save["progress"]["parts_claimed"] = []
	save["progress"]["parts_claimed"].append(id)
	profile.grant(data().get("part_reward", {}))
	return CLAIM_OK
