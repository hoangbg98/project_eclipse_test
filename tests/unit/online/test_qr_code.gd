extends GdUnitTestSuite
## Test QrCode + VietQr (M9-2): bảng chuẩn, đọc ngược bằng QrReader (RS mọi khối, thông tin định dạng, chuỗi), CRC VietQR.
## Lưu ý: không đối chiếu với thư viện QR bên thứ ba; kiểm cuối cùng là quét bằng app ngân hàng thật (xem DEVELOPMENT_LOG).

const VIETQR_TEXT := "00020101021238590010A00000072701290006970423011115324121998" \
		+ "0208QRIBFTTA5303704540714000005802VN62160812ECL 818138736304ABCD"


func test_data_capacities_match_standard() -> void:
	# Số codeword dữ liệu theo chuẩn ISO 18004 (bảng 7) — kiểm bảng ECC / số khối cho phiên bản 1–10.
	var expected := {
		QrCode.Ecc.LOW: [19, 34, 55, 80, 108, 136, 156, 194, 232, 274],
		QrCode.Ecc.MEDIUM: [16, 28, 44, 64, 86, 108, 124, 154, 182, 216],
		QrCode.Ecc.QUARTILE: [13, 22, 34, 48, 62, 76, 88, 110, 132, 154],
		QrCode.Ecc.HIGH: [9, 16, 26, 36, 46, 60, 66, 86, 100, 122],
	}
	for level: int in expected:
		for v in 10:
			assert_int(QrCode.num_data_codewords(v + 1, level)).is_equal(expected[level][v])
	# Tổng codeword (dữ liệu + sửa lỗi) theo phiên bản
	var totals := [26, 44, 70, 100, 134, 172, 196, 242, 292, 346]
	for v in 10:
		assert_int(QrCode._num_raw_data_modules(v + 1) / 8).is_equal(totals[v])


func test_format_and_version_bits_match_standard() -> void:
	# Bảng thông tin định dạng của chuẩn (mức sửa lỗi, mặt nạ) → 15 bit.
	assert_int(QrCode.format_bits(QrCode.Ecc.MEDIUM, 0)).is_equal(0b101010000010010)
	assert_int(QrCode.format_bits(QrCode.Ecc.MEDIUM, 1)).is_equal(0b101000100100101)
	assert_int(QrCode.format_bits(QrCode.Ecc.LOW, 0)).is_equal(0b111011111000100)
	assert_int(QrCode.format_bits(QrCode.Ecc.LOW, 1)).is_equal(0b111001011110011)
	assert_int(QrCode.format_bits(QrCode.Ecc.QUARTILE, 0)).is_equal(0b011010101011111)
	assert_int(QrCode.format_bits(QrCode.Ecc.HIGH, 0)).is_equal(0b001011010001001)
	# Thông tin phiên bản 7, 8.
	assert_int(QrCode.version_bits(7)).is_equal(0b000111110010010100)
	assert_int(QrCode.version_bits(8)).is_equal(0b001000010110111100)


func test_size_and_function_patterns() -> void:
	var qr := QrCode.encode_text("A", QrCode.Ecc.LOW)
	assert_int(qr.version).is_equal(1)
	assert_int(qr.size).is_equal(21)
	# ba ô định vị: hàng đầu của ô định vị là 7 ô tối, ô tối cố định ở (8, size - 8)
	for x in 7:
		assert_bool(qr.get_module(x, 0)).is_true()
		assert_bool(qr.get_module(qr.size - 1 - x, 0)).is_true()
		assert_bool(qr.get_module(x, qr.size - 1)).is_true()
	assert_bool(qr.get_module(8, qr.size - 8)).is_true()
	assert_bool(qr.get_module(1, 1)).is_false()
	assert_bool(qr.get_module(2, 2)).is_true()
	# định thời xen kẽ
	for i in range(8, qr.size - 8):
		assert_bool(qr.get_module(i, 6)).is_equal(i % 2 == 0)
		assert_bool(qr.get_module(6, i)).is_equal(i % 2 == 0)


func test_version_selection() -> void:
	assert_int(QrCode.encode_text("x".repeat(17), QrCode.Ecc.LOW).version).is_equal(1)
	assert_int(QrCode.encode_text("x".repeat(18), QrCode.Ecc.LOW).version).is_equal(2)
	assert_int(QrCode.encode_text("x".repeat(106), QrCode.Ecc.MEDIUM).version).is_equal(6)   # 108 codeword - 2 byte tiêu đề
	assert_int(QrCode.encode_text("x".repeat(107), QrCode.Ecc.MEDIUM).version).is_equal(7)
	assert_object(QrCode.encode_text("x".repeat(3000), QrCode.Ecc.HIGH)).is_null()
	assert_object(QrCode.encode_text("x".repeat(500), QrCode.Ecc.LOW, -1, 1, 10)).is_null()


func test_round_trip_all_masks_and_levels() -> void:
	var cases := [
		["HELLO WORLD", QrCode.Ecc.LOW],
		["HELLO WORLD", QrCode.Ecc.MEDIUM],
		["HELLO WORLD", QrCode.Ecc.QUARTILE],
		["HELLO WORLD", QrCode.Ecc.HIGH],
		["Xin chào, Project Eclipse! 日本", QrCode.Ecc.MEDIUM],
		[VIETQR_TEXT, QrCode.Ecc.MEDIUM],
		["x".repeat(100), QrCode.Ecc.QUARTILE],     # nhiều khối, có khối ngắn + khối dài
		["y".repeat(60), QrCode.Ecc.HIGH],
		["z".repeat(200), QrCode.Ecc.LOW],          # phiên bản >= 7, có thông tin phiên bản
		["ABC".repeat(120), QrCode.Ecc.MEDIUM],     # phiên bản >= 10: độ dài 16 bit
	]
	for c: Array in cases:
		for mask in 8:
			var qr := QrCode.encode_text(c[0], c[1], mask)
			assert_int(qr.mask).is_equal(mask)
			var r := QrReader.read(qr)
			assert_bool(r["ok"]).override_failure_message("%s (v%d, mask %d): %s" % [str(c[0]).left(12), qr.version, mask, r["error"]]).is_true()
			assert_str(r["text"]).is_equal(c[0])
			assert_int(r["level"]).is_equal(c[1])
			assert_int(r["mask"]).is_equal(mask)
			assert_int(r["version"]).is_equal(qr.version)


func test_auto_mask_is_valid_and_deterministic() -> void:
	var a := QrCode.encode_text(VIETQR_TEXT, QrCode.Ecc.MEDIUM)
	var b := QrCode.encode_text(VIETQR_TEXT, QrCode.Ecc.MEDIUM)
	assert_array(a.to_rows()).is_equal(b.to_rows())
	assert_int(a.version).is_equal(8)
	assert_int(a.size).is_equal(49)
	assert_bool(QrReader.read(a)["ok"]).is_true()
	assert_str(QrReader.read(a)["text"]).is_equal(VIETQR_TEXT)
	# mặt nạ tự chọn phải là mặt nạ ít điểm phạt nhất trong 8 mặt nạ
	var best := 1 << 30
	for m in 8:
		var q := QrCode.encode_text(VIETQR_TEXT, QrCode.Ecc.MEDIUM, m)
		best = mini(best, q._penalty())
	assert_int(a._penalty()).is_equal(best)


func test_to_image() -> void:
	var qr := QrCode.encode_text("A", QrCode.Ecc.LOW)
	var img := qr.to_image(4, 4)
	assert_int(img.get_width()).is_equal((21 + 8) * 4)
	assert_bool(img.get_pixel(0, 0).is_equal_approx(Color.WHITE)).is_true()                  # viền trắng
	assert_bool(img.get_pixel(4 * 4 + 1, 4 * 4 + 1).is_equal_approx(Color.BLACK)).is_true()  # ô (0,0) của ô định vị


# ---------- VietQr ----------

func test_crc16_standard_vector() -> void:
	assert_str(VietQr.crc16("123456789")).is_equal("29B1")   # CRC-16/CCITT-FALSE
	assert_str(VietQr.crc16("")).is_equal("FFFF")


func test_viet_qr_payload_structure() -> void:
	var p := VietQr.payload("970423", "15324121998", 140000, "ECL 81813873")
	var top := VietQr.parse(p)
	assert_str(top["00"]).is_equal("01")
	assert_str(top["01"]).is_equal("12")            # có số tiền cố định
	assert_str(top["53"]).is_equal("704")           # VND
	assert_str(top["54"]).is_equal("140000")
	assert_str(top["58"]).is_equal("VN")
	assert_str(VietQr.parse(top["62"])["08"]).is_equal("ECL 81813873")
	var merchant := VietQr.parse(top["38"])
	assert_str(merchant["00"]).is_equal("A000000727")
	assert_str(merchant["02"]).is_equal("QRIBFTTA")
	var acct := VietQr.parse(merchant["01"])
	assert_str(acct["00"]).is_equal("970423")
	assert_str(acct["01"]).is_equal("15324121998")
	# CRC nằm cuối và đúng
	assert_str(p.right(8).left(4)).is_equal("6304")
	assert_str(p.right(4)).is_equal(VietQr.crc16(p.left(p.length() - 4)))
	# không số tiền → kiểu tĩnh (11), không có trường 54
	var static_qr := VietQr.parse(VietQr.payload("970423", "15324121998"))
	assert_str(static_qr["01"]).is_equal("11")
	assert_bool(static_qr.has("54")).is_false()
	assert_bool(static_qr.has("62")).is_false()


func test_memo_is_cleaned() -> void:
	assert_str(VietQr.clean_memo("ECL 81813873")).is_equal("ECL 81813873")
	assert_str(VietQr.clean_memo("Nạp ngọc: ECL-1")).is_equal("Np ngc ECL1")
	assert_int(VietQr.clean_memo("x".repeat(40)).length()).is_equal(VietQr.MEMO_MAX)


func test_viet_qr_fits_version_8_and_round_trips() -> void:
	var p := VietQr.payload("970423", "15324121998", 1400000, "ECL 81813873")
	var qr := QrCode.encode_text(p, QrCode.Ecc.MEDIUM)
	assert_int(qr.version).is_less_equal(8)
	var r := QrReader.read(qr)
	assert_bool(r["ok"]).is_true()
	assert_str(r["text"]).is_equal(p)
