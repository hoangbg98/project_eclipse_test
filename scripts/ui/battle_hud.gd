class_name BattleHud
extends CanvasLayer
## HUD trận đấu (README 15.5): thẻ nhân vật trên sân (góc trên-trái: tên, HP, khiên, EN, UG, lượt né)
## và hai icon dự bị (góc trên-phải, chạm để chuyển). Chỉ đọc state; vị trí và màu ở HudTheme.
## Nút kỹ năng có vòng hồi, nút Pause: M7.

var party: PartyManager
var icons: Array[ReserveIcon] = []

var _card: Control
## Nút Tạm dừng, đặt cạnh thẻ nhân vật, xa icon dự bị (README 15.5).
var pause_button: Button


func _ready() -> void:
	layer = 60
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_card = Control.new()
	_card.position = HudTheme.ACTIVE_CARD_POS
	_card.size = HudTheme.ACTIVE_CARD_SIZE
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.draw.connect(_draw_card)
	root.add_child(_card)

	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "II"
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.add_theme_font_size_override("font_size", 40)
	pause_button.position = HudTheme.ACTIVE_CARD_POS + Vector2(0.0, HudTheme.ACTIVE_CARD_SIZE.y + 290.0)
	pause_button.size = Vector2.ONE * HudTheme.PAUSE_BUTTON_SIZE
	pause_button.pressed.connect(func() -> void:
		var menu := get_parent().get_node_or_null("PauseMenu") if get_parent() else null
		if menu and menu.has_method("open"):
			menu.open())
	root.add_child(pause_button)
	UiKit.apply_safe_area(root)

	var s := HudTheme.RESERVE_ICON_SIZE
	for i in 2:
		var icon := ReserveIcon.new()
		icon.name = "ReserveIcon%d" % (i + 1)
		icon.slot = i
		icon.party = party
		# Neo góc trên-phải: icon 1 nằm ngoài cùng bên trái của cụm, icon 2 sát mép phải.
		icon.anchor_left = 1.0
		icon.anchor_right = 1.0
		var x := -HudTheme.RESERVE_MARGIN.x - s - (1 - i) * (s + HudTheme.RESERVE_ICON_GAP)
		icon.offset_left = x
		icon.offset_right = x + s
		icon.offset_top = HudTheme.RESERVE_MARGIN.y
		icon.offset_bottom = HudTheme.RESERVE_MARGIN.y + s
		root.add_child(icon)
		icons.append(icon)
	if party:
		bind(party)


func bind(p: PartyManager) -> void:
	party = p
	for icon in icons:
		icon.party = p
	if not p.switched.is_connected(_on_switched):
		p.switched.connect(_on_switched)


func _process(_delta: float) -> void:
	if _card:
		_card.queue_redraw()


## Vào sân Liên kết: icon của người vừa vào nổ sáng 200 ms (icon còn giữ thành viên cũ tới lần cập nhật kế).
func _on_switched(_from: CharacterRuntime, to: CharacterRuntime, mode: String) -> void:
	if mode != LinkTracker.MODE_LINKED:
		return
	for icon in icons:
		if icon.member == to:
			icon.notify_link_used()


func _draw_card() -> void:
	if party == null or not is_instance_valid(party) or party.active() == null:
		return
	var m := party.active()
	var r := m.resources()
	var font := ThemeDB.fallback_font
	_card.draw_rect(Rect2(Vector2.ZERO, HudTheme.ACTIVE_CARD_SIZE), HudTheme.COLOR_PANEL)
	var col := HudTheme.ring_color(m.element())
	_card.draw_circle(Vector2(62, 66), 46.0, col.darkened(0.2))
	_card.draw_string(font, Vector2(16, 82), tr(m.def().name_key).substr(0, 1), HORIZONTAL_ALIGNMENT_CENTER, 92, 48, Color.WHITE)
	var x := 124.0
	_card.draw_string(font, Vector2(x, 34), tr(m.def().name_key), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
	_card.draw_string(font, Vector2(x + HudTheme.BAR_WIDTH - 150, 34), "%d / %d" % [int(r.hp), int(r.max_hp)],
			HORIZONTAL_ALIGNMENT_RIGHT, 150, 20, Color(1, 1, 1, 0.85))
	# HP (+ khiên chồng lên phía phải phần máu).
	var hp := Rect2(Vector2(x, 44), Vector2(HudTheme.BAR_WIDTH, HudTheme.HP_BAR_HEIGHT))
	_card.draw_rect(hp, HudTheme.COLOR_BAR_BACK)
	var ratio := r.hp_ratio()
	_card.draw_rect(Rect2(hp.position, Vector2(hp.size.x * ratio, hp.size.y)),
			HudTheme.COLOR_HP_LOW if ratio <= 0.3 else HudTheme.COLOR_HP)
	if r.shield > 0.0:
		var sw := hp.size.x * clampf(r.shield / r.max_hp, 0.0, 1.0)
		_card.draw_rect(Rect2(hp.position + Vector2(0, hp.size.y - 6), Vector2(sw, 6)), HudTheme.COLOR_SHIELD)
	# EN, UG.
	var en := Rect2(Vector2(x, 74), Vector2(HudTheme.BAR_WIDTH, HudTheme.SMALL_BAR_HEIGHT))
	_card.draw_rect(en, HudTheme.COLOR_BAR_BACK)
	_card.draw_rect(Rect2(en.position, Vector2(en.size.x * r.en / r.rules.en_max, en.size.y)), HudTheme.COLOR_EN)
	var ug := Rect2(Vector2(x, 92), Vector2(HudTheme.BAR_WIDTH, HudTheme.SMALL_BAR_HEIGHT))
	_card.draw_rect(ug, HudTheme.COLOR_BAR_BACK)
	var ugc := HudTheme.COLOR_UG if r.is_ultimate_ready() else HudTheme.COLOR_UG.darkened(0.35)
	_card.draw_rect(Rect2(ug.position, Vector2(ug.size.x * r.ug / r.rules.ug_max, ug.size.y)), ugc)
	# Lượt né.
	for i in r.rules.dodge_charges:
		_card.draw_circle(Vector2(x + 8 + i * 22, 118), 7.0,
				Color.WHITE if i < r.dodge_charges else Color(1, 1, 1, 0.25))
