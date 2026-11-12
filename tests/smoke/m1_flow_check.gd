extends SceneTree
## Kiểm tra khói M1 (headless, không cần GdUnit4):
## Boot -> Title -> Hub, rồi Back về Title. Thoát mã 0 nếu đạt, 1 nếu hỏng.
## Chạy: godot --headless --path . --script res://tests/smoke/m1_flow_check.gd

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		_failures += 1


func _wait_for_scene(path: String, timeout_s: float) -> bool:
	# Dùng thời gian thật: headless chạy nhanh hơn 60 fps nên không đếm frame.
	var deadline := Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while Time.get_ticks_msec() < deadline:
		var cur := current_scene
		var router := root.get_node("SceneRouter")
		if cur != null and cur.scene_file_path == path and not router.is_busy():
			return true
		await process_frame
	return false


func _run() -> void:
	var gc := root.get_node_or_null("GameConfig")
	var router := root.get_node_or_null("SceneRouter")
	_check(gc != null, "autoload GameConfig tồn tại")
	_check(root.get_node_or_null("EventBus") != null, "autoload EventBus tồn tại")
	_check(router != null, "autoload SceneRouter tồn tại")
	if gc == null or router == null:
		quit(1)
		return

	# M5-1: bắt đầu từ trạng thái chưa có save (headless dùng thư mục save riêng, không đụng save thật).
	var save := root.get_node_or_null("SaveService")
	_check(save != null, "autoload SaveService tồn tại")
	if save:
		save.delete_save()

	change_scene_to_file(gc.SCENE_BOOT)
	_check(await _wait_for_scene(gc.SCENE_BOOT, 2.0), "vào Boot")
	_check(await _wait_for_scene(gc.SCENE_TITLE, 5.0), "Boot tự chuyển sang Title")

	var new_game: Button = current_scene.get_node("%NewGameButton")
	var cont: Button = current_scene.get_node("%ContinueButton")
	_check(cont.disabled, "nút Tiếp tục bị khóa (chưa có save)")
	new_game.pressed.emit()
	_check(await _wait_for_scene(gc.SCENE_HUB, 3.0), "Game mới -> Hub")
	_check(router.can_go_back(), "có lịch sử để Back")

	# Hub: nút Màn thử nghiệm chỉ hiện ở tab Battle (M2-3), bấm vào được màn.
	var stage_btn: Button = current_scene.get_node("%TestStageButton")
	_check(not stage_btn.visible, "tab Home: nút Màn thử nghiệm ẩn")
	(current_scene.get_node("TopBar/TabBar/BattleTab") as Button).pressed.emit()
	_check(stage_btn.visible, "tab Battle: nút Màn thử nghiệm hiện")
	(current_scene.get_node("TopBar/TabBar/HomeTab") as Button).pressed.emit()
	_check(not stage_btn.visible, "về tab Home: nút ẩn lại")
	(current_scene.get_node("TopBar/TabBar/BattleTab") as Button).pressed.emit()
	stage_btn.pressed.emit()
	_check(await _wait_for_scene(gc.SCENE_TEST_STAGE, 3.0), "Battle -> Màn thử nghiệm")
	_send_back()
	_check(await _wait_for_scene(gc.SCENE_HUB, 3.0), "Esc ở màn thử nghiệm -> Hub")

	_send_back()
	_check(await _wait_for_scene(gc.SCENE_TITLE, 3.0), "Esc ở Hub -> Title")
	_check(not router.can_go_back(), "ở Title không còn lịch sử")
	if save:
		_check(save.has_save(), "Game mới đã tạo save")
		_check(not (current_scene.get_node("%ContinueButton") as Button).disabled, "có save: nút Tiếp tục bật")
		(current_scene.get_node("%ContinueButton") as Button).pressed.emit()
		_check(await _wait_for_scene(gc.SCENE_HUB, 3.0), "Tiếp tục -> Hub")
		save.delete_save()

	print("KẾT QUẢ: %d lỗi" % _failures)
	quit(1 if _failures > 0 else 0)


## Mô phỏng phím Esc qua action ui_back.
func _send_back() -> void:
	var esc := InputEventAction.new()
	esc.action = "ui_back"
	esc.pressed = true
	Input.parse_input_event(esc)
