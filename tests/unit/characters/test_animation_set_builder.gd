extends GdUnitTestSuite
## Unit test cho AnimationSetBuilder (M2-1) và 6 frames_manifest.json thật.

const Builder := preload("res://scripts/characters/animation_set_builder.gd")

## README 17.4: số đòn thường / đòn trên không của từng nhân vật.
const COMBOS := {
	"char_fire_01": [4, 2],       # Aether
	"char_wind_01": [3, 1],       # Lyra
	"char_lightning_01": [5, 3],  # Kael
	"char_light_01": [3, 1],      # Seraphine
	"char_dark_01": [4, 2],       # Noctis
	"char_earth_01": [3, 1],      # Terra
}
const BASIC := ["idle", "run", "jump_up", "fall", "land", "dodge", "hold_charge", "hold_release",
		"landing_attack", "skill_1", "skill_2", "ultimate", "switch_in", "switch_out",
		"hurt", "knockback", "down"]

const TMP_DIR := "user://test_anim_builder"
const TMP_ID := "char_test_01"


func after_test() -> void:
	_remove_dir(TMP_DIR)


# ---------- Manifest thật trong assets/characters ----------

func test_all_six_characters_have_manifest() -> void:
	for id: String in COMBOS:
		var errors := PackedStringArray()
		var m := Builder.load_manifest(Builder.CHARACTERS_DIR.path_join(id), errors)
		assert_array(errors).override_failure_message("%s: %s" % [id, errors]).is_empty()
		assert_str(str(m.get("character_id"))).is_equal(id)


func test_manifest_animation_sets_match_readme() -> void:
	for id: String in COMBOS:
		var m := Builder.load_manifest(Builder.CHARACTERS_DIR.path_join(id))
		var names: Array = m["animations"].keys()
		var expected: Array = BASIC.duplicate()
		for i in COMBOS[id][0]:
			expected.append("attack_%d" % (i + 1))
		for i in COMBOS[id][1]:
			expected.append("air_%d" % (i + 1))
		for n in expected:
			assert_bool(n in names).override_failure_message("%s thiếu animation %s" % [id, n]).is_true()


func test_real_frame_counts_match_folders() -> void:
	# README 17.4 bước 3: số PNG trong mỗi thư mục phải bằng `frames`.
	for id: String in COMBOS:
		var errors := Builder.validate_frame_counts(Builder.CHARACTERS_DIR.path_join(id))
		assert_array(errors).override_failure_message("%s: %s" % [id, errors]).is_empty()


func test_build_real_character_uses_manifest_values() -> void:
	var result := Builder.build_for_character("char_fire_01")
	assert_array(result.errors).is_empty()
	var anims: Dictionary = result.manifest["animations"]
	assert_int(result.sprite_frames.get_animation_names().size()).is_equal(anims.size())
	assert_bool(result.sprite_frames.has_animation(&"default")).is_false()
	for n: String in anims:
		var a := StringName(n)
		assert_bool(result.sprite_frames.has_animation(a)).is_true()
		assert_float(result.sprite_frames.get_animation_speed(a)).is_equal(float(anims[n]["fps"]))
		assert_bool(result.sprite_frames.get_animation_loop(a)).is_equal(bool(anims[n]["loop"]))


func test_undelivered_animations_use_placeholder() -> void:
	var result := Builder.build_for_character("char_fire_01")
	var placeholder: Texture2D = load(Builder.PLACEHOLDER_PATH)
	assert_object(placeholder).is_not_null()
	# Enkiba: idle, run, jump_up, fall, attack_1, attack_2 và attack_3 đã được owner duyệt; các animation còn lại dùng placeholder.
	var delivered := 0
	for n: String in result.manifest["animations"]:
		if int(result.manifest["animations"][n]["frames"]) > 0:
			delivered += 1
	assert_int(delivered).is_equal(7)
	assert_int(result.placeholder_animations.size()).is_equal(result.manifest["animations"].size() - 7)
	assert_bool(result.placeholder_animations.has("idle")).is_false()
	assert_bool(result.placeholder_animations.has("run")).is_false()
	assert_bool(result.placeholder_animations.has("jump_up")).is_false()
	assert_bool(result.placeholder_animations.has("fall")).is_false()
	assert_bool(result.placeholder_animations.has("attack_1")).is_false()
	assert_bool(result.placeholder_animations.has("attack_2")).is_false()
	assert_bool(result.placeholder_animations.has("attack_3")).is_false()
	assert_int(result.sprite_frames.get_frame_count(&"idle")).is_equal(6)
	assert_int(result.sprite_frames.get_frame_count(&"run")).is_equal(8)
	assert_int(result.sprite_frames.get_frame_count(&"jump_up")).is_equal(3)
	assert_int(result.sprite_frames.get_frame_count(&"fall")).is_equal(3)
	assert_int(result.sprite_frames.get_frame_count(&"attack_1")).is_equal(6)
	assert_int(result.sprite_frames.get_frame_count(&"attack_2")).is_equal(6)
	assert_int(result.sprite_frames.get_frame_count(&"attack_3")).is_equal(6)
	assert_object(result.sprite_frames.get_frame_texture(&"run", 0)).is_not_same(placeholder)


func test_sprite_offset_puts_feet_at_origin() -> void:
	var result := Builder.build_for_character("char_fire_01")
	# canvas 384, pivot (192, 336): tâm ảnh (192,192) phải dịch lên 144 px.
	assert_vector(result.sprite_offset).is_equal(Vector2(0, -144))


# ---------- Dữ liệu giả trong user:// ----------

func test_delivered_frames_are_loaded_in_order() -> void:
	_make_char({"idle": {"frames": 3, "fps": 8, "loop": true}, "run": {"frames": 0, "fps": 12, "loop": true}})
	_write_frames("idle", [0, 1, 2])
	var result := Builder.build_from_dir(TMP_DIR)
	assert_array(result.errors).is_empty()
	assert_int(result.sprite_frames.get_frame_count(&"idle")).is_equal(3)
	assert_float(result.sprite_frames.get_animation_speed(&"idle")).is_equal(8.0)
	# Frame thứ i có chiều rộng i+1 (đánh dấu khi ghi) để kiểm tra thứ tự.
	for i in 3:
		assert_int(result.sprite_frames.get_frame_texture(&"idle", i).get_width()).is_equal(i + 1)
	assert_array(Array(result.placeholder_animations)).contains_exactly(["run"])
	assert_array(Builder.validate_frame_counts(TMP_DIR)).is_empty()


func test_missing_frame_falls_back_to_placeholder_and_reports() -> void:
	_make_char({"idle": {"frames": 4, "fps": 12, "loop": true}})
	_write_frames("idle", [0, 1, 2])
	var result := Builder.build_from_dir(TMP_DIR)
	assert_bool(result.is_ok()).is_false()
	assert_str(result.errors[0]).contains("thiếu frame")
	assert_int(result.sprite_frames.get_frame_count(&"idle")).is_equal(1)
	assert_array(Array(result.placeholder_animations)).contains_exactly(["idle"])
	var errors := Builder.validate_frame_counts(TMP_DIR)
	assert_str(errors[0]).contains("manifest ghi 4 frame, thư mục có 3 PNG")


func test_gap_in_numbering_is_reported() -> void:
	_make_char({"idle": {"frames": 3, "fps": 12, "loop": true}})
	_write_frames("idle", [0, 1, 3])
	var errors := Builder.validate_frame_counts(TMP_DIR)
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0]).contains("%s_idle_002.png" % TMP_ID)


func test_missing_animation_folder_is_reported() -> void:
	_make_char({"idle": {"frames": 0, "fps": 12, "loop": true}}, false)
	assert_str(Builder.validate_frame_counts(TMP_DIR)[0]).contains("không có thư mục")


func test_missing_manifest_does_not_crash() -> void:
	var result := Builder.build_from_dir("user://khong_ton_tai")
	assert_bool(result.is_ok()).is_false()
	assert_int(result.sprite_frames.get_animation_names().size()).is_equal(0)


func test_invalid_values_are_reported() -> void:
	_make_char({"idle": {"frames": -1, "fps": 0, "loop": true}})
	var errors := PackedStringArray()
	Builder.load_manifest(TMP_DIR, errors)
	assert_int(errors.size()).is_equal(2)


func test_broken_json_is_reported() -> void:
	DirAccess.make_dir_recursive_absolute(TMP_DIR)
	var f := FileAccess.open(TMP_DIR.path_join(Builder.MANIFEST_NAME), FileAccess.WRITE)
	f.store_string("{ không phải json")
	f.close()
	var errors := PackedStringArray()
	assert_dict(Builder.load_manifest(TMP_DIR, errors)).is_empty()
	assert_int(errors.size()).is_equal(1)


# ---------- Hỗ trợ ----------

func _make_char(animations: Dictionary, make_folders := true) -> void:
	DirAccess.make_dir_recursive_absolute(TMP_DIR)
	var manifest := {
		"character_id": TMP_ID,
		"canvas": {"width": 384, "height": 384, "pivot_x": 192, "baseline_y": 336},
		"animations": animations,
	}
	var f := FileAccess.open(TMP_DIR.path_join(Builder.MANIFEST_NAME), FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest))
	f.close()
	if make_folders:
		for n: String in animations:
			DirAccess.make_dir_recursive_absolute(TMP_DIR.path_join("frames").path_join(n))


func _write_frames(anim: String, indices: Array) -> void:
	for i: int in indices:
		var img := Image.create_empty(i + 1, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		img.save_png(Builder.frame_path(TMP_DIR, TMP_ID, anim, i))


func _remove_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for d in DirAccess.get_directories_at(path):
		_remove_dir(path.path_join(d))
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)
