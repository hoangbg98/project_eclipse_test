# Kiểm thử nghiệm thu

> Theo README mục 10. **Auto** = test GdUnit4 chạy headless. **Thủ công** =
> Claude chạy game và quan sát. **Owner** = cần máy Android thật hoặc kiểm
> tra bằng mắt; Claude không tự đánh dấu, owner cung cấp bằng chứng.
>
> Trạng thái: `NOT RUN`, `PASS`, `FAIL`, `BLOCKED`. Không đánh `PASS` nếu chưa
> có bằng chứng (lệnh, kết quả, ngày).

## Core

| ID | Tiêu chí | Cách kiểm | Trạng thái |
|---|---|---|---|
| AT-CORE-01 | Project mở trong Godot 4.6.3 không có lỗi chặn | Thủ công: chạy editor headless `--quit`, đọc log | NOT RUN |
| AT-CORE-02 | Scene chính nạp và chuyển cảnh đúng | Thủ công | NOT RUN |
| AT-CORE-03 | Input chạy trên nền tảng đích | Thủ công (PC) / Owner (Android) | NOT RUN |

## Người chơi và combat

| ID | Tiêu chí | Cách kiểm | Trạng thái |
|---|---|---|---|
| AT-PLY-01 | Di chuyển, nhảy, rơi, đáp nhất quán | Thủ công | NOT RUN |
| AT-PLY-02 | Nút tấn công kích hoạt đúng animation và hitbox | Auto + Thủ công | NOT RUN |
| AT-CMB-01 | Sát thương áp đúng một lần mỗi lần trúng hợp lệ | Auto | NOT RUN |
| AT-CMB-02 | Công thức sát thương khớp CombatRules (DEF, chí mạng, trần giảm DEF) | Auto | NOT RUN |
| AT-CMB-03 | HP, EN, UG, CD cập nhật đúng; CDR không vượt 40% | Auto | NOT RUN |
| AT-CMB-04 | Rút CD riêng không vượt trần mỗi chu kỳ | Auto | NOT RUN |
| AT-CMB-05 | Hành động không hợp lệ bị từ chối an toàn (thiếu EN, đang CD…) | Auto | NOT RUN |
| AT-CMB-06 | Trạng thái: thời lượng, làm mới, tick, kháng Choáng 8s | Auto | NOT RUN |

## Đội

| ID | Tiêu chí | Cách kiểm | Trạng thái |
|---|---|---|---|
| AT-PTY-01 | Cấu hình được 3 slot | Auto | NOT RUN |
| AT-PTY-02 | Chỉ một người trên sân; dự bị không hành động, không nhận input | Auto + Thủ công | NOT RUN |
| AT-PTY-03 | Icon dự bị hiển thị HP và vòng SI-CD | Thủ công | NOT RUN |
| AT-PTY-04 | Vòng sáng chỉ hiện khi điều kiện xảy ra trong 6.0s **và** SI-CD đã hồi | Auto | NOT RUN |
| AT-PTY-05 | Chuyển Liên kết sinh đúng phản ứng cho cả 15 cặp; ICD 5.0s được tôn trọng | Auto | NOT RUN |
| AT-PTY-06 | Bảng phản ứng có đủ 15 cặp, không thiếu, không trùng | Auto | NOT RUN |
| AT-PTY-07 | Chuyển Thường không sinh phản ứng; switch-in trượt không sinh phản ứng sát thương | Auto | NOT RUN |
| AT-PTY-08 | Khóa chuyển trong tuyệt kỹ chuỗi đòn và với nhân vật đã gục; chờ chung 1.0s | Auto | NOT RUN |
| AT-PTY-09 | Dự bị: EN +1/s, nhận 30% UG; timer cá nhân vẫn chạy | Auto | NOT RUN |

## Kẻ địch và boss

| ID | Tiêu chí | Cách kiểm | Trạng thái |
|---|---|---|---|
| AT-ENM-01 | Quái phát hiện và giao chiến theo cấu hình AI | Thủ công | NOT RUN |
| AT-ENM-02 | Sát thương, hạ gục, phần thưởng của quái | Auto + Thủ công | NOT RUN |
| AT-BOS-01 | Boss chuyển phase đúng điều kiện | Auto | NOT RUN |
| AT-BOS-02 | Telegraph boss ≥ 0.4s, đọc được ở cỡ điện thoại | Owner | NOT RUN |

## Tiến trình và chiêu mộ

| ID | Tiêu chí | Cách kiểm | Trạng thái |
|---|---|---|---|
| AT-PRG-01 | Lên cấp cập nhật chỉ số đúng | Auto | NOT RUN |
| AT-PRG-02 | Thay đổi kho đồ và trang bị được lưu | Auto | NOT RUN |
| AT-GCH-01 | Chiêu mộ trừ đúng tài nguyên | Auto | BLOCKED (chờ config banner) |
| AT-GCH-02 | Tỉ lệ, pity, rate-up, bảo hiểm qua test có seed | Auto | BLOCKED (chờ config banner) |
| AT-GCH-03 | Lịch sử chiêu mộ lưu và nạp đúng | Auto | NOT RUN |
| AT-GCH-04 | Bảng tỉ lệ hiển thị sinh từ cùng config với logic quay | Auto | NOT RUN |

## Save và nền tảng

| ID | Tiêu chí | Cách kiểm | Trạng thái |
|---|---|---|---|
| AT-SAV-01 | Save/load giữ nguyên state cần thiết | Auto | NOT RUN |
| AT-SAV-02 | Save hỏng hoặc cũ được xử lý không crash (backup/migration) | Auto | NOT RUN |
| AT-PLT-01 | Điều khiển Windows (bàn phím, tay cầm) | Thủ công | NOT RUN |
| AT-PLT-02 | Điều khiển cảm ứng trên máy Android thật | Owner | NOT RUN |
| AT-PLT-03 | UI dùng được ở các tỉ lệ ngang 16:9 → 21:9, tôn trọng safe area | Thủ công + Owner | NOT RUN |
| AT-ANM-01 | Số PNG trong mỗi thư mục frame = `frames` trong manifest | Auto | NOT RUN |

## Checklist tự chơi (README 16)

Start → hub → chọn màn → chọn đội → chiến đấu (di chuyển, nhảy, đánh, kỹ năng,
chuyển người, nhận sát thương, hạ quái) → boss 2 phase → kết quả + thưởng →
chiêu mộ → lưu → thoát → mở lại → tiếp tục với tiến trình còn nguyên.
Trạng thái: NOT RUN.

Tiêu chí của các tính năng hoãn (README 2.3) không chặn bản đầu.
