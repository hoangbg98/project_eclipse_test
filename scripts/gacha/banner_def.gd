class_name BannerDef
extends Resource
## Cấu hình một banner chiêu mộ (data/banners/{id}.tres). Cùng một config sinh bảng tỉ lệ hiển thị và logic quay.
## Tỉ lệ thật do owner cung cấp (OWNER_ASSET_CHECKLIST mục A1); dự án chưa ship banner nào.

@export var id := ""
@export var name_key := ""
## Các bậc, sắp từ hiếm nhất xuống thường nhất. Bậc cuối nhận phần tỉ lệ còn lại.
@export var tiers: Array[GachaTierDef] = []

@export_group("Giá")
@export var cost_currency := "gems"
@export var cost_single := 0
@export var multi_count := 10
@export var cost_multi := 0

@export_group("Pity")
## Các banner cùng nhóm dùng chung bộ đếm pity và bảo hiểm (rỗng = riêng theo id banner).
@export var pity_group := ""

@export_group("Bảo đảm khi quay gói")
## Quay đúng gói `multi_count` mà không ra bậc nào trong danh sách này (khóa bậc) thì lượt cuối được đổi
## thành bậc đầu tiên của `multi_guarantee_pick` (owner: 10 lượt chắc chắn 1 nhân vật A trở lên;
## tiếp tế: 1 vũ khí / vết thánh 4★, ưu tiên vết thánh). Rỗng = không bảo đảm.
@export var multi_guarantee_tiers: PackedStringArray = PackedStringArray()
@export var multi_guarantee_pick: PackedStringArray = PackedStringArray()

@export_group("Hiển thị (màn Chiêu mộ)")
## Nhãn thẻ góc trái trên của banner (vd "Banner nhân vật"). Rỗng = không hiện.
@export var kind_key := ""
## Tiêu đề lớn của banner (khóa dịch). Rỗng = dùng `name_key`.
@export var title_key := ""
## Ảnh banner lớn / ảnh nhỏ trong danh sách bên trái. Rỗng = theo quy ước trong assets/ui/recruit/:
## `{id}_banner.png`, `{id}_thumb.png`, rồi bản `placeholder_{id}_*.png`, cuối cùng vẽ hình người placeholder.
@export_file("*.png", "*.webp", "*.jpg") var banner_art := ""
@export_file("*.png", "*.webp", "*.jpg") var thumb_art := ""
## Hết hạn (giây Unix UTC). 0 = không giới hạn thời gian.
@export var end_unix := 0
## Thứ tự trong danh sách bên trái: nhỏ lên trước, bằng nhau thì theo tên file. Banner trang bị thường = 100
## để luôn nằm cuối (owner 2026-11-15).
@export var list_order := 0

@export_group("Lượt miễn phí hướng dẫn")
## Banner dùng một lần cho người mới (owner 2026-11-13): quay gói `multi_count` không tốn tiền, đúng 1 lượt ra bậc
## đầu tiên (vd Raikiba), các lượt còn lại ra bậc cuối (nguyên liệu). Chỉ hiện ở màn Chiêu mộ khi còn dùng được.
@export var starter_free_multi := false
## Vé cần có (id vật phẩm trong data/items) để dùng lượt miễn phí; quay xong trừ 1 vé. Rỗng = không cần vé.
## Owner 2026-11-14: vé `ticket_starter_x10` nhận khi qua ải 1-1.
@export var ticket_item := ""


func tier(key: String) -> GachaTierDef:
	for t in tiers:
		if t and t.key() == key:
			return t
	return null


func group() -> String:
	return pity_group if pity_group != "" else id


func validate() -> PackedStringArray:
	var e := PackedStringArray()
	if id.is_empty():
		e.append("thiếu id")
	if name_key.is_empty() or name_key != name_key.to_upper():
		e.append("%s: name_key phải là khóa UPPER_SNAKE" % id)
	if tiers.is_empty():
		e.append("%s: không có bậc nào" % id)
		return e
	if cost_single <= 0 or cost_multi <= 0 or multi_count < 2:
		e.append("%s: giá và số lượt phải > 0" % id)
	var sum := 0.0
	var prev_rarity := 1 << 30
	var keys := {}
	var seen := {}
	for i in tiers.size():
		var t := tiers[i]
		if t == null:
			e.append("%s: bậc %d rỗng" % [id, i])
			continue
		if t.rarity > prev_rarity:
			e.append("%s: bậc phải sắp từ hiếm xuống thường" % id)
		prev_rarity = t.rarity
		if keys.has(t.key()):
			e.append("%s: trùng khóa bậc %s" % [id, t.key()])
		keys[t.key()] = true
		seen[t.rarity] = true
		if t.pool.is_empty():
			e.append("%s: bậc %d không có phần thưởng" % [id, t.rarity])
		for entry in t.pool:
			var kind := entry.get_slice(":", 0)
			if entry.get_slice_count(":") != 2 or kind not in ["char", "equip", "item", "gold"]:
				e.append("%s: phần thưởng sai dạng '%s'" % [id, entry])
		for f in t.featured:
			if f not in t.pool:
				e.append("%s: rate-up '%s' không nằm trong pool bậc %d" % [id, f, t.rarity])
		if not t.featured.is_empty() and t.featured.size() == t.pool.size() and t.featured_rate < 1.0:
			e.append("%s: bậc %d mọi phần thưởng đều rate-up thì featured_rate phải = 1" % [id, t.rarity])
		if t.featured.is_empty() and (t.featured_rate > 0.0 or t.guarantee_after_miss):
			e.append("%s: bậc %d có featured_rate / bảo hiểm nhưng không có rate-up" % [id, t.rarity])
		if t.soft_pity_start > 0 and t.hard_pity > 0 and t.soft_pity_start >= t.hard_pity:
			e.append("%s: bậc %d pity mềm phải bắt đầu trước pity cứng" % [id, t.rarity])
		if t.exclude_owned_until_complete:
			for entry in t.pool:
				if not entry.begins_with("equip:"):
					e.append("%s: bậc %d loại món đã có chỉ dùng cho trang bị" % [id, t.rarity])
		if i < tiers.size() - 1:
			sum += t.base_rate * (t.pool.size() if t.rate_per_item else 1)
	for k in multi_guarantee_tiers:
		if not keys.has(k):
			e.append("%s: multi_guarantee_tiers có khóa lạ '%s'" % [id, k])
	for k in multi_guarantee_pick:
		if not keys.has(k):
			e.append("%s: multi_guarantee_pick có khóa lạ '%s'" % [id, k])
	if multi_guarantee_tiers.is_empty() != multi_guarantee_pick.is_empty():
		e.append("%s: multi_guarantee_tiers và multi_guarantee_pick phải cùng có hoặc cùng không" % id)
	if sum > 1.0 + 0.000001:
		e.append("%s: tổng tỉ lệ các bậc trên vượt 100%%" % id)
	return e
