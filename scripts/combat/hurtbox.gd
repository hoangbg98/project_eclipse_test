class_name Hurtbox
extends Area2D
## Vùng nhận đòn. Nhận mỗi hit_id một lần, bỏ qua đòn cùng phe.
## Đang bất tử (vd khung né): đòn bị "né" — báo hit_evaded và vẫn ghi nhớ hit_id,
## nên hết bất tử giữa chừng cũng không bị chính lần chém đó trúng.

## Trúng thật; hệ thống máu/sát thương (M3-3, M3-4) nghe signal này.
signal hit_received(hit: HitInfo)
## Đòn đến khi đang bất tử; dùng cho né hoàn hảo (M3-4+).
signal hit_evaded(hit: HitInfo)

@export var team := PhysicsLayers.Team.PLAYER
## Quên hit_id sau bấy nhiêu giây (đủ dài hơn pha hiệu lực dài nhất).
@export var memory_sec := 3.0

var invulnerable := false
## Nguồn thời gian (giây). Test thay bằng đồng hồ giả để tái lập được.
var clock: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0
## Node sở hữu (nhân vật / quái); mặc định là cha.
var owner_node: Node

var _seen: Dictionary = {}  # hit_id -> thời điểm (giây)


func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_layer = PhysicsLayers.hurtbox_layer(team)
	collision_mask = 0
	if owner_node == null:
		owner_node = get_parent()


## Xử lý một đòn. Trả về true nếu trúng thật (lần đầu, khác phe, không bất tử).
func receive(hit: HitInfo) -> bool:
	if hit.team == team:
		return false
	if hit.attacker != null and hit.attacker == owner_node:
		return false
	_forget_old()
	if _seen.has(hit.hit_id):
		return false
	_seen[hit.hit_id] = _now()
	if invulnerable:
		hit_evaded.emit(hit)
		return false
	hit_received.emit(hit)
	return true


func has_seen(id: int) -> bool:
	return _seen.has(id)


func _forget_old() -> void:
	var now := _now()
	for id in _seen.keys():
		if now - float(_seen[id]) > memory_sec:
			_seen.erase(id)


func _now() -> float:
	return float(clock.call())
