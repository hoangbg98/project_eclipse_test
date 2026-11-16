class_name PurchasedCurrency
extends RefCounted
## Ngọc đã nạp (M9-2). Ví máy chủ (`wallet.gems`) chỉ TĂNG khi QTV phát gói / người chơi nhận thẻ tháng (hoặc giảm khi QTV thu hồi).
## Save của người chơi nhớ tổng đã cộng (`online.applied.gems`); phần chênh được cộng vào `currencies.gems`. Cách này an toàn
## khi tắt game / mất mạng giữa chừng: cả hai số nằm trong cùng một lần ghi save, nên không bao giờ cộng hai lần hay mất.
## Tiền nạp riêng (corona) không vào save: chỉ nằm ở ví máy chủ, dùng cho vật phẩm độc quyền.


## Cộng phần chênh vào `data` (save). Trả về số Ngọc đã đổi (âm = bị thu hồi); 0 nếu không có gì mới.
static func apply(data: Dictionary, wallet_gems: int) -> int:
	if not (data.get("online") is Dictionary):
		data["online"] = {"applied": {"gems": 0}}
	var online: Dictionary = data["online"]
	if not (online.get("applied") is Dictionary):
		online["applied"] = {"gems": 0}
	var applied := int(online["applied"].get("gems", 0))
	var delta := wallet_gems - applied
	if delta == 0:
		return 0
	var have := int(data["currencies"].get("gems", 0))
	data["currencies"]["gems"] = maxi(have + delta, 0)   # thu hồi không làm Ngọc âm
	online["applied"]["gems"] = wallet_gems
	return delta
