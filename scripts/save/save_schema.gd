class_name SaveSchema
extends RefCounted
## Cấu trúc dữ liệu người chơi (ARCHITECTURE mục 8). Chỉ lưu dữ liệu của người chơi (ID sở hữu, cấp,
## trang bị, tiền tệ, pity, lịch sử chiêu mộ, tiến độ màn, cài đặt), không lưu định nghĩa tĩnh.
##
## Khi đổi cấu trúc: tăng VERSION, thêm một hàm vào MIGRATIONS (v cũ → v cũ + 1) và sửa `default_data()`.

const VERSION := 2

## Nhân vật có sẵn khi bắt đầu game mới (slice Q5).
const STARTER_CHARACTERS: Array[String] = ["char_fire_01", "char_lightning_01", "char_wind_01"]
const HISTORY_LIMIT := 200


## Dữ liệu của một game mới.
static func default_data() -> Dictionary:
	var chars := {}
	for id in STARTER_CHARACTERS:
		chars[id] = default_character()
	return {
		"characters": chars,                 # id -> {level, exp, equipment: {slot: uid}}
		"party": STARTER_CHARACTERS.duplicate(),
		"inventory": {
			"next_uid": 1,
			"equipment": {},                 # uid (chuỗi) -> {def_id, level}
			"materials": {},                 # id -> số lượng
		},
		"currencies": {"gold": 0, "gems": 0},
		"gacha": {"pity": {}, "guarantee": {}, "history": []},
		"progress": {"stages": {}},          # stage_id -> {cleared, best_time_sec}
		"settings": {"language": "vi", "master_volume": 1.0, "music_volume": 1.0, "sfx_volume": 1.0, "fullscreen": false},
		"stats": {"play_time_sec": 0.0},
	}


static func default_character() -> Dictionary:
	return {"level": 1, "exp": 0, "equipment": {}}


# ---------- Migration ----------

## v1 → v2: tiền để ở gốc (`gold`, `gems`) chuyển vào `currencies`; thêm `stats`.
static func _migrate_1_to_2(d: Dictionary) -> Dictionary:
	var cur: Dictionary = d.get("currencies", {}) if d.get("currencies") is Dictionary else {}
	for k in ["gold", "gems"]:
		if d.has(k):
			cur[k] = int(d[k]) if (d[k] is float or d[k] is int) else 0
			d.erase(k)
	d["currencies"] = cur
	if not d.has("stats"):
		d["stats"] = {"play_time_sec": 0.0}
	return d


## Chỉ số i = migration từ version i + 1 lên i + 2.
static func migrations() -> Array[Callable]:
	return [_migrate_1_to_2]


## Nâng `data` từ `from_version` lên VERSION. Trả về null nếu version không hợp lệ hoặc mới hơn bản game.
static func migrate(data: Dictionary, from_version: int) -> Variant:
	if from_version < 1 or from_version > VERSION:
		return null
	var d := data
	var steps := migrations()
	for v in range(from_version, VERSION):
		d = steps[v - 1].call(d)
	return d


# ---------- Làm sạch ----------

## Điền mục thiếu và sửa kiểu sai theo `default_data()`; không bao giờ ném lỗi.
## Mục lạ (từ bản mới hơn hoặc rác) trong các từ điển cố định bị bỏ; từ điển động (characters, materials…) giữ lại.
static func sanitize(data: Variant) -> Dictionary:
	var def := default_data()
	if not (data is Dictionary):
		return def
	var out := _merge_fixed(def, data, ["characters", "inventory.equipment", "inventory.materials", "gacha.pity",
			"gacha.guarantee", "progress.stages"], "")
	# Nhân vật: mỗi mục đủ level / exp / equipment.
	var chars := {}
	for id in out["characters"]:
		var c: Variant = out["characters"][id]
		var base := default_character()
		if c is Dictionary:
			base["level"] = maxi(_int(c.get("level"), 1), 1)
			base["exp"] = maxi(_int(c.get("exp"), 0), 0)
			if c.get("equipment") is Dictionary:
				base["equipment"] = c["equipment"]
		chars[str(id)] = base
	out["characters"] = chars
	# Đội: chỉ gồm nhân vật đang sở hữu, không trùng, tối đa 3; rỗng thì lấy theo thứ tự sở hữu.
	var party: Array = []
	if out["party"] is Array:
		for id in out["party"]:
			if chars.has(str(id)) and not party.has(str(id)) and party.size() < 3:
				party.append(str(id))
	if party.is_empty():
		for id in chars:
			if party.size() < 3:
				party.append(id)
	out["party"] = party
	for k in out["currencies"]:
		out["currencies"][k] = maxi(_int(out["currencies"][k], 0), 0)
	var hist: Array = out["gacha"]["history"] if out["gacha"]["history"] is Array else []
	if hist.size() > HISTORY_LIMIT:
		hist = hist.slice(hist.size() - HISTORY_LIMIT)
	out["gacha"]["history"] = hist
	out["inventory"]["next_uid"] = maxi(_int(out["inventory"]["next_uid"], 1), 1)
	return out


## Trộn `src` vào bản mặc định `def`: khóa cố định lấy theo kiểu của mặc định; đường dẫn trong `dynamic` nhận nguyên từ điển.
static func _merge_fixed(def: Dictionary, src: Dictionary, dynamic: Array, path: String) -> Dictionary:
	var out := {}
	for k in def:
		var p: String = k if path == "" else path + "." + k
		var dv: Variant = def[k]
		var sv: Variant = src.get(k)
		if dv is Dictionary:
			if p in dynamic:
				out[k] = sv if sv is Dictionary else dv
			else:
				out[k] = _merge_fixed(dv, sv if sv is Dictionary else {}, dynamic, p)
		elif dv is Array:
			out[k] = sv if sv is Array else dv
		elif dv is bool:
			out[k] = sv if sv is bool else dv
		elif dv is String:
			out[k] = sv if sv is String else dv
		elif dv is float:
			out[k] = float(sv) if (sv is float or sv is int) else dv
		elif dv is int:
			out[k] = _int(sv, dv)
		else:
			out[k] = dv
	return out


static func _int(v: Variant, fallback: int) -> int:
	return int(v) if (v is int or v is float) else fallback
