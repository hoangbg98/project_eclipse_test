class_name BossDef
extends EnemyDef
## Định nghĩa boss: EnemyDef + các pha (data/enemies/{id}.tres). `attack` của EnemyDef không dùng.

## Telegraph tối thiểu của mọi đòn boss (README 15.7): pha khởi động ≥ 0.4 s.
const MIN_TELEGRAPH_MS := 400.0

## Các pha theo thứ tự; `hp_ratio_below` giảm dần.
@export var phases: Array[BossPhaseDef] = []
## Thời gian chuyển pha (s): boss đứng yên, bất tử, rồi vào pha mới.
@export var phase_transition_sec := 1.2


func validate() -> PackedStringArray:
	var e := PackedStringArray()
	if phases.size() < 2:
		e.append("%s: boss cần ít nhất 2 pha" % id)
	var prev := 1.0001
	for i in phases.size():
		var p := phases[i]
		if p == null or p.attacks.is_empty():
			e.append("%s: pha %d không có đòn" % [id, i + 1])
			continue
		if p.hp_ratio_below >= prev:
			e.append("%s: hp_ratio_below của pha %d phải nhỏ hơn pha trước" % [id, i + 1])
		prev = p.hp_ratio_below
		for a in p.attacks:
			if a.startup_ms < MIN_TELEGRAPH_MS:
				e.append("%s: đòn %s báo hiệu %d ms < %d ms" % [id, a.id, a.startup_ms, MIN_TELEGRAPH_MS])
			e.append_array(a.validate())
	if not phases.is_empty() and phases[0].hp_ratio_below < 1.0:
		e.append("%s: pha 1 phải có hp_ratio_below = 1.0" % id)
	return e
