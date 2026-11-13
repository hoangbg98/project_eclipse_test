class_name DebugGiftScreen
extends Control
## Màn "Quà thử nghiệm" (owner 2026-11-14): gửi quà thẳng vào tài khoản đang chơi để thử game, không cần quay gacha hay
## đi màn. Chỉ có ở bản debug (`available()`); mở từ tab Cài đặt của Hub. Gói quà mẫu đọc từ data/debug/gift_presets.json,
## ô nhập nhận cú pháp quà tự do (xem DebugGift). Màn chỉ gọi DebugGift; không chứa luật.

## Test đặt true / false để thử cả hai trường hợp; null = theo OS.is_debug_build().
static var force_available: Variant = null

var profile: PlayerProfile
## false: không ghi file save (test dùng dữ liệu riêng).
var save_enabled := true
## Kết quả lần gửi gần nhất (hiện ở khung dưới).
var result_text := ""

var _last_text := ""


static func available() -> bool:
	if force_available != null:
		return bool(force_available)
	return OS.is_debug_build()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if profile == null:
		var save := UiKit.autoload("SaveService")
		profile = PlayerProfile.new(save.data if save else SaveSchema.default_data())
	_build()


func status_text() -> String:
	var inv := profile.inventory
	return tr("DEBUG_GIFT_STATUS") % [inv.currency("gems"), inv.currency("gold"), profile.progression.captain_level(),
			profile.data["characters"].size(), inv.equipment_uids().size()]


## Gửi quà theo cú pháp DebugGift. Lỗi cú pháp / ID lạ thì không đổi gì và hiện lỗi. Trả về true nếu đã gửi.
func send(text: String) -> bool:
	_last_text = text
	var parsed := DebugGift.parse(text)
	var errors: PackedStringArray = parsed["errors"]
	if errors.is_empty() and DebugGift.is_empty(parsed["gift"]):
		errors.append(tr("DEBUG_GIFT_EMPTY"))
	var lines := PackedStringArray()
	var ok := false
	if errors.is_empty():
		var res := DebugGift.apply(profile, parsed["gift"])
		ok = res["ok"]
		errors = res["errors"]
		lines = res["lines"]
	if ok:
		result_text = tr("DEBUG_GIFT_OK") + "\n" + "\n".join(Array(lines).map(func(l: String) -> String: return "• " + l))
		var save := UiKit.autoload("SaveService")
		if save_enabled and save and is_same(save.data, profile.data):
			save.save_game()
	else:
		result_text = tr("DEBUG_GIFT_ERRORS") + "\n" + "\n".join(Array(errors).map(func(l: String) -> String: return "• " + l))
	_build()
	return ok


func send_preset(preset_name: String) -> bool:
	return send("preset:" + preset_name)


func _go_back() -> void:
	var router := UiKit.autoload("SceneRouter")
	if router:
		router.go_back()


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = Color("#1B1E2B")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 56)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	add_child(margin)
	var root := UiKit.vbox(12)
	margin.add_child(root)

	root.add_child(UiKit.label(tr("DEBUG_GIFT_TITLE"), UiKit.FONT_TITLE))
	var warn := UiKit.label(tr("DEBUG_GIFT_WARN"), 26)
	warn.modulate = Color("#FFB347")
	root.add_child(warn)
	var status := UiKit.label(status_text(), 28)
	status.name = "Status"
	root.add_child(status)

	root.add_child(UiKit.label(tr("DEBUG_GIFT_PRESETS"), 30))
	var presets := DebugGift.load_presets()
	if presets.is_empty():
		root.add_child(UiKit.label(tr("DEBUG_GIFT_NO_PRESETS"), 26))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for preset_name: String in presets:
		var info: Dictionary = presets[preset_name]
		var b := Button.new()
		b.name = "Preset_" + preset_name
		b.text = "%s\n%s" % [info.get("title", preset_name), info.get("gift", "")]   # chuỗi quà: ngắn gọn và là cú pháp để học
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.clip_text = true
		b.custom_minimum_size = Vector2(0, 104)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(send_preset.bind(preset_name))
		grid.add_child(b)
	root.add_child(grid)

	root.add_child(UiKit.label(tr("DEBUG_GIFT_CUSTOM"), 30))
	var row := UiKit.hbox(12)
	var input := LineEdit.new()
	input.name = "GiftInput"
	input.text = _last_text
	input.placeholder_text = DebugGift.SYNTAX_HELP
	input.custom_minimum_size = Vector2(0, 84)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.add_theme_font_size_override("font_size", 28)
	input.text_submitted.connect(send)
	row.add_child(input)
	var send_btn := UiKit.button(tr("DEBUG_GIFT_SEND"), 220.0, 30)
	send_btn.name = "SendButton"
	send_btn.custom_minimum_size.y = 84.0
	send_btn.pressed.connect(func() -> void: send(input.text))
	row.add_child(send_btn)
	root.add_child(row)
	root.add_child(UiKit.label(tr("DEBUG_GIFT_HINT"), 22))

	var result := UiKit.label(result_text, 26)
	result.name = "Result"
	var scroll := UiKit.scroll(result)
	scroll.custom_minimum_size.y = 150.0
	root.add_child(scroll)
	var back := UiKit.button(tr("UI_BACK"), 320.0, 30)
	back.name = "BackButton"
	back.custom_minimum_size.y = 84.0
	back.pressed.connect(_go_back)
	root.add_child(back)
