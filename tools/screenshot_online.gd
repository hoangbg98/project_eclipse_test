extends SceneTree
## Chụp màn Đăng nhập (2 thẻ, báo lỗi, hỏi mang save ngoại tuyến lên) và màn Tài khoản, với máy chủ thật
## (cần cửa sổ + máy chủ chạy):  <godot> --path . -s tools/screenshot_online.gd
## Ảnh ra build/screenshots/online_<n>.png. Phiên, save ngoại tuyến, bản đệm cloud dùng thư mục riêng (user://shot_online).

const ROOT := "user://shot_online"

var _frames := 0
var _screen: Control
var _done := false
var _service: Node
var _step := 0


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_service = root.get_node("OnlineService")
		_service.session_file = ROOT.path_join("session.cfg")
		_service.cloud_root = ROOT.path_join("cloud")
		var saves: Node = root.get_node("SaveService")
		saves.offline_dir = ROOT.path_join("offline")
		SaveStore.new(saves.offline_dir).write(SaveSchema.default_data())   # máy này có save ngoại tuyến
		saves.use_store(saves.offline_store())
		_service.logout()
		_screen = (load("res://scenes/main/login_screen.tscn") as PackedScene).instantiate()
		_screen.navigate = false
		root.add_child(_screen)
	elif _frames == 10:
		_screen.field("login_name").text = "tester1"
		_screen.field("login_password").text = "sai"
		_shot("0_login")
		_run(_screen.submit)
	elif _done and _step == 1:
		_shot("1_login_error")
		_screen.set_mode(LoginScreen.Mode.REGISTER)
		_screen.field("reg_name").text = "shot_%d" % (int(Time.get_unix_time_from_system()) % 1000000)
		_screen.field("reg_email").text = _screen.field("reg_name").text + "@example.com"
		_screen.field("reg_password").text = "matkhau123"
		_screen.field("reg_confirm").text = "matkhau123"
		_step = 2
	elif _step == 2:
		_shot("2_register")
		_run(_screen.submit)
		_step = 3
	elif _done and _step == 4:
		_shot("3_import_ask")
		_run(_screen.answer_import.bind(true))
		_step = 5
	elif _done and _step == 6:
		_screen.queue_free()
		root.add_child((load("res://scenes/main/online_screen.tscn") as PackedScene).instantiate())
		_step = 7
		_frames = 1000
	elif _step == 7 and _frames > 1010:
		_shot("4_account")
		_service.logout()
		return true
	return false


func _run(c: Callable) -> void:
	_done = false
	await c.call()
	_done = true
	_step += 1


func _shot(name_: String) -> void:
	var out := "res://build/screenshots/online_%s.png" % name_
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
