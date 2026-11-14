extends SceneTree
## Chụp màn chọn chương và map chương để soát bằng mắt (cần cửa sổ, không --headless):
##   <godot> --path . -s tools/screenshot_chapters.gd
## Ảnh ra build/screenshots/chapters_*.png. Dữ liệu chỉ trong bộ nhớ (đã qua 1-1, đạt 2 mục tiêu); KHÔNG ghi save.

## [tên ảnh, scene, chương, nhóm chương (màn chọn chương), cuộn thêm px (map)]
const SHOTS := [
	["select_arc1", "SCENE_CHAPTERS", 1, "arc_01", 0],
	["select_arc4", "SCENE_CHAPTERS", 7, "arc_04", 0],
	["map_ch1", "SCENE_CHAPTER_MAP", 1, "", 0],
	["map_ch4", "SCENE_CHAPTER_MAP", 4, "", 2600],
]
const PERIOD := 40

var _frames := 0
var _index := 0


func _process(_delta: float) -> bool:
	_frames += 1
	var phase := _frames % PERIOD
	var gc := root.get_node("GameConfig")
	if phase == 2:
		if _index >= SHOTS.size():
			return true
		var shot: Array = SHOTS[_index]
		var save := root.get_node("SaveService")
		save.store = SaveStore.new("user://screenshot_chapters_tmp")
		save.data = SaveSchema.default_data()
		save.data["tutorial"]["done"] = true
		save.data["progress"]["stages"]["stage_01"] = {"cleared": true, "best_time_sec": 200.0, "objectives": ["time", "hits"]}
		gc.selected_chapter = int(shot[2])
		gc.selected_part = 0
		change_scene_to_file(str(gc.get(shot[1])))
	if phase == 10:
		var shot: Array = SHOTS[_index]
		var cur := current_scene
		if cur is ChapterSelectScreen and str(shot[3]) != "":
			cur.select_arc(str(shot[3]))
		if cur is ChapterMapScreen and int(shot[4]) > 0:
			cur.set_scroll(cur.scroll_x + float(shot[4]))
	if phase == PERIOD - 2:
		var out := "res://build/screenshots/chapters_%s.png" % SHOTS[_index][0]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
		root.get_texture().get_image().save_png(out)
		print("saved ", out)
		_index += 1
	return false
