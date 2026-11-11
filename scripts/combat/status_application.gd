class_name StatusApplication
extends Resource
## Một trạng thái mà đòn/kỹ năng áp lên mục tiêu (vd "Cháy 3s").
## duration/magnitude âm = dùng mặc định trong StatusDef.

@export var status_id := ""
@export var duration := -1.0
@export var magnitude := -1.0
## Áp lên chính người đánh thay vì mục tiêu (vd buff).
@export var on_self := false


static func make(id: String, dur := -1.0, mag := -1.0) -> StatusApplication:
	var s := StatusApplication.new()
	s.status_id = id
	s.duration = dur
	s.magnitude = mag
	return s
