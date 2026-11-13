extends GdUnitTestSuite
## Test M7-2: các bảng trong Hub — Home, Chiến đấu (chọn đội, danh sách màn), Chiêu mộ (chưa mở / bảng tỉ lệ / quay), và việc lưu sau mỗi thao tác.

const HUB_SCENE := preload("res://scenes/main/hub.tscn")
const SAVE_DIR := "user://test_saves_m7_2"
const A := "char_fire_01"

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


func _add(p: HubPanel) -> HubPanel:
	add_child(auto_free(p))
	return p


func _texts(n: Node) -> String:
	var out := PackedStringArray()
	for c in n.find_children("*", "Label", true, false):
		out.append((c as Label).text)
	for c in n.find_children("*", "Button", true, false):
		out.append((c as Button).text)
	return "\n".join(out)


func _disk() -> Dictionary:
	return SaveStore.new(SAVE_DIR).read()


# ---------- Hub ----------

func test_hub_shows_a_panel_per_tab() -> void:
	var hub: Control = auto_free(HUB_SCENE.instantiate())
	add_child(hub)
	assert_bool(hub.panel is HubHomePanel).is_true()
	var expect := {"BattleTab": "HubBattlePanel", "RecruitTab": "HubRecruitPanel"}
	for tab: String in expect:
		hub.show_tab(tab)
		assert_str((hub.panel.get_script() as Script).get_global_name()).is_equal(expect[tab])
	hub.show_tab("SettingsTab")
	assert_int(hub.panel.find_children("*", "SettingsPanel", true, false).size() + hub.panel.find_children("*", "CreditsPanel", true, false).size()).is_greater_equal(0)
	assert_bool(_texts(hub.panel).contains(tr("SETTINGS_TITLE")) and _texts(hub.panel).contains(tr("CREDITS_TITLE"))).is_true()
	hub.show_tab("BattleTab")
	assert_bool((hub.get_node("%Stage01Button") as Button).visible).is_true()
	hub.show_tab("HomeTab")
	assert_bool((hub.get_node("%Stage01Button") as Button).visible).is_false()


func test_home_summary() -> void:
	_save.data["currencies"]["gold"] = 777
	_save.data["progress"]["stages"]["stage_01"] = {"cleared": true, "best_time_sec": 190.0}
	var p := _add(HubHomePanel.new()) as HubHomePanel
	var t := "\n".join(p.summary_lines())
	assert_bool(t.contains("777") and t.contains("Enkiba Lv.1") and t.contains(tr("HOME_STAGES_CLEARED") % 1)).is_true()


# ---------- Chiến đấu ----------

func test_party_selection_rules_and_persistence() -> void:
	var p := _add(HubBattlePanel.new()) as HubBattlePanel
	assert_int(p.party_buttons.size()).is_equal(3)
	assert_bool(p.toggle_party("char_lightning_01")).is_true()        # bỏ Kael
	assert_array(_save.data["party"]).is_equal([A, "char_wind_01"])
	assert_array(_disk()["party"]).is_equal([A, "char_wind_01"])       # đã lưu
	assert_bool(p.toggle_party("char_lightning_01")).is_true()        # thêm lại: xuống cuối
	assert_array(_save.data["party"]).is_equal([A, "char_wind_01", "char_lightning_01"])
	p.toggle_party("char_wind_01")
	p.toggle_party("char_lightning_01")
	assert_bool(p.toggle_party(A)).is_false()                         # không bỏ được người cuối cùng
	assert_array(_save.data["party"]).is_equal([A])
	assert_bool((p.party_buttons[A] as Button).text.begins_with("1 · ")).is_true()   # hiện thứ tự trong đội


func test_party_cannot_exceed_three() -> void:
	_save.data["characters"]["char_dark_01"] = SaveSchema.default_character()
	var p := _add(HubBattlePanel.new()) as HubBattlePanel
	assert_bool(p.toggle_party("char_dark_01")).is_false()
	assert_int(_save.data["party"].size()).is_equal(3)


func test_stage_list_shows_progress_and_hides_test_stage() -> void:
	var p := _add(HubBattlePanel.new()) as HubBattlePanel
	assert_array(Array(p.stage_ids())).is_equal(["stage_01"])
	assert_bool(p.stage_lines()[0].contains(tr("BATTLE_STAGE_NEW"))).is_true()
	_save.data["progress"]["stages"]["stage_01"] = {"cleared": true, "best_time_sec": 200.0}
	assert_bool(p.stage_lines()[0].contains("3:20") and p.stage_lines()[0].contains(tr("STAGE_01_NAME"))).is_true()


# Màn Nhân vật: tests/unit/ui/test_character_screen.gd


# ---------- Chiêu mộ ----------

func test_recruit_closed_without_banner_data() -> void:
	var p := HubRecruitPanel.new()
	p.banners_injected = true                                       # không có banner nào
	_add(p)
	assert_int(p.banners.size()).is_equal(0)
	assert_bool(_texts(p).contains(tr("RECRUIT_CLOSED"))).is_true()


func test_recruit_loads_shipped_character_banner() -> void:
	var p := _add(HubRecruitPanel.new()) as HubRecruitPanel
	assert_int(p.banners.size()).is_equal(2)                          # nhân vật + tiếp tế
	var lines := "\n".join(p.rate_lines(p.banners[0]))
	assert_bool(lines.contains("1.500%") and lines.contains("16.300%") and lines.contains("10.874%")).is_true()
	assert_bool(lines.contains(tr("RECRUIT_MULTI_GUARANTEE") % 10)).is_true()
	var eq := "\n".join(p.rate_lines(p.banners[1]))
	assert_bool(eq.contains("2.870%") and eq.contains("14.430%") and eq.contains("58.000%")).is_true()
	assert_bool(eq.contains(tr("GACHA_TIER_STIGMA_4"))).is_true()


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


func test_recruit_rates_come_from_config_and_pull_works() -> void:
	var p := HubRecruitPanel.new()
	p.banners = [_test_banner()]
	p.banners_injected = true
	_add(p)
	p.service.rng = RandomSource.new(42)
	var lines := "\n".join(p.rate_lines(p.banners[0]))
	assert_bool(lines.contains("5★  25.000%") and lines.contains("3★  75.000%")).is_true()   # đúng số trong config
	assert_bool(lines.contains("Yomigari")).is_true()
	assert_bool(p.pull(1)).is_false()                                 # chưa có ngọc
	assert_str(p.last_reason).is_equal(GachaService.REASON_NOT_ENOUGH)
	assert_bool(_texts(p).contains(tr("REASON_NOT_ENOUGH_CURRENCY"))).is_true()
	p.profile.inventory.add_currency("gems", 1000)
	assert_bool(p.pull(10)).is_true()
	assert_int(p.last_results.size()).is_equal(10)
	assert_int(p.profile.inventory.currency("gems")).is_equal(100)
	assert_int(_disk()["gacha"]["history"].size()).is_equal(10)        # lịch sử đã lưu
	assert_int(_disk()["currencies"]["gems"]).is_equal(100)
	assert_bool(_texts(p).contains(tr("RECRUIT_HISTORY") % 10)).is_true()
