class_name OnlineTestKit
extends RefCounted
## Tiện ích cho test trực tuyến (M9).


## Xóa cả thư mục (đệ quy) trong user://.
static func remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var d := DirAccess.open(path)
	for sub in d.get_directories():
		remove_tree(path.path_join(sub))
	for f in d.get_files():
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)
