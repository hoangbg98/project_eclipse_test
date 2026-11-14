extends GdUnitTestSuite
## Hiệu ứng trang bị theo sự kiện (EquipEffect TRIGGER), tham số lồng trong kỹ năng, thay đổi cơ chế kit
## (docs/design/EQUIPMENT_5STAR.md mục 6).

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")
const FIRE := "char_fire_01"
const LIGHTNING := "char_lightning_01"

var _p: PlayerProfile


func before_test() -> void:
	_p = PlayerProfile.new(TestTeam.three())             # Enkiba, Raikiba, Kazeyumi


func _eq(id: String) -> EquipmentDef:
	return PlayerProfile.equipment_defs().get_def(id) as EquipmentDef


func _wear(cid: String, ids: Array) -> void:
	for id in ids:
		assert_str(_p.inventory.equip(cid, _p.inventory.add_equipment(id))).is_equal("")


func _stage() -> Node2D:
	var stage: Node2D = auto_free(STAGE_SCENE.instantiate())
	stage.spawn_enemies = false
	stage.stats_provider = _p.stats_of
	stage.loadout_provider = _p.loadout_of
	add_child(stage)
	return stage


func _member(stage: Node2D, i: int) -> PlayerController:
	return (stage.party.members[i] as CharacterRuntime).controller


func _hit(skill_id: String, killed := false, before := PackedStringArray()) -> HitInfo:
	var h := HitInfo.new()
	h.hit_id = randi()
	h.skill_id = skill_id
	h.killed_target = killed
	h.target_statuses_before = before
	return h


func _enemy() -> Combatant:
	var c := Combatant.new()
	c.auto_setup = false
	c.team = PhysicsLayers.Team.ENEMY
	auto_free(c)
	c.setup()
	return c


# ---------- Dữ liệu ----------

func test_trigger_buffs_exist() -> void:
	var lib := StatusLibrary.load_dir()
	assert_array(lib.errors).is_empty()
	var n := 0
	for id in PlayerProfile.equipment_defs().ids():
		for e in _eq(id).effects:
			if e.kind == EquipEffect.Kind.TRIGGER:
				n += 1
				if e.action in ["buff", "self_status", "spread"]:
					assert_object(lib.get_status(e.status_id)).is_not_null()
	for sid in EquipmentResolver.set_defs().ids():
		var s := EquipmentResolver.set_defs().get_def(sid) as StigmaSetDef
		for e in s.bonus_2 + s.bonus_3:
			if e.kind == EquipEffect.Kind.TRIGGER:
				n += 1
				if e.action in ["buff", "self_status", "spread"]:
					assert_object(lib.get_status(e.status_id)).is_not_null()
	assert_int(n).is_greater(25)


# ---------- Tham số lồng trong kỹ năng ----------

func test_nested_skill_params() -> void:
	var light := load("res://data/characters/char_light_01.tres") as CharacterDef
	var lo := EquipmentResolver.resolve("char_light_01", "light", [_eq("eq_weapon_solar_verdict"),
			_eq("eq_stigma_top_nightingale"), _eq("eq_stigma_mid_nightingale"), _eq("eq_stigma_bot_nightingale")])
	var skills := EquipmentResolver.apply_to_skills(light.load_skills(), lo)
	var sk := skills["skill"] as SkillDef
	assert_int(sk.heals[0].cleanse).is_equal(2)                             # gỡ 2 hiệu ứng xấu
	assert_float(sk.heals[0].lowest_multiplier).is_equal_approx(1.5, 0.0001)
	assert_float(sk.heals[1].lowest_multiplier).is_equal_approx(1.5, 0.0001)
	assert_float((skills["weapon"] as SkillDef).heals[0].atk_ratio).is_equal_approx(0.9, 0.0001)
	assert_float((skills["ultimate"] as SkillDef).heals[0].max_hp_ratio).is_equal_approx(0.05, 0.0001)
	assert_int((light.load_skills()["skill"] as SkillDef).heals[0].cleanse).is_equal(1)   # resource gốc giữ nguyên

	var wind := load("res://data/characters/char_wind_01.tres") as CharacterDef
	var wlo := EquipmentResolver.resolve("char_wind_01", "wind", [_eq("eq_weapon_last_gale"),
			_eq("eq_stigma_top_davinci"), _eq("eq_stigma_mid_davinci"), _eq("eq_stigma_bot_davinci")])
	var ws := EquipmentResolver.apply_to_skills(wind.load_skills(), wlo)
	for h in (ws["weapon"] as SkillDef).hits:
		assert_float(h.bonus_vs_status_ratio).is_equal_approx(0.35, 0.0001)   # 25% → 35%
	var slow_found := false
	for h in (ws["skill"] as SkillDef).hits:
		for st in h.statuses:
			if st.status_id == "slow":
				slow_found = true
				assert_float(st.magnitude).is_equal_approx(0.25, 0.0001)        # Chậm trong vùng 20% → 25%
	assert_bool(slow_found).is_true()
	var ult := ws["ultimate"] as SkillDef
	assert_float(ult.hits[0].duration_ms).is_equal(7000.0)                    # bão +2 s
	assert_float(ult.hits[1].duration_ms).is_equal(120.0)                     # đòn khác không đổi


# ---------- Trong trận ----------

func test_fire_weapon_consumes_three_heat() -> void:
	_wear(FIRE, ["eq_weapon_dusk_inferno"])
	var fire := _member(_stage(), 0)
	for i in 5:
		fire.combatant.statuses.apply("heat", -1.0, -1.0, fire.combatant)
	assert_int(fire.combatant.statuses.stacks("heat")).is_equal(5)
	var bonus: Dictionary = fire.kit._bonus_for(fire.runner.skills["weapon"])
	assert_float(bonus.get("heat_full", 0.0)).is_equal_approx(0.25, 0.0001)
	assert_int(fire.combatant.statuses.stacks("heat")).is_equal(2)            # tiêu 3, giữ 2 (Q2)
	assert_float(fire.combatant.statuses.remaining("heat")).is_equal_approx(6.0, 0.01)


func test_ultimate_buff_and_team_heat_buff() -> void:
	_wear(FIRE, ["eq_weapon_dusk_inferno"])
	var stage := _stage()
	var fire := _member(stage, 0)
	var kael := _member(stage, 1)
	fire.runner.skill_started.emit("ultimate", fire.runner.skills["ultimate"])
	assert_bool(fire.combatant.statuses.has("eqb_dusk_ult")).is_true()
	assert_bool(kael.combatant.statuses.has("eqb_dusk_ult")).is_false()       # buff riêng người đeo
	# ≥ 3 Nhiệt: toàn đội +8% (liên tục), kể cả dự bị.
	for i in 3:
		fire.combatant.statuses.apply("heat", -1.0, -1.0, fire.combatant)
	fire.equip_triggers.tick(0.016)
	assert_bool(kael.combatant.statuses.has("eqb_dusk_heat_team")).is_true()
	fire.combatant.statuses.remove("heat")
	for i in 30:
		fire.equip_triggers.tick(0.016)
		kael.combatant.statuses.tick(0.016)
	assert_bool(kael.combatant.statuses.has("eqb_dusk_heat_team")).is_false() # hết điều kiện → tự tắt


func test_team_fire_buff_only_for_fire_members_with_icd() -> void:
	_wear(FIRE, ["eq_weapon_dusk_inferno"])
	var stage := _stage()
	var fire := _member(stage, 0)
	var kael := _member(stage, 1)
	var target := _enemy()
	fire.runner.skill_started.emit("weapon", fire.runner.skills["weapon"])
	fire.combatant.hit_dealt.emit(target, DamageCalculator.Result.new(), _hit("char_fire_01.weapon"))
	assert_bool(fire.combatant.statuses.has("eqb_dusk_fire_team")).is_true()
	assert_bool(kael.combatant.statuses.has("eqb_dusk_fire_team")).is_false() # chỉ nhân vật hệ Hỏa
	var i := fire.equip_triggers.effects.find(fire.equip_triggers.effects.filter(
			func(e: EquipEffect) -> bool: return e.status_id == "eqb_dusk_fire_team")[0])
	assert_int(int(fire.equip_triggers.fired[i])).is_equal(1)
	fire.runner.skill_started.emit("weapon", fire.runner.skills["weapon"])
	fire.combatant.hit_dealt.emit(target, DamageCalculator.Result.new(), _hit("char_fire_01.weapon"))
	assert_int(int(fire.equip_triggers.fired[i])).is_equal(1)                 # ICD 10 s


func test_equipment_buffs_share_damage_cap() -> void:
	_wear(FIRE, ["eq_weapon_dusk_inferno"])
	var fire := _member(_stage(), 0)
	var c := fire.combatant
	var base := c.equip_damage([], PackedStringArray())
	c.statuses.apply("eqb_dusk_ult", 6.0, 0.06, c)
	assert_float(c.equip_damage([], PackedStringArray())).is_equal_approx(base + 0.06, 0.0001)
	c.statuses.apply("eqb_lavoisier_ult", 8.0, 0.9, c)
	assert_float(c.equip_damage([], PackedStringArray())).is_equal_approx(1.0, 0.0001)   # trần ×2.0
	c.statuses.apply("eqb_crescent_curse_team", 6.0, 0.08, c)
	assert_float(c.statuses.equipment_damage_up(PackedStringArray()) ).is_equal_approx(0.96, 0.0001)
	assert_float(c.statuses.equipment_damage_up(PackedStringArray(["curse"]))).is_equal_approx(1.04, 0.0001)


func test_low_hp_guard_has_buffer() -> void:
	_wear(FIRE, ["eq_stigma_top_darwin", "eq_stigma_mid_darwin"])             # bộ 2 món: dưới 50% HP giảm 8% ST nhận
	var fire := _member(_stage(), 0)
	var r := fire.combatant.resources
	r.take_damage(r.max_hp * 0.6)                                           # còn 40%
	fire.equip_triggers.tick(0.016)
	assert_bool(fire.combatant.statuses.has("eqb_darwin_low_hp")).is_true()
	r.heal(r.max_hp * 0.12)                                                 # 52%: trong vùng đệm, vẫn bật
	fire.combatant.statuses.tick(0.5)
	fire.equip_triggers.tick(0.016)
	assert_bool(fire.combatant.statuses.has("eqb_darwin_low_hp")).is_true()
	r.heal(r.max_hp * 0.05)                                                 # 57% > 55%: tắt
	fire.combatant.statuses.tick(0.5)
	fire.equip_triggers.tick(0.016)
	assert_bool(fire.combatant.statuses.has("eqb_darwin_low_hp")).is_false()


func test_kill_heal_and_curse_buff_condition() -> void:
	_wear(FIRE, ["eq_stigma_top_poe", "eq_stigma_mid_poe"])                   # bộ 2 món: hạ gục hồi 3% HP
	var fire := _member(_stage(), 0)
	var r := fire.combatant.resources
	r.take_damage(r.max_hp * 0.5)
	var before := r.hp
	fire.combatant.hit_dealt.emit(_enemy(), DamageCalculator.Result.new(), _hit("char_fire_01.normal_1", true))
	assert_float(r.hp - before).is_equal_approx(r.max_hp * 0.03, 1.0)
	fire.combatant.hit_dealt.emit(_enemy(), DamageCalculator.Result.new(), _hit("char_fire_01.normal_1", true))
	assert_float(r.hp - before).is_equal_approx(r.max_hp * 0.03, 1.0)       # ICD 2 s


func test_lightning_burst_gives_en() -> void:
	_wear(LIGHTNING, ["eq_weapon_twin_thunder"])
	var stage := _stage()
	var kael := _member(stage, 1)
	var bus := get_tree().root.get_node_or_null("EventBus")
	assert_object(bus).is_not_null()
	var en := kael.combatant.resources.en
	bus.status_max_stacks.emit(_enemy(), "lightning_mark", kael.combatant)
	assert_float(kael.combatant.resources.en - en).is_greater_equal(8.0)
	assert_bool(_member(stage, 0).combatant.statuses.has("eqb_thunder_aspd_team")).is_true()   # toàn đội


func test_incoming_burn_duration_shorter() -> void:
	_wear(FIRE, ["eq_stigma_mid_lavoisier"])                                  # Thời gian bị Cháy −30% (hệ Hỏa)
	var fire := _member(_stage(), 0)
	fire.combatant.statuses.apply("burn", 4.0, -1.0, null)
	assert_float(fire.combatant.statuses.remaining("burn")).is_equal_approx(2.8, 0.0001)


func test_stone_shield_from_earth_guard_skill() -> void:
	# Khiên Đá = khiên của Giáp Địa (Kĩ năng thường Iwagane, owner 2026-11-15): 20% → 25%, trần 25% (mục 3.4 dòng 7).
	var earth := load("res://data/characters/char_earth_01.tres") as CharacterDef
	var lo := EquipmentResolver.resolve("char_earth_01", "earth", [_eq("eq_stigma_top_darwin"), _eq("eq_stigma_mid_darwin")])
	var sk := EquipmentResolver.apply_to_skills(earth.load_skills(), lo)["skill"] as SkillDef
	for st in sk.self_statuses:
		if st.status_id == "shield":
			assert_float(st.magnitude).is_equal_approx(0.25, 0.0001)
		elif st.status_id == "earth_guard":
			assert_float(st.magnitude).is_equal_approx(0.35, 0.0001)        # Giáp Địa giữ nguyên
	lo.params["skill:skill:self_statuses@shield.magnitude"] = 0.2           # cộng quá tay vẫn bị chặn
	sk = EquipmentResolver.apply_to_skills(earth.load_skills(), lo)["skill"] as SkillDef
	for st in sk.self_statuses:
		if st.status_id == "shield":
			assert_float(st.magnitude).is_equal_approx(0.25, 0.0001)
