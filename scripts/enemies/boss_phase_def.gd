class_name BossPhaseDef
extends Resource
## Một pha của boss (README "Boss phase controller"): điều kiện vào pha và bộ đòn của pha.

## Vào pha này khi HP ≤ tỉ lệ này (pha đầu đặt 1.0).
@export_range(0.0, 1.0) var hp_ratio_below := 1.0
## Các đòn của pha; boss dùng lần lượt theo thứ tự rồi lặp lại.
@export var attacks: Array[SkillDef] = []
## Nghỉ giữa hai đòn (s).
@export var attack_cooldown_sec := 1.6
## Đứng cách người chơi trong khoảng này thì ra đòn (px, trục ngang).
@export var attack_range := 260.0
@export var move_speed_multiplier := 1.0
