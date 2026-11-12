class_name StatusController
extends RefCounted
## Trạng thái đang có trên một đối tượng (CHARACTER_SKILLS mục 0, Q3, Q4).
## - REFRESH: áp lại cùng tên → làm mới thời gian, giữ độ mạnh lớn hơn (không cộng dồn).
## - STACKS: +1 tầng tới tối đa, làm mới thời gian; đủ tầng → signal max_stacks_reached.
## - Kháng sau khi hết (Choáng: 8s).
## - Nhịp sát thương (Cháy) phát signal `tick_damage`; Combatant tính số và trừ máu.
## RefCounted + tick(delta).

signal applied(status_id: String, stacks: int)
## Như `applied` nhưng kèm nguồn (Combatant gây ra); LinkTracker (Kael) nghe qua EventBus.status_applied.
signal applied_from(status_id: String, source: Object)
signal expired(status_id: String)
signal max_stacks_reached(status_id: String, source: Object)
signal tick_damage(status_id: String, atk_ratio: float, source: Object)

var library: StatusLibrary
var is_boss := false

## id -> {def, remaining, stacks, magnitude, source, tick_timer}
var _active: Dictionary = {}
var _resist: Dictionary = {}  # id -> giây kháng còn lại


func _init(lib: StatusLibrary, boss := false) -> void:
	library = lib
	is_boss = boss


## Áp trạng thái. duration/magnitude âm = mặc định StatusDef. Trả về false nếu bị từ chối
## (không có định nghĩa, đang kháng, boss miễn nhiễm, thời gian 0).
func apply(status_id: String, duration := -1.0, magnitude := -1.0, source: Object = null) -> bool:
	var def := library.get_status(status_id) if library else null
	if def == null:
		push_warning("StatusController: không có trạng thái '%s'" % status_id)
		return false
	if float(_resist.get(status_id, 0.0)) > 0.0:
		return false
	var dur := def.duration_for(is_boss, duration)
	if dur <= 0.0:
		return false
	var mag := def.default_magnitude if magnitude < 0.0 else magnitude
	if _active.has(status_id):
		var e: Dictionary = _active[status_id]
		e["remaining"] = maxf(float(e["remaining"]), dur)
		e["magnitude"] = maxf(float(e["magnitude"]), mag)
		e["source"] = source
		if def.stacking == StatusDef.Stacking.STACKS:
			var before: int = e["stacks"]
			e["stacks"] = mini(before + 1, def.max_stacks)
			if before < def.max_stacks and int(e["stacks"]) >= def.max_stacks:
				applied.emit(status_id, e["stacks"])
				applied_from.emit(status_id, source)
				max_stacks_reached.emit(status_id, source)
				return true
	else:
		_active[status_id] = {"def": def, "remaining": dur, "stacks": 1, "magnitude": mag,
				"source": source, "tick_timer": 0.0}
	applied.emit(status_id, int(_active[status_id]["stacks"]))
	applied_from.emit(status_id, source)
	return true


func remove(status_id: String) -> void:
	if _active.erase(status_id):
		expired.emit(status_id)


func has(status_id: String) -> bool:
	return _active.has(status_id)


func stacks(status_id: String) -> int:
	return int(_active[status_id]["stacks"]) if _active.has(status_id) else 0


func remaining(status_id: String) -> float:
	return float(_active[status_id]["remaining"]) if _active.has(status_id) else 0.0


func magnitude(status_id: String) -> float:
	return float(_active[status_id]["magnitude"]) if _active.has(status_id) else 0.0


func is_resisting(status_id: String) -> bool:
	return float(_resist.get(status_id, 0.0)) > 0.0


func active_ids() -> PackedStringArray:
	var out := PackedStringArray(_active.keys())
	out.sort()
	return out


func tick(delta: float) -> void:
	for id in _resist.keys():
		_resist[id] = float(_resist[id]) - delta
		if float(_resist[id]) <= 0.0:
			_resist.erase(id)
	for id in _active.keys():
		if not _active.has(id):
			continue
		var e: Dictionary = _active[id]
		var def: StatusDef = e["def"]
		# Thời gian trôi → phát các nhịp đến hạn (kể cả nhịp đúng lúc hết hạn) → xét hết hạn.
		var dt := minf(delta, float(e["remaining"]))
		e["remaining"] = float(e["remaining"]) - delta
		if def.tick_interval_sec > 0.0:
			e["tick_timer"] = float(e["tick_timer"]) + dt
			while float(e["tick_timer"]) >= def.tick_interval_sec - 0.000001:
				e["tick_timer"] = float(e["tick_timer"]) - def.tick_interval_sec
				tick_damage.emit(id, def.tick_atk_ratio, e["source"])
		if float(e["remaining"]) <= 0.000001:
			_active.erase(id)
			if def.resist_after_sec > 0.0:
				_resist[id] = def.resist_after_sec
			expired.emit(id)


# ---------- Chỉ số gộp cho DamageCalculator / di chuyển ----------

## Tổng theo một loại độ mạnh, khóa theo tên trạng thái (Q3: cùng tên chỉ một mục).
func modifiers(meaning: String) -> Dictionary:
	var out := {}
	for id in _active:
		var def: StatusDef = _active[id]["def"]
		if def.magnitude_meaning == meaning:
			out[id] = float(_active[id]["magnitude"])
	return out


func move_slow() -> float:
	var m := 0.0
	for v in modifiers(StatusDef.MAGNITUDE_MOVE_SLOW).values():
		m = maxf(m, float(v))
	return m


func blocks_movement() -> bool:
	return _any_flag("blocks_movement") or _any_flag("blocks_actions")


func blocks_actions() -> bool:
	return _any_flag("blocks_actions")


func stagger_immune() -> bool:
	return _any_flag("stagger_immune")


## Có trạng thái được tính là "hiệu ứng nguyên tố" không (Liên kết của Kael, nội tại Aether dùng has("burn")).
func has_elemental() -> bool:
	return _any_flag("counts_as_elemental")


func _any_flag(prop: String) -> bool:
	for id in _active:
		if bool((_active[id]["def"] as StatusDef).get(prop)):
			return true
	return false
