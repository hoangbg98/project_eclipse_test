class_name BattleObjectives
extends RefCounted
## Mục tiêu chiến đấu của một màn (owner 2026-11-14): mỗi mục tiêu đạt được khi qua màn thưởng thêm vàng.
## Dữ liệu trong data/stages/{id}.json, mục "objectives":
##   [{"id": "no_down", "type": "downs_max", "value": 0, "gold": 200}, ...]
## Loại (type):
##   time_max          qua màn trong `value` giây
##   hits_taken_max    cả đội chịu không quá `value` đòn
##   damage_taken_max  tổng sát thương cả đội chịu không quá `value`
##   downs_max         không quá `value` đồng đội gục
## Lớp này đếm số liệu trong trận (`track(party)`) và chấm điểm; StageController trao vàng, lưu mục tiêu đã đạt.

const TYPE_TIME_MAX := "time_max"
const TYPE_HITS_TAKEN_MAX := "hits_taken_max"
const TYPE_DAMAGE_TAKEN_MAX := "damage_taken_max"
const TYPE_DOWNS_MAX := "downs_max"
const TYPES: Array[String] = [TYPE_TIME_MAX, TYPE_HITS_TAKEN_MAX, TYPE_DAMAGE_TAKEN_MAX, TYPE_DOWNS_MAX]

## Số đòn (có sát thương) cả đội đã chịu.
var hits_taken := 0
## Tổng sát thương cả đội đã chịu (cả sát thương theo thời gian).
var damage_taken := 0
## Số lần một thành viên gục.
var downs := 0


## Nghe sát thương / gục của mọi thành viên trong đội.
func track(party: PartyManager) -> void:
	for m in party.members:
		m.combatant().damaged.connect(_on_damaged)
		m.combatant().dot_damaged.connect(_on_dot_damaged)
	party.member_down.connect(_on_member_down)


func _on_damaged(result: DamageCalculator.Result, _hit: HitInfo) -> void:
	if result.amount <= 0:
		return
	hits_taken += 1
	damage_taken += result.amount


func _on_dot_damaged(amount: int, _status_id: String) -> void:
	damage_taken += maxi(amount, 0)


func _on_member_down(_m: CharacterRuntime) -> void:
	downs += 1


## Số liệu để chấm điểm.
func stats(time_sec: float) -> Dictionary:
	return {"time_sec": time_sec, "hits_taken": hits_taken, "damage_taken": damage_taken, "downs": downs}


## Mục tiêu hợp lệ trong dữ liệu màn (bỏ mục sai loại / thiếu id).
static func list_of(stage_data: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var raw: Variant = stage_data.get("objectives", [])
	if not (raw is Array):
		return out
	for o: Variant in raw:
		if o is Dictionary and str(o.get("id", "")) != "" and str(o.get("type", "")) in TYPES:
			out.append(o)
	return out


static func is_met(objective: Dictionary, s: Dictionary) -> bool:
	var v := float(objective.get("value", 0))
	match str(objective.get("type", "")):
		TYPE_TIME_MAX:
			return float(s.get("time_sec", INF)) <= v
		TYPE_HITS_TAKEN_MAX:
			return float(s.get("hits_taken", INF)) <= v
		TYPE_DAMAGE_TAKEN_MAX:
			return float(s.get("damage_taken", INF)) <= v
		TYPE_DOWNS_MAX:
			return float(s.get("downs", INF)) <= v
	return false


## Chấm điểm: [{id, type, value, gold, met}] theo thứ tự trong dữ liệu.
static func evaluate(objectives: Array[Dictionary], s: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in objectives:
		var r := o.duplicate()
		r["gold"] = maxi(int(o.get("gold", 0)), 0)
		r["met"] = is_met(o, s)
		out.append(r)
	return out


## Tổng vàng thưởng của các mục tiêu đã đạt.
static func gold_of(results: Array[Dictionary]) -> int:
	var g := 0
	for r in results:
		if bool(r.get("met", false)):
			g += int(r.get("gold", 0))
	return g


## Câu mô tả mục tiêu (đã dịch).
static func describe(objective: Dictionary) -> String:
	var v := int(objective.get("value", 0))
	match str(objective.get("type", "")):
		TYPE_TIME_MAX:
			return TranslationServer.translate("OBJ_TIME_MAX") % StageHud.format_time(float(v))
		TYPE_HITS_TAKEN_MAX:
			return TranslationServer.translate("OBJ_HITS_TAKEN_MAX") % v
		TYPE_DAMAGE_TAKEN_MAX:
			return TranslationServer.translate("OBJ_DAMAGE_TAKEN_MAX") % v
		TYPE_DOWNS_MAX:
			return TranslationServer.translate("OBJ_NO_DOWNS") if v <= 0 else TranslationServer.translate("OBJ_DOWNS_MAX") % v
	return str(objective.get("id", ""))
