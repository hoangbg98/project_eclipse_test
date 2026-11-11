# Giấy phép asset, mã nguồn và plugin

> README 2.1: không được thêm asset, font, âm thanh, code hay plugin của bên
> thứ ba mà chưa giải thích lý do và ghi nguồn, giấy phép vào file này. Mọi
> giấy phép cần hiển thị phải có trong màn Credits / giấy phép trong game.

## 1. Engine và plugin

| Thành phần | Phiên bản | Giấy phép | Nguồn | Lý do dùng | Cần hiện trong game | Trạng thái |
|---|---|---|---|---|---|---|
| Godot Engine | 4.6.3-stable (`7d41c59c4`) | MIT | https://godotengine.org/license | Engine của dự án | Có (thông báo MIT của Godot + bên thứ ba đi kèm engine) | Đã cài trên máy owner |
| GdUnit4 | 6.2.3 (tag `v6.2.3`, 2026-11-01; README ghi tương thích Godot 4.6.3) | MIT (file `addons/gdUnit4/LICENSE`, © Mike Schulze) | https://github.com/godot-gdunit-labs/gdUnit4 (trước là `MikeSchulze/gdUnit4`); zip mã nguồn của tag, SHA-256 `8fb1a298af110be6d73067af66132bf036049deb6d5929d4a16756e18d2228bb` | Framework test do README chọn | Không ship (`addons/gdUnit4/*` bị loại khỏi mọi preset export, đã kiểm tra), vẫn ghi nhận | Owner duyệt 2026-11-11 (M1-6); đã cài vào `addons/gdUnit4/` |

## 2. Asset của owner (art, UI, VFX, nhạc, SFX, font)

Owner tự vẽ hoặc cung cấp và đã xác nhận có giấy phép thương mại cho mọi font,
nhạc, SFX bên ngoài. Ghi từng file bên ngoài vào bảng dưới khi được thêm vào.

| File / thư mục | Loại | Tác giả / nguồn | Giấy phép | Bằng chứng | Ngày thêm |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

## 3. Placeholder (không bao giờ ship)

Tạo bởi Claude (hình khối màu, âm sinh tự động). Tên luôn bắt đầu bằng
`placeholder_`, nằm trong `assets/placeholders/`.

| File | Thay cho | Thay bằng asset cuối? |
|---|---|---|
| — (chưa có) | | |

## 4. Tài liệu tham khảo (không phải asset game)

| File | Nội dung | Ghi chú |
|---|---|---|
| `docs/reference/ref_01_battle_hud.jpg` | Ảnh chụp game bên thứ ba (Houkai Gakuen 2) | Chỉ để học bố cục. Không import vào game. Loại khỏi export. |
| `docs/reference/ref_02_character_equipment.webp` | Như trên | Như trên |
| `docs/reference/ref_03_home_hub.jpg` | Như trên | Như trên |

## 5. Vấn đề tên / IP

| Tên | Vấn đề | Hành động |
|---|---|---|
| Aether (`char_fire_01`) | Trùng tên nhân vật nổi tiếng của bên thứ ba | Đổi trước khi phát hành công khai |
| Noctis (`char_dark_01`) | Trùng tên nhân vật nổi tiếng của bên thứ ba | Đổi trước khi phát hành công khai |
| Tên dự án "PROJECT ECLIPSE" | Tên làm việc | Kiểm tra nhãn hiệu trước khi phát hành |
