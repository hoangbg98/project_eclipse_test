class_name GachaTierDef
extends Resource
## Một bậc độ hiếm trong banner (README "Gacha and recruitment"). Mọi tỉ lệ và bảo hiểm nằm ở đây, trong data.

## Số sao / bậc (số lớn = hiếm hơn). Nhân vật: S = 5, A = 4, B = 3. Vật phẩm: số sao.
@export var rarity := 3
## Khóa của bậc (pity, bảo hiểm, bảo đảm 10 lượt). Rỗng = dùng số `rarity`. Cần khi hai bậc cùng số sao
## (vd vũ khí 4★ và vết thánh 4★).
@export var tier_id := ""
## Khóa dịch tên bậc hiển thị trên bảng tỉ lệ (vd "GACHA_TIER_CHAR_S"). Rỗng = "N★".
@export var label_key := ""
## Tỉ lệ gốc mỗi lượt (0..1). Bậc thấp nhất của banner nhận phần còn lại, trường này bị bỏ qua.
@export_range(0.0, 1.0) var base_rate := 0.0

@export_group("Pity")
## Pity cứng: lượt thứ N kể từ lần ra bậc này gần nhất chắc chắn ra bậc này (0 = không có).
@export var hard_pity := 0
## Pity mềm: từ lượt thứ N, mỗi lượt cộng thêm `soft_pity_step` vào tỉ lệ (0 = không có).
@export var soft_pity_start := 0
@export_range(0.0, 1.0) var soft_pity_step := 0.0
## "step": cộng `soft_pity_step` mỗi lượt từ lượt `soft_pity_start`. "flat": cộng một lần `soft_pity_step`
## cho mọi lượt từ lượt `soft_pity_start` (owner 2026-11-12: "đạt 80 lượt thì tăng 10%").
@export_enum("step", "flat") var soft_pity_mode := "step"

@export_group("Phần thưởng")
## Danh sách phần thưởng của bậc: "char:<id>", "equip:<id>", "item:<id>", "gold:<số>". Rút đều trong bậc.
@export var pool: PackedStringArray = PackedStringArray()
## Phần thưởng rate-up (phải nằm trong `pool`).
@export var featured: PackedStringArray = PackedStringArray()
## Khi ra bậc này: xác suất là phần thưởng rate-up (0..1).
@export_range(0.0, 1.0) var featured_rate := 0.0
## Bảo hiểm: lần ra bậc này mà trượt rate-up thì lần kế chắc chắn là rate-up.
@export var guarantee_after_miss := false

@export_group("Banner 5★ (owner 2026-11-14, EQUIPMENT_5STAR mục 5.6)")
## true: `base_rate` là tỉ lệ MỖI MÓN; tỉ lệ bậc = base_rate × số món còn được ra.
@export var rate_per_item := false
## true: món trang bị đã có không ra lại cho tới khi người chơi có đủ cả pool (đủ bộ); đủ rồi thì ra cả pool,
## có thể trùng. Pity của bậc vì vậy chỉ chắc chắn ra món chưa có.
@export var exclude_owned_until_complete := false

@export_group("Trùng nhân vật")
## Nhân vật đã sở hữu thì đổi thành nguyên liệu này (rỗng = không đổi, chỉ ghi lịch sử).
@export var duplicate_item := ""
@export var duplicate_count := 0
## Nhân vật đã sở hữu thì cộng bấy nhiêu mảnh nhân vật (dùng để tiến cấp S → S1 …).
@export var duplicate_fragments := 0


func key() -> String:
	return tier_id if tier_id != "" else str(rarity)
