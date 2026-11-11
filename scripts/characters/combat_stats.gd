class_name CombatStats
extends Resource
## Chỉ số chiến đấu gốc (nhân vật, quái, hình nộm).

@export var max_hp := 10000.0
@export var atk := 1000.0
@export var def := 500.0
@export_range(0.0, 1.0) var crit_rate := 0.05
@export var crit_damage := 0.5
@export_range(0.0, 1.0) var cdr := 0.0
