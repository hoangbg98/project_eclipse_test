# Tổng hợp prompt tạo ảnh game — PROJECT ECLIPSE

> Sinh bởi `tools/prompts/build_art_master.py` lúc 2026-11-17 — **không sửa tay**: sửa tài liệu gốc (đường dẫn ghi ở
> đầu mỗi phần) rồi chạy lại công cụ. Một file duy nhất để đưa cho Codex / ChatGPT tạo toàn bộ ảnh Chương 1.
> Ảnh AI được dùng trong bản phát hành (owner 2026-11-12) nhưng **mỗi file phải ghi vào `docs/ASSET_LICENSES.md`
> mục 2.1** trước khi commit; khai báo nội dung AI trên store.

## Mục lục

1. Cách dùng + prompt chính gửi Codex
2. Kinh thánh phong cách (style bible) và khóa nhân vật
3. Dòng thời gian liền mạch Chương 1 (trạng thái từng màn)
4. Danh sách ảnh cần làm (85 ảnh, 8 đã có)
5. Phần A — Thiết kế nhân vật mới (Kẻ Đeo Mặt Nạ)
6. Phần B — Truyện tranh Chương 1 (ô truyện)
7. Phần C — Tranh map chương và thẻ chương
8. Phần D — Ảnh nền màn chơi (1-1 → 1-10)

## 1. Cách dùng

**Thứ tự làm** (ảnh sau dùng ảnh trước làm tham chiếu, nên đừng đảo):

| Lô | Nội dung | Lý do đứng ở đây | Từ khóa duyệt |
|---|---|---|---|
| 1 | Phần A: bảng thiết kế + chân dung Kẻ Đeo Mặt Nạ | Ô truyện và nền 1-8 cần tham chiếu hắn | `duyệt tay sai` |
| 2 | Phần D: nền 1-1 rồi 1-2 (thung lũng, Lò Mẹ lạnh) | Đặt bảng màu, Mặt Trời Khuyết, dáng Lò Mẹ cho mọi ảnh sau | `duyệt nền 1-1`, `duyệt nền 1-2` |
| 3 | Phần B: ô truyện `ch01_open` (15 ô) | Mở chương | `duyệt trang N` |
| 4 | Phần B: ô truyện `ch01_golem` (10 ô) | Cuối 1-1, lần đầu thấy tay sai | `duyệt trang N` |
| 5 | Phần D: nền 1-3 → 1-9 theo thứ tự | Mỗi màn tham chiếu màn trước | `duyệt nền 1-X` |
| 6 | Phần D: nền 1-10 + Phần B: ô `ch01_end` (14 ô) | Cùng nơi (cửa lò), làm liền để khớp | `duyệt nền 1-10`, `duyệt trang N` |
| 7 | Phần C: tranh map + thẻ Chương 1 | Tổng hợp cảnh đã chốt | `duyệt map 1` |

**Prompt chính gửi Codex** (đã liên kết dự án; dán nguyên khối):

```text
Việc: tạo ảnh game theo docs/prompts/ART_MASTER.md, làm theo bảng "Thứ tự làm" (mục 1), mỗi lần MỘT lô.
Đọc trước: AGENTS.md (mục 4 "Ảnh do AI tạo"), mục 2 và 3 của ART_MASTER.md (style bible, khóa nhân vật, dòng thời
gian liền mạch). Mục 4 liệt kê từng file cần làm, đường dẫn, kích thước và trạng thái; bỏ qua file đã "✅ đã có".
Với mỗi lô:
1. Tạo ảnh bằng image_gen. Luôn đính kèm ảnh tham chiếu nhân vật ghi ở từng prompt và ảnh đã duyệt của lô / ô / lớp
   liền trước (cùng cảnh). Thêm vào prompt câu nối liền mạch lấy từ mục 3 (giờ trong ngày, Lò Mẹ lạnh/cháy, gió,
   độ che của Mặt Trời Khuyết).
2. Chép ảnh gốc vào art_review/<loại>/<id>/raw/ (art_review không vào git). Cắt / co đúng kích thước ở mục 4; ô truyện
   giữ chủ thể trong vùng xám của placeholder; nền lặp ngang liền mạch, mid/near giữ alpha.
3. Ghép ảnh xem trước vào art_review/.../_preview/ (trang truyện 1920x1080 đặt ô theo đa giác; nền ghép 3 lớp lặp 2
   lần). DỪNG, gửi tôi đường dẫn preview, chờ từ khóa duyệt của lô (cột cuối bảng).
4. Khi tôi duyệt: chép vào đúng đường dẫn ở mục 4 (không ghi đè file đã có: tạo -v2 và hỏi), chạy
   C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import, ghi từng file vào
   docs/ASSET_LICENSES.md mục 2.1, chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0),
   chạy python -X utf8 -I tools/prompts/build_art_master.py (cập nhật trạng thái), ghi docs/DEVELOPMENT_LOG.md,
   commit (không push). Rồi mới sang lô kế.
Không vẽ chữ, bóng thoại, viền ô, logo, watermark. Không bắt chước nhân vật / thương hiệu bên thứ ba.
Trả lời tôi bằng tiếng Việt.
```

Không dùng Codex: mỗi phần bên dưới có prompt dán thẳng vào ChatGPT và mục "Thay tay" (đặt file đúng tên rồi
`--import`). Game tự thay placeholder khi có ảnh thật, không cần sửa code.

## 2. Style bible và khóa nhân vật

**Phong cách chung:** anime 2D, nét sạch, cel shading 2–3 tông, ánh sáng điện ảnh, hơi giảm bão hòa; tỉ lệ nhân vật
anime chuẩn (không chibi). Thế giới dưới **Mặt Trời Khuyết**: mặt trời cam nhạt bị khuyết một mảng tối. Không chữ,
không logo, không watermark. Nền màn chơi: vẽ phẳng nhìn ngang, đường chân trời ~60%, tương phản thấp để nhân vật nổi.

| Nhân vật | Khóa thiết kế | Ảnh tham chiếu trong dự án |
|---|---|---|
| Enkiba (lửa, kiếm) | Nam 16–19, tóc gai đỏ cam, mắt hổ phách, áo khoác ngắn đen viền lửa đỏ, giáp vai đỏ, áo trắng, quần đỏ, kiếm lưỡi cam vân lửa | `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png` |
| Kazeyumi (gió, cung) | Nữ 16–19, tóc xanh ngọc buộc cao có lông vũ trắng, áo kem viền xanh, áo choàng ngắn xanh đậm, váy xếp ly, ống tên, cung gỗ quấn ruy băng | `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png` |
| Raikiba (sét, song dao) | Nam 16–19, tóc gai trắng bạc ánh vàng chanh, mắt xanh lục, áo cổ cao không tay xanh navy, quần túi hộp sọc vàng, găng hở ngón, hai dao cong răng cưa đen-vàng | `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png` |
| NEO | Thiết bị AI nhỏ bằng bàn tay: vòng sáng cyan quanh lõi trắng, hai cung mảnh xoay, không mặt, không tay chân | (mô tả trong prompt) |
| Kẻ Đeo Mặt Nạ (tay sai, boss 1-10) | Giáp xám tro đường nối cam xỉn, mặt nạ đen trơn không mắt miệng, áo choàng than rách, huy hiệu vòng trắng-đen, lưỡi móc đen | Phần A (vẽ trước) |
| Golem Đá Cổ (boss 1-1) | Khối đá khổng lồ, khe nứt sáng nhẹ, hai mắt cam đỏ; khi đổ thành đá vỡ nằm trước cửa lò tới hết chương | ô truyện `ch01_open_10`, `ch01_golem_01` |
| Cặn tro (quái) | Khối tro xám nhỏ như slime, đốm than li ti; Cặn lớn: to, nâu xám, nặng nề | ô truyện `ch01_open_12` |
| Dấu ba vòng đá | Ba vòng đá chồng nhau khắc nổi (dấu xưởng thủ vệ) — giống nhau ở lưng golem, hầm 1-3, cầu 1-6, trạm 1-7 | ô truyện `ch01_end_11` |
| Vòng trắng-đen (kênh 00) | Vòng nửa trắng nửa đen — mảnh ấn trong golem, cọc ấn 1-5, cột kênh 1-8, huy hiệu tay sai | ô truyện `ch01_golem_05/06` |

## 3. Dòng thời gian liền mạch Chương 1

Cốt truyện (owner 2026-11-15): golem ở 1-1 chỉ là thủ vệ bị sai tới chặn đường; kẻ chủ mưu là **tay sai đeo mặt nạ**
(người mặc giáp của một Quản lý dưới trướng thủ lĩnh mã 00); Lò Mẹ chỉ cháy lại sau khi hạ hắn ở 1-10.

| Đoạn | Nơi | Giờ | Lò Mẹ | Gió / tro | Mặt Trời Khuyết | Ghi chú liền mạch |
|---|---|---|---|---|---|---|
| Clip `ch01_open` | Cửa thung lũng | Chiều mù | Lạnh tối | Không gió, tro rơi thẳng | Khuyết như thường | Vạch mờ tím Vùng Thực |
| 1-1 (boss golem) | Thung lũng → cửa lò | Chiều | Lạnh | Không gió | Như thường | — |
| Clip `ch01_golem` | Cửa lò | Chiều muộn | **Lạnh** | Không gió | Như thường | Golem đổ thành đá vỡ; đĩa trắng-đen thứ nhất; tay sai trên vách |
| 1-2 Làng Lò Than | Cửa thung lũng | Chiều muộn | Lạnh | Không gió | Như thường | Đèn, khói bếp le lói |
| 1-3 Hầm Than Ngầm | Dưới làng | (trong hầm) | Lạnh | — | — | Mạch lửa bị lấp đá mới; dấu ba vòng đá |
| 1-4 Vách Lò Mẹ | Vách cao | Chiều muộn | Lạnh | Không gió, cờ rủ | Như thường | Ống thông khí bị lấp |
| 1-5 Rừng Cây Chết | Sườn trên vách | Hoàng hôn sớm | Lạnh | Không gió | Che hơn một chút | Cọc ấn vòng trắng-đen |
| 1-6 Cầu Đá Treo | Vực cao | Hoàng hôn | Lạnh | Không gió | Che hơn | Cầu bị phá, dấu ba vòng đá |
| 1-7 Trạm Thủ Vệ | Trong trạm | (trong nhà) | — | — | — | Hốc lõi trống, vết cạy mới |
| 1-8 Trại Mặt Nạ | Hẻm đá | Chạng vạng tím | Bị hút nhiệt | Không gió | Che **nhiều** | Cột kênh trắng-đen; lưỡi móc đen |
| 1-9 Đường Về Cửa Lò | Đường mòn | **Đêm** | Gần tắt (4%) | Không gió, sương tím | Gần đầy (vành mảnh) | Thấy bóng người ở cửa lò |
| 1-10 Cửa Lò Mẹ (boss tay sai) | Cửa lò | **Đêm nhật thực** | 2% | Không gió | Vành sáng mảnh | Đá vỡ golem như clip `ch01_golem` |
| Clip `ch01_end` | Cửa lò → vách đá | Đêm | **Cháy lại** từ ô 05–06 | **Gió về** từ ô 07 | Vành sáng | Hai đĩa trắng-đen; ô 14 bóng Quản lý trên vách |

## 4. Danh sách ảnh cần làm

### Phần A — nhân vật

| Ảnh | File | Kích thước | Trạng thái |
|---|---|---|---|
| Bảng thiết kế | assets/characters/boss_henchman_01/design/boss_henchman_01_sheet.png | 1536×1024 | ✅ đã có |
| Chân dung | assets/characters/boss_henchman_01/portrait/boss_henchman_01_portrait.png | 1024×1024 | ✅ đã có |

### Phần B — ô truyện (39 ô)

| Ô | File | Kích thước (1×, 2×) | Cảnh | Trạng thái |
|---|---|---|---|---|
| ch01_end_01 | assets/story/ch01/ch01_end_01.png | 1840×420 (2×: 3680×840) | Trước cửa Lò Mẹ lạnh tối; kẻ đeo mặt nạ quỳ gối, giáp nứt vỡ; Enkiba chĩa kiếm. | ⬜ chưa có |
| ch01_end_02 | assets/story/ch01/ch01_end_02.png | 1840×416 (2×: 3680×832) | Raikiba và Kazeyumi hiện ra từ hạt sáng; Raikiba ngồi phịch xuống. | ⬜ chưa có |
| ch01_end_03 | assets/story/ch01/ch01_end_03.png | 1260×760 (2×: 2520×1520) | Kẻ đeo mặt nạ ngẩng lên cười khẩy; Kazeyumi giương cung. | ⬜ chưa có |
| ch01_end_04 | assets/story/ch01/ch01_end_04.png | 956×760 (2×: 1912×1520) | Kẻ đeo mặt nạ tan thành hạt sáng trắng đen, bị kéo đi; Enkiba vươn tay chụp hụt. | ⬜ chưa có |
| ch01_end_05 | assets/story/ch01/ch01_end_05.png | 1120×620 (2×: 2240×1240) | Kiếm bén lửa của Enkiba chạm vào miệng lò. | ⬜ chưa có |
| ch01_end_06 | assets/story/ch01/ch01_end_06.png | 1840×760 (2×: 3680×1520) | Lò Mẹ bùng cháy rực rỡ, đốm lửa bay lên; Raikiba nhảy cẫng lên. | ⬜ chưa có |
| ch01_end_07 | assets/story/ch01/ch01_end_07.png | 1120×620 (2×: 2240×1240) | Kazeyumi mỉm cười, đốm lửa bay ngang theo gió vừa trở lại. | ⬜ chưa có |
| ch01_end_08 | assets/story/ch01/ch01_end_08.png | 720×760 (2×: 1440×1520) | Raikiba giơ hai chiếc đĩa trắng đen: một từ golem, một hắn đánh rơi. | ⬜ chưa có |
| ch01_end_09 | assets/story/ch01/ch01_end_09.png | 1126×380 (2×: 2252×760) | Cận hai chiếc đĩa; NEO lại gần, vòng sáng nhiễu loạn. | ⬜ chưa có |
| ch01_end_10 | assets/story/ch01/ch01_end_10.png | 1156×396 (2×: 2312×792) | Enkiba nghiêm mặt, siết chuôi kiếm. | ⬜ chưa có |
| ch01_end_11 | assets/story/ch01/ch01_end_11.png | 1840×380 (2×: 3680×760) | Tấm giáp lưng golem lật lên: dấu khắc ba vòng đá chồng nhau. | ⬜ chưa có |
| ch01_end_12 | assets/story/ch01/ch01_end_12.png | 960×387 (2×: 1920×774) | Raikiba nhét hai chiếc đĩa vào túi, cười. | ⬜ chưa có |
| ch01_end_13 | assets/story/ch01/ch01_end_13.png | 916×416 (2×: 1832×832) | Enkiba nhìn lại Lò Mẹ đang cháy rồi quay đi. | ⬜ chưa có |
| ch01_end_14 | assets/story/ch01/ch01_end_14.png | 1840×760 (2×: 3680×1520) | Đêm, đỉnh vách đá trên thung lũng; Lò Mẹ cháy sáng phía dưới; một bóng người cầm vòng sáng trắng đen giống Neo (Quản lý của tay sai). | ⬜ chưa có |
| ch01_golem_01 | assets/story/ch01/ch01_golem_01.png | 1840×420 (2×: 3680×840) | Golem đổ sụp thành từng khối đá trước cửa Lò Mẹ lạnh tối; Enkiba thở dốc, kiếm hạ xuống. | ⬜ chưa có |
| ch01_golem_02 | assets/story/ch01/ch01_golem_02.png | 1840×416 (2×: 3680×832) | Raikiba và Kazeyumi hiện ra từ hạt sáng; Raikiba ngồi phịch xuống, Kazeyumi nhìn lên lò. | ⬜ chưa có |
| ch01_golem_03 | assets/story/ch01/ch01_golem_03.png | 1260×760 (2×: 2520×1520) | Enkiba ngước nhìn cửa lò vẫn lạnh ngắt; NEO lơ lửng bên cạnh, ánh xanh nhạt. | ⬜ chưa có |
| ch01_golem_04 | assets/story/ch01/ch01_golem_04.png | 956×760 (2×: 1912×1520) | Kazeyumi quỳ một gối, đặt tay lên đầu đá của golem. | ⬜ chưa có |
| ch01_golem_05 | assets/story/ch01/ch01_golem_05.png | 720×760 (2×: 1440×1520) | Raikiba nhặt từ đống đá một chiếc đĩa nhỏ phát sáng trắng đen. | ⬜ chưa có |
| ch01_golem_06 | assets/story/ch01/ch01_golem_06.png | 1126×380 (2×: 2252×760) | Cận chiếc đĩa; NEO lại gần, vòng sáng nhiễu loạn. | ⬜ chưa có |
| ch01_golem_07 | assets/story/ch01/ch01_golem_07.png | 1156×396 (2×: 2312×792) | Enkiba nghiêm mặt, siết chuôi kiếm, cửa lò lạnh phía sau. | ⬜ chưa có |
| ch01_golem_08 | assets/story/ch01/ch01_golem_08.png | 1840×380 (2×: 3680×760) | Trên đỉnh vách phía trên Lò Mẹ, một kẻ mặc giáp xám tro, mặt nạ đen trơn, đứng nhìn xuống rồi quay lưng. | ⬜ chưa có |
| ch01_golem_09 | assets/story/ch01/ch01_golem_09.png | 960×387 (2×: 1920×774) | Raikiba bật dậy chỉ tay lên vách. | ⬜ chưa có |
| ch01_golem_10 | assets/story/ch01/ch01_golem_10.png | 916×416 (2×: 1832×832) | Enkiba nhìn theo, quyết tâm; NEO sáng đỏ cảnh báo. | ⬜ chưa có |
| ch01_open_01 | assets/story/ch01/ch01_open_01.png | 1840×380 (2×: 3680×760) | Toàn cảnh cửa thung lũng xám tro, đường dốc xuống, tro rơi thẳng đứng; Mặt Trời Khuyết trên trời; cuối thung lũng là vách đá có cửa lò khổng lồ tối om. | ✅ đã có |
| ch01_open_02 | assets/story/ch01/ch01_open_02.png | 960×387 (2×: 1920×774) | Raikiba phanh trượt ngay trước vạch mờ tím, chồm người nhìn vào, ngạc nhiên. | ✅ đã có |
| ch01_open_03 | assets/story/ch01/ch01_open_03.png | 916×416 (2×: 1832×832) | Kazeyumi giơ một tay dò gió, nét mặt nghiêm; tro rơi thẳng quanh cô. | ✅ đã có |
| ch01_open_04 | assets/story/ch01/ch01_open_04.png | 720×760 (2×: 1440×1520) | Enkiba đứng cạnh biển gỗ cháy xém chỉ về làng; đốm than cuối cùng trên biển vừa tắt. | ⬜ chưa có |
| ch01_open_05 | assets/story/ch01/ch01_open_05.png | 1126×380 (2×: 2252×760) | Raikiba quay sang Enkiba, nhướng mày. | ⬜ chưa có |
| ch01_open_06 | assets/story/ch01/ch01_open_06.png | 1156×396 (2×: 2312×792) | Cận mặt Enkiba nhìn xa, lo lắng, ánh tro phản chiếu trong mắt. | ⬜ chưa có |
| ch01_open_07 | assets/story/ch01/ch01_open_07.png | 1120×620 (2×: 2240×1240) | NEO trồi lên lơ lửng phía trước, vòng sáng xoay; ba người nhìn vào nó. | ⬜ chưa có |
| ch01_open_08 | assets/story/ch01/ch01_open_08.png | 1840×760 (2×: 3680×1520) | Kazeyumi nghiêm mặt; Raikiba gãi đầu, giọt mồ hôi. | ⬜ chưa có |
| ch01_open_09 | assets/story/ch01/ch01_open_09.png | 1120×620 (2×: 2240×1240) | Kazeyumi quay ra phía người xem (Quản lý), NEO lơ lửng bên cạnh. | ⬜ chưa có |
| ch01_open_10 | assets/story/ch01/ch01_open_10.png | 1260×760 (2×: 2520×1520) | Cuối thung lũng: trong bóng tối trước cửa Lò Mẹ, hai đốm mắt cam đỏ sáng lên trên một khối đá khổng lồ. | ⬜ chưa có |
| ch01_open_11 | assets/story/ch01/ch01_open_11.png | 956×760 (2×: 1912×1520) | Kazeyumi nheo mắt nhìn về cuối thung lũng. | ⬜ chưa có |
| ch01_open_12 | assets/story/ch01/ch01_open_12.png | 900×384 (2×: 1800×768) | Những khối tro xám nhỏ trồi lên, nảy về phía cuối thung lũng; Raikiba chỉ tay. | ⬜ chưa có |
| ch01_open_13 | assets/story/ch01/ch01_open_13.png | 931×363 (2×: 1862×726) | Enkiba bước tới vạch mờ, giơ kiếm, lưỡi kiếm bén lửa. | ⬜ chưa có |
| ch01_open_14 | assets/story/ch01/ch01_open_14.png | 884×372 (2×: 1768×744) | NEO sáng cam đều, như gật đầu. | ⬜ chưa có |
| ch01_open_15 | assets/story/ch01/ch01_open_15.png | 952×392 (2×: 1904×784) | Kazeyumi và Raikiba tan thành hạt sáng xanh ngọc và vàng, bay vào NEO. | ⬜ chưa có |

### Phần C — map và thẻ chương

| Ảnh | File | Kích thước | Trạng thái |
|---|---|---|---|
| Ch.1 map | assets/story/chapters/map_ch01.png | 3240×1080 | ⬜ chưa có |
| Ch.1 thẻ | assets/story/chapters/card_ch01.png | 380×600 | ⬜ chưa có |
| Ch.2 map | assets/story/chapters/map_ch02.png | 3800×1080 | ⬜ chưa có |
| Ch.2 thẻ | assets/story/chapters/card_ch02.png | 380×600 | ⬜ chưa có |
| Ch.3 map | assets/story/chapters/map_ch03.png | 4640×1080 | ⬜ chưa có |
| Ch.3 thẻ | assets/story/chapters/card_ch03.png | 380×600 | ⬜ chưa có |
| Ch.4 map | assets/story/chapters/map_ch04.png | 6400×1080 | ⬜ chưa có |
| Ch.4 thẻ | assets/story/chapters/card_ch04.png | 380×600 | ⬜ chưa có |
| Ch.5 map | assets/story/chapters/map_ch05.png | 7520×1080 | ⬜ chưa có |
| Ch.5 thẻ | assets/story/chapters/card_ch05.png | 380×600 | ⬜ chưa có |
| Ch.6 map | assets/story/chapters/map_ch06.png | 8080×1080 | ⬜ chưa có |
| Ch.6 thẻ | assets/story/chapters/card_ch06.png | 380×600 | ⬜ chưa có |
| Ch.7 map | assets/story/chapters/map_ch07.png | 9200×1080 | ⬜ chưa có |
| Ch.7 thẻ | assets/story/chapters/card_ch07.png | 380×600 | ⬜ chưa có |

### Phần D — nền màn chơi (3840×2160, lặp ngang)

| Màn | Lớp | File | Trạng thái |
|---|---|---|---|
| 1-1 | bg_stage_01_far.png | assets/backgrounds/stages/stage_01/bg_stage_01_far.png | ✅ đã có |
| 1-1 | bg_stage_01_mid.png | assets/backgrounds/stages/stage_01/bg_stage_01_mid.png | ✅ đã có |
| 1-1 | bg_stage_01_near.png | assets/backgrounds/stages/stage_01/bg_stage_01_near.png | ✅ đã có |
| 1-2 | bg_stage_01_02_far.png | assets/backgrounds/stages/stage_01_02/bg_stage_01_02_far.png | ⬜ chưa có |
| 1-2 | bg_stage_01_02_mid.png | assets/backgrounds/stages/stage_01_02/bg_stage_01_02_mid.png | ⬜ chưa có |
| 1-2 | bg_stage_01_02_near.png | assets/backgrounds/stages/stage_01_02/bg_stage_01_02_near.png | ⬜ chưa có |
| 1-3 | bg_stage_01_03_far.png | assets/backgrounds/stages/stage_01_03/bg_stage_01_03_far.png | ⬜ chưa có |
| 1-3 | bg_stage_01_03_mid.png | assets/backgrounds/stages/stage_01_03/bg_stage_01_03_mid.png | ⬜ chưa có |
| 1-3 | bg_stage_01_03_near.png | assets/backgrounds/stages/stage_01_03/bg_stage_01_03_near.png | ⬜ chưa có |
| 1-4 | bg_stage_01_04_far.png | assets/backgrounds/stages/stage_01_04/bg_stage_01_04_far.png | ⬜ chưa có |
| 1-4 | bg_stage_01_04_mid.png | assets/backgrounds/stages/stage_01_04/bg_stage_01_04_mid.png | ⬜ chưa có |
| 1-4 | bg_stage_01_04_near.png | assets/backgrounds/stages/stage_01_04/bg_stage_01_04_near.png | ⬜ chưa có |
| 1-5 | bg_stage_01_05_far.png | assets/backgrounds/stages/stage_01_05/bg_stage_01_05_far.png | ⬜ chưa có |
| 1-5 | bg_stage_01_05_mid.png | assets/backgrounds/stages/stage_01_05/bg_stage_01_05_mid.png | ⬜ chưa có |
| 1-5 | bg_stage_01_05_near.png | assets/backgrounds/stages/stage_01_05/bg_stage_01_05_near.png | ⬜ chưa có |
| 1-6 | bg_stage_01_06_far.png | assets/backgrounds/stages/stage_01_06/bg_stage_01_06_far.png | ⬜ chưa có |
| 1-6 | bg_stage_01_06_mid.png | assets/backgrounds/stages/stage_01_06/bg_stage_01_06_mid.png | ⬜ chưa có |
| 1-6 | bg_stage_01_06_near.png | assets/backgrounds/stages/stage_01_06/bg_stage_01_06_near.png | ⬜ chưa có |
| 1-7 | bg_stage_01_07_far.png | assets/backgrounds/stages/stage_01_07/bg_stage_01_07_far.png | ⬜ chưa có |
| 1-7 | bg_stage_01_07_mid.png | assets/backgrounds/stages/stage_01_07/bg_stage_01_07_mid.png | ⬜ chưa có |
| 1-7 | bg_stage_01_07_near.png | assets/backgrounds/stages/stage_01_07/bg_stage_01_07_near.png | ⬜ chưa có |
| 1-8 | bg_stage_01_08_far.png | assets/backgrounds/stages/stage_01_08/bg_stage_01_08_far.png | ⬜ chưa có |
| 1-8 | bg_stage_01_08_mid.png | assets/backgrounds/stages/stage_01_08/bg_stage_01_08_mid.png | ⬜ chưa có |
| 1-8 | bg_stage_01_08_near.png | assets/backgrounds/stages/stage_01_08/bg_stage_01_08_near.png | ⬜ chưa có |
| 1-9 | bg_stage_01_09_far.png | assets/backgrounds/stages/stage_01_09/bg_stage_01_09_far.png | ⬜ chưa có |
| 1-9 | bg_stage_01_09_mid.png | assets/backgrounds/stages/stage_01_09/bg_stage_01_09_mid.png | ⬜ chưa có |
| 1-9 | bg_stage_01_09_near.png | assets/backgrounds/stages/stage_01_09/bg_stage_01_09_near.png | ⬜ chưa có |
| 1-10 | bg_stage_01_10_far.png | assets/backgrounds/stages/stage_01_10/bg_stage_01_10_far.png | ⬜ chưa có |
| 1-10 | bg_stage_01_10_mid.png | assets/backgrounds/stages/stage_01_10/bg_stage_01_10_mid.png | ⬜ chưa có |
| 1-10 | bg_stage_01_10_near.png | assets/backgrounds/stages/stage_01_10/bg_stage_01_10_near.png | ⬜ chưa có |


## 5. Phần A — Thiết kế nhân vật mới

> Nguồn: `docs/prompts/characters/HENCHMAN_DESIGN.md`

### Thiết kế "Kẻ Đeo Mặt Nạ" (tay sai, boss ải 1-10)

> Cốt truyện owner 2026-11-15: kẻ chủ mưu Chương 1 là **tay sai (người mặc giáp) của một Quản lý dưới trướng thủ lĩnh
> mã 00**. Chưa có tên (thoại hiện "???", tên boss tạm "Kẻ Đeo Mặt Nạ"). Hình dưới đây là **đề xuất của Claude**;
> owner đổi được — sửa cả `CHAR_DESC["henchman"]` trong `tools/story/gen_story_clips.py` rồi chạy lại.
> Vẽ thiết kế này **trước** các ô truyện có hắn (`ch01_golem_07`, `ch01_end_01..04`) và nền 1-8: các ảnh đó đính kèm
> bản thiết kế đã duyệt làm tham chiếu.

#### Khóa thiết kế

| Mục | Mô tả |
|---|---|
| Dáng | Cao, gầy, vai rộng nhờ giáp; đứng hơi khom, bình thản, không bao giờ vội |
| Giáp | Tấm giáp xám tro (ash-grey) mờ, đường nối **cam xỉn** như than sắp tắt; giáp vai bất đối xứng (vai trái to hơn) |
| Mặt | **Mặt nạ đen trơn, không mắt, không miệng** — không bao giờ lộ mặt, kể cả khi giáp vỡ (end_01..04) |
| Áo choàng | Màu than, rách mép, dài tới bắp chân |
| Huy hiệu | Vòng tròn nhỏ **nửa trắng nửa đen** trên ngực (cùng kiểu mảnh ấn kênh 00) |
| Vũ khí | **Lưỡi móc** (glaive) cán dài đen, lưỡi cong như móc câu |
| Hiệu ứng | Tro xám rỉ ra từ khe giáp khi ra đòn; pha 2: khe giáp sáng cam mạnh hơn, tro cuộn quanh lưỡi móc |
| Phân biệt | Không giống Enkiba (đỏ cam, áo khoác) hay golem (khối đá thô): kim loại phẳng, lạnh, gọn |

#### Bảng thiết kế — `assets/characters/boss_henchman_01/design/boss_henchman_01_sheet.png`

Tạo 1536×1024 (ngang). Ảnh AI phải ghi vào `docs/ASSET_LICENSES.md` mục 2.1.

```text
Original character design sheet for PROJECT ECLIPSE, an anime-style 2D action RPG. Clean anime line art, cel shading
with 2-3 tones, neutral light grey background, no text, no logo, no watermark.
Character: "the masked henchman", an adult suit-wearer (gender ambiguous), tall and lean, broad armored shoulders,
calm slightly hunched stance. Dull ash-grey plated armor with seams glowing a faint dim orange like dying embers,
asymmetric pauldrons (left larger), a smooth faceless black visor-mask with no eyes and no mouth, a tattered
charcoal-grey cloak reaching the calves, a small half-white half-black ring emblem on the chest. Weapon: a long
black glaive with a hooked curved blade.
Show: full body front view, full body side view, full body back view, plus a close-up of the mask and the chest
emblem, plus the glaive alone. Same colors and proportions in every view.
```

#### Chân dung — `assets/characters/boss_henchman_01/portrait/boss_henchman_01_portrait.png`

Dùng cho thẻ boss / băng thoại "???". Tạo 1024×1024.

```text
Anime 2D portrait of the masked henchman from the attached design sheet: bust shot, three-quarter view, smooth
faceless black visor-mask catching a cold rim light, ash-grey armor with dim orange glowing seams, tattered charcoal
cloak collar, ash particles drifting. Dark moody background in deep indigo with a thin eclipse ring of light.
No text, no logo, no watermark. Faithful to the attached design sheet.
```

#### Tư thế chiến đấu (tham chiếu cho animation sau này)

```text
Anime 2D action pose of the masked henchman from the attached design sheet, facing right, side view, feet on a flat
ground line, holding the hooked black glaive low behind him ready to sweep, ash leaking from armor seams.
Transparent or plain light grey background. No text. Faithful to the attached design sheet.
```

> Game hiện vẽ boss bằng hình tạm (`scenes/enemies/boss_henchman.tscn`: thân xám, mặt nạ đen, đường nối cam, lưỡi móc
> đen). Khi có frame animation thật cho kẻ địch sẽ làm phiếu frame riêng như nhân vật (README 17.4).


## 6. Phần B — Truyện tranh Chương 1

> Nguồn: `docs/prompts/story/CH01_PANELS.md` (sinh bởi `tools/story/gen_story_clips.py`)

### Prompt ChatGPT cho truyện tranh Chương 1 (mở chương, cuối ải 1-1, kết chương)

> Sinh bởi `tools/story/gen_story_clips.py` — sửa kịch bản ở đó rồi chạy lại. Owner 2026-11-14: clip dẫn truyện là
> các trang truyện tranh, mỗi trang 1–4 ô (vuông, thang, tam giác...) hiện dần, hết trang thì xóa để sang trang mới.

#### Cách làm

1. Mở một cuộc trò chuyện mới với ChatGPT (công cụ tạo ảnh). **Đính kèm ảnh tham chiếu** ghi ở từng ô (lấy trong dự án)
   để giữ đúng thiết kế nhân vật. Có thể gửi đoạn "Bối cảnh dự án" bên dưới một lần ở đầu cuộc trò chuyện.
2. Dán prompt của ô (khối `text`). Chọn khung gần nhất theo mục "Tạo bằng ChatGPT ở ...".
3. Trong Photoshop: mở placeholder đúng số làm lớp dưới, đặt ảnh lên, co / cắt cho khớp **đúng kích thước** ghi ở ô
   (hoặc gấp đôi), giữ chủ thể trong vùng xám. Không cần cắt theo hình ô: game tự cắt theo đa giác.
4. Lưu PNG đúng tên vào `assets/story/ch01/`. Game tự dùng ảnh thật thay placeholder, không cần sửa code.
5. Ảnh AI được dùng trong bản phát hành (owner 2026-11-12) nhưng **phải ghi từng file** vào `docs/ASSET_LICENSES.md`
   mục 2.1 (file, công cụ + model, prompt rút gọn, ảnh tham chiếu, ngày) trước khi commit; khai báo nội dung AI trên store.
6. Không vẽ chữ, bóng thoại hay viền ô vào ảnh: game tự hiện thoại và viền.

#### Bối cảnh dự án (gửi ChatGPT một lần)

```text
I'm making illustrated story panels for PROJECT ECLIPSE, an original anime-style 2D action RPG. The world lies under the
"Eclipsed Sun": a pale orange sun with a dark bite missing from one side. Where its shadow falls, a "Hollow Zone"
forms and the elements fade: fire dies to ash, the wind stops. Leftover elements clump into small "Dregs" (slime
blobs) and ancient stone guardians go berserk. The player is an unseen Manager who carries NEO, a small floating AI
device (a glowing cyan ring with a light core), which deploys one suit-wearer at a time into the zone.
Chapter 1, "The Ashen Valley": Enkiba (fire, sword), Kazeyumi (wind, bow) and Raikiba (lightning, twin daggers) enter
a grey ash valley where the Mother Hearth, a giant furnace carved into a cliff that keeps Coalhearth Village alive, is
dying. The Ancient Stone Golem was sent to block its gate; the real culprit is a masked henchman in dark ash-grey armor
(faceless black visor), serving another Manager under a leader known only as "00". Keep every character faithful to
the reference images I attach.
Style for all panels: color manga panel, clean line art, cel shading, cinematic lighting. No text or speech bubbles.
```

#### ch01_open — Mở chương

##### Trang 1 (bố cục A)

###### Mở chương — ô 01 — `ch01_open_01.png`
- **Kích thước ảnh:** 1840 × 380 px (1×; khuyến nghị làm 2× = 3680 × 760 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_01.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Toàn cảnh cửa thung lũng xám tro, đường dốc xuống, tro rơi thẳng đứng; Mặt Trời Khuyết trên trời; cuối thung lũng là vách đá có cửa lò khổng lồ tối om.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** narration: “Thung Lũng Tro Tàn.”
- **Lưu thành:** `assets/story/ch01/ch01_open_01.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Wide establishing shot of a grey ash-covered valley seen from its mouth: a dirt road sloping down, ash falling straight down with no wind, the Eclipsed Sun in a hazy orange sky, and far away a cliff with a gigantic dark furnace gate carved into the rock. A faint violet haze line crosses the ground (the edge of the Hollow Zone).

Composition: final image 1840x380 px (aspect 4.84:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Mở chương — ô 02 — `ch01_open_02.png`
- **Kích thước ảnh:** 960 × 387 px (1×; khuyến nghị làm 2× = 1920 × 774 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_02.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba phanh trượt ngay trước vạch mờ tím, chồm người nhìn vào, ngạc nhiên.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Tới rồi! …Ơ. Sao im thế này?”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_02.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Raikiba skids to a stop right before the violet haze line, leaning forward to peer into the silent valley, surprised, dust kicked up behind him.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 960x387 px (aspect 2.48:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Mở chương — ô 03 — `ch01_open_03.png`
- **Kích thước ảnh:** 916 × 416 px (1×; khuyến nghị làm 2× = 1832 × 832 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_03.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi giơ một tay dò gió, nét mặt nghiêm; tro rơi thẳng quanh cô.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Không có gió. Tro rơi thẳng xuống như rơi trong nhà kín.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_03.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Kazeyumi raises one open hand to feel for wind, serious expression, ash falling perfectly straight around her, her cape hanging still.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 916x416 px (aspect 2.20:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

##### Trang 2 (bố cục B)

###### Mở chương — ô 04 — `ch01_open_04.png`
- **Kích thước ảnh:** 720 × 760 px (1×; khuyến nghị làm 2× = 1440 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1024×1024 (vuông) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_04.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba đứng cạnh biển gỗ cháy xém chỉ về làng; đốm than cuối cùng trên biển vừa tắt.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Lò Mẹ ở cuối đường này.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_04.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Tall shot: Enkiba stands beside a half-burnt wooden signpost pointing down the road; the last red ember on the sign has just gone out, a thin wisp of smoke rising. Melancholic.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 720x760 px (aspect 0.95:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Mở chương — ô 05 — `ch01_open_05.png`
- **Kích thước ảnh:** 1126 × 380 px (1×; khuyến nghị làm 2× = 2252 × 760 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_05.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba quay sang Enkiba, nhướng mày.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Đây là quê cậu à? Hồi ở Lò Nanh cậu kể suốt.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_05.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Raikiba turns toward Enkiba (off-panel) with a raised eyebrow, half-teasing, half-curious.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 1126x380 px (aspect 2.96:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Mở chương — ô 06 — `ch01_open_06.png`
- **Kích thước ảnh:** 1156 × 396 px (1×; khuyến nghị làm 2× = 2312 × 792 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_06.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Cận mặt Enkiba nhìn xa, lo lắng, ánh tro phản chiếu trong mắt.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Ừ. Lửa ở đây từng cao hơn mái nhà. Giờ thì… cậu nhìn đi.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_06.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Close-up of Enkiba looking into the distance, worried, grey ash reflected in his amber eyes.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 1156x396 px (aspect 2.92:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

##### Trang 3 (bố cục D)

###### Mở chương — ô 07 — `ch01_open_07.png`
- **Kích thước ảnh:** 1120 × 620 px (1×; khuyến nghị làm 2× = 2240 × 1240 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tam giác. Placeholder: `assets/placeholders/story/placeholder_ch01_open_07.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** NEO trồi lên lơ lửng phía trước, vòng sáng xoay; ba người nhìn vào nó.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Phát hiện ranh giới Vùng Thực. Mật độ nguyên tố phía trước chỉ còn 12%.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`, `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`, `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_07.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: NEO rises into frame in the foreground, its cyan ring glowing and spinning; behind it Enkiba, Kazeyumi and Raikiba look at it, lit by its light.

Characters:
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 1120x620 px (aspect 1.81:1). The visible area is a triangular panel; keep the main subject inside it (see the numbered placeholder).
```

###### Mở chương — ô 08 — `ch01_open_08.png`
- **Kích thước ảnh:** 1840 × 760 px (1×; khuyến nghị làm 2× = 3680 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** lục giác (dải chéo). Placeholder: `assets/placeholders/story/placeholder_ch01_open_08.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi nghiêm mặt; Raikiba gãi đầu, giọt mồ hôi.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Đủ nuôi một bộ giáp. Không đủ cho ba.” / char_lightning_01: “Vậy là đúng như bản hướng dẫn nói hả? Tớ… đọc lướt thôi.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`, `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_08.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Two-shot: Kazeyumi with a serious face, arms crossed; Raikiba scratching the back of his head, sheepish sweat drop.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 1840x760 px (aspect 2.42:1). The visible area is a diagonal band panel; keep the main subject inside it (see the numbered placeholder).
```

###### Mở chương — ô 09 — `ch01_open_09.png`
- **Kích thước ảnh:** 1120 × 620 px (1×; khuyến nghị làm 2× = 2240 × 1240 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tam giác. Placeholder: `assets/placeholders/story/placeholder_ch01_open_09.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi quay ra phía người xem (Quản lý), NEO lơ lửng bên cạnh.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Một người ra sân, hai người chờ trong kênh của Neo. Quản lý quyết định ai ra.” / neo: “Khi kênh của ai đó cộng hưởng, tôi sẽ báo. Đổi đúng lúc ấy, hai nguyên tố sẽ chạm nhau.” / char_lightning_01: “Rồi nổ chứ gì! Phần đó thì tớ nhớ.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_09.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Kazeyumi faces the viewer directly (as if talking to the Manager behind the camera), NEO floating at her shoulder.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 1120x620 px (aspect 1.81:1). The visible area is a triangular panel; keep the main subject inside it (see the numbered placeholder).
```

##### Trang 4 (bố cục C)

###### Mở chương — ô 10 — `ch01_open_10.png`
- **Kích thước ảnh:** 1260 × 760 px (1×; khuyến nghị làm 2× = 2520 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_10.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Cuối thung lũng: trong bóng tối trước cửa Lò Mẹ, hai đốm mắt cam đỏ sáng lên trên một khối đá khổng lồ.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Tín hiệu lớn ở cuối thung lũng. Một thủ vệ đá… nó đang đứng chắn cửa Lò Mẹ.” / char_fire_01: “Golem Đá Cổ…? Nó canh Lò Mẹ cả trăm năm, chưa từng nhúc nhích.”
- **Lưu thành:** `assets/story/ch01/ch01_open_10.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Dramatic shot down the valley: in the darkness before the giant furnace gate, two orange-red eyes light up on a towering stone silhouette — the Ancient Stone Golem, cracks glowing faintly. The ground trembles, ash jumps.

Composition: final image 1260x760 px (aspect 1.66:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Mở chương — ô 11 — `ch01_open_11.png`
- **Kích thước ảnh:** 956 × 760 px (1×; khuyến nghị làm 2× = 1912 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_11.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi nheo mắt nhìn về cuối thung lũng.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Lửa không tự tắt nhanh vậy đâu. Có ai đó đang dập nó.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_11.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Kazeyumi narrows her eyes toward the far end of the valley, hand on her bow.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 956x760 px (aspect 1.26:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

##### Trang 5 (bố cục G)

###### Mở chương — ô 12 — `ch01_open_12.png`
- **Kích thước ảnh:** 900 × 384 px (1×; khuyến nghị làm 2× = 1800 × 768 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_12.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Những khối tro xám nhỏ trồi lên, nảy về phía cuối thung lũng; Raikiba chỉ tay.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Còn mấy cục tro biết nhảy kia là gì?” / char_wind_01: “Cặn. Nguyên tố thừa vón lại. Chúng bị kéo về phía lò, chắn hết đường.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`, `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_12.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Small grey ash-slime blobs with faint ember specks pop out of the ash and hop toward the far end of the valley; Raikiba points at them, Kazeyumi beside him.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 900x384 px (aspect 2.34:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Mở chương — ô 13 — `ch01_open_13.png`
- **Kích thước ảnh:** 931 × 363 px (1×; khuyến nghị làm 2× = 1862 × 726 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_13.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba bước tới vạch mờ, giơ kiếm, lưỡi kiếm bén lửa.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Quản lý. Lò Mẹ mà tắt hẳn thì Vùng Thực nuốt luôn làng tớ. Cho bọn tớ vào.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_13.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Enkiba steps up to the haze line and raises his sword; a flame ignites along the blade, determined face, low angle.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 931x363 px (aspect 2.56:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Mở chương — ô 14 — `ch01_open_14.png`
- **Kích thước ảnh:** 884 × 372 px (1×; khuyến nghị làm 2× = 1768 × 744 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_14.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** NEO sáng cam đều, như gật đầu.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Đã ghi mục tiêu. Chờ lệnh xuất kích của Quản lý.”
- **Lưu thành:** `assets/story/ch01/ch01_open_14.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Close-up of NEO glowing a steady warm orange, as if nodding in agreement.

Characters:
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 884x372 px (aspect 2.38:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Mở chương — ô 15 — `ch01_open_15.png`
- **Kích thước ảnh:** 952 × 392 px (1×; khuyến nghị làm 2× = 1904 × 784 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_15.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi và Raikiba tan thành hạt sáng xanh ngọc và vàng, bay vào NEO.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Cần chạy nhanh thì gọi tớ.” / char_wind_01: “Còn tớ nhắc trước: đừng để bị đánh trúng nhiều quá.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`, `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_15.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Kazeyumi and Raikiba dissolve into teal and yellow light particles that stream into NEO; Raikiba gives a thumbs-up, Kazeyumi a small smile.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 952x392 px (aspect 2.43:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### ch01_golem — Cuối ải 1-1

##### Trang 1 (bố cục F)

###### Cuối ải 1-1 — ô 01 — `ch01_golem_01.png`
- **Kích thước ảnh:** 1840 × 420 px (1×; khuyến nghị làm 2× = 3680 × 840 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_01.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Golem đổ sụp thành từng khối đá trước cửa Lò Mẹ lạnh tối; Enkiba thở dốc, kiếm hạ xuống.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Thủ vệ đã ngừng hoạt động. Mở kênh: mọi người ra được rồi.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_01.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Wide shot: the Ancient Stone Golem collapses into huge boulders in front of the cold, dark mouth of the gigantic Mother Hearth carved into the cliff; dust and ash billow; Enkiba stands panting, sword lowered, seen from behind.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 1840x420 px (aspect 4.38:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Cuối ải 1-1 — ô 02 — `ch01_golem_02.png`
- **Kích thước ảnh:** 1840 × 416 px (1×; khuyến nghị làm 2× = 3680 × 832 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_02.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba và Kazeyumi hiện ra từ hạt sáng; Raikiba ngồi phịch xuống, Kazeyumi nhìn lên lò.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Phù… Xong rồi chứ?” / char_wind_01: “Chưa. Nhìn lò kìa.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`, `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_02.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Raikiba and Kazeyumi materialize from teal and yellow light particles; Raikiba flops down on a rock grinning, while Kazeyumi already looks up at the furnace with a frown.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 1840x416 px (aspect 4.42:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

##### Trang 2 (bố cục C)

###### Cuối ải 1-1 — ô 03 — `ch01_golem_03.png`
- **Kích thước ảnh:** 1260 × 760 px (1×; khuyến nghị làm 2× = 2520 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_03.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba ngước nhìn cửa lò vẫn lạnh ngắt; NEO lơ lửng bên cạnh, ánh xanh nhạt.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Lò Mẹ vẫn lạnh…” / neo: “Thủ vệ không hút lửa. Nó chỉ đứng chắn cửa lò.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_03.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Enkiba looks up at the still-cold, dark furnace mouth; NEO floats beside him glowing a pale, uncertain cyan. No fire anywhere.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 1260x760 px (aspect 1.66:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Cuối ải 1-1 — ô 04 — `ch01_golem_04.png`
- **Kích thước ảnh:** 956 × 760 px (1×; khuyến nghị làm 2× = 1912 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_04.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi quỳ một gối, đặt tay lên đầu đá của golem.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Nó không ác. Có kẻ sai nó tới chặn bọn mình.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_04.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Kazeyumi kneels on one knee and gently lays her hand on the golem's broken stone head; its eye sockets are dark now. Quiet, sorrowful mood.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 956x760 px (aspect 1.26:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

##### Trang 3 (bố cục B)

###### Cuối ải 1-1 — ô 05 — `ch01_golem_05.png`
- **Kích thước ảnh:** 720 × 760 px (1×; khuyến nghị làm 2× = 1440 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1024×1024 (vuông) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_05.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba nhặt từ đống đá một chiếc đĩa nhỏ phát sáng trắng đen.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Cái gì đây? Trông giống vòng sáng của Neo ghê.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_05.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Tall shot: Raikiba crouches among the golem rubble holding up a small disc that glows half white, half black, with a ring pattern; puzzled look.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 720x760 px (aspect 0.95:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Cuối ải 1-1 — ô 06 — `ch01_golem_06.png`
- **Kích thước ảnh:** 1126 × 380 px (1×; khuyến nghị làm 2× = 2252 × 760 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_06.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Cận chiếc đĩa; NEO lại gần, vòng sáng nhiễu loạn.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Mảnh ấn kênh… định dạng trùng với tôi. Nguồn lệnh: 00.” / char_wind_01: “Neo của chúng ta đâu phải số 00.”
- **Lưu thành:** `assets/story/ch01/ch01_golem_06.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Close-up of the white-and-black disc with its ring sigil; NEO hovers right next to it, its cyan ring glitching and flickering.

Characters:
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 1126x380 px (aspect 2.96:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Cuối ải 1-1 — ô 07 — `ch01_golem_07.png`
- **Kích thước ảnh:** 1156 × 396 px (1×; khuyến nghị làm 2× = 2312 × 792 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_07.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba nghiêm mặt, siết chuôi kiếm, cửa lò lạnh phía sau.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Vậy kẻ thật sự dập lửa vẫn còn trong thung lũng.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_07.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Enkiba with a grim face, gripping his sword hilt tightly, the cold dark furnace behind him.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 1156x396 px (aspect 2.92:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

##### Trang 4 (bố cục A)

###### Cuối ải 1-1 — ô 08 — `ch01_golem_08.png`
- **Kích thước ảnh:** 1840 × 380 px (1×; khuyến nghị làm 2× = 3680 × 760 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_08.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Trên đỉnh vách phía trên Lò Mẹ, một kẻ mặc giáp xám tro, mặt nạ đen trơn, đứng nhìn xuống rồi quay lưng.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** unknown: “Thủ vệ chỉ để câu giờ. Báo với Quản lý: lò sẽ tắt đúng hẹn.”
- **Lưu thành:** `assets/story/ch01/ch01_golem_08.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Wide shot from below: high on the cliff edge above the cold Mother Hearth stands the masked henchman against the hazy sky and the Eclipsed Sun, looking down, cloak hanging still, already half-turned to leave.

Characters:
- the masked henchman — a tall suit-wearer in dark ash-grey plated armor with dull orange seams, a smooth faceless black visor (face never shown), a tattered charcoal cloak, a small half-white half-black ring emblem on the chest; wields a heavy black hooked glaive

Composition: final image 1840x380 px (aspect 4.84:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Cuối ải 1-1 — ô 09 — `ch01_golem_09.png`
- **Kích thước ảnh:** 960 × 387 px (1×; khuyến nghị làm 2× = 1920 × 774 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_09.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba bật dậy chỉ tay lên vách.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Trên kia! Có người!”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_09.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Raikiba springs up and points sharply up at the cliff, shouting, daggers in his other hand.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 960x387 px (aspect 2.48:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Cuối ải 1-1 — ô 10 — `ch01_golem_10.png`
- **Kích thước ảnh:** 916 × 416 px (1×; khuyến nghị làm 2× = 1832 × 832 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_10.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba nhìn theo, quyết tâm; NEO sáng đỏ cảnh báo.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Đuổi theo. Phải tìm ra hắn trước khi Lò Mẹ tắt hẳn.” / neo: “Đã ghi dấu kênh lạ. Chờ lệnh của Quản lý.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_10.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Enkiba glares up toward the now-empty cliff edge, determined; NEO beside him glows a warning red.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 916x416 px (aspect 2.20:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### ch01_end — Kết chương (cuối ải 1-10)

##### Trang 1 (bố cục F)

###### Kết chương (cuối ải 1-10) — ô 01 — `ch01_end_01.png`
- **Kích thước ảnh:** 1840 × 420 px (1×; khuyến nghị làm 2× = 3680 × 840 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_01.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Trước cửa Lò Mẹ lạnh tối; kẻ đeo mặt nạ quỳ gối, giáp nứt vỡ; Enkiba chĩa kiếm.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Giáp của hắn đã vỡ. Vùng Thực loãng rồi: mọi người ra được.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_01.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Wide shot: before the cold, dark mouth of the Mother Hearth, the masked henchman kneels on one knee, his ash-grey armor cracked and smoking, glaive dropped; Enkiba stands over him, flaming sword pointed at him.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- the masked henchman — a tall suit-wearer in dark ash-grey plated armor with dull orange seams, a smooth faceless black visor (face never shown), a tattered charcoal cloak, a small half-white half-black ring emblem on the chest; wields a heavy black hooked glaive

Composition: final image 1840x420 px (aspect 4.38:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Kết chương (cuối ải 1-10) — ô 02 — `ch01_end_02.png`
- **Kích thước ảnh:** 1840 × 416 px (1×; khuyến nghị làm 2× = 3680 × 832 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_02.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba và Kazeyumi hiện ra từ hạt sáng; Raikiba ngồi phịch xuống.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Phù… Tên này còn lì hơn cả con golem.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`, `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_02.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Raikiba and Kazeyumi materialize from teal and yellow light particles; Raikiba flops down to sit on a rock, exhausted but grinning.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 1840x416 px (aspect 4.42:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

##### Trang 2 (bố cục C)

###### Kết chương (cuối ải 1-10) — ô 03 — `ch01_end_03.png`
- **Kích thước ảnh:** 1260 × 760 px (1×; khuyến nghị làm 2× = 2520 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_03.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kẻ đeo mặt nạ ngẩng lên cười khẩy; Kazeyumi giương cung.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** unknown: “Thắng một tay sai thì đã sao. Quản lý của ta chỉ cần lò này tắt một đêm.” / char_wind_01: “Quản lý của ngươi là ai?”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_03.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: The masked henchman lifts his faceless visor toward them in mockery; Kazeyumi draws her bow at him, cold expression.

Characters:
- the masked henchman — a tall suit-wearer in dark ash-grey plated armor with dull orange seams, a smooth faceless black visor (face never shown), a tattered charcoal cloak, a small half-white half-black ring emblem on the chest; wields a heavy black hooked glaive
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 1260x760 px (aspect 1.66:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Kết chương (cuối ải 1-10) — ô 04 — `ch01_end_04.png`
- **Kích thước ảnh:** 956 × 760 px (1×; khuyến nghị làm 2× = 1912 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_04.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kẻ đeo mặt nạ tan thành hạt sáng trắng đen, bị kéo đi; Enkiba vươn tay chụp hụt.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Đứng lại!” / neo: “Hắn bị rút về một kênh khác. Định dạng… 00.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_04.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: The henchman dissolves into black-and-white light particles that are sucked away into nothing; Enkiba lunges and grabs only empty air; NEO's ring flickers.

Characters:
- the masked henchman — a tall suit-wearer in dark ash-grey plated armor with dull orange seams, a smooth faceless black visor (face never shown), a tattered charcoal cloak, a small half-white half-black ring emblem on the chest; wields a heavy black hooked glaive
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 956x760 px (aspect 1.26:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

##### Trang 3 (bố cục D)

###### Kết chương (cuối ải 1-10) — ô 05 — `ch01_end_05.png`
- **Kích thước ảnh:** 1120 × 620 px (1×; khuyến nghị làm 2× = 2240 × 1240 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tam giác. Placeholder: `assets/placeholders/story/placeholder_ch01_end_05.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kiếm bén lửa của Enkiba chạm vào miệng lò.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Dậy đi. Tới lượt cậu rồi.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_05.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Close-up: the tip of Enkiba's flaming sword touches the stone lip of the furnace mouth; a single spark catches.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 1120x620 px (aspect 1.81:1). The visible area is a triangular panel; keep the main subject inside it (see the numbered placeholder).
```

###### Kết chương (cuối ải 1-10) — ô 06 — `ch01_end_06.png`
- **Kích thước ảnh:** 1840 × 760 px (1×; khuyến nghị làm 2× = 3680 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** lục giác (dải chéo). Placeholder: `assets/placeholders/story/placeholder_ch01_end_06.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Lò Mẹ bùng cháy rực rỡ, đốm lửa bay lên; Raikiba nhảy cẫng lên.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “…Cháy rồi.” / char_lightning_01: “Cháy rồi! Cháy thật rồi!”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`, `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_06.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: The Mother Hearth roars back to life with a huge warm orange glow, embers rising into the sky; Enkiba lowers his sword, smiling; Raikiba jumps for joy in the foreground.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 1840x760 px (aspect 2.42:1). The visible area is a diagonal band panel; keep the main subject inside it (see the numbered placeholder).
```

###### Kết chương (cuối ải 1-10) — ô 07 — `ch01_end_07.png`
- **Kích thước ảnh:** 1120 × 620 px (1×; khuyến nghị làm 2× = 2240 × 1240 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tam giác. Placeholder: `assets/placeholders/story/placeholder_ch01_end_07.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi mỉm cười, đốm lửa bay ngang theo gió vừa trở lại.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Gió cũng về rồi. Nghe này.” / neo: “Ranh giới Vùng Thực đã lùi 2 km. Làng Lò Than an toàn rồi.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_07.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Kazeyumi smiles with her eyes closed as embers drift sideways on a returning breeze, her ponytail and cape lifting; NEO glows calm green.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 1120x620 px (aspect 1.81:1). The visible area is a triangular panel; keep the main subject inside it (see the numbered placeholder).
```

##### Trang 4 (bố cục B)

###### Kết chương (cuối ải 1-10) — ô 08 — `ch01_end_08.png`
- **Kích thước ảnh:** 720 × 760 px (1×; khuyến nghị làm 2× = 1440 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1024×1024 (vuông) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_08.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba giơ hai chiếc đĩa trắng đen: một từ golem, một hắn đánh rơi.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Hắn làm rơi cái này. Giống hệt cái trong golem.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_08.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Tall shot: Raikiba holds up two small discs glowing half white, half black, one in each hand, comparing them; the burning hearth lights the scene warmly.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 720x760 px (aspect 0.95:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Kết chương (cuối ải 1-10) — ô 09 — `ch01_end_09.png`
- **Kích thước ảnh:** 1126 × 380 px (1×; khuyến nghị làm 2× = 2252 × 760 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_09.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Cận hai chiếc đĩa; NEO lại gần, vòng sáng nhiễu loạn.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Cả hai cùng nguồn lệnh 00. Golem và tên đó nhận lệnh từ cùng một mạng kênh.” / char_wind_01: “Tay sai, rồi Quản lý của hắn, rồi kẻ mang mã 00…”
- **Lưu thành:** `assets/story/ch01/ch01_end_09.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Close-up of the two white-and-black discs side by side with their ring sigils; NEO hovers next to them, its cyan ring glitching.

Characters:
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 1126x380 px (aspect 2.96:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Kết chương (cuối ải 1-10) — ô 10 — `ch01_end_10.png`
- **Kích thước ảnh:** 1156 × 396 px (1×; khuyến nghị làm 2× = 2312 × 792 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_10.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba nghiêm mặt, siết chuôi kiếm.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Tớ sẽ lần ra từng người một. Không ai được dập lửa của làng tớ nữa.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_10.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Enkiba with a grim face, gripping his sword hilt tightly, the burning hearth behind him.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 1156x396 px (aspect 2.92:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

##### Trang 5 (bố cục A)

###### Kết chương (cuối ải 1-10) — ô 11 — `ch01_end_11.png`
- **Kích thước ảnh:** 1840 × 380 px (1×; khuyến nghị làm 2× = 3680 × 760 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_11.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Tấm giáp lưng golem lật lên: dấu khắc ba vòng đá chồng nhau.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Dấu này tớ từng thấy trên bản đồ. Xưởng làm thủ vệ trên cao nguyên đá.” / char_wind_01: “Muốn sai được thủ vệ thì chắc chúng đã ghé đó trước.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_11.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Wide shot: Kazeyumi has flipped over a large back-plate of the golem rubble, revealing an engraved crest of three stacked stone rings.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 1840x380 px (aspect 4.84:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Kết chương (cuối ải 1-10) — ô 12 — `ch01_end_12.png`
- **Kích thước ảnh:** 960 × 387 px (1×; khuyến nghị làm 2× = 1920 × 774 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_12.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba nhét hai chiếc đĩa vào túi, cười.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Đi luôn hả? Chân tớ vẫn còn nóng.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_12.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Raikiba tucks the two discs into his pocket with a confident grin, ready to go.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 960x387 px (aspect 2.48:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

###### Kết chương (cuối ải 1-10) — ô 13 — `ch01_end_13.png`
- **Kích thước ảnh:** 916 × 416 px (1×; khuyến nghị làm 2× = 1832 × 832 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_13.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba nhìn lại Lò Mẹ đang cháy rồi quay đi.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Đi. Lò Mẹ cháy lại rồi. Tớ không để nơi nào khác tắt như vậy nữa.” / neo: “Đã ghi tọa độ: Cao nguyên Thủ Vệ. Chờ lệnh của Quản lý.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_13.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Enkiba glances back at the blazing hearth over his shoulder, then turns toward the road; NEO glows orange beside him.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 916x416 px (aspect 2.20:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

##### Trang 6 (bố cục E)

###### Kết chương (cuối ải 1-10) — ô 14 — `ch01_end_14.png`
- **Kích thước ảnh:** 1840 × 760 px (1×; khuyến nghị làm 2× = 3680 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_14.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Đêm, đỉnh vách đá trên thung lũng; Lò Mẹ cháy sáng phía dưới; một bóng người cầm vòng sáng trắng đen giống Neo (Quản lý của tay sai).
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** unknown: “Tay sai thua rồi à. Không sao. Báo với 00: thủ vệ trên cao nguyên còn nhiều.”
- **Lưu thành:** `assets/story/ch01/ch01_end_14.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Night. On a cliff top above the valley stands a lone silhouette (pure black shape, face never shown, long coat moving in the wind), holding a glowing white-and-black ring device like NEO; far below, the Mother Hearth burns bright orange. Ominous, quiet.

Composition: final image 1840x760 px (aspect 2.42:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```


## 7. Phần C — Tranh map chương và thẻ chương

> Nguồn: `docs/prompts/story/CHAPTER_ART.md` (sinh bởi `tools/story/gen_chapters.py`)

### Ảnh map chương và thẻ chương (ChatGPT)

> Sinh bởi `tools/story/gen_chapters.py`. Mỗi chương có **một tranh dài** làm nền map (người chơi kéo ngang liền mạch)
> và **một ảnh thẻ** ở màn chọn chương. Ảnh thật lưu ở `assets/story/chapters/` đúng tên, game tự thay placeholder.
> Ảnh AI phải ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.

#### Cách làm tranh map dài

ChatGPT không tạo được ảnh rất dài một lần: tạo **nhiều ảnh ngang 1536×1024 nối tiếp** (mỗi ảnh nói rõ "continues
seamlessly from the previous image, same horizon line and lighting"), rồi ghép trong Photoshop thành một dải, co về chiều
cao 1080 px và đúng chiều rộng ghi dưới đây. Làm mờ nhẹ (Gaussian ~6–12 px) để nút ải nổi lên trên nền.

Phong cách chung: *anime 2D background painting, soft painterly, wide panoramic side view, horizon at about 60% height,
no characters, no text, slightly desaturated so UI on top stays readable; the Eclipsed Sun (pale orange sun with a dark
bite missing from one side) appears in the sky.*

#### Chương 1 — Thung Lũng Tro Tàn (10 ải, 1 phần)

- **Tranh map:** `assets/story/chapters/map_ch01.png` — **3240 × 1080 px** (placeholder `placeholder_map_ch01.png`).
  Ghép khoảng 3 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch01.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, a grey ash-covered valley with a dirt road winding toward a cliff carved with a gigantic dark furnace (the Mother Hearth), dead trees, ash falling, a small village at the valley mouth. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, a grey ash-covered valley with a dirt road winding toward a cliff carved with a gigantic dark furnace (the Mother Hearth), dead trees, ash falling, a small village at the valley mouth, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```

#### Chương 2 — Xưởng Đá Ngủ (12 ải, 1 phần)

- **Tranh map:** `assets/story/chapters/map_ch02.png` — **3800 × 1080 px** (placeholder `placeholder_map_ch02.png`).
  Ghép khoảng 3 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch02.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, high stone plateau with ancient guardian workshops carved into rock, giant dormant stone golem statues, cranes and forges, misty. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, high stone plateau with ancient guardian workshops carved into rock, giant dormant stone golem statues, cranes and forges, misty, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```

#### Chương 3 — Thành Tháp Sét Câm (15 ải, 1 phần)

- **Tranh map:** `assets/story/chapters/map_ch03.png` — **4640 × 1080 px** (placeholder `placeholder_map_ch03.png`).
  Ghép khoảng 4 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch03.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, a city of tall lightning-rod towers under a dark storm-less sky, power lines gone dead, empty streets, unlit windows. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, a city of tall lightning-rod towers under a dark storm-less sky, power lines gone dead, empty streets, unlit windows, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```

#### Chương 4 — Thánh Đường Ngọn Đèn Cuối (20 ải, 2 phần)

- **Tranh map:** `assets/story/chapters/map_ch04.png` — **6400 × 1080 px** (placeholder `placeholder_map_ch04.png`).
  Ghép khoảng 5 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch04.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, a white marble sanctuary on a hill holding one great lamp of light, pilgrims' road, warm glow against a dim sky. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, a white marble sanctuary on a hill holding one great lamp of light, pilgrims' road, warm glow against a dim sky, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```

#### Chương 5 — Rừng Không Bóng (24 ải, 2 phần)

- **Tranh map:** `assets/story/chapters/map_ch05.png` — **7520 × 1080 px** (placeholder `placeholder_map_ch05.png`).
  Ghép khoảng 6 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch05.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, a deep forest where nothing casts a shadow, pale flat light, eerie silver trees, ancient pillar ruins half buried. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, a deep forest where nothing casts a shadow, pale flat light, eerie silver trees, ancient pillar ruins half buried, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```

#### Chương 6 — Đỉnh Gió Lặng (26 ải, 2 phần)

- **Tranh map:** `assets/story/chapters/map_ch06.png` — **8080 × 1080 px** (placeholder `placeholder_map_ch06.png`).
  Ghép khoảng 6 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch06.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, a towering wind mountain with dead still clouds, rope bridges, wind shrines, a summit with a broken ring-shaped pillar. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, a towering wind mountain with dead still clouds, rope bridges, wind shrines, a summit with a broken ring-shaped pillar, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```

#### Chương 7 — Nhật Thực (30 ải, 2 phần)

- **Tranh map:** `assets/story/chapters/map_ch07.png` — **9200 × 1080 px** (placeholder `placeholder_map_ch07.png`).
  Ghép khoảng 7 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch07.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, inside the eclipse: a vast dark sky with the bitten sun overhead, floating fragments of the seventh pillar, a bright ring of light. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, inside the eclipse: a vast dark sky with the bitten sun overhead, floating fragments of the seventh pillar, a bright ring of light, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```


## 8. Phần D — Ảnh nền màn chơi

> Nguồn: `docs/prompts/stages/STAGE_01_BACKGROUND.md`

### Ảnh nền màn 1-1 "Thung Lũng Tro Tàn" (3 lớp parallax)

> Màn `stage_01` (sinh bởi `tools/stages/gen_stage_01_backdrop.py`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/stage_01.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/gen_stage_01_backdrop.py` rồi chạy lại.

#### Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01/bg_stage_01_far.png` | 0.1 | Trời xám cam mù, Mặt Trời Khuyết, cuối thung lũng là vách đá có cửa Lò Mẹ khổng lồ tối om | Không (phủ kín) |
| Giữa | `.../bg_stage_01_mid.png` | 0.3 | Sườn thung lũng tro xám, đường đất dốc, cây chết, biển gỗ cháy xém | Có |
| Gần | `.../bg_stage_01_near.png` | 0.6 | Đá, gốc cây cháy, cỏ khô phủ tro | Có (trên ~55% trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: cùng nơi với ô truyện `ch01_open_01` (cửa thung lũng) và `ch01_open_10` (cuối thung lũng có golem); Lò Mẹ **lạnh**, **không gió**, tro rơi thẳng. Là nền chuẩn cho bảng màu cả Chương 1.

#### Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: the Ashen Valley seen from inside, the road leading down toward the Mother Hearth, a giant furnace carved into a cliff, which has gone cold; there is no wind and grey ash falls straight down. Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level, keep it plain.
```

#### Lớp xa — `bg_stage_01_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. Hazy grey-orange afternoon sky, the Eclipsed Sun on the left third, ash falling perfectly straight down. Far away at the end of the valley on the right third, a towering cliff with a gigantic carved furnace gate, dark and cold (the Mother Hearth).
```

#### Lớp giữa — `bg_stage_01_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). Grey ash-covered valley slopes with a dirt road sloping down toward the far cliff, scattered dead trees, a half-burnt wooden signpost, a faint violet haze line crossing the ground (the edge of the Hollow Zone).
```

#### Lớp gần — `bg_stage_01_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Dark foreground silhouettes: rocks, charred stumps and ash-covered dry grass along the bottom edge. Keep the middle readable.
```

#### Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-1 theo docs/prompts/stages/STAGE_01_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: ô truyện assets/story/ch01/ch01_open_01.png (nếu có) để khớp thung lũng, Mặt Trời Khuyết và cửa Lò Mẹ.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-1":
   - chép vào assets/backgrounds/stages/stage_01/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-1: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

#### Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-1 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.


> Nguồn: `docs/prompts/stages/STAGE_01_02_BACKGROUND.md`

### Ảnh nền màn 1-2 "Làng Lò Than" (3 lớp parallax)

> Màn `stage_01_02` (sinh bởi `tools/stages/gen_stage_01_02.py`) đọc 3 ảnh nền theo `backdrop` trong
> `data/stages/stage_01_02.json`. Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm.
> Không cần sửa code: chỉ đặt ảnh đúng tên rồi `--import`.

#### Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_02/bg_stage_01_02_far.png` | 0.1 | Trời, Mặt Trời Khuyết, vách đá xa có Lò Mẹ **lạnh tối** | Không (phủ kín) |
| Giữa | `.../bg_stage_01_02_mid.png` | 0.3 | Đồi tro, mái nhà làng Lò Than, ống khói, cối xay | Có (trời trong suốt) |
| Gần | `.../bg_stage_01_02_near.png` | 0.6 | Hàng rào gỗ, đèn lồng, cây chết, đống than | Có (trên ~55% trong suốt) |

- Kích thước: **3840 × 2160** (game co về cao 1080). Rộng có thể 3840 hoặc 7680; ảnh **lặp ngang**, mép trái và phải
  phải nối liền (Photoshop: *Filter → Other → Offset* +1920 px rồi vá đường nối).
- **18% dưới cùng bị nền đất của màn che** (mặt đất ở khoảng 83% chiều cao): đừng đặt chi tiết quan trọng ở đó.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa, tương phản thấp để nhân vật và quái nổi trên nền.
- Liền mạch với Chương 1 (cốt truyện owner 2026-11-15): golem ở 1-1 đã đổ nhưng **Lò Mẹ vẫn lạnh**; màn 1-2 đi ngược
  dốc về làng ở cửa thung lũng. Tro vẫn rơi thẳng (chưa có gió); hơi ấm duy nhất là đèn và khói bếp le lói trong làng.

#### Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: the mouth of the Ashen Valley; the giant cliff
furnace (the Mother Hearth) has gone cold, grey ash falls straight down with no wind, and only the village's small
lamps and chimney smoke give any warmth. Slightly desaturated, low contrast. No characters, no creatures, no text, no logo, no watermark.
The image must tile seamlessly horizontally (left and right edges match). The bottom 18% will be covered by the
ground tiles of the level, keep it plain.
```

#### Lớp xa — `bg_stage_01_02_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. Hazy dusk sky in grey-orange, the Eclipsed Sun high on the left third, soft ash particles
falling straight down. Far away on the right third, a tall cliff with a gigantic carved furnace gate, dark and cold
(the Mother Hearth gone out), only a faint dying ember glow deep inside. Distant grey mountain ridges along the horizon.
```

#### Lớp giữa — `bg_stage_01_02_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background above the hills (PNG with alpha). Gentle ash-covered hills, and on them the
small village of Coalhearth: stone-and-timber houses with dark tiled roofs, brick chimneys with thin cooking smoke,
a small water mill, warm lit windows. Buildings spaced so the layer repeats naturally.
```

#### Lớp gần — `bg_stage_01_02_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Foreground silhouettes darker than the other layers: a weathered
wooden fence, a few dead trees with ash on their branches, hanging iron lanterns with small flames, piles of coal and
charred logs, a half-burnt wooden signpost. Shapes stay low so the play area stays readable.
```

#### Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-2 theo docs/prompts/stages/STAGE_01_02_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu phong cách: assets/placeholders/story/placeholder_map_ch01.png (bố cục thung lũng),
   ảnh truyện tranh Chương 1 đã có trong assets/story/ch01/ (nếu có) để giữ cùng bảng màu, Mặt Trời Khuyết, Lò Mẹ.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_02/raw/. Viết tools/stages/fit_backdrop.py (Pillow): co về cao 2160,
   rộng 3840, làm mép trái/phải nối liền (trộn 128 px hai mép), mid/near giữ kênh alpha (tách nền nếu ảnh gốc không
   trong suốt). Lưu art_review/stages/stage_01_02/ và một ảnh _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-2":
   - chép vào assets/backgrounds/stages/stage_01_02/ đúng tên trong tài liệu (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-2: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

#### Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_02/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-2 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.
4. Muốn đổi tên file / hệ số trượt: sửa `backdrop` trong `tools/stages/gen_stage_01_02.py` rồi chạy lại script.


> Nguồn: `docs/prompts/stages/STAGE_01_03_BACKGROUND.md`

### Ảnh nền màn 1-3 "Hầm Than Ngầm" (3 lớp parallax)

> Màn `stage_01_03` (sinh bởi `tools/stages/gen_stage_01_03.py`) đọc 3 ảnh nền theo `backdrop` trong
> `data/stages/stage_01_03.json`. Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm.
> Quy cách giống màn 1-2: xem `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách).

#### Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_03/bg_stage_01_03_far.png` | 0.1 | Vách hầm sâu tối, vỉa than, mạch lửa ngầm le lói | Không (phủ kín) |
| Giữa | `.../bg_stage_01_03_mid.png` | 0.25 | Cột chống gỗ, đường ray xe goòng, dấu khắc ba vòng đá | Có |
| Gần | `.../bg_stage_01_03_near.png` | 0.55 | Đá nhũ, xe goòng lật, đèn mỏ treo, đống than | Có (giữa ảnh trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**, khoảng **15% trên cùng bị trần
  hầm che** (màn có trần đá 2–3 ô).
- Không nhân vật, không quái, không chữ. Tối nhưng đủ sáng để nhân vật và quái nổi lên (nền trung bình, không đen kịt).
- Liền mạch với 1-2: làng Lò Than nằm **ngay phía trên**; ánh cam ấm từ đèn mỏ và mạch lửa ngầm đang nguội (đỏ cam
  mờ trong khe đá). Cốt truyện owner 2026-11-15: mạch lửa bị **lấp bằng đá vụn còn mới** (kẻ đeo mặt nạ làm), lớp
  giữa có một đoạn chèn đá sáng màu hơn đá cũ. Dấu **ba vòng đá chồng nhau** phải giống dấu trên lưng golem ở ô truyện `ch01_end_11`.

#### Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt). Setting: old coal mine tunnels dug by ancient stone guardians,
right beneath Coalhearth Village at the mouth of the Ashen Valley. Cool grey-blue rock lit by warm orange lantern
light; a buried fire vein glows faintly red-orange in cracks, nearly gone cold; fine ash drifting. Slightly
desaturated, medium-low contrast, mid-tone (not pitch black) so characters stay readable. No characters, no creatures,
no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match). The bottom
18% will be covered by the ground tiles and the top 15% by the rock ceiling of the level, keep both plain.
```

#### Lớp xa — `bg_stage_01_03_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. A deep cavern wall with layered black coal seams, distant tunnel mouths fading into
darkness, thin glowing red-orange fissures of the cooling fire vein running horizontally, faint ash haze.
```

#### Lớp giữa — `bg_stage_01_03_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). Timber support frames and crossbeams at regular intervals,
an old minecart rail track on a ledge, and carved into one rock pillar a simple emblem of three overlapping stone
rings (ancient guardian workshop mark), weathered, softly lit by a lantern.
```

#### Lớp gần — `bg_stage_01_03_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent middle (PNG with alpha). Dark foreground silhouettes: stalactites hanging from the top
edge, an overturned minecart and coal piles along the bottom edge, iron mining lanterns hanging on chains with small
warm flames. Keep the central 60% height clear so the play area stays readable.
```

#### Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-3 theo docs/prompts/stages/STAGE_01_03_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: nền màn 1-2 đã duyệt trong assets/backgrounds/stages/stage_01_02/ (nếu có) để giữ cùng
   nét vẽ, bảng màu; ô truyện assets/story/ch01/ch01_end_11.png (nếu có) cho dấu ba vòng đá.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   rock style as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_03/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_03/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải trần (15% trên) và dải đất (18% dưới) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-3":
   - chép vào assets/backgrounds/stages/stage_01_03/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-3: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

#### Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_03/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-3 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.


> Nguồn: `docs/prompts/stages/STAGE_01_04_BACKGROUND.md`

### Ảnh nền màn 1-4 "Vách Lò Mẹ" (3 lớp parallax)

> Màn `stage_01_04` (sinh bởi `tools/stages/gen_stage_01_04.py`) đọc 3 ảnh nền theo `backdrop` trong
> `data/stages/stage_01_04.json`. Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm.
> Quy cách chung: xem `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách).

#### Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_04/bg_stage_01_04_far.png` | 0.08 | Trời, Mặt Trời Khuyết, toàn cảnh thung lũng nhìn từ trên cao, làng Lò Than nhỏ xa | Không (phủ kín) |
| Giữa | `.../bg_stage_01_04_mid.png` | 0.3 | Vách đá của Lò Mẹ, ống thông khí tạc vào đá, bị đá và tro lấp kín | Có |
| Gần | `.../bg_stage_01_04_near.png` | 0.6 | Gờ đá, xích sắt, cọc gỗ và dây thừng, cờ vải rủ xuống | Có (trên ~55% trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật nổi lên.
- Liền mạch với 1-2 / 1-3: cùng thung lũng tro, nay nhìn **từ trên vách cao**; Lò Mẹ **vẫn lạnh**
  (cốt truyện owner 2026-11-15), ống thông khí bị lấp cố ý, **chưa có gió**: tro rơi thẳng, cờ vải rủ. Gió chỉ trở lại
  ở clip kết chương (cuối 1-10).

#### Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: a narrow path high on the cliff that holds the Mother
Hearth, a gigantic furnace carved into the rock above the Ashen Valley; the furnace has gone cold, there is no wind,
and grey ash falls straight down. Slightly desaturated, low contrast. No characters, no creatures, no text, no
logo, no watermark. The image must tile seamlessly horizontally (left and right edges match). The bottom 18% will be
covered by the ground tiles of the level, keep it plain.
```

#### Lớp xa — `bg_stage_01_04_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. Wide sky in warm grey-orange, the Eclipsed Sun on the left third, ash hanging in the still
air. Far below, a panoramic view of the grey ash valley with a winding dirt road and the tiny
roofs of Coalhearth Village with thin chimney smoke rising straight up, distant mountain ridges along the horizon.
```

#### Lớp giữa — `bg_stage_01_04_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). The rugged dark rock face of the Hearth cliff with large
ancient vents carved into it at regular intervals, each deliberately packed with rubble and ash, old soot
stains around the vent mouths, a faint cold glow deep behind the rubble, a few stone stairways cut into the rock.
```

#### Lớp gần — `bg_stage_01_04_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Dark foreground silhouettes: jagged rock ledges, iron chains and
wooden posts with ropes along the path, a few tattered cloth banners hanging limp in the still air. Shapes stay low
so the play area stays readable.
```

#### Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-4 theo docs/prompts/stages/STAGE_01_04_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: nền màn 1-2 đã duyệt trong assets/backgrounds/stages/stage_01_02/ (nếu có) để giữ cùng
   nét vẽ, bảng màu, Mặt Trời Khuyết, dáng làng Lò Than và Lò Mẹ.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_04/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_04/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-4":
   - chép vào assets/backgrounds/stages/stage_01_04/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-4: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

#### Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_04/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-4 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.


> Nguồn: `docs/prompts/stages/STAGE_01_05_BACKGROUND.md`

### Ảnh nền màn 1-5 "Rừng Cây Chết" (3 lớp parallax)

> Màn `stage_01_05` (sinh bởi `tools/stages/gen_stages_01_05_10.py`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/stage_01_05.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/gen_stages_01_05_10.py` rồi chạy lại.

#### Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_05/bg_stage_01_05_far.png` | 0.1 | Trời xám cam, Mặt Trời Khuyết, vách Lò Mẹ lạnh tối ở xa, sườn núi tro | Không (phủ kín) |
| Giữa | `.../bg_stage_01_05_mid.png` | 0.3 | Rừng cây chết thân bạc, cọc đá khắc vòng trắng đen phát sáng yếu | Có |
| Gần | `.../bg_stage_01_05_near.png` | 0.6 | Thân cây gãy, rễ khô, gốc cây cháy đen | Có (trên ~55% trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: nối tiếp 1-4 (vách Lò Mẹ): lên cao hơn, vẫn **chưa có gió**, Lò Mẹ **lạnh**. Cọc ấn trắng-đen cùng kiểu vòng với mảnh ấn trong golem (ô truyện `ch01_golem_05/06`).

#### Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: a dead grove on the slope above the Ashen Valley; the Mother Hearth is cold, there is no wind, and grey ash falls straight down. Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level, keep it plain.
```

#### Lớp xa — `bg_stage_01_05_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. Hazy grey-orange sky, the Eclipsed Sun on the left third, ash falling straight down in still air. Far away on the right, the dark, cold cliff of the Mother Hearth; grey mountain slopes below.
```

#### Lớp giữa — `bg_stage_01_05_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). A grove of dead silver-grey trees with bare twisted branches, ash on every bough; here and there a carved stone stake with a faintly glowing half-white, half-black ring sigil, pulsing softly.
```

#### Lớp gần — `bg_stage_01_05_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Dark foreground silhouettes: broken trunks, dry roots and charred stumps along the bottom edge, a few hanging dead branches from the top corners. Keep the middle readable.
```

#### Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-5 theo docs/prompts/stages/STAGE_01_05_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: nền 1-4 đã duyệt trong assets/backgrounds/stages/stage_01_04/ (nếu có) để giữ nét, bảng màu, Mặt Trời Khuyết; ô truyện assets/story/ch01/ch01_golem_06.png (nếu có) cho kiểu vòng trắng-đen.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_05/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_05/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-5":
   - chép vào assets/backgrounds/stages/stage_01_05/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-5: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

#### Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_05/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-5 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.


> Nguồn: `docs/prompts/stages/STAGE_01_06_BACKGROUND.md`

### Ảnh nền màn 1-6 "Cầu Đá Treo" (3 lớp parallax)

> Màn `stage_01_06` (sinh bởi `tools/stages/gen_stages_01_05_10.py`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/stage_01_06.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/gen_stages_01_05_10.py` rồi chạy lại.

#### Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_06/bg_stage_01_06_far.png` | 0.1 | Vực sâu mù sương, vách đá đối diện, Mặt Trời Khuyết, thung lũng tro rất xa phía dưới | Không (phủ kín) |
| Giữa | `.../bg_stage_01_06_mid.png` | 0.3 | Trụ cầu đá cổ khắc dấu ba vòng đá, xích sắt đứt, nhịp cầu gãy treo lơ lửng | Có |
| Gần | `.../bg_stage_01_06_near.png` | 0.6 | Dây xích, mảnh đá vỡ, lan can cầu gãy | Có (trên ~55% trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: nối tiếp 1-5: cùng độ cao, cùng trời xám cam, **chưa có gió**. Dấu ba vòng đá giống lưng golem và hầm 1-3 (thủ vệ xây cầu).

#### Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: an ancient stone bridge built by the stone guardians across a deep chasm high above the Ashen Valley; the bridge has been deliberately broken in places; no wind, ash falls straight down. Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level, keep it plain.
```

#### Lớp xa — `bg_stage_01_06_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. A deep misty chasm between two grey cliffs, the Eclipsed Sun on the left third in a hazy grey-orange sky, the ash valley far, far below, ash hanging in still air.
```

#### Lớp giữa — `bg_stage_01_06_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). Massive ancient stone bridge pillars carved with a three-stacked-stone-ring emblem, broken bridge spans hanging at angles, snapped iron chains dangling, fresh pale cut marks on one pillar.
```

#### Lớp gần — `bg_stage_01_06_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Dark foreground silhouettes: chain links and broken stone railing pieces along the bottom edge, a snapped chain hanging from the top corner. Keep the middle readable.
```

#### Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-6 theo docs/prompts/stages/STAGE_01_06_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: nền 1-5 đã duyệt trong assets/backgrounds/stages/stage_01_05/ (nếu có); dấu ba vòng đá theo nền 1-3 (assets/backgrounds/stages/stage_01_03/) hoặc ô truyện ch01_end_11 (nếu có).
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_06/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_06/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-6":
   - chép vào assets/backgrounds/stages/stage_01_06/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-6: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

#### Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_06/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-6 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.


> Nguồn: `docs/prompts/stages/STAGE_01_07_BACKGROUND.md`

### Ảnh nền màn 1-7 "Trạm Thủ Vệ Bỏ Hoang" (3 lớp parallax)

> Màn `stage_01_07` (sinh bởi `tools/stages/gen_stages_01_05_10.py`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/stage_01_07.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/gen_stages_01_05_10.py` rồi chạy lại.

#### Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_07/bg_stage_01_07_far.png` | 0.1 | Tường đá trong trạm, hốc tường lớn trống rỗng, ánh sáng lọt qua khe trần | Không (phủ kín) |
| Giữa | `.../bg_stage_01_07_mid.png` | 0.3 | Cột đá khắc dấu ba vòng đá, giá đỡ lõi thủ vệ bị tháo, dây xích thả | Có |
| Gần | `.../bg_stage_01_07_near.png` | 0.6 | Đá vỡ, mảnh thủ vệ đá, bậc thềm sụt | Có (giữa ảnh trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**, khoảng **15% trên cùng bị trần đá che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: nối tiếp 1-6 (cùng dấu ba vòng đá, cùng đá xám); trong nhà nên không thấy trời. Hốc lõi trống có vết cạy **còn mới** (tay sai vừa lấy).

#### Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: inside an abandoned outpost of the ancient stone guardians, carved into the rock above the Ashen Valley; cold, dusty, silent, lit by faint orange light through cracks. Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level and the top 15% by the rock ceiling, keep it plain.
```

#### Lớp xa — `bg_stage_01_07_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. The deep interior wall of an ancient guardian outpost carved from grey stone: rows of large empty niches where stone guardian cores once sat, thin shafts of hazy orange light from cracks above.
```

#### Lớp giữa — `bg_stage_01_07_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). Carved stone columns bearing a three-stacked-stone-ring emblem, empty stone cradles with fresh pry marks where guardian cores were removed, iron chains hanging loose, a fallen stone guardian arm.
```

#### Lớp gần — `bg_stage_01_07_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent middle (PNG with alpha). Dark foreground silhouettes: rubble and broken pieces of stone guardians along the bottom edge, a cracked archway edge in a top corner. Keep the central 60% height clear.
```

#### Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-7 theo docs/prompts/stages/STAGE_01_07_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: nền 1-3 (hầm, có trần) và 1-6 đã duyệt trong assets/backgrounds/stages/ (nếu có) để giữ đá và dấu ba vòng đá.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_07/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_07/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới) và dải trần (15% trên) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-7":
   - chép vào assets/backgrounds/stages/stage_01_07/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-7: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

#### Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_07/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-7 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.


> Nguồn: `docs/prompts/stages/STAGE_01_08_BACKGROUND.md`

### Ảnh nền màn 1-8 "Trại Mặt Nạ" (3 lớp parallax)

> Màn `stage_01_08` (sinh bởi `tools/stages/gen_stages_01_05_10.py`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/stage_01_08.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/gen_stages_01_05_10.py` rồi chạy lại.

#### Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_08/bg_stage_01_08_far.png` | 0.1 | Hẻm đá hẹp, trời chạng vạng, Mặt Trời Khuyết bị che thêm | Không (phủ kín) |
| Giữa | `.../bg_stage_01_08_mid.png` | 0.3 | Trại tạm: lều vải than, hòm gỗ, giữa trại cột kênh trắng đen cao phát sáng | Có |
| Gần | `.../bg_stage_01_08_near.png` | 0.6 | Hòm, cọc lều, dây thừng, vũ khí dựng | Có (trên ~55% trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: nối tiếp 1-7; **chạng vạng** (trời bắt đầu tím), Mặt Trời Khuyết bị che **nhiều hơn** các màn trước. Cột kênh cùng kiểu vòng trắng-đen như cọc ấn 1-5; lưỡi móc đen giống vũ khí tay sai.

#### Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: the masked henchman's temporary camp hidden in a rocky gorge above the Ashen Valley at dusk; the Eclipsed Sun is noticeably more covered than before; no wind. Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level, keep it plain.
```

#### Lớp xa — `bg_stage_01_08_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. A narrow rocky gorge under a dusk sky turning violet-orange, the Eclipsed Sun with a larger dark bite than before, ash hanging in still air.
```

#### Lớp giữa — `bg_stage_01_08_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). A makeshift camp: charcoal-grey canvas tents, wooden crates, a cold campfire, and in the middle a tall black-and-white channel pylon made of stacked rings, glowing and pulling thin threads of orange heat out of the ground toward its top.
```

#### Lớp gần — `bg_stage_01_08_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Dark foreground silhouettes: crates, tent stakes and ropes, a rack of hooked black glaives along the bottom edge. Keep the middle readable.
```

#### Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-8 theo docs/prompts/stages/STAGE_01_08_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: nền 1-5 (cọc ấn) đã duyệt trong assets/backgrounds/stages/stage_01_05/ (nếu có); thiết kế tay sai docs/prompts/characters/HENCHMAN_DESIGN.md (ảnh đã duyệt, nếu có) cho kiểu lưỡi móc.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_08/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_08/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-8":
   - chép vào assets/backgrounds/stages/stage_01_08/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-8: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

#### Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_08/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-8 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.


> Nguồn: `docs/prompts/stages/STAGE_01_09_BACKGROUND.md`

### Ảnh nền màn 1-9 "Đường Về Cửa Lò" (3 lớp parallax)

> Màn `stage_01_09` (sinh bởi `tools/stages/gen_stages_01_05_10.py`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/stage_01_09.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/gen_stages_01_05_10.py` rồi chạy lại.

#### Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_09/bg_stage_01_09_far.png` | 0.1 | Trời đêm, nhật thực gần đầy (vành sáng mảnh), vách Lò Mẹ tối phía xa | Không (phủ kín) |
| Giữa | `.../bg_stage_01_09_mid.png` | 0.3 | Sườn đồi đêm, đường mòn đá, đá tảng và cây chết đen | Có |
| Gần | `.../bg_stage_01_09_near.png` | 0.6 | Đá tảng, cỏ khô, cọc đánh dấu đường | Có (trên ~55% trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: nối tiếp 1-8: **đêm**, Mặt Trời Khuyết gần như bị che hết (chỉ còn vành mảnh), vẫn **chưa có gió**. Khớp đêm ở ô truyện kết chương (`ch01_end_14`).

#### Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: a night trail descending back toward the Mother Hearth's gate in the Ashen Valley; the eclipse is almost total; cold, dark, no wind, violet Hollow Zone haze in the low ground. Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level, keep it plain.
```

#### Lớp xa — `bg_stage_01_09_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. A night sky in deep indigo, the Eclipsed Sun almost fully covered, only a thin pale orange crescent ring left; faint stars; far away on the right, the dark silhouette of the Mother Hearth cliff.
```

#### Lớp giữa — `bg_stage_01_09_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). Night hillside with a stone trail winding down, boulders and black dead trees, the cold faint violet glow of the Hollow Zone haze pooling in the hollows.
```

#### Lớp gần — `bg_stage_01_09_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Dark foreground silhouettes: boulders, dry grass tufts and old wooden trail markers along the bottom edge. Keep the middle readable.
```

#### Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-9 theo docs/prompts/stages/STAGE_01_09_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: nền 1-8 đã duyệt trong assets/backgrounds/stages/stage_01_08/ (nếu có); nền 1-2 (thung lũng, Lò Mẹ lạnh) để giữ dáng vách Lò Mẹ.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_09/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_09/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-9":
   - chép vào assets/backgrounds/stages/stage_01_09/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-9: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

#### Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_09/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-9 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.


> Nguồn: `docs/prompts/stages/STAGE_01_10_BACKGROUND.md`

### Ảnh nền màn 1-10 "Cửa Lò Mẹ" (3 lớp parallax)

> Màn `stage_01_10` (sinh bởi `tools/stages/gen_stages_01_05_10.py`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/stage_01_10.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/gen_stages_01_05_10.py` rồi chạy lại.

#### Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_10/bg_stage_01_10_far.png` | 0.1 | Đêm nhật thực đầy, vành sáng mảnh; vách Lò Mẹ khổng lồ, cửa lò tối om | Không (phủ kín) |
| Giữa | `.../bg_stage_01_10_mid.png` | 0.3 | Sân đá trước cửa lò, đá vỡ của golem, cột kênh trắng đen nhỏ cắm quanh | Có |
| Gần | `.../bg_stage_01_10_near.png` | 0.6 | Đá vụn, mảnh golem, xích lò | Có (trên ~55% trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: nối tiếp 1-9 (**đêm**, nhật thực gần đầy); **cùng nơi** với ô truyện `ch01_golem_01` và `ch01_end_01` (cửa lò, đá vỡ golem). Sau trận, clip kết chương cho lò cháy lại.

#### Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: the forecourt of the Mother Hearth, a gigantic furnace carved into the cliff of the Ashen Valley, on the night of the deepest eclipse; the furnace is cold, there is no wind. Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level, keep it plain.
```

#### Lớp xa — `bg_stage_01_10_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. Night of the deepest eclipse: an indigo sky, the Eclipsed Sun reduced to a thin bright ring; the gigantic carved furnace gate of the Mother Hearth fills the right half, dark and cold, a barely visible dying ember deep inside.
```

#### Lớp giữa — `bg_stage_01_10_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). The stone forecourt before the furnace gate: huge broken boulders of the fallen stone golem, and a few small black-and-white ring pylons planted around, faintly glowing.
```

#### Lớp gần — `bg_stage_01_10_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Dark foreground silhouettes: rubble and golem fragments along the bottom edge, old iron furnace chains hanging from the top corner. Keep the middle readable.
```

#### Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-10 theo docs/prompts/stages/STAGE_01_10_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: ô truyện assets/story/ch01/ch01_golem_01.png và ch01_end_01.png (nếu có) để khớp cửa lò và đá vỡ golem; nền 1-9 đã duyệt trong assets/backgrounds/stages/stage_01_09/ (nếu có).
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_10/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_10/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-10":
   - chép vào assets/backgrounds/stages/stage_01_10/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-10: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

#### Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_10/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-10 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.
