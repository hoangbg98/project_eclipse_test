extends SceneTree
## Chụp các bước hướng dẫn người mới để soát bằng mắt (cần cửa sổ, không chạy --headless):
##   <godot> --path . -s tools/screenshot_tutorial.gd
## Ảnh ra build/screenshots/tutorial_<bước>.png. Dữ liệu chỉ nằm trong bộ nhớ; KHÔNG ghi save.

const GC := preload("res://scripts/core/game_config.gd")

## [tên ảnh, scene, đã qua ải 1-1 chưa]
const SHOTS := [
	["1_hub_sortie", GC.SCENE_HUB, false],
	["2_sortie_story", GC.SCENE_SORTIE, false],
	["3_stage_info", GC.SCENE_STAGE_INFO, false],
	["4_party_go", GC.SCENE_PARTY_PREP, false],
	["5_hub_supply", GC.SCENE_HUB, true],
	["6_supply_gacha", GC.SCENE_SUPPLY, true],
	["7_recruit_starter", GC.SCENE_RECRUIT, true],
]

var _frames := 0
var _index := 0


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		var gc := root.get_node("GameConfig")
		gc.prep_launch_stage = true
	var phase := _frames % 30
	if phase == 2:
		if _index >= SHOTS.size():
			return true
		var shot: Array = SHOTS[_index]
		var save := root.get_node("SaveService")
		save.data = SaveSchema.default_data()
		if shot[2]:
			var p := PlayerProfile.new(save.data)
			p.grant(StageMap.load_from("res://data/stages/stage_01.json").data["first_clear_rewards"])
			save.data["progress"]["stages"]["stage_01"] = {"cleared": true, "best_time_sec": 214.0}
		change_scene_to_file(shot[1])
	if phase == 28:
		var out := "res://build/screenshots/tutorial_%s.png" % SHOTS[_index][0]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
		root.get_texture().get_image().save_png(out)
		print("saved ", out)
		_index += 1
	return false
