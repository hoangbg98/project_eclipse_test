class_name HubBattlePanel
extends HubPanel
## Tab Chiến đấu: chọn đội (1–3 nhân vật đang sở hữu, theo thứ tự bấm) và xem các màn (đã qua, kỷ lục).
## Nút vào màn nằm trong hub.tscn (Stage01Button, TestStageButton).

const STAGES_DIR := "res://data/stages"
## Màn hiện trong danh sách (test_stage là màn thử, không tính tiến độ).
const HIDDEN_STAGES := ["test_stage"]

var party_buttons: Dictionary = {}   # id -> Button


func build() -> void:
	add_child(UiKit.label(tr("BATTLE_PARTY_TITLE"), 40))
	add_child(UiKit.label(tr("BATTLE_PARTY_HINT"), 24))
	var row := UiKit.hbox(16)
	party_buttons.clear()
	var party := Array(profile.party_ids())
	for id: String in profile.data["characters"]:
		var slot := party.find(id)
		var text := "%s  Lv.%d" % [char_name(id), profile.progression.level_of(id)]
		var b := UiKit.button(("%d · " % (slot + 1) if slot >= 0 else "") + text, 300.0, 28)
		b.toggle_mode = true
		b.set_pressed_no_signal(slot >= 0)
		b.pressed.connect(toggle_party.bind(id))
		row.add_child(b)
		party_buttons[id] = b
	add_child(row)
	add_child(UiKit.label(tr("BATTLE_STAGES_TITLE"), 40))
	for line in stage_lines():
		add_child(UiKit.label(line, 28))


## Thêm / bỏ một nhân vật khỏi đội. Không bỏ được người cuối cùng; đội đủ 3 thì không thêm.
func toggle_party(id: String) -> bool:
	if profile.toggle_party(id) != PlayerProfile.PARTY_OK:
		refresh()
		return false
	commit()
	return true


func stage_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for f in ResourceLoader.list_directory(STAGES_DIR):
		if f.get_extension() == "json" and f.get_basename() not in HIDDEN_STAGES:
			out.append(f.get_basename())
	out.sort()
	return out


func stage_lines() -> PackedStringArray:
	var out := PackedStringArray()
	var stages: Dictionary = profile.data["progress"]["stages"]
	for id in stage_ids():
		var m := StageMap.load_from("%s/%s.json" % [STAGES_DIR, id])
		var title := tr(str(m.data.get("name_key", ""))) if m.data.has("name_key") else id
		var st: Variant = stages.get(id)
		if st is Dictionary and bool(st.get("cleared", false)):
			out.append("%s — %s · %s" % [title, tr("BATTLE_STAGE_CLEARED"),
					tr("BATTLE_STAGE_BEST") % StageHud.format_time(float(st.get("best_time_sec", 0.0)))])
		else:
			out.append("%s — %s" % [title, tr("BATTLE_STAGE_NEW")])
	return out
