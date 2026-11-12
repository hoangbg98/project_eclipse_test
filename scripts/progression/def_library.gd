class_name DefLibrary
extends RefCounted
## Nạp mọi Resource có trường `id` trong một thư mục data (items, equipment…), khóa theo id.

var defs: Dictionary = {}
var errors := PackedStringArray()


static func load_dir(dir: String) -> DefLibrary:
	var lib := DefLibrary.new()
	for f in ResourceLoader.list_directory(dir):
		if f.get_extension() not in ["tres", "res"]:
			continue
		var d := load(dir.path_join(f))
		if d == null or not ("id" in d):
			lib.errors.append("%s: không có id" % f)
			continue
		if d.has_method("validate"):
			lib.errors.append_array(d.validate())
		if lib.defs.has(d.id):
			lib.errors.append("trùng id %s" % d.id)
		lib.defs[d.id] = d
	return lib


func get_def(id: String) -> Resource:
	return defs.get(id)


func has(id: String) -> bool:
	return defs.has(id)


func ids() -> PackedStringArray:
	var out := PackedStringArray(defs.keys())
	out.sort()
	return out
