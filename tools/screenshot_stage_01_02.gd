extends SceneTree
## Chụp màn cốt truyện lúc đợt 2 để soát bằng mắt (cần cửa sổ, không --headless):
##   <godot> --path . -s tools/screenshot_stage_01_02.gd -- [id màn, mặc định stage_01_02]
## Ảnh ra build/screenshots/<id>_wave2.png. Không ghi save thật.

const STAGE := "res://scenes/stages/stage.tscn"

var _frames := 0
var _stage: StageController
var _id := "stage_01_02"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_id = args[0]
	_stage = (load(STAGE) as PackedScene).instantiate()
	_stage.use_selected_stage = false
	_stage.use_save = false
	_stage.stage_id = _id
	_stage.party_ids = PackedStringArray(["char_fire_01", "char_wind_01", "char_lightning_01"])
	root.add_child(_stage)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 20:
		_stage.party.use_player_input = false
		if _boss():
			_stage.waves_cleared = _stage.wave_count()
			_stage.player.global_position = _stage.map.ground_feet(int(_stage.boss_data()["trigger_col"]) + 2)
		else:
			var w: Dictionary = _stage.waves()[1]
			_stage.waves_cleared = 1
			_stage.player.global_position = _stage.map.ground_feet(int(w["trigger_col"]) + 2)
	if _frames == 90:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/screenshots"))
		root.get_viewport().get_texture().get_image().save_png("res://build/screenshots/%s_%s.png" % [
				_id, "boss" if _boss() else "wave2"])
		return true
	return false


## Thêm đối số thứ hai "boss" để chụp lúc vào đấu trường boss (ảnh <id>_boss.png).
func _boss() -> bool:
	var args := OS.get_cmdline_user_args()
	return args.size() > 1 and args[1] == "boss" and not _stage.boss_data().is_empty()
