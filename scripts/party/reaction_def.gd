class_name ReactionDef
extends Resource
## Một phản ứng nguyên tố (CHARACTER_SKILLS 8.4). Dữ liệu ở data/reactions/{a}_{b}.tres, id `reaction.{a}_{b}`.
## Phản ứng đối xứng: chỉ phụ thuộc cặp nguyên tố. Sát thương tính theo ATK của nhân vật VÀO sân.

## Thứ tự chuẩn để ghép khóa cặp (fire_wind, không phải wind_fire).
const ELEMENT_ORDER: Array[String] = ["fire", "wind", "lightning", "light", "dark", "earth"]

enum TargetMode {
	FIRST_HIT,   ## Tâm = kẻ địch đầu tiên trúng Kĩ năng vào sân (mặc định).
	SELF,        ## Tâm = nhân vật vào sân; không cần trúng kẻ địch (Thanh Phong, Thánh Giáp).
	HIGHEST_HP,  ## Một mục tiêu HP cao nhất trong `target_range_px` quanh kẻ địch trúng đầu tiên (Thần Phạt).
}

@export var id := ""
## Hai nguyên tố, theo ELEMENT_ORDER.
@export var elements: PackedStringArray = PackedStringArray()
@export var name_key := ""
@export var target_mode := TargetMode.FIRST_HIT
@export var target_range_px := 0.0

## Các vùng đòn đặt tại tâm (luôn là vùng tách). `at_ms` = trễ so với lúc phản ứng nổ;
## `tick_interval_ms` + `duration_ms` cho nhịp lặp và vùng kéo dài.
@export var hits: Array[HitDef] = []
## > 0: mỗi vùng đặt lệch ngẫu nhiên trong bán kính này quanh tâm (Bão Sét).
@export var scatter_radius_px := 0.0

@export_group("Hiệu ứng lên phe mình")
## Áp lên nhân vật vào sân.
@export var self_statuses: Array[StatusApplication] = []
## Hồi cả đội (kể cả dự bị còn sống) theo % HP tối đa của từng người.
@export_range(0.0, 1.0) var team_heal_max_hp_ratio := 0.0
## Xóa bấy nhiêu hiệu ứng xấu trên mỗi thành viên.
@export var team_cleanse_count := 0


## Khóa cặp theo thứ tự chuẩn, vd ("wind", "fire") → "fire_wind". Cùng nguyên tố hoặc lạ → "".
static func pair_key(a: String, b: String) -> String:
	var ia := ELEMENT_ORDER.find(a)
	var ib := ELEMENT_ORDER.find(b)
	if ia < 0 or ib < 0 or ia == ib:
		return ""
	return "%s_%s" % ([a, b] if ia < ib else [b, a])


## Số lần một vùng gây sát thương (1, hoặc số nhịp trong thời gian tồn tại).
static func pulses_of(h: HitDef) -> int:
	if h.tick_interval_ms <= 0.0:
		return 1
	return maxi(int(floor(h.duration_ms / h.tick_interval_ms + 0.0001)), 1)


## Tổng % ATK của mọi vùng (gồm cả vùng kéo dài).
func total_atk_ratio() -> float:
	var t := 0.0
	for h in hits:
		t += h.atk_ratio * pulses_of(h)
	return t


func validate() -> PackedStringArray:
	var e := PackedStringArray()
	if elements.size() != 2 or pair_key(elements[0], elements[1]) == "":
		e.append("%s: cần đúng 2 nguyên tố khác nhau" % id)
	elif id != "reaction." + pair_key(elements[0], elements[1]):
		e.append("%s: id phải là reaction.%s" % [id, pair_key(elements[0], elements[1])])
	if name_key.is_empty() or name_key != name_key.to_upper():
		e.append("%s: name_key phải là khóa UPPER_SNAKE" % id)
	if hits.is_empty():
		e.append("%s: không có vùng đòn" % id)
	if target_mode == TargetMode.HIGHEST_HP and target_range_px <= 0.0:
		e.append("%s: HIGHEST_HP cần target_range_px" % id)
	return e
