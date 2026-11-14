class_name BattleHud
extends CanvasLayer
## HUD trận đấu (README 15.5): thanh nhân vật trên sân (giữa-dưới: chân dung, tên, HP, khiên, EN; owner
## 2026-11-14 chuyển từ góc trên-trái xuống), hai icon dự bị (góc trên-phải, chạm để chuyển), nút Tạm dừng
## (góc trên-trái). Cụm nút kỹ năng có hồi chiêu ở TouchControls. Chỉ đọc state; vị trí và màu ở HudTheme.

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

	# Thanh nhân vật trên sân: neo giữa-dưới (owner 2026-11-14), lệch trái để chừa cụm nút kỹ năng.
	_card = Control.new()
	_card.name = "Vitals"
	var vs := HudTheme.VITALS_SIZE
	_card.anchor_left = 0.5
	_card.anchor_right = 0.5
	_card.anchor_top = 1.0
	_card.anchor_bottom = 1.0
	_card.offset_left = HudTheme.VITALS_CENTER_OFFSET_X - vs.x * 0.5
	_card.offset_right = _card.offset_left + vs.x
	_card.offset_bottom = -HudTheme.VITALS_BOTTOM_MARGIN
	_card.offset_top = _card.offset_bottom - vs.y
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.draw.connect(_draw_card)
	root.add_child(_card)

	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "II"
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.add_theme_font_size_override("font_size", 40)
	pause_button.position = HudTheme.ACTIVE_CARD_POS
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


## Thanh giữa-dưới: chân dung tạm (màu nguyên tố + chữ đầu tên), tên, HP (chia 3 đoạn) + khiên, EN.
## Hồi chiêu, UG và lượt né nằm trên cụm nút kỹ năng (TouchControls).
func _draw_card() -> void:
	if party == null or not is_instance_valid(party) or party.active() == null:
		return
	var m := party.active()
	var r := m.resources()
	var font := ThemeDB.fallback_font
	var pr := HudTheme.VITALS_PORTRAIT_RADIUS
	var pc := Vector2(pr + 4.0, HudTheme.VITALS_SIZE.y - pr - 8.0)
	var col := HudTheme.ring_color(m.element())
	_card.draw_circle(pc, pr + 4.0, Color(0, 0, 0, 0.55))
	_card.draw_circle(pc, pr, col.darkened(0.25))
	_card.draw_arc(pc, pr, 0.0, TAU, 48, col, 4.0)
	var nm := tr(m.def().name_key)
	var initial := nm.substr(0, 1)
	var isz := font.get_string_size(initial, HORIZONTAL_ALIGNMENT_LEFT, -1, 44)
	_card.draw_string(font, pc + Vector2(-isz.x * 0.5, font.get_ascent(44) - isz.y * 0.5), initial,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color.WHITE)
	var x := pc.x + pr + 24.0
	var w := HudTheme.BAR_WIDTH
	# Hàng chữ: tên bên trái, HP bên phải.
	var hp_y := 46.0
	_text(font, Vector2(x, hp_y - 12.0), nm, 26, Color.WHITE)
	var hp_text := "%d/%d" % [int(r.hp), int(r.max_hp)]
	var hsz := font.get_string_size(hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28)
	_text(font, Vector2(x + w - hsz.x, hp_y - 12.0), hp_text, 28, Color.WHITE)
	# HP: nền, phần máu, vạch chia 3 đoạn, khiên chồng mép dưới.
	var hp := Rect2(Vector2(x, hp_y), Vector2(w, HudTheme.HP_BAR_HEIGHT))
	_card.draw_rect(hp.grow(3.0), Color(0, 0, 0, 0.55))
	_card.draw_rect(hp, HudTheme.COLOR_BAR_BACK)
	var ratio := r.hp_ratio()
	_card.draw_rect(Rect2(hp.position, Vector2(hp.size.x * ratio, hp.size.y)),
			HudTheme.COLOR_HP_LOW if ratio <= 0.3 else HudTheme.COLOR_HP)
	for i: int in [1, 2]:
		var sx := hp.position.x + hp.size.x * i / 3.0
		_card.draw_line(Vector2(sx, hp.position.y), Vector2(sx, hp.end.y), Color(0, 0, 0, 0.6), 3.0)
	if r.shield > 0.0:
		var sw := hp.size.x * clampf(r.shield / r.max_hp, 0.0, 1.0)
		_card.draw_rect(Rect2(hp.position + Vector2(0, hp.size.y - 7), Vector2(sw, 7)), HudTheme.COLOR_SHIELD)
	# EN + số.
	var en := Rect2(Vector2(x, hp.end.y + 10.0), Vector2(w, HudTheme.SMALL_BAR_HEIGHT))
	_card.draw_rect(en.grow(2.0), Color(0, 0, 0, 0.55))
	_card.draw_rect(en, HudTheme.COLOR_BAR_BACK)
	_card.draw_rect(Rect2(en.position, Vector2(en.size.x * clampf(r.en / r.rules.en_max, 0.0, 1.0), en.size.y)),
			HudTheme.COLOR_EN)
	var en_text := "EN %d/%d" % [int(r.en), int(r.rules.en_max)]
	var esz := font.get_string_size(en_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	_text(font, Vector2(x + w - esz.x, en.end.y + 26.0), en_text, 22, Color(0.75, 0.88, 1.0))


func _text(font: Font, pos: Vector2, s: String, size_px: int, color: Color) -> void:
	_card.draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, 6, Color(0, 0, 0, 0.8))
	_card.draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)
