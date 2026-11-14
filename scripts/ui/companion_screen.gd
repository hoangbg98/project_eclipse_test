class_name CompanionScreen
extends HubScreen
## Người cộng tác (nút lục giác, owner 2026-11-14): tính năng riêng, CHƯA làm gameplay. Màn giới thiệu kế hoạch:
## một tinh linh nhỏ bay theo nhân vật trên sân, tự trợ chiến, tích năng lượng tinh linh và dùng kỹ năng chủ động khi
## đầy. Thiết kế chi tiết: docs/design/HUB_FEATURES.md mục Người cộng tác.


func screen_title() -> String:
	return tr("COMPANION_TITLE")


func _build_body() -> void:
	var ar := layout.rect("companion.art", Rect2(140, 150, 620, 700))
	_panel(ar, layout.color("panel_light", Color(0.16, 0.2, 0.31, 0.9)), "Art")
	_icon(Rect2(ar.position + ar.size * 0.15, ar.size * 0.7), "companion", layout.color("accent_blue", Color("#7FD4FF")))
	var pr := layout.rect("companion.panel", Rect2(820, 150, 960, 700))
	_panel(pr, layout.color("panel", Color(0.08, 0.09, 0.12, 0.85)), "Info")
	var tf := int(layout.num("companion.panel.title_font", 52))
	var f := int(layout.num("companion.panel.font", 30))
	_label(Rect2(pr.position + Vector2(40, 30), Vector2(pr.size.x - 80, tf * 1.4)), tr("COMPANION_TITLE"), tf)
	_label(Rect2(pr.position + Vector2(pr.size.x - 300, 40), Vector2(260, 50)), tr("HUB_BADGE_SOON"), f,
			layout.color("soon", Color.ORANGE), HORIZONTAL_ALIGNMENT_RIGHT).name = "Soon"
	var lines := PackedStringArray()
	for k in ["COMPANION_POINT_1", "COMPANION_POINT_2", "COMPANION_POINT_3", "COMPANION_POINT_4"]:
		lines.append("•  " + tr(k))
	_label(Rect2(pr.position + Vector2(40, 40 + tf * 1.8), Vector2(pr.size.x - 80, pr.size.y - tf * 2.4 - 60)),
			tr("COMPANION_DESC") + "\n\n" + "\n".join(lines), f)
