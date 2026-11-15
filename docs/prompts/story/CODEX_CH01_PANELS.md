# Prompt gửi Codex: vẽ 39 ô truyện tranh Chương 1 (liền mạch)

> Owner dán khối **PROMPT CHÍNH** vào Codex (đang mở ở thư mục dự án). Codex tự đọc kịch bản trong
> `docs/prompts/story/CH01_PANELS.md`, tạo ảnh bằng skill `imagegen`, làm **từng trang một** và dừng chờ duyệt.
> Sau mỗi trang owner trả lời `duyệt trang N` (hoặc `sửa ô XX: ...`).

## PROMPT CHÍNH (dán vào Codex)

```text
Việc: vẽ ảnh thật cho 39 ô truyện tranh Chương 1 (ch01_open_01..15, ch01_golem_01..10, ch01_end_01..14) thay
placeholder. Thứ tự vẽ: open → golem → end (cốt truyện owner 2026-11-15: golem chỉ chặn đường, kẻ chủ mưu là
tay sai đeo mặt nạ, Lò Mẹ chỉ cháy lại ở clip end).
Đọc trước: AGENTS.md (mục 4 "Ảnh do AI tạo"), docs/prompts/story/CH01_PANELS.md (kịch bản, kích thước, prompt,
ảnh tham chiếu từng ô), data/story/ch01_open.json, ch01_golem.json, ch01_end.json (đa giác "poly" của từng ô).

YÊU CẦU LIỀN MẠCH (quan trọng nhất)
1. Trước khi vẽ, tạo art_review/story/ch01/CONTINUITY.md (không vào git) gồm:
   - Bảng nhân vật: ngoại hình khóa theo ảnh tham chiếu (tóc, mắt, áo, vũ khí); Raikiba luôn cầm 2 dao, Kazeyumi
     cung + ống tên, Enkiba kiếm lưỡi cam vân lửa. NEO: vòng sáng cyan, lõi sáng, cỡ bằng bàn tay, bay ngang vai.
     Tay sai đeo mặt nạ (golem_07, end_01..04): giáp xám tro viền cam xỉn, mặt nạ đen trơn (không bao giờ lộ mặt),
     áo choàng than rách, huy hiệu vòng trắng-đen trên ngực, vũ khí lưỡi móc đen. Ô golem_07 đầu tiên vẽ hắn là
     bản gốc: các ô sau đính kèm ô đó làm tham chiếu.
   - Bản đồ cảnh: hướng nhìn cố định — đi VÀO thung lũng = đi sang PHẢI khung hình; cửa Lò Mẹ luôn ở phía phải/xa.
     Vị trí đứng mặc định: Kazeyumi trái, Enkiba giữa, Raikiba phải (giữ quy tắc 180°, đổi phía phải có lý do).
   - Dòng thời gian trạng thái: Mặt Trời Khuyết vị trí và độ cao như nhau suốt "open" và "golem"; tro rơi THẲNG,
     không gió suốt open, golem và end_01..05; Lò Mẹ TỐI LẠNH suốt open, golem và end_01..04, CHÁY từ end_05/end_06
     (ánh cam ấm phủ cảnh sau đó); gió trở lại từ end_07 (tóc, áo choàng, tro bay ngang); end_14 là ĐÊM. Vạch mờ
     tím của Vùng Rỗng ở open_01/02/13. Đá vỡ golem nằm trước cửa lò từ golem_01 tới hết end.
   - Đạo cụ xuyên ô: biển gỗ cháy (open_04), đá vỡ golem (golem_01 → end_11), đĩa trắng-đen thứ nhất (golem_05/06),
     hai đĩa (end_08/09/12), dấu khắc ba vòng đá (end_11), giáp nứt của tay sai (end_01..04).
   - Bảng màu chung: xám tro + cam nhạt, giảm bão hòa nhẹ; sau end_06 ấm hơn.
2. Vẽ ĐÚNG THỨ TỰ ô. Mỗi ô đính kèm vào image_gen:
   a) ảnh tham chiếu nhân vật ghi trong CH01_PANELS.md;
   b) ô liền trước đã duyệt (cùng cảnh) + ô "neo phong cách" open_01 (với "golem" thêm golem_01, "end" thêm end_01);
   c) nếu nhân vật vừa xuất hiện ở ô trước, đính kèm ô có nhân vật đó gần nhất.
   Thêm vào prompt của ô một câu nối: "Same scene, lighting, palette and character designs as the attached previous
   panel; continuity: <trạng thái lấy từ CONTINUITY.md>". Giữ nguyên đoạn style chung và phần Characters của ô.
3. Không chữ, không bóng thoại, không viền ô, không watermark. Không bắt chước nhân vật/thương hiệu bên thứ ba.

KỸ THUẬT
- Tạo ở khung gần tỉ lệ nhất (1536x1024 / 1024x1024 / 1024x1536), chép ảnh gốc từ $CODEX_HOME/generated_images/
  vào art_review/story/ch01/raw/.
- Viết tools/story/fit_panel.py (Pillow): cắt theo tỉ lệ khung bao của "poly", co về đúng kích thước 2x ghi trong
  CH01_PANELS.md (vd open_01 = 3680x760), không méo hình; lưu art_review/story/ch01/<tên>.png.
  Kèm _preview/<tên>_mask.png: ảnh với vùng ngoài đa giác tô tối, để kiểm tra chủ thể nằm trong vùng hiện.
- Mỗi trang xong: ghép _preview/page_<clip>_<N>.png = 1920x1080 nền đen, đặt các ô đúng poly (giống trong game)
  để owner xem cả trang liền mạch. DỪNG, gửi đường dẫn preview, chờ owner.

KHI OWNER "duyệt trang N"
- Chép các ô của trang vào assets/story/ch01/<tên>.png (không ghi đè file đã có, nếu có thì -v2 và hỏi).
- Chạy: C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import
- Ghi từng file vào docs/ASSET_LICENSES.md mục 2.1 (file, Codex imagegen + model, prompt rút gọn, ảnh tham chiếu,
  ngày). Chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (phải mã thoát 0).
- Ghi nhật ký docs/DEVELOPMENT_LOG.md, commit "Story: ch01 page N panels" (không push).
- Sửa theo góp ý "sửa ô XX: ..." thì vẽ lại ô đó, cập nhật CONTINUITY.md nếu đổi trạng thái, kiểm tra lại các ô
  sau nó có còn khớp không.

Bắt đầu: tạo CONTINUITY.md, rồi vẽ Trang 1 của ch01_open (ô 01–03). Trả lời tôi bằng tiếng Việt.
```

## Hướng dẫn owner thay ảnh

**Codex làm tự động** (cách trên): chỉ cần duyệt từng trang. Ảnh vào `assets/story/ch01/` là game tự dùng; không sửa code.

**Đang chạy dở bản cũ (29 ô)?** Nhắn Codex: "Kịch bản đổi (owner 2026-11-15): đọc lại docs/prompts/story/CH01_PANELS.md và CODEX_CH01_PANELS.md, cập nhật CONTINUITY.md, giữ các ô open đã duyệt (ảnh không đổi), vẽ tiếp theo thứ tự open → golem → end."

**Tự thay tay** (khi muốn dùng ảnh tự làm/sửa trong Photoshop):

1. Lưu PNG đúng tên vào `assets/story/ch01/` — ví dụ `ch01_open_01.png`. Tỉ lệ khung phải đúng kích thước ghi trong
   `CH01_PANELS.md` (1× hoặc 2×); sai tỉ lệ thì ảnh bị kéo méo vì game căng ảnh theo khung bao của ô.
2. Canh chủ thể bằng placeholder `assets/placeholders/story/placeholder_<tên>.png` làm lớp dưới: vùng xám là phần hiện,
   vùng gạch chéo bị cắt.
3. Mở Godot (hoặc chạy lệnh dưới) để Godot nhập ảnh mới — game chỉ thấy ảnh đã có file `.import`:

   ```bash
   C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import
   ```

4. Xem thử nhanh không cần chơi (chụp trang 1 và 3 ra `build/screenshots/story_<id>_*.png`):

   ```bash
   C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --path . -s tools/screenshot_story.gd -- ch01_open
   ```

   Đổi `ch01_open` thành `ch01_golem` (cuối ải 1-1) hoặc `ch01_end` (kết chương, cuối ải 1-10). Trong game, clip chỉ chạy một lần mỗi save (vào ải 1-1 /
   sau boss chương 1); muốn xem lại thì dùng save mới.
5. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.
6. Muốn trở lại placeholder: xóa file trong `assets/story/ch01/` (kèm `.import`).
