class_name GachaTierDef
extends Resource
## Một bậc độ hiếm trong banner (README "Gacha and recruitment"). Mọi tỉ lệ và bảo hiểm nằm ở đây, trong data.

## Số sao / bậc (số lớn = hiếm hơn).
@export var rarity := 3
## Tỉ lệ gốc mỗi lượt (0..1). Bậc thấp nhất của banner nhận phần còn lại, trường này bị bỏ qua.
@export_range(0.0, 1.0) var base_rate := 0.0

@export_group("Pity")
## Pity cứng: lượt thứ N kể từ lần ra bậc này gần nhất chắc chắn ra bậc này (0 = không có).
@export var hard_pity := 0
## Pity mềm: từ lượt thứ N, mỗi lượt cộng thêm `soft_pity_step` vào tỉ lệ (0 = không có).
@export var soft_pity_start := 0
@export_range(0.0, 1.0) var soft_pity_step := 0.0

@export_group("Phần thưởng")
## Danh sách phần thưởng của bậc: "char:<id>", "equip:<id>", "item:<id>".
@export var pool: PackedStringArray = PackedStringArray()
## Phần thưởng rate-up (phải nằm trong `pool`).
@export var featured: PackedStringArray = PackedStringArray()
## Khi ra bậc này: xác suất là phần thưởng rate-up (0..1).
@export_range(0.0, 1.0) var featured_rate := 0.0
## Bảo hiểm: lần ra bậc này mà trượt rate-up thì lần kế chắc chắn là rate-up.
@export var guarantee_after_miss := false

@export_group("Trùng nhân vật")
## Nhân vật đã sở hữu thì đổi thành nguyên liệu này (rỗng = không đổi, chỉ ghi lịch sử).
@export var duplicate_item := ""
@export var duplicate_count := 0
