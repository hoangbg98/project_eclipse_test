class_name CooldownController
extends RefCounted
## Hồi chiêu của một nhân vật (CHARACTER_SKILLS mục 0, 8.2).
## - CDR (trần cdr_cap = 40%) áp khi BẮT ĐẦU hồi: Kĩ năng thường, Kĩ năng vũ khí, SI-CD.
## - Tuyệt kỹ không có ở đây (dùng UG).
## - "Rút ngắn CD riêng": trừ thẳng thời gian còn lại, không bị trần CDR,
##   nhưng mỗi khóa có mức tối đa mỗi chu kỳ hồi để tránh lặp vô hạn.
## RefCounted + tick(delta): vẫn đếm khi nhân vật ở dự bị.

signal cooldown_started(key: StringName, duration: float)
signal cooldown_ready(key: StringName)

var rules: CombatRules
## Chỉ số giảm hồi chiêu của nhân vật (0..1, trước trần).
var cdr := 0.0

var _base: Dictionary = {}       # key -> giây gốc
var _remaining: Dictionary = {}  # key -> giây còn lại
var _uses_cdr: Dictionary = {}   # key -> bool
var _reduced: Dictionary = {}    # key -> giây đã rút trong chu kỳ hiện tại
var _cycle: Dictionary = {}      # key -> độ dài chu kỳ hiện tại (sau CDR)
var _floor: Dictionary = {}      # key -> tỉ lệ sàn: chu kỳ thực tế ≥ tỉ lệ × giây gốc (EQUIPMENT_5STAR 3.4 dòng 1)


## Sàn CD: tổng rút ngắn riêng trong một chu kỳ không làm chu kỳ ngắn hơn `ratio` × giây gốc đã khai báo.
func set_floor(key: StringName, ratio: float) -> void:
	_floor[key] = clampf(ratio, 0.0, 1.0)


func _init(combat_rules: CombatRules) -> void:
	rules = combat_rules


## Khai báo một hồi chiêu (thời gian gốc từ SkillDef / LinkRules).
func register(key: StringName, base_sec: float, uses_cdr := true) -> void:
	_base[key] = maxf(base_sec, 0.0)
	_remaining[key] = 0.0
	_uses_cdr[key] = uses_cdr
	_reduced[key] = 0.0


func has(key: StringName) -> bool:
	return _base.has(key)


## CDR thực tế sau trần.
func effective_cdr() -> float:
	return clampf(cdr, 0.0, rules.cdr_cap)


## Thời gian hồi đầy đủ của khóa sau CDR.
func duration_of(key: StringName) -> float:
	var base: float = _base.get(key, 0.0)
	return base * (1.0 - effective_cdr()) if _uses_cdr.get(key, true) else base


func is_ready(key: StringName) -> bool:
	return has(key) and float(_remaining[key]) <= 0.0


func remaining(key: StringName) -> float:
	return float(_remaining.get(key, 0.0))


## 0 = vừa bắt đầu hồi, 1 = sẵn sàng (cho vòng hồi trên HUD).
func progress(key: StringName) -> float:
	var d := duration_of(key)
	if d <= 0.0:
		return 1.0
	return 1.0 - clampf(remaining(key) / d, 0.0, 1.0)


## Dùng kỹ năng: chỉ khi sẵn sàng; bắt đầu chu kỳ hồi mới.
func trigger(key: StringName) -> bool:
	if not is_ready(key):
		return false
	var d := duration_of(key)
	_remaining[key] = d
	_reduced[key] = 0.0
	_cycle[key] = d
	cooldown_started.emit(key, d)
	if d <= 0.0:
		cooldown_ready.emit(key)
	return true


## Rút ngắn CD riêng: trừ thẳng `seconds`, tối đa `max_per_cycle` mỗi chu kỳ (âm = không giới hạn).
## Trả về số giây thực sự rút được.
func reduce(key: StringName, seconds: float, max_per_cycle: float = -1.0) -> float:
	if not has(key) or seconds <= 0.0 or is_ready(key):
		return 0.0
	var allowed := seconds
	if max_per_cycle >= 0.0:
		allowed = minf(allowed, maxf(max_per_cycle - float(_reduced[key]), 0.0))
	if _floor.has(key):
		var room := float(_cycle.get(key, 0.0)) - float(_floor[key]) * float(_base[key]) - float(_reduced[key])
		allowed = minf(allowed, maxf(room, 0.0))
	var applied := minf(allowed, remaining(key))
	if applied <= 0.0:
		return 0.0
	_reduced[key] = float(_reduced[key]) + applied
	_set_remaining(key, remaining(key) - applied)
	return applied


func tick(delta: float) -> void:
	for key in _remaining.keys():
		var r: float = _remaining[key]
		if r > 0.0:
			_set_remaining(key, r - delta)


## Phần dư nhỏ hơn mức này coi như 0 (cộng/trừ delta dấu phẩy động để lại ~1e-15 s).
const EPSILON := 0.000001


func _set_remaining(key: StringName, value: float) -> void:
	var was_ready := float(_remaining[key]) <= 0.0
	_remaining[key] = value if value > EPSILON else 0.0
	if not was_ready and float(_remaining[key]) <= 0.0:
		cooldown_ready.emit(key)
