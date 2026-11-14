extends GdUnitTestSuite
## Test màn Chiêu mộ (owner 2026-11-13, theo ảnh màn Wish): bố cục đọc từ JSON, danh sách banner, banner lớn (nhãn, tiêu đề,
## đề cử, thời gian còn lại, bảo đảm), tỉ lệ nằm trong Chi tiết, Lịch sử, bảng kết quả, quay + lưu, ảnh placeholder.

const SCREEN_SCENE := preload("res://scenes/main/recruit_screen.tscn")
const SAVE_DIR := "user://test_saves_recruit_screen"
const CHAR_BANNER := "res://data/banners/banner_char_terra.tres"
const EQUIP_BANNER := "res://data/banners/banner_equip_terra.tres"

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


func _screen(custom: Variant = null) -> RecruitScreen:
	var s: RecruitScreen = auto_free(SCREEN_SCENE.instantiate())
	if custom != null:
		s.banners = custom
		s.banners_injected = true
	add_child(s)
	_resize(s, Vector2(1920, 1080))
	s.service.rng = RandomSource.new(42)
	return s


func _resize(s: RecruitScreen, sz: Vector2) -> void:
	s.set_anchors_preset(Control.PRESET_TOP_LEFT)
	s.size = sz


func _node(s: Node, name_: String) -> Control:
	return s.find_child(name_, true, false) as Control


func _text(s: Node, name_: String) -> String:
	var n := _node(s, name_)
	return (n as Label).text if n else "<không có %s>" % name_


func _all_text(n: Node) -> String:
	var out := PackedStringArray()
	for c in n.find_children("*", "Label", true, false):
		out.append((c as Label).text)
	for c in n.find_children("*", "Button", true, false):
		out.append((c as Button).text)
	return "\\n".join(out)


func _disk() -> Dictionary:
	return SaveStore.new(SAVE_DIR).read()


func _test_banner() -> BannerDef:
	var b := BannerDef.new()
	b.id = "ui_test_banner"
	b.name_key = "RECRUIT_CLOSED"
	b.cost_single = 100
	b.cost_multi = 900
	var top := GachaTierDef.new()
	top.rarity = 5
	top.base_rate = 0.25
	top.hard_pity = 20
	top.pool = PackedStringArray(["char:char_dark_01"])
	var low := GachaTierDef.new()
	low.rarity = 3
	low.pool = PackedStringArray(["item:mat_exp_small"])
	b.tiers = [top, low]
	return b


# ---------- Bố cục và dữ liệu ----------

func test_layout_file_is_valid_and_complete() -> void:
	var l := UiLayout.load_from(RecruitScreen.LAYOUT_PATH)
	assert_array(Array(l.errors)).is_empty()
	for path in ["top.close_button", "top.gold_pill", "top.gems_pill", "panel", "panel.title", "panel.orange_box", "panel.featured_name",
			"panel.stars", "panel.time_value", "bottom.shop_button", "bottom.details_button", "bottom.history_button", "bottom.wish_1",
			"bottom.wish_10", "overlay"]:
		assert_bool(l.rect(path).size.x > 0.0).override_failure_message(path).is_true()
	assert_int((l.get_value("list.item", []) as Array).size()).is_equal(2)


func test_closed_without_banners() -> void:
	var none: Array[BannerDef] = []
	var s := _screen(none)
	assert_str(_text(s, "Closed")).is_equal(tr("RECRUIT_CLOSED"))
	assert_object(_node(s, "Wish_1")).is_null()
	assert_bool(s.pull(1)).is_false()


func test_shipped_banners_listed_in_order() -> void:
	var s := _screen()
	assert_int(s.banners.size()).is_equal(3)                           # nhân vật + tiếp tế + 5★; lượt hướng dẫn không hiện
	assert_str(s.banners[0].id).is_equal("banner_char_terra")
	assert_str(s.banners[1].id).is_equal("banner_equip_terra")
	assert_str(s.banners[2].id).is_equal("banner_star5_earth")
	assert_object(_node(s, "Banner_0")).is_not_null()
	assert_object(_node(s, "Banner_1")).is_not_null()
	assert_object(_node(s, "Banner_2")).is_not_null()
	for b in s.banners:
		assert_bool(b.starter_free_multi).is_false()


# ---------- Màn chính (ảnh tham chiếu) ----------

func test_character_banner_main_screen() -> void:
	var s := _screen()
	assert_str(_text(s, "KindTag")).is_equal(tr("BANNER_KIND_CHAR"))
	assert_str(_text(s, "BannerTitle")).is_equal(tr("BANNER_TITLE_TERRA"))
	assert_str(_text(s, "FeaturedName")).is_equal(tr("CHAR_EARTH_01"))   # Iwagane
	assert_str(_text(s, "Stars")).is_equal("★★★★★")
	assert_str(_text(s, "FeaturedSub")).is_equal(tr("SUIT_EARTH_01"))
	assert_str(_text(s, "TimeValue")).is_equal(tr("RECRUIT_UI_PERMANENT"))
	assert_str(_text(s, "Tagline")).is_equal(tr("RECRUIT_UI_TAGLINE"))
	assert_str(_text(s, "OrangeBox")).is_equal(tr("RECRUIT_UI_GUARANTEE_BOX") % [10, "%s / %s" % [tr("GACHA_TIER_CHAR_S"), tr("GACHA_TIER_CHAR_A")]])
	assert_str(_text(s, "PityLine")).is_equal(tr("RECRUIT_UI_PITY") % [tr("GACHA_TIER_CHAR_S"), 0, 100])
	assert_object(_node(s, "ElementIcon")).is_not_null()
	assert_str(_node(s, "Wish_1").get("text")).contains("280")
	assert_str(_node(s, "Wish_10").get("text")).contains("2520")


func test_rates_are_not_on_main_screen_but_in_details() -> void:
	var s := _screen()
	var main := _all_text(s)
	assert_bool(main.contains("16.300%") or main.contains("10.874%")).is_false()
	(_node(s, "DetailsButton") as Button).pressed.emit()
	assert_int(s.overlay).is_equal(RecruitScreen.Overlay.DETAILS)
	var d := _text(s, "DetailsText")
	assert_bool(d.contains("1.500%") and d.contains("16.300%") and d.contains("10.874%")).is_true()
	assert_bool(d.contains(tr("RECRUIT_UI_GUARANTEE_BOX").substr(0, 4)) or d.contains(tr("RECRUIT_MULTI_GUARANTEE") % 10)).is_true()
	assert_object(_node(s, "Details")).is_not_null()
	assert_bool(s.intercept_back()).is_true()
	assert_int(s.overlay).is_equal(RecruitScreen.Overlay.NONE)
	assert_object(_node(s, "DetailsText")).is_null()


func test_equipment_banner_switch() -> void:
	var s := _screen()
	(_node(s, "Banner_1") as Button).pressed.emit()
	assert_int(s.selected).is_equal(1)
	var weapon := PlayerProfile.equipment_defs().get_def("eq_weapon_greatsword_magma") as EquipmentDef
	assert_str(_text(s, "KindTag")).is_equal(tr("BANNER_KIND_EQUIP"))
	assert_str(_text(s, "FeaturedName")).is_equal(tr(weapon.name_key))
	assert_str(_text(s, "Stars")).is_equal("★★★★")
	assert_str(_text(s, "FeaturedSub")).is_equal(tr("RECRUIT_UI_STIGMA_SET") % 3)
	assert_str(_text(s, "PityLine")).contains("0/60")
	assert_str(_text(s, "Note")).is_equal(tr("RECRUIT_UI_NOTE_EQUIP"))
	# Tên dài vẫn nằm một dòng trong khung (thu nhỏ chữ), không xuống dòng đè lên hàng sao.
	var name_label := _node(s, "FeaturedName") as Label
	assert_int(name_label.autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	assert_bool(name_label.get_theme_font_size("font_size") <= 70).is_true()
	var w := name_label.get_theme_default_font().get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_label.get_theme_font_size("font_size")).x
	assert_bool(w <= name_label.size.x).is_true()
	assert_int((_node(s, "KindTag") as Label).autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	assert_str(_text(s, "OrangeBox")).contains(tr("GACHA_TIER_STIGMA_4"))
	(_node(s, "DetailsButton") as Button).pressed.emit()
	var d := _text(s, "DetailsText")
	assert_bool(d.contains("2.870%") and d.contains("14.430%") and d.contains("58.000%")).is_true()


func test_time_remaining_text() -> void:
	var s := _screen()
	var b := s.banners[0].duplicate() as BannerDef
	assert_str(s.time_text(b)).is_equal(tr("RECRUIT_UI_PERMANENT"))
	s.now_unix = 1_000_000
	b.end_unix = 1_000_000 + 86400 + 3600 + 60 + 1
	assert_str(s.time_text(b)).is_equal(tr("RECRUIT_UI_TIME_FMT") % [1, 1, 1])
	b.end_unix = 1_000_000 + 5 * 86400 + 7 * 3600 + 46 * 60
	assert_str(s.time_text(b)).is_equal(tr("RECRUIT_UI_TIME_FMT") % [5, 7, 46])
	b.end_unix = 999_999
	assert_str(s.time_text(b)).is_equal(tr("RECRUIT_UI_ENDED"))


func test_placeholder_art_resolution() -> void:
	var s := _screen()
	var b := s.banners[0]
	assert_object(s.art_texture(b, "banner")).is_not_null()          # placeholder_{id}_banner.png
	assert_object(s.art_texture(b, "thumb")).is_not_null()
	assert_bool((_node(s, "BannerArt") as PlaceholderArt).is_placeholder()).is_false()
	var nowhere := b.duplicate() as BannerDef
	nowhere.id = "khong_co_anh"
	assert_object(s.art_texture(nowhere, "banner")).is_null()         # không file nào: màn vẽ hình người
	var injected: Array[BannerDef] = [nowhere]
	var s2 := _screen(injected)
	assert_bool((_node(s2, "BannerArt") as PlaceholderArt).is_placeholder()).is_true()
	assert_bool(FileAccess.file_exists("res://assets/ui/recruit/README.md")).is_true()


# ---------- Lịch sử, quay, kết quả ----------

func test_history_empty_then_filled() -> void:
	var s := _screen()
	(_node(s, "HistoryButton") as Button).pressed.emit()
	assert_str(_text(s, "HistoryText")).is_equal(tr("RECRUIT_UI_HISTORY_EMPTY"))
	s.intercept_back()
	s.profile.inventory.add_currency("gems", 1000)
	assert_bool(s.pull(1)).is_true()
	s.intercept_back()
	(_node(s, "HistoryButton") as Button).pressed.emit()
	assert_int(_text(s, "HistoryText").split("\n").size()).is_equal(1)


func test_pull_needs_currency_then_saves_and_shows_results() -> void:
	var s := _screen()
	assert_bool(s.pull(1)).is_false()                                 # chưa có ngọc
	assert_str(s.last_reason).is_equal(GachaService.REASON_NOT_ENOUGH)
	assert_str(_text(s, "Notice")).is_equal(tr("REASON_NOT_ENOUGH_CURRENCY"))
	assert_int(s.overlay).is_equal(RecruitScreen.Overlay.NONE)
	s.profile.inventory.add_currency("gems", 3000)
	(_node(s, "Wish_10") as Button).pressed.emit()
	assert_int(s.overlay).is_equal(RecruitScreen.Overlay.RESULTS)
	assert_int(s.last_results.size()).is_equal(10)
	for i in 10:
		assert_object(_node(s, "ResultCard_%d" % i)).override_failure_message("thẻ %d" % i).is_not_null()
	assert_int(s.profile.inventory.currency("gems")).is_equal(480)
	assert_str(_text(s, "Gems")).contains("480")
	assert_int(_disk()["gacha"]["history"].size()).is_equal(10)       # lịch sử và ngọc đã lưu
	assert_int(_disk()["currencies"]["gems"]).is_equal(480)
	assert_bool(s.intercept_back()).is_true()                         # đóng bảng kết quả
	assert_int(s.overlay).is_equal(RecruitScreen.Overlay.NONE)
	assert_bool(s.intercept_back()).is_false()                        # hết bước lùi: để SceneRouter về Hub


func test_ten_pull_guarantee_is_applied_through_screen() -> void:
	var s := _screen()
	s.profile.inventory.add_currency("gems", 100_000)
	for i in 30:
		assert_bool(s.pull(10)).is_true()
		var ok := false
		for r: Dictionary in s.last_results:
			ok = ok or r["tier"] in ["S", "A"]
		assert_bool(ok).is_true()


func test_rates_come_from_config_and_pull_works() -> void:
	var custom: Array[BannerDef] = [_test_banner()]
	var s := _screen(custom)
	var lines := "\n".join(s.rate_lines(s.banners[0]))
	assert_bool(lines.contains("5★  25.000%") and lines.contains("3★  75.000%")).is_true()   # đúng số trong config
	assert_bool(lines.contains("Yomigari")).is_true()
	s.profile.inventory.add_currency("gems", 1000)
	assert_bool(s.pull(10)).is_true()
	assert_int(s.profile.inventory.currency("gems")).is_equal(100)
	assert_str(s.result_line(s.last_results[0])).is_not_empty()


func test_overlay_dim_blocks_clicks_below() -> void:
	var s := _screen()
	(_node(s, "DetailsButton") as Button).pressed.emit()
	assert_int(_node(s, "Dim").mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)
	assert_bool(s.is_in_group(RecruitScreen.BACK_GROUP)).is_true()


func test_close_and_placeholder_buttons() -> void:
	var s := _screen()
	assert_object(_node(s, "CloseButton")).is_not_null()
	(_node(s, "ShopButton") as Button).pressed.emit()
	assert_str(_text(s, "Notice")).is_equal(tr("CHAR_UI_NOT_YET"))


func test_every_state_builds_at_other_sizes() -> void:
	var s := _screen()
	s.profile.inventory.add_currency("gems", 10_000)
	for sz in [Vector2(2560, 1080), Vector2(1280, 720)]:
		_resize(s, sz)
		for i in s.banners.size():
			s.select(i)
			s.open_overlay(RecruitScreen.Overlay.DETAILS)
			s.open_overlay(RecruitScreen.Overlay.HISTORY)
			s.pull(10)
			s.intercept_back()
	assert_object(_node(s, "CloseButton")).is_not_null()
