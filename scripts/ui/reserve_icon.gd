class_name ReserveIcon
extends Control
## Icon nhân vật dự bị trên HUD (README 15.5, 17.5; CHARACTER_SKILLS 8.3, 8.11):
## chân dung, thanh HP nhỏ, vòng hồi SI-CD, vòng sáng Liên kết. Chạm để chuyển nhân vật.
## Chỉ đọc state từ PartyManager / LinkTracker; không chứa luật gameplay.

const PORTRAIT_PATH := "res://assets/characters/%s/portrait/%s_portrait_full.png"

var party: PartyManager
## Ô dự bị: 0 = icon 1 (switch_1), 1 = icon 2 (switch_2).
var slot := 0
## Thành viên đang hiển thị (cập nhật mỗi lần `advance`).
var member: CharacterRuntime

## 0..1: độ hiện của vòng sáng (hiện 150 ms, mờ 300 ms).
var ring_visibility := 0.0
## Thời gian vòng nổ sáng còn lại sau khi dùng (s).
var burst_left := 0.0

var _pulse_t := 0.0
var _portraits: Dictionary = {}   # id -> Texture2D hoặc null


func _init() -> void:
	custom_minimum_size = Vector2.ONE * HudTheme.RESERVE_ICON_SIZE
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	advance(delta)
	queue_redraw()


## Cập nhật theo state của đội; tách riêng để test bước với delta cố định.
func advance(delta: float) -> void:
	member = _resolve_member()
	burst_left = maxf(burst_left - delta, 0.0)
	if is_glowing():
		ring_visibility = minf(ring_visibility + delta / HudTheme.RING_FADE_IN_SEC, 1.0)
		_pulse_t += delta
	else:
		ring_visibility = maxf(ring_visibility - delta / HudTheme.RING_FADE_OUT_SEC, 0.0)
		if ring_visibility <= 0.0:
			_pulse_t = 0.0


func _resolve_member() -> CharacterRuntime:
	if party == null or not is_instance_valid(party):
		return null
	var r := party.reserves()
	return r[slot] if slot < r.size() else null


# ---------- State để vẽ (và để test) ----------

func is_glowing() -> bool:
	return member != null and party.links != null and party.links.is_glowing(member)


func is_down() -> bool:
	return member != null and member.is_down()


func hp_ratio() -> float:
	return member.resources().hp_ratio() if member else 0.0


## 0 = SI-CD đã hồi; 1 = vừa bắt đầu hồi.
func si_cd_ratio() -> float:
	if member == null or party.links == null:
		return 0.0
	var cds := member.combatant().cooldowns
	var total := cds.duration_of(LinkTracker.SI_CD_KEY)
	return clampf(party.links.si_cd_left(member) / total, 0.0, 1.0) if total > 0.0 else 0.0


## Phần cửa sổ Liên kết còn lại (1 → 0 trong 6.0 s): cung mỏng co dần.
func arc_ratio() -> float:
	if member == null or party.links == null or party.rules.link_window_sec <= 0.0:
		return 0.0
	return clampf(party.links.window_left(member) / party.rules.link_window_sec, 0.0, 1.0)


## Nhịp đập 0..1 chu kỳ 0.8 s.
func pulse() -> float:
	return 0.5 - 0.5 * cos(TAU * _pulse_t / HudTheme.RING_PULSE_SEC)


func ring_scale() -> float:
	return lerpf(1.0, HudTheme.RING_SCALE_MAX, pulse())


func ring_brightness() -> float:
	return lerpf(HudTheme.RING_BRIGHT_MIN, HudTheme.RING_BRIGHT_MAX, pulse())


## Vừa chuyển sang nhân vật của icon này bằng Liên kết: vòng nổ sáng 200 ms.
func notify_link_used() -> void:
	burst_left = HudTheme.RING_BURST_SEC
	ring_visibility = 0.0


# ---------- Chạm ----------

func _gui_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		pressed = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	elif event is InputEventScreenTouch:
		pressed = event.pressed
	if pressed:
		tap()
		accept_event()


func tap() -> void:
	if party and is_instance_valid(party):
		party.press_switch(slot)


# ---------- Vẽ ----------

func _draw() -> void:
	if member == null:
		return
	var c := size * 0.5 + Vector2(0, -8)
	var col := HudTheme.ring_color(member.element())
	var down := is_down()
	# Nền + chân dung.
	draw_circle(c, HudTheme.RESERVE_PORTRAIT_RADIUS + 4.0, HudTheme.COLOR_PANEL)
	var tex := _portrait(member.id)
	var pr := HudTheme.RESERVE_PORTRAIT_RADIUS
	if tex:
		# Lấy phần đầu (40% trên) của ảnh đứng.
		var side := minf(tex.get_width(), tex.get_height() * 0.42)
		var src := Rect2((tex.get_width() - side) * 0.5, 0, side, side)
		draw_texture_rect_region(tex, Rect2(c - Vector2(pr, pr) * 0.92, Vector2(pr, pr) * 1.84), src,
				HudTheme.COLOR_DOWN if down else Color.WHITE)
	else:
		draw_circle(c, pr, HudTheme.COLOR_DOWN if down else col.darkened(0.25))
		var font := ThemeDB.fallback_font
		var letter := tr(member.def().name_key).substr(0, 1)
		draw_string(font, c + Vector2(-pr, 18), letter, HORIZONTAL_ALIGNMENT_CENTER, pr * 2.0, 52, Color.WHITE)
	# Vòng hồi SI-CD: quạt tối phủ lên chân dung, co theo thời gian còn lại + số giây.
	var cd := si_cd_ratio()
	if cd > 0.0 and not down:
		var pts := PackedVector2Array([c])
		var steps := 32
		for i in steps + 1:
			var a := -PI / 2.0 + TAU * cd * float(i) / steps
			pts.append(c + Vector2(cos(a), sin(a)) * pr)
		draw_colored_polygon(pts, HudTheme.COLOR_COOLDOWN)
		draw_string(ThemeDB.fallback_font, c + Vector2(-pr, 12), "%.0f" % ceilf(party.links.si_cd_left(member)),
				HORIZONTAL_ALIGNMENT_CENTER, pr * 2.0, 36, Color.WHITE)
	# Vòng sáng Liên kết.
	if ring_visibility > 0.0:
		var rc := col
		rc.a = ring_visibility * ring_brightness()
		var rr := HudTheme.RESERVE_RING_RADIUS * ring_scale()
		draw_arc(c, rr, 0.0, TAU, 48, rc, HudTheme.RESERVE_RING_WIDTH, true)
		for i in HudTheme.RING_PARTICLES:
			var a := _pulse_t * 2.4 + TAU * float(i) / HudTheme.RING_PARTICLES
			draw_circle(c + Vector2(cos(a), sin(a)) * (rr + 8.0), 4.0, Color(1, 1, 1, rc.a))
		# Cung mỏng co dần theo cửa sổ 6.0 s.
		var ar := arc_ratio()
		if ar > 0.0:
			draw_arc(c, HudTheme.RESERVE_ARC_RADIUS * ring_scale(), -PI / 2.0, -PI / 2.0 + TAU * ar, 48,
					Color(1, 1, 1, 0.85 * ring_visibility), HudTheme.RESERVE_ARC_WIDTH, true)
	if burst_left > 0.0:
		var k := 1.0 - burst_left / HudTheme.RING_BURST_SEC
		var bc := col.lightened(0.5)
		bc.a = 1.0 - k
		draw_arc(c, HudTheme.RESERVE_RING_RADIUS * (1.0 + 0.5 * k), 0.0, TAU, 48, bc, HudTheme.RESERVE_RING_WIDTH * 1.6, true)
	# Thanh HP nhỏ dưới chân dung.
	var bw := pr * 2.0
	var bar := Rect2(c + Vector2(-pr, pr + 12.0), Vector2(bw, 8.0))
	draw_rect(bar, HudTheme.COLOR_BAR_BACK)
	draw_rect(Rect2(bar.position, Vector2(bw * hp_ratio(), 8.0)), HudTheme.COLOR_DOWN if down else HudTheme.COLOR_HP)
	if down:
		draw_line(c - Vector2(30, 30), c + Vector2(30, 30), Color(1, 0.3, 0.3), 6.0)
		draw_line(c + Vector2(-30, 30), c + Vector2(30, -30), Color(1, 0.3, 0.3), 6.0)


func _portrait(id: String) -> Texture2D:
	if not _portraits.has(id):
		var path := PORTRAIT_PATH % [id, id]
		_portraits[id] = load(path) if ResourceLoader.exists(path) else null
	return _portraits[id]
