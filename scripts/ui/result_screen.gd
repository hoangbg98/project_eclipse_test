class_name ResultScreen
extends CanvasLayer
## Màn kết quả cuối màn chơi (README 15.7): thắng / thua, thời gian, phần thưởng, lên cấp; nút Về Hub và Chơi lại.
## StageController gọi `show_result(summary)`; lớp này chỉ hiển thị và điều hướng.

signal closed(action: String)

var summary: Dictionary = {}

var _panel: PanelContainer
var _title: Label
var _lines: VBoxContainer
var _hub: Button
var _retry: Button


func _ready() -> void:
	layer = 95
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(1000, 860)
	_panel.offset_left = -500
	_panel.offset_right = 500
	_panel.offset_top = -430
	_panel.offset_bottom = 430
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_panel.add_child(box)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 64)
	box.add_child(_title)
	_lines = VBoxContainer.new()
	_lines.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lines.add_theme_constant_override("separation", 6)
	box.add_child(_lines)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	box.add_child(row)
	_retry = _button(row, "RESULT_RETRY")
	_hub = _button(row, "RESULT_TO_HUB")
	_retry.pressed.connect(_on_retry)
	_hub.pressed.connect(_on_hub)


func _button(row: HBoxContainer, key: String) -> Button:
	var b := Button.new()
	b.text = tr(key)
	b.custom_minimum_size = Vector2(320, 128)        # vùng chạm ≥ 128 px
	b.add_theme_font_size_override("font_size", 34)
	row.add_child(b)
	return b


func show_result(s: Dictionary) -> void:
	summary = s
	for c in _lines.get_children():
		c.queue_free()
	var victory := bool(s.get("victory", false))
	_title.text = tr("RESULT_VICTORY") if victory else tr("RESULT_DEFEAT")
	_title.add_theme_color_override("font_color", Color("#FFD93D") if victory else Color("#FF6A6A"))
	for text in result_lines(s):
		var l := Label.new()
		l.text = text
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 28)
		_lines.add_child(l)
	visible = true
	(_hub if victory else _retry).grab_focus()


## Các dòng nội dung (tách riêng để test không cần dựng UI).
func result_lines(s: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var t := StageHud.format_time(float(s.get("time_sec", 0.0)))
	out.append(tr("RESULT_TIME") % t + ("  " + tr("RESULT_BEST_TIME") if bool(s.get("best_time", false)) else ""))
	if not bool(s.get("victory", false)):
		out.append(tr("RESULT_DEFEAT_HINT"))
		return out
	out.append_array(_reward_lines(tr("RESULT_REWARDS"), s.get("rewards", {})))
	if bool(s.get("first_clear", false)):
		out.append_array(_reward_lines(tr("RESULT_FIRST_CLEAR"), s.get("first_clear_rewards", {})))
	var objs: Array = s.get("objectives", [])
	if not objs.is_empty():
		out.append(tr("RESULT_OBJECTIVES") % [objs.filter(func(o: Dictionary) -> bool: return bool(o.get("met", false))).size(),
				objs.size(), int((s.get("objective_rewards", {}) as Dictionary).get("gold", 0))])
		for o: Dictionary in objs:
			out.append("  %s %s" % ["✔" if bool(o.get("met", false)) else "✘", BattleObjectives.describe(o)])
	var levels := {}
	for part in [s.get("rewards", {}), s.get("first_clear_rewards", {}), s.get("objective_rewards", {})]:
		for id in (part as Dictionary).get("levels", {}):
			levels[id] = int(levels.get(id, 0)) + int(part["levels"][id])
	for id in levels:
		out.append(tr("RESULT_LEVEL_UP") % [_char_name(str(id)), levels[id]])
	return out


func _reward_lines(header: String, got: Dictionary) -> PackedStringArray:
	var parts := PackedStringArray()
	if int(got.get("gold", 0)) > 0:
		parts.append("%s ×%d" % [tr("CURRENCY_GOLD"), int(got["gold"])])
	if int(got.get("gems", 0)) > 0:
		parts.append("%s ×%d" % [tr("CURRENCY_GEMS"), int(got["gems"])])
	var mats: Dictionary = got.get("materials", {})
	for id in mats:
		var d := PlayerProfile.item_defs().get_def(str(id)) as ItemDef
		parts.append("%s ×%d" % [tr(d.name_key) if d else str(id), int(mats[id])])
	var eq: Array = got.get("equipment", [])
	if not eq.is_empty():
		parts.append(tr("RESULT_EQUIPMENT") % eq.size())
	if parts.is_empty():
		return PackedStringArray()
	return PackedStringArray([header, "  " + " · ".join(parts)])


func _char_name(id: String) -> String:
	var path := "res://data/characters/%s.tres" % id
	return tr((load(path) as CharacterDef).name_key) if ResourceLoader.exists(path) else id


func _on_retry() -> void:
	closed.emit("retry")
	var router := _autoload("SceneRouter")
	var gc := _autoload("GameConfig")
	if router and gc:
		router.replace(gc.SCENE_STAGE)


func _on_hub() -> void:
	closed.emit("hub")
	var router := _autoload("SceneRouter")
	var gc := _autoload("GameConfig")
	if router == null or gc == null:
		return
	# go_back() là hàm bất đồng bộ: không dùng giá trị trả về, hỏi can_go_back() trước.
	if router.can_go_back():
		router.go_back()
	else:
		router.replace(gc.SCENE_HUB)


## Lấy autoload qua đường dẫn (scene màn chơi còn được nạp bằng --script trong test khói).
func _autoload(n: String) -> Node:
	return get_tree().root.get_node_or_null(n) if is_inside_tree() else null
