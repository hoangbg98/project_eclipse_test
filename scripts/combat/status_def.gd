class_name StatusDef
extends Resource
## Định nghĩa một trạng thái dùng chung (CHARACTER_SKILLS mục 0 + Q3, Q4).
## Chỉ là dữ liệu tĩnh; áp/làm mới/hết hạn do StatusController (M3) xử lý.
## Kỹ năng có thể ghi đè thời gian và độ mạnh khi áp (vd "Chậm 30% trong 2s").

enum Kind { DEBUFF, BUFF, CONTROL }
## REFRESH: áp lại cùng tên thì làm mới thời gian, không cộng dồn (Q3).
## STACKS: cộng tầng tới max_stacks, mỗi lần áp làm mới thời gian.
enum Stacking { REFRESH, STACKS }

## Khóa dữ liệu, trùng tên file (vd "burn" ↔ data/statuses/burn.tres).
@export var id := ""
## Khóa dịch tên hiển thị (vd STATUS_BURN).
@export var name_key := ""
@export var kind := Kind.DEBUFF
@export var stacking := Stacking.REFRESH
@export var max_stacks := 1

@export_group("Thời gian")
## Thời gian mặc định (s). 0 = do kỹ năng áp quyết định (Khiên, Giáp Địa, Khiêu khích...).
@export var default_duration := 0.0
## Hệ số thời gian trên boss (Choáng: 1.0s / 2.0s = 0.5). 0 = boss miễn nhiễm.
@export var boss_duration_multiplier := 1.0
## Sau khi hết, mục tiêu kháng trạng thái này trong bấy nhiêu giây (Choáng: 8s).
@export var resist_after_sec := 0.0

@export_group("Sát thương theo nhịp")
## 0 = không tick.
@export var tick_interval_sec := 0.0
## Sát thương mỗi nhịp theo ATK người áp (0.08 = 8% ATK).
@export var tick_atk_ratio := 0.0

@export_group("Độ mạnh")
## Độ mạnh mặc định nếu kỹ năng không ghi (ý nghĩa theo `magnitude_meaning`).
@export var default_magnitude := 0.0
## Độ mạnh dùng cho chỉ số nào (xem MAGNITUDE_*).
@export var magnitude_meaning := ""

@export_group("Cờ")
## Mục tiêu không di chuyển được.
@export var blocks_movement := false
## Mục tiêu mất hành động (không tấn công, không di chuyển).
@export var blocks_actions := false
## Mục tiêu không bị khựng.
@export var stagger_immune := false
## Tính là "hiệu ứng nguyên tố" cho điều kiện Liên kết của Kael (mục 8.3).
@export var counts_as_elemental := false
## Kích hoạt sự kiện khi đạt đủ tầng (vd Dấu Sét 3 tầng → "lightning_burst").
@export var on_max_stacks_event := ""

const MAGNITUDE_MOVE_SLOW := "move_slow"          ## giảm % tốc độ di chuyển
const MAGNITUDE_DEF_REDUCTION := "def_reduction"  ## giảm % DEF (cộng dồn khác tên, trần CombatRules)
const MAGNITUDE_DAMAGE_TAKEN_UP := "damage_taken_up"      ## nhận thêm % sát thương
const MAGNITUDE_DAMAGE_TAKEN_DOWN := "damage_taken_down"  ## giảm % sát thương nhận
const MAGNITUDE_DAMAGE_DEALT_DOWN := "damage_dealt_down"  ## giảm % sát thương gây ra
const MAGNITUDE_SHIELD_MAX_HP := "shield_max_hp"  ## khiên hấp thụ = % HP tối đa
const MAGNITUDE_DAMAGE_DEALT_UP := "damage_dealt_up"  ## tăng % sát thương gây ra (buff)
const MAGNITUDE_MOVE_SPEED_UP := "move_speed_up"      ## tăng % tốc độ di chuyển (Gió Trợ Bước)
const MAGNITUDE_ATTACK_SPEED_UP := "attack_speed_up"  ## tăng % tốc độ tấn công (đòn cơ bản chạy nhanh hơn)
const MAGNITUDE_TICK_BONUS := "tick_bonus"  ## tăng % sát thương mỗi nhịp (Thiêu Hồn: Cháy tick gấp đôi = 1.0)
const MAGNITUDE_EN_REGEN_UP := "en_regen_up"  ## tăng % tốc độ nạp EN theo giây (Gió Thuận)
const MAGNITUDES: Array[String] = ["", MAGNITUDE_MOVE_SLOW, MAGNITUDE_DEF_REDUCTION, MAGNITUDE_DAMAGE_TAKEN_UP,
		MAGNITUDE_DAMAGE_TAKEN_DOWN, MAGNITUDE_DAMAGE_DEALT_DOWN, MAGNITUDE_SHIELD_MAX_HP, MAGNITUDE_DAMAGE_DEALT_UP,
		MAGNITUDE_MOVE_SPEED_UP, MAGNITUDE_ATTACK_SPEED_UP, MAGNITUDE_TICK_BONUS, MAGNITUDE_EN_REGEN_UP]


## Số nhịp sát thương trong thời gian mặc định (Cháy: 4s / 0.5s = 8).
func tick_count(duration := -1.0) -> int:
	if tick_interval_sec <= 0.0:
		return 0
	var d := default_duration if duration < 0.0 else duration
	return int(floor(d / tick_interval_sec + 0.0001))


## Thời gian thực áp lên mục tiêu.
func duration_for(is_boss: bool, duration := -1.0) -> float:
	var d := default_duration if duration < 0.0 else duration
	return d * boss_duration_multiplier if is_boss else d


func validate() -> PackedStringArray:
	var e := PackedStringArray()
	if id.is_empty():
		e.append("thiếu id")
	if name_key.is_empty() or name_key != name_key.to_upper():
		e.append("%s: name_key phải là khóa UPPER_SNAKE" % id)
	if max_stacks < 1:
		e.append("%s: max_stacks phải >= 1" % id)
	if stacking == Stacking.REFRESH and max_stacks != 1:
		e.append("%s: REFRESH chỉ có 1 tầng" % id)
	if default_duration < 0.0 or boss_duration_multiplier < 0.0 or resist_after_sec < 0.0:
		e.append("%s: thời gian không được âm" % id)
	if (tick_interval_sec > 0.0) != (tick_atk_ratio > 0.0):
		e.append("%s: tick_interval_sec và tick_atk_ratio phải cùng có hoặc cùng không" % id)
	if magnitude_meaning not in MAGNITUDES:
		e.append("%s: magnitude_meaning lạ '%s'" % [id, magnitude_meaning])
	if default_magnitude < 0.0 or default_magnitude > 1.0:
		e.append("%s: default_magnitude phải trong 0..1" % id)
	return e
