class_name RhythmProgress
extends RefCounted
## Tiến độ ải nguyên liệu nhịp điệu trong save (`data["rhythm"]`): kỷ lục từng ải / bài, ải đã qua, bài yêu thích,
## và nhận thưởng sau mỗi lượt chơi. Định nghĩa ải: data/rhythm/material_stages.json.
##
## Khóa kỷ lục: id ải (vd "rhythm_mat_01") hoặc "endless:<song_id>:<độ khó>".

const STAGES_PATH := "res://data/rhythm/material_stages.json"
## Tốc độ hiển thị "×1.0" (px / giây), chỉ để hiện trên thẻ.
const BASE_SPEED := 800.0

var profile: PlayerProfile
var defs: Dictionary


func _init(profile_: PlayerProfile, defs_: Dictionary = {}) -> void:
	profile = profile_
	defs = defs_ if not defs_.is_empty() else load_defs()


static func load_defs(path := STAGES_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"stages": [], "endless": {}, "rank_multiplier": {}}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {"stages": [], "endless": {}, "rank_multiplier": {}}


static func endless_key(song_id: String, difficulty: String) -> String:
	return "endless:%s:%s" % [song_id, difficulty]


func stages() -> Array:
	return defs.get("stages", [])


func stage(id: String) -> Dictionary:
	for s in stages():
		if str(s.get("id", "")) == id:
			return s
	return {}


func _root() -> Dictionary:
	if not (profile.data.get("rhythm") is Dictionary):
		profile.data["rhythm"] = {"records": {}, "favorites": []}
	var r: Dictionary = profile.data["rhythm"]
	if not (r.get("records") is Dictionary):
		r["records"] = {}
	if not (r.get("favorites") is Array):
		r["favorites"] = []
	return r


func record(key: String) -> Dictionary:
	var rec: Variant = _root()["records"].get(key)
	return rec if rec is Dictionary else {}


func is_cleared(key: String) -> bool:
	return bool(record(key).get("cleared", false))


## Ải mở khi ải trước đã qua (ải đầu luôn mở).
func is_unlocked(stage_id: String) -> bool:
	var list := stages()
	for i in list.size():
		if str(list[i].get("id", "")) == stage_id:
			return i == 0 or is_cleared(str(list[i - 1].get("id", "")))
	return false


func endless_unlocked() -> bool:
	var after := str(defs.get("endless", {}).get("unlock_after", ""))
	return after == "" or is_cleared(after)


func best_rank(key: String) -> String:
	return str(record(key).get("best_rank", ""))


func is_favorite(song_id: String) -> bool:
	return song_id in _root()["favorites"]


func toggle_favorite(song_id: String) -> bool:
	var fav: Array = _root()["favorites"]
	if song_id in fav:
		fav.erase(song_id)
		return false
	fav.append(song_id)
	return true


## Thưởng gốc của một lượt (chưa nhân hạng): ải nguyên liệu theo id, vô tận theo độ khó.
func base_rewards(key: String) -> Dictionary:
	if key.begins_with("endless:"):
		var diff := key.get_slice(":", 2)
		return defs.get("endless", {}).get("rewards", {}).get(diff, {})
	return stage(key).get("rewards", {})


## Tốc độ quái (px / giây) của một lượt: ải theo `note_speed` của ải, Vô tận theo độ khó; 0 = tốc độ chuẩn của luật.
func note_speed(key: String) -> float:
	if key.begins_with("endless:"):
		return float(defs.get("endless", {}).get("note_speed", {}).get(key.get_slice(":", 2), 0.0))
	return float(stage(key).get("note_speed", 0.0))


## Nhân số lượng theo hạng (làm tròn xuống, tối thiểu giữ 1 nếu gốc > 0).
func scaled_rewards(base: Dictionary, rank_: String) -> Dictionary:
	var m := float(defs.get("rank_multiplier", {}).get(rank_, 1.0))
	var out := {}
	for k in base:
		if base[k] is Dictionary:
			var sub := {}
			for id in base[k]:
				sub[id] = maxi(int(floor(int(base[k][id]) * m)), 1 if int(base[k][id]) > 0 else 0)
			out[k] = sub
		elif k == "captain_exp":
			out[k] = int(base[k])
		else:
			out[k] = maxi(int(floor(int(base[k]) * m)), 0)
	return out


## Ghi kết quả một lượt và nhận thưởng nếu qua. `result`: {cleared, score, rank, max_combo, accuracy}.
## Trả về {first_clear, new_best, rewards (đã nhận thật, dạng PlayerProfile.grant), first_clear_rewards}.
func finish(key: String, result: Dictionary) -> Dictionary:
	var out := {"first_clear": false, "new_best": false, "rewards": {}, "first_clear_rewards": {}}
	var recs: Dictionary = _root()["records"]
	var rec: Dictionary = recs.get(key, {}) if recs.get(key) is Dictionary else {}
	var cleared := bool(result.get("cleared", false))
	rec["plays"] = int(rec.get("plays", 0)) + 1
	if cleared:
		var score := int(result.get("score", 0))
		if score > int(rec.get("best_score", 0)):
			rec["best_score"] = score
			out["new_best"] = true
		var r := str(result.get("rank", "D"))
		if _rank_value(r) > _rank_value(str(rec.get("best_rank", ""))):
			rec["best_rank"] = r
		rec["best_combo"] = maxi(int(rec.get("best_combo", 0)), int(result.get("max_combo", 0)))
		rec["best_accuracy"] = maxf(float(rec.get("best_accuracy", 0.0)), float(result.get("accuracy", 0.0)))
		if not bool(rec.get("cleared", false)):
			rec["cleared"] = true
			out["first_clear"] = true
			var fc: Dictionary = stage(key).get("first_clear_rewards", {})
			if not fc.is_empty():
				out["first_clear_rewards"] = profile.grant(fc)
		out["rewards"] = profile.grant(scaled_rewards(base_rewards(key), r))
	recs[key] = rec
	return out


static func _rank_value(r: String) -> int:
	return {"S": 5, "A": 4, "B": 3, "C": 2, "D": 1}.get(r, 0)
