class_name QrCode
extends RefCounted
## Bộ mã hóa mã QR (ISO/IEC 18004, chế độ byte, phiên bản 1–40) viết riêng cho dự án, không dùng thư viện ngoài. Dùng để vẽ mã
## QR chuyển khoản (VietQr) ngay trong game, không gửi thông tin ra dịch vụ nào. Đã đối chiếu từng ô với thư viện tham chiếu
## (python-qrcode) cho cả 8 mặt nạ (tests/unit/online/test_qr_code.gd).

enum Ecc { LOW, MEDIUM, QUARTILE, HIGH }

const ECC_FORMAT_BITS := [1, 0, 3, 2]
const ECC_CODEWORDS_PER_BLOCK := [
	[-1, 7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30, 28, 28, 28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
	[-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28],
	[-1, 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28, 26, 30, 28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
	[-1, 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28, 26, 28, 30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
]
const NUM_ERROR_CORRECTION_BLOCKS := [
	[-1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 4, 6, 6, 6, 6, 7, 8, 8, 9, 9, 10, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25],
	[-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16, 17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49],
	[-1, 1, 1, 2, 2, 4, 4, 6, 6, 8, 8, 8, 10, 12, 16, 12, 17, 16, 18, 21, 20, 23, 23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68],
	[-1, 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11, 16, 16, 18, 16, 19, 21, 25, 25, 25, 34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81],
]

var version := 0
var size := 0
## Mặt nạ đã chọn (0–7).
var mask := -1
var ecc := Ecc.MEDIUM

var _modules: Array = []       # [y][x] -> bool (true = ô tối)
var _is_function: Array = []   # [y][x] -> bool


## Mã hóa `text` (UTF-8, chế độ byte). `force_mask` -1 = tự chọn mặt nạ ít điểm phạt nhất. Trả về null nếu quá dài.
static func encode_text(text: String, level := Ecc.MEDIUM, force_mask := -1, min_version := 1, max_version := 40) -> QrCode:
	var data := text.to_utf8_buffer()
	var ver := min_version
	var used_bits := 0
	while true:
		var capacity := _num_data_codewords(ver, level) * 8
		used_bits = 4 + (8 if ver <= 9 else 16) + data.size() * 8
		if used_bits <= capacity:
			break
		if ver >= max_version:
			return null
		ver += 1
	var bits: Array = []
	_append_bits(bits, 0x4, 4)   # chế độ byte
	_append_bits(bits, data.size(), 8 if ver <= 9 else 16)
	for b in data:
		_append_bits(bits, b, 8)
	var cap_bits := _num_data_codewords(ver, level) * 8
	_append_bits(bits, 0, mini(4, cap_bits - bits.size()))
	_append_bits(bits, 0, (8 - bits.size() % 8) % 8)
	var pad := 0xEC
	while bits.size() < cap_bits:
		_append_bits(bits, pad, 8)
		pad = 0x11 if pad == 0xEC else 0xEC
	var codewords := PackedByteArray()
	codewords.resize(bits.size() / 8)
	for i in bits.size():
		codewords[i >> 3] = codewords[i >> 3] | (int(bits[i]) << (7 - (i & 7)))
	var qr := QrCode.new()
	qr._build(ver, level, codewords, force_mask)
	return qr


## Ô (x, y) thuộc vùng chức năng (ô định vị, căn chỉnh, định thời, thông tin định dạng / phiên bản), không phải dữ liệu.
func is_function(x: int, y: int) -> bool:
	return _is_function[y][x]


## 15 bit thông tin định dạng (mức sửa lỗi + mặt nạ, đã BCH và XOR 0x5412).
static func format_bits(level: Ecc, m: int) -> int:
	var data: int = (ECC_FORMAT_BITS[level] << 3) | m
	var rem := data
	for i in 10:
		rem = (rem << 1) ^ ((rem >> 9) * 0x537)
	return ((data << 10) | rem) ^ 0x5412


## 18 bit thông tin phiên bản (chỉ có từ phiên bản 7).
static func version_bits(ver: int) -> int:
	var rem := ver
	for i in 12:
		rem = (rem << 1) ^ ((rem >> 11) * 0x1F25)
	return (ver << 12) | rem


func get_module(x: int, y: int) -> bool:
	return x >= 0 and x < size and y >= 0 and y < size and _modules[y][x]


## Mỗi hàng là chuỗi '0' / '1' (để test).
func to_rows() -> PackedStringArray:
	var out := PackedStringArray()
	for y in size:
		var s := ""
		for x in size:
			s += "1" if _modules[y][x] else "0"
		out.append(s)
	return out


## Ảnh đen trắng: mỗi ô `module_px` điểm ảnh, viền trắng `border` ô (chuẩn là 4).
func to_image(module_px := 8, border := 4) -> Image:
	var total := (size + border * 2) * module_px
	var img := Image.create(total, total, false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	for y in size:
		for x in size:
			if _modules[y][x]:
				img.fill_rect(Rect2i((x + border) * module_px, (y + border) * module_px, module_px, module_px), Color.BLACK)
	return img


# ---------- Dựng ma trận ----------

func _build(ver: int, level: Ecc, data_codewords: PackedByteArray, force_mask: int) -> void:
	version = ver
	ecc = level
	size = ver * 4 + 17
	_modules = []
	_is_function = []
	for y in size:
		_modules.append(_row(false))
		_is_function.append(_row(false))
	_draw_function_patterns()
	_draw_codewords(_add_ecc_and_interleave(data_codewords))
	var best := force_mask
	if best < 0:
		var min_penalty := 1 << 30
		for m in 8:
			_apply_mask(m)
			_draw_format_bits(m)
			var p := _penalty()
			if p < min_penalty:
				best = m
				min_penalty = p
			_apply_mask(m)   # bỏ mặt nạ
	mask = best
	_apply_mask(mask)
	_draw_format_bits(mask)


func _row(v: bool) -> Array:
	var r: Array = []
	r.resize(size)
	r.fill(v)
	return r


func _set_function(x: int, y: int, dark: bool) -> void:
	_modules[y][x] = dark
	_is_function[y][x] = true


func _draw_function_patterns() -> void:
	for i in size:
		_set_function(6, i, i % 2 == 0)
		_set_function(i, 6, i % 2 == 0)
	_draw_finder(3, 3)
	_draw_finder(size - 4, 3)
	_draw_finder(3, size - 4)
	var pos := _alignment_positions()
	var n := pos.size()
	for i in n:
		for j in n:
			if not ((i == 0 and j == 0) or (i == 0 and j == n - 1) or (i == n - 1 and j == 0)):
				_draw_alignment(pos[i], pos[j])
	_draw_format_bits(0)   # chỉ để đánh dấu vùng chức năng
	_draw_version()


func _draw_finder(cx: int, cy: int) -> void:
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			var dist := maxi(absi(dx), absi(dy))
			var x := cx + dx
			var y := cy + dy
			if x >= 0 and x < size and y >= 0 and y < size:
				_set_function(x, y, dist != 2 and dist != 4)


func _draw_alignment(cx: int, cy: int) -> void:
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			_set_function(cx + dx, cy + dy, maxi(absi(dx), absi(dy)) != 1)


func _alignment_positions() -> Array:
	if version == 1:
		return []
	var n := version / 7 + 2
	var step := (version * 8 + n * 3 + 5) / (n * 4 - 4) * 2 if version != 32 else 26
	var result: Array = [6]
	var p := size - 7
	for i in n - 1:
		result.insert(1, p)
		p -= step
	return result


func _draw_format_bits(m: int) -> void:
	var bits := format_bits(ecc, m)
	for i in 6:
		_set_function(8, i, _bit(bits, i))
	_set_function(8, 7, _bit(bits, 6))
	_set_function(8, 8, _bit(bits, 7))
	_set_function(7, 8, _bit(bits, 8))
	for i in range(9, 15):
		_set_function(14 - i, 8, _bit(bits, i))
	for i in 8:
		_set_function(size - 1 - i, 8, _bit(bits, i))
	for i in range(8, 15):
		_set_function(8, size - 15 + i, _bit(bits, i))
	_set_function(8, size - 8, true)


func _draw_version() -> void:
	if version < 7:
		return
	var bits := version_bits(version)
	for i in 18:
		var dark := _bit(bits, i)
		var a := size - 11 + i % 3
		var b := i / 3
		_set_function(a, b, dark)
		_set_function(b, a, dark)


static func _bit(value: int, i: int) -> bool:
	return ((value >> i) & 1) != 0


func _draw_codewords(data: PackedByteArray) -> void:
	var i := 0
	var right := size - 1
	while right >= 1:
		if right == 6:
			right = 5
		for vert in size:
			for j in 2:
				var x := right - j
				var upward := ((right + 1) & 2) == 0
				var y := size - 1 - vert if upward else vert
				if not _is_function[y][x] and i < data.size() * 8:
					_modules[y][x] = _bit(data[i >> 3], 7 - (i & 7))
					i += 1
		right -= 2


func _apply_mask(m: int) -> void:
	for y in size:
		for x in size:
			if _is_function[y][x]:
				continue
			var invert := false
			match m:
				0: invert = (x + y) % 2 == 0
				1: invert = y % 2 == 0
				2: invert = x % 3 == 0
				3: invert = (x + y) % 3 == 0
				4: invert = (x / 3 + y / 2) % 2 == 0
				5: invert = x * y % 2 + x * y % 3 == 0
				6: invert = (x * y % 2 + x * y % 3) % 2 == 0
				7: invert = ((x + y) % 2 + x * y % 3) % 2 == 0
			if invert:
				_modules[y][x] = not _modules[y][x]


## Điểm phạt chọn mặt nạ (4 luật của chuẩn: dải cùng màu, khối 2x2, mẫu giống ô định vị, tỉ lệ ô tối).
func _penalty() -> int:
	var result := 0
	for horizontal in 2:
		for a in size:
			var run := 1
			var prev: bool = _cell(0, a, horizontal)
			for b in range(1, size):
				var cur: bool = _cell(b, a, horizontal)
				if cur == prev:
					run += 1
					if run == 5:
						result += 3
					elif run > 5:
						result += 1
				else:
					run = 1
					prev = cur
	for y in size - 1:
		for x in size - 1:
			var c: bool = _modules[y][x]
			if c == _modules[y][x + 1] and c == _modules[y + 1][x] and c == _modules[y + 1][x + 1]:
				result += 3
	var pat_a := [true, false, true, true, true, false, true, false, false, false, false]
	var pat_b := [false, false, false, false, true, false, true, true, true, false, true]
	for horizontal in 2:
		for a in size:
			for b in range(0, size - 10):
				var ma := true
				var mb := true
				for k in 11:
					var v: bool = _cell(b + k, a, horizontal)
					if v != pat_a[k]:
						ma = false
					if v != pat_b[k]:
						mb = false
					if not ma and not mb:
						break
				if ma:
					result += 40
				if mb:
					result += 40
	var dark := 0
	for row in _modules:
		for v in row:
			if v:
				dark += 1
	var total := size * size
	var k := (absi(dark * 20 - total * 10) + total - 1) / total - 1
	result += maxi(k, 0) * 10
	return result


func _cell(b: int, a: int, horizontal: int) -> bool:
	return _modules[a][b] if horizontal == 0 else _modules[b][a]


# ---------- Dữ liệu + Reed-Solomon ----------

static func _append_bits(bits: Array, value: int, count: int) -> void:
	for i in range(count - 1, -1, -1):
		bits.append((value >> i) & 1)


static func _num_raw_data_modules(ver: int) -> int:
	var result := (16 * ver + 128) * ver + 64
	if ver >= 2:
		var n := ver / 7 + 2
		result -= (25 * n - 10) * n - 55
		if ver >= 7:
			result -= 36
	return result


static func num_data_codewords(ver: int, level: Ecc) -> int:
	return _num_data_codewords(ver, level)


static func _num_data_codewords(ver: int, level: Ecc) -> int:
	return _num_raw_data_modules(ver) / 8 - ECC_CODEWORDS_PER_BLOCK[level][ver] * NUM_ERROR_CORRECTION_BLOCKS[level][ver]


func _add_ecc_and_interleave(data: PackedByteArray) -> PackedByteArray:
	var num_blocks: int = NUM_ERROR_CORRECTION_BLOCKS[ecc][version]
	var block_ecc_len: int = ECC_CODEWORDS_PER_BLOCK[ecc][version]
	var raw := _num_raw_data_modules(version) / 8
	var num_short := num_blocks - raw % num_blocks
	var short_len := raw / num_blocks
	var blocks: Array = []
	var divisor := _rs_divisor(block_ecc_len)
	var k := 0
	for i in num_blocks:
		var dat_len := short_len - block_ecc_len + (0 if i < num_short else 1)
		var dat := data.slice(k, k + dat_len)
		k += dat_len
		var ecc_bytes := _rs_remainder(dat, divisor)
		if i < num_short:
			dat.append(0)   # chỗ trống để các khối dài bằng nhau
		dat.append_array(ecc_bytes)
		blocks.append(dat)
	var result := PackedByteArray()
	for i in blocks[0].size():
		for j in blocks.size():
			if i != short_len - block_ecc_len or j >= num_short:
				result.append(blocks[j][i])
	return result


static func _gf_mul(x: int, y: int) -> int:
	var z := 0
	for i in range(7, -1, -1):
		z = (z << 1) ^ ((z >> 7) * 0x11D)
		z ^= ((y >> i) & 1) * x
	return z


static func _rs_divisor(degree: int) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(degree)
	result[degree - 1] = 1
	var root := 1
	for i in degree:
		for j in degree:
			result[j] = _gf_mul(result[j], root)
			if j + 1 < degree:
				result[j] = result[j] ^ result[j + 1]
		root = _gf_mul(root, 0x02)
	return result


static func _rs_remainder(data: PackedByteArray, divisor: PackedByteArray) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(divisor.size())
	for b in data:
		var factor: int = b ^ result[0]
		result.remove_at(0)
		result.append(0)
		for i in divisor.size():
			result[i] = result[i] ^ _gf_mul(divisor[i], factor)
	return result
