extends GdUnitTestSuite
## Hub mới (owner 2026-11-14): tab Trang chủ có thẻ người chơi + cụm nút lục giác; các màn Túi đồ, Tiếp tế, Xuất kích,
## Người cộng tác, Thông tin người chơi; tên người chơi (save v4).

const HUB_SCENE := preload("res://scenes/main/hub.tscn")
const SAVE_DIR := "user://test_saves_hub_home"

var _save: Node
var _old_store: SaveStore
var _old_data: Dictionary


func before_test() -> void:
	_save = get_tree().root.get_node("SaveService")
	_old_store = _save.store
	_old_data = _save.data
	_save.store = SaveStore.new(SAVE_DIR)
	_save.store.delete_all()
	_save.data = SaveSchema.default_data()


func after_test() -> void:
	_save.store.delete_all()
	DirAccess.remove_absolute(SAVE_DIR)
	_save.store = _old_store
	_save.data = _old_data
	GameConfig.hub_start_tab = ""
	GameConfig.selected_stage_id = "stage_01"


func _profile_with_items() -> PlayerProfile:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var flame := p.inventory.add_equipment("eq_weapon_flame")
	p.inventory.equip("char_fire_01", flame)
	p.inventory.add_equipment("eq_weapon_iron")
	p.inventory.add_equipment("eq_stigma_top_blaze")
	p.inventory.add_material("mat_exp_small", 5)
	p.progression.add_fragments("char_fire_01", 3)
	return p


func _screen(scene: PackedScene, p: PlayerProfile = null) -> HubScreen:
	var s := scene.instantiate() as HubScreen
	s.profile = p if p else PlayerProfile.new(SaveSchema.default_data())
	s.save_enabled = false
	s.navigate_enabled = false
	add_child(auto_free(s))
	return s


# ---------- Save v4: tên người chơi ----------

func test_save_v4_player_name() -> void:
	assert_int(SaveSchema.VERSION).is_equal(4)
	var old := SaveSchema.default_data()
	old["account"].erase("name")
	var m: Dictionary = SaveSchema.migrate(old, 3)
	assert_str(str(m["account"]["name"])).is_equal("")
	assert_str(SaveSchema.clean_name("  An   Hikaru \u0007 ")).is_equal("An Hikaru")
	assert_int(SaveSchema.clean_name("x".repeat(40)).length()).is_equal(SaveSchema.NAME_MAX)
	var d := SaveSchema.default_data()
	d["account"]["name"] = 42
	assert_str(str(SaveSchema.sanitize(d)["account"]["name"])).is_equal("")


func test_set_player_name_reasons() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	assert_str(p.player_name()).is_equal("")
	assert_str(p.set_player_name("   ")).is_equal(PlayerProfile.NAME_EMPTY)
	assert_str(p.set_player_name("y".repeat(SaveSchema.NAME_MAX + 1))).is_equal(PlayerProfile.NAME_TOO_LONG)
	assert_str(p.set_player_name(" Hikaru ")).is_equal(PlayerProfile.NAME_OK)
	assert_str(p.player_name()).is_equal("Hikaru")
	assert_str(p.set_player_name("Hikaru")).is_equal(PlayerProfile.NAME_SAME)


# ---------- Trang chủ ----------

func test_home_has_hex_cluster_and_player_card() -> void:
	var hub := HUB_SCENE.instantiate()
	add_child(auto_free(hub))
	await get_tree().process_frame
	assert_bool(hub.get_node("TopBar/TabBar").has_node("CharactersTab")).is_false()      # thay bằng nút lục giác
	var home := hub.panel as HubHomePanel
	assert_object(home).is_not_null()
	home.navigate_enabled = false
	assert_array(home.hex_buttons.keys()).contains_exactly_in_any_order(
			["equipment", "companion", "sortie", "character", "supply"])
	var expected := {"equipment": GameConfig.SCENE_BAG, "companion": GameConfig.SCENE_COMPANION,
			"sortie": GameConfig.SCENE_SORTIE, "character": GameConfig.SCENE_CHARACTER, "supply": GameConfig.SCENE_SUPPLY}
	var rects: Array[Rect2] = []
	for k: String in expected:
		var b := home.hex_buttons[k] as HexButton
		assert_object(b.icon).override_failure_message(k).is_not_null()
		b.pressed.emit()
		assert_str(home.last_target).is_equal(expected[k])
		rects.append(b.get_global_rect())
	assert_float((home.hex_buttons["sortie"] as HexButton).size.y).is_greater((home.hex_buttons["equipment"] as HexButton).size.y)
	home.player_card.pressed.emit()
	assert_str(home.last_target).is_equal(GameConfig.SCENE_PLAYER)
	assert_str(home.display_name()).is_equal(tr("PLAYER_DEFAULT_NAME"))
	# Nút lục giác nằm nửa phải màn hình, không đè thẻ người chơi.
	for r in rects:
		assert_float(r.position.x).is_greater(960.0)
		assert_bool(r.intersects(home.player_card.get_global_rect())).is_false()


func test_hex_button_hit_test_is_hexagonal() -> void:
	var b: HexButton = auto_free(HexButton.new())
	b.size = Vector2(200.0 * sqrt(3.0), 400.0)
	add_child(b)
	assert_bool(b._has_point(b.size * 0.5)).is_true()
	assert_bool(b._has_point(Vector2(2, 2))).is_false()                                 # góc khung, ngoài lục giác


func test_hub_opens_requested_start_tab() -> void:
	GameConfig.hub_start_tab = "BattleTab"
	var hub := HUB_SCENE.instantiate()
	add_child(auto_free(hub))
	await get_tree().process_frame
	assert_str(hub.current_tab).is_equal("BattleTab")
	assert_str(GameConfig.hub_start_tab).is_equal("")


# ---------- Túi đồ ----------

func test_bag_lists_each_category() -> void:
	var s := _screen(load(GameConfig.SCENE_BAG), _profile_with_items()) as BagScreen
	assert_int(s.entries("weapon").size()).is_equal(2)
	assert_int(s.entries("stigma").size()).is_equal(1)
	assert_int(s.entries("material").size()).is_equal(1)
	assert_int(s.entries("fragment").size()).is_equal(1)
	var first: Dictionary = s.entries("weapon")[0]
	assert_str(str(first["in_use_by"])).is_equal("char_fire_01")                         # đang dùng xếp trước
	assert_int(s.cards.size()).is_equal(2)
	s.select("equipment", str(first["id"]))
	assert_str(s.detail_text()).contains(tr("BAG_IN_USE"))
	s.set_category("material")
	assert_str(s.entries("material")[0]["level_text"]).is_equal("×5")
	var empty := _screen(load(GameConfig.SCENE_BAG)) as BagScreen
	assert_bool(empty.find_child("Empty", true, false) != null).is_true()


# ---------- Tiếp tế, Xuất kích ----------

func test_supply_routes_gacha_and_blocks_topup_offline() -> void:
	var s := _screen(load(GameConfig.SCENE_SUPPLY)) as SupplyScreen
	assert_array(s.action_buttons.keys()).contains_exactly_in_any_order(["shop", "gacha", "topup"])
	s.activate("gacha")
	assert_str(s.last_target).is_equal(GameConfig.SCENE_RECRUIT)
	s.activate("topup")
	assert_str(s.notice).is_equal(tr("SUPPLY_TOPUP_OFFLINE"))
	s.activate("shop")
	assert_str(s.notice).is_equal(tr("UI_COMING_SOON"))


func test_sortie_cards() -> void:
	var s := _screen(load(GameConfig.SCENE_SORTIE)) as SortieScreen
	assert_array(s.card_buttons.keys()).contains_exactly_in_any_order(["trial", "story", "material", "party"])
	GameConfig.selected_stage_id = ""
	s.activate("story")
	assert_str(GameConfig.selected_stage_id).is_equal("stage_01")
	assert_str(s.last_target).is_equal(GameConfig.SCENE_STAGE)
	s.activate("trial")
	assert_str(s.last_target).is_equal(GameConfig.SCENE_TEST_STAGE)
	s.activate("party")
	assert_str(GameConfig.hub_start_tab).is_equal("BattleTab")
	assert_str(s.last_target).is_equal(GameConfig.SCENE_HUB)
	s.activate("material")
	assert_str(s.notice).is_equal(tr("UI_COMING_SOON"))


func test_companion_screen_is_coming_soon() -> void:
	var s := _screen(load(GameConfig.SCENE_COMPANION))
	assert_object(s.find_child("Soon", true, false)).is_not_null()


# ---------- Thông tin người chơi ----------

func test_player_rename_and_collection() -> void:
	var p := _profile_with_items()
	var s := _screen(load(GameConfig.SCENE_PLAYER), p) as PlayerScreen
	s.open_rename()
	assert_object(s.name_edit).is_not_null()
	assert_str(s.rename("")).is_equal(PlayerProfile.NAME_EMPTY)
	assert_str(s.rename("Another Hikaru")).is_equal(PlayerProfile.NAME_OK)
	assert_str(p.player_name()).is_equal("Another Hikaru")
	assert_int(s.overlay).is_equal(PlayerScreen.Overlay.NONE)
	var weapons := s.collection_entries("weapon")
	var owned := weapons.filter(func(e: Dictionary) -> bool: return e["owned"]).size()
	assert_int(owned).is_equal(2)
	assert_int(weapons.size()).is_greater(owned)                                        # còn vũ khí chưa sở hữu
	assert_str(s.count_text("character")).is_equal("3/%d" % PlayerScreen.all_character_ids().size())
	s.open_collection("stigma")
	assert_object(s.find_child("CollectionBox", true, false)).is_not_null()
	assert_bool(s.intercept_back()).is_true()                                           # Back đóng bảng trước
	assert_int(s.overlay).is_equal(PlayerScreen.Overlay.NONE)
