class_name HubCharactersPanel
extends HubPanel
## Tab Nhân vật: chọn nhân vật, xem cấp / EXP / chỉ số, dùng sách EXP, mặc / tháo / cường hóa trang bị.

var selected := ""
## Lý do của thao tác gần nhất bị từ chối ("" = thành công); hiện thành một dòng thông báo.
var last_reason := ""


func build() -> void:
	var ids: Array = profile.data["characters"].keys()
	if selected == "" or selected not in ids:
		selected = str(ids[0]) if not ids.is_empty() else ""
	add_child(UiKit.label(wallet_text(), 28))
	var tabs := UiKit.hbox(12)
	for id: String in ids:
		var b := UiKit.button(char_name(id), 240.0, 28)
		b.toggle_mode = true
		b.set_pressed_no_signal(id == selected)
		b.pressed.connect(select.bind(id))
		tabs.add_child(b)
	add_child(tabs)
	if selected == "":
		return
	for line in stat_lines():
		add_child(UiKit.label(line, 28))
	if last_reason != "":
		var warn := UiKit.label(tr("REASON_" + last_reason.to_upper()), 26)
		warn.add_theme_color_override("font_color", Color("#FF8A6A"))
		add_child(warn)
	# Sách EXP.
	var books := UiKit.hbox(12)
	for mat_id in PlayerProfile.item_defs().ids():
		var d := PlayerProfile.item_defs().get_def(mat_id) as ItemDef
		if d.kind != ItemDef.Kind.EXP:
			continue
		var n := profile.inventory.material_count(mat_id)
		var b := UiKit.button("%s ×%d" % [tr(d.name_key), n], 360.0, 24)
		b.disabled = n <= 0
		b.pressed.connect(use_exp.bind(mat_id))
		books.add_child(b)
	add_child(books)
	# Trang bị: mỗi ô một hàng.
	for slot in EquipmentDef.SLOTS:
		var row := UiKit.hbox(12)
		var uid := profile.inventory.equipped_uid(selected, slot)
		var name_label := UiKit.label("%s: %s" % [tr("SLOT_" + slot.to_upper()), equip_name(uid) if uid != "" else "—"], 26)
		name_label.custom_minimum_size.x = 520
		row.add_child(name_label)
		var next := UiKit.button(tr("CHAR_EQUIP_NEXT"), 220.0, 24)
		next.disabled = candidates(slot).is_empty()
		next.pressed.connect(equip_next.bind(slot))
		row.add_child(next)
		var up := UiKit.button(tr("CHAR_ENHANCE"), 220.0, 24)
		up.disabled = uid == ""
		up.pressed.connect(enhance_slot.bind(slot))
		row.add_child(up)
		var off := UiKit.button(tr("CHAR_UNEQUIP"), 180.0, 24)
		off.disabled = uid == ""
		off.pressed.connect(unequip.bind(slot))
		row.add_child(off)
		add_child(row)


func select(id: String) -> void:
	selected = id
	last_reason = ""
	refresh()


func stat_lines() -> PackedStringArray:
	var s := profile.stats_of(selected)
	var lv := profile.progression.level_of(selected)
	var need := profile.rules.exp_to_next(lv)
	var xp := tr("CHAR_MAX_LEVEL") if need <= 0 else "%d / %d" % [profile.progression.exp_of(selected), need]
	return PackedStringArray([
		"%s   Lv.%d   EXP %s" % [char_name(selected), lv, xp],
		"HP %d   ATK %d   DEF %d   %s %d%%   %s +%d%%" % [int(s.max_hp), int(s.atk), int(s.def),
				tr("CHAR_CRIT_RATE"), roundi(s.crit_rate * 100.0), tr("CHAR_CRIT_DAMAGE"), roundi(s.crit_damage * 100.0)],
	])


## Dùng 1 sách EXP cho nhân vật đang chọn.
func use_exp(material_id: String) -> bool:
	last_reason = profile.progression.use_exp_material(selected, material_id, 1)
	commit()
	return last_reason == ""


## Trang bị trong kho thuộc ô `slot` mà nhân vật đang chọn chưa mặc.
func candidates(slot: String) -> PackedStringArray:
	var out := PackedStringArray()
	for uid in profile.inventory.equipment_uids():
		var d := profile.inventory.equipment_def_of(uid)
		if d and d.slot == slot and profile.inventory.equipped_uid(selected, slot) != uid:
			out.append(uid)
	return out


## Mặc món kế tiếp trong kho cho ô này (xoay vòng qua các món cùng ô).
func equip_next(slot: String) -> bool:
	var list := candidates(slot)
	if list.is_empty():
		return false
	last_reason = profile.inventory.equip(selected, list[0])
	commit()
	return last_reason == ""


func unequip(slot: String) -> bool:
	var ok := profile.inventory.unequip(selected, slot)
	last_reason = ""
	commit()
	return ok


## Cường hóa món đang mặc ở ô này: dùng nguyên liệu cường hóa đầu tiên đủ số lượng.
func enhance_slot(slot: String) -> bool:
	var uid := profile.inventory.equipped_uid(selected, slot)
	last_reason = Inventory.REASON_NOT_OWNED
	for mat_id in PlayerProfile.item_defs().ids():
		var d := PlayerProfile.item_defs().get_def(mat_id) as ItemDef
		if d.kind != ItemDef.Kind.ENHANCE:
			continue
		last_reason = profile.inventory.enhance(uid, mat_id)
		if last_reason == "" or last_reason == Inventory.REASON_MAX_LEVEL:
			break
	commit()
	return last_reason == ""
