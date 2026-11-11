extends Node
## Signal toàn cục. Chỉ khai báo signal, không chứa logic.

## Phát sau khi scene mới đã vào cây.
signal scene_changed(scene_path: String)
## Phát khi người chơi yêu cầu quay lại (Esc, phím Back Android, nút Back).
signal back_requested
