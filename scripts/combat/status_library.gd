class_name StatusLibrary
extends RefCounted
## Nạp mọi StatusDef trong data/statuses/ (tên file = id).

const DIR := "res://data/statuses"

var statuses: Dictionary = {}  # String id -> StatusDef
var errors := PackedStringArray()


static func load_dir(dir := DIR) -> StatusLibrary:
	var lib := StatusLibrary.new()
	# list_directory xử lý cả file đã đổi tên khi export (.remap).
	for f in ResourceLoader.list_directory(dir):
		if f.get_extension() not in ["tres", "res"]:
			continue
		var res := load(dir.path_join(f))
		if not res is StatusDef:
			lib.errors.append("%s không phải StatusDef" % f)
			continue
		var s := res as StatusDef
		if s.id != f.get_basename():
			lib.errors.append("%s: id '%s' khác tên file" % [f, s.id])
		lib.errors.append_array(s.validate())
		lib.statuses[s.id] = s
	return lib


func get_status(id: String) -> StatusDef:
	return statuses.get(id)


func ids() -> PackedStringArray:
	var out := PackedStringArray(statuses.keys())
	out.sort()
	return out
