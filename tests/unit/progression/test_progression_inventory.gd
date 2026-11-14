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
	assert_int(PlayerProfile.item_defs().defs.size()).is_equal(6)
	assert_int(PlayerProfile.equipment_defs().defs.size()).is_equal(40)   # 16 cũ + 6 vũ khí 5★ + 18 vết thánh 5★
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
	var w := _inv.add_equipment("eq_weapon_iron")                     # hiếm 1: 200 vàng × (L+1), 100 điểm × (L+1)
	assert_str(_inv.enhance(w, "mat_enhance_ore")).is_equal(Inventory.REASON_NOT_ENOUGH)
	_inv.add_currency("gold", 100000)
	_inv.add_material("mat_enhance_ore", 3)                           # 50 điểm mỗi món
	assert_int(_inv.materials_to_enhance(w, "mat_enhance_ore")).is_equal(2)
	assert_str(_inv.enhance(w, "mat_enhance_ore")).is_equal("")
	assert_int(_inv.equipment_level(w)).is_equal(1)
	assert_int(_inv.currency("gold")).is_equal(100000 - 200)
	assert_int(_inv.material_count("mat_enhance_ore")).is_equal(1)
	assert_str(_inv.enhance(w, "mat_enhance_ore")).is_equal(Inventory.REASON_NOT_ENOUGH)   # cần 4, còn 1
	assert_int(_inv.currency("gold")).is_equal(100000 - 200)          # thất bại: không trừ
	assert_str(_inv.enhance(w, "mat_exp_small")).is_equal(Inventory.REASON_UNKNOWN_ITEM)
	_inv.add_material("mat_enhance_crystal", 500)
	for i in 9:
		assert_str(_inv.enhance(w, "mat_enhance_crystal")).is_equal("")
	assert_int(_inv.equipment_level(w)).is_equal(10)
	assert_str(_inv.enhance(w, "mat_enhance_crystal")).is_equal(Inventory.REASON_MAX_LEVEL)


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
	_data["inventory"]["equipment"][w]["level"] = 5                   # ×1.5 phần cộng thẳng
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
	assert_int(p2.inventory.currency("gold")).is_equal(4800)
	assert_int(p2.inventory.material_count("mat_enhance_ore")).is_equal(8)
	assert_str(p2.inventory.equipped_uid(A, "weapon")).is_equal(w)
	assert_int(p2.inventory.equipment_level(w)).is_equal(1)
	assert_float(p2.stats_of(A).atk).is_equal(round(1000.0 * 1.18 + 80.0 * 1.1))
	var w2 := p2.inventory.add_equipment("eq_stigma_mid_hide")          # uid không trùng sau khi đọc lại
	assert_bool(w2 != w).is_true()
	store.delete_all()
	DirAccess.remove_absolute("user://test_saves_m5_2")
