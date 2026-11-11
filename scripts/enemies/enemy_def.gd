class_name EnemyDef
extends Resource
## Định nghĩa tĩnh một loại quái thường (README 5 Enemies). Dữ liệu: data/enemies/{id}.tres.
## Giá trị ban đầu do Claude đặt (ARCHITECTURE mục 4), owner chỉnh sau khi chơi thử.

@export var id := ""
@export var name_key := ""
@export var stats: CombatStats

@export_group("Sức choáng (SC)")
## Thanh SC; đầy → Choáng (StatusDef stun: 2 s, sau đó kháng 8 s).
@export var sc_max := 300.0
## Không bị đánh trong bấy nhiêu giây thì SC tự giảm.
@export var sc_decay_delay_sec := 2.0
@export var sc_decay_per_sec := 40.0

@export_group("Di chuyển")
@export var move_speed := 160.0
@export var gravity := 2400.0
## Tuần tra quanh điểm xuất hiện ± bấy nhiêu px.
@export var patrol_radius := 200.0
## Nghỉ ở mỗi đầu đường tuần tra (s).
@export var patrol_pause_sec := 0.8

@export_group("AI")
## Thấy người chơi trong bán kính này thì đuổi.
@export var detect_range := 700.0
## Mất dấu nếu người chơi ra xa quá mức này.
@export var lose_range := 1000.0
## Đứng cách người chơi trong khoảng này thì đánh (tính theo trục ngang).
@export var attack_range := 170.0
## Nghỉ giữa hai lần đánh (s), tính từ khi đòn kết thúc.
@export var attack_cooldown_sec := 1.5
@export var attack: SkillDef

@export_group("Phản ứng")
## Bị khựng bao lâu khi trúng đòn (s). Boss có thể đặt 0 (kháng khựng).
@export var stagger_sec := 0.25
## Đẩy lùi tối thiểu khi khựng (px), cộng với đẩy lùi của đòn.
@export var stagger_push_px := 20.0
## Thời gian mờ dần khi chết (s).
@export var death_fade_sec := 0.6
## Màu tạm của thân (placeholder).
@export var placeholder_color := Color(0.45, 0.8, 0.35)
