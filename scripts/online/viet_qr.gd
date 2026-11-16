class_name VietQr
extends RefCounted
## Chuỗi mã VietQR (chuẩn NAPAS 247 / EMVCo QR) để người chơi quét bằng app ngân hàng và chuyển khoản đúng số tiền + nội dung.
## Thông tin nhận tiền lấy từ máy chủ (data/shop/topup_packs.json, "payment"). Mã QR vẽ bằng QrCode, không gọi dịch vụ ngoài.

const NAPAS_GUID := "A000000727"
const SERVICE_ACCOUNT := "QRIBFTTA"   # chuyển nhanh tới số tài khoản
const MEMO_MAX := 25


## Một trường TLV: mã (2 ký tự) + độ dài (2 chữ số) + giá trị.
static func tlv(id: String, value: String) -> String:
	return id + "%02d" % value.to_utf8_buffer().size() + value


## Chuỗi QR chuyển khoản. amount <= 0: không cố định số tiền (người chuyển tự nhập).
static func payload(bank_bin: String, account: String, amount := 0, memo := "") -> String:
	var beneficiary := tlv("00", bank_bin) + tlv("01", account)
	var merchant := tlv("00", NAPAS_GUID) + tlv("01", beneficiary) + tlv("02", SERVICE_ACCOUNT)
	var s := tlv("00", "01") + tlv("01", "12" if amount > 0 else "11") + tlv("38", merchant) + tlv("53", "704")
	if amount > 0:
		s += tlv("54", str(amount))
	s += tlv("58", "VN")
	var clean := clean_memo(memo)
	if not clean.is_empty():
		s += tlv("62", tlv("08", clean))
	s += "6304"
	return s + crc16(s)


## Nội dung chuyển khoản: chỉ chữ không dấu, số, dấu cách (ngân hàng không nhận ký tự khác), tối đa 25 ký tự.
static func clean_memo(memo: String) -> String:
	var out := ""
	for ch in memo:
		var c := ch.unicode_at(0)
		if (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 32:
			out += ch
	return out.strip_edges().substr(0, MEMO_MAX)


## CRC-16/CCITT-FALSE (đa thức 0x1021, khởi tạo 0xFFFF) của chuỗi, 4 chữ hex HOA.
static func crc16(text: String) -> String:
	var crc := 0xFFFF
	for b in text.to_utf8_buffer():
		crc ^= b << 8
		for i in 8:
			crc = ((crc << 1) ^ 0x1021) if (crc & 0x8000) != 0 else (crc << 1)
			crc &= 0xFFFF
	return "%04X" % crc


## Tách các trường TLV cấp ngoài cùng: {mã: giá trị}. Dùng trong test.
static func parse(payload_text: String) -> Dictionary:
	var out := {}
	var i := 0
	while i + 4 <= payload_text.length():
		var id := payload_text.substr(i, 2)
		var n := int(payload_text.substr(i + 2, 2))
		out[id] = payload_text.substr(i + 4, n)
		i += 4 + n
	return out
