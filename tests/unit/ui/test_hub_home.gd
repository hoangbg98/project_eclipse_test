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
	assert_int(SaveSchema.VERSION).is_greater_equal(4)
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


# ---------- Sảnh chính (bản 2: ô ghép, không thanh tab) ----------

func test_lobby_tiles_icons_and_no_tab_bar() -> void:
	var hub := HUB_SCENE.instantiate()
	add_child(auto_free(hub))
	await get_tree().process_frame
	assert_bool(hub.has_node("TopBar")).is_false()                                      # bỏ thanh tab ô vuông
	var home := hub.panel as HubHomePanel
	assert_object(home).is_not_null()
	home.navigate_enabled = false
	var texts := PackedStringArray()
	for l in home.find_children("*", "Label", true, false):
		texts.append((l as Label).text)
	assert_bool("\n".join(texts).contains("PROJECT ECLIPSE")).is_false()               # bỏ dòng tóm tắt cũ
	assert_object(home.find_child("Splash", true, false)).is_not_null()                # splash nhân vật bên trái
	assert_object(home.find_child("BackgroundArt", true, false)).is_not_null()         # nền đang chọn
	var expected := {"character": GameConfig.SCENE_CHARACTER, "sortie": GameConfig.SCENE_SORTIE,
			"equipment": GameConfig.SCENE_BAG, "supply": GameConfig.SCENE_SUPPLY, "companion": GameConfig.SCENE_COMPANION}
	assert_array(home.tiles.keys()).contains_exactly_in_any_order(expected.keys())
	var rects: Array[Rect2] = []
	for k: String in expected:
		var t := home.tiles[k] as TileButton
		assert_str(t.label_text).is_not_empty()
		t.pressed.emit()
		assert_str(home.last_target).is_equal(expected[k])
		rects.append(t.get_global_rect())
	for i in rects.size():
		assert_float(rects[i].position.x).is_greater(700.0)                              # nửa phải, nhường chỗ splash
		for j in range(i + 1, rects.size()):
			assert_bool(rects[i].intersects(rects[j])).is_false()
	home.player_card.pressed.emit()
	assert_str(home.last_target).is_equal(GameConfig.SCENE_PLAYER)
	# Bánh răng góc phải → bảng nổi Cài đặt; khung tranh → Đổi nền; Back đóng bảng nổi.
	var gear := home.icon_buttons["settings"] as Button
	assert_float(gear.get_global_rect().end.x).is_greater(1800.0)
	gear.pressed.emit()
	assert_str(hub.current_tab).is_equal("SettingsTab")
	assert_bool(hub.popup_open()).is_true()
	assert_bool(hub.intercept_back()).is_true()
	assert_bool(hub.popup_open()).is_false()
	(home.icon_buttons["background"] as Button).pressed.emit()
	assert_bool(hub.panel is HubBackgroundPanel).is_true()
	assert_bool(hub.intercept_back()).is_true()
	assert_bool(hub.intercept_back()).is_false()                                       # không còn bảng: để về Title


func test_tile_hit_test_is_parallelogram() -> void:
	var t: TileButton = auto_free(TileButton.new())
	t.size = Vector2(400, 300)
	t.skew = 40.0
	add_child(t)
	assert_bool(t._has_point(Vector2(200, 150))).is_true()
	assert_bool(t._has_point(Vector2(5, 5))).is_false()                                # góc trên-trái nằm ngoài (nghiêng)
	assert_bool(t._has_point(Vector2(395, 295))).is_false()                            # góc dưới-phải nằm ngoài


# ---------- Nền sảnh (save v5) ----------

func test_backgrounds_starter_buy_unlock_select() -> void:
	assert_int(SaveSchema.VERSION).is_greater_equal(5)
	var old := SaveSchema.default_data()
	old.erase("cosmetics")
	var m: Dictionary = SaveSchema.migrate(old, 4)
	assert_bool(m["cosmetics"] is Dictionary).is_true()
	var p := PlayerProfile.new(SaveSchema.default_data())
	assert_str(p.hub_background()).is_equal("bg_sky_garden")                          # nền khởi đầu
	assert_bool(p.owns_background("bg_sky_garden")).is_true()
	assert_str(p.set_hub_background("bg_khong_co")).is_equal(PlayerProfile.BG_UNKNOWN)
	assert_str(p.buy_background("bg_sky_garden")).is_equal(PlayerProfile.BG_OWNED)
	assert_bool(p.unlock_background("bg_sky_garden")).is_false()
	# Nền bán / nền sự kiện giả lập (thư viện nạp sẵn; không cần file trong data/).
	var shop_bg := BackgroundDef.new()
	shop_bg.id = "bg_test_shop"
	shop_bg.name_key = "BG_SKY_GARDEN"
	shop_bg.image = "res://x.png"
	shop_bg.price_gems = 300
	var event_bg := BackgroundDef.new()
	event_bg.id = "bg_test_event"
	event_bg.name_key = "BG_SKY_GARDEN"
	event_bg.image = "res://x.png"
	event_bg.source = BackgroundDef.Source.EVENT
	var lib := PlayerProfile.background_defs()
	lib.defs[shop_bg.id] = shop_bg
	lib.defs[event_bg.id] = event_bg
	assert_str(p.set_hub_background("bg_test_shop")).is_equal(PlayerProfile.BG_NOT_OWNED)
	assert_str(p.buy_background("bg_test_shop")).is_equal(PlayerProfile.BG_NO_GEMS)
	p.inventory.add_currency("gems", 500)
	assert_str(p.buy_background("bg_test_shop")).is_equal(PlayerProfile.BG_OK)
	assert_int(p.inventory.currency("gems")).is_equal(200)
	assert_str(p.set_hub_background("bg_test_shop")).is_equal(PlayerProfile.BG_OK)
	assert_str(p.hub_background()).is_equal("bg_test_shop")
	assert_str(p.buy_background("bg_test_event")).is_equal(PlayerProfile.BG_NOT_FOR_SALE)
	assert_bool(p.unlock_background("bg_test_event")).is_true()                         # phần thưởng sự kiện
	assert_bool(p.owns_background("bg_test_event")).is_true()
	# Bảng Đổi nền: nút theo trạng thái.
	_save.data = p.data
	var panel := HubBackgroundPanel.new()
	add_child(auto_free(panel))
	assert_bool((panel.action_buttons["bg_test_shop"] as Button).disabled).is_true()   # đang dùng
	assert_str(panel.use("bg_sky_garden")).is_equal(PlayerProfile.BG_OK)
	assert_str(p.data["cosmetics"]["hub_background"]).is_equal("bg_sky_garden")
	lib.defs.erase(shop_bg.id)
	lib.defs.erase(event_bg.id)


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
	assert_str(tr("SUPPLY_GACHA_TITLE")).is_equal(tr("HUB_TAB_RECRUIT"))                # ô thứ 2 tên Chiêu mộ
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
	assert_str(s.last_target).is_equal(GameConfig.SCENE_STORY_CLIP)   # lần đầu: clip mở chương
	s.activate("trial")
	assert_str(s.last_target).is_equal(GameConfig.SCENE_TEST_STAGE)
	GameConfig.prep_launch_stage = true
	s.activate("party")
	assert_bool(GameConfig.prep_launch_stage).is_false()
	assert_str(s.last_target).is_equal(GameConfig.SCENE_PARTY_PREP)
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
	assert_str(s.count_text("character")).is_equal("1/%d" % PlayerScreen.all_character_ids().size())
	s.open_collection("stigma")
	assert_object(s.find_child("CollectionBox", true, false)).is_not_null()
	assert_bool(s.intercept_back()).is_true()                                           # Back đóng bảng trước
	assert_int(s.overlay).is_equal(PlayerScreen.Overlay.NONE)
