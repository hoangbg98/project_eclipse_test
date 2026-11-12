class_name LinkTracker
extends RefCounted
## Liên kết và SI-CD (CHARACTER_SKILLS 8.2, 8.3; ARCHITECTURE mục 6).
## - Mỗi nhân vật có một điều kiện Liên kết (CharacterDef.link_condition): việc người TRÊN SÂN làm.
##   Khi việc đó xảy ra, cửa sổ `link_window_sec` của mọi người DỰ BỊ có điều kiện đó mở (làm mới nếu đang mở).
## - Vòng sáng = cửa sổ còn + SI-CD đã hồi + chưa gục.
## - Chuyển sang ai: cửa sổ của người đó đóng. Mức vào sân: Liên kết (vòng sáng) / Thường (SI-CD đã hồi)
##   / mặc định (SI-CD chưa hồi). Thường và Liên kết bắt đầu SI-CD.
## - SI-CD là khóa `switch_in` trong CooldownController của từng nhân vật: đếm cả khi ở dự bị, chịu CDR chung.
## PartyManager cấp sự kiện (`notify`) và gọi `tick`; lớp này không tự nghe EventBus để test được độc lập.

signal window_opened(member: CharacterRuntime, seconds: float)
signal window_closed(member: CharacterRuntime)

const COND_ENEMY_STUNNED := "enemy_stunned"          # Aether
const COND_PERFECT_DODGE := "perfect_dodge"          # Lyra
const COND_ELEMENTAL_STATUS := "elemental_status"    # Kael
const COND_LOW_HP := "low_hp"                        # Seraphine
const COND_ENEMY_DEFEATED := "enemy_defeated"        # Noctis
const COND_WEAPON_OR_ULTIMATE := "weapon_or_ultimate"  # Terra
const CONDITIONS := [COND_ENEMY_STUNNED, COND_PERFECT_DODGE, COND_ELEMENTAL_STATUS, COND_LOW_HP,
		COND_ENEMY_DEFEATED, COND_WEAPON_OR_ULTIMATE]

const MODE_LINKED := "linked"
const MODE_NORMAL := "normal"
const MODE_DEFAULT := "default"

const SI_CD_KEY := &"switch_in"

var rules: CombatRules
var members: Array[CharacterRuntime] = []
var active_index := 0

var _window: Dictionary = {}   # party_index -> giây còn lại
var _time := 0.0
var _hp_log: Array = []        # [thời điểm, HP mất] của người trên sân
var _last_hp := -1.0


func _init(combat_rules: CombatRules) -> void:
	rules = combat_rules


func setup(party: Array[CharacterRuntime], active := 0) -> void:
	members = party
	active_index = active
	for m in members:
		var d := m.def()
		var cd := d.switch_in_cd_sec if d else 0.0
		m.combatant().cooldowns.register(SI_CD_KEY, cd, true)
	reset_hp_tracking()


static func condition_of(m: CharacterRuntime) -> String:
	var d := m.def()
	return d.link_condition if d else ""


# ---------- Sự kiện ----------

## Người trên sân vừa làm `condition`: mở cửa sổ cho người dự bị có điều kiện đó.
func notify(condition: String) -> void:
	for m in members:
		if m.party_index == active_index or m.is_down():
			continue
		if condition_of(m) == condition:
			_open(m)


func _open(m: CharacterRuntime) -> void:
	var was_open := window_left(m) > 0.0
	_window[m.party_index] = rules.link_window_sec
	if not was_open:
		window_opened.emit(m, rules.link_window_sec)


func _close(m: CharacterRuntime) -> void:
	if _window.erase(m.party_index):
		window_closed.emit(m)


func tick(delta: float) -> void:
	_time += delta
	for i in _window.keys():
		_window[i] = float(_window[i]) - delta
		if float(_window[i]) <= 0.0:
			_close(members[i])
	_track_hp()


## Seraphine: HP người trên sân ≤ 50%, hoặc mất ≥ 25% HP tối đa trong 3 s gần nhất.
## HP thấp là trạng thái kéo dài: còn đúng thì cửa sổ được làm mới liên tục.
func _track_hp() -> void:
	if active_index >= members.size():
		return
	var r := members[active_index].resources()
	if r.is_dead():
		return
	if _last_hp >= 0.0 and r.hp < _last_hp:
		_hp_log.append([_time, _last_hp - r.hp])
	_last_hp = r.hp
	var cutoff := _time - rules.link_hp_loss_window_sec
	while not _hp_log.is_empty() and float(_hp_log[0][0]) < cutoff:
		_hp_log.pop_front()
	var lost := 0.0
	for e in _hp_log:
		lost += float(e[1])
	if r.hp_ratio() <= rules.link_low_hp_ratio or lost >= rules.link_hp_loss_ratio * r.max_hp:
		notify(COND_LOW_HP)


func reset_hp_tracking() -> void:
	_hp_log.clear()
	_last_hp = members[active_index].resources().hp if active_index < members.size() else -1.0


# ---------- Truy vấn ----------

func window_left(m: CharacterRuntime) -> float:
	return maxf(float(_window.get(m.party_index, 0.0)), 0.0)


func si_cd_ready(m: CharacterRuntime) -> bool:
	return m.combatant().cooldowns.is_ready(SI_CD_KEY)


func si_cd_left(m: CharacterRuntime) -> float:
	return m.combatant().cooldowns.remaining(SI_CD_KEY)


## Vòng sáng quanh icon dự bị (mục 8.3).
func is_glowing(m: CharacterRuntime) -> bool:
	return m.party_index != active_index and not m.is_down() and window_left(m) > 0.0 and si_cd_ready(m)


## Mức vào sân nếu chuyển sang `m` lúc này.
func mode_for(m: CharacterRuntime) -> String:
	if not si_cd_ready(m):
		return MODE_DEFAULT
	return MODE_LINKED if is_glowing(m) else MODE_NORMAL


# ---------- Chuyển ----------

## Gọi khi chuyển sang `to` với `mode`: đóng cửa sổ của `to`, bắt đầu SI-CD (Thường / Liên kết),
## Liên kết cộng UG / EN cho người vào sân. Cập nhật người trên sân.
func on_switched(to: CharacterRuntime, mode: String) -> void:
	_close(to)
	active_index = to.party_index
	if mode != MODE_DEFAULT:
		to.combatant().cooldowns.trigger(SI_CD_KEY)
	if mode == MODE_LINKED:
		var r := to.resources()
		r.add_en(rules.link_bonus_en)
		r.add_ug(rules.link_bonus_ug, false)
	reset_hp_tracking()
