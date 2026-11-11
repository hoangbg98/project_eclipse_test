# Đặc tả UI / UX

> Rút từ README mục 15 và 17.5. Owner vẽ giao diện cuối cùng; Claude làm màn
> hình chạy được với dữ liệu thật và một Theme dùng lại được để owner đổi
> giao diện **mà không sửa code**. Ảnh trong `docs/reference/` chỉ để học
> bố cục, không sao chép asset, nhân vật, icon, chữ, bảng màu hay bố cục 1:1.

## 1. Danh sách màn hình (bản đầu)

| Màn hình | Thành phần chính | Bản đầu |
|---|---|---|
| Boot / loading | Logo, tiến độ, phiên bản | Có |
| Title | Tiếp tục, Game mới, Cài đặt | Có |
| Hub | Nền key art, thẻ hồ sơ, tiền tệ, tab điều hướng | Có |
| Chọn màn | Danh sách màn, xem trước thưởng, bắt đầu | Có |
| Chọn đội | 3 slot, thẻ nhân vật, vai trò, nguyên tố | Có |
| HUD chiến đấu | Mục 3 | Có |
| Pause | Tiếp tục, Cài đặt, Thoát (có xác nhận) | Có |
| Kết quả | Thưởng, EXP, chơi lại, về hub | Có |
| Nhân vật | Hình lớn, băng thẻ chọn, chỉ số, kỹ năng | Có |
| Trang bị / kho đồ | Slot, danh sách, so sánh, trang bị | Có (cơ bản) |
| Chiêu mộ | Banner, nút tỉ lệ, bộ đếm pity, x1 / x10, lịch sử, bỏ qua hoạt cảnh | Có |
| Cài đặt | Âm thanh, điều khiển, ngôn ngữ, đồ họa | Có |
| Credits / giấy phép | Godot MIT và mọi plugin | Có |
| Nâng cấp kỹ năng | Hệ kỹ năng nhiều tầng | Sau slice |
| Shop, Social, Codex, Mail, Quest | — | Không |

## 2. Điều hướng

- Tab hub bản đầu: **Home, Battle, Characters/Equipment, Recruit, Settings**.
  Tab của tính năng chưa làm thì **ẩn**, không hiển thị dạng khóa.
- Thanh trên cùng (hồ sơ, tiền tệ, tab) giữ nguyên trên mọi màn hub.
- Mọi màn con có nút Back góc trên trái và nhận phím Back Android / Esc.
- Chuyển cảnh 150–250 ms. Nạp > 2s hiện thanh tiến độ.

## 3. HUD chiến đấu (1920×1080 logic)

```
┌──────────────────────────────────────────────────────────────────┐
│[Chân dung][HP ███████][EN ████] [II]        [BOSS HP ──|──|──]   │
│                                              (combo x12)  [◎][◎] │ ← icon dự bị
│                                                                  │
│                         (gameplay)                               │
│                                                                  │
│                                              [Kĩ năng][Vũ khí]   │
│   (  joystick  )                        [Né]   [ĐÁNH]  [Tuyệt kỹ]│
│                                                   [Nhảy]         │
└──────────────────────────────────────────────────────────────────┘
```

- **Trên trái:** chân dung, thanh HP, thanh EN của nhân vật trên sân; nút
  Pause đặt cạnh thẻ này (xa icon dự bị).
- **Trên phải:** 2 icon dự bị — chân dung, thanh HP nhỏ, vòng SI-CD, vòng sáng
  Liên kết; vùng chạm ≥ 140 px; chạm để chuyển.
- **Combo counter:** dưới cụm icon dự bị, không đè lên chúng; mờ sau 2–3s không trúng.
- **Trên giữa:** thanh HP boss có vạch phase. Quái thường hiện thanh HP nhỏ khi bị đánh.
- **Dưới phải:** nút Đánh lớn nhất (~170 px; nhấn giữ = Nhấn giữ TC), Nhảy, Né,
  Kĩ năng, Vũ khí (vòng hồi + số giây), Tuyệt kỹ (vòng UG, sáng khi đầy).
- **Dưới trái:** joystick ảo (nổi trong nửa trái, có vùng chết; tùy chọn cố định).
- Số sát thương bay lên: màu theo nguyên tố, to hơn khi chí mạng.
- Tất cả vị trí, kích thước nằm trong một file theme/layout.

### Quy tắc cảm ứng (Android)

- Multitouch độc lập: ngón joystick không chặn nút.
- Vùng chạm tối thiểu 128 px (base 1920×1080); số liệu chốt sau khi thử máy thật.
- Không đặt phần tử HUD ở hai góc dưới ngoài nút điều khiển.
- Tôn trọng safe area / tai thỏ; màn 18:9 → 21:9 kéo dài nền, neo UI theo góc
  safe area; không kéo giãn UI, không viền đen.
- Bộ đệm input 100–150 ms cho đánh, nhảy, chuyển.
- Icon dự bị xa ngón cái: nếu thử máy thật thấy khó, thêm tùy chọn đổi vị trí (OD-6).

## 4. Vòng sáng Liên kết (README 17.5)

| Thuộc tính | Giá trị |
|---|---|
| Điều kiện hiện | Điều kiện Liên kết xảy ra trong 6.0s gần nhất **và** SI-CD đã hồi |
| Hiện | Fade in 150 ms + âm thanh ngắn |
| Nhịp | Chu kỳ 0.8s, scale 1.0 → 1.12, độ sáng 0.6 → 1.0, hạt nhỏ quay quanh |
| Đếm ngược | Cung mỏng co theo thời gian còn lại của cửa sổ 6.0s |
| Hết hạn | Fade out 300 ms |
| Khi dùng | Nổ sáng 200 ms |
| Nhiều icon | Hai icon có thể sáng cùng lúc |

Token màu placeholder (owner thay bằng art cuối):

| Nguyên tố | Token | Hex |
|---|---|---|
| Hỏa | `ring_fire` | `#FF6A3D` |
| Phong | `ring_wind` | `#3DDBB5` |
| Lôi | `ring_lightning` | `#FFD93D` |
| Quang | `ring_light` | `#FFF2B8` |
| Ám | `ring_dark` | `#A855F7` |
| Địa | `ring_earth` | `#D99A3E` |

## 5. Quy tắc UX

- **Mọi nút đều hoạt động.** Không nút giả, không menu giả. Mọi con số lấy từ state thật.
- Nhấn nút: thu nhỏ nhẹ + âm thanh.
- Tiêu tiền tệ (chiêu mộ, nâng cấp) cần bước xác nhận ghi rõ chi phí.
- Chữ không bị cắt: panel cuộn được; chừa 30–40% cho bản dịch (Anh, Việt, Trung).
- Chiêu mộ: tỉ lệ luôn cách một lần chạm, sinh từ config; pity luôn hiển thị;
  hoạt cảnh bỏ qua được; x10 hiện lưới kết quả; ghi rõ cách xử lý trùng.
- Chấm thông báo chỉ khi có thứ thật sự nhận được/chưa xem, tự tắt khi đã xem.
- Chip tiền tệ có nút `+` phải dẫn tới nơi hoạt động, nếu không thì ẩn.

## 6. Cảm giác chơi (giá trị khởi điểm, chỉnh trong config)

| Mục | Giá trị |
|---|---|
| Coyote time | 80–120 ms |
| Hit-stop mỗi đòn | 40–80 ms; phản ứng 60 ms |
| Tuyệt kỹ | trình diễn < ~1.5s |
| Switch-in | < ~1s; tên phản ứng hiện 0.8s |
| Telegraph boss | ≥ 0.4s |
| Camera | Follow mượt có look-ahead; khóa đấu trường khi gặp boss |
| Môi trường | Bóng tròn mềm dưới nhân vật, hạt môi trường theo chủ đề màn |
| Màn đầu | 3–5 phút, 2–3 đợt quái + boss, kết thúc ở màn kết quả |
