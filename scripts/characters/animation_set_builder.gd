class_name AnimationSetBuilder
extends RefCounted
## Dựng SpriteFrames của một nhân vật từ frames_manifest.json (README 2.2, 17.4).
##
## - Số frame, fps, loop lấy từ manifest; không viết cứng trong code.
## - Animation có `frames: 0` (chưa giao hình) dùng ảnh placeholder để game vẫn chạy.
## - Thiếu file hoặc manifest sai: ghi vào `errors`, dùng placeholder cho animation đó, không crash.
##
## Dùng:
##   var result := AnimationSetBuilder.build_for_character("char_fire_01")
##   $AnimatedSprite2D.sprite_frames = result.sprite_frames
##   $AnimatedSprite2D.offset = result.sprite_offset

const CHARACTERS_DIR := "res://assets/characters"
const PLACEHOLDER_PATH := "res://assets/placeholders/placeholder_character_384.png"
const MANIFEST_NAME := "frames_manifest.json"
const DEFAULT_FPS := 12.0


class Result:
	extends RefCounted
	var character_id := ""
	var sprite_frames: SpriteFrames
	## Dịch chuyển cho AnimatedSprite2D (centered = true) để pivot nằm ở gốc node.
	var sprite_offset := Vector2.ZERO
	## Animation đang dùng placeholder (chưa giao hình hoặc lỗi).
	var placeholder_animations := PackedStringArray()
	var errors := PackedStringArray()
	var manifest: Dictionary = {}

	func is_ok() -> bool:
		return errors.is_empty()


## Dựng cho một nhân vật theo Data ID, đọc từ assets/characters/{id}/.
static func build_for_character(character_id: String, placeholder: Texture2D = null) -> Result:
	return build_from_dir(CHARACTERS_DIR.path_join(character_id), placeholder)


## Dựng từ một thư mục nhân vật bất kỳ (res:// hoặc user://; test dùng user://).
static func build_from_dir(dir: String, placeholder: Texture2D = null) -> Result:
	var result := Result.new()
	result.sprite_frames = SpriteFrames.new()
	# SpriteFrames mới luôn có animation "default"; bỏ đi để chỉ còn animation của manifest.
	if result.sprite_frames.has_animation(&"default"):
		result.sprite_frames.remove_animation(&"default")

	var manifest := load_manifest(dir, result.errors)
	result.manifest = manifest
	if manifest.is_empty():
		return result

	result.character_id = str(manifest.get("character_id", dir.get_file()))
	result.sprite_offset = sprite_offset(manifest)
	if placeholder == null:
		placeholder = _default_placeholder()

	var animations: Dictionary = manifest.get("animations", {})
	for anim_name: String in animations:
		var spec: Dictionary = animations[anim_name]
		var anim := StringName(anim_name)
		result.sprite_frames.add_animation(anim)
		result.sprite_frames.set_animation_speed(anim, float(spec.get("fps", DEFAULT_FPS)))
		result.sprite_frames.set_animation_loop(anim, bool(spec.get("loop", false)))

		var count := int(spec.get("frames", 0))
		var added := 0
		for i in count:
			var path := frame_path(dir, result.character_id, anim_name, i)
			var tex := _load_texture(path)
			if tex == null:
				result.errors.append("%s: thiếu frame %s" % [anim_name, path])
				break
			result.sprite_frames.add_frame(anim, tex)
			added += 1

		if added < count:
			# Bộ hình dở dang: bỏ hết, dùng placeholder để không hiện animation lệch.
			result.sprite_frames.clear(anim)
		if added < count or count == 0:
			if placeholder != null:
				result.sprite_frames.add_frame(anim, placeholder)
			result.placeholder_animations.append(anim_name)
	return result


## Đọc và kiểm tra manifest. Trả về {} nếu không dùng được (lỗi ghi vào errors).
static func load_manifest(dir: String, errors: PackedStringArray = PackedStringArray()) -> Dictionary:
	var path := dir.path_join(MANIFEST_NAME)
	if not FileAccess.file_exists(path):
		errors.append("không có manifest: %s" % path)
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		errors.append("manifest không phải JSON object: %s" % path)
		return {}
	var manifest: Dictionary = data
	if typeof(manifest.get("animations")) != TYPE_DICTIONARY:
		errors.append("manifest thiếu 'animations': %s" % path)
		return {}
	for anim_name: String in manifest["animations"]:
		var spec: Variant = manifest["animations"][anim_name]
		if typeof(spec) != TYPE_DICTIONARY:
			errors.append("%s: mục animation không phải object" % anim_name)
			continue
		var frames: Variant = spec.get("frames", 0)
		if typeof(frames) not in [TYPE_INT, TYPE_FLOAT] or int(frames) < 0:
			errors.append("%s: 'frames' phải là số >= 0" % anim_name)
		var fps: Variant = spec.get("fps", DEFAULT_FPS)
		if typeof(fps) not in [TYPE_INT, TYPE_FLOAT] or float(fps) <= 0.0:
			errors.append("%s: 'fps' phải > 0" % anim_name)
	return manifest


## Kiểm tra số PNG trong từng thư mục animation khớp `frames` (README 17.4 bước 3).
## Chỉ dùng khi phát triển/test: bản export không còn file .png gốc.
static func validate_frame_counts(dir: String) -> PackedStringArray:
	var errors := PackedStringArray()
	var manifest := load_manifest(dir, errors)
	if manifest.is_empty():
		return errors
	var id := str(manifest.get("character_id", dir.get_file()))
	for anim_name: String in manifest["animations"]:
		var expected := int(manifest["animations"][anim_name].get("frames", 0))
		var anim_dir := dir.path_join("frames").path_join(anim_name)
		if not DirAccess.dir_exists_absolute(anim_dir):
			errors.append("%s: không có thư mục %s" % [anim_name, anim_dir])
			continue
		var pngs := PackedStringArray()
		for f in DirAccess.get_files_at(anim_dir):
			if f.get_extension().to_lower() == "png":
				pngs.append(f)
		if pngs.size() != expected:
			errors.append("%s: manifest ghi %d frame, thư mục có %d PNG" % [anim_name, expected, pngs.size()])
			continue
		for i in expected:
			var name := frame_path(dir, id, anim_name, i).get_file()
			if name not in pngs:
				errors.append("%s: thiếu file %s (đánh số phải liền từ 000)" % [anim_name, name])
	return errors


## Đường dẫn frame theo quy ước `{id}_{animation}_{NNN}.png`.
static func frame_path(dir: String, character_id: String, anim_name: String, index: int) -> String:
	return dir.path_join("frames").path_join(anim_name).path_join(
			"%s_%s_%03d.png" % [character_id, anim_name, index])


## Offset để pivot (chân giữa) của canvas nằm đúng gốc node khi AnimatedSprite2D.centered = true.
static func sprite_offset(manifest: Dictionary) -> Vector2:
	var canvas: Dictionary = manifest.get("canvas", {})
	var w := float(canvas.get("width", 384))
	var h := float(canvas.get("height", 384))
	var px := float(canvas.get("pivot_x", w * 0.5))
	var py := float(canvas.get("baseline_y", h))
	return Vector2(w * 0.5 - px, h * 0.5 - py)


static func _default_placeholder() -> Texture2D:
	if ResourceLoader.exists(PLACEHOLDER_PATH):
		return load(PLACEHOLDER_PATH)
	return _load_texture(PLACEHOLDER_PATH)


## res:// đã import: dùng ResourceLoader. Đường dẫn khác (user://, file chưa import): đọc PNG trực tiếp.
static func _load_texture(path: String) -> Texture2D:
	if path.begins_with("res://") and ResourceLoader.exists(path):
		return load(path) as Texture2D
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null
