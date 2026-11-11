extends Node
## Chuyển scene có hiệu ứng mờ, giữ lịch sử để nút Back / Esc / phím Back Android hoạt động.
## Không biết nội dung scene (xem docs/ARCHITECTURE.md mục 3).

var _history: Array[String] = []
var _busy := false
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_back"):
		get_viewport().set_input_as_handled()
		EventBus.back_requested.emit()
		go_back()


func _notification(what: int) -> void:
	# Phím Back của Android (quit_on_go_back đã tắt trong project.godot).
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		EventBus.back_requested.emit()
		go_back()


## Vào scene mới và nhớ scene hiện tại để Back quay lại.
func push(scene_path: String) -> void:
	var current := get_tree().current_scene
	if current != null and not current.scene_file_path.is_empty():
		_history.append(current.scene_file_path)
	await _transition(scene_path)


## Thay scene hiện tại, xóa lịch sử (dùng cho Boot -> Title).
func replace(scene_path: String) -> void:
	_history.clear()
	await _transition(scene_path)


## Quay lại scene trước. Trả về false nếu không còn gì để quay lại.
func go_back() -> bool:
	if _history.is_empty() or _busy:
		return false
	var target: String = _history.pop_back()
	await _transition(target)
	return true


func is_busy() -> bool:
	return _busy


func can_go_back() -> bool:
	return not _history.is_empty()


func _transition(scene_path: String) -> void:
	if _busy:
		return
	if not ResourceLoader.exists(scene_path):
		push_error("SceneRouter: không tìm thấy scene %s" % scene_path)
		return
	_busy = true
	var half := GameConfig.TRANSITION_TIME * 0.5
	await _fade_to(1.0, half)
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneRouter: change_scene_to_file lỗi %d cho %s" % [err, scene_path])
	else:
		# change_scene_to_file chạy ở cuối frame; chờ scene mới vào cây.
		await get_tree().process_frame
		await get_tree().process_frame
		EventBus.scene_changed.emit(scene_path)
	await _fade_to(0.0, half)
	_busy = false


func _fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", alpha, duration)
	await tween.finished
