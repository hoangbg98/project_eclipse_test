extends Node
## Signal toàn cục. Chỉ khai báo signal, không chứa logic.

## Phát sau khi scene mới đã vào cây.
signal scene_changed(scene_path: String)
## Phát khi người chơi yêu cầu quay lại (Esc, phím Back Android, nút Back).
signal back_requested

## Chiến đấu (LinkTracker M4-3 nghe để mở cửa sổ Liên kết).
## Kẻ địch bị Choáng (thanh SC đầy); `by` là Combatant gây đòn cuối.
signal enemy_stunned(enemy: Node, by: Object)
## Kẻ địch bị hạ.
signal enemy_defeated(enemy: Node, by: Object)

## Phản hồi đòn (HitFeedback M3-7 nghe; logic combat không phụ thuộc vào ai nghe).
## Một đòn trực tiếp trúng: attacker/target là Combatant; result là DamageCalculator.Result.
signal hit_landed(attacker: Object, target: Object, result: Object, hit: Object)
## Sát thương theo nhịp (Cháy...).
signal dot_landed(target: Object, amount: int, status_id: String)
## Bắt đầu tuyệt kỹ (dừng thời gian + cut-in).
signal ultimate_started(actor: Node, skill: Resource)
