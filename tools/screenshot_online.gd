extends SceneTree
## Chụp màn Title và màn "Trực tuyến" khi đã kết nối máy chủ thật (cần cửa sổ và máy chủ đang chạy):
##   <godot> --path . -s tools/screenshot_online.gd
## Ảnh ra build/screenshots/online_<n>.png.

var _frames := 0
var _screen: Control
var _done := false


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		root.add_child((load("res://scenes/main/title.tscn") as PackedScene).instantiate())
	elif _frames == 10:
		_shot("0_title")
		root.get_child(root.get_child_count() - 1).queue_free()
		root.get_node("OnlineService").device_file = "user://online_e2e_device.cfg"
		_screen = (load("res://scenes/main/online_screen.tscn") as PackedScene).instantiate()
		root.add_child(_screen)
		_connect()
	elif _done and _frames > 20:
		_shot("1_connected")
		return true
	return false


func _connect() -> void:
	await _screen.connect_server()
	_done = true


func _shot(name_: String) -> void:
	var out := "res://build/screenshots/online_%s.png" % name_
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
