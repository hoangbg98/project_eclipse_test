extends GdUnitTestSuite
## Test M5-4 (phần logic): banner, tỉ lệ, pity mềm / cứng, rate-up, bảo hiểm, lịch sử, tiền, seed.
## Banner ở đây CHỈ dùng cho test (số tự đặt để kiểm thuật toán); dự án chưa ship banner nào vì tỉ lệ thật chờ owner.

var _data: Dictionary
var _profile: PlayerProfile


func before_test() -> void:
	_data = SaveSchema.default_data()
	_profile = PlayerProfile.new(_data)
	_profile.inventory.add_currency("gems", 10_000_000)


func _tier(rarity: int, rate: float, pool: Array, extra := {}) -> GachaTierDef:
	var t := GachaTierDef.new()
	t.rarity = rarity
	t.base_rate = rate
	t.pool = PackedStringArray(pool)
	for k in extra:
		t.set(k, extra[k])
	return t


## Banner test: 5★ 2% (pity cứng 50, mềm từ 40 +10%/lượt, rate-up 50% có bảo hiểm), 4★ 10% (pity cứng 10), 3★ phần còn lại.
func _banner() -> BannerDef:
	var b := BannerDef.new()
	b.id = "test_banner"
	b.name_key = "TEST_BANNER"
	b.cost_currency = "gems"
	b.cost_single = 100
	b.multi_count = 10
	b.cost_multi = 900
	b.tiers = [
		_tier(5, 0.02, ["char:char_dark_01", "char:char_light_01", "char:char_earth_01"], {
			"hard_pity": 50, "soft_pity_start": 40, "soft_pity_step": 0.10,
			"featured": PackedStringArray(["char:char_dark_01"]), "featured_rate": 0.5, "guarantee_after_miss": true,
			"duplicate_item": "mat_enhance_crystal", "duplicate_count": 5}),
		_tier(4, 0.10, ["equip:eq_weapon_flame", "equip:eq_stigma_mid_guardian"], {"hard_pity": 10}),
		_tier(3, 0.0, ["item:mat_exp_small", "item:mat_enhance_ore"]),
	]
	return b


func _svc(seed_value := 12345) -> GachaService:
	return GachaService.new(_profile, RandomSource.new(seed_value))


# ---------- Config ----------

func test_banner_validation() -> void:
	assert_array(_banner().validate()).is_empty()
	var b := _banner()
	b.tiers[0].base_rate = 0.95
	assert_bool(b.validate().size() > 0).is_true()                    # tổng > 100%
	b = _banner()
	b.tiers[0].featured = PackedStringArray(["char:not_in_pool"])
	assert_bool(b.validate().size() > 0).is_true()
	b = _banner()
	b.tiers[2].pool = PackedStringArray()
	assert_bool(b.validate().size() > 0).is_true()
	b = _banner()
	b.tiers = [b.tiers[1], b.tiers[0], b.tiers[2]]                    # sai thứ tự
	assert_bool(b.validate().size() > 0).is_true()
	b = _banner()
	b.tiers[1].pool = PackedStringArray(["weapon_without_kind"])
	assert_bool(b.validate().size() > 0).is_true()


func test_shipped_banners_are_valid() -> void:
	var files := ResourceLoader.list_directory("res://data/banners")
	assert_array(Array(files)).is_equal(["banner_char_aether.tres", "banner_equip_aether.tres"])
	for f in files:
		var b: BannerDef = load("res://data/banners/" + f)
		assert_array(b.validate()).is_empty()
		assert_bool(b.starter_free_multi).is_false()


func test_rates_table_sums_to_one_and_matches_config() -> void:
	var table := GachaService.rates_table(_banner())
	var total := 0.0
	for row in table:
		total += row["rate"]
		var items := 0.0
		for it in row["items"]:
			items += it["rate"]
		assert_float(items).is_equal_approx(row["rate"], 0.000001)
	assert_float(total).is_equal_approx(1.0, 0.000001)
	assert_float(table[0]["rate"]).is_equal(0.02)
	assert_float(table[2]["rate"]).is_equal_approx(0.88, 0.000001)    # bậc thấp nhất = phần còn lại
	assert_int(table[0]["hard_pity"]).is_equal(50)
	# 5★ rate-up chiếm 50% của 2%; hai nhân vật còn lại chia 50% kia.
	for it in table[0]["items"]:
		assert_float(it["rate"]).is_equal_approx(0.01 if it["featured"] else 0.005, 0.000001)


# ---------- Tiền ----------

func test_cost_single_and_multi() -> void:
	var s := _svc()
	var before := _profile.inventory.currency("gems")
	assert_int(s.pull(_banner(), 1)["results"].size()).is_equal(1)
	assert_int(_profile.inventory.currency("gems")).is_equal(before - 100)
	assert_int(s.pull(_banner(), 10)["results"].size()).is_equal(10)
	assert_int(_profile.inventory.currency("gems")).is_equal(before - 1000)


func test_rejected_pull_changes_nothing() -> void:
	var s := _svc()
	_data["currencies"]["gems"] = 899
	var r := s.pull(_banner(), 10)
	assert_str(r["reason"]).is_equal(GachaService.REASON_NOT_ENOUGH)
	assert_array(r["results"]).is_empty()
	assert_int(_profile.inventory.currency("gems")).is_equal(899)
	assert_array(s.history()).is_empty()
	assert_int(s.pity_count(_banner(), 5)).is_equal(0)
	assert_str(s.pull(_banner(), 3)["reason"]).is_equal(GachaService.REASON_BAD_COUNT)
	var bad := _banner()
	bad.tiers[2].pool = PackedStringArray()
	assert_str(s.pull(bad, 1)["reason"]).is_equal(GachaService.REASON_INVALID)
	assert_str(s.pull(null, 1)["reason"]).is_equal(GachaService.REASON_INVALID)


# ---------- Xác suất ----------

func test_same_seed_same_results() -> void:
	var a: Array = _svc(777).pull(_banner(), 10)["results"]
	_data = SaveSchema.default_data()
	_profile = PlayerProfile.new(_data)
	_profile.inventory.add_currency("gems", 10_000_000)
	var b: Array = _svc(777).pull(_banner(), 10)["results"]
	for i in 10:
		assert_str(a[i]["item"]).is_equal(b[i]["item"])
		assert_int(a[i]["rarity"]).is_equal(b[i]["rarity"])


func test_base_rates_without_pity_match_config() -> void:
	var b := _banner()
	for t in b.tiers:                                                 # tắt pity để đo tỉ lệ gốc
		t.hard_pity = 0
		t.soft_pity_start = 0
	var s := _svc(2024)
	var n := 30000
	var count := {5: 0, 4: 0, 3: 0}
	_data["currencies"]["gems"] = 100 * n
	for i in n:
		count[s.pull(b, 1)["results"][0]["rarity"]] += 1
	assert_float(float(count[5]) / n).is_equal_approx(0.02, 0.004)
	assert_float(float(count[4]) / n).is_equal_approx(0.10, 0.008)
	assert_float(float(count[3]) / n).is_equal_approx(0.88, 0.008)


func test_hard_pity_guarantees_within_limit() -> void:
	var s := _svc(99)
	var gap5 := 0
	var gap4 := 0
	var max5 := 0
	var max4 := 0
	for i in 3000:
		var r: Dictionary = s.pull(_banner(), 1)["results"][0]
		gap5 += 1
		gap4 += 1
		if r["rarity"] == 5:
			max5 = maxi(max5, gap5)
			gap5 = 0
		if r["rarity"] == 4:
			max4 = maxi(max4, gap4)
			gap4 = 0
	assert_int(max5).is_less_equal(50)
	assert_int(max4).is_less_equal(10)
	assert_int(maxi(gap5, 0)).is_less(50)


func test_hard_pity_exact_pull() -> void:
	var b := _banner()
	b.tiers[0].base_rate = 0.0                                        # chỉ ra nhờ pity
	b.tiers[0].soft_pity_start = 0
	var s := _svc()
	for i in 49:
		assert_int(s.pull(b, 1)["results"][0]["rarity"]).is_less(5)
	assert_int(s.pity_count(b, 5)).is_equal(49)
	var r: Dictionary = s.pull(b, 1)["results"][0]
	assert_int(r["rarity"]).is_equal(5)                               # đúng lượt 50
	assert_int(r["pity"]).is_equal(50)
	assert_int(s.pity_count(b, 5)).is_equal(0)                        # về 0


func test_soft_pity_raises_rate() -> void:
	var t := _banner().tiers[0]
	assert_float(GachaService.tier_rate(t, 39)).is_equal(0.02)
	assert_float(GachaService.tier_rate(t, 40)).is_equal_approx(0.12, 0.000001)
	assert_float(GachaService.tier_rate(t, 45)).is_equal_approx(0.62, 0.000001)
	assert_float(GachaService.tier_rate(t, 49)).is_equal(1.0)         # 0.02 + 1.0, chặn 1
	assert_float(GachaService.tier_rate(t, 50)).is_equal(1.0)         # pity cứng


func test_featured_rate_and_guarantee_after_miss() -> void:
	var b := _banner()
	b.tiers[0].base_rate = 1.0                                        # lượt nào cũng 5★ để đo rate-up
	b.tiers[1].base_rate = 0.0
	b.tiers[1].hard_pity = 0                                          # không để 4★ chen vào
	var s := _svc(5)
	var feat := 0
	var prev_missed := false
	var n := 4000
	_data["currencies"]["gems"] = 100 * n
	for i in n:
		var r: Dictionary = s.pull(b, 1)["results"][0]
		if prev_missed:
			assert_bool(r["featured"]).is_true()                      # trượt lần trước → lần này chắc chắn rate-up
		prev_missed = not r["featured"]
		if r["featured"]:
			feat += 1
			assert_str(r["item"]).is_equal("char:char_dark_01")
	# 50% + bảo hiểm → về lâu dài 2/3 là rate-up.
	assert_float(float(feat) / n).is_equal_approx(2.0 / 3.0, 0.03)


func test_guarantee_flag_is_stored_and_cleared() -> void:
	var b := _banner()
	b.tiers[0].base_rate = 1.0
	b.tiers[1].base_rate = 0.0
	b.tiers[1].hard_pity = 0
	b.tiers[0].featured_rate = 0.0                                    # luôn trượt khi không có bảo hiểm
	var s := _svc()
	assert_bool(s.pull(b, 1)["results"][0]["featured"]).is_false()
	assert_bool(s.is_guaranteed(b, 5)).is_true()
	assert_bool(s.pull(b, 1)["results"][0]["featured"]).is_true()
	assert_bool(s.is_guaranteed(b, 5)).is_false()


func test_pity_group_shared_between_banners() -> void:
	var a := _banner()
	var b := _banner()
	b.id = "test_banner_2"
	a.pity_group = "limited"
	b.pity_group = "limited"
	for t in a.tiers + b.tiers:
		t.base_rate = 0.0 if t.rarity == 5 else t.base_rate
		t.soft_pity_start = 0
	var s := _svc()
	for i in 30:
		s.pull(a, 1)
	assert_int(s.pity_count(b, 5)).is_equal(30)                       # banner cùng nhóm thấy chung bộ đếm
	var c := _banner()
	c.id = "other"
	assert_int(s.pity_count(c, 5)).is_equal(0)


# ---------- Trao thưởng, lịch sử ----------

func test_rewards_are_granted() -> void:
	var b := _banner()
	b.tiers[0].base_rate = 1.0
	b.tiers[1].base_rate = 0.0
	b.tiers[1].hard_pity = 0
	b.tiers[0].pool = PackedStringArray(["char:char_dark_01"])
	b.tiers[0].featured = PackedStringArray()
	b.tiers[0].featured_rate = 0.0
	b.tiers[0].guarantee_after_miss = false
	var s := _svc()
	var first: Dictionary = s.pull(b, 1)["results"][0]
	assert_bool(first["duplicate"]).is_false()
	assert_bool(_profile.progression.owns("char_dark_01")).is_true()
	var second: Dictionary = s.pull(b, 1)["results"][0]
	assert_bool(second["duplicate"]).is_true()                        # trùng → đổi nguyên liệu
	assert_int(_profile.inventory.material_count("mat_enhance_crystal")).is_equal(5)
	b.tiers[0].base_rate = 0.0
	b.tiers[1].base_rate = 1.0
	s.pull(b, 1)
	assert_int(_profile.inventory.equipment_uids().size()).is_equal(1)
	b.tiers[1].base_rate = 0.0
	b.tiers[0].hard_pity = 0
	b.tiers[0].soft_pity_start = 0
	s.pull(b, 1)
	assert_int(_profile.inventory.material_count("mat_exp_small") + _profile.inventory.material_count("mat_enhance_ore")).is_equal(1)


func test_history_recorded_capped_and_persisted() -> void:
	var s := _svc()
	s.pull(_banner(), 10)
	var h := s.history()
	assert_int(h.size()).is_equal(10)
	for k in ["banner", "item", "rarity", "featured", "duplicate", "pity", "time"]:
		assert_bool(h[0].has(k)).is_true()
	for i in 25:
		s.pull(_banner(), 10)
	assert_int(s.history().size()).is_equal(SaveSchema.HISTORY_LIMIT)
	# Lưu rồi đọc: lịch sử, pity, bảo hiểm còn nguyên.
	var store := SaveStore.new("user://test_saves_m5_4")
	store.delete_all()
	var pity5 := s.pity_count(_banner(), 5)
	var last_item: String = s.history()[-1]["item"]
	store.write(_data)
	var p2 := PlayerProfile.new(store.read())
	var s2 := GachaService.new(p2, RandomSource.new(1))
	assert_int(s2.history().size()).is_equal(SaveSchema.HISTORY_LIMIT)
	assert_str(s2.history()[-1]["item"]).is_equal(last_item)
	assert_int(s2.pity_count(_banner(), 5)).is_equal(pity5)
	store.delete_all()
	DirAccess.remove_absolute("user://test_saves_m5_4")
