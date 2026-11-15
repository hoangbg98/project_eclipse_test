extends SceneTree
## Chụp màn 1-2 lúc đợt 2 (có Slime tro lớn) để soát bằng mắt (cần cửa sổ, không --headless):
##   <godot> --path . -s tools/screenshot_stage_01_02.gd
## Ảnh ra build/screenshots/stage_01_02_wave2.png. Không ghi save thật.

const STAGE := "res://scenes/stages/stage.tscn"

var _frames := 0
var _stage: StageController


func _initialize() -> void:
	_stage = (load(STAGE) as PackedScene).instantiate()
	_stage.use_selected_stage = false
	_stage.use_save = false
	_stage.stage_id = "stage_01_02"
	_stage.party_ids = PackedStringArray(["char_fire_01", "char_wind_01", "char_lightning_01"])
	root.add_child(_stage)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 20:
		_stage.party.use_player_input = false
		var w: Dictionary = _stage.waves()[1]
		_stage.waves_cleared = 1
		_stage.player.global_position = _stage.map.ground_feet(int(w["trigger_col"]) + 2)
	if _frames == 90:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/screenshots"))
		root.get_viewport().get_texture().get_image().save_png("res://build/screenshots/stage_01_02_wave2.png")
		return true
	return false
