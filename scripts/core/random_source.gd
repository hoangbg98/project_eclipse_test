class_name RandomSource
extends RefCounted
## Nguồn ngẫu nhiên có seed (ARCHITECTURE mục 5): mọi roll gameplay đi qua đây để test tái lập được.
## Không dùng randf() toàn cục trong code gameplay.

var _rng := RandomNumberGenerator.new()


## seed_value = 0: seed ngẫu nhiên theo thời gian (khi chơi thật).
func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value


## Số thực đều trong [0, 1).
func randf() -> float:
	return _rng.randf()


## True với xác suất `chance` (0..1).
func chance(p: float) -> bool:
	if p <= 0.0:
		return false
	if p >= 1.0:
		return true
	return _rng.randf() < p


func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


## Lưu/khôi phục trạng thái (cho save hoặc phát lại).
func get_state() -> int:
	return _rng.state


func set_state(s: int) -> void:
	_rng.state = s


## Nguồn luôn trả một giá trị cố định (test ép chí mạng có/không).
class Fixed:
	extends RandomSource
	var value := 0.0

	func _init(v: float = 0.0) -> void:
		super(1)
		value = v

	func randf() -> float:
		return value

	func chance(p: float) -> bool:
		if p <= 0.0:
			return false
		if p >= 1.0:
			return true
		return value < p
