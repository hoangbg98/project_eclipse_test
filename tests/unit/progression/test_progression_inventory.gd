extends GdUnitTestSuite
## Test M5-2 / M5-3: cấp, EXP, tiền, nguyên liệu, trang bị, cường hóa, chỉ số cuối cùng, lưu / đọc.

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")
const A := "char_fire_01"

var _data: Dictionary
var _p: PlayerProfile
var _inv: Inventory
var _prog: Progression
var _rules: ProgressionRules


func before_test() -> void:
	_data = TestTeam.three()
	_data["account"]["level"] = 50                                 # test cũ: không vướng giới hạn cấp đội trưởng
	_p = PlayerProfile.new(_data)
	_inv = _p.inventory
	_prog = _p.progression
	_rules = _p.rules


func _aether() -> CharacterDef:
	return load("res://data/characters/char_fire_01.tres")


# ---------- Dữ liệu ----------

func test_data_is_valid() -> void:
	assert_array(_rules.validate()).is_empty()
	assert_array(PlayerProfile.item_defs().errors).is_empty()
	assert_array(PlayerProfile.equipment_defs().errors).is_empty()
	assert_int(PlayerProfile.item_defs().defs.size()).is_equal(8)    # + Tinh thể nâng bậc, Đá tẩy phụ tố (2026-11-15)
	assert_int(PlayerProfile.equipment_defs().defs.size()).is_equal(59)   # 16 cũ + 6 vũ khí 5★ + 18 vết thánh 5★ + 4 bộ 4★ mới × 4 + 3 vũ khí 3★ mới
	var slots := {}
	for id in PlayerProfile.equipment_defs().ids():
		var d: EquipmentDef = PlayerProfile.equipment_defs().get_def(id)
		slots[d.slot] = true
		assert_str(tr(d.name_key)).is_not_equal(d.name_key)
	assert_int(slots.size()).is_equal(4)                              # đủ 3 ô
	for id in PlayerProfile.item_defs().ids():
		assert_str(tr((PlayerProfile.item_defs().get_def(id) as ItemDef).name_key)).is_not_equal("")


# ---------- Cấp / EXP ----------

func test_exp_curve() -> void:
	assert_int(_rules.exp_to_next(1)).is_equal(100)
	assert_int(_rules.exp_to_next(4)).is_equal(800)                   # 100 × 4^1.5
	assert_int(_rules.exp_to_next(_rules.max_level)).is_equal(0)
	assert_int(_rules.total_exp_for(3)).is_equal(100 + 283)


func test_add_exp_levels_up_and_carries_remainder() -> void:
	var ups := []
	_prog.leveled_up.connect(func(id: String, a: int, b: int) -> void: ups.append([id, a, b]))
	assert_int(_prog.add_exp(A, 99)).is_equal(0)
	assert_int(_prog.level_of(A)).is_equal(1)
	assert_int(_prog.add_exp(A, 1 + 283 + 50)).is_equal(2)            # qua cấp 2 và 3, dư 50
	assert_int(_prog.level_of(A)).is_equal(3)
	assert_int(_prog.exp_of(A)).is_equal(50)
	assert_array(ups).is_equal([[A, 1, 3]])
	assert_int(_prog.add_exp(A, -5)).is_equal(0)
	assert_int(_prog.add_exp("char_nobody", 500)).is_equal(0)


func test_max_level_caps_and_drops_overflow() -> void:
	_prog.add_exp(A, 100_000_000)
	assert_int(_prog.level_of(A)).is_equal(_rules.max_level)
	assert_int(_prog.exp_of(A)).is_equal(0)
	assert_bool(_prog.is_max_level(A)).is_true()
	assert_int(_prog.exp_room(A)).is_equal(0)
	assert_int(_prog.add_exp(A, 500)).is_equal(0)


func test_exp_material_costs_material_and_gold() -> void:
	_inv.add_material("mat_exp_medium", 3)
	assert_str(_prog.use_exp_material(A, "mat_exp_medium", 2)).is_equal(Inventory.REASON_NOT_ENOUGH)   # chưa có vàng
	assert_int(_inv.material_count("mat_exp_medium")).is_equal(3)     # thất bại: không trừ gì
	_inv.add_currency("gold", 1000)
	assert_int(_prog.exp_material_gold_cost("mat_exp_medium", 2)).is_equal(200)   # 1000 EXP × 0.2
	assert_str(_prog.use_exp_material(A, "mat_exp_medium", 2)).is_equal("")
	assert_int(_inv.material_count("mat_exp_medium")).is_equal(1)
	assert_int(_inv.currency("gold")).is_equal(800)
	assert_int(_prog.level_of(A)).is_equal(4)                         # 1000 EXP: 100 + 283 + 520, dư 97
	assert_int(_prog.exp_of(A)).is_equal(97)
	assert_str(_prog.use_exp_material(A, "mat_exp_medium", 5)).is_equal(Inventory.REASON_NOT_ENOUGH)
	assert_str(_prog.use_exp_material(A, "mat_enhance_ore", 1)).is_equal(Inventory.REASON_UNKNOWN_ITEM)
	assert_str(_prog.use_exp_material("char_nobody", "mat_exp_medium", 1)).is_equal(Inventory.REASON_UNKNOWN_CHARACTER)


func test_unlock_character() -> void:
	assert_bool(_prog.owns("char_dark_01")).is_false()
	assert_bool(_prog.unlock("char_dark_01")).is_true()
	assert_bool(_prog.unlock("char_dark_01")).is_false()
	assert_int(_prog.level_of("char_dark_01")).is_equal(1)


# ---------- Tiền, nguyên liệu ----------

func test_currency_validation() -> void:
	assert_bool(_inv.add_currency("gold", 500)).is_true()
	assert_bool(_inv.add_currency("gold", -1)).is_false()
	assert_bool(_inv.add_currency("rubles", 5)).is_false()
	assert_bool(_inv.spend_currency("gold", 501)).is_false()
	assert_int(_inv.currency("gold")).is_equal(500)                   # thiếu thì giữ nguyên
	assert_bool(_inv.spend_currency("gold", 500)).is_true()
	assert_int(_inv.currency("gold")).is_equal(0)
	assert_bool(_inv.spend_currency("gold", -5)).is_false()


func test_materials_add_consume() -> void:
	assert_bool(_inv.add_material("mat_exp_small", 4)).is_true()
	assert_bool(_inv.add_material("mat_fake", 4)).is_false()
	assert_bool(_inv.consume_material("mat_exp_small", 5)).is_false()
	assert_int(_inv.material_count("mat_exp_small")).is_equal(4)
	assert_bool(_inv.consume_material("mat_exp_small", 4)).is_true()
	assert_bool(_data["inventory"]["materials"].has("mat_exp_small")).is_false()   # hết thì bỏ khóa


# ---------- Trang bị ----------

func test_equip_swap_and_move_between_characters() -> void:
	var w1 := _inv.add_equipment("eq_weapon_iron")
	var w2 := _inv.add_equipment("eq_weapon_flame")
	assert_str(_inv.add_equipment("eq_fake")).is_equal("")
	assert_bool(w1 != w2 and w1 != "").is_true()
	assert_str(_inv.equip(A, w1)).is_equal("")
	assert_str(_inv.equipped_uid(A, "weapon")).is_equal(w1)
	assert_str(_inv.equip(A, w2)).is_equal("")                        # thay món cùng ô
	assert_str(_inv.equipped_uid(A, "weapon")).is_equal(w2)
	assert_str(_inv.equipped_by(w1)).is_equal("")
	assert_str(_inv.equip("char_wind_01", w2)).is_equal(Inventory.REASON_WRONG_WEAPON)   # Lyra dùng cung
	var s := _inv.add_equipment("eq_stigma_top_elite")
	_inv.equip(A, s)
	assert_str(_inv.equip("char_wind_01", s)).is_equal("")            # vết thánh: chuyển sang nhân vật khác
	assert_str(_inv.equipped_uid(A, "stigma_top")).is_equal("")
	assert_str(_inv.equipped_by(s)).is_equal("char_wind_01")
	assert_str(_inv.equip(A, "999")).is_equal(Inventory.REASON_NOT_OWNED)
	assert_str(_inv.equip("char_nobody", w1)).is_equal(Inventory.REASON_UNKNOWN_CHARACTER)
	assert_bool(_inv.unequip("char_wind_01", "stigma_top")).is_true()
	assert_bool(_inv.unequip("char_wind_01", "stigma_top")).is_false()


func test_remove_equipped_item_unequips() -> void:
	var a := _inv.add_equipment("eq_stigma_mid_hide")
	_inv.equip(A, a)
	assert_bool(_inv.remove_equipment(a)).is_true()
	assert_str(_inv.equipped_uid(A, "stigma_mid")).is_equal("")
	assert_bool(_inv.owns(a)).is_false()


func test_enhance_costs_and_caps() -> void:
	var w := _inv.add_equipment("eq_weapon_iron")                     # 3★: 20 vàng × (L+1), 10 điểm × (L+1)
	var d := _inv.equipment_def_of(w)
	assert_str(_inv.enhance(w, "mat_enhance_ore")).is_equal(Inventory.REASON_NOT_ENOUGH)
	_inv.add_currency("gold", 100000)
	_inv.add_material("mat_enhance_ore", 3)                           # 50 điểm mỗi món
	assert_int(_inv.materials_to_enhance(w, "mat_enhance_ore")).is_equal(int(ceil(d.points_to_enhance(0) / 50.0)))
	assert_str(_inv.enhance(w, "mat_enhance_ore")).is_equal("")
	assert_int(_inv.equipment_level(w)).is_equal(1)
	assert_int(_inv.currency("gold")).is_equal(100000 - d.gold_to_enhance(0))
	assert_str(_inv.enhance(w, "mat_exp_small")).is_equal(Inventory.REASON_UNKNOWN_ITEM)
	_inv.add_material("mat_enhance_crystal", 500)
	while _inv.enhance(w, "mat_enhance_crystal") == "":
		pass
	assert_int(_inv.equipment_level(w)).is_equal(15)                 # 3★ bậc 0: giới hạn 15
	assert_str(_inv.enhance(w, "mat_enhance_crystal")).is_equal(Inventory.REASON_MAX_LEVEL)
	_inv.add_material("mat_enhance_ore", 0)
	assert_int(_inv.material_count("mat_enhance_ore")).is_greater_equal(0)


## Bậc cường hóa (owner 2026-11-15): vũ khí 3★ 15-20-25, 4★ 25-30-35, 5★ 25-40-45-50; vết thánh 30-40-50.
func test_level_caps_by_rarity_and_slot() -> void:
	var cases := {"eq_weapon_iron": [15, 20, 25], "eq_weapon_flame": [25, 30, 35],
			"eq_weapon_dusk_inferno": [25, 40, 45, 50], "eq_stigma_top_blaze": [30, 40, 50], "eq_stigma_top_elite": [30, 40, 50]}
	for def_id: String in cases:
		var uid := _inv.add_equipment(def_id)
		assert_array(Array(_inv.level_caps(uid))).override_failure_message(def_id).is_equal(cases[def_id])
		assert_int(_inv.max_tier(uid)).is_equal((cases[def_id] as Array).size() - 1)
		assert_int(_inv.level_cap(uid)).is_equal(int(cases[def_id][0]))
		assert_int(_inv.final_level_cap(uid)).is_equal(int(cases[def_id][-1]))


## Nâng bậc: đủ cấp + vàng + nguyên liệu thì +1 bậc, giới hạn lên mức kế; hết bậc thì dừng. Vết thánh cũng nâng bậc.
func test_ascension_raises_level_cap() -> void:
	var w := _inv.add_equipment("eq_weapon_flame")                    # 4★: 25 → 30 → 35
	assert_str(_inv.check_ascend(w)).is_equal(Inventory.REASON_NEED_LEVEL)
	_data["inventory"]["equipment"][w]["level"] = 25
	assert_str(_inv.ascend(w)).is_equal(Inventory.REASON_NOT_ENOUGH)
	var cost := _inv.ascend_cost(w)
	assert_int(int(cost["count"])).is_equal(_rules.ascend_material_count[0])
	_inv.add_currency("gold", 100000)
	_inv.add_material(_rules.ascend_material, 20)
	_inv.equip(A, w)
	var bonus_25: float = _inv.equipped_bonus(A)["atk"]
	assert_str(_inv.ascend(w)).is_equal("")
	assert_int(_inv.equipment_tier(w)).is_equal(1)
	assert_int(_inv.level_cap(w)).is_equal(30)
	assert_int(_inv.currency("gold")).is_equal(100000 - _rules.ascend_gold[0])
	assert_int(_inv.material_count(_rules.ascend_material)).is_equal(20 - _rules.ascend_material_count[0])
	_inv.add_material("mat_enhance_crystal", 2000)
	assert_str(_inv.enhance(w, "mat_enhance_crystal")).is_equal("")    # vượt Lv.25
	assert_int(_inv.equipment_level(w)).is_equal(26)
	assert_float(_inv.equipped_bonus(A)["atk"]).is_greater(bonus_25)
	_data["inventory"]["equipment"][w]["level"] = 30
	assert_str(_inv.ascend(w)).is_equal("")
	_data["inventory"]["equipment"][w]["level"] = 35
	assert_str(_inv.check_ascend(w)).is_equal(Inventory.REASON_MAX_LEVEL)   # hết bậc
	assert_bool(_inv.ascend_cost(w).is_empty()).is_true()
	assert_str(_inv.enhance(w, "mat_enhance_crystal")).is_equal(Inventory.REASON_MAX_LEVEL)
	var st := _inv.add_equipment("eq_stigma_top_blaze")
	_data["inventory"]["equipment"][st]["level"] = 30
	assert_str(_inv.ascend(st)).is_equal("")
	assert_int(_inv.level_cap(st)).is_equal(40)


## Cấp cường hóa không vượt quá cấp người chơi (owner 2026-11-15).
func test_enhance_capped_by_captain_level() -> void:
	_data["account"]["level"] = 3
	var w := _inv.add_equipment("eq_weapon_iron")
	_inv.add_currency("gold", 100000)
	_inv.add_material("mat_enhance_crystal", 500)
	while _inv.enhance(w, "mat_enhance_crystal") == "":
		pass
	assert_int(_inv.equipment_level(w)).is_equal(3)
	assert_str(_inv.check_enhance(w, "mat_enhance_crystal")).is_equal(Inventory.REASON_LEVEL_CAP)
	_data["account"]["level"] = 4
	assert_str(_inv.enhance(w, "mat_enhance_crystal")).is_equal("")


## Phụ tố vết thánh (owner 2026-11-15): bốc khi nhận theo độ hiếm, không trùng loại, cộng vào chỉ số; tẩy bằng đá, chọn
## giữ mới / cũ; vũ khí không có phụ tố.
func test_stigma_affixes_roll_apply_and_reroll() -> void:
	_inv.rng.seed = 12345
	var w := _inv.add_equipment("eq_weapon_flame")
	var s5 := _inv.add_equipment("eq_stigma_top_blaze")
	var s3 := _inv.add_equipment("eq_stigma_top_elite")
	assert_array(_inv.affixes_of(w)).is_empty()
	assert_int(_inv.affixes_of(s5).size()).is_equal(_rules.affix_count_for(_inv.equipment_def_of(s5).rarity))
	assert_int(_inv.affixes_of(s3).size()).is_equal(_rules.affix_count_for(_inv.equipment_def_of(s3).rarity))
	var ids := {}
	for a: Dictionary in _inv.affixes_of(s5):
		var ad := PlayerProfile.affix_defs().get_def(str(a["id"])) as AffixDef
		assert_object(ad).is_not_null()
		assert_bool(ids.has(ad.id)).is_false()
		ids[ad.id] = true
		var scale := _rules.affix_scale_for(_inv.equipment_def_of(s5).rarity)
		assert_float(float(a["value"])).is_between(ad.min_value * scale - 0.001, ad.max_value * scale + 0.001)
	# Cộng vào chỉ số: phụ tố cộng thẳng vào equipped_bonus, phụ tố % vào loadout.
	_data["inventory"]["equipment"][s5]["affixes"] = [{"id": "affix_atk", "value": 40.0}, {"id": "affix_all_dmg", "value": 0.05}]
	var before: float = _inv.equipped_bonus(A)["atk"]
	_inv.equip(A, s5)
	assert_float(_inv.equipped_bonus(A)["atk"] - before - _inv.equipment_def_of(s5).atk).is_equal_approx(40.0, 0.001)
	assert_float(_inv.loadout_of(A, "fire").stat("all_dmg")).is_greater_equal(0.05)
	# Tẩy: thiếu đá → không đổi; đủ đá → có kết quả chờ, chọn giữ cũ / mới.
	assert_str(_inv.reroll_affixes(s5)).is_equal(Inventory.REASON_NOT_ENOUGH)
	_inv.add_material(_rules.affix_reroll_material, 10)
	var old := _inv.affixes_of(s5).duplicate(true)
	assert_str(_inv.reroll_affixes(s5)).is_equal("")
	assert_int(_inv.material_count(_rules.affix_reroll_material)).is_equal(10 - _inv.reroll_cost(s5))
	assert_int(_inv.pending_affixes(s5).size()).is_equal(2)
	assert_str(_inv.reroll_affixes(s5)).is_equal(Inventory.REASON_PENDING)
	assert_str(_inv.confirm_reroll(s5, false)).is_equal("")
	assert_array(_inv.affixes_of(s5)).is_equal(old)
	assert_str(_inv.reroll_affixes(s5)).is_equal("")
	var fresh := _inv.pending_affixes(s5).duplicate(true)
	assert_str(_inv.confirm_reroll(s5, true)).is_equal("")
	assert_array(_inv.affixes_of(s5)).is_equal(fresh)
	assert_array(_inv.pending_affixes(s5)).is_empty()
	assert_str(_inv.reroll_affixes(w)).is_equal(Inventory.REASON_NO_AFFIX)


## Save cũ: vết thánh chưa có phụ tố được gieo một lần khi tạo PlayerProfile.
func test_old_save_stigmata_get_affixes() -> void:
	var uid := _inv.add_equipment("eq_stigma_top_elite")
	_data["inventory"]["equipment"][uid].erase("affixes")
	var p2 := PlayerProfile.new(_data)
	assert_int(p2.inventory.affixes_of(uid).size()).is_greater(0)
	assert_array(PlayerProfile.affix_defs().errors).is_empty()


## Tinh thể nâng bậc rơi từ ải 1-5 → 1-10 (owner 2026-11-15), cả lượt thường và lần đầu; Đá tẩy phụ tố rơi lần đầu.
func test_ascension_material_drops_from_stages() -> void:
	var mat := _rules.ascend_material
	var stone := _rules.affix_reroll_material
	assert_object(PlayerProfile.item_defs().get_def(mat)).is_not_null()
	assert_object(PlayerProfile.item_defs().get_def(stone)).is_not_null()
	var first_total := 0
	for n in range(5, 11):
		var d: Dictionary = StageMap.load_from("res://data/stages/stage_01_%02d.json" % n).data
		assert_int(int(d["rewards"]["materials"].get(mat, 0))).override_failure_message("1-%d" % n).is_greater(0)
		assert_int(int(d["first_clear_rewards"]["materials"].get(stone, 0))).override_failure_message("1-%d" % n).is_greater(0)
		first_total += int(d["first_clear_rewards"]["materials"].get(mat, 0))
	var four_star := 0
	for i in 2:
		four_star += _rules.ascend_material_count[i]
	assert_int(first_total).is_greater_equal(four_star)


# ---------- Chỉ số cuối cùng ----------

func test_stats_at_level_1_no_gear_equal_base() -> void:
	var s := _prog.stats_for(_aether())
	assert_array([s.max_hp, s.atk, s.def, s.crit_rate, s.crit_damage]).is_equal([12000.0, 1000.0, 500.0, 0.05, 0.5])
	assert_object(s).is_not_same(_aether().stats)                     # không sửa bản gốc


func test_stats_scale_with_level_and_gear() -> void:
	_data["characters"][A]["level"] = 11                             # +10 cấp: HP/ATK ×1.6, DEF ×1.5
	var w := _inv.add_equipment("eq_weapon_flame")                    # ATK +160, chí mạng +5%
	var r := _inv.add_equipment("eq_stigma_top_elite")                        # ATK +30, chí mạng +4%, sát thương chí mạng +10%
	var h := _inv.add_equipment("eq_stigma_mid_guardian")                  # HP +1800, DEF +90
	for uid in [r, h]:
		_data["inventory"]["equipment"][uid]["affixes"] = []           # bỏ phụ tố ngẫu nhiên để số liệu cố định
	_data["inventory"]["equipment"][w]["level"] = 10                  # 4★ 5%/cấp: ×1.5 phần cộng thẳng
	for uid in [w, r, h]:
		_inv.equip(A, uid)
	var s := _prog.stats_for(_aether())
	assert_float(s.atk).is_equal(1000.0 * 1.6 + 160.0 * 1.5 + 30.0)
	assert_float(s.max_hp).is_equal(12000.0 * 1.6 + 1800.0)
	assert_float(s.def).is_equal(500.0 * 1.5 + 90.0)
	assert_float(s.crit_rate).is_equal_approx(0.05 + 0.05 + 0.04, 0.0001)
	assert_float(s.crit_damage).is_equal_approx(0.6, 0.0001)
	assert_float(_aether().stats.atk).is_equal(1000.0)


func test_missing_equipped_item_is_ignored() -> void:
	_data["characters"][A]["equipment"]["weapon"] = "404"            # save trỏ tới món không còn
	assert_float(_prog.stats_for(_aether()).atk).is_equal(1000.0)


func test_party_uses_profile_stats_in_stage() -> void:
	_data["characters"][A]["level"] = 11
	var stage: Node2D = auto_free(STAGE_SCENE.instantiate())
	stage.spawn_enemies = false
	stage.stats_provider = _p.stats_of
	add_child(stage)
	var c: Combatant = stage.player.combatant
	assert_float(c.stats.atk).is_equal(1600.0)
	assert_float(c.resources.max_hp).is_equal(19200.0)
	assert_float(stage.party.members[1].combatant().stats.atk).is_equal(950.0)   # Kael cấp 1


# ---------- Đội, thưởng, lưu ----------

func test_set_party_validates() -> void:
	assert_bool(_p.set_party(["char_wind_01", A])).is_true()
	assert_array(Array(_p.party_ids())).is_equal(["char_wind_01", A])
	assert_bool(_p.set_party([])).is_false()
	assert_bool(_p.set_party([A, A])).is_false()
	assert_bool(_p.set_party([A, "char_dark_01"])).is_false()         # chưa sở hữu
	assert_bool(_p.set_party([A, "char_wind_01", "char_lightning_01", A])).is_false()
	assert_array(Array(_p.party_ids())).is_equal(["char_wind_01", A])   # giữ nguyên khi không hợp lệ


func test_party_rejects_two_suits_of_same_person() -> void:
	assert_str(_p.person_of(A)).is_equal("enkiba")
	assert_str(_p.person_of("char_earth_01")).is_equal("iwagane")
	_p.person_cache["char_wind_01"] = "enkiba"                          # giả lập Lyra là giáp thứ hai của Enkiba
	assert_bool(_p.set_party([A, "char_wind_01"])).is_false()
	assert_bool(_p.set_party([A, "char_lightning_01"])).is_true()


func test_grant_reward_summary() -> void:
	var got := _p.grant({"gold": 500, "gems": 20, "materials": {"mat_exp_small": 3, "mat_fake": 9},
			"equipment": ["eq_stigma_top_elite", "eq_fake"], "exp": 150})
	assert_int(_inv.currency("gold")).is_equal(500)
	assert_int(_inv.currency("gems")).is_equal(20)
	assert_int(_inv.material_count("mat_exp_small")).is_equal(3)
	assert_dict(got["materials"]).is_equal({"mat_exp_small": 3})
	assert_int(got["equipment"].size()).is_equal(1)
	for id in SaveSchema.STARTER_CHARACTERS:                          # EXP cho cả đội
		assert_int(_prog.level_of(id)).is_equal(2)
		assert_int(got["levels"][id]).is_equal(1)


func test_changes_persist_through_save_and_load() -> void:
	var store := SaveStore.new("user://test_saves_m5_2")
	store.delete_all()
	_inv.add_currency("gold", 5000)
	_inv.add_material("mat_enhance_ore", 10)
	var w := _inv.add_equipment("eq_weapon_iron")
	_inv.equip(A, w)
	_inv.enhance(w, "mat_enhance_ore")
	_prog.add_exp(A, 1000)
	store.write(_data)
	var p2 := PlayerProfile.new(store.read())
	assert_int(p2.progression.level_of(A)).is_equal(4)
	var wd := p2.inventory.equipment_def_of(w)
	assert_int(p2.inventory.currency("gold")).is_equal(5000 - wd.gold_to_enhance(0))
	assert_int(p2.inventory.material_count("mat_enhance_ore")).is_equal(10 - int(ceil(wd.points_to_enhance(0) / 50.0)))
	assert_str(p2.inventory.equipped_uid(A, "weapon")).is_equal(w)
	assert_int(p2.inventory.equipment_level(w)).is_equal(1)
	assert_float(p2.stats_of(A).atk).is_equal(round(1000.0 * 1.18 + 80.0 * (1.0 + wd.growth_per_level)))
	var w2 := p2.inventory.add_equipment("eq_stigma_mid_hide")          # uid không trùng sau khi đọc lại
	assert_bool(w2 != w).is_true()
	store.delete_all()
	DirAccess.remove_absolute("user://test_saves_m5_2")
