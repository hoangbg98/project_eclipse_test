extends SceneTree
## Chụp màn Đăng nhập (2 thẻ, báo lỗi) và màn Tài khoản khi đã đăng nhập máy chủ thật (cần cửa sổ + máy chủ chạy):
##   <godot> --path . -s tools/screenshot_online.gd
## Ảnh ra build/screenshots/online_<n>.png. Phiên lưu riêng (không đụng phiên thật của người chơi).

var _frames := 0
var _screen: Control
var _done := false
var _service: Node


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_service = root.get_node("OnlineService")
		_service.session_file = "user://screenshot_online_session.cfg"
		_service.logout()
		_screen = (load("res://scenes/main/login_screen.tscn") as PackedScene).instantiate()
		_screen.navigate = false
		root.add_child(_screen)
	elif _frames == 10:
		_screen.field("login_name").text = "tester1"
		_screen.field("login_password").text = "sai"
		_shot("0_login")
		_submit_wrong()
	elif _frames == 40 and _done:
		_shot("1_login_error")
		_screen.set_mode(LoginScreen.Mode.REGISTER)
		_screen.field("reg_name").text = "nguoi_choi_moi"
		_screen.field("reg_email").text = "moi@example.com"
		_screen.field("reg_password").text = "matkhau123"
		_screen.field("reg_confirm").text = "matkhau123"
	elif _frames == 50:
		_shot("2_register")
		_screen.queue_free()
		_done = false
		_login_ok()
	elif _frames > 60 and _done:
		_shot("3_account")
		_service.logout()
		return true
	elif _frames == 40 or _frames == 50:
		pass
	return false


func _submit_wrong() -> void:
	await _screen.submit()
	_done = true


func _login_ok() -> void:
	await _service.login_account("tester1", "matkhau123", false)
	root.add_child((load("res://scenes/main/online_screen.tscn") as PackedScene).instantiate())
	_done = true


func _shot(name_: String) -> void:
	var out := "res://build/screenshots/online_%s.png" % name_
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
