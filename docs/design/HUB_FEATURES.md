# Sảnh chính (Hub) và các tính năng mở từ đó

> Owner đề xuất 2026-11-14 (5 ảnh tham chiếu: sảnh chính, kho vũ khí, Tiếp tế, Chỉ huy, Xuất kích). Bố cục chỉnh trong
> `data/ui/hub_home_layout.json` (tab Trang chủ) và `data/ui/hub_screens_layout.json` (các màn con), không cần sửa code.

## Bản đồ màn (bản 2, owner 2026-11-14: kiểu ô ghép theo dự án cũ của owner)

Không còn thanh tab ô vuông phía trên và dòng tóm tắt (PROJECT ECLIPSE, vàng / ngọc, đội hình, số màn).

| Vị trí ở sảnh | Mở ra | Trạng thái |
|---|---|---|
| Nền phía sau | Nền người chơi đang chọn (`data/backgrounds/`) | Có: đổi nền, mua bằng ngọc, mở khóa từ sự kiện (save v5 `cosmetics`) |
| Bên trái | Splash nhân vật đầu đội (`{id}_splash_overview.png`, thiếu thì ảnh chibi) | Có |
| Thẻ người chơi (góc trên-trái) | Thông tin người chơi `scenes/main/player_screen.tscn` | Có: LV / EXP Chỉ huy, đổi tên, bộ sưu tập |
| Góc trên-phải | Ô vàng / ngọc; nút khung tranh → bảng Đổi nền; bánh răng → bảng Cài đặt (+ Credits, quà thử nghiệm bản debug) | Có |
| Ô Nhân vật | Màn Nhân vật | Có |
| Ô Xuất kích (lớn) | `sortie_screen.tscn`: Cốt truyện chính, Thử đội hình, Đội hình (→ bảng Chiến đấu của sảnh), Ải nguyên liệu (Sắp có) | Có |
| Ô Trang bị | Túi đồ `bag_screen.tscn` | Có |
| Ô Tiếp tế | `supply_screen.tscn`: Shop (Sắp có), **Chiêu mộ** (→ màn Chiêu mộ), Nạp (chỉ bản online) | Có |
| Ô Người cộng tác | `companion_screen.tscn` (giới thiệu, Sắp có) | Gameplay chưa làm |

Bảng nổi của sảnh (đóng bằng ✕ hoặc Back / Esc): Chiến đấu (chọn đội, danh sách màn, nút Màn 1 / Màn thử nghiệm),
Cài đặt, Đổi nền.

## Nền sảnh

- Định nghĩa: `data/backgrounds/{id}.tres` (`BackgroundDef`: ảnh, nguồn STARTER / SHOP / EVENT, `price_gems`,
  `how_to_get_key`, `sort_order`). Thêm nền = thêm file .tres + ảnh, không sửa code.
- Nền STARTER có sẵn; SHOP mua bằng ngọc trong bảng Đổi nền (sau này cả Shop); EVENT mở bằng
  `PlayerProfile.unlock_background(id)` khi phát thưởng sự kiện.
- Nền khởi đầu hiện là ảnh TẠM `assets/placeholders/placeholder_hub_bg_sky_garden.png` (không ship, xem ASSET_LICENSES).

## Người cộng tác (tinh linh) — kế hoạch, CHƯA làm

Owner 2026-11-14: tính năng riêng của game.

- Một tinh linh nhỏ bay theo nhân vật đang trên sân; đổi nhân vật thì bay theo người mới.
- Tự đánh hỗ trợ nhẹ khi nhân vật tấn công (sát thương nhỏ, không phá chuỗi đòn).
- Tích **năng lượng tinh linh** khi đánh trúng và khi né hoàn hảo.
- Đầy năng lượng: dùng **kỹ năng chủ động** riêng của tinh linh (nút riêng trên HUD, cạnh nút tuyệt kỹ).
- Cần owner quyết định trước khi làm: số tinh linh và cách nhận (gacha / sự kiện / cốt truyện), có nâng cấp không,
  kỹ năng chủ động của từng tinh linh, nút trên HUD, art (sprite bay, icon). Số cân bằng sẽ nằm trong `data/`.

## Nạp tiền — chỉ khi phát hành online (mục riêng)

- Bản hiện tại là offline: thẻ Nạp ở màn Tiếp tế chỉ hiện thông báo "Nạp chỉ mở khi game phát hành online"
  (`SupplyScreen.ONLINE_BUILD = false`).
- Nếu phát hành online cần làm riêng: máy chủ xác thực giao dịch, cổng thanh toán của từng store (Google Play Billing,
  Steam Microtransactions...), chính sách hoàn tiền, công bố tỉ lệ gacha theo luật từng nước, bảo vệ trẻ vị thành niên.
  Không làm nạp tiền phía client một mình.
