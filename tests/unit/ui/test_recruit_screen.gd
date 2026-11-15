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
	for path in ["top.back_button", "top.gold_pill", "top.gems_pill", "panel", "panel.title", "panel.callout_1", "panel.callout_2",
			"panel.pity_box", "panel.time", "panel.gift_card", "panel.fragment_line", "bottom.guarantee_note", "bottom.wish_1",
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
	# Bố cục theo ảnh gợi ý 2 (owner 2026-11-15): pity S còn lại, mảnh tiến cấp, nút Chơi thử / Shop / Chi tiết / Lịch sử.
	var s := _screen()
	assert_str(s.banner_layout(s.banners[0])).is_equal("char")
	assert_str(_text(s, "Banner_0") if _node(s, "Banner_0") is Label else (_node(s, "Banner_0") as Button).text).is_equal(tr("BANNER_KIND_CHAR"))
	assert_str(_text(s, "BannerTitle")).is_equal(tr("BANNER_TITLE_TERRA"))
	for n in ["FeaturedName", "Stars", "FeaturedSub"]:                   # owner 2026-11-15: bỏ chữ Iwagane / tên giáp
		assert_object(_node(s, n)).override_failure_message(n).is_null()
	assert_str(_text(s, "TimeValue")).contains(tr("RECRUIT_UI_PERMANENT"))
	assert_str(_text(s, "OrangeBox")).is_equal(tr("RECRUIT_UI_GUARANTEE_BOX") % [10, "%s / %s" % [tr("GACHA_TIER_CHAR_S"), tr("GACHA_TIER_CHAR_A")]])
	assert_str(_text(s, "PityLine")).is_equal(tr("RECRUIT_UI_PITY_LEFT") % [100, tr("GACHA_TIER_CHAR_S")])
	assert_str(_text(s, "FragmentLine")).is_equal(tr("RECRUIT_UI_FRAG_NOT_OWNED"))   # chưa có Iwagane
	for n in ["TrialButton", "ShopButton", "DetailsButton", "HistoryButton", "GiftButton"]:
		assert_object(_node(s, n)).override_failure_message(n).is_not_null()
	assert_object(_node(s, "OwnedIcon_0")).is_null()                   # banner nhân vật không có dãy icon
	assert_str(_node(s, "Wish_1").get("text")).contains("280")
	assert_str(_node(s, "Wish_10").get("text")).contains("2520")
	# Đã có Iwagane: hiện số mảnh còn thiếu để lên S1.
	s.profile.progression.unlock("char_earth_01")
	s.profile.progression.add_fragments("char_earth_01", 4)
	s.refresh()
	var need := s.profile.progression.fragments_to_promote("char_earth_01") - 4
	assert_str(_text(s, "FragmentLine")).is_equal(tr("RECRUIT_UI_FRAG_LEFT") % [need, "S1"])


func test_right_column_stays_on_screen_for_any_aspect() -> void:
	# Owner 2026-11-15: chữ cột phải (thời gian, mảnh, pity, bảo đảm) bị cắt ở màn rộng; mọi tỉ lệ phải nằm trong màn.
	var s := _screen()
	for sz in [Vector2(1920, 1080), Vector2(2560, 1080), Vector2(1728, 1080), Vector2(1440, 1080)]:
		_resize(s, sz)
		s.refresh()
		for i in s.banners.size():
			s.select(i)
			for n in ["TimeValue", "FragmentLine", "PityLine", "OrangeBox", "GiftButton", "Wish_10", "OwnedIcon_3"]:
				var c := _node(s, n)
				if c == null:
					continue
				var r := c.get_global_rect()
				assert_bool(r.end.x <= sz.x + 0.5 and r.position.x >= 0.0) \
						.override_failure_message("%s %s banner %d: %s" % [n, sz, i, r]).is_true()
				if c is Label and (c as Label).autowrap_mode == TextServer.AUTOWRAP_OFF:
					var l := c as Label
					var w := l.get_theme_default_font().get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
							l.get_theme_font_size("font_size")).x
					assert_bool(w <= l.size.x + 0.5).override_failure_message("%s rộng %s > %s" % [n, w, l.size.x]).is_true()
		var art := _node(s, "BannerArt")
		assert_float(art.get_global_rect().end.x).is_greater_equal(sz.x - 0.5)


func test_rates_are_not_on_main_screen_but_in_details() -> void:
	var s := _screen()
	var main := _all_text(s)
	assert_bool(main.contains("16.300%") or main.contains("10.874%")).is_false()
	(_node(s, "DetailsButton") as Button).pressed.emit()
	assert_int(s.overlay).is_equal(RecruitScreen.Overlay.DETAILS)
	var d := _text(s, "DetailsText")
	assert_bool(d.contains("0.150%") and d.contains("16.300%") and d.contains("10.874%")).is_true()
	assert_bool(d.contains(tr("RECRUIT_UI_GUARANTEE_BOX").substr(0, 4)) or d.contains(tr("RECRUIT_MULTI_GUARANTEE") % 10)).is_true()
	assert_object(_node(s, "Details")).is_not_null()
	assert_bool(s.intercept_back()).is_true()
	assert_int(s.overlay).is_equal(RecruitScreen.Overlay.NONE)
	assert_object(_node(s, "DetailsText")).is_null()


func test_equipment_banner_switch() -> void:
	# Bố cục theo ảnh gợi ý 1 (owner 2026-11-15): chú thích món đề cử, dãy icon, không pity, giá 200 / 1800.
	var s := _screen()
	(_node(s, "Banner_1") as Button).pressed.emit()
	assert_int(s.selected).is_equal(1)
	assert_str(s.banner_layout(s.banners[1])).is_equal("equip")
	var weapon := PlayerProfile.equipment_defs().get_def("eq_weapon_greatsword_magma") as EquipmentDef
	assert_str(_text(s, "FeaturedName")).is_equal(tr(weapon.name_key))
	assert_str(_text(s, "Stars")).is_equal("★★★★")
	assert_str(_text(s, "FeaturedSub")).is_equal(tr("RECRUIT_UI_STIGMA_SET") % 3)
	assert_object(_node(s, "PityLine")).is_null()                      # tiếp tế không còn pity
	assert_object(_node(s, "OrangeBox")).is_null()                     # không còn bảo đảm 10 lượt
	assert_object(_node(s, "FragmentLine")).is_null()
	assert_object(_node(s, "TrialButton")).is_null()
	assert_object(_node(s, "OwnedIcon_3")).is_not_null()               # 1 vũ khí + 3 vết thánh đề cử
	assert_object(_node(s, "OwnedDim_0")).is_null()                    # tiếp tế không hiện đã có / chưa có
	assert_str(_node(s, "Wish_1").get("text")).contains("200")
	assert_str(_node(s, "Wish_10").get("text")).contains("1800")
	# Tên dài vẫn nằm một dòng trong khung (thu nhỏ chữ).
	var name_label := _node(s, "FeaturedName") as Label
	assert_int(name_label.autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	var w := name_label.get_theme_default_font().get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_label.get_theme_font_size("font_size")).x
	assert_bool(w <= name_label.size.x).is_true()
	(_node(s, "DetailsButton") as Button).pressed.emit()
	var d := _text(s, "DetailsText")
	assert_bool(d.contains("2.870%") and d.contains("14.430%") and d.contains("58.000%")).is_true()


func test_star5_banner_owned_icons() -> void:
	# Banner 5★: dãy icon cả bộ, món đã có sáng + dấu ✓, chưa có phủ lớp tối mờ (owner 2026-11-15).
	var s := _screen()
	s.profile.inventory.add_equipment("eq_stigma_mid_darwin")
	(_node(s, "Banner_2") as Button).pressed.emit()
	assert_str(s.banner_layout(s.banners[2])).is_equal("equip")
	var items := s.icon_items(s.banners[2])
	assert_int(items.size()).is_equal(4)
	for i in 4:
		var owned := str(items[i]["item"]) == "equip:eq_stigma_mid_darwin"
		assert_bool(items[i]["owned"]).is_equal(owned)
		assert_bool(_node(s, "OwnedCheck_%d" % i) != null).override_failure_message("check %d" % i).is_equal(owned)
		assert_bool(_node(s, "OwnedDim_%d" % i) != null).override_failure_message("dim %d" % i).is_equal(not owned)
	assert_str(_text(s, "PityLine")).is_equal(tr("RECRUIT_UI_PITY_LEFT") % [50, tr("GACHA_TIER_STAR5")])
	assert_str(_node(s, "Wish_10").get("text")).contains("2520")


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


# ---------- Thẻ kết quả (owner 2026-11-15) ----------

func test_result_cards_sorted_and_colored_by_rarity() -> void:
	var s := _screen()
	s.select(0)
	s.last_results = [
		{"item": "item:mat_exp_small", "rarity": 1, "tier": "MAT", "duplicate": false},
		{"item": "char:char_dark_01", "rarity": 4, "tier": "A", "duplicate": true},
		{"item": "equip:eq_weapon_unyielding_peak", "rarity": 5, "tier": "X5", "duplicate": false},
		{"item": "char:char_fire_01", "rarity": 5, "tier": "S", "duplicate": false},
		{"item": "item:mat_enhance_crystal", "rarity": 1, "tier": "MAT", "duplicate": false},
	]
	s.open_overlay(RecruitScreen.Overlay.RESULTS)
	assert_array(s.result_order()).is_equal([3, 2, 1, 4, 0])          # S nhân vật, 5★ đồ, A, rồi vật phẩm theo sao
	var gold := s.layout.color("rank_s", Color.GOLD)
	var purple := s.layout.color("rank_a", Color.MEDIUM_PURPLE)
	var blue := s.layout.color("rank_b", Color.DEEP_SKY_BLUE)
	var border := func(i: int) -> Color:
		return ((_node(s, "ResultCard_%d" % i) as Panel).get_theme_stylebox("panel") as StyleBoxFlat).border_color
	assert_that(border.call(3)).is_equal(gold)
	assert_that(border.call(2)).is_equal(gold)
	assert_that(border.call(1)).is_equal(purple)
	assert_that(border.call(0)).is_equal(blue)                         # còn lại xanh dương
	# Enkiba có splash → ảnh thật phủ thẻ; Yomigari chưa có ảnh → hình người placeholder.
	assert_bool((_node(s, "ResultArt_3") as PlaceholderArt).is_placeholder()).is_false()
	assert_bool(s.result_art("char:char_fire_01")["cover"]).is_true()
	assert_object(_node(s, "ResultNew_3")).is_not_null()               # nhân vật mới
	assert_str(_text(s, "ResultDup_1")).is_equal(tr("RECRUIT_FRAGMENTS") % 10)   # trùng A → mảnh
	assert_str(_text(s, "ResultStars_2")).is_equal("★★★★★")
	assert_str(_text(s, "ResultStars_4")).is_equal("★★★")              # tinh thể cường hóa 3★


func test_results_reveal_left_to_right_and_skip() -> void:
	var s := _screen()
	s.profile.inventory.add_currency("gems", 3000)
	assert_bool(s.pull(10)).is_true()
	assert_float(s.reveal_total()).is_equal_approx(7.6, 0.001)         # owner: ×1.5 so với 11.4 s
	assert_int(s.revealed_count()).is_equal(0)
	assert_float(_node(s, "ResultSlot_0").modulate.a).is_less(0.2)
	s._process(0.8 * 3 + 0.4)                                         # 4 thẻ đầu đã hiện rõ
	assert_int(s.revealed_count()).is_equal(4)
	assert_float(_node(s, "ResultSlot_3").modulate.a).is_equal_approx(1.0, 0.001)
	assert_float(_node(s, "ResultSlot_0").position.x).is_equal_approx(0.0, 0.001)
	assert_float(_node(s, "ResultSlot_5").modulate.a).is_equal(0.0)   # thẻ bên phải chưa hiện
	assert_bool(_node(s, "ResultSkip").visible).is_true()
	(_node(s, "ResultSkip") as Button).pressed.emit()
	assert_int(s.revealed_count()).is_equal(10)
	assert_bool(s.is_revealing()).is_false()
	assert_bool(_node(s, "ResultSkip").visible).is_false()
	s.refresh()                                                       # dựng lại màn: vẫn hiện hết
	assert_float(_node(s, "ResultSlot_9").modulate.a).is_equal_approx(1.0, 0.001)
	assert_bool(s.intercept_back()).is_true()
	s.pull(1)                                                         # lượt mới: chạy lại từ đầu
	assert_float(s.reveal_total()).is_equal_approx(0.4, 0.001)
	assert_bool(s.is_revealing()).is_true()


func test_five_star_card_has_light_effect() -> void:
	var s := _screen()
	s.select(0)
	s.last_results = [
		{"item": "char:char_fire_01", "rarity": 5, "tier": "S", "duplicate": false},
		{"item": "item:mat_exp_small", "rarity": 1, "tier": "MAT", "duplicate": false},
	]
	s.open_overlay(RecruitScreen.Overlay.RESULTS)
	assert_object(_node(s, "ResultGlow_0")).is_not_null()            # 5★ có quầng, cột sáng, chớp
	assert_object(_node(s, "ResultBeam_0")).is_not_null()
	assert_object(_node(s, "ResultFlash_0")).is_not_null()
	assert_object(_node(s, "ResultGlow_1")).is_null()                # thẻ thường không có
	var spark := s.find_child("ResultSpark_0", true, false) as CPUParticles2D
	var drift := s.find_child("ResultDrift_0", true, false) as CPUParticles2D
	assert_object(spark).is_not_null()                               # hạt lấp lánh
	assert_object(s.find_child("ResultSpark_1", true, false)).is_null()
	assert_bool(drift.emitting).is_true()                            # thẻ đầu bắt đầu hiện ngay ở giây 0
	assert_float(_node(s, "ResultGlow_0").modulate.a).is_equal(0.0)   # chưa tới lượt thẻ
	s._process(0.15)
	assert_float(_node(s, "ResultFlash_0").modulate.a).is_greater(0.3)   # chớp sáng lúc thẻ hiện
	assert_float(s.shake_offset().length()).is_greater(0.0)               # đang rung
	assert_bool(spark.emitting).is_true()                                 # hạt bung lúc thẻ hiện
	assert_bool(drift.emitting).is_true()
	assert_float(s.shake_offset().length()).is_less_equal(14.0 * 1.25)
	s._process(0.6)
	assert_float(_node(s, "ResultFlash_0").modulate.a).is_equal(0.0)
	assert_that(s.shake_offset()).is_equal(Vector2.ZERO)                  # hết rung sau 0.45 s
	assert_float(_node(s, "ResultSlot_0").position.y).is_equal(0.0)
	assert_float(_node(s, "ResultGlow_0").modulate.a).is_greater(0.3)    # quầng còn sáng, nhấp nháy
	s.skip_reveal()
	assert_float(_node(s, "ResultBeam_0").modulate.a).is_greater(0.2)
	var audio := get_tree().root.get_node_or_null("AudioRouter")
	if audio:
		var n := (audio.requested as Array).count("sfx_gacha_5star")
		assert_int(n).is_greater_equal(1)                              # đã phát khi thẻ 5★ hiện
		s.refresh()
		s._process(0.1)
		assert_int((audio.requested as Array).count("sfx_gacha_5star")).is_equal(n)   # dựng lại không phát lại
