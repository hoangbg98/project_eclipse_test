class_name UiLayout
extends RefCounted
## Đọc file bố cục JSON (vd data/ui/character_screen_layout.json) để owner chỉnh vị trí, cỡ chữ, màu mà không sửa code.
## Mọi hàm nhận đường dẫn dạng "nhom.muc" và giá trị mặc định: thiếu hoặc sai kiểu thì dùng mặc định (không lỗi).

var data: Dictionary = {}
var design_size := Vector2(1920, 1080)
## Kích thước khung đang hiển thị (để dời phần tử neo phải / giữa khi màn rộng hơn 16:9).
var view_size := Vector2(1920, 1080)
var errors := PackedStringArray()


static func load_from(path: String) -> UiLayout:
	var l := UiLayout.new()
	if not FileAccess.file_exists(path):
		l.errors.append("không có file bố cục: %s" % path)
		return l
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (d is Dictionary):
		l.errors.append("file bố cục không phải JSON object: %s" % path)
		return l
	l.data = d
	var ds: Variant = d.get("design_size")
	if ds is Array and ds.size() == 2:
		l.design_size = Vector2(float(ds[0]), float(ds[1]))
	l.view_size = l.design_size
	return l


func get_value(path: String, fallback: Variant = null) -> Variant:
	var cur: Variant = data
	for k in path.split("."):
		if not (cur is Dictionary) or not cur.has(k):
			return fallback
		cur = cur[k]
	return cur


func dict(path: String) -> Dictionary:
	var v: Variant = get_value(path, {})
	return v if v is Dictionary else {}


func num(path: String, fallback: float) -> float:
	var v: Variant = get_value(path, fallback)
	return float(v) if (v is float or v is int) else fallback


func text(path: String, fallback := "") -> String:
	var v: Variant = get_value(path, fallback)
	return str(v) if v != null else fallback


func color(name: String, fallback := Color.WHITE) -> Color:
	var v: Variant = get_value("colors." + name, "")
	return Color.from_string(str(v), fallback) if str(v) != "" else fallback


## Độ dời ngang theo neo: màn rộng hơn khung thiết kế thì phần tử neo phải dời hết phần dư, neo giữa dời một nửa.
func anchor_shift(anchor: String) -> float:
	var extra := view_size.x - design_size.x
	match anchor:
		"right":
			return extra
		"center":
			return extra * 0.5
	return 0.0


static func _rect_of(v: Variant) -> Variant:
	if v is Array and v.size() == 4:
		return Rect2(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
	return null


## Hình chữ nhật của mục `path` (mục có "rect" và "anchor"), đã dời theo neo.
func rect(path: String, fallback := Rect2()) -> Rect2:
	var d := dict(path)
	var r: Variant = _rect_of(d.get("rect"))
	if r == null:
		return fallback
	var out: Rect2 = r
	out.position.x += anchor_shift(str(d.get("anchor", "left")))
	return out


## Hình chữ nhật thô trong một mảng (vd "stigma_tab.cards.rects", chỉ số i), dời theo neo của mục cha.
func rect_in(path: String, index: int, anchor := "left", fallback := Rect2()) -> Rect2:
	var arr: Variant = get_value(path, [])
	if not (arr is Array) or index >= arr.size():
		return fallback
	var r: Variant = _rect_of(arr[index])
	if r == null:
		return fallback
	var out: Rect2 = r
	out.position.x += anchor_shift(anchor)
	return out


## Điểm [x, y] của mục `path.key`, dời theo neo của mục `path`.
func point(path: String, key: String, fallback := Vector2.ZERO) -> Vector2:
	var d := dict(path)
	var v: Variant = d.get(key)
	if not (v is Array and v.size() == 2):
		return fallback
	return Vector2(float(v[0]) + anchor_shift(str(d.get("anchor", "left"))), float(v[1]))


func font(path: String, fallback := 30) -> int:
	return int(num(path + ".font", fallback))


## Chữ của mục: "text_key" (qua tr) nếu có, không thì "text".
func label(path: String, fallback := "") -> String:
	var d := dict(path)
	if str(d.get("text_key", "")) != "":
		return TranslationServer.translate(str(d["text_key"]))
	return str(d.get("text", fallback))
