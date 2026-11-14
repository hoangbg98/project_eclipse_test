extends GdUnitTestSuite
## Test banner tiếp tế vũ khí + vết thánh (owner 2026-11-12/13: 2.87 / 14 / 10.7 / 14.43 / 58%, pity cứng vũ khí 4★ 60,
## 10 lượt chắc chắn 4★ ưu tiên vết thánh) và lượt x10 miễn phí đầu tiên (chắc chắn 1 Raikiba, còn lại nguyên liệu).

const EQUIP_PATH := "res://data/banners/banner_equip_terra.tres"
const STARTER_PATH := "res://data/tutorial/starter_pull.tres"

var _data: Dictionary
var _profile: PlayerProfile


func before_test() -> void:
	_data = SaveSchema.default_data()
	_profile = PlayerProfile.new(_data)
	_profile.inventory.add_currency("gems", 100_000_000)


func _equip() -> BannerDef:
	return load(EQUIP_PATH)


func _svc(seed_value := 7) -> GachaService:
	return GachaService.new(_profile, RandomSource.new(seed_value))


# ---------- Tiếp tế ----------

func test_equip_config_matches_owner_and_sums_to_100() -> void:
	var b := _equip()
	assert_array(b.validate()).is_empty()
	assert_array([b.cost_single, b.cost_multi, b.multi_count]).is_equal([200, 1800, 10])   # owner 2026-11-15
	assert_float(b.tier("W4").base_rate).is_equal(0.0287)
	assert_float(b.tier("S4").base_rate).is_equal(0.14)
	assert_float(b.tier("W3").base_rate).is_equal(0.107)
	assert_float(b.tier("S3").base_rate).is_equal(0.1443)
	var table := GachaService.rates_table(b)
	assert_float(table[4]["rate"]).is_equal_approx(0.58, 0.0000001)
	var total := 0.0
	for row in table:
		total += float(row["rate"])
	assert_float(total).is_equal_approx(1.0, 0.0000001)
	for t in b.tiers:                                                     # owner 2026-11-15: không pity, không bảo đảm
		assert_int(t.hard_pity).is_equal(0)
		assert_int(t.soft_pity_start).is_equal(0)
	assert_array(Array(b.multi_guarantee_tiers)).is_empty()
	assert_array(Array(b.multi_guarantee_pick)).is_empty()
	assert_str(b.group()).is_equal("equip")
	assert_array(Array(b.tier("W4").featured)).is_equal(["equip:eq_weapon_greatsword_magma"])
	assert_int(b.tier("S4").featured.size()).is_equal(3)                  # bộ Đầu / Thân / Chân đề cử


func test_equip_pools_hold_right_rarity_and_slot() -> void:
	var b := _equip()
	var defs := PlayerProfile.equipment_defs()
	for key in ["W4", "S4", "W3", "S3"]:
		for entry in b.tier(key).pool:
			var d := defs.get_def(entry.get_slice(":", 1)) as EquipmentDef
			assert_int(d.rarity).is_equal(int(key.substr(1)))
			assert_bool(d.slot == "weapon").is_equal(key.begins_with("W"))
	var slots := {}
	for entry in b.tier("S3").pool:
		slots[(defs.get_def(entry.get_slice(":", 1)) as EquipmentDef).slot] = true
	assert_int(slots.size()).is_equal(3)


func test_no_pity_and_no_forced_pulls() -> void:
	# Owner 2026-11-15: tiếp tế không còn pity cứng 60 và bảo đảm 10 lượt: không lượt nào bị ép bậc.
	var s := _svc(13)
	var four := 0
	for i in 120:
		for r: Dictionary in s.pull(_equip(), 10)["results"]:
			assert_bool(r["forced"]).is_false()
			if r["tier"] in ["W4", "S4"]:
				four += 1
	var rate := float(four) / 1200.0
	assert_float(rate).is_between(0.13, 0.21)                             # 2.87% + 14% ≈ 16.9%


func test_equip_pull_adds_equipment_and_shares_no_pity_with_characters() -> void:
	var s := _svc(4)
	var before := _profile.inventory.equipment_uids().size()
	var res: Array = s.pull(_equip(), 10)["results"]
	var equips := 0
	for r: Dictionary in res:
		if str(r["item"]).begins_with("equip:"):
			equips += 1
	assert_int(_profile.inventory.equipment_uids().size() - before).is_equal(equips)
	var char_banner: BannerDef = load("res://data/banners/banner_char_terra.tres")
	assert_int(s.pity_count(char_banner, "S")).is_equal(0)


# ---------- Lượt x10 miễn phí đầu tiên ----------

func test_starter_pull_is_free_once_with_exactly_one_kael() -> void:
	var b: BannerDef = load(STARTER_PATH)
	assert_array(b.validate()).is_empty()
	assert_bool(b.starter_free_multi).is_true()
	assert_str(b.ticket_item).is_equal("ticket_starter_x10")
	var s := _svc(21)
	assert_bool(s.starter_available(b)).is_false()                     # chưa có vé (nhận ở ải 1-1)
	assert_str(s.pull_starter(b)["reason"]).is_equal(GachaService.REASON_NO_TICKET)
	_profile.inventory.add_material("ticket_starter_x10", 1)
	assert_bool(s.starter_available(b)).is_true()
	var gems := _profile.inventory.currency("gems")
	var out := s.pull_starter(b)
	assert_str(out["reason"]).is_equal("")
	assert_int(_profile.inventory.currency("gems")).is_equal(gems)     # miễn phí
	var kael := 0
	for r: Dictionary in out["results"]:
		if r["item"] == "char:char_lightning_01":
			kael += 1
		else:
			assert_str(str(r["item"])).starts_with("item:mat_exp_")
	assert_int(out["results"].size()).is_equal(10)
	assert_int(kael).is_equal(1)
	assert_bool(_profile.progression.owns("char_lightning_01")).is_true()
	assert_array(Array(_profile.party_ids())).is_equal(["char_fire_01", "char_lightning_01"])   # vào đội luôn
	assert_int(_profile.inventory.material_count("ticket_starter_x10")).is_equal(0)            # trừ vé
	_profile.inventory.add_material("ticket_starter_x10", 1)
	assert_bool(s.starter_available(b)).is_false()                     # có vé nhưng đã dùng
	assert_str(s.pull_starter(b)["reason"]).is_equal(GachaService.REASON_STARTER_USED)
	assert_array(SaveSchema.sanitize(_data)["gacha"]["starter_used"]).is_equal(["starter_pull"])


func test_starter_kael_position_varies_and_normal_banner_refused() -> void:
	var seen := {}
	for seed_value in 12:
		before_test()
		_profile.inventory.add_material("ticket_starter_x10", 1)
		var out := _svc(seed_value).pull_starter(load(STARTER_PATH))
		for i in out["results"].size():
			if out["results"][i]["item"] == "char:char_lightning_01":
				seen[i] = true
	assert_int(seen.size()).is_greater(1)
	assert_str(_svc().pull_starter(_equip())["reason"]).is_equal(GachaService.REASON_INVALID)
