class_name HitboxTrack
extends RefCounted
## Dựng track AnimationPlayer bật/tắt Hitbox theo frame (README 2.2: hitbox theo track, không vẽ vào sprite).
## Thời gian lấy từ dữ liệu (frame + fps), nên đổi số frame không phải sửa code.
##
## Ví dụ đòn 1 của Aether: khởi động frame 0-2, hiệu lực frame 3-4, hồi phục 5-7 ở 24 fps:
##   HitboxTrack.add(anim, ^"Hitbox", [HitboxTrack.window_from_frames(3, 4, 24.0)])


## Một cửa sổ hiệu lực: [bắt đầu, kết thúc) tính bằng giây; keep_id: dùng lại hit_id của cửa sổ trước.
class HitWindow:
	extends RefCounted
	var start_sec := 0.0
	var end_sec := 0.0
	var keep_id := false

	func _init(s := 0.0, e := 0.0, k := false) -> void:
		start_sec = s
		end_sec = e
		keep_id = k


## Frame `first`..`last` (tính cả hai, đếm từ 0) ở `fps` → cửa sổ giây.
static func window_from_frames(first: int, last: int, fps: float, keep_id := false) -> HitWindow:
	return HitWindow.new(first / fps, (last + 1) / fps, keep_id)


## Thêm track gọi activate()/deactivate() lên Hitbox tại `hitbox_path` (tương đối với root của AnimationPlayer).
## Trả về chỉ số track. Cửa sổ chồng nhau, rỗng hoặc vượt độ dài animation bị bỏ qua và ghi vào `errors`.
static func add(anim: Animation, hitbox_path: NodePath, windows: Array,
		errors: PackedStringArray = PackedStringArray()) -> int:
	var t := anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(t, hitbox_path)
	var last_end := -1.0
	for w: HitWindow in windows:
		if w.start_sec < last_end or w.end_sec <= w.start_sec or w.end_sec > anim.length + 0.0001:
			errors.append("cửa sổ sai %.3f-%.3f (animation dài %.3f)" % [w.start_sec, w.end_sec, anim.length])
			continue
		anim.track_insert_key(t, w.start_sec, {"method": &"activate", "args": [w.keep_id]})
		anim.track_insert_key(t, w.end_sec, {"method": &"deactivate", "args": []})
		last_end = w.end_sec
	return t


## Cửa sổ hiệu lực đọc lại từ track (để test và gỡ lỗi).
static func read_windows(anim: Animation, track: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var start := -1.0
	for k in anim.track_get_key_count(track):
		var v: Dictionary = anim.track_get_key_value(track, k)
		var time := anim.track_get_key_time(track, k)
		if v["method"] == &"activate":
			start = time
		elif v["method"] == &"deactivate" and start >= 0.0:
			out.append(Vector2(start, time))
			start = -1.0
	return out
