class_name RecruitScreen
extends LayoutScreen
## Màn Chiêu mộ (bố cục owner 2026-11-15, theo ảnh gợi ý): thẻ chữ chọn banner bên trái, ảnh banner lớn phủ nền,
## tiêu đề và chú thích món / nhân vật đề cử, cột phải (pity còn lại, dãy icon trang bị đã có / chưa có, thời gian,
## túi quà), nút tròn Chơi thử / Shop / Chi tiết / Lịch sử, hai nút vàng Chiêu mộ ×1 / ×10. Tỉ lệ ở bảng Chi tiết.
## Vị trí, cỡ chữ, màu đọc từ data/ui/recruit_screen_layout.json. Ảnh banner theo quy ước trong assets/ui/recruit/.
## Màn chỉ gọi GachaService / PlayerProfile; không tự chứa luật quay.

const LAYOUT_PATH := "res://data/ui/recruit_screen_layout.json"
const BANNERS_DIR := "res://data/banners"
## Lượt x10 miễn phí đầu tiên (cần vé nhận ở ải 1-1): chỉ hiện, ở đầu danh sách, khi còn dùng được.
const STARTER_PATH := "res://data/tutorial/starter_pull.tres"
const ART_DIR := "res://assets/ui/recruit"
const HISTORY_SHOWN := 50
## Thẻ kết quả rỗng và icon tạm (tools/gen_recruit_card_placeholders.py). Bản Release không có: thẻ vẽ màu nền.
const RESULT_CARD := "res://assets/placeholders/placeholder_recruit_card.png"
const RESULT_ICON := "res://assets/placeholders/placeholder_recruit_icon_%s.png"

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
## Hiệu ứng hiện thẻ kết quả lần lượt từ trái sang (owner 2026-11-15): số giây đã chạy. ≥ reveal_total() = đã hiện hết.
## Tính theo thời gian (không dùng Tween) để dựng lại màn giữa chừng vẫn tiếp tục đúng chỗ.
var reveal_time := 0.0
var _reveal_slots: Array[Control] = []
## Ánh sáng thẻ 5★: chỉ số ô hiển thị → {glow, beam, flash}. `_fx_time` chạy liên tục để quầng sáng nhấp nháy.
var _reveal_fx: Dictionary = {}
var _fx_time := 0.0
## Ô 5★ đã phát âm thanh trong lượt kết quả hiện tại (dựng lại màn không phát lại).
var _fx_sounded: Dictionary = {}
## Ô 5★ đã bung hạt trong lượt kết quả hiện tại (dựng lại màn chỉ giữ hạt trôi, không bung lại).
var _fx_sparked: Dictionary = {}
## Sự kiện âm thanh khi thẻ 5★ hiện (data/config/audio_events.json → sfx_gacha_5star).
const SFX_FIVE_STAR := "gacha_5star"


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
	return layout.color("rank_b", Color.DEEP_SKY_BLUE)   # còn lại xanh dương (owner 2026-11-15)


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
	reveal_time = 0.0
	_fx_sounded.clear()
	_fx_sparked.clear()
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
	reveal_time = 0.0
	_fx_sounded.clear()
	_fx_sparked.clear()
	commit()
	return true


func open_overlay(o: Overlay) -> void:
	if o == Overlay.RESULTS:
		reveal_time = 0.0
		_fx_sounded.clear()
		_fx_sparked.clear()
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

## Hình chữ nhật của mục trong "panel": mục có neo riêng (vd cột phải "right") dùng neo đó;
## mục không có neo dời theo neo của panel. Không cộng hai lần (trước đây chữ cột phải bị đẩy ra ngoài màn rộng).
func _pr(key: String) -> Rect2:
	var r := layout.rect("panel." + key)
	if not layout.dict("panel." + key).has("anchor"):
		r.position.x += layout.anchor_shift(layout.text("panel.anchor", "left"))
	return r


func _build() -> void:
	var b: BannerDef = null
	if not banners.is_empty():
		selected = clampi(selected, 0, banners.size() - 1)
		b = banners[selected]
		_build_banner(b)      # ảnh lớn nằm dưới cùng; thanh trên, danh sách, nút đè lên
	var t := "top."
	# Thanh trên: nút Trở về + tên màn bên trái, tiền tệ bên phải (owner 2026-11-15, ảnh gợi ý 1 và 2).
	var back := _button(layout.rect(t + "back_button"), tr("RECRUIT_UI_BACK"), layout.font(t + "back_button", 30),
			on_back_button, false, "CloseButton")
	_yellow(back)
	_label(layout.rect(t + "title"), tr("RECRUIT_UI_TITLE"), layout.font(t + "title", 34), Color.WHITE).name = "ScreenTitle"
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
	_build_list()
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


## Nút vàng (nút chính: Trở về, Chiêu mộ ×1 / ×10): nền vàng, chữ tối.
func _yellow(btn: Button) -> void:
	var bg := layout.color("button_yellow", Color("#FFD84A"))
	var border := layout.color("button_yellow_border", Color("#C99A12"))
	btn.add_theme_stylebox_override("normal", _style(bg, border, 10))
	btn.add_theme_stylebox_override("hover", _style(bg.lightened(0.1), border, 10))
	btn.add_theme_stylebox_override("pressed", _style(bg.darkened(0.12), border, 10))
	btn.add_theme_stylebox_override("disabled", _style(bg.darkened(0.4), border.darkened(0.3), 10))
	var fg := layout.color("text_dark", Color("#1B1E2B"))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		btn.add_theme_color_override(k, fg)


## Danh sách banner dạng thẻ chữ dọc bên trái; thẻ đang chọn nền sáng chữ tối.
func _build_list() -> void:
	var o := layout.point("list", "origin", Vector2(0, 120))
	var item_v: Variant = layout.get_value("list.item", [330, 104])
	var item := Vector2(float(item_v[0]), float(item_v[1]))
	var step := layout.num("list.step", 112)
	var col_on := layout.color("tab_selected", Color("#F2F4FA"))
	var col_off := layout.color("tab", Color("#3D5FC4E6"))
	for i in banners.size():
		var b := banners[i]
		var on := i == selected
		var r := Rect2(Vector2(o.x, o.y + i * step), item)
		var btn := _button(r, tab_text(b), layout.font("list", 30), select.bind(i), on, "Banner_%d" % i)
		var st := _style(col_on if on else col_off, Color(1, 1, 1, 0.35), 4)
		st.content_margin_right = 28
		st.content_margin_left = 16
		btn.add_theme_stylebox_override("normal", st)
		var hv := st.duplicate() as StyleBoxFlat
		hv.bg_color = hv.bg_color.lightened(0.1)
		btn.add_theme_stylebox_override("hover", hv)
		btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		btn.add_theme_constant_override("h_separation", 0)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## Chữ trên thẻ danh sách: nhãn loại banner (kind_key), thiếu thì tên banner.
func tab_text(b: BannerDef) -> String:
	if is_starter(b):
		return tr("RECRUIT_TAB_STARTER")
	return tr(b.kind_key) if b.kind_key != "" else tr(b.name_key)


## Loại bố cục: "char" (ảnh gợi ý 2: banner nhân vật), "equip" (ảnh gợi ý 1: tiếp tế, trang bị 5★).
func banner_layout(b: BannerDef) -> String:
	for t in b.tiers:
		for p in t.pool:
			if p.begins_with("char:"):
				return "char"
	return "equip"


## Bậc trang bị theo món của banner 5★ (exclude_owned_until_complete), null nếu không có.
func set_tier(b: BannerDef) -> GachaTierDef:
	for t in b.tiers:
		if t and t.exclude_owned_until_complete:
			return t
	return null


## Món hiện trong dãy icon góc phải: banner 5★ → cả bộ đề cử (có trạng thái đã có / chưa có);
## banner khác → các món đề cử. [{item, owned (null = không hiện trạng thái)}]
func icon_items(b: BannerDef) -> Array:
	var out: Array = []
	var st := set_tier(b)
	if st:
		for p in st.pool:
			out.append({"item": p, "owned": profile.inventory.owns_def(p.get_slice(":", 1))})
		return out
	for t in b.tiers:
		for p in t.featured:
			if p.begins_with("equip:"):
				out.append({"item": p, "owned": null})
	return out


## "Còn N lượt chắc chắn có <bậc>" cho bậc có pity cứng đầu tiên; rỗng nếu banner không có pity.
func pity_text(b: BannerDef) -> String:
	for t in b.tiers:
		if t and t.hard_pity > 0:
			var label := tr(t.label_key) if t.label_key != "" else "%d★" % t.rarity
			return tr("RECRUIT_UI_PITY_LEFT") % [maxi(t.hard_pity - service.pity_count(b, t.key()), 1), label]
	return ""


## Banner nhân vật: còn bao nhiêu mảnh để tiến cấp nhân vật đề cử (ảnh gợi ý 2). Rỗng nếu không có nhân vật đề cử.
func fragment_text(b: BannerDef) -> String:
	var cid := ""
	for t in b.tiers:
		for p in t.featured:
			if p.begins_with("char:") and cid == "":
				cid = p.get_slice(":", 1)
	if cid == "":
		return ""
	var prog := profile.progression
	if not prog.owns(cid):
		return tr("RECRUIT_UI_FRAG_NOT_OWNED")
	var need := prog.fragments_to_promote(cid)
	if need <= 0:
		return tr("RECRUIT_UI_FRAG_MAX")
	var d := char_def(cid)
	var rank := d.rank if d and d.rank != "" else "?"
	return tr("RECRUIT_UI_FRAG_LEFT") % [maxi(need - prog.fragments_of(cid), 0), "%s%d" % [rank, prog.promotion_of(cid) + 1]]


func _build_banner(b: BannerDef) -> void:
	var kind := banner_layout(b)
	var pr := layout.rect("panel")
	pr.size.x = maxf(pr.size.x, layout.view_size.x - pr.position.x)   # ảnh phủ tới mép phải mọi tỉ lệ màn
	var art := _art(pr, art_texture(b, "banner"), banner_title(b), Rect2(0, 0, 1, 1), "BannerArt")
	art.border_color = Color(0, 0, 0, 0)
	# Làm tối dần hai bên để chữ đọc được trên mọi ảnh.
	for side in [Rect2(pr.position, Vector2(pr.size.x * 0.3, pr.size.y)),
			Rect2(pr.position + Vector2(pr.size.x * 0.68, 0), Vector2(pr.size.x * 0.32, pr.size.y))]:
		_panel(side, Color(0, 0, 0, 0.35)).name = "Shade"
	var kt := _label(_pr("kind_tag"), tr(b.kind_key) if b.kind_key != "" else "", layout.font("panel.kind_tag", 26),
			layout.color("accent_blue", Color.SKY_BLUE))
	kt.name = "KindTag"
	_label(_pr("title"), banner_title(b), layout.font("panel.title", 76), Color.WHITE).name = "BannerTitle"
	# Chú thích tên món đề cử (đường kẻ + tên + nhãn sao), theo ảnh gợi ý 1. Banner nhân vật không có
	# chú thích tên nhân vật / giáp (owner 2026-11-15: ảnh banner tự thể hiện).
	var f := featured(b) if kind == "equip" else {}
	if not f.is_empty():
		var cr := _pr("callout_1")
		_callout(cr, str(f["name"]), "★".repeat(int(f["stars"])), tr("RECRUIT_UI_SURE" if is_starter(b) else "RECRUIT_UI_UP"),
				"FeaturedName", "Stars")
		if str(f["sub"]) != "":
			_callout(_pr("callout_2"), str(f["sub"]), "", tr("RECRUIT_UI_UP"), "FeaturedSub", "")
	# Cột phải: pity, dãy icon (trang bị), thời gian, túi quà.
	var pity := pity_text(b)
	if pity != "":
		var pb := _pr("pity_box")
		_panel(pb, Color(0, 0, 0, 0.6))
		var pl := _label(pb.grow_individual(-16, 0, -16, 0), pity,
				_fit_font(pity, layout.font("panel.pity_box", 30), pb.size.x - 32.0, 18), Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
		pl.name = "PityLine"
		pl.autowrap_mode = TextServer.AUTOWRAP_OFF
	if kind == "equip":
		_build_icon_row(b)
	var tr_ := _pr("time")
	var time_s := "%s %s" % [tr("RECRUIT_UI_TIME_LEFT"), time_text(b)]
	var tl := _label(tr_, time_s, _fit_font(time_s, layout.font("panel.time", 28), tr_.size.x, 18), Color.WHITE,
			HORIZONTAL_ALIGNMENT_RIGHT)
	tl.name = "TimeValue"
	tl.autowrap_mode = TextServer.AUTOWRAP_OFF
	var gift := _pr("gift_card")
	var gb := _button(gift, tr("RECRUIT_UI_GIFT"), layout.font("panel.gift_card", 26), Callable(), false, "GiftButton")
	gb.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.9), Color(1, 1, 1, 1), 6))
	gb.add_theme_color_override("font_color", layout.color("text_dark", Color("#1B1E2B")))
	if kind == "char":
		var frag := fragment_text(b)
		if frag != "":
			_label(_pr("fragment_line"), frag, layout.font("panel.fragment_line", 30), Color.WHITE,
					HORIZONTAL_ALIGNMENT_RIGHT).name = "FragmentLine"


## Một chú thích: chấm tròn + đường kẻ ngang + tên (to) + dòng nhỏ (sao, nhãn UP).
func _callout(r: Rect2, title: String, stars: String, tag: String, name_node: String, stars_node: String) -> void:
	var dot := _panel(Rect2(r.position + Vector2(r.size.x - 18, 4), Vector2(18, 18)), layout.color("star", Color.GOLD))
	dot.add_theme_stylebox_override("panel", _style(layout.color("star", Color.GOLD), Color.WHITE, 9))
	_panel(Rect2(r.position + Vector2(0, 56), Vector2(r.size.x, 3)), Color(1, 1, 1, 0.85))
	var nl := _label(Rect2(r.position, Vector2(r.size.x - 26, 54)), title,
			_fit_font(title, layout.font("panel.callout", 38), r.size.x - 30, 22), layout.color("callout", Color("#FFD84A")))
	nl.name = name_node
	nl.autowrap_mode = TextServer.AUTOWRAP_OFF
	var tag_r := Rect2(r.position + Vector2(0, 64), Vector2(minf(150, r.size.x * 0.4), 34))
	_panel(tag_r, layout.color("tag", Color("#4A63D9")))
	_label(tag_r, tag, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	if stars != "" and stars_node != "":
		_label(Rect2(tag_r.end.x + 10, tag_r.position.y, r.size.x - tag_r.size.x - 10, 34), stars, 26,
				layout.color("star", Color.GOLD)).name = stars_node


## Dãy icon trang bị đề cử góc phải; banner 5★: món đã có sáng + dấu ✓, chưa có phủ lớp tối mờ.
func _build_icon_row(b: BannerDef) -> void:
	var items := icon_items(b)
	var o := layout.point("panel.icons", "origin", Vector2(1430, 190))
	var size := layout.num("panel.icons.size", 104)
	var step := layout.num("panel.icons.step", 112)
	var n := items.size()
	for i in n:
		var it: Dictionary = items[i]
		var r := Rect2(Vector2(o.x + (4 - n + i) * step, o.y), Vector2(size, size))   # canh phải theo 4 ô
		var rar := _item_rarity(str(it["item"]))
		var box := _panel(r, Color(0.1, 0.12, 0.2, 0.95), "OwnedIcon_%d" % i)
		box.add_theme_stylebox_override("panel", _style(Color(0.1, 0.12, 0.2, 0.95), _rarity_color(rar), 6))
		var art := result_art(str(it["item"]))
		var a := _art(r.grow(-6), art["texture"], reward_name(str(it["item"])), Rect2(0, 0, 1, 1), "OwnedArt_%d" % i)
		a.fill_color = Color(0, 0, 0, 0)
		a.border_color = Color(0, 0, 0, 0)
		_label(Rect2(r.position + Vector2(0, r.size.y - 28), Vector2(r.size.x, 26)), "★".repeat(rar), 18,
				layout.color("star", Color.GOLD), HORIZONTAL_ALIGNMENT_CENTER)
		if it["owned"] == null:
			continue
		if bool(it["owned"]):
			var ck := _label(Rect2(r.end - Vector2(34, 34), Vector2(30, 30)), "✓", 26, Color("#5BE37A"), HORIZONTAL_ALIGNMENT_CENTER)
			ck.name = "OwnedCheck_%d" % i
		else:
			_panel(r, Color(0, 0, 0, 0.62), "OwnedDim_%d" % i)


func _item_rarity(item: String) -> int:
	var id := item.get_slice(":", 1)
	if item.begins_with("equip:"):
		var d := PlayerProfile.equipment_defs().get_def(id) as EquipmentDef
		return d.rarity if d else 1
	return 1


func _build_bottom(b: BannerDef) -> void:
	var kind := banner_layout(b)
	# Nút tròn bên trái (ảnh gợi ý 1, 2): nhân vật có Chơi thử / Shop; mọi banner có Chi tiết, Lịch sử.
	var side: Array = []
	if kind == "char":
		side.append(["TrialButton", "RECRUIT_UI_TRIAL", Callable()])
		side.append(["ShopButton", "RECRUIT_UI_SHOP", Callable()])
	side.append(["DetailsButton", "RECRUIT_UI_DETAILS", open_overlay.bind(Overlay.DETAILS)])
	side.append(["HistoryButton", "RECRUIT_UI_HISTORY", open_overlay.bind(Overlay.HISTORY)])
	var so := layout.point("bottom.side", "origin", Vector2(400, 640))
	var sv: Variant = layout.get_value("bottom.side.item", [330, 76])
	var ss := Vector2(float(sv[0]), float(sv[1]))
	var sstep := layout.num("bottom.side.step", 92)
	var y0 := so.y + (4 - side.size()) * sstep   # canh dưới
	for i in side.size():
		var s: Array = side[i]
		var r := Rect2(Vector2(so.x, y0 + i * sstep), ss)
		var btn := _button(r, tr(str(s[1])), layout.font("bottom.side", 30), s[2], false, str(s[0]))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		for state in ["normal", "hover", "pressed"]:
			var sb := _style(Color(1, 1, 1, 0.08 if state != "normal" else 0.0))
			sb.content_margin_left = 78
			btn.add_theme_stylebox_override(state, sb)
		var ic := _panel(Rect2(r.position + Vector2(0, (ss.y - 60) * 0.5), Vector2(60, 60)), layout.color("accent_blue", Color.SKY_BLUE))
		ic.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.92), Color(0, 0, 0, 0), 30))
		_label(ic.get_rect(), str(tr(str(s[1]))).substr(0, 1), 28, layout.color("tag", Color("#4A63D9")), HORIZONTAL_ALIGNMENT_CENTER)
	var p := "bottom."
	if not b.multi_guarantee_tiers.is_empty() and not is_starter(b):
		var gr := layout.rect(p + "guarantee_note")
		_panel(gr, Color(1, 1, 1, 0.88))
		var gl := _label(gr.grow(-6), guarantee_text(b), layout.font(p + "guarantee_note", 24),
				layout.color("guarantee_text", Color("#D23B3B")), HORIZONTAL_ALIGNMENT_RIGHT)   # căn phải (owner 2026-11-15)
		gl.name = "OrangeBox"
	if is_starter(b):
		var sr := layout.rect(p + "wish_10")
		var ticket := PlayerProfile.item_defs().get_def(b.ticket_item) as ItemDef if b.ticket_item != "" else null
		var cost_line := tr("RECRUIT_UI_STARTER_FREE")
		if ticket:
			cost_line = tr("RECRUIT_UI_STARTER_TICKET") % profile.inventory.material_count(b.ticket_item)
		var sb := _button(sr, "%s\n%s" % [tr("RECRUIT_UI_WISH") % b.multi_count, cost_line], layout.font(p + "wish_10", 34),
				pull_starter, false, "Wish_starter")
		_yellow(sb)
		sb.disabled = not service.starter_available(b)
		return
	for count: int in [1, b.multi_count]:
		var key := p + ("wish_1" if count == 1 else "wish_10")
		var r := layout.rect(key)
		var wb := _button(r, "%s\n%s ×%d" % [tr("RECRUIT_UI_WISH") % count, tr("CURRENCY_GEMS"), GachaService.cost_of(b, count)],
				layout.font(key, 34), pull.bind(count), false, "Wish_%d" % count)
		_yellow(wb)


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


## Thứ tự hiện kết quả (owner 2026-11-15): nhiều sao / bậc cao trước; cùng độ hiếm thì nhân vật, trang bị, vật phẩm, vàng.
func result_order() -> Array:
	var kinds := ["char", "equip", "item", "gold"]
	var idx := range(last_results.size())
	idx.sort_custom(func(a: int, b: int) -> bool:
		var ra := result_stars(last_results[a]) * 10 + int(last_results[a]["rarity"])
		var rb := result_stars(last_results[b]) * 10 + int(last_results[b]["rarity"])
		if ra != rb:
			return ra > rb
		var ka := kinds.find(str(last_results[a]["item"]).get_slice(":", 0))
		var kb := kinds.find(str(last_results[b]["item"]).get_slice(":", 0))
		return ka < kb if ka != kb else a < b)
	return idx


## Ảnh trong thẻ kết quả: nhân vật → splash (có thì dùng), không thì chibi, không thì placeholder nhân vật;
## trang bị → ảnh món (EquipmentDef.art), không thì icon tạm theo ô; vật phẩm / vàng → icon tạm.
## Trả về {texture, cover}: cover = true thì ảnh phủ kín thẻ (cắt phần trên cho thấy mặt).
func result_art(item: String) -> Dictionary:
	var id := item.get_slice(":", 1)
	match item.get_slice(":", 0):
		"char":
			var sp := CharacterArt.SPLASH_PATH % [id, id]
			if ResourceLoader.exists(sp):
				return {"texture": load(sp), "cover": true}
			return {"texture": CharacterArt.figure(id), "cover": false}   # null → PlaceholderArt vẽ hình người + tên
		"equip":
			var d := PlayerProfile.equipment_defs().get_def(id) as EquipmentDef
			if d and d.art != "" and ResourceLoader.exists(d.art):
				return {"texture": load(d.art), "cover": false}
			return {"texture": _tex(RESULT_ICON % ("weapon" if d and d.slot == "weapon" else "stigma")), "cover": false}
		"gold":
			return {"texture": _tex(RESULT_ICON % "gold"), "cover": false}
	return {"texture": _tex(RESULT_ICON % "material"), "cover": false}


## Số sao của thẻ: trang bị / nhân vật theo bậc (S = 5, A = 4, B = 3); vật phẩm theo ItemDef.
func result_stars(r: Dictionary) -> int:
	var item := str(r["item"])
	if item.begins_with("item:"):
		var it := PlayerProfile.item_defs().get_def(item.get_slice(":", 1)) as ItemDef
		if it:
			return it.rarity
	return clampi(int(r["rarity"]), 1, 5)


static func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## Kết quả quay (owner 2026-11-15, theo ảnh gợi ý): một hàng thẻ dọc, viền phát sáng theo độ hiếm (S / 5★ vàng,
## A / 4★ tím, còn lại xanh dương). Thẻ là placeholder rỗng; nhân vật dùng splash, vật phẩm dùng ảnh / icon tạm.
# ---------- Hiệu ứng hiện thẻ ----------

## Giây giữa hai thẻ, thời gian hiện một thẻ, quãng trượt (px). Owner 2026-11-15: nhanh ×1.5 so với bản đầu
## (1.2 / 0.6 → 0.8 / 0.4), ×10 ≈ 9 × 0.8 + 0.4 ≈ 7.6 s.
func _reveal_interval() -> float:
	return layout.num("overlay.result_reveal_interval", 0.8)


func _reveal_fade() -> float:
	return layout.num("overlay.result_reveal_fade", 0.4)


## Tổng thời gian hiện hết các thẻ.
func reveal_total() -> float:
	return maxf(last_results.size() - 1, 0) * _reveal_interval() + _reveal_fade()


func is_revealing() -> bool:
	return overlay == Overlay.RESULTS and reveal_time < reveal_total()


## Hiện ngay tất cả thẻ (nút Bỏ qua, chạm màn hình).
func skip_reveal() -> void:
	reveal_time = reveal_total()
	_apply_reveal()


## Số thẻ đã hiện (đủ rõ) lúc này.
func revealed_count() -> int:
	var n := 0
	for k in _reveal_slots.size():
		if reveal_time >= k * _reveal_interval() + _reveal_fade():
			n += 1
	return n


func _process(delta: float) -> void:
	if overlay != Overlay.RESULTS:
		return
	_fx_time += delta
	if is_revealing():
		reveal_time += delta
	_apply_reveal()


## Độ lệch rung lúc này: mỗi thẻ 5★ vừa hiện góp biên độ giảm dần tuyến tính về 0 trong `result_shake_sec`.
func shake_offset() -> Vector2:
	var px := layout.num("overlay.result_shake_px", 14) if layout else 14.0
	var sec := maxf(layout.num("overlay.result_shake_sec", 0.45) if layout else 0.45, 0.01)
	var amp := 0.0
	for k in _reveal_fx:
		var lt := reveal_time - int(k) * _reveal_interval()
		if lt >= 0.0 and lt < sec:
			amp = maxf(amp, px * (1.0 - lt / sec))
	if amp <= 0.0:
		return Vector2.ZERO
	return Vector2(sin(_fx_time * 61.0), cos(_fx_time * 47.0) * 0.7) * amp


func _apply_reveal() -> void:
	var slide := layout.num("overlay.result_reveal_slide", 90) if layout else 90.0
	var shake := shake_offset()   # rung hàng thẻ, nền đứng yên (không lộ mép màn)
	for k in _reveal_slots.size():
		var slot := _reveal_slots[k]
		if not is_instance_valid(slot):
			continue
		var p := clampf((reveal_time - k * _reveal_interval()) / maxf(_reveal_fade(), 0.01), 0.0, 1.0)
		var e := 1.0 - pow(1.0 - p, 3.0)
		slot.modulate.a = e
		slot.position = Vector2(-(1.0 - e) * slide, 0.0) + shake
		if _reveal_fx.has(k):
			var lt := reveal_time - k * _reveal_interval()
			_apply_fx(_reveal_fx[k], lt)
			var fx: Dictionary = _reveal_fx[k]
			(fx["drift"] as CPUParticles2D).emitting = lt >= 0.0
			if lt >= 0.0 and not _fx_sparked.has(k):
				_fx_sparked[k] = true
				(fx["burst"] as CPUParticles2D).restart()
			if lt >= 0.0 and not _fx_sounded.has(k):
				_fx_sounded[k] = true
				_play_sfx(SFX_FIVE_STAR)   # nhiều thẻ 5★ cùng lúc (Bỏ qua): AudioRouter chặn phát trùng trong 40 ms
	var skip := _root.find_child("ResultSkip", true, false) as Control if _root else null
	if skip:
		skip.visible = is_revealing()


func _play_sfx(event: String) -> void:
	var audio := UiKit.autoload("AudioRouter")
	if audio:
		audio.play_event(event)


## Ánh sáng 5★ theo thời gian kể từ lúc thẻ bắt đầu hiện (`t`): chớp trắng trên thẻ (tắt sau ~0.45 s), quầng vàng
## phía sau phóng to rồi thu về, cột sáng dọc bùng lên rồi giữ mức nhẹ; sau đó quầng và cột nhấp nháy chậm.
func _apply_fx(fx: Dictionary, t: float) -> void:
	var flash := fx["flash"] as Control
	var glow := fx["glow"] as Control
	var beam := fx["beam"] as Control
	if t <= 0.0:
		flash.modulate.a = 0.0
		glow.modulate.a = 0.0
		beam.modulate.a = 0.0
		return
	var burst := clampf(t / 0.25, 0.0, 1.0) * clampf(1.0 - (t - 0.25) / 0.9, 0.0, 1.0)   # 0 → 1 → 0 trong ~1.15 s
	var pulse := 0.5 + 0.5 * sin(_fx_time * 3.0)
	flash.modulate.a = clampf(1.0 - t / 0.45, 0.0, 1.0) * 0.85
	glow.modulate.a = clampf(t / 0.2, 0.0, 1.0) * (0.55 + 0.25 * pulse) + 0.4 * burst
	var sc := 1.0 + 0.45 * burst
	glow.scale = Vector2(sc, sc)
	beam.modulate.a = clampf(t / 0.2, 0.0, 1.0) * (0.35 + 0.15 * pulse) + 0.6 * burst
	beam.scale = Vector2(1.0 + 0.6 * burst, 1.0)


## Ba lớp ánh sáng của thẻ 5★ (tạo TRƯỚC các node của thẻ để nằm phía sau, trừ chớp trắng nằm trên cùng).
func _make_fx_back(c: Rect2, col: Color, i: int) -> Dictionary:
	var g := Gradient.new()
	g.set_color(0, Color(col.lightened(0.35), 0.95))
	g.set_color(1, Color(col, 0.0))
	var radial := GradientTexture2D.new()
	radial.gradient = g
	radial.fill = GradientTexture2D.FILL_RADIAL
	radial.fill_from = Vector2(0.5, 0.5)
	radial.fill_to = Vector2(0.5, 0.0)
	var glow := TextureRect.new()
	glow.name = "ResultGlow_%d" % i
	glow.texture = radial
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gr := Rect2(c.get_center() - Vector2(c.size.x * 1.6, c.size.y * 0.75), Vector2(c.size.x * 3.2, c.size.y * 1.5))
	_place(glow, gr)
	glow.pivot_offset = gr.size * 0.5
	var bg := Gradient.new()
	bg.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	bg.colors = PackedColorArray([Color(col, 0.0), Color(col.lightened(0.5), 0.9), Color(col, 0.0)])
	var col_tex := GradientTexture2D.new()
	col_tex.gradient = bg
	col_tex.fill_from = Vector2(0.0, 0.5)
	col_tex.fill_to = Vector2(1.0, 0.5)
	var beam := TextureRect.new()
	beam.name = "ResultBeam_%d" % i
	beam.texture = col_tex
	beam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	beam.stretch_mode = TextureRect.STRETCH_SCALE
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var br := Rect2(Vector2(c.get_center().x - c.size.x * 0.45, 0), Vector2(c.size.x * 0.9, layout.view_size.y))
	_place(beam, br)
	beam.pivot_offset = br.size * 0.5
	return {"glow": glow, "beam": beam}


## Hạt lấp lánh của thẻ 5★: `burst` bung một lần lúc thẻ hiện, `drift` trôi lên chậm sau đó.
func _make_fx_sparkles(c: Rect2, col: Color, i: int) -> Dictionary:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var dot := GradientTexture2D.new()
	dot.gradient = g
	dot.width = 24
	dot.height = 24
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(0.5, 0.0)
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 0.9, 1), Color(col.lightened(0.3), 1), Color(col, 0)])
	var burst := CPUParticles2D.new()
	burst.name = "ResultSpark_%d" % i
	burst.texture = dot
	burst.local_coords = true   # hạt đi theo thẻ khi thẻ trượt / rung
	burst.emitting = false
	burst.one_shot = true
	burst.amount = 60
	burst.lifetime = 1.2
	burst.explosiveness = 1.0
	burst.direction = Vector2.UP
	burst.spread = 180.0
	burst.initial_velocity_min = 160.0
	burst.initial_velocity_max = 420.0
	burst.gravity = Vector2(0, 260)
	burst.damping_min = 40.0
	burst.damping_max = 90.0
	burst.scale_amount_min = 0.3
	burst.scale_amount_max = 1.1
	burst.color_ramp = ramp
	burst.position = c.get_center() - Vector2(0, c.size.y * 0.15)
	_root.add_child(burst)
	var drift := CPUParticles2D.new()
	drift.name = "ResultDrift_%d" % i
	drift.texture = dot
	drift.local_coords = true   # hạt đi theo thẻ khi thẻ trượt / rung
	drift.emitting = false
	drift.amount = 16
	drift.lifetime = 2.4
	drift.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	drift.emission_rect_extents = c.size * 0.5
	drift.direction = Vector2.UP
	drift.spread = 25.0
	drift.initial_velocity_min = 20.0
	drift.initial_velocity_max = 60.0
	drift.gravity = Vector2(0, -15)
	drift.scale_amount_min = 0.2
	drift.scale_amount_max = 0.6
	drift.color_ramp = ramp
	drift.position = c.get_center()
	_root.add_child(drift)
	return {"burst": burst, "drift": drift}


func _make_fx_flash(c: Rect2, i: int) -> Control:
	var flash := ColorRect.new()
	flash.name = "ResultFlash_%d" % i
	flash.color = Color(1, 1, 1, 1)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(flash, c)
	return flash


func _build_results(b: BannerDef) -> void:
	_dim_background()
	var bg := _panel(Rect2(Vector2.ZERO, layout.view_size), Color(0.03, 0.04, 0.08, 0.94), "ResultBackdrop")
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.is_pressed() and is_revealing():
			skip_reveal())
	_reveal_slots.clear()
	_reveal_fx.clear()
	var view := layout.view_size
	_label(Rect2(60, 40, 900, 60), tr("RECRUIT_UI_RESULT_TITLE"), 40, Color.WHITE).name = "ResultTitle"
	var card_v: Variant = layout.get_value("overlay.result_card", [168, 620])
	var card := Vector2(float(card_v[0]), float(card_v[1]))
	var gap := layout.num("overlay.result_gap", 14)
	var order := result_order()
	var n := order.size()
	var total_w := n * card.x + maxi(n - 1, 0) * gap
	var origin := Vector2((view.x - total_w) * 0.5, (view.y - card.y) * 0.5 - 10)
	var frame := _tex(RESULT_CARD)
	for slot in n:
		var first_child := _root.get_child_count()
		var i: int = order[slot]
		var res: Dictionary = last_results[i]
		var c := Rect2(origin + Vector2(slot * (card.x + gap), 0), card)
		var col := _rarity_color(int(res["rarity"]))
		var fx := _make_fx_back(c, col, i) if int(res["rarity"]) >= 5 else {}
		# Viền + quầng sáng theo độ hiếm.
		var glow := StyleBoxFlat.new()
		glow.bg_color = Color(0.1, 0.12, 0.18, 1.0)
		glow.set_corner_radius_all(14)
		glow.border_color = col
		glow.set_border_width_all(3)
		glow.shadow_color = Color(col, 0.75)
		glow.shadow_size = 20
		var p := _panel(c, Color.BLACK, "ResultCard_%d" % i)
		p.add_theme_stylebox_override("panel", glow)
		if frame:
			var fr := TextureRect.new()
			fr.texture = frame
			fr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			fr.stretch_mode = TextureRect.STRETCH_SCALE
			fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_place(fr, c.grow(-3))
		# Ánh màu độ hiếm phía trên thẻ.
		var grad := Gradient.new()
		grad.set_color(0, Color(col, 0.32))
		grad.set_color(1, Color(col, 0.0))
		var gt := GradientTexture2D.new()
		gt.gradient = grad
		gt.fill_from = Vector2(0.5, 0.0)
		gt.fill_to = Vector2(0.5, 1.0)
		var tint := TextureRect.new()
		tint.texture = gt
		tint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tint.stretch_mode = TextureRect.STRETCH_SCALE
		tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(tint, Rect2(c.position + Vector2(3, 3), Vector2(c.size.x - 6, c.size.y * 0.45)))
		var art := result_art(str(res["item"]))
		var tex := art["texture"] as Texture2D
		if bool(art["cover"]) and tex:
			var a := _art(c.grow(-3), tex, "", _top_crop(tex, card.x / card.y), "ResultArt_%d" % i)
			a.fill_color = Color(0, 0, 0, 0)
			a.border_color = Color(0, 0, 0, 0)
		else:
			var box := Rect2(c.position + Vector2(10, card.y * 0.2), Vector2(card.x - 20, card.x - 20))
			var a := _art(box, tex, reward_name(str(res["item"])), Rect2(0, 0, 1, 1), "ResultArt_%d" % i)
			a.fill_color = Color(0, 0, 0, 0)
			a.border_color = Color(0, 0, 0, 0)
		var name_y := card.y - 150.0
		_label(Rect2(c.position + Vector2(6, name_y), Vector2(card.x - 12, 80)), reward_name(str(res["item"])), 22,
				Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER).name = "ResultName_%d" % i
		var stars := _label(Rect2(c.position + Vector2(4, card.y - 64), Vector2(card.x - 8, 40)),
				"★".repeat(result_stars(res)), 26, layout.color("rank_s", Color.GOLD), HORIZONTAL_ALIGNMENT_CENTER)
		stars.name = "ResultStars_%d" % i
		if str(res["item"]).begins_with("char:"):
			if res["duplicate"]:
				var t := b.tier(str(res.get("tier", ""))) if b else null
				var frag := t.duplicate_fragments if t else 0
				var txt := tr("RECRUIT_FRAGMENTS") % frag if frag > 0 else tr("RECRUIT_DUPLICATE")
				_label(Rect2(c.position + Vector2(6, name_y - 50), Vector2(card.x - 12, 44)), txt, 20,
						layout.color("text_dim", Color.GRAY), HORIZONTAL_ALIGNMENT_CENTER).name = "ResultDup_%d" % i
			else:
				var badge := _panel(Rect2(c.position + Vector2(card.x - 70, 10), Vector2(60, 32)), col, "ResultNew_%d" % i)
				badge.add_theme_stylebox_override("panel", _style(col, Color(0, 0, 0, 0), 8))
				_label(badge.get_rect(), tr("RECRUIT_NEW"), 20, Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER)
		if not fx.is_empty():
			fx["flash"] = _make_fx_flash(c, i)
			fx.merge(_make_fx_sparkles(c, col, i))
			_reveal_fx[slot] = fx
		# Gom các node của thẻ vào một lớp để hiệu ứng mờ + trượt chung.
		var holder := Control.new()
		holder.name = "ResultSlot_%d" % slot
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(holder, Rect2(Vector2.ZERO, view))
		var parts: Array[Node] = []
		for k in range(first_child, _root.get_child_count()):
			if _root.get_child(k) != holder:
				parts.append(_root.get_child(k))
		for part in parts:
			part.reparent(holder, true)
		_reveal_slots.append(holder)
	# Xác nhận luôn đóng ngay (cả khi đang hiện, để hướng dẫn người mới bấm một lần là xong); Bỏ qua hiện hết thẻ.
	_button(Rect2(view.x - 340, view.y - 120, 280, 70), tr("RECRUIT_UI_CONFIRM"), 32, intercept_back, false, "ResultClose")
	_button(Rect2(view.x - 640, view.y - 120, 280, 70), tr("RECRUIT_UI_SKIP"), 32, skip_reveal, false, "ResultSkip")
	_apply_reveal()


## Khung cắt phần trên của ảnh để vừa tỉ lệ rộng / cao `aspect` (ảnh toàn thân → thấy mặt và thân trên).
static func _top_crop(tex: Texture2D, aspect: float) -> Rect2:
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	if w <= 0.0 or h <= 0.0 or aspect <= 0.0:
		return Rect2(0, 0, 1, 1)
	if w / h > aspect:
		var fw := (h * aspect) / w
		return Rect2((1.0 - fw) * 0.5, 0, fw, 1)
	return Rect2(0, 0, 1, (w / aspect) / h)
