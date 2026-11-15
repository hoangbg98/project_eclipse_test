# Ảnh màn Chiêu mộ

Thư mục này chứa ảnh banner của màn Chiêu mộ (`scripts/ui/recruit_screen.gd`). Phần lớn là **ảnh tạm**
(`placeholder_*`, hình người xám kèm tên banner); owner thay bằng ảnh thật khi có.

## Cách thay ảnh

Mỗi banner (id ghi trong `data/banners/*.tres`, ví dụ `banner_char_terra`) cần hai ảnh:

| Ảnh | Tên file | Kích thước khuyến nghị | Hiện ở đâu |
|---|---|---|---|
| Banner lớn | `{id}_banner.png` | **1590 × 1080** px | Phủ phần phải màn (x 330 → 1920); vùng chữ / nút xem wireframe `docs/design/wireframes/recruit/` |
| Ảnh nhỏ | `{id}_thumb.png` | **390 × 226** px | Bố cục 2026-11-15 không còn hiện (danh sách trái là thẻ chữ) |

Đã có ảnh thật: `banner_char_terra_banner.png` (Iwagane, owner 2026-11-15).

Chỉ cần **thêm file đúng tên** vào thư mục này, không sửa code. Màn tìm theo thứ tự:

1. đường dẫn ghi trong `BannerDef.banner_art` / `thumb_art` (nếu có điền),
2. `{id}_banner.png` / `{id}_thumb.png`,
3. `placeholder_{id}_banner.png` / `placeholder_{id}_thumb.png`,
4. không có file nào: màn tự vẽ hình người xám kèm tên banner.

Ảnh khác tỉ lệ vẫn dùng được: màn thu vừa khung, giữ tỉ lệ, không kéo méo.

Sau khi thêm file, mở Godot một lần (hoặc chạy `godot --headless --path . --import`) để nó nhập ảnh.

## Quy tắc

- Ảnh `placeholder_*` không bao giờ ship (bản Release tự loại).
- Ảnh do AI tạo dùng thật phải ghi vào `docs/ASSET_LICENSES.md` mục 2.1; ảnh owner tự vẽ ghi vào mục asset của owner.
- Tạo lại ảnh tạm cho banner mới: `python -X utf8 tools/gen_recruit_placeholders.py` (không ghi đè file đã có, `--force` để ghi đè).
- Vị trí chữ, nút, màu của màn nằm ở `data/ui/recruit_screen_layout.json`.
