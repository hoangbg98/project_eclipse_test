extends SceneTree
## Chụp chế độ nhịp điệu (M10) với máy chủ thật (cổng vào server/gateway.mjs đang chạy, đã build_catalog):
##   <godot> --path . -s tools/screenshot_rhythm.gd
## Bước: màn Ải nguyên liệu (tải danh mục) → tải bài ải N-1 thật qua /music/ → màn chơi tự chơi (đồng hồ tay) →
## kết quả → ải boss → danh sách Vô tận. Dùng hồ sơ thử riêng, không ghi save. Ảnh ra build/screenshots/rhythm_<n>.png.

var _frames := 0
var _step := 0
var _busy := false
var _screen: Node
var _profile: PlayerProfile


func _process(_delta: float) -> bool:
	_frames += 1
	if _busy:
		return false
	match _step:
		0:
			if _frames < 3:
				return false
			_profile = PlayerProfile.new(SaveSchema.default_data())
			_screen = _open("res://scenes/main/rhythm_material_screen.tscn")
			_step = 1
			_frames = 0
		1:
			if _screen.catalog_state == "loading" or _frames < 5:
				return false
			print("danh mục: ", _screen.catalog_state, " ", _screen.library.songs().size(), " bài")
			_shot("0_material")
			_run(_screen.start_stage.bind("rhythm_mat_01"), 2)
		2:
			print("mở: ", _screen.last_target, " | ", _screen.notice)
			_screen.queue_free()
			_screen = _stage()
			_step = 3
			_frames = 0
		3:
			if _frames < 3:
				return false
			_screen.advance(3.6)   # hướng dẫn bước 1: Dơi Nốt đang bay tới
			_step = 30
			_frames = 0
		30:
			if _frames < 2:
				return false
			_shot("1t_tutorial")
			_screen.advance(13.0)   # sang bước "cả hai"
			_step = 31
			_frames = 0
		31:
			if _frames < 2:
				return false
			_shot("1u_tutorial_both")
			_screen.skip_tutorial()
			_screen.advance(22.05)   # 0.3 s trước nốt 20.346: hitbox còn nhấp nháy
			_step = 4
			_frames = 0
		4:
			if _frames < 2:
				return false
			_shot("1_stage")
			_screen.advance(0.285)   # 15 ms trước nhịp: hitbox gần khít vòng chấm
			_step = 40
			_frames = 0
		40:
			if _frames < 2:
				return false
			_shot("1b_stage")
			_screen.advance(200.0)
			_step = 5
			_frames = 0
		5:
			if _frames < 2:
				return false
			print("kết quả: ", _screen.result)
			_shot("2_result")
			_screen.queue_free()
			_screen = _open("res://scenes/main/rhythm_material_screen.tscn")
			_step = 6
			_frames = 0
		6:
			if _screen.catalog_state == "loading" or _frames < 5:
				return false
			_run(_screen.start_stage.bind("rhythm_mat_02"), 60)
		60:
			print("mở N-2: ", _screen.last_target, " | ", _screen.notice, " | đã qua N-1: ", RhythmProgress.new(_profile).is_cleared("rhythm_mat_01"))
			_screen.queue_free()
			_screen = _stage()
			_screen.autoplay = true
			_step = 61
			_frames = 0
		61:
			if _frames < 3:
				return false
			_screen.advance(1.2)   # đếm ngược có dòng giới thiệu Rắn Ngân
			_step = 62
			_frames = 0
		62:
			if _frames < 2:
				return false
			_shot("6_intro")
			_screen.advance(5.0 - 1.2 + 38.4)   # 0.6 s trước Rắn Ngân đầu tiên (giây 39.04)
			_step = 63
			_frames = 0
		63:
			if _frames < 2:
				return false
			_shot("7_serpent")
			_screen.advance(0.85)   # đang giữ: đầu rắn cắn ở vòng chấm
			_step = 64
			_frames = 0
		64:
			if _frames < 2:
				return false
			_shot("7b_serpent_hold")
			_screen.queue_free()
			_screen = _open("res://scenes/main/rhythm_material_screen.tscn")
			_step = 65
			_frames = 0
		65:
			if _screen.catalog_state == "loading" or _frames < 5:
				return false
			var prog := RhythmProgress.new(_profile)
			for i in range(2, 5):
				prog.finish("rhythm_mat_0%d" % i, {"cleared": true, "score": 1, "rank": "B"})
			_screen.refresh()
			_shot("3_material_progress")
			_run(_screen.start_stage.bind("rhythm_mat_05"), 7)
		7:
			_screen.queue_free()
			_screen = _stage()
			_step = 8
			_frames = 0
		8:
			if _frames < 3:
				return false
			_screen.advance(34.1)
			_step = 9
			_frames = 0
		9:
			if _frames < 2:
				return false
			_shot("4_boss")
			_screen.queue_free()
			var prog := RhythmProgress.new(_profile)
			prog.finish("rhythm_mat_05", {"cleared": true, "score": 1, "rank": "A"})
			prog.finish(RhythmProgress.endless_key("song_gale_runner", "normal"), {"cleared": true, "score": 81234, "rank": "S"})
			prog.toggle_favorite("song_gale_runner")
			_screen = _open("res://scenes/main/rhythm_song_list_screen.tscn")
			_step = 10
			_frames = 0
		10:
			if _screen.catalog_state == "loading" or _frames < 5:
				return false
			_shot("5_endless")
			return true
	return false


func _open(path: String) -> Node:
	var s := (load(path) as PackedScene).instantiate()
	s.profile = _profile
	s.save_enabled = false
	s.navigate_enabled = false
	root.add_child(s)
	return s


func _stage() -> RhythmStage:
	var s := (load("res://scenes/main/rhythm_stage.tscn") as PackedScene).instantiate() as RhythmStage
	s.profile = _profile
	s.save_enabled = false
	s.manual_clock = true
	s.autoplay = true
	root.add_child(s)
	print("màn chơi: ", s.song_title, " lỗi=", s.load_error, " nốt=", s.chart.notes.size(), " nhạc=", s.player.stream)
	return s


func _run(c: Callable, next: int) -> void:
	_busy = true
	await c.call()
	_busy = false
	_step = next


func _shot(name_: String) -> void:
	var out := "res://build/screenshots/rhythm_%s.png" % name_
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
