class_name DebugGift
extends RefCounted
## Công cụ gửi quà thử nghiệm thẳng vào tài khoản (owner 2026-11-14): ngọc, vàng, vật phẩm, trang bị, mở khóa nhân vật, mảnh
## nhân vật, cấp người chơi. KHÔNG phải luật gameplay: chỉ dùng để thử game; bảng trong game chỉ hiện ở bản debug
## (`DebugGiftScreen.available()`), còn lệnh dòng lệnh là `tools/give_gift.ps1` (chạy khi game đã đóng).
##
## Cú pháp quà (các mục cách nhau bằng dấu cách hoặc dấu phẩy):
##   gems=5000  gold=100000                  tiền tệ
##   item:mat_exp_small=5  item:all=10       vật phẩm / nguyên liệu (thiếu =N là 1; all = mọi loại)
##   equip:eq_weapon_flame=2  equip:all      trang bị (mỗi món một bản; =N cho N bản)
##   char:char_earth_01  char:all            mở khóa nhân vật
##   frag:char_fire_01=50  frag:all=100      mảnh nhân vật (tự mở khóa nhân vật nếu chưa có)
##   captain=50                              nâng cấp người chơi lên ít nhất cấp này (không bao giờ hạ cấp)
##   captain_exp=300                         cộng EXP người chơi
##   preset:rich                             gói quà mẫu trong data/debug/gift_presets.json (gói có thể gọi gói khác)
## Quà được kiểm tra trước: có ID lạ thì không áp gì cả (không áp nửa chừng).

const PRESETS_PATH := "res://data/debug/gift_presets.json"
const CHARACTERS_DIR := "res://data/characters"
const MAX_PRESET_DEPTH := 6
const SYNTAX_HELP := "gems=5000 gold=100000 item:mat_exp_small=5 equip:all char:all frag:all=100 captain=50 preset:rich"


static func empty() -> Dictionary:
	return {"gold": 0, "gems": 0, "materials": {}, "equipment": {}, "characters": [], "fragments": {},
			"captain_level": 0, "captain_exp": 0}


static func is_empty(gift: Dictionary) -> bool:
	return int(gift["gold"]) == 0 and int(gift["gems"]) == 0 and (gift["materials"] as Dictionary).is_empty() \
			and (gift["equipment"] as Dictionary).is_empty() and (gift["characters"] as Array).is_empty() \
			and (gift["fragments"] as Dictionary).is_empty() and int(gift["captain_level"]) == 0 and int(gift["captain_exp"]) == 0


# ---------- Danh sách ID hiện có ----------

static func item_ids() -> PackedStringArray:
	return PlayerProfile.item_defs().ids()


static func equipment_ids() -> PackedStringArray:
	return PlayerProfile.equipment_defs().ids()


static func character_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for f in ResourceLoader.list_directory(CHARACTERS_DIR):
		var base := f.get_basename()
		if f.get_extension() in ["tres", "res"] and not base.ends_with("_kit"):
			out.append(base)
	out.sort()
	return out


# ---------- Gói quà mẫu ----------

## {tên gói: {"title": "...", "gift": "cú pháp quà"}} theo thứ tự trong file; rỗng nếu thiếu file (vd bản Release).
static func load_presets() -> Dictionary:
	if not FileAccess.file_exists(PRESETS_PATH):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESETS_PATH))
	if d is Dictionary and d.get("presets") is Dictionary:
		return d["presets"]
	return {}


static func preset_gift(preset_name: String, depth := 0) -> Dictionary:
	var presets := load_presets()
	if not presets.has(preset_name):
		return {"gift": empty(), "errors": PackedStringArray(["không có gói quà '%s'" % preset_name])}
	return parse(str((presets[preset_name] as Dictionary).get("gift", "")), depth)


# ---------- Cú pháp ----------

## Đọc cú pháp quà. Trả về {"gift": Dictionary, "errors": PackedStringArray}; lỗi cú pháp thì gift vẫn gồm các mục đã đọc được.
static func parse(text: String, depth := 0) -> Dictionary:
	var gift := empty()
	var errors := PackedStringArray()
	var syntax := "xem ví dụ: " + SYNTAX_HELP
	for raw in text.replace(",", " ").replace("\n", " ").replace("\t", " ").split(" ", false):
		var tok := String(raw).strip_edges()
		var key := tok
		var val := ""
		var eq := tok.find("=")
		if eq >= 0:
			key = tok.substr(0, eq)
			val = tok.substr(eq + 1)
		var kind := key.get_slice(":", 0).to_lower()
		var id := key.get_slice(":", 1) if key.contains(":") else ""
		var n := 1
		if eq >= 0:
			if not val.is_valid_int() or int(val) <= 0:
				errors.append("'%s': số lượng phải là số nguyên lớn hơn 0" % tok)
				continue
			n = int(val)
		match kind:
			"gold", "gems", "captain", "captain_exp":
				if eq < 0:
					errors.append("'%s': thiếu số lượng (vd %s=100)" % [tok, kind])
					continue
				match kind:
					"captain":
						gift["captain_level"] = maxi(int(gift["captain_level"]), n)
					"captain_exp":
						gift["captain_exp"] = int(gift["captain_exp"]) + n
					_:
						gift[kind] = int(gift[kind]) + n
			"preset":
				if id == "":
					errors.append("'%s': thiếu tên gói (vd preset:rich)" % tok)
				elif depth >= MAX_PRESET_DEPTH:
					errors.append("'%s': gói quà lồng nhau quá sâu (có vòng lặp?)" % tok)
				else:
					var p := preset_gift(id, depth + 1)
					errors.append_array(p["errors"])
					gift = merge(gift, p["gift"])
			"item", "equip", "frag", "char":
				if id == "":
					errors.append("'%s': thiếu ID (vd %s:<id> hoặc %s:all)" % [tok, kind, kind])
					continue
				var ids: PackedStringArray
				if id == "all":
					ids = item_ids() if kind == "item" else (equipment_ids() if kind == "equip" else character_ids())
				else:
					ids = PackedStringArray([id])
				for one in ids:
					match kind:
						"item":
							gift["materials"][one] = int(gift["materials"].get(one, 0)) + n
						"equip":
							gift["equipment"][one] = int(gift["equipment"].get(one, 0)) + n
						"frag":
							gift["fragments"][one] = int(gift["fragments"].get(one, 0)) + n
						"char":
							if one not in gift["characters"]:
								gift["characters"].append(one)
			_:
				errors.append("'%s': không hiểu (%s)" % [tok, syntax])
	return {"gift": gift, "errors": errors}


## Cộng hai quà (cấp người chơi lấy giá trị lớn hơn).
static func merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate(true)
	for k in ["gold", "gems", "captain_exp"]:
		out[k] = int(a[k]) + int(b[k])
	out["captain_level"] = maxi(int(a["captain_level"]), int(b["captain_level"]))
	for k in ["materials", "equipment", "fragments"]:
		for id in b[k]:
			out[k][id] = int(out[k].get(id, 0)) + int(b[k][id])
	for id in b["characters"]:
		if id not in out["characters"]:
			out["characters"].append(id)
	return out


# ---------- Kiểm tra, áp dụng ----------

## Lỗi của quà (ID không tồn tại, cấp vượt tối đa). Rỗng = hợp lệ.
static func validate(gift: Dictionary) -> PackedStringArray:
	var e := PackedStringArray()
	for id in gift["materials"]:
		if not PlayerProfile.item_defs().has(id):
			e.append("không có vật phẩm '%s' (xem danh sách bằng --list)" % id)
	for id in gift["equipment"]:
		if not PlayerProfile.equipment_defs().has(id):
			e.append("không có trang bị '%s'" % id)
	var chars := character_ids()
	var wanted: Array = (gift["characters"] as Array).duplicate()
	wanted.append_array((gift["fragments"] as Dictionary).keys())
	for id in wanted:
		if id not in chars:
			e.append("không có nhân vật '%s'" % id)
	var rules := load(PlayerProfile.RULES_PATH) as ProgressionRules
	if rules and int(gift["captain_level"]) > rules.captain_max_level:
		e.append("cấp người chơi tối đa là %d" % rules.captain_max_level)
	return e


## Gửi quà vào `profile` (chỉ sửa dữ liệu trong bộ nhớ; người gọi tự lưu). Có lỗi thì không đổi gì.
## Trả về {"ok": bool, "errors": PackedStringArray, "lines": PackedStringArray (tóm tắt đã gửi)}.
static func apply(profile: PlayerProfile, gift: Dictionary) -> Dictionary:
	var errors := validate(gift)
	if not errors.is_empty():
		return {"ok": false, "errors": errors, "lines": PackedStringArray()}
	var inv := profile.inventory
	var prog := profile.progression
	if int(gift["gold"]) > 0:
		inv.add_currency("gold", int(gift["gold"]))
	if int(gift["gems"]) > 0:
		inv.add_currency("gems", int(gift["gems"]))
	for id in gift["materials"]:
		inv.add_material(id, int(gift["materials"][id]))
	for id in gift["equipment"]:
		for i in int(gift["equipment"][id]):
			inv.add_equipment(id)
	for id in gift["characters"]:
		prog.unlock(id)
	for id in gift["fragments"]:
		prog.unlock(id)
		prog.add_fragments(id, int(gift["fragments"][id]))
	if int(gift["captain_level"]) > prog.captain_level():
		profile.data["account"]["level"] = int(gift["captain_level"])
		profile.data["account"]["exp"] = 0
	if int(gift["captain_exp"]) > 0:
		prog.add_captain_exp(int(gift["captain_exp"]))
	return {"ok": true, "errors": PackedStringArray(), "lines": summary_lines(gift)}


# ---------- Tóm tắt hiển thị ----------

static func _t(key: String) -> String:
	return TranslationServer.translate(key)


static func _char_name(id: String) -> String:
	var p := PlayerProfile.CHARACTER_DATA % id
	var d := load(p) as CharacterDef if ResourceLoader.exists(p) else null
	return _t(d.name_key) if d else id


static func summary_lines(gift: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	if int(gift["gems"]) > 0:
		out.append("%s +%d" % [_t("CURRENCY_GEMS"), int(gift["gems"])])
	if int(gift["gold"]) > 0:
		out.append("%s +%d" % [_t("CURRENCY_GOLD"), int(gift["gold"])])
	for id in gift["materials"]:
		var d := PlayerProfile.item_defs().get_def(id) as ItemDef
		out.append("%s ×%d" % [_t(d.name_key) if d else id, int(gift["materials"][id])])
	for id in gift["equipment"]:
		var d := PlayerProfile.equipment_defs().get_def(id) as EquipmentDef
		out.append("%s ×%d" % [_t(d.name_key) if d else id, int(gift["equipment"][id])])
	for id in gift["characters"]:
		out.append(_t("DEBUG_GIFT_LINE_CHAR_UNLOCK") % _char_name(id))
	for id in gift["fragments"]:
		out.append(_t("DEBUG_GIFT_LINE_FRAG") % [_char_name(id), int(gift["fragments"][id])])
	if int(gift["captain_level"]) > 0:
		out.append(_t("DEBUG_GIFT_LINE_CAPTAIN") % int(gift["captain_level"]))
	if int(gift["captain_exp"]) > 0:
		out.append(_t("DEBUG_GIFT_LINE_CAPTAIN_EXP") % int(gift["captain_exp"]))
	return out


## Một dòng tóm tắt cho nút gói quà (rút gọn khi quá dài).
static func short_summary(gift: Dictionary, max_chars := 90) -> String:
	var s := "  ·  ".join(summary_lines(gift))
	return s if s.length() <= max_chars else s.substr(0, max_chars - 1) + "…"


# ---------- Dòng lệnh ----------

## Chạy lệnh: `args` là các mục quà và tuỳ chọn --list, --dry-run, --save-dir=<thư mục>, --help.
## Trả về {"code": 0 hoặc 1, "lines": PackedStringArray}. `tools/give_gift.gd` chỉ gọi hàm này; test gọi trực tiếp.
static func run_args(args: PackedStringArray, default_save_dir := "user://saves") -> Dictionary:
	var lines := PackedStringArray()
	var save_dir := default_save_dir
	var dry := false
	var listing := false
	var tokens := PackedStringArray()
	for a in args:
		if a == "--help" or a == "-h":
			return {"code": 0, "lines": help_lines()}
		elif a == "--list":
			listing = true
		elif a == "--dry-run":
			dry = true
		elif a.begins_with("--save-dir="):
			save_dir = a.trim_prefix("--save-dir=")
		else:
			tokens.append(a)
	if listing:
		return {"code": 0, "lines": list_lines()}
	if tokens.is_empty():
		lines.append("Chưa có quà nào để gửi.")
		lines.append_array(help_lines())
		return {"code": 1, "lines": lines}
	var parsed := parse(" ".join(tokens))
	if not (parsed["errors"] as PackedStringArray).is_empty():
		lines.append("LỖI cú pháp (chưa đổi gì):")
		for e in parsed["errors"]:
			lines.append("  - " + e)
		return {"code": 1, "lines": lines}
	var gift: Dictionary = parsed["gift"]
	var store := SaveStore.new(save_dir)
	var had_save := store.has_save()
	var data := store.read()
	var profile := PlayerProfile.new(data)
	var res := apply(profile, gift)
	if not res["ok"]:
		lines.append("LỖI (chưa đổi gì):")
		for e in res["errors"]:
			lines.append("  - " + e)
		return {"code": 1, "lines": lines}
	lines.append("%s %s" % ["Chạy thử, KHÔNG ghi save:" if dry else "Đã gửi vào", "" if dry else save_dir])
	for l in res["lines"]:
		lines.append("  + " + l)
	if not had_save:
		lines.append("(chưa có save trước đó: tạo save mới từ dữ liệu mặc định)")
	if not dry:
		var err := store.write(profile.data)
		if err != OK:
			lines.append("LỖI ghi save (mã %d)" % err)
			return {"code": 1, "lines": lines}
		lines.append("Đã lưu. Đóng game trước khi chạy lệnh này, nếu không game sẽ ghi đè khi thoát.")
	return {"code": 0, "lines": lines}


static func help_lines() -> PackedStringArray:
	return PackedStringArray([
		"Gửi quà thử nghiệm vào save:  tools\\give_gift.ps1 <quà...> [--dry-run] [--save-dir=<thư mục>]",
		"  tools\\give_gift.ps1 --list        in gói quà mẫu và danh sách ID",
		"Quà:  " + SYNTAX_HELP,
		"Đóng game trước khi chạy. Có ID lạ thì không áp gì cả.",
	])


static func list_lines() -> PackedStringArray:
	var out := PackedStringArray()
	out.append("Gói quà mẫu (data/debug/gift_presets.json):")
	var presets := load_presets()
	for name_ in presets:
		out.append("  preset:%s  —  %s" % [name_, (presets[name_] as Dictionary).get("title", "")])
		out.append("      %s" % (presets[name_] as Dictionary).get("gift", ""))
	out.append("Vật phẩm (item:): " + ", ".join(item_ids()))
	out.append("Trang bị (equip:): " + ", ".join(equipment_ids()))
	out.append("Nhân vật (char:, frag:): " + ", ".join(character_ids()))
	out.append("Tiền tệ: gems, gold.  Cấp người chơi: captain=<cấp>, captain_exp=<EXP>.")
	return out
