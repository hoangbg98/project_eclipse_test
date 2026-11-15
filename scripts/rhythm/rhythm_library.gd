class_name RhythmLibrary
extends RefCounted
## Thư viện bài nhạc của chế độ nhịp điệu (M10): đọc danh mục `catalog.json` trên máy chủ (đường dẫn
## `<máy chủ>/music/`, server/gateway.mjs phát file), tải nhạc + bản nốt về `user://rhythm_cache/` và kiểm sha256.
## Owner chọn 2026-11-16: tải về rồi lưu cache; mất mạng vẫn chơi được bài đã tải.
##
## Mạng đi qua `fetcher` (Callable bất đồng bộ: url -> {ok, code, body: PackedByteArray, error}) để test thay bằng
## máy chủ giả. Màn chơi tạo bằng `RhythmLibrary.create(node)` (dùng HTTPRequest gắn vào node đó).

const CATALOG_FILE := "catalog.json"
const DEFAULT_CACHE := "user://rhythm_cache"
const FORMAT := 1
const AUDIO_EXT: Array[String] = ["wav", "ogg", "mp3"]

var base_url := ""
var cache_dir := DEFAULT_CACHE
var fetcher: Callable
## Danh mục đang dùng: {format, songs: [...]}.
var catalog: Dictionary = {}
## true = danh mục lấy từ bản đã lưu (không tới được máy chủ).
var from_cache := false
var last_error := ""

var _verified: Dictionary = {}   # đường dẫn -> sha256 đã kiểm


func _init(base_url_ := "", fetcher_ := Callable(), cache_dir_ := DEFAULT_CACHE) -> void:
	base_url = base_url_
	if base_url != "" and not base_url.ends_with("/"):
		base_url += "/"
	fetcher = fetcher_
	cache_dir = cache_dir_


## Thư viện dùng máy chủ của OnlineService (`<server_url>/music/`) và HTTPRequest gắn vào `owner`.
static func create(owner: Node) -> RhythmLibrary:
	var online := owner.get_tree().root.get_node_or_null("OnlineService") if owner.is_inside_tree() else null
	var url := ""
	if online and online.config:
		url = str(online.config.server_url)
	return RhythmLibrary.new(url + "/music/" if url != "" else "", http_fetcher(owner))


## Fetcher mặc định: mỗi lần tải tạo một HTTPRequest con của `owner`.
static func http_fetcher(owner: Node, timeout_sec := 90.0) -> Callable:
	return func(url: String) -> Dictionary:
		if not is_instance_valid(owner) or not owner.is_inside_tree():
			return {"ok": false, "code": 0, "body": PackedByteArray(), "error": "no_tree"}
		var req := HTTPRequest.new()
		req.timeout = timeout_sec
		owner.add_child(req)
		var err := req.request(url)
		if err != OK:
			req.queue_free()
			return {"ok": false, "code": 0, "body": PackedByteArray(), "error": "request_failed"}
		var res: Array = await req.request_completed
		req.queue_free()
		var code := int(res[1])
		var ok := int(res[0]) == HTTPRequest.RESULT_SUCCESS and code == 200
		return {"ok": ok, "code": code, "body": res[3], "error": "" if ok else "http_%d" % code}


static func safe_name(file: String) -> bool:
	if file.is_empty() or file.length() > 120 or file.begins_with("."):
		return false
	for ch in file:
		if not (ch.is_valid_identifier() or ch in "0123456789.-_"):
			return false
	return true


func songs() -> Array:
	return catalog.get("songs", [])


func song(id: String) -> Dictionary:
	for s in songs():
		if str(s.get("id", "")) == id:
			return s
	return {}


func chart_info(song_id: String, chart_key: String) -> Dictionary:
	var c: Variant = song(song_id).get("charts", {}).get(chart_key)
	return c if c is Dictionary else {}


## Tải danh mục mới; lỗi mạng thì dùng bản đã lưu. Trả về true nếu có danh mục dùng được.
func refresh_catalog() -> bool:
	last_error = ""
	if base_url != "" and fetcher.is_valid():
		var res: Dictionary = await fetcher.call(base_url + CATALOG_FILE)
		if bool(res.get("ok", false)):
			var parsed := _parse_catalog((res["body"] as PackedByteArray).get_string_from_utf8())
			if not parsed.is_empty():
				catalog = parsed
				from_cache = false
				DirAccess.make_dir_recursive_absolute(cache_dir)
				_write(cache_dir.path_join(CATALOG_FILE), res["body"])
				return true
			last_error = "bad_catalog"
		else:
			last_error = str(res.get("error", "network"))
	else:
		last_error = "no_server"
	var cached_path := cache_dir.path_join(CATALOG_FILE)
	if FileAccess.file_exists(cached_path):
		var cached := _parse_catalog(FileAccess.get_file_as_string(cached_path))
		if not cached.is_empty():
			catalog = cached
			from_cache = true
			return true
	catalog = {}
	return false


static func _parse_catalog(text: String) -> Dictionary:
	var d: Variant = JSON.parse_string(text)
	if not (d is Dictionary) or int(d.get("format", 0)) != FORMAT or not (d.get("songs") is Array):
		return {}
	var ok: Array = []
	for s in d["songs"]:
		if s is Dictionary and str(s.get("id", "")) != "" and s.get("audio") is Dictionary and s.get("charts") is Dictionary \
				and safe_name(str(s["audio"].get("file", ""))):
			ok.append(s)
	d["songs"] = ok
	return d


## Các file (nhạc + bản nốt) cần cho một lượt chơi: [{file, sha256, bytes}].
func _needed(song_id: String, chart_key: String) -> Array:
	var s := song(song_id)
	var c := chart_info(song_id, chart_key)
	if s.is_empty() or c.is_empty() or not safe_name(str(c.get("file", ""))):
		return []
	return [s["audio"], c]


func local_path(file: String) -> String:
	return cache_dir.path_join(file)


func _valid_file(info: Dictionary) -> bool:
	var path := local_path(str(info.get("file", "")))
	if not FileAccess.file_exists(path):
		return false
	var want := str(info.get("sha256", ""))
	if want == "":
		return true
	if _verified.get(path, "") == want:
		return true
	var got := FileAccess.get_sha256(path)
	if got == want:
		_verified[path] = got
		return true
	return false


func is_cached(song_id: String, chart_key: String) -> bool:
	var need := _needed(song_id, chart_key)
	if need.is_empty():
		return false
	for info in need:
		if not _valid_file(info):
			return false
	return true


## Số byte còn phải tải cho một lượt chơi.
func missing_bytes(song_id: String, chart_key: String) -> int:
	var n := 0
	for info in _needed(song_id, chart_key):
		if not _valid_file(info):
			n += int(info.get("bytes", 0))
	return n


## Tải các file còn thiếu. Trả về {ok, error}.
func ensure(song_id: String, chart_key: String) -> Dictionary:
	var need := _needed(song_id, chart_key)
	if need.is_empty():
		return {"ok": false, "error": "unknown_song"}
	DirAccess.make_dir_recursive_absolute(cache_dir)
	for info in need:
		if _valid_file(info):
			continue
		if base_url == "" or not fetcher.is_valid():
			return {"ok": false, "error": "no_server"}
		var res: Dictionary = await fetcher.call(base_url + str(info["file"]))
		if not bool(res.get("ok", false)):
			return {"ok": false, "error": str(res.get("error", "network"))}
		var body: PackedByteArray = res["body"]
		var want := str(info.get("sha256", ""))
		if want != "" and _sha256(body) != want:
			return {"ok": false, "error": "checksum"}
		_write(local_path(str(info["file"])), body)
		_verified[local_path(str(info["file"]))] = want
	return {"ok": true, "error": ""}


func load_chart(song_id: String, chart_key: String) -> RhythmChart:
	var c := chart_info(song_id, chart_key)
	if c.is_empty():
		var bad := RhythmChart.new()
		bad.errors.append("không có bản nốt %s/%s" % [song_id, chart_key])
		return bad
	return RhythmChart.load_file(local_path(str(c["file"])))


func load_audio(song_id: String) -> AudioStream:
	var s := song(song_id)
	if s.is_empty():
		return null
	return load_audio_file(local_path(str(s["audio"]["file"])))


static func load_audio_file(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		return null
	match path.get_extension().to_lower():
		"wav":
			return AudioStreamWAV.load_from_file(path)
		"ogg":
			return AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			return AudioStreamMP3.load_from_file(path)
	return null


static func _sha256(bytes: PackedByteArray) -> String:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(bytes)
	return h.finish().hex_encode()


static func _write(path: String, bytes: PackedByteArray) -> void:
	var tmp := path + ".part"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_buffer(bytes)
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	DirAccess.rename_absolute(tmp, path)
