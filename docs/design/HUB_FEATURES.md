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
| Ô Xuất kích (lớn) | `sortie_screen.tscn`: Cốt truyện chính (→ Thông tin màn), Thử đội hình, Đội hình (→ màn Đội hình), Ải nguyên liệu (Sắp có) | Có |
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

## Vào màn: mục tiêu chiến đấu, đội hình, chọn giáp (owner 2026-11-14)

Luồng: Xuất kích → Cốt truyện chính → **Thông tin màn** → Chuẩn bị → **Đội hình** → Khai chiến. Chạm ảnh ở Đội hình →
**Chọn giáp** → Xác nhận đội ngũ (quay lại Đội hình). Thẻ Đội hình ở Xuất kích mở màn Đội hình không có nút Khai chiến.

- Thông tin màn (`stage_info_screen.tscn`): tên, ảnh xem trước (trường `preview` trong data màn; chưa có thì icon),
  mô tả (`desc_key`), cấp đề cử (`recommended_level`), mục tiêu chiến đấu (Đã đạt / Chưa đạt), Có thể rơi.
- Mục tiêu chiến đấu: mục `objectives` trong `data/stages/{id}.json`, loại `time_max`, `hits_taken_max`,
  `damage_taken_max`, `downs_max` (`BattleObjectives`). **Mỗi lần qua màn**, mỗi mục tiêu đạt thưởng thêm số vàng
  `gold` của nó; mục tiêu đã từng đạt lưu ở `progress.stages[id].objectives`. Thua thì không chấm.
- Đội hình (`party_prep_screen.tscn`): splash 3 giáp trong đội (chưa có splash thì chân dung chibi, rồi frame idle);
  bên phải tóm tắt màn và mục tiêu.
- Chọn giáp (`party_select_screen.tscn`): lưới giáp đang sở hữu (số thứ tự trong đội ở góc) + sân khấu 3 vị trí
  (1 giữa, 2 trái, 3 phải) nhân vật đứng idle. Luật giữ như cũ (`PlayerProfile.toggle_party`): thêm xuống cuối, bỏ
  ra, không bỏ người cuối, tối đa 3, không hai giáp cùng nhân vật.
- Bố cục: mục `stage_info`, `party_prep`, `party_select` trong `data/ui/hub_screens_layout.json`.

## Hướng dẫn người mới (owner 2026-11-14)

- Game mới chỉ có **Enkiba** (`SaveSchema.STARTER_CHARACTERS`). Qua **ải 1-1** (`stage_01`, `code` "1-1") lần đầu nhận
  **Kazeyumi** (vào đội luôn) và **Vé chiêu mộ đầu tiên** (`ticket_starter_x10`), cùng thưởng cũ.
- Vé mở lượt x10 miễn phí `data/tutorial/starter_pull.tres` (chắc chắn 1 Raikiba + 9 sách EXP). Banner này chỉ hiện ở
  đầu danh sách màn Chiêu mộ khi có vé và chưa dùng; quay xong trừ vé, Raikiba vào đội nếu còn chỗ, banner biến mất.
- Hướng dẫn khóa màn (`TutorialGuide`, luật ở `TutorialFlow`): làm tối toàn màn, chừa ô sáng nhấp nháy quanh nút cần
  bấm + dòng gợi ý; chuột / chạm ngoài ô bị chặn, phím và tay cầm bị chặn (Enter / A bấm đúng nút được chỉ), Back bị chặn.
  - Chưa qua 1-1: Sảnh **Xuất kích** → **Chương cốt truyện chính** → **Chuẩn bị** → **Khai chiến**. Trong trận không
    khóa; thua thì chỉ cho **Chơi lại**.
  - Đã qua 1-1, còn vé: màn kết quả **Về Hub** → (Menu nếu đang ở màn khác) → **Tiếp tế** → **Đi chiêu mộ** →
    **Chiêu mộ ×10 (dùng vé)** → **Xác nhận** → xong (`tutorial.done`).
  - Bước suy từ save, nên thoát game giữa chừng vẫn tiếp tục đúng chỗ. Save cũ (v5) coi như đã xong hướng dẫn.
- **Trợ lý AI NEO** (owner 2026-11-14): mỗi bước mở đầu bằng đoạn trò chuyện giữa NEO (trợ lý AI của Trạm) và
  Quản lý (người chơi). Khung hội thoại kiểu viễn tưởng: lõi AI phát sáng vẽ bằng code (chưa có art), tên "NEO · Trợ
  lý AI", chữ hiện dần (48 ký tự/giây), nút đáp của Quản lý; chạm bất kỳ đâu / Enter / A để hiện hết câu rồi sang câu
  kế; "Bỏ qua thoại" nhảy tới câu chỉ dẫn. Lúc trò chuyện cả màn bị che; câu chỉ dẫn cuối mới chừa ô sáng quanh nút.
  - Kịch bản: `data/tutorial/tutorial_dialogue.json` (id bước → danh sách khóa câu NEO + khóa câu đáp); chữ thật trong
    `localization/*.po` (`TUTORIAL_<ID>_<n>`, `..._R`). Đổi tên trợ lý: khóa `TUTORIAL_AI_NAME`.
  - Mỗi đoạn trò chuyện chỉ phát một lần (`tutorial.seen`); quay lại bước đó (vd thua lần hai) chỉ còn câu chỉ dẫn.
  - NEO lấy theo đề xuất cốt truyện (`docs/design/STORY_PROPOSAL.md`, chưa phải canon): thiết bị / trợ lý của Quản lý.

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
