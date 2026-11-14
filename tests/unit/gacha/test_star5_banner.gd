extends GdUnitTestSuite
## Banner 5★ vũ khí + vết thánh (owner 2026-11-14, EQUIPMENT_5STAR mục 5.6): mỗi món 1.5%, món đã có không ra lại
## tới khi đủ bộ, pity cứng 50 (chỉ ra món chưa có), pity mềm từ lượt 30 +10% một lần, pity riêng mỗi kỳ,
## bậc 4★ / 3★ như tiếp tế, phần 5★ lấy từ nguyên liệu, giá 280 / 2520.

const PATH := "res://data/banners/banner_star5_earth.tres"
const SET_ITEMS := ["equip:eq_weapon_unyielding_peak", "equip:eq_stigma_top_darwin", "equip:eq_stigma_mid_darwin",
		"equip:eq_stigma_bot_darwin"]

var _data: Dictionary
var _profile: PlayerProfile


func before_test() -> void:
	_data = SaveSchema.default_data()
	_profile = PlayerProfile.new(_data)
	_profile.inventory.add_currency("gems", 100_000_000)


func _banner() -> BannerDef:
	return load(PATH)


func _svc(seed_value := 7) -> GachaService:
	return GachaService.new(_profile, RandomSource.new(seed_value))


func _owned_count() -> int:
	var n := 0
	for item in SET_ITEMS:
		if _profile.inventory.owns_def(str(item).get_slice(":", 1)):
			n += 1
	return n


func test_config_matches_owner() -> void:
	var b := _banner()
	assert_array(b.validate()).is_empty()
	assert_array([b.cost_single, b.cost_multi, b.multi_count]).is_equal([280, 2520, 10])
	var t := b.tier("X5")
	assert_float(t.base_rate).is_equal(0.0015)                          # owner 2026-11-15: 1.5% → 0.15% mỗi món
	assert_bool(t.rate_per_item).is_true()
	assert_bool(t.exclude_owned_until_complete).is_true()
	assert_array(Array(t.pool)).is_equal(SET_ITEMS)
	assert_array([t.hard_pity, t.soft_pity_start]).is_equal([50, 30])
	assert_float(t.soft_pity_step).is_equal(0.1)
	assert_str(t.soft_pity_mode).is_equal("flat")
	assert_float(b.tier("W4").base_rate).is_equal(0.0287)                   # giữ như tiếp tế
	assert_float(b.tier("S3").base_rate).is_equal(0.1443)
	assert_str(b.group()).is_not_equal("equip")                             # pity riêng kỳ này
	var table := GachaService.rates_table(b)
	assert_float(table[0]["rate"]).is_equal_approx(0.006, 0.0000001)         # thiếu 4 món
	assert_float(table[table.size() - 1]["rate"]).is_equal_approx(0.574, 0.0000001)  # 58% − 0.6%
	assert_str(tr(b.name_key)).is_not_equal(b.name_key)
	assert_str(tr(t.label_key)).is_not_equal(t.label_key)


func test_rate_drops_with_owned_items_then_returns_when_complete() -> void:
	var svc := _svc()
	var t := _banner().tier("X5")
	var expect := [0.006, 0.0045, 0.003, 0.0015]
	for i in SET_ITEMS.size():
		assert_float(svc.base_rate_of(t)).is_equal_approx(expect[i], 0.0000001)
		_profile.inventory.add_equipment(str(SET_ITEMS[i]).get_slice(":", 1))
	assert_float(svc.base_rate_of(t)).is_equal_approx(0.006, 0.0000001)    # đủ bộ: 0.6%, có thể trùng
	assert_int(svc.eligible_pool(t).size()).is_equal(4)


func test_soft_pity_flat_once() -> void:
	var t := _banner().tier("X5")
	assert_float(GachaService.tier_rate(t, 29, 0.06)).is_equal_approx(0.06, 0.0000001)
	assert_float(GachaService.tier_rate(t, 30, 0.06)).is_equal_approx(0.16, 0.0000001)
	assert_float(GachaService.tier_rate(t, 45, 0.015)).is_equal_approx(0.115, 0.0000001)
	assert_float(GachaService.tier_rate(t, 50, 0.015)).is_equal(1.0)


func test_never_duplicate_before_complete_and_hard_pity_50() -> void:
	var svc := _svc(11)
	var b := _banner()
	var got := {}
	var since := 0
	var max_gap := 0
	for i in 2000:
		if got.size() == SET_ITEMS.size():
			break
		var r: Dictionary = svc.pull(b, 1)["results"][0]
		since += 1
		if r["tier"] == "X5":
			assert_bool(got.has(r["item"])).is_false()                     # món đã có không ra lại
			got[r["item"]] = true
			max_gap = maxi(max_gap, since)
			since = 0
	assert_int(got.size()).is_equal(4)
	assert_int(max_gap).is_less_equal(50)
	assert_int(_owned_count()).is_equal(4)


func test_hard_pity_gives_missing_item() -> void:
	var svc := _svc(3)
	var b := _banner()
	for item in SET_ITEMS.slice(0, 3):
		_profile.inventory.add_equipment(str(item).get_slice(":", 1))
	_data["gacha"]["pity"][b.group()] = {"X5": 49}
	var r: Dictionary = svc.pull(b, 1)["results"][0]
	assert_str(r["tier"]).is_equal("X5")
	assert_str(r["item"]).is_equal("equip:eq_stigma_bot_darwin")             # món duy nhất còn thiếu
	assert_int(svc.pity_count(b, "X5")).is_equal(0)


func test_pity_separate_from_supply_banner() -> void:
	var svc := _svc(5)
	svc.pull(_banner(), 10)
	var supply: BannerDef = load("res://data/banners/banner_equip_terra.tres")
	assert_int(svc.pity_count(supply, "W4")).is_equal(0)
	assert_int(svc.pity_count(_banner(), "W4")).is_greater(0)


func test_rates_over_many_pulls() -> void:
	# Thống kê thô (seed cố định): khi đã đủ bộ, tỉ lệ ra 5★ quanh 6% (cộng thêm pity mềm / cứng).
	for item in SET_ITEMS:
		_profile.inventory.add_equipment(str(item).get_slice(":", 1))
	var svc := _svc(21)
	var b := _banner()
	var n := 0
	for i in 400:
		for r in svc.pull(b, 10)["results"]:
			if r["tier"] == "X5":
				n += 1
	var rate := float(n) / 4000.0
	assert_float(rate).is_between(0.015, 0.045)                       # gốc 0.6%, chủ yếu ra nhờ pity mềm 30 / cứng 50
