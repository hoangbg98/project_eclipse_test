class_name HubPanel
extends VBoxContainer
## Lớp cha của các bảng trong Hub (Home, Chiến đấu, Nhân vật, Chiêu mộ): giữ PlayerProfile trên dữ liệu save,
## dựng lại nội dung bằng `refresh()`, và lưu file sau mỗi thay đổi của người chơi (`commit()`).
## Bảng chỉ gọi PlayerProfile / Inventory / Progression / GachaService; không tự chứa luật.

signal changed

var profile: PlayerProfile


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	if profile == null:
		var save := UiKit.autoload("SaveService")
		profile = PlayerProfile.new(save.data if save else SaveSchema.default_data())
	refresh()


## Dựng lại toàn bộ nội dung từ dữ liệu hiện tại.
func refresh() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	build()


## Lớp con ghi đè: thêm control vào bảng.
func build() -> void:
	pass


## Ghi save, dựng lại và báo cho Hub.
func commit() -> void:
	var save := UiKit.autoload("SaveService")
	if save and is_same(save.data, profile.data):
		save.save_game()
	refresh()
	changed.emit()


func char_def(id: String) -> CharacterDef:
	var path := PlayerProfile.CHARACTER_DATA % id
	return load(path) as CharacterDef if ResourceLoader.exists(path) else null


func char_name(id: String) -> String:
	var d := char_def(id)
	return tr(d.name_key) if d else id


func item_name(id: String) -> String:
	var d := PlayerProfile.item_defs().get_def(id) as ItemDef
	return tr(d.name_key) if d else id


func equip_name(uid: String) -> String:
	var d := profile.inventory.equipment_def_of(uid)
	if d == null:
		return "—"
	var lv := profile.inventory.equipment_level(uid)
	return tr(d.name_key) + (" +%d" % lv if lv > 0 else "")


func wallet_text() -> String:
	return "%s %d   ·   %s %d" % [tr("CURRENCY_GOLD"), profile.inventory.currency("gold"),
			tr("CURRENCY_GEMS"), profile.inventory.currency("gems")]
