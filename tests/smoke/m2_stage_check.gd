extends SceneTree
## Kiểm tra khói M2-3: chạy màn thử nghiệm bằng vòng lặp thật của engine (không tự bước vật lý).
## Chạy: godot --headless --path . --script res://tests/smoke/m2_stage_check.gd

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		_failures += 1


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout


func _run() -> void:
	change_scene_to_file("res://scenes/stages/test_stage.tscn")
	await process_frame
	await process_frame
	var stage := current_scene
	_check(stage != null and stage.player != null, "màn và nhân vật được tạo")
	if stage == null or stage.player == null:
		quit(1)
		return
	var player: PlayerController = stage.player
	var camera: FollowCamera = stage.camera
	player.use_player_input = false

	await _wait(1.0)
	_check(player.is_on_floor(), "nhân vật đứng trên sàn sau 1 s")
	_check(absf(player.global_position.y - 896.0) < 2.0, "đứng đúng mặt đất y = 896 (thực tế %.1f)" % player.global_position.y)
	_check(camera.is_current(), "camera của màn là camera hiện hành")

	# Đo theo khung thiết kế 1920x1080: cửa sổ headless có hình vuông nên khung nhìn thực tế bị nới dọc.
	var half := Vector2(GameConfig.BASE_RESOLUTION) * 0.5
	var c := camera.get_screen_center_position()
	print("      viewport headless %s, tâm camera %s" % [root.get_visible_rect().size, c])
	_check(c.x - half.x >= -0.5, "camera không lộ ngoài mép trái (mép trái màn hình = %.1f)" % (c.x - half.x))
	_check(c.y + half.y <= 17 * 64 + 0.5, "camera không lộ dưới đáy bản đồ (đáy màn hình = %.1f)" % (c.y + half.y))
	_check(c.y - half.y >= -0.5, "camera không lộ trên đỉnh bản đồ (đỉnh màn hình = %.1f)" % (c.y - half.y))

	# Chạy phải 1.5 s bằng vòng lặp thật
	var x0 := player.global_position.x
	player.intent.move_x = 1.0
	await _wait(1.5)
	player.intent.move_x = 0.0
	_check(player.global_position.x - x0 > 300.0, "chạy phải được quãng đường (%.0f px)" % (player.global_position.x - x0))
	_check(player.facing == 1, "quay mặt phải")

	print("KẾT QUẢ: %d lỗi" % _failures)
	quit(1 if _failures > 0 else 0)
