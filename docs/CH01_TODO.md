# Chương 1 — Việc cần làm và mô tả boss cuối (2026-11-15)

> Tổng hợp sau khi làm xong 10 ải Chương 1 và cốt truyện bản 2 (golem chỉ chặn đường, kẻ chủ mưu là tay sai đeo mặt nạ).
> Prompt ảnh chi tiết của mọi thứ dưới đây nằm trong `docs/prompts/ART_MASTER.md`.

## 1. Owner cần quyết / làm

| # | Việc | Vì sao cần | Gợi ý |
|---|---|---|---|
| 1 | **Chốt tên và hình dáng boss cuối** (mục 3 bên dưới) | Ảnh truyện `ch01_golem_07`, `ch01_end_01..04`, nền 1-8 và boss 1-10 đều vẽ theo nó | Trả lời "giữ thiết kế" hoặc ghi chỗ muốn đổi; có tên thì thoại thay "???" bằng tên |
| 2 | **Nhắn Codex chuyển sang kịch bản 39 ô** | Codex đang vẽ theo bản 29 ô cũ | Câu nhắn có trong `docs/prompts/story/CODEX_CH01_PANELS.md` |
| 3 | **Chạy Codex theo `ART_MASTER.md`, mỗi lần một lô** | 85 ảnh, ảnh sau tham chiếu ảnh trước | Thứ tự 7 lô ở mục 1 của file tổng; duyệt bằng từ khóa (`duyệt tay sai`, `duyệt nền 1-1`, `duyệt trang N`…) |
| 4 | **Mở Godot chơi thử 1-1 → 1-10** | Độ khó, số quái, thời gian mục tiêu mới chỉ đặt theo ước lượng | Chú ý 1-6 (nhiều hố), 1-9 (đợt cuối 6 quái), boss 1-10 |
| 5 | Xem lại cốt truyện 1-5 → 1-10 | Claude tự viết theo hướng owner chốt | Truyện từng màn ở đầu `tools/stages/gen_stages_01_05_10.py`; cần đổi thì báo |
| 6 | Duyệt ô truyện Codex đang vẽ | `assets/story/ch01/` có ảnh mới chưa commit (Codex đang làm) | Kiểm tra Codex đã chuyển sang kịch bản 39 ô (việc 2) trước khi duyệt tiếp |
| 7 | Nhắc lại: **làm lại Android trước M7** | Quyết định hoãn Android (2026-11-11) | Code vẫn giữ đa nền tảng |

## 2. Việc kỹ thuật còn lại (Claude / Codex làm được)

| # | Việc | Ghi chú |
|---|---|---|
| 1 | Commit 1-5 → 1-10 + boss + file tổng | Đang chờ lượt test toàn bộ |
| 2 | Animation thật cho boss tay sai (và golem) | Boss đang là hình tạm (`scenes/enemies/boss_henchman.tscn`); cần phiếu frame như nhân vật khi có bảng thiết kế |
| 3 | Thêm loại quái thường | Mới có Slime và Slime tro lớn; 10 ải khác nhau chủ yếu ở địa hình |
| 4 | "Ổ Cặn" (1-3), "cọc ấn" (1-5), "cột kênh" (1-8) là vật phá được | Hiện chỉ là đợt quái + thoại; có thể thêm vật thể có máu |
| 5 | Ảnh phủ vòng ấn trắng-đen trên ngực golem pha 2 | Từ kịch bản cũ D4/D5, vẫn hợp với bản mới |
| 6 | Chữ checkpoint "Đã cắm điểm neo" | Owner đã chốt (hàng 11), đã hiện trong game; kiểm tra lại khi có font chính thức |
| 7 | Cập nhật mục D1, D5, D6 trong `STORY_PROPOSAL.md` theo bản 2 | Hiện có ghi chú trỏ sang kịch bản đúng |
| 8 | Dọn khóa chữ cũ không dùng của `ch01_end` trong `.po` | Vô hại, chỉ cho gọn |
| 9 | Cân bằng lại số liệu sau khi owner chơi thử | Mọi số nằm trong `tools/stages/*.py` và `data/enemies/*.tres` |

## 3. Boss cuối Chương 1 — "Kẻ Đeo Mặt Nạ" (tên tạm)

### Vai trò trong truyện (canon owner 2026-11-15)

- Là **tay sai, người mặc giáp của một Quản lý**; Quản lý đó phục vụ **thủ lĩnh mã 00**. Ba tầng: tay sai → Quản lý → 00.
- Là **kẻ chủ mưu thật của Chương 1**: sai golem chặn cửa lò, lấp mạch lửa ngầm (1-3), lấp ống thông khí (1-4), cắm cọc ấn
  gọi Cặn (1-5), phá cầu thủ vệ (1-6), tháo lõi thủ vệ (1-7), dựng cột kênh hút nhiệt Lò Mẹ (1-8). Kế hoạch: tắt Lò Mẹ
  vào **đêm nhật thực đầy nhất**.
- Xuất hiện: đứng trên vách nhìn xuống rồi bỏ đi (clip cuối 1-1, ô `ch01_golem_07`) → đấu ở **cửa Lò Mẹ, đêm nhật thực**
  (1-10) → thua, **bị rút về kênh 00** (biến thành hạt sáng trắng-đen), làm rơi mảnh ấn thứ hai (clip `ch01_end`).
- Chưa có tên: thoại hiện "???". Tính cách: lạnh, bình thản, coi thường đối thủ ("Thắng một tay sai thì đã sao").

### Hình dáng (đề xuất, chờ owner chốt)

| Mục | Mô tả | Tiếng Anh cho prompt |
|---|---|---|
| Tuổi / giới | Người lớn, giới tính không rõ | adult suit-wearer, gender ambiguous |
| Dáng | Cao, gầy, vai rộng nhờ giáp; đứng hơi khom, bình thản | tall and lean, broad armored shoulders, calm slightly hunched stance |
| Giáp | Tấm giáp xám tro mờ; đường nối sáng **cam xỉn** như than sắp tắt; giáp vai lệch (vai trái to hơn) | dull ash-grey plated armor, seams glowing faint dim orange like dying embers, asymmetric pauldrons (left larger) |
| Mặt | **Mặt nạ đen trơn, không mắt, không miệng**; không bao giờ lộ mặt, kể cả khi giáp vỡ | smooth faceless black visor-mask, no eyes, no mouth, face never shown |
| Áo choàng | Màu than, rách mép, dài tới bắp chân | tattered charcoal-grey cloak to the calves |
| Huy hiệu | Vòng tròn nhỏ **nửa trắng nửa đen** trên ngực (cùng kiểu mảnh ấn kênh 00) | small half-white half-black ring emblem on the chest |
| Vũ khí | **Lưỡi móc** (glaive) cán dài màu đen, lưỡi cong như móc câu | long black glaive with a hooked curved blade |
| Hiệu ứng | Tro xám rỉ từ khe giáp khi ra đòn; pha 2 khe giáp sáng cam mạnh, tro cuộn quanh lưỡi móc | ash leaking from armor seams; phase 2: brighter orange seams, ash swirling around the glaive |
| Khi thua | Giáp nứt, bốc khói, quỳ một gối; tan thành hạt sáng trắng-đen | cracked smoking armor, kneeling, dissolving into black-and-white particles |
| Phân biệt | Kim loại phẳng, lạnh, gọn — khác Enkiba (đỏ cam, áo khoác) và golem (khối đá thô) | flat cold metal, sleek — unlike the rough stone golem |

### Trận đấu (ải 1-10, `data/enemies/boss_henchman_01.tres`)

| Pha | Khi nào | Đòn | Báo hiệu | Cách né |
|---|---|---|---|---|
| 1 | Từ đầu | **Chém quét** lưỡi móc: vùng rộng 360 px trước mặt, 140% ATK | 0.6 s | Lùi ra hoặc né hoàn hảo |
| 1 | Từ đầu | **Lao móc**: lao 460 px, 120% ATK | 0.55 s | Nhảy qua hoặc né |
| 2 | HP ≤ 50% (gầm chuyển pha 1.2 s) | **Sóng tro**: cắm lưỡi móc, hai sóng chạy hai phía 640 px, 130% ATK mỗi sóng | 0.8 s | Nhảy lên |
| 2 | HP ≤ 50% | Chém quét nhanh (150% ATK) / lao móc nhanh 520 px (130% ATK) | 0.45 s | Như pha 1, phản xạ nhanh hơn |

Chỉ số: HP 80000 · ATK 650 · DEF 420 · Sức choáng 1200 · tốc độ 170 (nhanh hơn golem: 60000 / 600 / 400 / 1000 / 130).

### Thoại

| Lúc | Người nói | Câu |
|---|---|---|
| Clip cuối 1-1 | ??? (trên vách) | "Thủ vệ chỉ để câu giờ. Báo với Quản lý: lò sẽ tắt đúng hẹn." |
| Vào trận 1-10 | Enkiba | "Ngươi sai golem, lấp mạch lửa, phá cầu. Hôm nay dừng ở đây!" |
| Vào trận (3 s sau) | NEO | "Giáp của hắn nhận lệnh qua kênh 00. Đánh vỡ giáp là cắt được kênh." |
| Chuyển pha 2 | NEO | "Giáp quá tải! Hắn đang dồn tro vào lưỡi móc." |
| Pha 2 | Kazeyumi | "Sóng tro chạy hai phía, nhảy lên!" |
| Clip kết chương | ??? (quỳ gối) | "Thắng một tay sai thì đã sao. Quản lý của ta chỉ cần lò này tắt một đêm." |

### Ảnh cần làm cho boss (prompt đầy đủ trong `docs/prompts/characters/HENCHMAN_DESIGN.md`)

1. Bảng thiết kế (trước, sau, nghiêng + cận mặt nạ, huy hiệu, lưỡi móc) — `assets/characters/boss_henchman_01/design/boss_henchman_01_sheet.png`, 1536×1024.
2. Chân dung bán thân — `assets/characters/boss_henchman_01/portrait/boss_henchman_01_portrait.png`, 1024×1024.
3. (Sau) frame animation: đứng, đi, chém quét, lao móc, sóng tro, chuyển pha, gục.
