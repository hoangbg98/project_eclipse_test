class_name HubBackgroundPanel
extends HubPanel
## Bảng nổi Đổi nền sảnh (nút khung tranh góc phải, owner 2026-11-14): thẻ mỗi nền (ảnh thu nhỏ, tên, trạng thái).
## Nút theo trạng thái: Đang dùng / Dùng (đã có) / Mua N ngọc (bán trong shop) / cách nhận (chỉ từ sự kiện).
## Chỉ gọi PlayerProfile (set_hub_background, buy_background); dữ liệu nền ở data/backgrounds/.

const CARD := Vector2(460, 330)

var action_buttons: Dictionary = {}   # id -> Button
var last_reason := ""


func build() -> void:
	action_buttons.clear()
	var hint := UiKit.label(tr("BG_PANEL_HINT"), 26)
	add_child(hint)
	if last_reason != "":
		var n := UiKit.label(tr("BG_ERR_" + last_reason.to_upper()), 26)
		n.name = "Notice"
		n.add_theme_color_override("font_color", Color("#FFB347"))
		add_child(n)
	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	for b in profile.all_backgrounds():
		grid.add_child(_card(b))
	add_child(UiKit.scroll(grid))


func _card(b: BackgroundDef) -> Control:
	var box := UiKit.vbox(8)
	box.name = "Bg_" + b.id
	box.custom_minimum_size = CARD
	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(CARD.x, CARD.y * 0.6)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.texture = load(b.image) as Texture2D if ResourceLoader.exists(b.image) else null
	thumb.clip_contents = true
	box.add_child(thumb)
	box.add_child(UiKit.label(tr(b.name_key), 30))
	var current := profile.hub_background() == b.id
	var btn: Button
	if current:
		btn = UiKit.button(tr("BG_IN_USE"), CARD.x, 28)
		btn.disabled = true
	elif profile.owns_background(b.id):
		btn = UiKit.button(tr("BG_USE"), CARD.x, 28)
		btn.pressed.connect(use.bind(b.id))
	elif b.price_gems > 0:
		btn = UiKit.button(tr("BG_BUY") % b.price_gems, CARD.x, 28)
		btn.pressed.connect(buy.bind(b.id))
	else:
		btn = UiKit.button(tr(b.how_to_get_key) if b.how_to_get_key != "" else tr("BG_FROM_EVENT"), CARD.x, 26)
		btn.disabled = true
	btn.name = "Action"
	box.add_child(btn)
	action_buttons[b.id] = btn
	return box


func use(id: String) -> String:
	last_reason = profile.set_hub_background(id)
	if last_reason == PlayerProfile.BG_OK:
		commit()
	else:
		refresh()
	return last_reason


func buy(id: String) -> String:
	last_reason = profile.buy_background(id)
	if last_reason == PlayerProfile.BG_OK:
		profile.set_hub_background(id)
		commit()
	else:
		refresh()
	return last_reason
