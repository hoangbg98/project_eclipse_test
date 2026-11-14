extends GdUnitTestSuite
## Joystick dùng ảnh owner (2026-11-14): đế + phím trung tâm tách từ ảnh vòng HUD (tools/ui/split_joystick.py).


func test_textures_exist_and_are_transparent_outside() -> void:
	for p in [HudTheme.JOYSTICK_BASE, HudTheme.JOYSTICK_KNOB, "res://assets/ui/hud/joystick/joystick_full.png"]:
		assert_bool(ResourceLoader.exists(p)).override_failure_message(p).is_true()
	var base := (load(HudTheme.JOYSTICK_BASE) as Texture2D).get_image()
	var knob := (load(HudTheme.JOYSTICK_KNOB) as Texture2D).get_image()
	assert_int(base.get_width()).is_equal(base.get_height())
	assert_int(knob.get_width()).is_equal(knob.get_height())
	assert_float(float(knob.get_width()) / base.get_width()).is_equal_approx(HudTheme.JOYSTICK_KNOB_RATIO, 0.002)
	# Góc ảnh trong suốt hoàn toàn (không còn nền caro cũ).
	for img: Image in [base, knob]:
		var w := img.get_width() - 1
		for p: Vector2i in [Vector2i(0, 0), Vector2i(w, 0), Vector2i(0, w), Vector2i(w, w)]:
			assert_float(img.get_pixelv(p).a).is_equal(0.0)


func test_knob_follows_drag_and_stays_inside_base() -> void:
	var j: VirtualJoystick = auto_free(VirtualJoystick.new())
	j.size = Vector2(360, 360)
	add_child(j)
	assert_vector(j.knob_center()).is_equal(Vector2(180, 180))
	j._update(Vector2(360, 180))                                  # kéo hết sang phải
	var c := j.knob_center()
	assert_float(c.x).is_greater(180.0)
	var radius := 180.0
	assert_float(c.x - 180.0 + radius * HudTheme.JOYSTICK_KNOB_RATIO).is_less_equal(radius)   # phím không ra ngoài đế
	j._reset()
	assert_vector(j.knob_center()).is_equal(Vector2(180, 180))
