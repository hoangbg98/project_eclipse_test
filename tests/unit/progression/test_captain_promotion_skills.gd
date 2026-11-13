extends GdUnitTestSuite
## Test: cấp đội trưởng giới hạn cấp nhân vật, mảnh + tiến cấp, cấp kỹ năng (vào trận), 1 vũ khí + 3 vết thánh,
## loại vũ khí theo nhân vật, migration save v2 → v3.

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")
const A := "char_fire_01"

var _data: Dictionary
var _p: PlayerProfile


func before_test() -> void:
	_data = SaveSchema.default_data()
	_p = PlayerProfile.new(_data)


# ---------- Cấp đội trưởng ----------

func test_character_level_capped_by_captain_level() -> void:
	assert_int(_p.progression.captain_level()).is_equal(1)
	_p.progression.add_exp(A, 10000)
	assert_int(_p.progression.level_of(A)).is_equal(1)                # đội trưởng cấp 1: nhân vật đứng ở cấp 1
	assert_int(_p.progression.exp_of(A)).is_equal(100)               # thanh EXP đầy, chờ
	assert_bool(_p.progression.is_capped(A)).is_true()
	_p.progression.add_captain_exp(50 + 141)                          # đội trưởng lên cấp 3
	assert_int(_p.progression.captain_level()).is_equal(3)
	assert_int(_p.progression.level_of(A)).is_equal(2)               # EXP đã giữ đẩy nhân vật lên ngay
	_p.progression.add_exp(A, 5000)
	assert_int(_p.progression.level_of(A)).is_equal(3)


func test_exp_book_refused_when_capped() -> void:
	_p.inventory.add_currency("gold", 10000)
	_p.inventory.add_material("mat_exp_medium", 2)
	assert_str(_p.progression.use_exp_material(A, "mat_exp_medium", 1)).is_equal("")   # lấp đầy thanh
	assert_str(_p.progression.use_exp_material(A, "mat_exp_medium", 1)).is_equal(Inventory.REASON_LEVEL_CAP)
	assert_int(_p.inventory.material_count("mat_exp_medium")).is_equal(1)


func test_stage_reward_raises_captain_before_characters() -> void:
	var got := _p.grant({"captain_exp": 400, "exp": 600})
	assert_int(got["captain_levels"]).is_equal(2)                     # 1 → 3
	assert_int(_p.progression.level_of(A)).is_equal(3)                # 600 EXP: 100 + 283, chạm cấp 3


# ---------- Mảnh, tiến cấp ----------

func test_promotion_uses_fragments_and_raises_stats() -> void:
	var def: CharacterDef = load("res://data/characters/char_fire_01.tres")
	assert_str(_p.progression.rank_label(def)).is_equal("S")
	assert_str(_p.progression.promote(A)).is_equal(Inventory.REASON_NOT_ENOUGH)
	_p.progression.add_fragments(A, 12)
	assert_str(_p.progression.promote(A)).is_equal("")
	assert_int(_p.progression.fragments_of(A)).is_equal(2)
	assert_str(_p.progression.rank_label(def)).is_equal("S1")
	assert_float(_p.stats_of(A).atk).is_equal(1050.0)                 # +5% mỗi bước
	_p.progression.add_fragments(A, 100)
	_p.progression.promote(A)
	assert_int(_p.progression.fragments_to_promote(A)).is_equal(25)   # S2 → S3 cần 25 (như ảnh tham chiếu)
	_p.progression.promote(A)
	assert_str(_p.progression.rank_label(def)).is_equal("S3")
	assert_str(_p.progression.promote(A)).is_equal(Inventory.REASON_MAX_LEVEL)


# ---------- Cấp kỹ năng ----------

func test_skill_upgrade_costs_gold_and_caps() -> void:
	assert_int(_p.progression.skill_level(A, "skill")).is_equal(1)
	assert_str(_p.progression.upgrade_skill(A, "skill")).is_equal(Inventory.REASON_NOT_ENOUGH)
	_p.inventory.add_currency("gold", 1_000_000)
	assert_str(_p.progression.upgrade_skill(A, "skill")).is_equal("")
	assert_int(_p.inventory.currency("gold")).is_equal(1_000_000 - 500)
	assert_int(_p.progression.skill_level(A, "skill")).is_equal(2)
	for i in 20:
		_p.progression.upgrade_skill(A, "skill")
	assert_int(_p.progression.skill_level(A, "skill")).is_equal(10)
	assert_str(_p.progression.upgrade_skill(A, "skill")).is_equal(Inventory.REASON_MAX_LEVEL)
	assert_str(_p.progression.upgrade_skill(A, "nope")).is_equal(Inventory.REASON_INVALID)
	var by_key := _p.skill_levels_of(A)
	assert_int(by_key["skill"]).is_equal(10)
	assert_int(by_key["hold"]).is_equal(1)


func test_skill_level_reaches_hits_in_battle() -> void:
	_p.inventory.add_currency("gold", 1_000_000)
	for i in 3:
		_p.progression.upgrade_skill(A, "normal")                     # cấp 4: ×1.18
	var stage: Node2D = auto_free(STAGE_SCENE.instantiate())
	stage.spawn_enemies = false
	stage.party_ids = PackedStringArray([A])
	stage.skill_levels_provider = _p.skill_levels_of
	add_child(stage)
	var pl: PlayerController = stage.player
	pl.use_player_input = false
	pl.combatant.rng = RandomSource.Fixed.new(0.99)
	pl.global_position = Vector2(820, 896)
	pl.facing = 1
	for i in 20:
		await get_tree().physics_frame
	var levels := []
	stage.dummies[0].combatant.damaged.connect(func(_r: DamageCalculator.Result, h: HitInfo) -> void: levels.append(h.skill_level))
	pl.intent.tap_attack(pl.config.jump_buffer_time)
	for i in 40:
		await get_tree().physics_frame
		if not levels.is_empty():
			break
	assert_array(levels).is_not_empty()
	assert_int(levels[0]).is_equal(4)


# ---------- Trang bị ----------

func test_four_slots_and_weapon_type_rule() -> void:
	assert_array(Array(EquipmentDef.SLOTS)).is_equal(["weapon", "stigma_top", "stigma_mid", "stigma_bot"])
	var bow := _p.inventory.add_equipment("eq_weapon_bow_gale")
	var sword := _p.inventory.add_equipment("eq_weapon_iron")
	assert_str(_p.inventory.equip(A, bow)).is_equal(Inventory.REASON_WRONG_WEAPON)   # Aether dùng kiếm
	assert_str(_p.inventory.equip(A, sword)).is_equal("")
	assert_str(_p.inventory.equip("char_wind_01", bow)).is_equal("")
	for slot in EquipmentDef.STIGMA_SLOTS:                            # vết thánh: ai cũng mặc được
		var ids := {"stigma_top": "eq_stigma_top_elite", "stigma_mid": "eq_stigma_mid_hide", "stigma_bot": "eq_stigma_bot_hourglass"}
		assert_str(_p.inventory.equip(A, _p.inventory.add_equipment(ids[slot]))).is_equal("")
	assert_int(_data["characters"][A]["equipment"].size()).is_equal(4)


# ---------- Migration v2 → v3 ----------

func test_v2_save_migrates_equipment_and_adds_new_fields() -> void:
	var v2 := SaveSchema.default_data()
	v2.erase("account")
	v2["characters"][A] = {"level": 7, "exp": 3, "equipment": {"weapon": "1", "armor": "2", "accessory": "3"}}
	v2["inventory"]["equipment"] = {"1": {"def_id": "eq_weapon_flame", "level": 2},
			"2": {"def_id": "eq_armor_guardian", "level": 4}, "3": {"def_id": "eq_acc_ring", "level": 0}}
	v2["inventory"]["next_uid"] = 4
	var store := SaveStore.new("user://test_saves_v3")
	store.delete_all()
	DirAccess.make_dir_recursive_absolute("user://test_saves_v3")
	var f := FileAccess.open(store.path_of(SaveStore.MAIN), FileAccess.WRITE)
	f.store_string(SaveStore.encode(v2, 2))
	f.close()
	var d := store.read()
	assert_int(store.last_status).is_equal(SaveStore.Status.OK)
	var c: Dictionary = d["characters"][A]
	assert_dict(c["equipment"]).is_equal({"weapon": "1", "stigma_mid": "2", "stigma_top": "3"})
	assert_str(d["inventory"]["equipment"]["2"]["def_id"]).is_equal("eq_stigma_mid_guardian")
	assert_int(int(d["inventory"]["equipment"]["2"]["level"])).is_equal(4)          # giữ cấp cường hóa
	assert_int(c["fragments"]).is_equal(0)
	assert_int(c["promotion"]).is_equal(0)
	assert_int(d["account"]["level"]).is_equal(7)                     # đội trưởng = cấp cao nhất cũ: không bị khóa
	var p := PlayerProfile.new(d)
	assert_float(p.stats_of(A).max_hp).is_greater(12000.0)
	store.delete_all()
	DirAccess.remove_absolute("user://test_saves_v3")
