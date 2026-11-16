class_name RhythmChart
extends RefCounted
## Bản nốt của một bài ở một độ khó (M10). File JSON do tools/rhythm/build_catalog.py sinh từ file nhạc
## (hoặc bản cố định chỉnh tay ở server/music/fixed/). Định dạng (docs/design/RHYTHM_MODE.md mục 4):
##   {"format": 1, "song_id", "difficulty", "level", "bpm", "duration_sec",
##    "notes": [{"t": giây, "lane": "up"|"down"|"both", "kind": "tap"|"hold"|"mash", "dur": giây, "hits": n}]}
## Nốt nối tiếp nhau, không chồng thời gian: nốt chồng lên nốt trước (kể cả phần giữ / ấn liên tục) bị bỏ.

const FORMAT := 1

## Làn dạng bit: trên = 1, dưới = 2, cả hai = 3.
const LANE_UP := 1
const LANE_DOWN := 2
const LANE_BOTH := 3

const KIND_TAP := "tap"
const KIND_HOLD := "hold"
const KIND_MASH := "mash"

const LANE_NAMES := {"up": LANE_UP, "down": LANE_DOWN, "both": LANE_BOTH}

var song_id := ""
var difficulty := ""
var level := 1
var bpm := 120.0
var duration_sec := 0.0
## Mỗi nốt: {t: float, lane: int (bit), kind: String, dur: float, hits: int}.
var notes: Array[Dictionary] = []
var errors := PackedStringArray()
## Số nốt bị bỏ vì sai dạng hoặc chồng lên nốt trước.
var dropped := 0


static func from_json_text(text: String) -> RhythmChart:
	var parsed: Variant = JSON.parse_string(text)
	var c := RhythmChart.new()
	if not (parsed is Dictionary):
		c.errors.append("không đọc được JSON")
		return c
	c._read(parsed)
	return c


static func load_file(path: String) -> RhythmChart:
	if not FileAccess.file_exists(path):
		var c := RhythmChart.new()
		c.errors.append("không có file " + path)
		return c
	return from_json_text(FileAccess.get_file_as_string(path))


static func from_dict(d: Dictionary) -> RhythmChart:
	var c := RhythmChart.new()
	c._read(d)
	return c


func is_valid() -> bool:
	return errors.is_empty() and not notes.is_empty()


## Số đơn vị chấm (nốt giữ tính 2: đầu + cuối thanh).
func judgment_units() -> int:
	var n := 0
	for note in notes:
		n += 2 if note["kind"] == KIND_HOLD else 1
	return n


## Thời điểm kết thúc nốt cuối (kể cả phần giữ).
func last_note_end() -> float:
	if notes.is_empty():
		return 0.0
	var last: Dictionary = notes[notes.size() - 1]
	return float(last["t"]) + float(last["dur"])


## Bỏ nốt đến quá sát nốt trước có chung làn (tính từ lúc nốt trước kết thúc, kể cả phần giữ / ấn liên tục) để
## hitbox không đè nhau. Ảnh quái vẫn có thể chồng lên nhau. Trả về số nốt bị bỏ (cộng vào `dropped`).
func enforce_spacing(min_gap: float) -> int:
	var kept: Array[Dictionary] = []
	var last_end := {RhythmChart.LANE_UP: -INF, RhythmChart.LANE_DOWN: -INF}
	var removed := 0
	for n in notes:
		var ok := true
		for l in [LANE_UP, LANE_DOWN]:
			if int(n["lane"]) & l and float(n["t"]) - float(last_end[l]) < min_gap - 0.0005:
				ok = false
		if not ok:
			removed += 1
			continue
		kept.append(n)
		for l in [LANE_UP, LANE_DOWN]:
			if int(n["lane"]) & l:
				last_end[l] = float(n["t"]) + float(n["dur"])
	notes = kept
	dropped += removed
	return removed


## Chỉ giữ các loại nốt trong `kinds` (vd ["tap"] cho ải đầu): nốt giữ / ấn liên tục khác loại đổi thành nốt ấn
## 1 lần ở cùng thời điểm, cùng làn. Mảng rỗng = giữ nguyên. Trả về số nốt bị đổi.
func limit_kinds(kinds: Array) -> int:
	if kinds.is_empty():
		return 0
	var changed := 0
	for n in notes:
		if not str(n["kind"]) in kinds:
			n["kind"] = KIND_TAP
			n["dur"] = 0.0
			n["hits"] = 0
			changed += 1
	return changed


static func lane_name(lane: int) -> String:
	for k in LANE_NAMES:
		if LANE_NAMES[k] == lane:
			return k
	return ""


func _read(d: Dictionary) -> void:
	if int(d.get("format", 0)) != FORMAT:
		errors.append("format phải là %d" % FORMAT)
		return
	song_id = str(d.get("song_id", ""))
	difficulty = str(d.get("difficulty", ""))
	level = maxi(int(d.get("level", 1)), 1)
	bpm = maxf(float(d.get("bpm", 120.0)), 1.0)
	duration_sec = maxf(float(d.get("duration_sec", 0.0)), 0.0)
	var raw: Variant = d.get("notes", [])
	if not (raw is Array):
		errors.append("notes phải là mảng")
		return
	var list: Array[Dictionary] = []
	for r in raw:
		var n := _read_note(r)
		if n.is_empty():
			dropped += 1
		else:
			list.append(n)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["t"]) < float(b["t"]))
	var end := -INF
	for n in list:
		if float(n["t"]) <= end:
			dropped += 1
			continue
		notes.append(n)
		end = float(n["t"]) + float(n["dur"])
	if duration_sec <= 0.0:
		duration_sec = last_note_end()


func _read_note(r: Variant) -> Dictionary:
	if not (r is Dictionary):
		return {}
	var t := float(r.get("t", -1.0))
	var lane := int(LANE_NAMES.get(str(r.get("lane", "")), 0))
	var kind := str(r.get("kind", KIND_TAP))
	var dur := maxf(float(r.get("dur", 0.0)), 0.0)
	if t < 0.0 or lane == 0 or not kind in [KIND_TAP, KIND_HOLD, KIND_MASH]:
		return {}
	if kind == KIND_TAP:
		dur = 0.0
	elif dur <= 0.0:
		return {}
	var hits := 0
	if kind == KIND_MASH:
		hits = maxi(int(r.get("hits", ceili(dur * 6.0))), 1)
	return {"t": t, "lane": lane, "kind": kind, "dur": dur, "hits": hits}
