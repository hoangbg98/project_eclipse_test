extends SceneTree
## Chụp băng thoại trong trận (NeoBark) ở Màn 1 để soát vị trí so với HUD (cần cửa sổ, không --headless):
##   <godot> --path . -s tools/screenshot_bark.gd
## Ảnh: build/screenshots/bark_neo.png (NEO nói lúc vào màn), bark_char.png (Kazeyumi nói ở đợt 1).
## Màn chạy không ghi save (use_save = false).

var _frames := 0
var _t := 0.0
var _step := 0
var _stage: StageController


func _process(delta: float) -> bool:
	_frames += 1
	_t += delta
	if _frames == 1:
		root.get_node("GameConfig").selected_stage_id = "stage_01"
		_stage = (load("res://scenes/stages/stage.tscn") as PackedScene).instantiate()
		_stage.use_save = false
		_stage.party_ids = PackedStringArray(["char_fire_01", "char_wind_01"])
		root.add_child(_stage)
		current_scene = _stage
	if _step == 0 and _t >= 2.5:
		_step = 1
		_shot("bark_neo")
		_stage.party.use_player_input = false
		_stage.player.global_position = _stage.map.ground_feet(int(_stage.waves()[0]["trigger_col"]) + 1)
	if _step == 1 and _t >= 10.0:
		_shot("bark_char")
		return true
	return false


func _shot(n: String) -> void:
	var out := "res://build/screenshots/%s.png" % n
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
