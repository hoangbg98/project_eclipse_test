class_name TrainingDummy
extends Node2D
## Hình nộm tập (màn thử nghiệm): nhận đòn, hiện số sát thương, trạng thái, DPS; không đánh lại.
## Không bị đánh trong `reset_after_sec` thì hồi đầy máu và xoá trạng thái.

@export var reset_after_sec := 3.0
## Cửa sổ tính DPS (s).
@export var dps_window_sec := 5.0

@onready var combatant: Combatant = $Combatant
@onready var info: Label = $Info
@onready var body: Polygon2D = $Body

var _idle := 0.0
var _log: Array = []  # [thời điểm, lượng]
var _time := 0.0
var _flash := 0.0
var total_damage := 0


func _ready() -> void:
	combatant.damaged.connect(_on_damaged)
	combatant.dot_damaged.connect(_on_dot)


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	_time += delta
	combatant.tick(delta)
	_idle += delta
	if _idle >= reset_after_sec and combatant.resources.hp < combatant.resources.max_hp:
		combatant.resources.hp = combatant.resources.max_hp
		for id in combatant.statuses.active_ids():
			combatant.statuses.remove(id)
		_log.clear()
	_flash = maxf(_flash - delta, 0.0)
	body.modulate = Color(1.6, 1.3, 1.3) if _flash > 0.0 else Color.WHITE
	_update_info()


func dps() -> float:
	var cutoff := _time - dps_window_sec
	var s := 0.0
	for e in _log:
		if float(e[0]) >= cutoff:
			s += float(e[1])
	return s / dps_window_sec


func _on_damaged(result: DamageCalculator.Result, _hit: HitInfo) -> void:
	_record(result.amount)
	_flash = 0.08
	FloatingNumber.spawn(get_parent(), global_position + Vector2(0, -260), result.amount, result.is_crit)


func _on_dot(amount: int, _status_id: String) -> void:
	_record(amount)
	FloatingNumber.spawn(get_parent(), global_position + Vector2(40, -200), amount, false, true)


func _record(amount: int) -> void:
	_idle = 0.0
	total_damage += amount
	_log.append([_time, amount])
	while _log.size() > 400:
		_log.pop_front()


func _update_info() -> void:
	var r := combatant.resources
	var names := PackedStringArray()
	for id in combatant.statuses.active_ids():
		var s := combatant.statuses
		var n := tr("STATUS_" + id.to_upper())
		if s.stacks(id) > 1:
			n += " ×%d" % s.stacks(id)
		names.append("%s %.1fs" % [n, s.remaining(id)])
	info.text = "%s %d / %d\nDPS %d\n%s" % [tr("DUMMY_HP"), int(r.hp), int(r.max_hp), int(dps()), "\n".join(names)]
