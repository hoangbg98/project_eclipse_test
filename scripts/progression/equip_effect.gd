class_name EquipEffect
extends Resource
## Một dòng hiệu ứng của trang bị hoặc hiệu ứng bộ vết thánh (docs/design/EQUIPMENT_5STAR.md).
## Gom và chặn trần ở một chỗ: EquipmentResolver. Số liệu nằm trong data, không viết cứng trong script.

enum Kind {
	## Chỉ số cố định của người đeo (hoặc cả đội nếu `team`): khóa trong `stat` (xem STATS).
	STAT,
	## Sửa một giá trị gốc kiểu "A → B": cộng `value` (phần tăng) vào tham số `param` (owner Q3: cộng dồn phần tăng).
	PARAM,
	## % sát thương người đeo gây thêm lên mục tiêu thỏa `condition` (tên trạng thái hoặc CONDITIONS).
	VS_TARGET,
	## Kĩ năng vũ khí (`weapon`) trúng: áp trạng thái `status_id` lên mục tiêu.
	ON_WEAPON_HIT,
	## Hiệu ứng theo sự kiện chưa cài đặt (buff toàn đội có thời hạn, thay đổi cơ chế kit...). Chỉ ghi data + mô tả.
	PENDING,
}

## Khóa chỉ số của Kind.STAT. Tỉ lệ 0..1 (0.08 = 8%).
const STATS := ["atk_pct", "all_dmg", "elem_dmg", "hp_pct", "def_pct", "dmg_taken_down", "crit_rate",
		"en_regen", "atk_speed", "move_speed", "heal_bonus", "lifesteal"]
## Điều kiện đặc biệt của Kind.VS_TARGET (ngoài tên trạng thái).
const CONDITIONS := ["elemental", "def_down", "low_hp", "boss"]
## Tiền tố tham số của Kind.PARAM:
##   kit:<thuộc tính cấu hình kit>            vd kit:heat_icd_sec
##   skill:<SkillDef.key>:<thuộc tính>        vd skill:weapon:cooldown_sec
##   status_dur:<id trạng thái>               cộng giây vào thời gian trạng thái do người đeo gây ra
##   status_mag:<id trạng thái>               cộng vào độ mạnh trạng thái do người đeo gây ra
const PARAM_PREFIXES := ["kit", "skill", "status_dur", "status_mag"]

@export var kind := Kind.STAT
## true = chỉ chủ sở hữu (giáp `owner_id`, owner Q1) được nhận.
@export var exclusive := false
## Khác rỗng: chỉ người đeo có nguyên tố này nhận (mục 3.2, quyết định 5.3).
@export var requires_element := ""
## STAT: true = áp cho cả đội (cùng `effect_id` từ nhiều người đeo chỉ lấy mức cao nhất).
@export var team := false
## Định danh để không cộng dồn buff toàn đội. Rỗng = không áp cho đội.
@export var effect_id := ""
@export var stat := ""
@export var param := ""
@export var condition := ""
@export var status_id := ""
## Giá trị chính: tỉ lệ (STAT, VS_TARGET), phần tăng (PARAM), thời gian giây (ON_WEAPON_HIT).
@export var value := 0.0
## ON_WEAPON_HIT: độ mạnh trạng thái (âm = mặc định StatusDef).
@export var magnitude := -1.0
## Mô tả thiết kế (tiếng Việt, theo tài liệu) để đối chiếu và hiện tạm; chữ hiển thị chính thức đi qua tr() sau.
@export var note := ""


func validate(where: String) -> PackedStringArray:
	var e := PackedStringArray()
	match kind:
		Kind.STAT:
			if stat not in STATS:
				e.append("%s: stat lạ '%s'" % [where, stat])
			if team and effect_id.is_empty():
				e.append("%s: hiệu ứng toàn đội cần effect_id" % where)
		Kind.PARAM:
			if param.get_slice(":", 0) not in PARAM_PREFIXES or param.get_slice_count(":") < 2:
				e.append("%s: param lạ '%s'" % [where, param])
		Kind.VS_TARGET:
			if condition.is_empty():
				e.append("%s: thiếu condition" % where)
		Kind.ON_WEAPON_HIT:
			if status_id.is_empty() or value <= 0.0:
				e.append("%s: ON_WEAPON_HIT cần status_id và value > 0" % where)
		Kind.PENDING:
			if note.is_empty():
				e.append("%s: PENDING cần note" % where)
	return e
