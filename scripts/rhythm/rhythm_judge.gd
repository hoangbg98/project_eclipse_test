class_name RhythmJudge
extends RefCounted
## Bộ chấm của chế độ nhịp điệu (M10, docs/design/RHYTHM_MODE.md mục 3). Logic thuần: không đọc phím, không
## đọc đồng hồ nhạc. Màn chơi gọi `press` / `release` với thời điểm trong bài và `update(t)` mỗi frame.
##
## Luật:
## - Mỗi nốt đòi đúng MỘT trong 3 lựa chọn: trên, dưới hoặc cả hai (ấn hai phím cách nhau ≤ chord_window).
##   Lần ấn đầu tiên trong cửa sổ quyết định; chọn nhầm = "wrong", mất HP, mất combo.
## - Ấn khi chưa có nốt nào trong cửa sổ: không sao (vung đòn trống).
## - Để nốt trôi qua = "miss", mất HP.
## - Giữ (hold): chấm đầu thanh như nốt thường, rồi phải giữ đủ (các) phím tới cuối thanh; thả sớm = gãy.
## - Ấn liên tục (mash): ấn đúng làn càng nhiều càng tốt tới hết thời gian; chấm theo tỉ lệ số lần / yêu cầu.

signal judged(index: int, result: String, unit: String)   # result: perfect | great | miss | wrong; unit: head | tail | note
signal mash_hit(index: int, count: int)
signal empty_press(lane: int)
signal hp_changed(hp: int)
signal fever_started(until: float)
signal failed

const PERFECT := "perfect"
const GREAT := "great"
const MISS := "miss"
const WRONG := "wrong"

const _PENDING := 0
const _ACTIVE := 1
const _DONE := 2

var rules: RhythmRules
var chart: RhythmChart
## Trạng thái từng nốt: {state, result, count, start}.
var states: Array[Dictionary] = []
var cursor := 0
var held := 0
var hp := 0
var score := 0
var combo := 0
var max_combo := 0
var counts := {PERFECT: 0, GREAT: 0, MISS: 0, WRONG: 0}
var fever := 0.0
var fever_until := -1.0
var is_failed := false
var now := 0.0

## Lần ấn đang chờ đủ chord_window: {idx, mask, time}; rỗng = không có.
var _pending: Dictionary = {}


func _init(rules_: RhythmRules, chart_: RhythmChart) -> void:
	rules = rules_
	chart = chart_
	hp = rules.max_hp
	for i in chart.notes.size():
		states.append({"state": _PENDING, "result": "", "count": 0, "start": 0.0})


func is_finished() -> bool:
	return is_failed or cursor >= chart.notes.size()


func in_fever() -> bool:
	return now < fever_until


## Đơn vị đã chấm (trừ phần chưa tới).
func judged_units() -> int:
	return int(counts[PERFECT]) + int(counts[GREAT]) + int(counts[MISS]) + int(counts[WRONG])


## Độ chính xác trên toàn bài (đơn vị chưa chấm tính là trượt).
func accuracy() -> float:
	var total := chart.judgment_units()
	if total <= 0:
		return 0.0
	return (float(counts[PERFECT]) + float(counts[GREAT]) * 0.5) / float(total)


func rank() -> String:
	return rank_of(accuracy(), rules)


static func rank_of(acc: float, r: RhythmRules) -> String:
	if acc >= r.rank_s:
		return "S"
	if acc >= r.rank_a:
		return "A"
	if acc >= r.rank_b:
		return "B"
	if acc >= r.rank_c:
		return "C"
	return "D"


## Vương miện (0-3) theo hạng: S = 3, A = 2, B = 1.
static func crowns_of(rank_: String) -> int:
	return {"S": 3, "A": 2, "B": 1}.get(rank_, 0)


func press(lane: int, t: float) -> void:
	update(t)
	held |= lane
	if is_finished():
		return
	var idx := cursor
	var note: Dictionary = chart.notes[idx]
	var st: Dictionary = states[idx]
	if st["state"] == _ACTIVE:
		if note["kind"] == RhythmChart.KIND_MASH and _mash_accepts(note, lane):
			st["count"] = int(st["count"]) + 1
			_add_score(rules.score_mash_hit, false)
			mash_hit.emit(idx, int(st["count"]))
		return
	if not _pending.is_empty():
		_pending["mask"] = int(_pending["mask"]) | lane
		if int(_pending["mask"]) == RhythmChart.LANE_BOTH:
			_resolve_pending()
		return
	if t < float(note["t"]) - rules.great_window:
		empty_press.emit(lane)
		return
	if note["kind"] == RhythmChart.KIND_MASH:
		if _mash_accepts(note, lane):
			_start(idx, PERFECT, t)
			st["count"] = 1
			_add_score(rules.score_mash_hit, false)
			mash_hit.emit(idx, 1)
		else:
			_finish(idx, WRONG, "note")
		return
	_pending = {"idx": idx, "mask": lane, "time": t}
	if lane == RhythmChart.LANE_BOTH:
		_resolve_pending()


func release(lane: int, t: float) -> void:
	held &= ~lane
	update(t)


## Đẩy thời gian tới `t`: chốt lần ấn đang chờ, kết thúc giữ / ấn liên tục, cho nốt quá hạn thành trượt.
func update(t: float) -> void:
	now = maxf(now, t)
	if is_failed:
		return
	if not _pending.is_empty() and t - float(_pending["time"]) >= rules.chord_window:
		_resolve_pending()
	while cursor < chart.notes.size() and not is_failed:
		var note: Dictionary = chart.notes[cursor]
		var st: Dictionary = states[cursor]
		var end := float(note["t"]) + float(note["dur"])
		if st["state"] == _ACTIVE:
			if note["kind"] == RhythmChart.KIND_HOLD:
				var need := int(note["lane"])
				if held & need != need and t < end - rules.hold_release_tolerance:
					_tail(cursor, false)
					continue
				if t >= end:
					_tail(cursor, true)
					continue
			elif t >= end:
				_finish_mash(cursor)
				continue
			break
		if not _pending.is_empty():
			break
		var deadline := end if note["kind"] == RhythmChart.KIND_MASH else float(note["t"]) + rules.great_window
		if t > deadline:
			_finish(cursor, MISS, "note" if note["kind"] != RhythmChart.KIND_HOLD else "head")
			if note["kind"] == RhythmChart.KIND_HOLD and not is_failed:
				_count(MISS, cursor, "tail", false)
			continue
		break


func _mash_accepts(note: Dictionary, lane: int) -> bool:
	return lane & int(note["lane"]) != 0 if int(note["lane"]) == RhythmChart.LANE_BOTH else lane == int(note["lane"])


func _resolve_pending() -> void:
	var idx := int(_pending["idx"])
	var mask := int(_pending["mask"])
	var time := float(_pending["time"])
	_pending = {}
	var note: Dictionary = chart.notes[idx]
	if mask != int(note["lane"]):
		_finish(idx, WRONG, "note" if note["kind"] != RhythmChart.KIND_HOLD else "head")
		if note["kind"] == RhythmChart.KIND_HOLD and not is_failed:
			_count(WRONG, idx, "tail", false)
		return
	var off := absf(time - float(note["t"]))
	var res := PERFECT if off <= rules.perfect_window else GREAT
	if note["kind"] == RhythmChart.KIND_HOLD:
		_start(idx, res, time)
		_count(res, idx, "head", true)
	else:
		_finish(idx, res, "note")


func _start(idx: int, res: String, t: float) -> void:
	states[idx]["state"] = _ACTIVE
	states[idx]["result"] = res
	states[idx]["start"] = t


func _tail(idx: int, ok: bool) -> void:
	states[idx]["state"] = _DONE
	cursor = idx + 1
	_count(PERFECT if ok else MISS, idx, "tail", true, rules.hold_break_damage)


func _finish_mash(idx: int) -> void:
	var note: Dictionary = chart.notes[idx]
	var ratio := float(states[idx]["count"]) / float(maxi(int(note["hits"]), 1))
	var res := MISS
	if ratio >= rules.mash_perfect_ratio:
		res = PERFECT
	elif ratio >= rules.mash_great_ratio:
		res = GREAT
	_finish(idx, res, "note")


func _finish(idx: int, res: String, unit: String) -> void:
	states[idx]["state"] = _DONE
	states[idx]["result"] = res
	cursor = idx + 1
	_count(res, idx, unit, true)


## Ghi một đơn vị chấm. `apply` = cộng điểm / trừ HP / combo (false: chỉ đếm, vd phần cuối của nốt giữ đã trượt).
func _count(res: String, idx: int, unit: String, apply: bool, miss_damage := -1) -> void:
	counts[res] = int(counts[res]) + 1
	if apply:
		match res:
			PERFECT, GREAT:
				combo += 1
				max_combo = maxi(max_combo, combo)
				_add_score(rules.score_perfect if res == PERFECT else rules.score_great, true)
				_gain_fever(rules.fever_gain_perfect if res == PERFECT else rules.fever_gain_great)
			MISS:
				combo = 0
				_damage(rules.miss_damage if miss_damage < 0 else miss_damage)
			WRONG:
				combo = 0
				_damage(rules.wrong_damage)
	judged.emit(idx, res, unit)


func _add_score(base: int, with_combo: bool) -> void:
	var s := float(base)
	if with_combo:
		s *= 1.0 + float(mini(combo, rules.combo_bonus_cap)) * rules.combo_bonus_step
	if in_fever():
		s *= rules.fever_score_multiplier
	score += int(round(s))


func _gain_fever(v: float) -> void:
	if in_fever():
		return
	fever += v
	if fever >= rules.fever_max:
		fever = 0.0
		fever_until = now + rules.fever_duration
		fever_started.emit(fever_until)


func _damage(v: int) -> void:
	if v <= 0:
		return
	hp = maxi(hp - v, 0)
	hp_changed.emit(hp)
	if hp == 0 and not is_failed:
		is_failed = true
		failed.emit()
