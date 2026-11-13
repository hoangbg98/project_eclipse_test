extends GdUnitTestSuite
## Test banner nhân vật theo câu trả lời của owner (2026-11-12): tỉ lệ S / A / B, pity cứng 100, pity mềm +10% từ lượt 80,
## 10 lượt chắc chắn ≥ 1 nhân vật A, pity chuyển sang banner kế tiếp, giá 280 / 2520, trùng nhân vật → mảnh.

const PATH := "res://data/banners/banner_char_terra.tres"

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


func test_config_matches_owner_answers() -> void:
	var b := _banner()
	assert_array(b.validate()).is_empty()
	assert_int(b.cost_single).is_equal(280)
	assert_int(b.cost_multi).is_equal(2520)
	assert_int(b.multi_count).is_equal(10)
	assert_str(b.cost_currency).is_equal("gems")
	var s := b.tier("S")
	assert_float(s.base_rate).is_equal(0.015)
	assert_int(s.hard_pity).is_equal(100)
	assert_array([s.soft_pity_start, s.soft_pity_step, s.soft_pity_mode]).is_equal([80, 0.1, "flat"])
	assert_int(s.pool.size()).is_equal(1)                              # chỉ 1 nhân vật S (rate-up)
	assert_float(s.featured_rate).is_equal(1.0)
	assert_float(b.tier("A").base_rate).is_equal(0.163)
	assert_float(b.tier("B").base_rate).is_equal(0.10874)
	var table := GachaService.rates_table(b)
	assert_float(table[3]["rate"]).is_equal_approx(1.0 - 0.015 - 0.163 - 0.10874, 0.0000001)   # nguyên liệu, vàng
	assert_array(Array(b.multi_guarantee_tiers)).is_equal(["S", "A"])
	assert_array(Array(b.multi_guarantee_pick)).is_equal(["A"])
	assert_str(b.group()).is_equal("char")
	# Hạng tạm của owner (2026-11-13): S = Enkiba, Iwagane; B = Raikiba, Kazeyumi.
	assert_array(Array(s.featured)).is_equal(["char:char_earth_01"])          # owner: banner đầu là Iwagane
	assert_array(Array(b.tier("B").pool)).contains(["char:char_lightning_01", "char:char_wind_01"])
	for id in ["char_fire_01", "char_earth_01"]:
		assert_str((load("res://data/characters/%s.tres" % id) as CharacterDef).rank).is_equal("S")


func test_soft_pity_is_flat_plus_ten_percent() -> void:
	var s := _banner().tier("S")
	assert_float(GachaService.tier_rate(s, 79)).is_equal(0.015)
	assert_float(GachaService.tier_rate(s, 80)).is_equal_approx(0.115, 0.000001)
	assert_float(GachaService.tier_rate(s, 99)).is_equal_approx(0.115, 0.000001)
	assert_float(GachaService.tier_rate(s, 100)).is_equal(1.0)


func test_hard_pity_100_never_exceeded() -> void:
	var s := _svc(11)
	var gap := 0
	var worst := 0
	for i in 150:
		for r: Dictionary in s.pull(_banner(), 10)["results"]:
			gap += 1
			if r["tier"] == "S":
				worst = maxi(worst, gap)
				gap = 0
	assert_int(worst).is_less_equal(100)
	assert_int(worst).is_greater(0)


func test_every_ten_pull_has_at_least_one_a_or_better() -> void:
	var s := _svc(3)
	var forced := 0
	for i in 200:
		var res: Array = s.pull(_banner(), 10)["results"]
		var ok := false
		for r: Dictionary in res:
			if r["tier"] in ["S", "A"]:
				ok = true
			if r["forced"]:
				forced += 1
		assert_bool(ok).is_true()
	assert_int(forced).is_greater(0)                                   # bảo đảm thật sự được dùng


func test_single_pulls_have_no_ten_pull_guarantee() -> void:
	var s := _svc(5)
	for i in 300:
		assert_bool(s.pull(_banner(), 1)["results"][0]["forced"]).is_false()


func test_rates_over_many_pulls() -> void:
	var s := _svc(2026)
	var n := 20000
	var count := {"S": 0, "A": 0, "B": 0, "MAT": 0}
	for i in n:
		count[s.pull(_banner(), 1)["results"][0]["tier"]] += 1
	# S cao hơn 1.5% một chút do pity (mềm + cứng); A, B, nguyên liệu theo config.
	assert_float(float(count["S"]) / n).is_between(0.015, 0.03)
	assert_float(float(count["A"]) / n).is_equal_approx(0.163, 0.012)
	assert_float(float(count["B"]) / n).is_equal_approx(0.10874, 0.01)


func test_pity_carries_over_to_next_character_banner() -> void:
	var a := _banner()
	var next := _banner().duplicate(true) as BannerDef
	next.id = "banner_char_next"
	var s := _svc(1)
	for i in 30:
		s.pull(a, 1)
	if s.pity_count(a, "S") == 0:                                    # lượt cuối đúng lúc ra S: quay thêm một lượt
		s.pull(a, 1)
	assert_int(s.pity_count(next, "S")).is_equal(s.pity_count(a, "S"))   # cùng nhóm "char"
	assert_int(s.pity_count(next, "S")).is_greater(0)


func test_cost_and_duplicate_fragments() -> void:
	var s := _svc()
	var before := _profile.inventory.currency("gems")
	s.pull(_banner(), 1)
	assert_int(_profile.inventory.currency("gems")).is_equal(before - 280)
	s.pull(_banner(), 10)
	assert_int(_profile.inventory.currency("gems")).is_equal(before - 280 - 2520)
	# Iwagane (S đề cử): lần đầu mở khóa, lần sau trùng → 25 mảnh.
	_profile.progression.unlock("char_earth_01")
	var b := _banner()
	b.tier("S").base_rate = 1.0
	b.tier("A").base_rate = 0.0
	b.tier("B").base_rate = 0.0
	var r: Dictionary = s.pull(b, 1)["results"][0]
	assert_bool(r["duplicate"]).is_true()
	assert_int(_profile.progression.fragments_of("char_earth_01")).is_equal(25)


func test_new_character_unlocked_and_gold_reward() -> void:
	var b := _banner()
	b.tier("S").base_rate = 0.0
	b.tier("S").soft_pity_start = 0
	b.tier("S").hard_pity = 0
	b.tier("A").base_rate = 1.0
	b.tier("B").base_rate = 0.0
	b.multi_guarantee_tiers = PackedStringArray()
	b.multi_guarantee_pick = PackedStringArray()
	var s := _svc()
	var r: Dictionary = s.pull(b, 1)["results"][0]
	assert_bool(r["duplicate"]).is_false()
	assert_bool(_profile.progression.owns(str(r["item"]).get_slice(":", 1))).is_true()
	var m := _banner()
	m.tier("MAT").pool = PackedStringArray(["gold:2000"])
	m.tier("S").base_rate = 0.0
	m.tier("S").soft_pity_start = 0
	m.tier("S").hard_pity = 0
	m.tier("A").base_rate = 0.0
	m.tier("B").base_rate = 0.0
	var gold := _profile.inventory.currency("gold")
	s.pull(m, 1)
	assert_int(_profile.inventory.currency("gold")).is_equal(gold + 2000)
