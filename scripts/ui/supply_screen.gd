class_name SupplyScreen
extends HubScreen
## Tiếp tế (nút lục giác Tiếp tế, owner 2026-11-14, theo ảnh tham chiếu): 3 thẻ
## - Shop: bán vũ khí, vết thánh, tài nguyên — chưa có (thông báo Sắp ra mắt);
## - Tiếp tế: chiêu mộ (gacha) → màn RecruitScreen;
## - Nạp: chỉ có nếu game phát hành online (docs/design/HUB_FEATURES.md mục Nạp) — bản offline hiện thông báo.
## Dải dưới: Rèn trang bị (chưa có), Sắp ra mắt.

## Thẻ: [khóa, icon, màu vạch trên, khóa tiêu đề, khóa mô tả, khóa nút].
const CARDS := [
	["shop", "shop", "card_line_shop", "SUPPLY_SHOP_TITLE", "SUPPLY_SHOP_DESC", "SUPPLY_SHOP_GO"],
	["gacha", "gacha", "card_line_gacha", "SUPPLY_GACHA_TITLE", "SUPPLY_GACHA_DESC", "SUPPLY_GACHA_GO"],
	["topup", "topup", "card_line_topup", "SUPPLY_TOPUP_TITLE", "SUPPLY_TOPUP_DESC", "SUPPLY_TOPUP_GO"],
]
## Bản phát hành online mới mở Nạp (cấu hình phát hành, không phải luật gameplay).
const ONLINE_BUILD := false

var action_buttons: Dictionary = {}


func screen_title() -> String:
	return tr("SUPPLY_TITLE")


func _build_body() -> void:
	action_buttons.clear()
	var tf := int(layout.num("supply.cards.title_font", 52))
	var bf := int(layout.num("supply.cards.body_font", 26))
	var btf := int(layout.num("supply.cards.button_font", 32))
	for i in CARDS.size():
		var c: Array = CARDS[i]
		var r := layout.rect_in("supply.cards.rects", i, "center", Rect2(300 + 480 * i, 112, 440, 640))
		var line := layout.color(str(c[2]), Color.WHITE)
		_panel(Rect2(r.position - Vector2(0, 24), Vector2(r.size.x, 8)), line)
		_panel(r, layout.color("panel_light", Color(0.16, 0.2, 0.31, 0.9)), "Card_" + str(c[0]))
		_label(Rect2(r.position + Vector2(24, 12), Vector2(r.size.x - 48, tf * 1.4)), tr(str(c[3])), tf)
		_icon(Rect2(r.position + Vector2(r.size.x * 0.2, tf * 1.6), Vector2(r.size.x * 0.6, r.size.x * 0.6)), str(c[1]), line.lightened(0.3))
		_label(Rect2(r.position + Vector2(24, r.size.y * 0.56), Vector2(r.size.x - 48, r.size.y * 0.24)), tr(str(c[4])), bf,
				Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		var b := _yellow_button(Rect2(r.position + Vector2(24, r.size.y - 112), Vector2(r.size.x - 48, 88)), tr(str(c[5])), btf,
				activate.bind(str(c[0])), "Go_" + str(c[0]))
		action_buttons[str(c[0])] = b
		if str(c[0]) == "topup" and not ONLINE_BUILD:
			_label(Rect2(r.position + Vector2(r.size.x - 220, r.size.y - 150), Vector2(200, 36)), tr("SUPPLY_ONLINE_ONLY"), 22,
					layout.color("soon", Color.ORANGE), HORIZONTAL_ALIGNMENT_RIGHT)
		elif str(c[0]) == "shop":
			_label(Rect2(r.position + Vector2(r.size.x - 220, r.size.y - 150), Vector2(200, 36)), tr("HUB_BADGE_SOON"), 24,
					layout.color("soon", Color.ORANGE), HORIZONTAL_ALIGNMENT_RIGHT)
	var bot := layout.rect("supply.bottom", Rect2(0, 790, 1920, 120))
	_panel(bot, layout.color("panel", Color(0.08, 0.09, 0.12, 0.85)))
	var f := int(layout.num("supply.bottom.font", 32))
	_button(Rect2(bot.position + Vector2(400, 20), Vector2(380, bot.size.y - 40)), tr("SUPPLY_FORGE") + " ▶", f,
			say.bind(tr("UI_COMING_SOON")), false, "Forge")
	_label(Rect2(bot.position + Vector2(1200, 20), Vector2(380, bot.size.y - 40)), tr("UI_COMING_SOON") + " ▶", f,
			layout.color("text_dim", Color(0.72, 0.74, 0.8)), HORIZONTAL_ALIGNMENT_CENTER)


func activate(key: String) -> void:
	match key:
		"gacha":
			open_scene("SCENE_RECRUIT")
		"topup":
			say(tr("SUPPLY_TOPUP_OFFLINE") if not ONLINE_BUILD else tr("UI_COMING_SOON"))
		_:
			say(tr("UI_COMING_SOON"))
