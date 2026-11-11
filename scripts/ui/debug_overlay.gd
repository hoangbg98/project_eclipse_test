extends CanvasLayer
## Dòng thông tin khi chơi thử: state, vận tốc, chạm đất, FPS và phím.
## Chỉ hiện ở bản debug (editor, build debug); F3 bật/tắt.

var player: PlayerController

var _label: Label


func _ready() -> void:
	layer = 90
	visible = OS.is_debug_build()
	_label = Label.new()
	_label.position = Vector2(24, 16)
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 8)
	add_child(_label)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		visible = not visible


func _process(_delta: float) -> void:
	if not visible:
		return
	var lines := PackedStringArray([tr("STAGE_HINT")])
	if player and is_instance_valid(player):
		lines.append("%s  vx %4d  vy %5d  %s  %d fps" % [
			player.current_state(), int(player.velocity.x), int(player.velocity.y),
			"floor" if player.is_on_floor() else "air", Engine.get_frames_per_second()])
		var c := player.combatant
		if c and c.resources:
			var r := c.resources
			lines.append(tr("DEBUG_COMBAT") % [int(r.hp), int(r.max_hp), int(r.en), int(r.ug), r.dodge_charges,
					_cd(c, &"skill"), _cd(c, &"weapon")])
			if player.runner and player.runner.is_running():
				lines.append("%s  %d ms" % [player.runner.current.id, int(player.runner.elapsed_ms)])
	_label.text = "\n".join(lines)


func _cd(c: Combatant, key: StringName) -> String:
	if not c.cooldowns.has(key):
		return "-"
	return "OK" if c.cooldowns.is_ready(key) else "%.1fs" % c.cooldowns.remaining(key)
