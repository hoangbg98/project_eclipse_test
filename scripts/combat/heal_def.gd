class_name HealDef
extends Resource
## Một lần (hoặc một chuỗi nhịp) hồi máu trong kỹ năng (Hikarine, CHARACTER_SKILLS mục 4).
## Lượng hồi = ATK người hồi × atk_ratio + HP tối đa của người được hồi × max_hp_ratio.
## Mục mới 8.1: hồi máu cả đội hồi cho cả nhân vật dự bị; vùng chỉ tính người đang trên sân đứng trong vùng.

const TARGET_TEAM := "team"      ## cả đội (kể cả dự bị, bỏ người đã gục)
const TARGET_LOWEST := "lowest"  ## một người có % HP thấp nhất trong đội
const TARGET_SELF := "self"
const TARGET_AREA := "area"      ## người đang trên sân đứng trong bán kính quanh tâm vùng

## Bắt đầu lúc nào tính từ đầu kỹ năng (ms).
@export var at_ms := 0.0
@export var atk_ratio := 0.0
@export var max_hp_ratio := 0.0
## "team" | "lowest" | "self" | "area".
@export var target := TARGET_TEAM
## Vùng ("area"): bán kính và tâm so với chân người hồi (x dương = phía trước).
@export var radius_px := 0.0
@export var offset := Vector2.ZERO
## Đặt tâm vùng tại mục tiêu kỹ năng đã chọn (SkillDef.target_range_px) thay vì tại người hồi.
@export var at_target := false
## Hồi cả đội: người có % HP thấp nhất nhận × hệ số này (1 = không ưu tiên).
@export var lowest_multiplier := 1.0
## Số nhịp và khoảng cách giữa hai nhịp (ms); nhịp đầu ngay lúc at_ms.
@export var ticks := 1
@export var interval_ms := 0.0
## Chờ bấy nhiêu ms rồi mới bắt đầu (quả cầu rơi trễ).
@export var delay_ms := 0.0
## true: vùng đi theo người hồi và dừng khi kỹ năng kết thúc / bị huỷ (cầu nguyện). false: độc lập (tuyệt kỹ).
@export var follow_caster := false
## Xoá bấy nhiêu hiệu ứng xấu (DEBUFF) khỏi mỗi người được hồi (nhịp đầu).
@export var cleanse := 0
## Trạng thái áp cho mỗi người được hồi mỗi nhịp (vd giảm sát thương nhận trong vùng thánh).
@export var ally_statuses: Array[StatusApplication] = []
## Hồi sinh người đã gục trong vùng với % HP tối đa này, một lần mỗi vùng; chỉ khi CombatRules.revive_enabled.
@export var revive_hp_ratio := 0.0


func total_ms() -> float:
	return delay_ms + interval_ms * float(maxi(ticks - 1, 0))
