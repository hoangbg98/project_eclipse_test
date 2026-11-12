class_name CreditsPanel
extends VBoxContainer
## Màn Credits / giấy phép trong game (README 2.1: mọi giấy phép cần hiển thị phải có ở đây).
## Nội dung lấy từ `data/credits.json` (soạn theo docs/ASSET_LICENSES.md) + giấy phép của Godot Engine.

const DATA_PATH := "res://data/credits.json"

var text_label: RichTextLabel


func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(UiKit.label(tr("CREDITS_TITLE"), UiKit.FONT_TITLE))
	text_label = RichTextLabel.new()
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.custom_minimum_size = Vector2(0, 400)
	text_label.add_theme_font_size_override("normal_font_size", 24)
	text_label.add_theme_font_size_override("bold_font_size", 28)
	text_label.bbcode_enabled = true
	text_label.text = build_text()
	add_child(text_label)


## Danh sách mục credits từ file data; lỗi thì trả về rỗng (không crash).
static func load_entries() -> Array:
	if not FileAccess.file_exists(DATA_PATH):
		return []
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return d.get("entries", []) if d is Dictionary and d.get("entries") is Array else []


func build_text() -> String:
	var out := PackedStringArray()
	for e: Dictionary in load_entries():
		out.append("[b]%s[/b]" % str(e.get("name", "")))
		for k in ["role", "license", "copyright", "source"]:
			if str(e.get(k, "")) != "":
				out.append("%s: %s" % [tr("CREDITS_" + k.to_upper()), str(e[k])])
		if str(e.get("license_text", "")) != "":
			out.append(str(e["license_text"]))
		out.append("")
	out.append("[b]Godot Engine[/b]")
	out.append(Engine.get_license_text())
	return "\n".join(out)
