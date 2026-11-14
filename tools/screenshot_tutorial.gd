extends SceneTree
## Chụp các bước hướng dẫn người mới (NEO trò chuyện + câu chỉ dẫn) để soát bằng mắt (cần cửa sổ, không --headless):
##   <godot> --path . -s tools/screenshot_tutorial.gd
## Ảnh ra build/screenshots/tutorial_<bước>.png. Dữ liệu chỉ nằm trong bộ nhớ; KHÔNG ghi save.

const GC := preload("res://scripts/core/game_config.gd")

## [tên ảnh, scene, đã qua ải 1-1 chưa, "talk" = câu thoại đầu | "act" = câu chỉ dẫn (đã nghe thoại)]
const SHOTS := [
	["1_hub_talk", GC.SCENE_HUB, false, "talk"],
	["2_hub_act", GC.SCENE_HUB, false, "act"],
	["3_sortie_talk", GC.SCENE_SORTIE, false, "talk"],
	["3b_chapters_act", GC.SCENE_CHAPTERS, false, "act"],
	["3c_map_talk", GC.SCENE_CHAPTER_MAP, false, "talk"],
	["3d_map_act", GC.SCENE_CHAPTER_MAP, false, "act"],
	["4_stage_info_act", GC.SCENE_STAGE_INFO, false, "act"],
	["5_party_go_act", GC.SCENE_PARTY_PREP, false, "act"],
	["6_hub_supply_talk", GC.SCENE_HUB, true, "talk"],
	["7_supply_act", GC.SCENE_SUPPLY, true, "act"],
	["8_recruit_talk", GC.SCENE_RECRUIT, true, "talk"],
	["9_recruit_act", GC.SCENE_RECRUIT, true, "act"],
]
const PERIOD := 40

var _frames := 0
var _index := 0


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		root.get_node("GameConfig").prep_launch_stage = true
	var phase := _frames % PERIOD
	var guide := root.get_node_or_null("TutorialGuide")
	if phase == 2:
		if _index >= SHOTS.size():
			return true
		var shot: Array = SHOTS[_index]
		var save := root.get_node("SaveService")
		save.store = SaveStore.new("user://screenshot_tutorial_tmp")   # _mark_seen không đụng save thật
		save.data = SaveSchema.default_data()
		if shot[2]:
			var p := PlayerProfile.new(save.data)
			p.grant(StageMap.load_from("res://data/stages/stage_01.json").data["first_clear_rewards"])
			save.data["progress"]["stages"]["stage_01"] = {"cleared": true, "best_time_sec": 214.0}
		if shot[3] == "act":
			for id in ["hub_sortie", "sortie_story", "chapter_card", "map_stage", "stage_prepare", "party_go", "hub_supply", "supply_gacha",
					"recruit_starter"]:
				TutorialFlow.mark_seen(save.data, id)
		if guide:
			guide.step_id = ""
		change_scene_to_file(shot[1])
	if phase == PERIOD - 6 and guide and guide.is_active() and not guide.line_done():
		guide.advance()                # hiện hết câu đang gõ
	if phase == PERIOD - 2:
		var out := "res://build/screenshots/tutorial_%s.png" % SHOTS[_index][0]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
		root.get_texture().get_image().save_png(out)
		print("saved ", out)
		_index += 1
	return false
