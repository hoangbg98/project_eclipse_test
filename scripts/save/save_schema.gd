class_name SaveSchema
extends RefCounted
## Cấu trúc dữ liệu người chơi (ARCHITECTURE mục 8). Chỉ lưu dữ liệu của người chơi (ID sở hữu, cấp,
## trang bị, tiền tệ, pity, lịch sử chiêu mộ, tiến độ màn, cài đặt), không lưu định nghĩa tĩnh.
##
## Khi đổi cấu trúc: tăng VERSION, thêm một hàm vào MIGRATIONS (v cũ → v cũ + 1) và sửa `default_data()`.

const VERSION := 6

## Độ dài tối đa của tên người chơi (ký tự).
const NAME_MAX := 16

## Nhân vật có sẵn khi bắt đầu game mới (owner 2026-11-14: chỉ Enkiba; Kazeyumi nhận khi qua ải 1-1,
## Raikiba từ lượt x10 miễn phí đầu tiên — vé nhận khi qua ải 1-1).
const STARTER_CHARACTERS: Array[String] = ["char_fire_01"]
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
			"equipment": {},                 # uid -> {def_id, level, tier?, affixes?, affix_pending?} (tier: bậc, thiếu = 0)
			"materials": {},                 # id -> số lượng
		},
		"currencies": {"gold": 0, "gems": 0},
		"account": {"level": 1, "exp": 0, "name": ""},   # cấp đội trưởng (giới hạn cấp nhân vật), tên người chơi
		"cosmetics": {"backgrounds": [], "hub_background": ""},   # nền sảnh đã có (ngoài nền starter), nền đang dùng
		"gacha": {"pity": {}, "guarantee": {}, "history": [], "starter_used": []},   # starter_used: id banner x10 miễn phí đã dùng
		"progress": {"stages": {}, "parts_claimed": []},   # stage_id -> {cleared, best_time_sec}; id phần đã nhận quà
		"rhythm": {"records": {}, "favorites": []},   # ải nhịp điệu (RhythmProgress): khóa -> kỷ lục; id bài yêu thích
		"tutorial": {"done": false, "seen": []},   # hướng dẫn người mới (TutorialFlow); seen: id bước đã nghe NEO nói
		"settings": {"language": "vi", "master_volume": 1.0, "music_volume": 1.0, "sfx_volume": 1.0, "fullscreen": false},
		"stats": {"play_time_sec": 0.0},
	}


## Tên người chơi đã làm sạch: bỏ khoảng trắng hai đầu, gộp khoảng trắng, bỏ ký tự điều khiển, cắt NAME_MAX ký tự.
static func clean_name(s: String) -> String:
	var out := ""
	for ch in s.strip_edges():
		if ch.unicode_at(0) >= 32:
			out += ch
	while out.contains("  "):
		out = out.replace("  ", " ")
	return out.substr(0, NAME_MAX)


static func default_character() -> Dictionary:
	return {"level": 1, "exp": 0, "equipment": {}, "skills": {}, "fragments": 0, "promotion": 0}


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


## v2 → v3 (2026-11-12): trang bị đổi từ vũ khí / giáp / phụ kiện sang 1 vũ khí + 3 vết thánh.
## Món cũ được đổi sang món tương ứng (giữ cấp cường hóa); món đang mặc chuyển sang ô mới. Thêm `skills`, `fragments`,
## `promotion` cho nhân vật và `account` (cấp đội trưởng = cấp cao nhất của nhân vật hiện có, để không bị khóa cấp).
const V3_DEF_RENAME := {
	"eq_acc_ring": "eq_stigma_top_elite", "eq_armor_leather": "eq_stigma_mid_hide",
	"eq_armor_guardian": "eq_stigma_mid_guardian", "eq_acc_hourglass": "eq_stigma_bot_hourglass",
}
const V3_SLOT_OF := {
	"eq_stigma_top_elite": "stigma_top", "eq_stigma_mid_hide": "stigma_mid",
	"eq_stigma_mid_guardian": "stigma_mid", "eq_stigma_bot_hourglass": "stigma_bot",
}


static func _migrate_2_to_3(d: Dictionary) -> Dictionary:
	var owned: Dictionary = {}
	if d.get("inventory") is Dictionary and d["inventory"].get("equipment") is Dictionary:
		owned = d["inventory"]["equipment"]
	for uid in owned:
		var e: Variant = owned[uid]
		if e is Dictionary and V3_DEF_RENAME.has(str(e.get("def_id", ""))):
			e["def_id"] = V3_DEF_RENAME[str(e["def_id"])]
	if d.get("characters") is Dictionary:
		for cid in d["characters"]:
			var c: Variant = d["characters"][cid]
			if not (c is Dictionary):
				continue
			var old: Dictionary = c["equipment"] if c.get("equipment") is Dictionary else {}
			var now := {}
			for slot in old:
				var uid := str(old[slot])
				if slot == "weapon":
					now["weapon"] = uid
				elif owned.get(uid) is Dictionary and V3_SLOT_OF.has(str(owned[uid].get("def_id", ""))):
					now[V3_SLOT_OF[str(owned[uid]["def_id"])]] = uid
			c["equipment"] = now
			if not (c.get("skills") is Dictionary):
				c["skills"] = {}
	if not (d.get("account") is Dictionary):
		var top := 1
		if d.get("characters") is Dictionary:
			for cid in d["characters"]:
				var c: Variant = d["characters"][cid]
				if c is Dictionary:
					top = maxi(top, _int(c.get("level"), 1))
		d["account"] = {"level": top, "exp": 0}
	return d


## Chỉ số i = migration từ version i + 1 lên i + 2.
static func migrations() -> Array[Callable]:
	return [_migrate_1_to_2, _migrate_2_to_3, _migrate_3_to_4, _migrate_4_to_5, _migrate_5_to_6]


## v5 → v6 (2026-11-14): hướng dẫn người mới. Save cũ đã chơi trước khi có hướng dẫn → coi như đã xong
## (không khóa màn của người chơi cũ; họ vẫn giữ đội 3 người cũ).
static func _migrate_5_to_6(d: Dictionary) -> Dictionary:
	if not (d.get("tutorial") is Dictionary):
		d["tutorial"] = {"done": true}
	return d


## v4 → v5 (2026-11-14): nền sảnh chính (`cosmetics`): danh sách nền đã có + nền đang dùng (rỗng = nền starter đầu tiên).
static func _migrate_4_to_5(d: Dictionary) -> Dictionary:
	if not (d.get("cosmetics") is Dictionary):
		d["cosmetics"] = {"backgrounds": [], "hub_background": ""}
	return d


## v3 → v4 (2026-11-14): tên người chơi (`account.name`, rỗng = dùng tên mặc định PLAYER_DEFAULT_NAME).
static func _migrate_3_to_4(d: Dictionary) -> Dictionary:
	if d.get("account") is Dictionary and not (d["account"].get("name") is String):
		d["account"]["name"] = ""
	return d


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
			"gacha.guarantee", "progress.stages", "rhythm.records"], "")
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
			if c.get("skills") is Dictionary:
				for k in c["skills"]:
					base["skills"][str(k)] = maxi(_int(c["skills"][k], 1), 1)
			base["fragments"] = maxi(_int(c.get("fragments"), 0), 0)
			base["promotion"] = maxi(_int(c.get("promotion"), 0), 0)
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
	out["account"]["level"] = maxi(_int(out["account"]["level"], 1), 1)
	out["account"]["exp"] = maxi(_int(out["account"]["exp"], 0), 0)
	out["account"]["name"] = clean_name(str(out["account"]["name"]))
	var bgs := PackedStringArray()
	for b in out["cosmetics"]["backgrounds"]:
		if b is String and not bgs.has(b):
			bgs.append(b)
	out["cosmetics"]["backgrounds"] = Array(bgs)
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
