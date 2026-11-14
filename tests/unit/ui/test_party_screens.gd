extends GdUnitTestSuite
## Chuỗi vào màn (owner 2026-11-14): thông tin màn + mục tiêu → đội hình (splash) → chọn giáp (lưới + 3 vị trí idle).


func after_test() -> void:
	GameConfig.selected_stage_id = "stage_01"
	GameConfig.prep_launch_stage = false
	GameConfig.selected_character_id = ""


func _screen(path: String, p: PlayerProfile = null) -> HubScreen:
	var s := (load(path) as PackedScene).instantiate() as HubScreen
	s.profile = p if p else PlayerProfile.new(TestTeam.three())
	s.save_enabled = false
	s.navigate_enabled = false
	add_child(auto_free(s))
	return s


func test_stage_info_shows_objectives_drops_and_prepare() -> void:
	GameConfig.selected_stage_id = "stage_01"
	var p := PlayerProfile.new(TestTeam.three())
	p.data["progress"]["stages"]["stage_01"] = {"cleared": true, "best_time_sec": 100.0, "objectives": ["hits"]}
	var s := _screen(GameConfig.SCENE_STAGE_INFO, p) as StageInfoScreen
	assert_str(s.stage_id).is_equal("stage_01")
	assert_int(s.objective_rows.size()).is_equal(3)
	assert_array(s.objective_rows.map(func(o: Dictionary) -> bool: return o["achieved"])).is_equal([false, true, false])
	var kinds := s.drops().map(func(d: Dictionary) -> String: return d["kind"])
	assert_array(kinds).contains(["gold", "gems", "material", "equipment"])
	assert_object(s.find_child("PrepareButton", true, false)).is_not_null()
	s.prepare()
	assert_bool(GameConfig.prep_launch_stage).is_true()
	assert_str(s.last_target).is_equal(GameConfig.SCENE_PARTY_PREP)


func test_party_prep_slots_and_launch() -> void:
	GameConfig.prep_launch_stage = true
	var s := _screen(GameConfig.SCENE_PARTY_PREP) as PartyPrepScreen
	assert_bool(s.launch_stage).is_true()
	assert_int(s.slot_buttons.size()).is_equal(3)
	s.slot_buttons[1].pressed.emit()
	assert_str(s.last_target).is_equal(GameConfig.SCENE_PARTY_SELECT)
	(s.find_child("GoButton", true, false) as Button).pressed.emit()
	assert_str(s.last_target).is_equal(GameConfig.SCENE_STAGE)


func test_party_prep_edit_only_has_confirm() -> void:
	GameConfig.prep_launch_stage = false
	var p := PlayerProfile.new(TestTeam.three())
	p.set_party(["char_fire_01"])
	var s := _screen(GameConfig.SCENE_PARTY_PREP, p) as PartyPrepScreen
	assert_bool(s.launch_stage).is_false()
	assert_str((s.find_child("GoButton", true, false) as Button).text).is_equal(tr("PARTY_PREP_CONFIRM"))
	assert_object(s.find_child("StagePanel", true, false)).is_null()


func test_party_select_toggle_keeps_old_rules() -> void:
	var p := PlayerProfile.new(TestTeam.three())
	var s := _screen(GameConfig.SCENE_PARTY_SELECT, p) as PartySelectScreen
	var owned := s.owned_ids()
	assert_int(s.suit_buttons.size()).is_equal(owned.size())
	assert_int(s.stage_nodes.size()).is_equal(3)
	var party := Array(p.party_ids())
	assert_int(party.size()).is_equal(3)
	# Đội đủ 3: bỏ người thứ 2 rồi thêm lại → xuống cuối.
	var second: String = party[1]
	assert_str(s.toggle(second)).is_equal(PlayerProfile.PARTY_OK)
	assert_int(p.party_ids().size()).is_equal(2)
	assert_str(s.toggle(second)).is_equal(PlayerProfile.PARTY_OK)
	assert_str(p.party_ids()[2]).is_equal(second)
	# Bỏ tới người cuối thì từ chối, có thông báo.
	s.toggle(party[0])
	s.toggle(party[2])
	assert_str(s.toggle(second)).is_equal(PlayerProfile.PARTY_LAST)
	assert_str(s.notice).is_equal(tr("PARTY_ERR_LAST"))
	assert_int(p.party_ids().size()).is_equal(1)


func test_profile_toggle_party_rejects_full_same_person_unowned() -> void:
	var p := PlayerProfile.new(TestTeam.three())
	p.person_cache = {"char_fire_01": "a", "char_fire_02": "a", "char_wind_01": "b", "char_lightning_01": "c"}
	assert_str(p.toggle_party("char_light_01")).is_equal(PlayerProfile.PARTY_NOT_OWNED)
	p.progression.data["characters"]["char_fire_02"] = SaveSchema.default_character()
	assert_str(p.toggle_party("char_fire_02")).is_equal(PlayerProfile.PARTY_FULL)
	p.toggle_party("char_wind_01")
	assert_str(p.toggle_party("char_fire_02")).is_equal(PlayerProfile.PARTY_SAME_PERSON)


func test_character_art_fallbacks() -> void:
	assert_object(CharacterArt.splash("char_fire_01")).is_not_null()
	# Không có chân dung nhưng có frame idle → dùng frame idle.
	var idle := CharacterArt.idle("char_lightning_01")
	if not idle.is_empty():
		assert_object(CharacterArt.figure("char_lightning_01")).is_not_null()
	assert_object(CharacterArt.figure("no_such_char")).is_null()
	var tall := CharacterArt.top_crop(CharacterArt.splash("char_fire_01"), 0.8) as AtlasTexture
	assert_object(tall).is_not_null()
	assert_float(tall.region.size.x / tall.region.size.y).is_equal_approx(0.8, 0.01)
