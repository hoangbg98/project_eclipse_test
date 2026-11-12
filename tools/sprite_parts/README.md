# sprite_parts — cắt sheet bộ phận nhân vật (rig)

Dùng cho sheet bộ phận vẽ trên nền trắng (owner giao, hoặc ảnh AI theo `AGENTS.md`).

1. `python -I segment_parts.py <sheet.jpg> <parts.json> <preview.png> 190 0`
   Tách vùng (bounding box) và đánh số theo hàng; ngưỡng 190, không giãn.
2. Owner đặt tên từng vùng (loại, lớp gần/xa, tên, ghi chú). Lần đầu (Aether, 2026-11-12) làm qua trang
   artifact "Bảng tên bộ phận Aether"; kết quả lưu ở `assets/characters/<id>/rig_parts/source/<id>_parts_labels.json`.
3. `python -I cut_parts.py <sheet.jpg> <labels.json> <out_dir>`
   Mỗi bộ phận ra một PNG nền trong suốt, chỉ giữ pixel của chính nó (vùng chồng nhau không lẫn),
   lấp lỗ trắng bên trong (áo sơ mi, mắt), làm mềm viền trắng JPEG, bỏ mảnh vụn < 2%.
   Ghi `parts_manifest.json` (id, file, loại, tên, lớp, ghi chú, vị trí trên sheet).

Tên file: `{id}_part_{NN}_{category}_{tên không dấu}.png`. Thư mục `source/` có `.gdignore` (không vào bản build).
Script đọc `character_id` cố định `char_fire_01` trong manifest: sửa khi dùng cho nhân vật khác.
