class_name QrReader
extends RefCounted
## Bộ ĐỌC mã QR dùng trong test để kiểm tra QrCode (đi ngược lại bộ mã hóa): đọc thông tin định dạng ở cả hai chỗ, gỡ mặt nạ,
## lấy codeword theo đường zigzag, tách khối, kiểm đa thức Reed-Solomon của MỌI khối (phần dư phải bằng 0) rồi đọc lại chuỗi.
## Viết riêng (bảng GF dựng bằng log / exp, không dùng hàm nhân của QrCode) để lỗi ở một bên lộ ra ở bên kia.

const FORMAT_COPY_1 := [Vector2i(0, 8), Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4, 8), Vector2i(5, 8),
		Vector2i(7, 8), Vector2i(8, 8), Vector2i(8, 7), Vector2i(8, 5), Vector2i(8, 4), Vector2i(8, 3), Vector2i(8, 2),
		Vector2i(8, 1), Vector2i(8, 0)]   # bit 14 → bit 0


## {ok, error, text, level, mask, version, blocks_ok}
static func read(qr: QrCode) -> Dictionary:
	var size := qr.size
	var rows := qr.to_rows()
	var f1 := 0
	for k in 15:
		var p: Vector2i = FORMAT_COPY_1[k]
		f1 = (f1 << 1) | (1 if rows[p.y][p.x] == "1" else 0)
	var f2 := 0
	var bits2 := PackedInt32Array()
	bits2.resize(15)
	for i in 8:
		bits2[i] = 1 if rows[8][size - 1 - i] == "1" else 0
	for i in range(8, 15):
		bits2[i] = 1 if rows[size - 15 + i][8] == "1" else 0
	for i in range(14, -1, -1):
		f2 = (f2 << 1) | bits2[i]
	if f1 != f2:
		return {"ok": false, "error": "hai bản thông tin định dạng khác nhau"}
	var level := -1
	var mask := -1
	for l in 4:
		for m in 8:
			if QrCode.format_bits(l, m) == f1:
				level = l
				mask = m
	if level < 0:
		return {"ok": false, "error": "thông tin định dạng không hợp lệ"}
	var version := (size - 17) / 4
	# bản sao ma trận đã gỡ mặt nạ
	var grid: Array = []
	for y in size:
		var r: Array = []
		for x in size:
			var v: bool = rows[y][x] == "1"
			if not qr.is_function(x, y) and _mask_flip(mask, x, y):
				v = not v
			r.append(v)
		grid.append(r)
	# codeword theo zigzag
	var total_bits: Array = []
	var right := size - 1
	while right >= 1:
		if right == 6:
			right = 5
		var upward := ((right + 1) & 2) == 0
		for vert in size:
			for j in 2:
				var x := right - j
				var y := size - 1 - vert if upward else vert
				if not qr.is_function(x, y):
					total_bits.append(1 if grid[y][x] else 0)
		right -= 2
	var raw := total_bits.size() / 8
	var cw: Array = []
	for i in raw:
		var b := 0
		for k in 8:
			b = (b << 1) | int(total_bits[i * 8 + k])
		cw.append(b)
	# tách khối
	var num_blocks: int = QrCode.NUM_ERROR_CORRECTION_BLOCKS[level][version]
	var ecc_len: int = QrCode.ECC_CODEWORDS_PER_BLOCK[level][version]
	var num_short := num_blocks - raw % num_blocks
	var short_len := raw / num_blocks
	var blocks: Array = []
	for i in num_blocks:
		blocks.append([])
	var idx := 0
	for i in short_len + 1:
		for j in num_blocks:
			# khối ngắn không có byte ở cột này (cột giữa dữ liệu và phần sửa lỗi của khối dài)
			if i == short_len - ecc_len and j < num_short:
				continue
			blocks[j].append(cw[idx])
			idx += 1
	# kiểm RS từng khối + gom dữ liệu
	var gf := _gf_tables()
	var data: Array = []
	for j in num_blocks:
		var blk: Array = blocks[j]
		for root in ecc_len:
			var acc := 0
			var alpha: int = gf["exp"][root]
			for b in blk:
				acc = _gf_mul(acc, alpha, gf) ^ b
			if acc != 0:
				return {"ok": false, "error": "khối %d sai Reed-Solomon (nghiệm %d)" % [j, root], "level": level, "mask": mask}
		var data_len := blk.size() - ecc_len
		data.append_array(blk.slice(0, data_len))
	# đọc chuỗi (chế độ byte)
	var bits: Array = []
	for b in data:
		for k in range(7, -1, -1):
			bits.append((b >> k) & 1)
	if _take(bits, 0, 4) != 0x4:
		return {"ok": false, "error": "không phải chế độ byte"}
	var count_bits := 8 if version <= 9 else 16
	var n := _take(bits, 4, count_bits)
	var bytes := PackedByteArray()
	for i in n:
		bytes.append(_take(bits, 4 + count_bits + i * 8, 8))
	return {"ok": true, "error": "", "text": bytes.get_string_from_utf8(), "level": level, "mask": mask, "version": version}


static func _take(bits: Array, start: int, count: int) -> int:
	var v := 0
	for i in count:
		v = (v << 1) | int(bits[start + i])
	return v


static func _mask_flip(m: int, x: int, y: int) -> bool:
	match m:
		0: return (x + y) % 2 == 0
		1: return y % 2 == 0
		2: return x % 3 == 0
		3: return (x + y) % 3 == 0
		4: return (x / 3 + y / 2) % 2 == 0
		5: return (x * y) % 2 + (x * y) % 3 == 0
		6: return ((x * y) % 2 + (x * y) % 3) % 2 == 0
		_: return ((x + y) % 2 + (x * y) % 3) % 2 == 0


static func _gf_tables() -> Dictionary:
	var exp: Array = []
	var log: Array = []
	exp.resize(512)
	log.resize(256)
	var x := 1
	for i in 255:
		exp[i] = x
		log[x] = i
		x <<= 1
		if x & 0x100:
			x ^= 0x11D
	for i in range(255, 512):
		exp[i] = exp[i - 255]
	return {"exp": exp, "log": log}


static func _gf_mul(a: int, b: int, gf: Dictionary) -> int:
	if a == 0 or b == 0:
		return 0
	return gf["exp"][int(gf["log"][a]) + int(gf["log"][b])]
