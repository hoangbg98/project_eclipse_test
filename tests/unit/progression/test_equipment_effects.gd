extends GdUnitTestSuite
## Hiệu ứng trang bị 5★ và trần (docs/design/EQUIPMENT_5STAR.md mục 3.4, quyết định owner mục 5).

const FIRE := "char_fire_01"
const WIND := "char_wind_01"
const LIGHTNING := "char_lightning_01"
const LIGHT := "char_light_01"
const DARK := "char_dark_01"
const EARTH := "char_earth_01"


func _eq(id: String) -> EquipmentDef:
	return PlayerProfile.equipment_defs().get_def(id) as EquipmentDef


func _pieces(key: String) -> Array:
	return [_eq("eq_stigma_top_" + key), _eq("eq_stigma_mid_" + key), _eq("eq_stigma_bot_" + key)]


func _resolve(cid: String, element: String, items: Array) -> EquipmentResolver.Loadout:
	return EquipmentResolver.resolve(cid, element, items)


# ---------- Dữ liệu ----------

func test_data_loads_without_errors() -> void:
	assert_array(PlayerProfile.equipment_defs().errors).is_empty()
	assert_array(EquipmentResolver.set_defs().errors).is_empty()
	assert_array(EquipmentResolver.default_rules().validate()).is_empty()
	assert_int(EquipmentResolver.set_defs().defs.size()).is_equal(12)   # 6 bộ 5★ + 6 bộ 4★ (một bộ mỗi loại vũ khí)
	for key in ["lavoisier", "davinci", "franklin", "nightingale", "poe", "darwin"]:
		for d in _pieces(key):
			assert_object(d).is_not_null()
			assert_int(d.rarity).is_equal(5)
			assert_str(d.set_id).is_equal("set_" + key)
			assert_str(tr(d.name_key)).is_not_equal(d.name_key)
		var s := EquipmentResolver.set_defs().get_def("set_" + key) as StigmaSetDef
		assert_str(tr(s.name_key)).is_not_equal(s.name_key)


func test_five_star_weapons_match_character_weapon_types() -> void:
	for pair in [["eq_weapon_dusk_inferno", FIRE], ["eq_weapon_last_gale", WIND], ["eq_weapon_twin_thunder", LIGHTNING],
			["eq_weapon_solar_verdict", LIGHT], ["eq_weapon_crescent_pact", DARK], ["eq_weapon_unyielding_peak", EARTH]]:
		var w := _eq(pair[0])
		var c := load("res://data/characters/%s.tres" % pair[1]) as CharacterDef
		assert_str(w.owner_id).is_equal(pair[1])
		assert_str(w.weapon_type).is_equal(c.weapon_type)   # 5.1: vũ khí khóa theo loại vũ khí


func test_four_star_sets_have_only_common_effects() -> void:
	for sid in ["set_blaze", "set_bedrock", "set_whirlwind", "set_thunderclap", "set_dawnlight", "set_nightshade"]:
		var s := EquipmentResolver.set_defs().get_def(sid) as StigmaSetDef
		assert_int(s.rarity).is_equal(4)
		for e in s.bonus_2 + s.bonus_3:
			assert_bool(e.exclusive).is_false()               # Q9: bộ 4★ chỉ có phần chung


func test_four_star_gear_for_every_weapon_type() -> void:
	# Owner 2026-11-15: mỗi loại vũ khí có vũ khí 4★ + bộ 3 vết thánh 4★ (Đầu / Thân / Chân) cùng hệ với nhân vật.
	var defs := PlayerProfile.equipment_defs()
	for row in [["sword", "eq_weapon_flame", "blaze"], ["greatsword", "eq_weapon_greatsword_magma", "bedrock"],
			["bow", "eq_weapon_bow_whirlwind", "whirlwind"], ["dual_blades", "eq_weapon_blades_thunderclap", "thunderclap"],
			["staff", "eq_weapon_staff_dawnlight", "dawnlight"], ["scythe", "eq_weapon_scythe_nightshade", "nightshade"]]:
		var w := defs.get_def(row[1]) as EquipmentDef
		assert_object(w).override_failure_message(row[1]).is_not_null()
		assert_int(w.rarity).is_equal(4)
		assert_str(w.weapon_type).is_equal(row[0])
		var set_def := EquipmentResolver.set_defs().get_def("set_" + row[2]) as StigmaSetDef
		for slot in ["top", "mid", "bot"]:
			var st := defs.get_def("eq_stigma_%s_%s" % [slot, row[2]]) as EquipmentDef
			assert_object(st).override_failure_message("%s %s" % [row[2], slot]).is_not_null()
			assert_int(st.rarity).is_equal(4)
			assert_str(st.slot).is_equal("stigma_" + slot)
			assert_str(st.set_id).is_equal("set_" + row[2])
		var has_char := false
		for c in DirAccess.get_files_at("res://data/characters"):
			if c.ends_with(".tres"):
				var cd := load("res://data/characters/" + c) as CharacterDef
				if cd and cd.weapon_type == row[0]:
					has_char = true
					assert_str(set_def.element).is_equal(cd.element)   # bộ cùng hệ với nhân vật dùng loại vũ khí đó
		assert_bool(has_char).override_failure_message(row[0]).is_true()


func test_three_star_weapon_for_every_weapon_type() -> void:
	# Owner 2026-11-15: mỗi loại vũ khí có ít nhất 1 vũ khí 3★.
	var by_type := {}
	for d in PlayerProfile.equipment_defs().defs.values():
		var e := d as EquipmentDef
		if e and e.slot == "weapon" and e.rarity == 3:
			by_type[e.weapon_type] = true
	for t in ["sword", "greatsword", "bow", "dual_blades", "staff", "scythe"]:
		assert_bool(by_type.has(t)).override_failure_message(t).is_true()


func test_pending_effects_are_documented() -> void:
	# Hiệu ứng theo sự kiện chưa cài đặt: phải có mô tả, và được đếm để không quên (xem nhật ký).
	var pending := 0
	for id in PlayerProfile.equipment_defs().ids():
		for e in _eq(id).effects:
			if e.kind == EquipEffect.Kind.PENDING:
				pending += 1
				assert_str(e.note).is_not_empty()
	for sid in EquipmentResolver.set_defs().ids():
		var s := EquipmentResolver.set_defs().get_def(sid) as StigmaSetDef
		for e in s.bonus_2 + s.bonus_3:
			if e.kind == EquipEffect.Kind.PENDING:
				pending += 1
	assert_int(pending).is_equal(0)                                   # Khiên Đá = khiên của Giáp Địa (owner 2026-11-15)


# ---------- Chủ sở hữu, nguyên tố, bộ ----------

func test_exclusive_only_for_owner_suit() -> void:
	var w := _eq("eq_weapon_dusk_inferno")
	var own := _resolve(FIRE, "fire", [w])
	var other := _resolve("char_fire_02", "fire", [w])       # giáp khác cùng nhân vật: không nhận (Q1)
	assert_float(own.params.get("skill:weapon:cooldown_sec", 0.0)).is_equal(-2.0)
	assert_bool(other.params.has("skill:weapon:cooldown_sec")).is_false()
	assert_float(other.stat("all_dmg")).is_equal_approx(0.08, 0.0001)        # phần chung vẫn nhận
	assert_bool(own.team_out.has("fire_wpn_team_dmg")).is_true()
	assert_bool(other.team_out.has("fire_wpn_team_dmg")).is_false()


func test_requires_element_blocks_wrong_element() -> void:
	var top := _eq("eq_stigma_top_lavoisier")                   # ST Hỏa +10% (chỉ hệ Hỏa)
	assert_float(_resolve(WIND, "wind", [top]).stat("elem_dmg")).is_equal(0.0)
	assert_float(_resolve(FIRE, "fire", [top]).stat("elem_dmg")).is_equal_approx(0.10, 0.0001)
	var w := _eq("eq_weapon_dusk_inferno")                     # 5.3: vũ khí cũng khóa hệ
	var wrong := _resolve(WIND, "wind", [w])
	assert_bool(wrong.vs_target.has("burn")).is_false()
	assert_int(wrong.on_weapon_hit.size()).is_equal(0)


func test_set_bonus_needs_two_and_three_pieces() -> void:
	var pieces := _pieces("darwin")
	var one := _resolve(EARTH, "earth", [pieces[0]])
	var two := _resolve(EARTH, "earth", [pieces[0], pieces[1]])
	var three := _resolve(EARTH, "earth", pieces)
	assert_float(one.stat("elem_dmg")).is_equal_approx(0.10, 0.0001)        # chỉ món Đầu
	assert_float(two.stat("elem_dmg")).is_equal_approx(0.20, 0.0001)        # + bộ 2 món
	assert_bool(two.params.has("status_mag:stone_god")).is_false()
	assert_float(three.params.get("status_mag:stone_god", 0.0)).is_equal_approx(0.05, 0.0001)
	assert_int(int(three.set_counts["set_darwin"])).is_equal(3)


func test_four_star_set_bonus() -> void:
	var blaze := [_eq("eq_stigma_top_blaze"), _eq("eq_stigma_mid_blaze"), _eq("eq_stigma_bot_blaze")]
	var lo := _resolve(FIRE, "fire", blaze)
	assert_float(lo.stat("elem_dmg")).is_equal_approx(0.05, 0.0001)
	assert_float(lo.vs_target.get("burn", 0.0)).is_equal_approx(0.04, 0.0001)


# ---------- "A → B": cộng dồn phần tăng (Q3) ----------

func test_param_increments_stack() -> void:
	var lo := _resolve(LIGHTNING, "lightning", [_eq("eq_weapon_twin_thunder"), _eq("eq_stigma_mid_franklin")])
	var cfg := load("res://data/characters/char_lightning_01_kit.tres") as LightningKitConfig
	var out := EquipmentResolver.apply_to_kit_config(cfg, lo) as LightningKitConfig
	assert_float(out.burst.atk_ratio).is_equal_approx(2.1, 0.0001)          # 150 + 40 + 20 = 210%
	assert_float(cfg.burst.atk_ratio).is_equal_approx(1.5, 0.0001)          # resource gốc không đổi
	var earth := _resolve(EARTH, "earth", [_eq("eq_weapon_unyielding_peak"), _eq("eq_stigma_mid_darwin")])
	var ecfg := EquipmentResolver.apply_to_kit_config(load("res://data/characters/char_earth_01_kit.tres"), earth) as EarthKitConfig
	assert_float(ecfg.bone_damage_reduction).is_equal_approx(0.04, 0.0001)  # 3 + 0.5 + 0.5 = 4% mỗi tầng
	assert_int(ecfg.full_bones).is_equal(4)


func test_weapon_cooldown_change_copies_skill() -> void:
	var c := load("res://data/characters/char_fire_01.tres") as CharacterDef
	var skills := c.load_skills()
	var lo := _resolve(FIRE, "fire", [_eq("eq_weapon_dusk_inferno")])
	var out := EquipmentResolver.apply_to_skills(skills, lo)
	assert_float((out["weapon"] as SkillDef).cooldown_sec).is_equal(10.0)
	assert_float((skills["weapon"] as SkillDef).cooldown_sec).is_equal(12.0)


# ---------- Trần (mục 3.4) ----------

func test_cap_shield_param() -> void:
	# Dòng 7: khiên từ hồi thừa 8% + vũ khí 4% + món Thân 2% = 14% → trần 12%.
	var lo := _resolve(LIGHT, "light", [_eq("eq_weapon_solar_verdict"), _eq("eq_stigma_mid_nightingale")])
	assert_float(lo.param_value("kit:shield_max_ratio", 0.08)).is_equal_approx(0.12, 0.0001)


func test_cap_damage_bonus() -> void:
	# Dòng 8: nhóm "tất cả ST" + "ST nguyên tố" (kể cả theo điều kiện) ≤ ×2.0.
	var lo := EquipmentResolver.Loadout.new()
	lo.rules = EquipmentResolver.default_rules()
	lo.stats = {"all_dmg": 0.6, "elem_dmg": 0.5}
	lo.vs_target = {"burn": 0.3}
	assert_float(lo.damage_bonus()).is_equal_approx(1.0, 0.0001)
	lo.stats = {"all_dmg": 0.1}
	assert_float(lo.damage_bonus(["burn"])).is_equal_approx(0.4, 0.0001)
	assert_float(lo.damage_bonus([])).is_equal_approx(0.1, 0.0001)


func test_cap_attack_speed_lifesteal_heal() -> void:
	var lo := EquipmentResolver.Loadout.new()
	lo.rules = EquipmentResolver.default_rules()
	lo.stats = {"atk_speed": 0.16, "lifesteal": 0.09, "heal_bonus": 0.7}
	assert_float(lo.attack_speed(0.55)).is_equal_approx(0.6, 0.0001)        # dòng 3
	assert_float(lo.attack_speed(0.10)).is_equal_approx(0.26, 0.0001)
	assert_float(lo.lifesteal()).is_equal_approx(0.09, 0.0001)              # dòng 5
	assert_float(lo.kit_lifesteal(0.30)).is_equal_approx(0.21, 0.0001)      # kit + trang bị ≤ 30%
	assert_float(lo.heal_bonus()).is_equal_approx(0.5, 0.0001)              # dòng 6


func test_cap_full_noctis_lifesteal() -> void:
	# Dòng 5: Yomigari đeo đủ vũ khí + bộ Poe: phần trang bị + kit vẫn ≤ 30%.
	var lo := _resolve(DARK, "dark", [_eq("eq_weapon_crescent_pact")] + _pieces("poe"))
	var kit_max := 0.06 + 0.10 + 0.08 + 0.10   # Nguyền + skill vũ khí + Dạ Vương … (cộng hết nguồn)
	assert_float(lo.lifesteal() + lo.kit_lifesteal(kit_max)).is_less_equal(0.3 + 0.0001)


func test_cap_cooldown_floor() -> void:
	# Dòng 1: CD 10 s (sau vũ khí), CDR 40% → chu kỳ 6 s; rút CD riêng không xuống dưới 5 s.
	var cd := CooldownController.new(load("res://data/config/combat_rules.tres"))
	cd.cdr = 0.4
	cd.register(&"weapon", 10.0)
	cd.set_floor(&"weapon", 0.5)
	assert_bool(cd.trigger(&"weapon")).is_true()
	for i in 10:
		cd.reduce(&"weapon", 3.0)
	assert_float(cd.remaining(&"weapon")).is_equal_approx(5.0, 0.0001)
	cd.tick(5.0)
	assert_bool(cd.is_ready(&"weapon")).is_true()                            # không âm, sẵn sàng đúng lúc


func test_cap_damage_taken_floor() -> void:
	# Dòng 4: Iwagane bật hết nguồn giảm ST nhận: vẫn nhận ≥ 20%.
	var rules: CombatRules = load("res://data/config/combat_rules.tres")
	var t := DamageCalculator.Target.new()
	t.def = 0.0
	t.damage_taken_down = {"stone_bone": 0.2, "stone_god": 0.45, "earth_guard": 0.35, "equip": 0.2, "sanctuary": 0.3}
	var a := DamageCalculator.Attacker.from_rules(rules, 1000.0)
	a.crit_rate = 0.0
	var r := DamageCalculator.compute(rules, a, t, 1.0, 1, RandomSource.new(7))
	assert_float(r.taken).is_equal_approx(0.2, 0.0001)
	assert_int(r.amount).is_greater(0)


func test_team_buff_same_id_not_stacked() -> void:
	# Dòng 15: 2 người đeo cùng hiệu ứng toàn đội (cùng ID) chỉ lấy mức cao nhất; khác ID thì cộng.
	var w := _eq("eq_weapon_dusk_inferno")
	var a := _resolve(FIRE, "fire", [w])
	var b := _resolve(FIRE, "fire", [w])
	var c := _resolve(LIGHT, "light", [_eq("eq_weapon_solar_verdict")])
	var total := EquipmentResolver.merge_team([a, b, c])
	assert_float(total.get("all_dmg", 0.0)).is_equal_approx(0.08, 0.0001)
	assert_float(total.get("heal_bonus", 0.0)).is_equal_approx(0.08, 0.0001)
	assert_float(c.stat("all_dmg")).is_equal_approx(0.08, 0.0001)            # người không đeo cũng nhận


# ---------- Áp vào trận ----------

class _Src:
	extends RefCounted
	var bonus := {}

	func status_bonus(param: String) -> float:
		return float(bonus.get(param, 0.0))


func test_status_duration_and_magnitude_bonus() -> void:
	var st := StatusController.new(StatusLibrary.load_dir())
	var src := _Src.new()
	src.bonus = {"status_dur:heat": 2.0, "status_mag:melt": 0.05}
	st.apply("heat", -1.0, -1.0, src)
	st.apply("melt", -1.0, -1.0, src)
	assert_float(st.remaining("heat")).is_equal_approx(8.0, 0.0001)          # Nhiệt 6 s → 8 s
	assert_float(st.magnitude("melt")).is_equal_approx(0.15, 0.0001)         # Nung chảy 10% → 15%
	var plain := StatusController.new(StatusLibrary.load_dir())
	plain.apply("heat")
	assert_float(plain.remaining("heat")).is_equal_approx(6.0, 0.0001)


func test_profile_stats_include_percent_effects() -> void:
	var data := TestTeam.three()
	var p := PlayerProfile.new(data)
	p.progression.unlock(EARTH)
	var def := load("res://data/characters/char_earth_01.tres") as CharacterDef
	var before := p.stats_of(EARTH)
	var uid := p.inventory.add_equipment("eq_stigma_bot_darwin")             # HP tối đa +12%
	p.inventory.data["inventory"]["equipment"][uid]["affixes"] = []          # bỏ phụ tố ngẫu nhiên (2026-11-15)
	assert_str(p.inventory.equip(EARTH, uid)).is_equal("")
	var after := p.stats_of(EARTH)
	var flat := _eq("eq_stigma_bot_darwin").atk
	assert_float(after.max_hp).is_equal_approx(round(before.max_hp * 1.12), 1.0)
	assert_float(after.atk).is_equal_approx(before.atk + flat, 1.0)
	assert_str(def.element).is_equal("earth")
	var lo := p.loadout_of(EARTH)
	assert_float(lo.stat("hp_pct")).is_equal_approx(0.12, 0.0001)


# ---------- Trong màn chơi ----------

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")


func test_loadout_reaches_battle() -> void:
	var data := TestTeam.three()          # Enkiba, Raikiba, Kazeyumi
	var p := PlayerProfile.new(data)
	assert_str(p.inventory.equip(FIRE, p.inventory.add_equipment("eq_weapon_dusk_inferno"))).is_equal("")
	var franklin := p.inventory.add_equipment("eq_stigma_mid_franklin")
	data["inventory"]["equipment"][franklin]["affixes"] = []                 # bỏ phụ tố ngẫu nhiên (2026-11-15)
	assert_str(p.inventory.equip(LIGHTNING, franklin)).is_equal("")
	var stage: Node2D = auto_free(STAGE_SCENE.instantiate())
	stage.spawn_enemies = false
	stage.stats_provider = p.stats_of
	stage.loadout_provider = p.loadout_of
	add_child(stage)
	var fire: PlayerController = stage.player
	var c: Combatant = fire.combatant
	# CD Kĩ năng vũ khí 12 → 10 s (đúng chủ sở hữu), sát thương trang bị, buff toàn đội.
	assert_float((fire.runner.skills["weapon"] as SkillDef).cooldown_sec).is_equal(10.0)
	assert_float(c.attacker_snapshot().damage_bonus.get(Combatant.EQUIP_KEY, 0.0)).is_equal_approx(0.15 + 0.08 + 0.08, 0.0001)
	var kael: CharacterRuntime = stage.party.members[1]
	assert_float(kael.combatant().equip.stat("all_dmg")).is_equal_approx(0.08, 0.0001)   # toàn đội +8% từ vũ khí Enkiba
	assert_float((kael.controller.kit.config as LightningKitConfig).burst.atk_ratio).is_equal_approx(1.7, 0.0001)
	# Nung chảy từ Enkiba: −15% DEF (10% + 5%).
	var dummy := Combatant.new()
	dummy.auto_setup = false
	auto_free(dummy)
	dummy.setup()
	dummy.statuses.apply("melt", -1.0, -1.0, c)
	assert_float(dummy.statuses.magnitude("melt")).is_equal_approx(0.15, 0.0001)
