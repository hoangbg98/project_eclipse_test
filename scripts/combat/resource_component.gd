class_name ResourceComponent
extends RefCounted
## Tài nguyên của một nhân vật: HP, EN, UG, lượt né (CHARACTER_SKILLS mục 0, ghi đè 8.1).
## RefCounted + tick(delta) để vẫn chạy khi nhân vật ở dự bị (không có node trên sân).
## Mọi số lấy từ CombatRules; HP tối đa lấy từ chỉ số nhân vật.

signal hp_changed(hp: float, max_hp: float)
signal en_changed(en: float)
signal ug_changed(ug: float)
signal ultimate_ready
signal dodge_charges_changed(charges: int)
signal died

## Loại đòn trúng để cộng EN/UG (mục 0).
enum HitKind { NORMAL, HOLD, AIR, LANDING, SKILL, WEAPON, ULTIMATE, SWITCH_IN }

var rules: CombatRules
var max_hp := 1.0
var hp := 1.0
var en := 0.0
var ug := 0.0
var dodge_charges := 0
## Chỉ số giảm hồi chiêu của nhân vật (0..1); áp trần cdr_cap khi hồi lượt né.
var cdr := 0.0
## true: đang trên sân (EN +2/s); false: dự bị (EN +1/s).
var on_field := true

var _dodge_timer := 0.0


func _init(combat_rules: CombatRules, max_hp_value: float) -> void:
	rules = combat_rules
	max_hp = maxf(max_hp_value, 1.0)
	hp = max_hp
	dodge_charges = rules.dodge_charges


func is_dead() -> bool:
	return hp <= 0.0


func tick(delta: float) -> void:
	if is_dead():
		return
	add_en((rules.en_regen_per_sec if on_field else rules.reserve_en_regen_per_sec) * delta)
	_tick_dodge(delta)


# ---------- HP ----------

## Nhận sát thương; trả về lượng HP thực mất. Mất HP cộng UG (+0.3 mỗi 1% HP tối đa).
func take_damage(amount: float) -> float:
	if is_dead() or amount <= 0.0:
		return 0.0
	var lost := minf(amount, hp)
	hp -= lost
	hp_changed.emit(hp, max_hp)
	add_ug(rules.ug_per_hp_percent_lost * (lost / max_hp * 100.0))
	if hp <= 0.0:
		hp = 0.0
		died.emit()
	return lost


## Hồi máu; trả về lượng thừa vượt HP tối đa (nội tại Seraphine đổi thành khiên).
## Nhân vật đã gục không được hồi (hồi sinh tắt theo Q6).
func heal(amount: float) -> float:
	if is_dead() or amount <= 0.0:
		return 0.0
	var room := max_hp - hp
	var applied := minf(amount, room)
	hp += applied
	if applied > 0.0:
		hp_changed.emit(hp, max_hp)
	return amount - applied


func hp_ratio() -> float:
	return hp / max_hp


# ---------- EN ----------

func add_en(amount: float) -> void:
	var before := en
	en = clampf(en + amount, 0.0, rules.en_max)
	if en != before:
		en_changed.emit(en)


func can_spend_en(cost: float) -> bool:
	return not is_dead() and en >= cost


## Trừ EN nếu đủ; trả về false và giữ nguyên nếu thiếu (hành động bị từ chối an toàn).
func spend_en(cost: float) -> bool:
	if not can_spend_en(cost):
		return false
	add_en(-cost)
	return true


# ---------- UG ----------

## Cộng UG. Phần chia cho dự bị (30%) do PartyManager gọi riêng với lượng đã nhân.
func add_ug(amount: float) -> void:
	var was_full := is_ultimate_ready()
	var before := ug
	ug = clampf(ug + amount, 0.0, rules.ug_max)
	if ug != before:
		ug_changed.emit(ug)
	if not was_full and is_ultimate_ready():
		ultimate_ready.emit()


func is_ultimate_ready() -> bool:
	return ug >= rules.ug_max


## Dùng tuyệt kỹ: cần UG đầy, về 0.
func use_ultimate() -> bool:
	if is_dead() or not is_ultimate_ready():
		return false
	ug = 0.0
	ug_changed.emit(ug)
	return true


## Cộng EN/UG khi một đòn trúng. Gọi MỘT lần mỗi hit_id (không nhân theo số mục tiêu).
## Trả về lượng UG đã cộng (để PartyManager chia 30% cho dự bị).
func register_hit(kind: HitKind) -> float:
	var ug_gain := 0.0
	match kind:
		HitKind.NORMAL:
			add_en(rules.en_per_basic_hit)
			ug_gain = rules.ug_per_normal_hit
		HitKind.HOLD, HitKind.AIR, HitKind.LANDING:
			add_en(rules.en_per_basic_hit)
		HitKind.SKILL:
			ug_gain = rules.ug_per_skill_hit
		HitKind.WEAPON:
			ug_gain = rules.ug_per_weapon_hit
	if ug_gain > 0.0:
		add_ug(ug_gain)
	return ug_gain


# ---------- Né ----------

## Thời gian hồi một lượt né sau CDR (trần cdr_cap).
func dodge_recharge_time() -> float:
	return rules.dodge_recharge_sec * (1.0 - clampf(cdr, 0.0, rules.cdr_cap))


func try_dodge() -> bool:
	if is_dead() or dodge_charges <= 0:
		return false
	dodge_charges -= 1
	dodge_charges_changed.emit(dodge_charges)
	return true


## Né hoàn hảo hoàn lại lượt (mặc định 1).
func refund_dodge(count: int = -1) -> void:
	var n := rules.perfect_dodge_refund_charges if count < 0 else count
	_set_dodges(dodge_charges + n)


func _tick_dodge(delta: float) -> void:
	if dodge_charges >= rules.dodge_charges:
		_dodge_timer = 0.0
		return
	_dodge_timer += delta
	var t := dodge_recharge_time()
	while _dodge_timer >= t and dodge_charges < rules.dodge_charges:
		_dodge_timer -= t
		_set_dodges(dodge_charges + 1)
	if dodge_charges >= rules.dodge_charges:
		_dodge_timer = 0.0


func _set_dodges(n: int) -> void:
	var v := clampi(n, 0, rules.dodge_charges)
	if v != dodge_charges:
		dodge_charges = v
		dodge_charges_changed.emit(dodge_charges)
