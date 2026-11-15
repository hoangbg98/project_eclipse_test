extends GdUnitTestSuite
## Test màn Nhân vật (6 ảnh tham chiếu owner 2026-11-12): bố cục đọc từ JSON, tổng quan + đổi nhân vật, 4 tab,
## chi tiết kỹ năng, nâng cấp, trang bị qua bảng chọn, lùi từng bước, lưu sau thao tác.

const SCREEN_SCENE := preload("res://scenes/main/character_screen.tscn")
const SAVE_DIR := "user://test_saves_char_screen"
const A := "char_fire_01"
const L := "char_wind_01"

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
	_save.data["account"]["level"] = 50


func after_test() -> void:
	_save.store.delete_all()
	DirAccess.remove_absolute(SAVE_DIR)
	_save.store = _old_store
	_save.data = _old_data


func _screen() -> CharacterScreen:
	var s: CharacterScreen = auto_free(SCREEN_SCENE.instantiate())
	add_child(s)
	_resize(s, Vector2(1920, 1080))
	return s


## Màn neo kín khung cha; trong test cha là Node nên đặt kích thước tay (bỏ neo để Godot không cảnh báo).
func _resize(s: CharacterScreen, sz: Vector2) -> void:
	s.set_anchors_preset(Control.PRESET_TOP_LEFT)
	s.size = sz


func _node(s: CharacterScreen, name_: String) -> Control:
	return s.find_child(name_, true, false) as Control


func _texts(n: Node) -> String:
	var out := PackedStringArray()
	for c in n.find_children("*", "Label", true, false):
		out.append((c as Label).text)
	for c in n.find_children("*", "Button", true, false):
		out.append((c as Button).text)
	return "\n".join(out)


func _disk() -> Dictionary:
	return SaveStore.new(SAVE_DIR).read()


# ---------- Bố cục ----------

func test_layout_file_is_valid_and_complete() -> void:
	var l := UiLayout.load_from(CharacterScreen.LAYOUT_PATH)
	assert_array(Array(l.errors)).is_empty()
	assert_vector(l.design_size).is_equal(Vector2(1920, 1080))
	for path in ["overview.character_art", "overview.title", "overview.weapon_card", "overview.roster", "detail.tab_bar",
			"level_tab.exp_bar", "weapon_tab.art", "stigma_tab.set_text", "skill_detail.panel", "skill_detail.description",
			"weapon_detail.art", "weapon_detail.skill_text", "weapon_detail.enhance_button", "weapon_detail.ascend_button"]:
		assert_bool(l.rect(path).size.x > 0.0).override_failure_message(path).is_true()
	assert_int((l.get_value("skill_tab.nodes", []) as Array).size()).is_equal(8)
	assert_int((l.get_value("stigma_tab.cards.rects", []) as Array).size()).is_equal(3)


func test_layout_anchor_shift_on_wider_screen() -> void:
	var l := UiLayout.load_from(CharacterScreen.LAYOUT_PATH)
	var r := l.rect("overview.weapon_card")
	l.view_size = Vector2(2400, 1080)
	assert_float(l.rect("overview.weapon_card").position.x - r.position.x).is_equal(480.0)
	assert_float(l.anchor_shift("center")).is_equal(240.0)
	assert_float(l.anchor_shift("left")).is_equal(0.0)
	assert_float(l.rect("common.back_button").position.x).is_equal(
			UiLayout.load_from(CharacterScreen.LAYOUT_PATH).rect("common.back_button").position.x)


func test_layout_missing_values_fall_back() -> void:
	var l := UiLayout.load_from("res://khong_co.json")
	assert_int(l.errors.size()).is_equal(1)
	assert_float(l.rect("x.y", Rect2(1, 2, 3, 4)).size.x).is_equal(3.0)
	assert_float(l.num("a.b", 7.0)).is_equal(7.0)
	assert_object(l.color("none", Color.RED)).is_equal(Color.RED)


func test_placeholder_art_without_texture() -> void:
	var a: PlaceholderArt = auto_free(PlaceholderArt.new())
	assert_bool(a.is_placeholder()).is_true()
	a.texture = PlaceholderTexture2D.new()
	assert_bool(a.is_placeholder()).is_false()


# ---------- Tổng quan (ảnh 1) ----------

func test_overview_shows_selected_character_and_roster() -> void:
	_save.data["characters"][L] = SaveSchema.default_character()
	var s := _screen()
	assert_int(s.view).is_equal(CharacterScreen.View.OVERVIEW)
	assert_str(s.selected).is_equal(A)
	var t := _texts(s)
	assert_bool(t.contains(tr("CHAR_FIRE_01")) and t.contains("Lv.1") and t.contains(tr("ELEMENT_FIRE"))).is_true()
	assert_object(_node(s, "Roster_%s" % A)).is_not_null()
	assert_object(_node(s, "Roster_%s" % L)).is_not_null()
	(_node(s, "Roster_%s" % L) as Button).pressed.emit()
	assert_str(s.selected).is_equal(L)
	assert_bool(_texts(s).contains(tr("CHAR_WIND_01"))).is_true()


func test_overview_art_uses_portrait_or_placeholder() -> void:
	var s := _screen()
	var art := _node(s, "CharacterArt") as PlaceholderArt
	assert_bool(art.is_placeholder()).is_equal(s.portrait(A) == null)
	_save.data["characters"]["char_dark_01"] = SaveSchema.default_character()
	s.select("char_dark_01")
	assert_bool((_node(s, "CharacterArt") as PlaceholderArt).is_placeholder()).is_true()   # Yomigari chưa có ảnh


# ---------- Splash art 2D (owner 2026-11-13) ----------

const SPLASH_DIR := "res://assets/characters/char_fire_01/splash/char_fire_01_splash_%s.png"


func _tex(s: CharacterScreen, node_name: String) -> Texture2D:
	return (_node(s, node_name) as PlaceholderArt).texture


func test_enkiba_uses_splash_art_on_every_view() -> void:
	var s := _screen()
	assert_object(_tex(s, "CharacterArt")).is_same(load(SPLASH_DIR % "overview"))
	s.open_tab("level")
	assert_object(_tex(s, "CharacterArt")).is_same(load(SPLASH_DIR % "level"))
	s.open_tab("weapon")
	assert_object(_tex(s, "CharacterArt")).is_same(load(SPLASH_DIR % "weapon"))
	s.open_tab("skill")
	assert_object(_tex(s, "CharacterArt")).is_same(load(SPLASH_DIR % "skill"))
	s.open_tab("stigma")
	assert_object(_tex(s, "BackArt")).is_same(load(SPLASH_DIR % "stigma"))          # ảnh lưng cho tab Vết Thánh
	assert_bool((_node(s, "BackArt") as PlaceholderArt).is_placeholder()).is_false()
	# Roster vẫn dùng chân dung chibi (cắt phần đầu), không dùng splash.
	assert_object(s.portrait(A)).is_not_same(load(SPLASH_DIR % "overview"))


func test_kazeyumi_raikiba_iwagane_use_splash_art_on_every_view() -> void:
	for id in ["char_wind_01", "char_lightning_01", "char_earth_01"]:
		_check_splash_views(id)


func _check_splash_views(id: String) -> void:
	var s := _screen()
	_save.data["characters"][id] = SaveSchema.default_character()
	s.select(id)
	var dir := "res://assets/characters/{id}/splash/{id}_splash_%s.png".replace("{id}", id)
	assert_object(_tex(s, "CharacterArt")).is_same(load(dir % "overview"))
	for t in ["level", "weapon", "skill"]:
		s.open_tab(t)
		assert_object(_tex(s, "CharacterArt")).is_same(load(dir % t))
	s.open_tab("stigma")
	assert_object(_tex(s, "BackArt")).is_same(load(dir % "stigma"))                 # ảnh lưng cho tab Vết Thánh


func test_splash_file_per_view_is_configurable_in_layout() -> void:
	var s := _screen()
	s.layout.data["art"]["level"] = "skill"                                         # đổi ảnh tab Tăng cấp bằng cấu hình
	s.open_tab("level")
	assert_object(_tex(s, "CharacterArt")).is_same(load(SPLASH_DIR % "skill"))


func test_splash_falls_back_to_chibi_or_placeholder() -> void:
	var s := _screen()
	s.layout.data["art"]["weapon"] = "khong_co_file"
	assert_object(s.splash(A, "weapon")).is_same(s.portrait(A))                      # thiếu file: dùng chibi
	assert_object(s.splash(A, "weapon", false)).is_null()                            # ảnh lưng không thay bằng chibi
	_save.data["characters"]["char_dark_01"] = SaveSchema.default_character()
	s.select("char_dark_01")                                                         # nhân vật chưa có splash lẫn chibi
	assert_bool((_node(s, "CharacterArt") as PlaceholderArt).is_placeholder()).is_true()
	s.open_tab("stigma")
	assert_bool((_node(s, "BackArt") as PlaceholderArt).is_placeholder()).is_true()


func test_selected_from_game_config() -> void:
	_save.data["characters"][L] = SaveSchema.default_character()
	var gc := get_tree().root.get_node("GameConfig")
	gc.selected_character_id = L
	var s := _screen()
	gc.selected_character_id = ""
	assert_str(s.selected).is_equal(L)


func test_overview_buttons_open_tabs() -> void:
	var s := _screen()
	(_node(s, "WeaponCardButton") as Button).pressed.emit()
	assert_int(s.view).is_equal(CharacterScreen.View.DETAIL)
	assert_str(s.tab).is_equal("weapon")
	s.intercept_back()
	(_node(s, "StigmaIcon1") as Button).pressed.emit()
	assert_str(s.tab).is_equal("stigma")
	s.intercept_back()
	(_node(s, "SkillViewButton") as Button).pressed.emit()
	assert_str(s.tab).is_equal("skill")


func test_back_steps_then_lets_router_go() -> void:
	var s := _screen()
	s.open_skill("ultimate")
	s.glossary_open = true
	assert_bool(s.intercept_back()).is_true()
	assert_bool(s.glossary_open).is_false()
	assert_bool(s.intercept_back()).is_true()
	assert_int(s.view).is_equal(CharacterScreen.View.DETAIL)
	assert_str(s.tab).is_equal("skill")
	assert_bool(s.intercept_back()).is_true()
	assert_int(s.view).is_equal(CharacterScreen.View.OVERVIEW)
	assert_bool(s.intercept_back()).is_false()
	assert_bool(s.is_in_group(CharacterScreen.BACK_GROUP)).is_true()


# ---------- Tab Tăng cấp (ảnh 4) ----------

func test_level_tab_stats_and_exp_book() -> void:
	var s := _screen()
	s.profile.inventory.add_material("mat_exp_medium", 2)
	s.profile.inventory.add_currency("gold", 1000)
	s.open_tab("level")
	assert_str((_node(s, "Stat_atk") as Label).text).is_equal("1000")
	(_node(s, "LevelUpButton") as Button).pressed.emit()
	assert_str(s.picker).is_equal("exp")
	(_node(s, "UseExp_mat_exp_medium") as Button).pressed.emit()
	assert_int(s.profile.progression.level_of(A)).is_equal(3)
	assert_int(int(_disk()["characters"][A]["level"])).is_equal(3)
	assert_int(_disk()["currencies"]["gold"]).is_equal(900)


func test_failed_exp_shows_reason() -> void:
	var s := _screen()
	s.profile.inventory.add_material("mat_exp_small", 1)              # có sách, không có vàng
	s.open_tab("level")
	s.use_exp("mat_exp_small")
	assert_str(s.notice).is_equal(tr("REASON_NOT_ENOUGH"))
	assert_bool(_texts(s).contains(tr("REASON_NOT_ENOUGH"))).is_true()
	assert_int(s.profile.progression.level_of(A)).is_equal(1)


func test_promotion_from_fragments() -> void:
	var s := _screen()
	s.open_tab("level")
	assert_bool((_node(s, "PromoteButton") as Button).disabled).is_false()
	s.promote()                                                        # chưa đủ mảnh
	assert_int(s.profile.progression.promotion_of(A)).is_equal(0)
	s.profile.progression.add_fragments(A, 10)
	s.promote()
	assert_int(s.profile.progression.promotion_of(A)).is_equal(1)
	assert_int(int(_disk()["characters"][A]["promotion"])).is_equal(1)
	assert_str((_node(s, "FragmentCount") as Label).text).is_equal("0/20")


# ---------- Tab Vũ khí / Vết thánh (ảnh 2, 3) ----------

func test_weapon_picker_only_lists_matching_type_and_equips() -> void:
	var s := _screen()
	var inv := s.profile.inventory
	var w1 := inv.add_equipment("eq_weapon_iron")
	var w2 := inv.add_equipment("eq_weapon_flame")
	var bow := inv.add_equipment("eq_weapon_bow_gale")
	s.open_tab("weapon")
	assert_bool(_texts(s).contains(tr("CHAR_UI_EMPTY"))).is_true()
	var c := s.candidates("weapon")
	assert_bool(w1 in c and w2 in c).is_true()
	assert_bool(bow in c).is_false()                                   # Enkiba dùng kiếm
	(_node(s, "ChangeWeaponButton") as Button).pressed.emit()
	(_node(s, "Equip_%s" % w2) as Button).pressed.emit()
	assert_str(inv.equipped_uid(A, "weapon")).is_equal(w2)
	assert_str(s.picker).is_equal("")
	assert_str((_node(s, "WeaponName") as Label).text).is_equal(tr(inv.equipment_def_of(w2).name_key))
	assert_str(_disk()["characters"][A]["equipment"]["weapon"]).is_equal(w2)
	assert_str(s.candidates("weapon")[0]).is_equal(w2)                 # món đang mặc lên đầu


## Tab Vũ khí không còn hiện chỉ số (owner 2026-11-15); nút Chi tiết / bấm ảnh mở màn chi tiết vũ khí.
func test_weapon_tab_hides_stats_and_opens_detail() -> void:
	var s := _screen()
	var inv := s.profile.inventory
	s.open_tab("weapon")
	assert_bool((_node(s, "WeaponDetailButton") as Button).disabled).is_true()      # chưa mặc vũ khí
	var w := inv.add_equipment("eq_weapon_flame")
	inv.equip(A, w)
	s.refresh()
	assert_bool(_texts(s).contains(tr("STAT_ATK"))).is_false()
	(_node(s, "WeaponArtButton") as Button).pressed.emit()
	assert_int(s.view).is_equal(CharacterScreen.View.WEAPON_DETAIL)
	assert_str((_node(s, "WeaponDetailName") as Label).text).is_equal(tr("EQUIP_EQ_WEAPON_FLAME"))
	assert_bool(_texts(s).contains(tr("STAT_ATK"))).is_true()
	assert_str((_node(s, "WeaponLevel") as Label).text).is_equal("LV. 0 / 25")      # 4★ bậc 0: 25
	assert_str((_node(s, "WeaponTier") as Label).text).is_equal(tr("WEAPON_UI_TIER") % [0, 2])
	s.intercept_back()
	assert_int(s.view).is_equal(CharacterScreen.View.DETAIL)
	assert_str(s.tab).is_equal("weapon")
	(_node(s, "WeaponDetailButton") as Button).pressed.emit()
	assert_int(s.view).is_equal(CharacterScreen.View.WEAPON_DETAIL)


func test_enhance_weapon() -> void:
	var s := _screen()
	var inv := s.profile.inventory
	var w := inv.add_equipment("eq_weapon_flame")
	inv.equip(A, w)
	inv.add_currency("gold", 5000)
	inv.add_material("mat_enhance_ore", 10)
	s.open_weapon_detail()
	(_node(s, "EnhanceButton") as Button).pressed.emit()
	assert_str(s.picker).is_equal("enhance")
	assert_bool((_node(s, "EnhancePreview") as Label).text.contains("→")).is_true()
	assert_bool((_node(s, "EnhanceWith_mat_enhance_crystal") as Button).disabled).is_true()   # chưa có tinh thể
	(_node(s, "EnhanceWith_mat_enhance_ore") as Button).pressed.emit()
	assert_int(inv.equipment_level(w)).is_equal(1)
	assert_str(s.picker).is_equal("enhance")                                        # bảng giữ mở để nâng tiếp
	assert_str((_node(s, "WeaponLevel") as Label).text).is_equal("LV. 1 / 25")
	assert_int(int(_disk()["inventory"]["equipment"][w]["level"])).is_equal(1)


func test_ascend_weapon_from_detail() -> void:
	var s := _screen()
	var inv := s.profile.inventory
	var rules := s.profile.rules
	var w := inv.add_equipment("eq_weapon_flame")
	inv.equip(A, w)
	s.open_weapon_detail()
	(_node(s, "AscendButton") as Button).pressed.emit()
	assert_str(s.picker).is_equal("ascend")
	assert_bool((_node(s, "AscendConfirm") as Button).disabled).is_true()
	assert_str((_node(s, "AscendReason") as Label).text).is_equal(tr("WEAPON_UI_NEED_LEVEL") % 25)
	s.profile.data["inventory"]["equipment"][w]["level"] = 25
	inv.add_currency("gold", 100000)
	inv.add_material(rules.ascend_material, 10)
	s.refresh()
	assert_bool((_node(s, "AscendConfirm") as Button).disabled).is_false()
	(_node(s, "AscendConfirm") as Button).pressed.emit()
	assert_int(inv.equipment_tier(w)).is_equal(1)
	assert_str(s.picker).is_equal("")
	assert_str((_node(s, "WeaponLevel") as Label).text).is_equal("LV. 25 / 30")
	assert_int(int(_disk()["inventory"]["equipment"][w]["tier"])).is_equal(1)


## Kĩ năng chủ động = Kĩ năng vũ khí của giáp; bị động = dòng hiệu ứng của vũ khí, dòng độc quyền ghi tên giáp chủ.
func test_weapon_detail_skill_text() -> void:
	var s := _screen()
	var inv := s.profile.inventory
	var five := inv.add_equipment("eq_weapon_dusk_inferno")
	var three := inv.add_equipment("eq_weapon_iron")
	inv.equip(A, five)
	var t := s.weapon_skill_text(five)
	assert_bool(t.contains(SkillText.skill_name(A, "weapon"))).is_true()
	assert_bool(t.contains("Người đeo +8% tất cả ST")).is_true()
	assert_bool(t.contains(tr("WEAPON_UI_WHEN_EQUIPPED") % s.suit_label(A))).is_true()
	assert_bool(t.contains("Kẻ địch đang Choáng chịu +15% tất cả ST từ người đeo")).is_true()
	assert_bool(t.contains(s.char_name(A) + " ")).is_false()                     # không lặp tên nhân vật
	assert_int(t.find(tr("WEAPON_UI_WHEN_EQUIPPED") % s.suit_label(A))).is_greater(t.find("Người đeo +8% tất cả ST"))
	assert_bool(s.weapon_skill_text(three).contains(tr("WEAPON_UI_NO_PASSIVE"))).is_true()
	s.open_weapon_detail()
	assert_bool((_node(s, "WeaponSkills") as RichTextLabel).text.contains(tr("WEAPON_UI_PASSIVE"))).is_true()


## Tab Vết thánh: bấm ảnh thẻ mở bảng thông tin vết thánh với 3 tab (owner 2026-11-15); Trở về quay lại tab Vết thánh.
func test_stigma_detail_three_tabs_and_reroll() -> void:
	var s := _screen()
	var inv := s.profile.inventory
	var top := inv.add_equipment("eq_stigma_top_blaze")
	var mid := inv.add_equipment("eq_stigma_mid_blaze")
	inv.equip(A, top)
	inv.equip(A, mid)
	s.open_tab("stigma")
	(_node(s, "StigmaCard0") as Button).pressed.emit()
	assert_int(s.view).is_equal(CharacterScreen.View.WEAPON_DETAIL)
	assert_str(s.detail_uid).is_equal(top)
	assert_str((_node(s, "WeaponLevel") as Label).text).is_equal("LV. 0 / 30")
	assert_object(_node(s, "StigmaTab_skill")).is_not_null()
	# Skill set: tên bộ 2 món đang kích hoạt (mặc 2 món cùng bộ).
	(_node(s, "StigmaTab_set") as Button).pressed.emit()
	assert_str(s.detail_tab).is_equal("set")
	var sd := EquipmentResolver.set_defs().get_def(inv.equipment_def_of(top).set_id) as StigmaSetDef
	assert_bool((_node(s, "WeaponSkills") as RichTextLabel).text.contains(tr("STIGMA_UI_SET_PIECES") % [tr(sd.name_key), 2])).is_true()
	# Skill phụ tố: tẩy, chọn giữ mới.
	(_node(s, "StigmaTab_affix") as Button).pressed.emit()
	inv.add_material(s.profile.rules.affix_reroll_material, 5)
	(_node(s, "RerollButton") as Button).pressed.emit()
	assert_str(s.picker).is_equal("reroll")
	(_node(s, "RerollConfirm") as Button).pressed.emit()
	assert_object(_node(s, "AffixNew")).is_not_null()
	var fresh := inv.pending_affixes(top).duplicate(true)
	(_node(s, "KeepNew") as Button).pressed.emit()
	assert_array(inv.affixes_of(top)).is_equal(fresh)
	assert_str(s.picker).is_equal("")
	assert_array(_disk()["inventory"]["equipment"][top]["affixes"]).is_equal(fresh)
	s.intercept_back()
	assert_int(s.view).is_equal(CharacterScreen.View.DETAIL)
	assert_str(s.tab).is_equal("stigma")


## Mở từ Túi đồ: GameConfig.inspect_equipment_uid → màn mở thẳng bảng thông tin, Trở về là rời màn.
func test_open_detail_from_bag() -> void:
	var inv := PlayerProfile.new(_save.data).inventory
	var w := inv.add_equipment("eq_weapon_iron")
	GameConfig.inspect_equipment_uid = w
	var s := _screen()
	assert_int(s.view).is_equal(CharacterScreen.View.WEAPON_DETAIL)
	assert_str(s.detail_uid).is_equal(w)
	assert_str(GameConfig.inspect_equipment_uid).is_equal("")
	assert_str((_node(s, "WeaponWearer") as Label).text).is_equal(tr("BAG_NOT_IN_USE"))
	assert_object(_node(s, "WeaponDetailChange")).is_null()
	assert_bool(s.intercept_back()).is_false()


func test_background_image_per_view() -> void:
	var s := _screen()
	assert_str(s.background_key()).is_equal("overview")
	s.open_tab("stigma")
	assert_str(s.background_key()).is_equal("stigma")
	s.open_skill("normal")
	assert_str(s.background_key()).is_equal("skill_detail")
	# Chưa có file ảnh nào: nền màu, không lỗi. Đổi đường dẫn sang ảnh có sẵn thì hiện ảnh.
	s.layout.data["backgrounds"]["path"] = "res://assets/ui/recruit/{name}.png"
	s.layout.data["backgrounds"]["default"] = "banner_char_terra_banner"
	s.refresh()
	assert_object(_node(s, "Background")).is_not_null()
	s.layout.data["backgrounds"]["path"] = "res://khong_co/{name}.png"
	s.refresh()
	assert_object(_node(s, "Background")).is_null()


func test_stigma_tab_three_slots_and_unequip() -> void:
	var s := _screen()
	var inv := s.profile.inventory
	var mid := inv.add_equipment("eq_stigma_mid_hide")
	s.open_tab("stigma")
	for i in 3:
		assert_object(_node(s, "StigmaSlot%d" % i)).is_not_null()
		assert_object(_node(s, "ChangeStigma%d" % i)).is_not_null()
	(_node(s, "ChangeStigma1") as Button).pressed.emit()
	assert_str(s.picker).is_equal("stigma_mid")
	(_node(s, "Equip_%s" % mid) as Button).pressed.emit()
	assert_str(inv.equipped_uid(A, "stigma_mid")).is_equal(mid)
	assert_bool((_node(s, "StigmaText") as Label).text.contains(tr(inv.equipment_def_of(mid).name_key))).is_true()
	s.open_picker("stigma_mid")
	(_node(s, "Unequip") as Button).pressed.emit()
	assert_str(inv.equipped_uid(A, "stigma_mid")).is_equal("")
	s.open_picker("stigma_top")
	assert_bool(_texts(s).contains(tr("CHAR_UI_NOTHING"))).is_true()


# ---------- Tab Skill + chi tiết (ảnh 5, 6) ----------

func test_skill_tree_has_eight_nodes_and_levels() -> void:
	var s := _screen()
	s.open_tab("skill")
	for g in SkillText.GROUP_ORDER:
		assert_object(_node(s, "SkillNode_%s" % g)).override_failure_message(g).is_not_null()
	assert_str((_node(s, "SkillLevel_ultimate") as Label).text).is_equal("+0")
	assert_bool(_texts(s).contains(tr("SKILL_FIRE_01_ULTIMATE"))).is_true()
	(_node(s, "SkillNode_ultimate") as Button).pressed.emit()
	assert_int(s.view).is_equal(CharacterScreen.View.SKILL_DETAIL)
	assert_str(s.skill_group).is_equal("ultimate")


func test_skill_detail_description_from_data() -> void:
	var s := _screen()
	s.open_skill("normal")
	var d := (_node(s, "Description") as RichTextLabel).text
	assert_bool(d.contains(tr("SUBSKILL_NORMAL") % 1) and d.contains(tr("SUBSKILL_NORMAL") % 4)).is_true()
	assert_bool(d.contains("ATK")).is_true()
	(_node(s, "BriefToggle") as Button).pressed.emit()
	assert_bool(s.brief).is_true()
	var brief := (_node(s, "Description") as RichTextLabel).text
	assert_int(brief.length()).is_less(d.length())
	s.open_skill("passive")
	assert_bool((_node(s, "Description") as RichTextLabel).text.contains("4%")).is_true()   # +4% ATK mỗi tầng Nhiệt
	assert_object(_node(s, "UpgradeSkillButton")).is_null()               # bị động không nâng cấp


func test_skill_upgrade_costs_gold_and_saves() -> void:
	var s := _screen()
	s.profile.inventory.add_currency("gold", 600)
	s.open_skill("skill")
	(_node(s, "UpgradeSkillButton") as Button).pressed.emit()
	assert_int(s.profile.progression.skill_level(A, "skill")).is_equal(2)
	assert_int(_disk()["currencies"]["gold"]).is_equal(100)
	s.upgrade_skill()                                                    # thiếu vàng
	assert_int(s.profile.progression.skill_level(A, "skill")).is_equal(2)
	assert_str(s.notice).is_not_empty()
	s.open_tab("skill")
	assert_str((_node(s, "SkillLevel_skill") as Label).text).is_equal("+1")


func test_skill_nav_cycles_groups() -> void:
	var s := _screen()
	s.open_skill(SkillText.GROUP_ORDER[0])
	(_node(s, "NavNext") as Button).pressed.emit()
	assert_str(s.skill_group).is_equal(SkillText.GROUP_ORDER[1])
	(_node(s, "NavPrev") as Button).pressed.emit()
	(_node(s, "NavPrev") as Button).pressed.emit()
	assert_str(s.skill_group).is_equal(SkillText.GROUP_ORDER[-1])


func test_glossary_lists_statuses() -> void:
	var s := _screen()
	s.open_skill("skill")
	(_node(s, "GlossaryButton") as Button).pressed.emit()
	assert_object(_node(s, "Glossary")).is_not_null()
	var lines := SkillText.glossary_lines(StatusLibrary.load_dir())
	assert_int(lines.size()).is_greater(5)
	assert_bool("\n".join(lines).contains(tr("STATUS_BURN"))).is_true()


func test_title_shows_person_and_suit_name() -> void:
	var s := _screen()
	var t := _texts(s)
	assert_bool(t.contains("Enkiba") and t.contains(tr("SUIT_FIRE_01"))).is_true()
	assert_str(s.suit_name("char_earth_01")).is_equal(tr("SUIT_EARTH_01"))


func test_filter_by_rank_element_person() -> void:
	_save.data["characters"]["char_lightning_01"] = SaveSchema.default_character()
	_save.data["characters"][L] = SaveSchema.default_character()
	_save.data["characters"]["char_earth_01"] = SaveSchema.default_character()
	var s := _screen()
	assert_int(s.filtered_ids().size()).is_equal(4)
	(_node(s, "FilterButton") as Button).pressed.emit()
	assert_bool(s.filter_open).is_true()
	assert_object(_node(s, "Filter_rank_S")).is_not_null()
	assert_int(_node(s, "Dim").mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)   # không bấm xuyên xuống nút bên dưới
	(_node(s, "Filter_rank_S") as Button).pressed.emit()                  # S = Enkiba, Iwagane
	assert_array(Array(s.filtered_ids())).contains_exactly_in_any_order([A, "char_earth_01"])
	(_node(s, "Filter_element_earth") as Button).pressed.emit()           # và nguyên tố Địa
	assert_array(Array(s.filtered_ids())).is_equal(["char_earth_01"])
	assert_str((_node(s, "FilterCount") as Label).text).is_equal(tr("CHAR_UI_FILTER_COUNT") % [1, 4])
	(_node(s, "Filter_element_earth") as Button).pressed.emit()           # bấm lại thì bỏ
	(_node(s, "Filter_rank_S") as Button).pressed.emit()
	s.toggle_filter("person", "kazeyumi")
	assert_array(Array(s.filtered_ids())).is_equal([L])
	s.toggle_filter("rank", "A")                                          # không ai khớp
	assert_bool(s.intercept_back()).is_true()                             # đóng bảng lọc
	assert_bool(s.filter_open).is_false()
	assert_object(_node(s, "FilterEmpty")).is_not_null()
	assert_object(_node(s, "Roster_%s" % L)).is_null()
	s.clear_filter()
	assert_bool(s.is_filtered()).is_false()
	assert_object(_node(s, "Roster_%s" % L)).is_not_null()


func test_every_screen_builds_at_other_sizes() -> void:
	var s := _screen()
	for sz in [Vector2(2560, 1080), Vector2(1280, 720)]:
		_resize(s, sz)
		for t in ["level", "weapon", "stigma", "skill"]:
			s.open_tab(t)
		for g in SkillText.GROUP_ORDER:
			s.open_skill(g)
		s.open_weapon_detail()
		for pk in ["enhance", "ascend", "reroll"]:
			s.open_picker(pk)
		for t in ["skill", "affix", "set"]:
			s.open_detail_tab(t)
		s.picker = ""
		s.view = CharacterScreen.View.OVERVIEW
		s.refresh()
	assert_object(_node(s, "BackButton")).is_not_null()
