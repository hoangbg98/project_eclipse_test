class_name CharacterArt
extends RefCounted
## Ảnh nhân vật dùng ở UI: chân dung chibi, splash (thiếu thì chân dung), animation idle (chỉ nạp frame idle,
## nhớ lại theo id). Thiếu ảnh trả null để màn tự vẽ placeholder.

const PORTRAIT_PATH := "res://assets/characters/%s/portrait/%s_portrait_full.png"
const SPLASH_PATH := "res://assets/characters/%s/splash/%s_splash_overview.png"
const CHARACTER_DATA := "res://data/characters/%s.tres"

static var _idle_cache := {}


static func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D if path != "" and ResourceLoader.exists(path) else null


static func def_of(id: String) -> CharacterDef:
	var p := CHARACTER_DATA % id
	return load(p) as CharacterDef if ResourceLoader.exists(p) else null


static func portrait(id: String) -> Texture2D:
	return _tex(PORTRAIT_PATH % [id, id]) if id != "" else null


## Splash toàn thân; chưa có thì chân dung chibi, rồi frame idle đầu tiên.
static func splash(id: String) -> Texture2D:
	var t := _tex(SPLASH_PATH % [id, id]) if id != "" else null
	return t if t else figure(id)


## Ảnh nhỏ cho thẻ: chân dung chibi; chưa có thì frame idle đầu tiên; không có gì thì null.
static func figure(id: String) -> Texture2D:
	var t := portrait(id)
	if t:
		return t
	var i := idle(id)
	return (i["frames"] as SpriteFrames).get_frame_texture(&"idle", 0) if not i.is_empty() else null


## Cắt phần trên của ảnh cao (splash toàn thân) theo tỉ lệ rộng / cao `aspect` để thẻ thấy mặt.
static func top_crop(tex: Texture2D, aspect: float) -> Texture2D:
	if tex == null or aspect <= 0.0:
		return tex
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	if w / h >= aspect:
		return tex
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = Rect2(0, 0, w, w / aspect)
	return a


## Animation idle: {"frames": SpriteFrames (animation "idle"), "offset": Vector2} hoặc {} nếu chưa có frame idle.
static func idle(id: String) -> Dictionary:
	if _idle_cache.has(id):
		return _idle_cache[id]
	var out := {}
	var dir := AnimationSetBuilder.CHARACTERS_DIR.path_join(id)
	var manifest := AnimationSetBuilder.load_manifest(dir)
	var spec: Dictionary = manifest.get("animations", {}).get("idle", {})
	var count := int(spec.get("frames", 0))
	if count > 0:
		var sf := SpriteFrames.new()
		sf.add_animation(&"idle")
		sf.set_animation_speed(&"idle", float(spec.get("fps", AnimationSetBuilder.DEFAULT_FPS)))
		sf.set_animation_loop(&"idle", true)
		for i in count:
			var t := _tex(AnimationSetBuilder.frame_path(dir, id, "idle", i))
			if t == null:
				sf = null
				break
			sf.add_frame(&"idle", t)
		if sf:
			out = {"frames": sf, "offset": AnimationSetBuilder.sprite_offset(manifest)}
	_idle_cache[id] = out
	return out
