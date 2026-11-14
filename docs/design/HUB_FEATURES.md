# Sảnh chính (Hub) và các tính năng mở từ đó

> Owner đề xuất 2026-11-14 (5 ảnh tham chiếu: sảnh chính, kho vũ khí, Tiếp tế, Chỉ huy, Xuất kích). Bố cục chỉnh trong
> `data/ui/hub_home_layout.json` (tab Trang chủ) và `data/ui/hub_screens_layout.json` (các màn con), không cần sửa code.

## Bản đồ màn

| Vị trí ở tab Trang chủ | Màn | Trạng thái |
|---|---|---|
| Thẻ người chơi (góc trên-trái) | Thông tin người chơi `scenes/main/player_screen.tscn` | Có: LV / EXP Chỉ huy, đổi tên, bộ sưu tập nhân vật / vũ khí / vết thánh (đã có / chưa sở hữu) |
| Phần bên trái | Dòng tóm tắt cũ | Giữ nguyên, owner chỉnh sau |
| Lục giác Trang bị | Túi đồ `bag_screen.tscn` | Có: Vũ khí, Vết thánh, Nguyên liệu, Mảnh; thẻ theo độ hiếm, Đang dùng, chi tiết chỉ số |
| Lục giác Người cộng tác | `companion_screen.tscn` | Màn giới thiệu "Sắp có"; gameplay chưa làm (mục dưới) |
| Lục giác Xuất kích | `sortie_screen.tscn` | Có: Cốt truyện chính (Màn 1), Thử đội hình (màn thử nghiệm), Đội hình (về tab Chiến đấu); Ải nguyên liệu "Sắp có"; tab Đề cử / Khiêu chiến / Event "Sắp ra mắt" |
| Lục giác Nhân vật | Màn Nhân vật cũ | Thay tab Nhân vật trên thanh tab |
| Lục giác Tiếp tế | `supply_screen.tscn` | Có: Tiếp tế → Chiêu mộ; Shop "Sắp có"; Nạp chỉ bản online (mục dưới) |

Tab Chiêu mộ trên thanh tab vẫn còn (trùng với Tiếp tế → Tiếp tế); owner quyết định có bỏ hay không.

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
