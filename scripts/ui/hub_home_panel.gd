class_name HubHomePanel
extends HubPanel
## Tab Home: tóm tắt tài khoản — tiền, đội hiện tại, tiến độ màn.


func build() -> void:
	add_child(UiKit.label("PROJECT ECLIPSE", 64))
	for line in summary_lines():
		add_child(UiKit.label(line, 30))


func summary_lines() -> PackedStringArray:
	var out := PackedStringArray([wallet_text()])
	var names := PackedStringArray()
	for id in profile.party_ids():
		names.append("%s Lv.%d" % [char_name(id), profile.progression.level_of(id)])
	out.append("%s: %s" % [tr("BATTLE_PARTY_TITLE"), " · ".join(names)])
	var cleared := 0
	for id in profile.data["progress"]["stages"]:
		var st: Variant = profile.data["progress"]["stages"][id]
		if st is Dictionary and bool(st.get("cleared", false)):
			cleared += 1
	out.append(tr("HOME_STAGES_CLEARED") % cleared)
	return out
