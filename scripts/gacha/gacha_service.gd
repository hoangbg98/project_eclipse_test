class_name GachaService
extends RefCounted
## Chiêu mộ ngoại tuyến (README "Gacha and recruitment"; ARCHITECTURE mục 9). Không biết UI.
## Luồng: yêu cầu → kiểm tra tiền → luật banner → quay (tỉ lệ / pity / bảo hiểm) → trao thưởng → lịch sử.
## Người gọi lưu file sau đó (`SaveService.save_game()`).
##
## - Tỉ lệ cố định theo BannerDef, không đổi ngẫu nhiên lúc chạy; bảng hiển thị (`rates_table`) sinh từ cùng config.
## - Ngẫu nhiên qua RandomSource có seed → test tái lập được.
## - Pity của một bậc = số lượt kể từ lần ra đúng bậc đó gần nhất (theo nhóm pity của banner).

const REASON_OK := ""
const REASON_INVALID := "invalid_banner"
const REASON_NOT_ENOUGH := "not_enough_currency"
const REASON_BAD_COUNT := "bad_count"
const REASON_STARTER_USED := "starter_used"
const REASON_NO_TICKET := "no_ticket"

var profile: PlayerProfile
var rng: RandomSource


func _init(player_profile: PlayerProfile, random: RandomSource = null) -> void:
	profile = player_profile
	rng = random if random else RandomSource.new(int(Time.get_unix_time_from_system()))


# ---------- Giá ----------

## Giá cho `count` lượt: 1 = giá đơn, `multi_count` = giá gói; số khác không hợp lệ (-1).
static func cost_of(banner: BannerDef, count: int) -> int:
	if count == 1:
		return banner.cost_single
	if count == banner.multi_count:
		return banner.cost_multi
	return -1


func check(banner: BannerDef, count: int) -> String:
	if banner == null or not banner.validate().is_empty():
		return REASON_INVALID
	var cost := cost_of(banner, count)
	if cost < 0:
		return REASON_BAD_COUNT
	if not profile.inventory.can_spend(banner.cost_currency, cost):
		return REASON_NOT_ENOUGH
	return REASON_OK


# ---------- Quay ----------

## Quay `count` lượt. Trả về {"reason": "", "results": [ {item, rarity, featured, duplicate, pity} ]}.
## Thất bại (reason khác rỗng): không trừ tiền, không đổi pity, không ghi lịch sử.
func pull(banner: BannerDef, count: int) -> Dictionary:
	var reason := check(banner, count)
	if reason != REASON_OK:
		return {"reason": reason, "results": []}
	profile.inventory.spend_currency(banner.cost_currency, cost_of(banner, count))
	var results: Array = []
	var satisfied := false
	var guarantee := count == banner.multi_count and count > 1 and not banner.multi_guarantee_tiers.is_empty()
	for i in count:
		var force := ""
		if guarantee and i == count - 1 and not satisfied:
			force = banner.multi_guarantee_pick[0]
		var r := _pull_one(banner, force)
		if r["tier"] in banner.multi_guarantee_tiers:
			satisfied = true
		results.append(r)
	return {"reason": REASON_OK, "results": results}


## Lượt x10 miễn phí đầu tiên (banner `starter_free_multi`): miễn phí, dùng một lần cho mỗi banner, đúng 1 lượt
## ra bậc đầu (vị trí ngẫu nhiên trong gói), các lượt khác ra bậc cuối. Pity nằm trong nhóm riêng của banner.
func pull_starter(banner: BannerDef) -> Dictionary:
	if banner == null or not banner.starter_free_multi or not banner.validate().is_empty() or banner.tiers.size() < 2:
		return {"reason": REASON_INVALID, "results": []}
	if not starter_available(banner):
		var used: bool = banner.id in profile.data["gacha"]["starter_used"]
		return {"reason": REASON_STARTER_USED if used else REASON_NO_TICKET, "results": []}
	if banner.ticket_item != "":
		profile.inventory.consume_material(banner.ticket_item, 1)
	var used: Array = profile.data["gacha"]["starter_used"]
	used.append(banner.id)
	var first := banner.tiers[0].key()
	var rest := banner.tiers[banner.tiers.size() - 1].key()
	var at := rng.randi_range(0, banner.multi_count - 1)
	var results: Array = []
	for i in banner.multi_count:
		var r := _pull_one(banner, first if i == at else rest)
		results.append(r)
		# Nhân vật mới vào đội nếu còn chỗ — trừ lúc hướng dẫn người mới: NEO chỉ người chơi tự xếp đội (owner 2026-11-15).
		if str(r["item"]).begins_with("char:") and not r["duplicate"]:
			profile.auto_join_party(str(r["item"]).get_slice(":", 1))
	return {"reason": REASON_OK, "results": results}


## Còn dùng được lượt miễn phí: banner có cờ starter, chưa dùng, và có vé nếu banner cần vé.
func starter_available(banner: BannerDef) -> bool:
	if banner == null or not banner.starter_free_multi or banner.id in profile.data["gacha"]["starter_used"]:
		return false
	return banner.ticket_item == "" or profile.inventory.material_count(banner.ticket_item) > 0


## Một lượt. `force_tier`: khóa bậc bắt buộc (bảo đảm khi quay gói) — vẫn tăng / reset pity như lượt thường.
func _pull_one(banner: BannerDef, force_tier := "") -> Dictionary:
	var group := banner.group()
	var pity := _pity_table(group)
	# Mỗi lượt: mọi bộ đếm +1 (đây là lượt thứ n kể từ lần ra bậc đó).
	for t in banner.tiers:
		pity[t.key()] = int(pity.get(t.key(), 0)) + 1
	var tier: GachaTierDef = banner.tier(force_tier) if force_tier != "" else null
	if tier == null:
		tier = _roll_tier(banner, pity)
	var pity_at := int(pity[tier.key()])
	pity[tier.key()] = 0
	var picked := _pick_reward(tier, group)
	var item: String = picked["item"]
	var dup := _grant(item, tier)
	var entry := {"banner": banner.id, "item": item, "rarity": tier.rarity, "tier": tier.key(),
			"featured": picked["featured"], "duplicate": dup, "pity": pity_at, "forced": force_tier != "",
			"time": Time.get_datetime_string_from_system(true)}
	var hist: Array = profile.data["gacha"]["history"]
	hist.append(entry)
	while hist.size() > SaveSchema.HISTORY_LIMIT:
		hist.pop_front()
	return entry


## Phần thưởng còn được ra của bậc: bậc `exclude_owned_until_complete` bỏ món đã có cho tới khi có đủ cả pool.
func eligible_pool(t: GachaTierDef) -> PackedStringArray:
	if not t.exclude_owned_until_complete:
		return t.pool
	var out := PackedStringArray()
	for p in t.pool:
		if not (p.begins_with("equip:") and profile.inventory.owns_def(p.get_slice(":", 1))):
			out.append(p)
	return out if not out.is_empty() else t.pool


## Tỉ lệ gốc của bậc lúc này: `rate_per_item` → tỉ lệ mỗi món × số món còn được ra.
func base_rate_of(t: GachaTierDef) -> float:
	return t.base_rate * eligible_pool(t).size() if t.rate_per_item else t.base_rate


## Tỉ lệ thực của một bậc ở lượt hiện tại (đã tính pity mềm / cứng); bậc cuối không dùng hàm này.
## `base` ≥ 0: tỉ lệ gốc thay cho t.base_rate (bậc tính theo món, base_rate_of).
static func tier_rate(t: GachaTierDef, pulls_since: int, base := -1.0) -> float:
	if t.hard_pity > 0 and pulls_since >= t.hard_pity:
		return 1.0
	var r := t.base_rate if base < 0.0 else base
	if t.soft_pity_start > 0 and pulls_since >= t.soft_pity_start:
		if t.soft_pity_mode == "flat":
			r += t.soft_pity_step
		else:
			r += t.soft_pity_step * float(pulls_since - t.soft_pity_start + 1)
	return clampf(r, 0.0, 1.0)


func _roll_tier(banner: BannerDef, pity: Dictionary) -> GachaTierDef:
	var last := banner.tiers.size() - 1
	# Pity cứng: bậc hiếm nhất đang chạm ngưỡng được ưu tiên.
	for i in last:
		var t := banner.tiers[i]
		if t.hard_pity > 0 and int(pity[t.key()]) >= t.hard_pity:
			return t
	var roll := rng.randf()
	var acc := 0.0
	for i in last:
		var t := banner.tiers[i]
		acc += tier_rate(t, int(pity[t.key()]), base_rate_of(t))
		if roll < acc:
			return t
	return banner.tiers[last]


func _pick_reward(tier: GachaTierDef, group: String) -> Dictionary:
	if tier.exclude_owned_until_complete:
		var pool := eligible_pool(tier)
		var item := pool[rng.randi_range(0, pool.size() - 1)]
		return {"item": item, "featured": item in tier.featured}
	if tier.featured.is_empty():
		return {"item": tier.pool[rng.randi_range(0, tier.pool.size() - 1)], "featured": false}
	var g := _guarantee_table(group)
	var key := tier.key()
	var others := PackedStringArray()
	for p in tier.pool:
		if p not in tier.featured:
			others.append(p)
	var want_featured := bool(g.get(key, false)) or others.is_empty() or rng.randf() < tier.featured_rate
	if want_featured:
		g[key] = false
		return {"item": tier.featured[rng.randi_range(0, tier.featured.size() - 1)], "featured": true}
	if tier.guarantee_after_miss:
		g[key] = true
	return {"item": others[rng.randi_range(0, others.size() - 1)], "featured": false}


## Trao thưởng; trả về true nếu là nhân vật trùng (đã sở hữu).
func _grant(item: String, tier: GachaTierDef) -> bool:
	var kind := item.get_slice(":", 0)
	var id := item.get_slice(":", 1)
	match kind:
		"char":
			if profile.progression.unlock(id):
				return false
			if tier.duplicate_fragments > 0:
				profile.progression.add_fragments(id, tier.duplicate_fragments)
			if tier.duplicate_item != "" and tier.duplicate_count > 0:
				profile.inventory.add_material(tier.duplicate_item, tier.duplicate_count)
			return true
		"gold":
			profile.inventory.add_currency("gold", int(id))
		"equip":
			profile.inventory.add_equipment(id)
		"item":
			profile.inventory.add_material(id, 1)
	return false


# ---------- Pity / bảo hiểm trong save ----------

func _pity_table(group: String) -> Dictionary:
	var all: Dictionary = profile.data["gacha"]["pity"]
	if not (all.get(group) is Dictionary):
		all[group] = {}
	return all[group]


func _guarantee_table(group: String) -> Dictionary:
	var all: Dictionary = profile.data["gacha"]["guarantee"]
	if not (all.get(group) is Dictionary):
		all[group] = {}
	return all[group]


## Số lượt kể từ lần ra bậc `rarity` gần nhất (để UI hiện "còn N lượt nữa chắc chắn ra").
## Số lượt kể từ lần ra bậc `tier_key` gần nhất (khóa bậc, hoặc số sao khi bậc không đặt tier_id).
func pity_count(banner: BannerDef, tier_key: Variant) -> int:
	return int(_pity_table(banner.group()).get(str(tier_key), 0))


func is_guaranteed(banner: BannerDef, tier_key: Variant) -> bool:
	return bool(_guarantee_table(banner.group()).get(str(tier_key), false))


func history() -> Array:
	return profile.data["gacha"]["history"]


# ---------- Bảng tỉ lệ hiển thị (sinh từ cùng config) ----------

## [{rarity, rate, hard_pity, soft_pity_start, soft_pity_step, guarantee_after_miss, items: [{item, rate, featured}]}]
## `rate` là tỉ lệ gốc mỗi lượt (chưa tính pity); tổng mọi bậc = 1; tổng items của một bậc = rate của bậc.
static func rates_table(banner: BannerDef) -> Array:
	var out: Array = []
	var upper := 0.0
	var last := banner.tiers.size() - 1
	for i in banner.tiers.size():
		var t := banner.tiers[i]
		# Bậc tính theo món: hiện mức khi còn thiếu cả pool (tỉ lệ thật giảm dần theo món đã có, base_rate_of).
		var base := t.base_rate * (t.pool.size() if t.rate_per_item else 1)
		var rate := base if i < last else maxf(1.0 - upper, 0.0)
		if i < last:
			upper += base
		var items: Array = []
		var n_feat := t.featured.size()
		var n_other := t.pool.size() - n_feat
		for p in t.pool:
			var is_f := p in t.featured
			var share := 1.0 / t.pool.size()
			if n_feat > 0:
				var f_rate := 1.0 if n_other == 0 else t.featured_rate
				share = f_rate / n_feat if is_f else (1.0 - f_rate) / n_other
			items.append({"item": p, "rate": rate * share, "featured": is_f})
		out.append({"rarity": t.rarity, "tier": t.key(), "label_key": t.label_key, "soft_pity_mode": t.soft_pity_mode,
				"rate": rate, "hard_pity": t.hard_pity, "soft_pity_start": t.soft_pity_start,
				"soft_pity_step": t.soft_pity_step, "guarantee_after_miss": t.guarantee_after_miss, "items": items})
	return out
