extends SceneTree
## Chụp màn "Quà thử nghiệm" (cần cửa sổ, không chạy --headless):
##   <godot> --path . -s tools/screenshot_gift.gd
## Ảnh ra build/screenshots/gift_<n>.png. Dữ liệu tạm trong bộ nhớ; KHÔNG ghi save.

var _frames := 0
var _screen: DebugGiftScreen


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		var data := SaveSchema.default_data()
		var save := root.get_node_or_null("SaveService")
		if save:
			save.data = data
		_screen = (load("res://scenes/main/debug_gift_screen.tscn") as PackedScene).instantiate()
		_screen.profile = PlayerProfile.new(data)
		_screen.save_enabled = false
		root.add_child(_screen)
	elif _frames == 10:
		_shot("1_start")
		_screen.send("preset:level_up equip:eq_weapon_flame=2 char:char_earth_01")
	elif _frames == 20:
		_shot("2_sent")
		_screen.send("gems=5000 equip:eq_khong_co")
	elif _frames == 30:
		_shot("3_error")
		return true
	return false


func _shot(name_: String) -> void:
	var out := "res://build/screenshots/gift_%s.png" % name_
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
