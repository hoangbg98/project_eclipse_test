class_name HubRecruitPanel
extends HubPanel
## Tab Chiêu mộ: banner trong data/banners, bảng tỉ lệ sinh từ cùng config với logic quay (README Gacha),
## quay 1 / gói, kết quả và lịch sử. Chưa có banner (tỉ lệ thật chờ owner) thì hiện thông báo chưa mở.

const BANNERS_DIR := "res://data/banners"

var banners: Array[BannerDef] = []
var selected := 0
var service: GachaService
var last_results: Array = []
var last_reason := ""
## Test gán sẵn banner để không cần file trong data/.
var banners_injected := false


func build() -> void:
	if not banners_injected:
		banners = load_banners()
	if service == null:
		service = GachaService.new(profile)
	add_child(UiKit.label(wallet_text(), 28))
	if banners.is_empty():
		add_child(UiKit.label(tr("RECRUIT_CLOSED"), 36, HORIZONTAL_ALIGNMENT_CENTER))
		return
	selected = clampi(selected, 0, banners.size() - 1)
	var b := banners[selected]
	add_child(UiKit.label(tr(b.name_key), 44))
	var body := UiKit.vbox(6)
	for line in rate_lines(b):
		body.add_child(UiKit.label(line, 24))
	if last_reason != "":
		body.add_child(UiKit.label(tr("REASON_" + last_reason.to_upper()), 26))
	for r: Dictionary in last_results:
		body.add_child(UiKit.label(result_line(r), 26))
	body.add_child(UiKit.label(tr("RECRUIT_HISTORY") % service.history().size(), 24))
	add_child(UiKit.scroll(body))
	var row := UiKit.hbox()
	for count: int in [1, b.multi_count]:
		var btn := UiKit.button(tr("RECRUIT_PULL") % [count, GachaService.cost_of(b, count)], 420.0, 28)
		btn.disabled = service.check(b, count) != ""
		btn.pressed.connect(pull.bind(count))
		row.add_child(btn)
	add_child(row)


static func load_banners() -> Array[BannerDef]:
	var out: Array[BannerDef] = []
	if not DirAccess.dir_exists_absolute(BANNERS_DIR):
		return out
	for f in ResourceLoader.list_directory(BANNERS_DIR):
		if f.get_extension() in ["tres", "res"]:
			var b := load(BANNERS_DIR.path_join(f)) as BannerDef
			if b and b.validate().is_empty():
				out.append(b)
	return out


## Bảng tỉ lệ hiển thị, lấy từ GachaService.rates_table (cùng config với logic quay).
func rate_lines(b: BannerDef) -> PackedStringArray:
	var out := PackedStringArray()
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
	return item_name(id)


func result_line(r: Dictionary) -> String:
	var b := banners[selected] if selected < banners.size() else null
	var t := b.tier(str(r.get("tier", ""))) if b else null
	var label := tr(t.label_key) if t and t.label_key != "" else "%d★" % r["rarity"]
	return "%s  %s%s" % [label, reward_name(r["item"]), "  (%s)" % tr("RECRUIT_DUPLICATE") if r["duplicate"] else ""]


func pull(count: int) -> bool:
	var res := service.pull(banners[selected], count)
	last_reason = res["reason"]
	last_results = res["results"]
	commit()
	return last_reason == ""
