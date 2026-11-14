class_name BackgroundDef
extends Resource
## Ảnh nền sảnh chính (data/backgrounds/{id}.tres, owner 2026-11-14): người chơi đổi nền phía sau nhân vật. Nền có sẵn
## từ đầu (starter), mua bằng ngọc (price_gems > 0) hoặc phát trong sự kiện (PlayerProfile.unlock_background).
## Nền đang sở hữu / đang dùng nằm trong save (cosmetics).

enum Source { STARTER, SHOP, EVENT }

@export var id := ""
@export var name_key := ""
@export_file("*.png", "*.jpg", "*.webp") var image := ""
@export var source := Source.SHOP
## Giá ngọc khi mua (0 = không bán, chỉ nhận từ sự kiện / có sẵn).
@export var price_gems := 0
## Khóa chữ mô tả cách nhận (vd tên sự kiện); rỗng = mặc định theo `source`.
@export var how_to_get_key := ""
@export var sort_order := 0


func validate() -> PackedStringArray:
	var e := PackedStringArray()
	if id.is_empty() or name_key.is_empty():
		e.append("thiếu id / name_key")
	if image.is_empty():
		e.append("%s: thiếu ảnh" % id)
	if price_gems < 0:
		e.append("%s: giá âm" % id)
	return e
