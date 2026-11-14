extends GdUnitTestSuite
## Animation biến thể chưa có hình thì mượn bản gốc (Kazeyumi air_2 → air_1, hold_release_2 → hold_release).


func _frames(names: Array) -> SpriteFrames:
	var f := SpriteFrames.new()
	for n in names:
		f.add_animation(StringName(n))
	return f


func test_existing_animation_is_used_as_is() -> void:
	var f := _frames(["air_1", "air_2"])
	assert_str(String(PlayerController.animation_or_fallback(f, &"air_2"))).is_equal("air_2")


func test_numbered_variant_falls_back_to_first() -> void:
	var f := _frames(["air_1"])
	assert_str(String(PlayerController.animation_or_fallback(f, &"air_2"))).is_equal("air_1")


func test_level_variant_falls_back_to_base() -> void:
	var f := _frames(["hold_release"])
	assert_str(String(PlayerController.animation_or_fallback(f, &"hold_release_2"))).is_equal("hold_release")


func test_missing_without_base_returns_empty() -> void:
	var f := _frames(["idle"])
	assert_str(String(PlayerController.animation_or_fallback(f, &"attack_1"))).is_empty()
	assert_str(String(PlayerController.animation_or_fallback(f, &"ultimate"))).is_empty()
