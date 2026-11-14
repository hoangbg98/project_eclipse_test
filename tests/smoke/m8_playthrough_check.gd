extends SceneTree
## Kiểm tra khói M8 — chơi xuyên suốt theo checklist README 16 (headless, không cần GdUnit4):
## Title → Game mới → Hub → chọn đội → Màn 1 → đánh thật bằng input → 3 đợt quái → boss 2 pha → kết quả + thưởng
## → lưu → "thoát" (đọc lại save từ đĩa) → Tiếp tục với tiến trình còn nguyên.
## Chiêu mộ không nằm trong luồng vì chưa có banner (tỉ lệ chờ owner).
## Chạy: godot --headless --path . --script res://tests/smoke/m8_playthrough_check.gd
##
## Để giữ test ngắn và ổn định, phần lớn quái bị hạ bằng sát thương trực tiếp sau khi đã xác nhận
## đòn đánh thật từ input gây được sát thương. Cảm giác chơi và độ khó vẫn cần người chơi thử.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		_failures += 1


func _wait_for_scene(path: String, timeout_s: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while Time.get_ticks_msec() < deadline:
		var cur := current_scene
		if cur != null and cur.scene_file_path == path and not root.get_node("SceneRouter").is_busy():
			return true
		await process_frame
	return false


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
	await _frames(1)


func _kill_all(stage: Node) -> void:
	for e in stage.enemies.duplicate():
		e.combatant.resources.take_damage(1e9)
	await _frames(3)


func _run() -> void:
	var gc := root.get_node_or_null("GameConfig")
	var save := root.get_node_or_null("SaveService")
	_check(gc != null and save != null, "autoload GameConfig và SaveService tồn tại")
	if gc == null or save == null:
		quit(1)
		return
	save.delete_save()

	# --- Start → Hub ---
	change_scene_to_file(gc.SCENE_BOOT)
	_check(await _wait_for_scene(gc.SCENE_TITLE, 6.0), "Boot → Title")
	(current_scene.get_node("%NewGameButton") as Button).pressed.emit()
	_check(await _wait_for_scene(gc.SCENE_HUB, 3.0), "Game mới → Hub")
	var hub := current_scene

	# --- Chọn đội: đưa Kael lên đầu (bỏ rồi thêm lại hai người kia) ---
	hub.show_tab("BattleTab")
	var battle = hub.panel
	battle.toggle_party("char_fire_01")
	battle.toggle_party("char_fire_01")
	_check(Array(save.data["party"]) == ["char_lightning_01", "char_wind_01", "char_fire_01"], "chọn đội: thứ tự mới được lưu")
	battle.toggle_party("char_lightning_01")
	battle.toggle_party("char_wind_01")
	battle.toggle_party("char_lightning_01")
	battle.toggle_party("char_wind_01")
	_check(Array(save.data["party"]) == ["char_fire_01", "char_lightning_01", "char_wind_01"], "chọn đội: về Aether / Kael / Lyra")

	# --- Chọn màn → vào Màn 1 ---
	(hub.get_node("%Stage01Button") as Button).pressed.emit()
	_check(await _wait_for_scene(gc.SCENE_STAGE, 4.0), "Hub → Màn 1")
	var stage := current_scene
	await _frames(30)
	var p = stage.player
	_check(p != null and p.is_on_floor(), "nhân vật đứng trên sàn")
	_check(stage.party.active().id == "char_fire_01", "người trên sân là Aether")

	# --- Di chuyển, nhảy bằng input thật ---
	var x0: float = p.global_position.x
	Input.action_press("move_right")
	await _frames(40)
	Input.action_release("move_right")
	_check(p.global_position.x > x0 + 150.0, "chạy phải bằng input (%.0f px)" % (p.global_position.x - x0))
	await _tap("jump")
	await _frames(8)
	_check(not p.is_on_floor(), "nhảy bằng input")
	await _frames(60)

	# --- Đợt 1: đánh thật bằng input ---
	p.global_position = stage.map.ground_feet(17)
	await _frames(5)
	_check(stage.phase == 1 and stage.enemies_alive() == 3, "đợt 1 bắt đầu: 3 kẻ địch, sân bị khóa")
	var target = stage.enemies[0]
	var hp0: float = target.combatant.resources.hp
	p.global_position = target.global_position + Vector2(-110, 0)
	p.facing = 1
	await _frames(4)
	for i in 4:
		await _tap("attack")
		await _frames(14)
	_check(target.combatant.resources.hp < hp0, "đòn đánh từ input gây sát thương (%d)" % int(hp0 - target.combatant.resources.hp))
	# Kỹ năng: nạp đủ EN rồi bấm.
	p.combatant.resources.add_en(100.0)
	await _frames(40)
	var hp1: float = target.combatant.resources.hp
	p.global_position = target.global_position + Vector2(-110, 0)
	await _tap("skill")
	await _frames(50)
	_check(target.combatant.resources.hp < hp1 or target.is_dead(), "kỹ năng từ input gây sát thương")
	# Nhận sát thương: để quái đánh trúng (tối đa ~6 s).
	var php: float = p.combatant.resources.hp
	for i in 360:
		await physics_frame
		if stage.party.active().resources().hp < php:
			break
	_check(stage.party.active().resources().hp < php, "nhân vật nhận sát thương từ quái")
	# Chuyển người bằng input.
	stage.party.tick(1.1)
	await _tap("switch_1")
	await _frames(6)
	_check(stage.party.active().id == "char_lightning_01", "đổi sang Kael bằng input")
	await _frames(40)
	await _kill_all(stage)
	_check(stage.phase == 0 and stage.waves_cleared == 1 and not stage.is_locked(), "hạ hết đợt 1: sân mở")

	# --- Đợt 2, 3 ---
	for i in [1, 2]:
		var w: Dictionary = stage.waves()[i]
		stage.player.global_position = stage.map.ground_feet(int(w["trigger_col"]) + 1)
		await _frames(5)
		_check(stage.phase == 1, "đợt %d bắt đầu" % (i + 1))
		await _kill_all(stage)
	_check(stage.waves_cleared == 3, "đã qua cả 3 đợt")
	_check(stage.respawn_point.x > stage.map.spawn_position().x, "đã chạm checkpoint")

	# --- Boss 2 pha ---
	stage.player.global_position = stage.map.ground_feet(int(stage.boss_data()["trigger_col"]) + 1)
	await _frames(5)
	_check(stage.phase == 2 and stage.boss != null, "vào đấu trường boss")
	var boss = stage.boss
	_check(boss.phase == 1, "boss ở pha 1")
	boss.combatant.resources.take_damage(boss.combatant.resources.max_hp * 0.55)
	await _frames(4)
	_check(boss.phase == 2 and boss.is_transitioning(), "HP ≤ 50%: boss chuyển pha 2")
	await _frames(90)
	_check(not boss.is_transitioning(), "boss hết chuyển pha")
	stage.elapsed_sec = 205.0
	boss.combatant.resources.take_damage(1e9)
	await _frames(4)

	# --- Kết quả + thưởng + lưu ---
	_check(stage.phase == 3, "hạ boss: màn hoàn thành")
	var result := stage.get_node("ResultScreen")
	_check(result.visible, "màn kết quả hiện")
	var bonus := int(stage.last_summary.get("objective_rewards", {}).get("gold", 0))
	_check(stage.last_summary.get("objectives", []).size() == 3, "chấm 3 mục tiêu chiến đấu (thưởng thêm %d vàng)" % bonus)
	_check(int(save.data["currencies"]["gold"]) == 1200 + bonus and int(save.data["currencies"]["gems"]) == 300, "nhận 1200 vàng + 300 ngọc (thưởng lần đầu)")
	_check(int(save.data["characters"]["char_fire_01"]["level"]) > 1, "cả đội lên cấp")
	result._on_hub()
	_check(await _wait_for_scene(gc.SCENE_HUB, 4.0), "Về Hub từ màn kết quả")

	# --- "Thoát rồi mở lại": bỏ dữ liệu trong bộ nhớ, đọc lại từ đĩa ---
	save.data = {}
	save.load_game()
	_check(int(save.last_status) == 0, "đọc save từ đĩa: OK")
	_check(bool(save.data["progress"]["stages"]["stage_01"]["cleared"]), "tiến độ Màn 1 còn nguyên")
	_check(int(save.data["currencies"]["gold"]) == 1200 + bonus, "vàng còn nguyên")
	_check(save.data["inventory"]["equipment"].size() == 1, "trang bị thưởng còn nguyên")
	root.get_node("SceneRouter").replace(gc.SCENE_TITLE)
	_check(await _wait_for_scene(gc.SCENE_TITLE, 4.0), "về Title")
	_check(not (current_scene.get_node("%ContinueButton") as Button).disabled, "nút Tiếp tục bật")
	(current_scene.get_node("%ContinueButton") as Button).pressed.emit()
	_check(await _wait_for_scene(gc.SCENE_HUB, 3.0), "Tiếp tục → Hub")
	current_scene.show_tab("BattleTab")
	var lines: String = "\n".join(current_scene.panel.stage_lines())
	_check(lines.contains("3:25"), "Hub hiện Màn 1 đã qua với kỷ lục 3:25")

	save.delete_save()
	print("KẾT QUẢ: %d lỗi" % _failures)
	quit(1 if _failures > 0 else 0)
