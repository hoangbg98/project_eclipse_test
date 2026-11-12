extends SceneTree
## Chụp ảnh đấu trường boss của Màn 1 để soát bằng mắt (cần cửa sổ, không chạy --headless):
##   <godot> --path . -s tools/screenshot_boss.gd -- [đường dẫn png]
## Không đọc / ghi save thật (use_save = false).

var _frames := 0
var _stage: Node
var _out := "res://build/screenshots/stage_01_boss.png"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_stage = (load("res://scenes/stages/stage.tscn") as PackedScene).instantiate()
	_stage.use_selected_stage = false
	_stage.use_save = false
	_stage.stage_id = "stage_01"
	root.add_child(_stage)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 20:
		_stage.party.use_player_input = false
		_stage.waves_cleared = 3
		_stage.player.global_position = _stage.map.ground_feet(170)
	if _frames == 60 and _stage.boss:
		_stage.boss.combatant.resources.take_damage(_stage.boss.combatant.resources.max_hp * 0.3)
	if _frames >= 60 and _stage.boss and _stage.boss.is_telegraphing() or _frames == 400:
		_frames = maxi(_frames, 1000)
	if _frames == 1008:
		var img := root.get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out.get_base_dir()))
		img.save_png(_out)
		print("saved ", ProjectSettings.globalize_path(_out))
		return true
	return false
