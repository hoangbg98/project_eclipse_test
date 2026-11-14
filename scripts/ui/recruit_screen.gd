class_name RecruitScreen
extends LayoutScreen
## Màn Chiêu mộ (owner 2026-11-13, theo ảnh tham chiếu màn Wish): danh sách banner bên trái, banner lớn ở giữa
## (nhãn loại, tiêu đề, ô bảo đảm, nhân vật / vật phẩm đề cử, thời gian còn lại), nút Cửa hàng / Chi tiết / Lịch sử và
## Chiêu mộ ×1 / ×10 phía dưới. Tỉ lệ đầy đủ nằm ở bảng Chi tiết, không trên màn chính.
## Vị trí, cỡ chữ, màu đọc từ data/ui/recruit_screen_layout.json. Ảnh banner theo quy ước trong assets/ui/recruit/.
## Màn chỉ gọi GachaService / PlayerProfile; không tự chứa luật quay.

const LAYOUT_PATH := "res://data/ui/recruit_screen_layout.json"
const BANNERS_DIR := "res://data/banners"
## Lượt x10 miễn phí đầu tiên (cần vé nhận ở ải 1-1): chỉ hiện, ở đầu danh sách, khi còn dùng được.
const STARTER_PATH := "res://data/tutorial/starter_pull.tres"
const ART_DIR := "res://assets/ui/recruit"
const HISTORY_SHOWN := 50

enum Overlay { NONE, DETAILS, HISTORY, RESULTS }

var banners: Array[BannerDef] = []
var selected := 0
var service: GachaService
var overlay := Overlay.NONE
var last_results: Array = []
var last_reason := ""
## Test gán sẵn banner để không cần file trong data/.
var banners_injected := false
## Test gán giờ giả (giây Unix); -1 = giờ thật.
var now_unix := -1


func _layout_path() -> String:
	return LAYOUT_PATH


func _ready() -> void:
	_setup_layout()
	if not banners_injected:
		banners = load_banners()
	if service == null:
		service = GachaService.new(profile)
	if not banners_injected:
		add_starter(load(STARTER_PATH) as BannerDef if ResourceLoader.exists(STARTER_PATH) else null)
	refresh()


## Đặt banner lượt miễn phí lên đầu danh sách và chọn nó nếu người chơi còn dùng được (đã có vé, chưa dùng).
func add_starter(b: BannerDef) -> void:
	if b == null or not b.validate().is_empty() or not service.starter_available(b) or b in banners:
		return
	banners.insert(0, b)
	selected = 0


func is_starter(b: BannerDef) -> bool:
	return b != null and b.starter_free_multi


static func load_banners() -> Array[BannerDef]:
	var out: Array[BannerDef] = []
	if not DirAccess.dir_exists_absolute(BANNERS_DIR):
		return out
	var files := Array(ResourceLoader.list_directory(BANNERS_DIR))
	files.sort()
	for f: String in files:
		if f.get_extension() in ["tres", "res"]:
			var b := load(BANNERS_DIR.path_join(f)) as BannerDef
			if b and b.validate().is_empty() and not b.starter_free_multi:
				out.append(b)
	return out


# ---------- Dữ liệu hiển thị ----------

func current() -> BannerDef:
	return banners[selected] if selected >= 0 and selected < banners.size() else null


func select(i: int) -> void:
	if i >= 0 and i < banners.size():
		selected = i
		overlay = Overlay.NONE
		notice = ""
		refresh()


func char_def(id: String) -> CharacterDef:
	var p := PlayerProfile.CHARACTER_DATA % id
	return load(p) as CharacterDef if ResourceLoader.exists(p) else null


func char_name(id: String) -> String:
	var d := char_def(id)
	return tr(d.name_key) if d else id


func banner_title(b: BannerDef) -> String:
	return tr(b.title_key if b.title_key != "" else b.name_key)


## Ảnh banner / ảnh nhỏ: đường dẫn ghi trong BannerDef, rồi quy ước `{id}_{kind}.png`, rồi bản placeholder; null = vẽ hình người.
func art_texture(b: BannerDef, kind: String) -> Texture2D:
	var explicit := b.banner_art if kind == "banner" else b.thumb_art
	for p: String in [explicit, "%s/%s_%s.png" % [ART_DIR, b.id, kind], "%s/placeholder_%s_%s.png" % [ART_DIR, b.id, kind]]:
		if p != "" and ResourceLoader.exists(p):
			return load(p) as Texture2D
	return null


## Nhân vật / vật phẩm đề cử của banner: {name, stars, element, sub}; rỗng nếu banner không có rate-up.
func featured(b: BannerDef) -> Dictionary:
	if is_starter(b) and not b.tiers.is_empty() and not b.tiers[0].pool.is_empty() and b.tiers[0].pool[0].begins_with("char:"):
		var sid := b.tiers[0].pool[0].get_slice(":", 1)
		var sd := char_def(sid)
		return {"kind": "char", "name": char_name(sid), "stars": b.tiers[0].rarity, "element": sd.element if sd else "",
				"sub": tr(sd.suit_key) if sd and sd.suit_key != "" else ""}
	var extra := 0
	var first := {}
	for t in b.tiers:
		if t == null or t.featured.is_empty():
			continue
		if first.is_empty():
			var item := t.featured[0]
			var id := item.get_slice(":", 1)
			if item.begins_with("char:"):
				var d := char_def(id)
				first = {"kind": "char", "name": char_name(id), "stars": t.rarity, "element": d.element if d else "",
						"sub": tr(d.suit_key) if d and d.suit_key != "" else ""}
			else:
				var e := PlayerProfile.equipment_defs().get_def(id) as EquipmentDef
				first = {"kind": "equip", "name": tr(e.name_key) if e else id, "stars": e.rarity if e else t.rarity, "element": "", "sub": ""}
			extra += t.featured.size() - 1
		else:
			extra += t.featured.size()
	if first.is_empty():
		return first
	if first["sub"] == "" and extra > 0:
		first["sub"] = tr("RECRUIT_UI_STIGMA_SET") % extra
	return first


@warning_ignore("integer_division")
func time_text(b: BannerDef) -> String:
	if b.end_unix <= 0:
		return tr("RECRUIT_UI_PERMANENT")
	var now := now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	var left := b.end_unix - now
	if left <= 0:
		return tr("RECRUIT_UI_ENDED")
	return tr("RECRUIT_UI_TIME_FMT") % [left / 86400, (left % 86400) / 3600, (left % 3600) / 60]


## "Mỗi 10 lượt chắc chắn có ít nhất 1: Nhân vật S / Nhân vật A" (bậc trong multi_guarantee_tiers).
func guarantee_text(b: BannerDef) -> String:
	var labels := PackedStringArray()
	for k in b.multi_guarantee_tiers:
		var t := b.tier(k)
		labels.append(tr(t.label_key) if t and t.label_key != "" else k)
	return tr("RECRUIT_UI_GUARANTEE_BOX") % [b.multi_count, " / ".join(labels)]


## "Bảo đảm S: 23/100 lượt" cho bậc có pity cứng đầu tiên; rỗng nếu banner không có.
func pity_text(b: BannerDef) -> String:
	for t in b.tiers:
		if t and t.hard_pity > 0:
			var label := tr(t.label_key) if t.label_key != "" else "%d★" % t.rarity
			return tr("RECRUIT_UI_PITY") % [label, service.pity_count(b, t.key()), t.hard_pity]
	return ""


## Bảng tỉ lệ hiển thị trong Chi tiết, lấy từ GachaService.rates_table (cùng config với logic quay).
func rate_lines(b: BannerDef) -> PackedStringArray:
	var out := PackedStringArray()
	if is_starter(b):
		var f := featured(b)
		out.append(tr("RECRUIT_STARTER_RULE") % [b.multi_count, str(f.get("name", "")), b.multi_count - 1])
		for it in b.tiers[b.tiers.size() - 1].pool:
			out.append("      " + reward_name(it))
		return out
	for row: Dictionary in GachaService.rates_table(b):
		var label := tr(str(row["label_key"])) if str(row["label_key"]) != "" else "%d★" % row["rarity"]
		var line := "%s  %.3f%%" % [label, row["rate"] * 100.0]
		if int(row["hard_pity"]) > 0:
			line += "  ·  " + tr("RECRUIT_HARD_PITY") % [row["hard_pity"], service.pity_count(b, row["tier"])]
		if int(row["soft_pity_start"]) > 0:
			var key := "RECRUIT_SOFT_PITY_FLAT" if str(row["soft_pity_mode"]) == "flat" else "RECRUIT_SOFT_PITY"
			line += "  ·  " + tr(key) % [row["soft_pity_start"], row["soft_pity_step"] * 100.0]
		if bool(row["guarantee_after_miss"]):
			line += "  ·  " + tr("RECRUIT_GUARANTEE")
		out.append(line)
		if str(row["tier"]) in b.multi_guarantee_pick:
			out.append("      " + tr("RECRUIT_MULTI_GUARANTEE") % b.multi_count)
		for it: Dictionary in row["items"]:
			out.append("      %s%s  %.3f%%" % ["▲ " if it["featured"] else "", reward_name(it["item"]), it["rate"] * 100.0])
	return out


func reward_name(item: String) -> String:
	var id := item.get_slice(":", 1)
	match item.get_slice(":", 0):
		"gold":
			return "%s ×%s" % [tr("CURRENCY_GOLD"), id]
		"char":
			return char_name(id)
		"equip":
			var d := PlayerProfile.equipment_defs().get_def(id) as EquipmentDef
			return tr(d.name_key) if d else id
	var it := PlayerProfile.item_defs().get_def(id) as ItemDef
	return tr(it.name_key) if it else id


func tier_label(b: BannerDef, tier_key: String, rarity: int) -> String:
	var t := b.tier(tier_key) if b else null
	return tr(t.label_key) if t and t.label_key != "" else "%d★" % rarity


func result_line(r: Dictionary) -> String:
	var b := current()
	return "%s  %s%s" % [tier_label(b, str(r.get("tier", "")), int(r["rarity"])), reward_name(r["item"]),
			"  (%s)" % tr("RECRUIT_DUPLICATE") if r["duplicate"] else ""]


## Lịch sử mới nhất trước: "giờ  bậc  phần thưởng".
func history_lines() -> PackedStringArray:
	var out := PackedStringArray()
	var hist := service.history()
	for i in range(hist.size() - 1, maxi(hist.size() - 1 - HISTORY_SHOWN, -1), -1):
		var r: Dictionary = hist[i]
		out.append("%s   %s   %s%s" % [str(r.get("time", "")).substr(0, 16).replace("T", " "),
				tier_label(current(), str(r.get("tier", "")), int(r.get("rarity", 1))), reward_name(str(r.get("item", ""))),
				"  (%s)" % tr("RECRUIT_DUPLICATE") if r.get("duplicate", false) else ""])
	return out


## Cỡ chữ lớn nhất (không dưới `min_size`) để `text` một dòng vừa bề rộng `max_w`.
func _fit_font(text: String, size: int, max_w: float, min_size := 30) -> int:
	while size > min_size and get_theme_default_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_w:
		size -= 2
	return size


func _rarity_color(rarity: int) -> Color:
	if rarity >= 5:
		return layout.color("rank_s", Color.GOLD)
	if rarity == 4:
		return layout.color("rank_a", Color.MEDIUM_PURPLE)
	if rarity == 3:
		return layout.color("rank_b", Color.DEEP_SKY_BLUE)
	return layout.color("text_dim", Color.GRAY)


# ---------- Thao tác ----------

## Quay `count` lượt ở banner đang chọn. Thất bại: hiện lý do, không trừ tiền. Thành công: lưu và hiện bảng kết quả.
func pull(count: int) -> bool:
	var b := current()
	if b == null:
		return false
	var res := service.pull(b, count)
	last_reason = res["reason"]
	last_results = res["results"]
	if last_reason != "":
		notice = tr("REASON_" + last_reason.to_upper())
		overlay = Overlay.NONE
		refresh()
		return false
	notice = ""
	overlay = Overlay.RESULTS
	commit()
	return true


## Dùng lượt x10 miễn phí của banner đang chọn (banner starter). Thành công: lưu và hiện bảng kết quả.
func pull_starter() -> bool:
	var b := current()
	if not is_starter(b):
		return false
	var res := service.pull_starter(b)
	last_reason = res["reason"]
	last_results = res["results"]
	if last_reason != "":
		notice = tr("REASON_" + last_reason.to_upper())
		overlay = Overlay.NONE
		refresh()
		return false
	notice = ""
	overlay = Overlay.RESULTS
	commit()
	return true


func open_overlay(o: Overlay) -> void:
	overlay = o
	notice = ""
	refresh()


func intercept_back() -> bool:
	if overlay != Overlay.NONE:
		overlay = Overlay.NONE
		# Lượt miễn phí đã dùng xong: bỏ banner đó khỏi danh sách.
		var b := current()
		if is_starter(b) and not service.starter_available(b):
			banners.erase(b)
			selected = 0
		refresh()
		return true
	return false


# ---------- Dựng giao diện ----------

## Hình chữ nhật của mục trong "panel": dời theo neo của panel (các mục con không tự có neo).
func _pr(key: String) -> Rect2:
	var r := layout.rect("panel." + key)
	r.position.x += layout.anchor_shift(layout.text("panel.anchor", "left"))
	return r


func _build() -> void:
	var t := "top."
	_label(layout.rect(t + "title"), tr("RECRUIT_UI_TITLE"), layout.font(t + "title", 40), Color.WHITE).name = "ScreenTitle"
	_button(layout.rect(t + "close_button"), "✕", 40, on_back_button, false, "CloseButton")
	var gold_r := layout.rect(t + "gold_pill")
	_panel(gold_r, Color(0, 0, 0, 0.55))
	_label(gold_r, "%s %d" % [tr("CURRENCY_GOLD"), profile.inventory.currency("gold")], layout.font(t + "gold_pill", 28),
			Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER).name = "Gold"
	var gems_r := layout.rect(t + "gems_pill")
	_panel(gems_r, Color(0, 0, 0, 0.55))
	_label(gems_r, "%s %d" % [tr("CURRENCY_GEMS"), profile.inventory.currency("gems")], layout.font(t + "gems_pill", 28),
			Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER).name = "Gems"
	_button(layout.rect(t + "gems_plus"), "+", layout.font(t + "gems_plus", 34), Callable(), false, "GemsPlus")
	if banners.is_empty():
		_label(Rect2(layout.view_size.x * 0.5 - 500, 500, 1000, 80), tr("RECRUIT_CLOSED"), 40, Color.WHITE,
				HORIZONTAL_ALIGNMENT_CENTER).name = "Closed"
		return
	selected = clampi(selected, 0, banners.size() - 1)
	var b := banners[selected]
	_build_list()
	_build_banner(b)
	_build_bottom(b)
	match overlay:
		Overlay.DETAILS:
			_build_text_overlay(tr("RECRUIT_UI_DETAILS_TITLE"), "\n".join(rate_lines(b)), "DetailsText", "Details")
		Overlay.HISTORY:
			var lines := history_lines()
			_build_text_overlay(tr("RECRUIT_UI_HISTORY_TITLE"), "\n".join(lines) if lines.size() > 0 else tr("RECRUIT_UI_HISTORY_EMPTY"),
					"HistoryText", "History")
		Overlay.RESULTS:
			_build_results(b)


func _build_list() -> void:
	var o := layout.point("list", "origin", Vector2(62, 119))
	var item_v: Variant = layout.get_value("list.item", [176, 101])
	var act_v: Variant = layout.get_value("list.active", [195, 113])
	var item := Vector2(float(item_v[0]), float(item_v[1]))
	var act := Vector2(float(act_v[0]), float(act_v[1]))
	var step := layout.num("list.step", 129)
	for i in banners.size():
		var b := banners[i]
		var on := i == selected
		var r := Rect2(Vector2(o.x, o.y + i * step), item)
		if on:   # thẻ đang chọn to hơn, nở đều hai phía
			r = Rect2(r.position - (act - item) * 0.5, act)
		_art(r, art_texture(b, "thumb"), banner_title(b), Rect2(0, 0, 1, 1), "Thumb_%d" % i)
		var btn := _button(r, "", 10, select.bind(i), false, "Banner_%d" % i)
		btn.add_theme_stylebox_override("normal", _style(Color(0, 0, 0, 0), Color.WHITE if on else Color(1, 1, 1, 0.25), 6))


func _build_banner(b: BannerDef) -> void:
	var pr := layout.rect("panel")
	_art(pr, art_texture(b, "banner"), banner_title(b), Rect2(0, 0, 1, 1), "BannerArt")
	# Làm tối dần về bên trái để chữ đọc được trên mọi ảnh.
	var shade := _panel(Rect2(pr.position, Vector2(pr.size.x * 0.55, pr.size.y)), Color(0, 0, 0, 0.45))
	shade.name = "Shade"
	if b.kind_key != "":
		var kr := _pr("kind_tag")
		_panel(kr, layout.color("accent", Color.ORANGE_RED))
		var kl := _label(kr, tr(b.kind_key), _fit_font(tr(b.kind_key), layout.font("panel.kind_tag", 28), kr.size.x - 20.0, 16),
				Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		kl.name = "KindTag"
		kl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label(_pr("title"), banner_title(b), layout.font("panel.title", 64), Color.WHITE).name = "BannerTitle"
	if not b.multi_guarantee_tiers.is_empty():
		_label(_pr("tagline"), tr("RECRUIT_UI_TAGLINE"), layout.font("panel.tagline", 38), layout.color("accent", Color.ORANGE)).name = "Tagline"
		var box := _pr("orange_box")
		_panel(box, layout.color("orange_box", Color.ORANGE_RED))
		_label(box.grow(-14), guarantee_text(b), layout.font("panel.orange_box", 30), Color.WHITE).name = "OrangeBox"
	var f := featured(b)
	_label(_pr("note"), tr("RECRUIT_UI_NOTE_EQUIP" if f.get("kind", "") == "equip" else "RECRUIT_UI_NOTE"), layout.font("panel.note", 26),
			layout.color("text_dim", Color.GRAY)).name = "Note"
	if not f.is_empty():
		if f["element"] != "":
			var er := _pr("element_icon")
			_panel(er, Color(0, 0, 0, 0.55))
			_label(er, tr("ELEMENT_" + str(f["element"]).to_upper()).substr(0, 1), layout.font("panel.element_icon", 34),
					HudTheme.ring_color(str(f["element"])), HORIZONTAL_ALIGNMENT_CENTER).name = "ElementIcon"
		var nr := _pr("featured_name")
		var nfont := _fit_font(str(f["name"]), layout.font("panel.featured_name", 70), nr.size.x)
		var nl := _label(nr, str(f["name"]), nfont, Color.WHITE)
		nl.name = "FeaturedName"
		nl.autowrap_mode = TextServer.AUTOWRAP_OFF
		# "UP!" nằm ngay sau tên (đo độ rộng chữ), không cố định ở một tọa độ.
		var name_w := get_theme_default_font().get_string_size(str(f["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, nfont).x
		var ur := _pr("up_tag")
		ur.position = Vector2(minf(nr.position.x + name_w + 14.0, nr.end.x), nr.position.y + 4.0)
		_label(ur, tr("RECRUIT_UI_SURE" if is_starter(b) else "RECRUIT_UI_UP"), layout.font("panel.up_tag", 30), layout.color("accent", Color.ORANGE)).name = "UpTag"
		_label(_pr("stars"), "★".repeat(int(f["stars"])), layout.font("panel.stars", 40), layout.color("star", Color.GOLD)).name = "Stars"
		if f["sub"] != "":
			var sr := _pr("featured_sub")
			_panel(sr, Color(0.1, 0.12, 0.2, 0.85))
			_label(sr, str(f["sub"]), layout.font("panel.featured_sub", 28), layout.color("accent_blue", Color.SKY_BLUE),
					HORIZONTAL_ALIGNMENT_CENTER).name = "FeaturedSub"
	_label(_pr("time_label"), tr("RECRUIT_UI_TIME_LEFT"), layout.font("panel.time_label", 28), layout.color("text_dim", Color.GRAY))
	_label(_pr("time_value"), time_text(b), layout.font("panel.time_value", 32), Color.WHITE).name = "TimeValue"
	var pity := pity_text(b)
	if pity != "":
		_label(_pr("pity"), pity, layout.font("panel.pity", 26), layout.color("text_dim", Color.GRAY), HORIZONTAL_ALIGNMENT_RIGHT).name = "PityLine"


func _build_bottom(b: BannerDef) -> void:
	var p := "bottom."
	_button(layout.rect(p + "shop_button"), layout.label(p + "shop_button"), layout.font(p + "shop_button", 28), Callable(), false, "ShopButton")
	_button(layout.rect(p + "details_button"), layout.label(p + "details_button"), layout.font(p + "details_button", 28),
			open_overlay.bind(Overlay.DETAILS), false, "DetailsButton")
	_button(layout.rect(p + "history_button"), layout.label(p + "history_button"), layout.font(p + "history_button", 28),
			open_overlay.bind(Overlay.HISTORY), false, "HistoryButton")
	if is_starter(b):
		var sr := layout.rect(p + "wish_10")
		var ticket := PlayerProfile.item_defs().get_def(b.ticket_item) as ItemDef if b.ticket_item != "" else null
		var cost_line := tr("RECRUIT_UI_STARTER_FREE")
		if ticket:
			cost_line = tr("RECRUIT_UI_STARTER_TICKET") % [tr(ticket.name_key), profile.inventory.material_count(b.ticket_item)]
		var sb := _button(sr, "%s\n%s" % [tr("RECRUIT_UI_WISH") % b.multi_count, cost_line], layout.font(p + "wish_10", 34),
				pull_starter, false, "Wish_starter")
		sb.disabled = not service.starter_available(b)
		return
	for count: int in [1, b.multi_count]:
		var key := p + ("wish_1" if count == 1 else "wish_10")
		var r := layout.rect(key)
		_button(r, "%s\n%s %d" % [tr("RECRUIT_UI_WISH") % count, tr("CURRENCY_GEMS"), GachaService.cost_of(b, count)],
				layout.font(key, 34), pull.bind(count), false, "Wish_%d" % count)


func _dim_background() -> void:
	var dim := _panel(Rect2(Vector2.ZERO, layout.view_size), Color(0, 0, 0, 0.7), "Dim")
	dim.mouse_filter = Control.MOUSE_FILTER_STOP   # chặn bấm xuyên xuống các nút bên dưới


func _overlay_rect() -> Rect2:
	return layout.rect("overlay", Rect2(300, 110, 1320, 860))


func _build_text_overlay(title: String, body: String, text_name: String, panel_name: String) -> void:
	_dim_background()
	var r := _overlay_rect()
	var bg := layout.color("panel_light", Color(0.16, 0.18, 0.24))
	bg.a = 1.0
	_panel(r, bg, panel_name)
	_label(Rect2(r.position + Vector2(30, 14), Vector2(r.size.x - 260, 60)), title, 38, Color.WHITE)
	_button(Rect2(r.end - Vector2(220, r.size.y - 14), Vector2(200, 60)), tr("UI_BACK"), 28, intercept_back, false, "OverlayClose")
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var text := Label.new()
	text.name = text_name
	text.text = body
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = r.size.x - 80
	text.add_theme_font_size_override("font_size", layout.font("overlay", 26))
	scroll.add_child(text)
	_place(scroll, Rect2(r.position + Vector2(30, 90), Vector2(r.size.x - 60, r.size.y - 110)))


func _build_results(b: BannerDef) -> void:
	_dim_background()
	var r := _overlay_rect()
	var bg := layout.color("panel_light", Color(0.16, 0.18, 0.24))
	bg.a = 1.0
	_panel(r, bg, "Results")
	_label(Rect2(r.position + Vector2(30, 14), Vector2(r.size.x - 60, 60)), tr("RECRUIT_UI_RESULT_TITLE"), 38, Color.WHITE)
	var card_v: Variant = layout.get_value("overlay.result_card", [224, 168])
	var card := Vector2(float(card_v[0]), float(card_v[1]))
	var cols := maxi(int(layout.num("overlay.result_columns", 5)), 1)
	var gap := layout.num("overlay.result_gap", 18)
	var n := last_results.size()
	var used_cols := mini(n, cols)
	var rows := ceili(float(n) / cols)
	var origin := Vector2(r.position.x + (r.size.x - (used_cols * card.x + (used_cols - 1) * gap)) * 0.5,
			r.position.y + 110 + maxf(0.0, (r.size.y - 260 - rows * (card.y + gap)) * 0.5))
	for i in n:
		var res: Dictionary = last_results[i]
		var c := Rect2(origin + Vector2((i % cols) * (card.x + gap), floori(float(i) / cols) * (card.y + gap)), card)
		var col := _rarity_color(int(res["rarity"]))
		var p := _panel(c, Color(0.08, 0.09, 0.14, 0.95), "ResultCard_%d" % i)
		p.add_theme_stylebox_override("panel", _style(Color(0.08, 0.09, 0.14, 0.95), col, 8))
		_label(Rect2(c.position + Vector2(8, 8), Vector2(c.size.x - 16, 36)), tier_label(b, str(res.get("tier", "")), int(res["rarity"])),
				24, col, HORIZONTAL_ALIGNMENT_CENTER)
		_label(Rect2(c.position + Vector2(8, 48), Vector2(c.size.x - 16, 80)), reward_name(str(res["item"])), 26, Color.WHITE,
				HORIZONTAL_ALIGNMENT_CENTER)
		if res["duplicate"]:
			_label(Rect2(c.position + Vector2(8, c.size.y - 40), Vector2(c.size.x - 16, 32)), tr("RECRUIT_DUPLICATE"), 22,
					layout.color("text_dim", Color.GRAY), HORIZONTAL_ALIGNMENT_CENTER)
	_button(Rect2(r.position + Vector2(r.size.x * 0.5 - 150, r.size.y - 100), Vector2(300, 70)), tr("RECRUIT_UI_CONFIRM"), 32,
			intercept_back, false, "ResultClose")
