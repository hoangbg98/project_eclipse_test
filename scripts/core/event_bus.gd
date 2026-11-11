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
