extends CanvasLayer
## Dòng thông tin khi chơi thử: state, vận tốc, chạm đất, FPS và phím.
## Chỉ hiện ở bản debug (editor, build debug); F3 bật/tắt.

var player: PlayerController
## Đội (màn thử nghiệm gán); hiện người trên sân, icon dự bị, SI-CD, Liên kết cho tới khi có HUD (M4-7).
var party: PartyManager

var _label: Label


func _ready() -> void:
	layer = 90
	visible = OS.is_debug_build()
	_label = Label.new()
	_label.position = Vector2(40, 184)  # dưới nút Tạm dừng của BattleHud
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
			var st := PackedStringArray()
			for id in c.statuses.active_ids():
				var n := tr("STATUS_" + id.to_upper())
				if c.statuses.stacks(id) > 1:
					n += " ×%d" % c.statuses.stacks(id)
				st.append("%s %.1fs" % [n, c.statuses.remaining(id)])
			if not st.is_empty():
				lines.append(" · ".join(st))
			if player.runner and player.runner.is_running():
				lines.append("%s  %d ms" % [player.runner.current.id, int(player.runner.elapsed_ms)])
	if party and is_instance_valid(party) and party.links:
		lines.append(_party_line())
	_label.text = "\n".join(lines)


## "[Aether] Q: Kael SI 3.2s · E: Lyra ✦ LIÊN KẾT 4.1s" — trạng thái icon dự bị.
func _party_line() -> String:
	var parts := PackedStringArray(["[%s]" % tr(party.active().def().name_key)])
	var keys := ["Q", "E"]
	var r := party.reserves()
	for i in r.size():
		var m := r[i]
		var s := "%s: %s" % [keys[i] if i < keys.size() else "?", tr(m.def().name_key)]
		if m.is_down():
			s += " " + tr("DEBUG_PARTY_DOWN")
		elif party.links.is_glowing(m):
			s += " ✦ %s %.1fs" % [tr("DEBUG_PARTY_LINK"), party.links.window_left(m)]
		elif not party.links.si_cd_ready(m):
			s += " SI %.1fs" % party.links.si_cd_left(m)
		parts.append(s)
	if party.switch_cooldown_left() > 0.0:
		parts.append("%.1fs" % party.switch_cooldown_left())
	return "  ·  ".join(parts)


func _cd(c: Combatant, key: StringName) -> String:
	if not c.cooldowns.has(key):
		return "-"
	return "OK" if c.cooldowns.is_ready(key) else "%.1fs" % c.cooldowns.remaining(key)
