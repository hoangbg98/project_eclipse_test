class_name Combatant
extends Node
## Thành phần chiến đấu gắn vào nhân vật / quái / hình nộm (đặt tên node "Combatant").
## Giữ chỉ số, tài nguyên, hồi chiêu, trạng thái; nhận đòn từ Hurtbox và tính sát thương.

## Sau khi trúng đòn và trừ máu.
signal damaged(result: DamageCalculator.Result, hit: HitInfo)
## Sát thương theo nhịp (Cháy...).
signal dot_damaged(amount: int, status_id: String)
## Người đánh: đòn của mình trúng một mục tiêu.
signal hit_dealt(target: Combatant, result: DamageCalculator.Result, hit: HitInfo)

@export var team := PhysicsLayers.Team.PLAYER
@export var stats: CombatStats
@export var is_boss := false
## Hurtbox để nghe đòn; mặc định tìm anh em tên "Hurtbox".
@export var hurtbox_path: NodePath = ^"../Hurtbox"
## false: chủ (vd PlayerController) gán chỉ số rồi tự gọi setup() (vì _ready của con chạy trước cha).
@export var auto_setup := true

var rules: CombatRules
var resources: ResourceComponent
var cooldowns: CooldownController
var statuses: StatusController
var rng: RandomSource
## % tăng ATK đang có (nội tại, buff), khóa theo nguồn.
var atk_bonus: Dictionary = {}
## % tăng sát thương đang có, khóa theo nguồn.
var damage_bonus: Dictionary = {}

var _registered_hits: Dictionary = {}  # hit_id -> true (cộng EN/UG một lần mỗi nhát)


## Lấy Combatant của một node thực thể (node đó hoặc con tên "Combatant").
static func of(node: Object) -> Combatant:
	if node is Combatant:
		return node
	if node is Node:
		return (node as Node).get_node_or_null("Combatant") as Combatant
	return null


## Nhóm chứa node thực thể (cha của Combatant) để tìm mục tiêu.
const GROUP := &"combatants"


func _ready() -> void:
	if get_parent():
		get_parent().add_to_group(GROUP)
	if auto_setup:
		setup()


## Tạo các thành phần và nối Hurtbox; gọi lại an toàn.
func setup(seed_value := 0) -> void:
	if resources != null:
		return
	if is_inside_tree():
		var hb := get_node_or_null(hurtbox_path) as Hurtbox
		if hb and not hb.hit_received.is_connected(receive_hit):
			hb.hit_received.connect(receive_hit)
	var gc := _game_config()
	rules = gc.combat_rules if gc else load("res://data/config/combat_rules.tres")
	var lib: StatusLibrary = gc.statuses if gc else StatusLibrary.load_dir()
	if stats == null:
		stats = CombatStats.new()
	resources = ResourceComponent.new(rules, stats.max_hp)
	resources.cdr = stats.cdr
	cooldowns = CooldownController.new(rules)
	cooldowns.cdr = stats.cdr
	statuses = StatusController.new(lib, is_boss)
	statuses.tick_damage.connect(_on_status_tick)
	statuses.applied_from.connect(_on_status_applied)
	statuses.max_stacks_reached.connect(_on_status_max_stacks)
	rng = RandomSource.new(seed_value)


func tick(delta: float) -> void:
	resources.tick(delta)
	cooldowns.tick(delta)
	statuses.tick(delta)


func current_atk() -> float:
	return stats.atk * (1.0 + _sum(atk_bonus))


## Ảnh chụp chỉ số người đánh cho DamageCalculator.
func attacker_snapshot(extra_bonus: Dictionary = {}) -> DamageCalculator.Attacker:
	var a := DamageCalculator.Attacker.new()
	a.atk = current_atk()
	a.crit_rate = stats.crit_rate
	a.crit_damage = stats.crit_damage
	a.damage_bonus = damage_bonus.duplicate()
	a.damage_bonus.merge(statuses.modifiers(StatusDef.MAGNITUDE_DAMAGE_DEALT_UP), true)
	a.damage_bonus.merge(extra_bonus, true)
	a.damage_dealt_down = statuses.modifiers(StatusDef.MAGNITUDE_DAMAGE_DEALT_DOWN)
	return a


func target_snapshot() -> DamageCalculator.Target:
	var t := DamageCalculator.Target.new()
	t.def = stats.def
	t.def_reduction = statuses.modifiers(StatusDef.MAGNITUDE_DEF_REDUCTION)
	t.damage_taken_up = statuses.modifiers(StatusDef.MAGNITUDE_DAMAGE_TAKEN_UP)
	t.damage_taken_down = statuses.modifiers(StatusDef.MAGNITUDE_DAMAGE_TAKEN_DOWN)
	return t


## Hurtbox gọi khi trúng thật. Tính sát thương bằng chỉ số người đánh, trừ máu, áp trạng thái.
func receive_hit(hit: HitInfo) -> DamageCalculator.Result:
	var src := Combatant.of(hit.attacker)
	var a: DamageCalculator.Attacker
	var bonus := hit.damage_bonus
	if hit.bonus_vs_status != "" and statuses.has(hit.bonus_vs_status):
		bonus = bonus.duplicate()
		bonus["vs_" + hit.bonus_vs_status] = hit.bonus_vs_status_ratio
	if src:
		a = src.attacker_snapshot(bonus)
	else:
		a = DamageCalculator.Attacker.from_rules(rules, 0.0)
	var roll_rng := src.rng if src else rng
	hit.target_statuses_before = statuses.active_ids()
	var result := DamageCalculator.compute(rules, a, target_snapshot(), hit.atk_ratio, hit.skill_level, roll_rng)
	var was_alive := not resources.is_dead()
	resources.take_damage(result.amount)
	hit.killed_target = was_alive and resources.is_dead()
	for s in hit.statuses:
		if s.on_self:
			if src:
				src.statuses.apply(s.status_id, s.duration, s.magnitude, src)
		else:
			statuses.apply(s.status_id, s.duration, s.magnitude, src)
	damaged.emit(result, hit)
	if src:
		src._on_hit_dealt(self, result, hit)
	var bus := _bus()
	if bus:
		bus.hit_landed.emit(src, self, result, hit)
	return result


func _on_hit_dealt(target: Combatant, result: DamageCalculator.Result, hit: HitInfo) -> void:
	if not _registered_hits.has(hit.hit_id):
		_registered_hits[hit.hit_id] = true
		if _registered_hits.size() > 256:
			_registered_hits.clear()
			_registered_hits[hit.hit_id] = true
		resources.register_hit(hit.hit_kind)
		if hit.extra_en > 0.0:
			resources.add_en(hit.extra_en)
	hit_dealt.emit(target, result, hit)


func _on_status_tick(status_id: String, atk_ratio: float, source: Object) -> void:
	var src := source as Combatant
	if src == null or not is_instance_valid(src):
		return
	# Sát thương nhịp: qua công thức (DEF, Phán quyết...) nhưng không chí mạng.
	var a := src.attacker_snapshot()
	a.crit_rate = 0.0
	var result := DamageCalculator.compute(rules, a, target_snapshot(), atk_ratio, 1, rng)
	resources.take_damage(result.amount)
	dot_damaged.emit(result.amount, status_id)
	var bus := _bus()
	if bus:
		bus.dot_landed.emit(self, result.amount, status_id)


func _on_status_applied(status_id: String, source: Object) -> void:
	var bus := _bus()
	if bus:
		bus.status_applied.emit(self, status_id, source)


## Đủ tầng (vd 3 Dấu Sét → Bùng nổ Sét): báo lên EventBus.
func _on_status_max_stacks(status_id: String, source: Object) -> void:
	var bus := _bus()
	if bus:
		bus.status_max_stacks.emit(self, status_id, source)


func _game_config() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("GameConfig")
	return null


func _bus() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("EventBus")
	return null


static func _sum(d: Dictionary) -> float:
	var s := 0.0
	for v in d.values():
		s += float(v)
	return s
