class_name PartyManager
extends Node
## Đội 3 người, 1 người trên sân (CHARACTER_SKILLS 8.1, 8.2; ARCHITECTURE mục 6).
## - Chuyển bằng `switch_1` / `switch_2` (2 icon dự bị theo thứ tự trong đội, bỏ người trên sân).
## - Chờ chung `switch_cooldown_sec` giữa hai lần chuyển; khóa khi đang trong tuyệt kỹ chuỗi đòn;
##   không chuyển sang nhân vật đã gục.
## - Dự bị: EN +1/s (ResourceComponent.on_field = false), nhận `reserve_ug_share` UG mà người trên sân nhận.
## - Người trên sân gục: sau `down_auto_switch_sec` tự đưa người dự bị còn sống đầu tiên vào (vào mặc định);
##   cả đội gục → `party_defeated`.
## - Liên kết / SI-CD: LinkTracker (M4-3); PartyManager cấp sự kiện từ EventBus và người trên sân.
## - Kĩ năng vào sân (M4-4): Thường chạy `switch_in`, Liên kết chạy `switch_in_linked` (thiếu thì `switch_in`),
##   mặc định không chạy kỹ năng; áp buff bản thân và giảm SI-CD riêng theo SwitchInDef.
## - Phản ứng nguyên tố (M4-5): chỉ khi vào sân Liên kết; nổ tại kẻ địch đầu tiên trúng Kĩ năng vào sân
##   (Thanh Phong, Thánh Giáp nổ ngay tại người vào sân); ICD chung do ReactionResolver giữ.

## mode: LinkTracker.MODE_LINKED | MODE_NORMAL | MODE_DEFAULT.
signal switched(from: CharacterRuntime, to: CharacterRuntime, mode: String)
signal switch_rejected(index: int, reason: String)
## Một thành viên gục.
signal member_down(member: CharacterRuntime)
## Cả đội gục.
signal party_defeated

const PLAYER_SCENE := preload("res://scenes/player/player_character.tscn")

const REASON_COOLDOWN := "switch_cooldown"
const REASON_LOCKED := "switch_locked"
const REASON_DOWN := "member_down"
const REASON_ACTIVE := "already_active"
const REASON_INVALID := "invalid"

## Nút chuyển → ô dự bị (0, 1).
const SWITCH_ACTIONS: Array[StringName] = [&"switch_1", &"switch_2"]
const SKILL_SWITCH_IN := "switch_in"
const SKILL_SWITCH_IN_LINKED := "switch_in_linked"
## Trạng thái đủ tầng tính là Bùng nổ Sét (giảm SI-CD Kael).
const LIGHTNING_MARK := "lightning_mark"

## Tắt để test tự gọi `request_switch` / `tick`.
@export var use_player_input := true

var members: Array[CharacterRuntime] = []
## (character_id) -> CombatStats: chỉ số theo cấp + trang bị của người chơi (PlayerProfile.stats_of).
## Không gán thì dùng chỉ số gốc cấp 1 trong CharacterDef.
var stats_provider: Callable
## (character_id) -> {SkillDef.key: cấp} (PlayerProfile.skill_levels_of). Không gán thì mọi kỹ năng cấp 1.
var skill_levels_provider: Callable
var active_index := 0
var rules: CombatRules
var links: LinkTracker
var reactions: ReactionResolver
## Phản ứng đang chờ Kĩ năng vào sân trúng kẻ địch.
var _pending_reaction: ReactionDef
var _pending_reaction_member: CharacterRuntime
## Mức vào sân của lần chuyển gần nhất.
var last_switch_mode := ""

var _switch_cd := 0.0
var _auto_switch_timer := -1.0
## Nút chuyển bấm khi chưa chuyển được: giữ trong `switch_input_buffer_sec` rồi thử lại (mục 8.11).
var _pending_slot := -1
var _pending_t := 0.0
var _field_parent: Node


## Tạo đội: mỗi nhân vật một PlayerController, đặt vào `parent` để chạy _ready, rồi gỡ người dự bị ra.
func setup(character_ids: PackedStringArray, parent: Node, spawn: Vector2) -> void:
	_field_parent = parent
	rules = _rules()
	for i in character_ids.size():
		var p: PlayerController = PLAYER_SCENE.instantiate()
		p.character_id = character_ids[i]
		if stats_provider.is_valid():
			p.stats_override = stats_provider.call(character_ids[i])
		if skill_levels_provider.is_valid():
			p.skill_levels = skill_levels_provider.call(character_ids[i])
		p.position = spawn
		parent.add_child(p)
		var m := CharacterRuntime.new(character_ids[i], p, i)
		members.append(m)
		p.combatant.resources.ug_gained.connect(_on_ug_gained.bind(m))
		p.player_died.connect(_on_member_died.bind(m))
		p.perfect_dodged.connect(_on_perfect_dodged.bind(m))
		p.runner.skill_started.connect(_on_skill_started.bind(m))
		p.combatant.hit_dealt.connect(_on_member_hit_dealt.bind(m))
		p.runner.skill_finished.connect(_on_skill_finished.bind(m))
		p.kit_event.connect(func(trigger: String) -> void: _try_reduce_si_cd(m, trigger))
	var team: Array[Combatant] = []
	for m in members:
		team.append(m.controller.combatant)
	for m in members:
		m.controller.team_combatants = team
	active_index = 0
	for m in members:
		if m.party_index != active_index:
			m.controller.leave_field()
			parent.remove_child(m.controller)
	links = LinkTracker.new(rules)
	links.setup(members, active_index)
	links.window_opened.connect(_on_window_opened)
	links.window_closed.connect(_on_window_closed)
	reactions = ReactionResolver.new(rules)
	for e in reactions.load_dir():
		push_warning("PartyManager: phản ứng: %s" % e)
	var bus := _bus()
	if bus:
		bus.enemy_stunned.connect(_on_enemy_stunned)
		bus.enemy_defeated.connect(_on_enemy_defeated)
		bus.status_applied.connect(_on_status_applied)
		bus.status_max_stacks.connect(_on_status_max_stacks)


func active() -> CharacterRuntime:
	return members[active_index] if active_index < members.size() else null


func active_controller() -> PlayerController:
	var a := active()
	return a.controller if a else null


## Người dự bị theo thứ tự trong đội (icon 1, icon 2).
func reserves() -> Array[CharacterRuntime]:
	var out: Array[CharacterRuntime] = []
	for m in members:
		if m.party_index != active_index:
			out.append(m)
	return out


func switch_cooldown_left() -> float:
	return _switch_cd


## Lý do không chuyển được sang thành viên `index` ("" = được).
func check_switch(index: int) -> String:
	if index < 0 or index >= members.size():
		return REASON_INVALID
	if index == active_index:
		return REASON_ACTIVE
	if members[index].is_down():
		return REASON_DOWN
	if _switch_cd > 0.0:
		return REASON_COOLDOWN
	if active_controller().is_switch_locked():
		return REASON_LOCKED
	return ""


## Chuyển theo ô dự bị (0 = icon 1, 1 = icon 2).
func request_switch_slot(slot: int) -> bool:
	var r := reserves()
	if slot < 0 or slot >= r.size():
		switch_rejected.emit(-1, REASON_INVALID)
		return false
	return request_switch(r[slot].party_index)


func request_switch(index: int) -> bool:
	var reason := check_switch(index)
	if reason != "":
		switch_rejected.emit(index, reason)
		return false
	_do_switch(index)
	return true


func _physics_process(delta: float) -> void:
	if use_player_input:
		_read_input()
	tick(delta)


## Bấm nút chuyển (ô dự bị 0/1) qua bộ đệm: chưa chuyển được thì thử lại trong `switch_input_buffer_sec`.
func press_switch(slot: int) -> void:
	_pending_slot = slot
	_pending_t = rules.switch_input_buffer_sec
	_try_pending(false)


## Mức vào sân nếu chuyển sang thành viên `index` lúc này.
func mode_for(index: int) -> String:
	return links.mode_for(members[index])


func _try_pending(expire: bool) -> void:
	if _pending_slot < 0:
		return
	var r := reserves()
	if _pending_slot >= r.size():
		_pending_slot = -1
		return
	var index := r[_pending_slot].party_index
	var reason := check_switch(index)
	if reason == "":
		_pending_slot = -1
		_do_switch(index)
	elif expire or reason in [REASON_DOWN, REASON_INVALID, REASON_ACTIVE]:
		_pending_slot = -1
		switch_rejected.emit(index, reason)


func tick(delta: float) -> void:
	_switch_cd = maxf(_switch_cd - delta, 0.0)
	links.tick(delta)
	reactions.tick(delta)
	if _pending_slot >= 0:
		_pending_t -= delta
		_try_pending(_pending_t <= 0.0)
	for m in members:
		if m.party_index != active_index:
			m.tick_reserve(delta)
		m.si_window_left = maxf(m.si_window_left - delta, 0.0)
		m.si_icd_left = maxf(m.si_icd_left - delta, 0.0)
	if _auto_switch_timer >= 0.0:
		_auto_switch_timer -= delta
		if _auto_switch_timer < 0.0:
			_auto_switch()


func _read_input() -> void:
	var router := get_tree().root.get_node_or_null("InputRouter") if is_inside_tree() else null
	if router == null:
		return
	for slot in SWITCH_ACTIONS.size():
		if router.consume_buffered(SWITCH_ACTIONS[slot]):
			press_switch(slot)


func _do_switch(index: int, auto := false) -> void:
	var from := active()
	var to := members[index]
	var mode := LinkTracker.MODE_DEFAULT if auto else links.mode_for(to)
	var old := from.controller
	var pos := old.global_position
	var dir := old.facing
	old.leave_field()
	var parent := old.get_parent() if old.get_parent() else _field_parent
	var at := old.get_index()
	parent.remove_child(old)
	parent.add_child(to.controller)
	parent.move_child(to.controller, at)
	to.controller.enter_field(pos, dir)
	from.si_window_left = 0.0
	active_index = index
	links.on_switched(to, mode)
	last_switch_mode = mode
	_pending_reaction = null
	_start_switch_in(to, mode)
	if mode == LinkTracker.MODE_LINKED:
		_arm_reaction(from, to)
	_switch_cd = rules.switch_cooldown_sec
	_auto_switch_timer = -1.0
	switched.emit(from, to, mode)
	var bus := _bus()
	if bus:
		bus.character_switched.emit(from.id, to.id, mode)


func _auto_switch() -> void:
	for m in members:
		if not m.is_down():
			_do_switch(m.party_index, true)
			return


func is_defeated() -> bool:
	for m in members:
		if not m.is_down():
			return false
	return true


func _on_member_died(m: CharacterRuntime) -> void:
	member_down.emit(m)
	if is_defeated():
		_auto_switch_timer = -1.0
		party_defeated.emit()
	elif m.party_index == active_index:
		_auto_switch_timer = rules.down_auto_switch_sec


## Mục 8.1: dự bị nhận 30% lượng UG người trên sân nhận.
func _on_ug_gained(amount: float, m: CharacterRuntime) -> void:
	if m.party_index != active_index:
		return
	for r in reserves():
		r.resources().add_ug(amount * rules.reserve_ug_share, false)


## Hồi đầy cả đội (màn thử nghiệm; hồi sinh trong game thật tắt theo Q6).
func restore_all() -> void:
	for m in members:
		m.controller.restore_full()


## Node dự bị nằm ngoài cây: tự giải phóng cùng PartyManager.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for m in members:
			if is_instance_valid(m.controller) and m.controller.get_parent() == null:
				m.controller.free()


# ---------- Kĩ năng vào sân (mục 8.5–8.10) ----------

## Chạy Kĩ năng vào sân theo mức, áp buff bản thân, mở cửa sổ giảm SI-CD.
func _start_switch_in(m: CharacterRuntime, mode: String) -> void:
	m.si_window_left = 0.0
	m.si_icd_left = 0.0
	if mode == LinkTracker.MODE_DEFAULT:
		return
	var linked := mode == LinkTracker.MODE_LINKED
	var key := SKILL_SWITCH_IN_LINKED if linked and m.controller.runner.has_skill(SKILL_SWITCH_IN_LINKED) \
			else SKILL_SWITCH_IN
	m.controller.start_switch_in(key)
	var sd := m.switch_in_def()
	if sd == null:
		return
	for st in (sd.self_statuses_linked if linked else sd.self_statuses_normal):
		m.combatant().statuses.apply(st.status_id, st.duration, st.magnitude, m.combatant())
	m.si_window_left = sd.reduce_window_sec


## Giảm SI-CD riêng của `m` nếu `trigger` đúng cơ chế của nhân vật và còn trong cửa sổ / hết ICD.
func _try_reduce_si_cd(m: CharacterRuntime, trigger: String, needs_window := true) -> float:
	var sd := m.switch_in_def()
	if sd == null or sd.reduce_on != trigger or sd.reduce_sec <= 0.0:
		return 0.0
	if needs_window and m.si_window_left <= 0.0:
		return 0.0
	if m.si_icd_left > 0.0:
		return 0.0
	var cut := m.combatant().cooldowns.reduce(LinkTracker.SI_CD_KEY, sd.reduce_sec, sd.reduce_max_per_cycle_sec)
	if cut > 0.0:
		m.si_icd_left = sd.reduce_icd_sec
	return cut


## Aether: mỗi kẻ địch đang Choáng trúng đòn vào sân.
func _on_member_hit_dealt(_target: Combatant, _result: DamageCalculator.Result, hit: HitInfo,
		m: CharacterRuntime) -> void:
	if m.party_index != active_index or not hit.skill_id.begins_with(m.id + "." + SKILL_SWITCH_IN):
		return
	if _pending_reaction != null and _pending_reaction_member == m:
		var node := _target.get_parent() as Node2D
		var def := _pending_reaction
		_pending_reaction = null
		if node:
			_fire_reaction(def, m, node.global_position)
	if hit.target_statuses_before.has("stun"):
		_try_reduce_si_cd(m, SwitchInDef.REDUCE_STUNNED_HIT, false)


## Kael: Bùng nổ Sét (Dấu Sét đủ tầng do người trên sân gây).
func _on_status_max_stacks(_target: Object, status_id: String, source: Object) -> void:
	if status_id == LIGHTNING_MARK and _is_active_combatant(source):
		_try_reduce_si_cd(active(), SwitchInDef.REDUCE_LIGHTNING_BURST)


# ---------- Phản ứng nguyên tố (mục 8.4) ----------

## Vào sân Liên kết: chuẩn bị phản ứng của cặp (nguyên tố người rời sân, nguyên tố người vào sân).
func _arm_reaction(from: CharacterRuntime, to: CharacterRuntime) -> void:
	var def := reactions.find(from.element(), to.element())
	if def == null or not reactions.can_trigger():
		return
	if def.target_mode == ReactionDef.TargetMode.SELF:
		_fire_reaction(def, to, to.controller.global_position)
	else:
		_pending_reaction = def
		_pending_reaction_member = to


func _fire_reaction(def: ReactionDef, m: CharacterRuntime, center: Vector2) -> void:
	if reactions.trigger(def, m.controller, center, members):
		var bus := _bus()
		if bus:
			bus.reaction_triggered.emit(def, center, m.controller)


## Kĩ năng vào sân kết thúc mà không trúng ai: phản ứng không xảy ra (không tốn ICD).
func _on_skill_finished(_key: String, skill: SkillDef, m: CharacterRuntime) -> void:
	if skill.key == SKILL_SWITCH_IN and _pending_reaction_member == m:
		_pending_reaction = null


# ---------- Điều kiện Liên kết (mục 8.3) ----------

func _is_active_combatant(c: Object) -> bool:
	var a := active()
	return a != null and c != null and c == a.combatant()


func _on_enemy_stunned(_enemy: Node, by: Object) -> void:
	if _is_active_combatant(by):
		links.notify(LinkTracker.COND_ENEMY_STUNNED)


func _on_enemy_defeated(_enemy: Node, by: Object) -> void:
	if _is_active_combatant(by):
		links.notify(LinkTracker.COND_ENEMY_DEFEATED)


## Kael: người trên sân gây hiệu ứng nguyên tố (StatusDef.counts_as_elemental) lên kẻ địch.
func _on_status_applied(target: Object, status_id: String, source: Object) -> void:
	if not _is_active_combatant(source):
		return
	var t := target as Combatant
	var src := source as Combatant
	if t == null or t.team == src.team:
		return
	var def := t.statuses.library.get_status(status_id) if t.statuses.library else null
	if def and def.counts_as_elemental:
		links.notify(LinkTracker.COND_ELEMENTAL_STATUS)


func _on_perfect_dodged(_hit: HitInfo, m: CharacterRuntime) -> void:
	if m.party_index == active_index:
		links.notify(LinkTracker.COND_PERFECT_DODGE)
		_try_reduce_si_cd(m, SwitchInDef.REDUCE_PERFECT_DODGE)  # Lyra


func _on_skill_started(_key: String, skill: SkillDef, m: CharacterRuntime) -> void:
	if m.party_index == active_index and skill.key in ["weapon", "ultimate"]:
		links.notify(LinkTracker.COND_WEAPON_OR_ULTIMATE)


func _on_window_opened(m: CharacterRuntime, seconds: float) -> void:
	var bus := _bus()
	if bus:
		bus.link_window_opened.emit(m.id, seconds)


func _on_window_closed(m: CharacterRuntime) -> void:
	var bus := _bus()
	if bus:
		bus.link_window_closed.emit(m.id)


func _bus() -> Node:
	return get_tree().root.get_node_or_null("EventBus") if is_inside_tree() else null


func _rules() -> CombatRules:
	var gc := get_tree().root.get_node_or_null("GameConfig") if is_inside_tree() else null
	return gc.combat_rules if gc else load("res://data/config/combat_rules.tres")
