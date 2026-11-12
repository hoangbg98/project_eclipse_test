extends SceneTree
## Kiểm tra khói M1-5 (headless): file dịch vi/en đủ khóa, mọi chữ trong scene là khóa dịch có bản dịch.
## Chạy: godot --headless --path . --script res://tests/smoke/m1_i18n_check.gd

const SCENE_DIRS: Array[String] = ["res://scenes/main", "res://scenes/stages"]
## Chữ không dịch: tên thương hiệu và giá trị tạm được script ghi đè khi chạy.
const ALLOWED_LITERALS: Array[String] = ["PROJECT ECLIPSE", "v0"]
const PO_FILES := {"vi": "res://localization/vi.po", "en": "res://localization/en.po"}

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		_failures += 1


func _po_keys(path: String) -> PackedStringArray:
	var keys := PackedStringArray()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return keys
	var rx := RegEx.create_from_string('^msgid "([^"]+)"')
	while not f.eof_reached():
		var m := rx.search(f.get_line())
		if m != null:
			keys.append(m.get_string(1))
	return keys


func _scene_texts() -> Dictionary:  # đường dẫn -> Array[String]
	var out := {}
	var rx := RegEx.create_from_string('(?m)^text = "([^"]*)"')
	for dir_path in SCENE_DIRS:
		for file in DirAccess.get_files_at(dir_path):
			if not file.ends_with(".tscn"):
				continue
			var path := dir_path.path_join(file)
			var texts: Array[String] = []
			for m in rx.search_all(FileAccess.get_file_as_string(path)):
				texts.append(m.get_string(1))
			out[path] = texts
	return out


func _run() -> void:
	var game_config := root.get_node("GameConfig")

	# 1. Hai file dịch có cùng tập khóa, không rỗng
	var vi := _po_keys(PO_FILES["vi"])
	var en := _po_keys(PO_FILES["en"])
	_check(vi.size() > 0, "vi.po có khóa (%d)" % vi.size())
	var missing_in_en := []
	for k in vi:
		if k not in en:
			missing_in_en.append(k)
	var missing_in_vi := []
	for k in en:
		if k not in vi:
			missing_in_vi.append(k)
	_check(missing_in_en.is_empty(), "mọi khóa vi có trong en %s" % [missing_in_en])
	_check(missing_in_vi.is_empty(), "mọi khóa en có trong vi %s" % [missing_in_vi])

	# 2. Mỗi khóa dịch ra khác chính nó ở cả hai ngôn ngữ
	for code in ["vi", "en"]:
		_check(game_config.set_language(code), "chuyển ngôn ngữ %s" % code)
		var untranslated := []
		for k in vi:
			if TranslationServer.translate(k) == k:
				untranslated.append(k)
		_check(untranslated.is_empty(), "[%s] mọi khóa có bản dịch %s" % [code, untranslated])
	_check(not game_config.set_language("xx"), "từ chối ngôn ngữ không hỗ trợ")

	# 3. Giá trị mẫu
	game_config.set_language("vi")
	_check(TranslationServer.translate("TITLE_NEW_GAME") == "Game mới", "vi: TITLE_NEW_GAME = Game mới")
	game_config.set_language("en")
	_check(TranslationServer.translate("TITLE_NEW_GAME") == "New Game", "en: TITLE_NEW_GAME = New Game")

	# 4. Chữ trong scene: hoặc là khóa có trong file dịch, hoặc nằm trong danh sách cho phép
	var scene_texts := _scene_texts()
	_check(scene_texts.size() > 0, "đọc được scene để kiểm tra (%d file)" % scene_texts.size())
	var key_rx := RegEx.create_from_string("^[A-Z][A-Z0-9_]+$")
	for path: String in scene_texts:
		var bad := []
		for t: String in scene_texts[path]:
			if t in ALLOWED_LITERALS or t.is_empty():
				continue
			if key_rx.search(t) == null or t not in vi:
				bad.append(t)
		_check(bad.is_empty(), "%s: chữ đều là khóa dịch hợp lệ %s" % [path, bad])

	# 5. Hub thật sự đổi chữ theo ngôn ngữ
	game_config.set_language("en")
	var hub: Control = load("res://scenes/main/hub.tscn").instantiate()
	root.add_child(hub)
	await process_frame
	# M7-2: nội dung tab là bảng dựng bằng code; gom chữ của mọi Label trong vùng nội dung.
	var texts := PackedStringArray()
	for l in hub.get_node("Content").find_children("*", "Label", true, false):
		texts.append((l as Label).text)
	var joined := " | ".join(texts)
	_check(joined.contains("Party") and joined.contains("Gold") and joined.contains("Stages cleared"),
			"Hub (en) hiện chữ tiếng Anh: %s" % joined)
	hub.queue_free()
	game_config.set_language("vi")

	print("KẾT QUẢ: %d lỗi" % _failures)
	quit(1 if _failures > 0 else 0)
