# Prompt gốc: animation nhân vật chibi anime 2D side-scrolling

> Chuyển thể từ file `Prompt_Chibi_Anime_SideScroll.txt` của owner (2026-11-13) cho dự án PROJECT ECLIPSE. Mọi phiếu
> `NN_<animation>.md` của một nhân vật đều dựa trên file này. Phần riêng của từng nhân vật (bảng màu, bộ phận, trạng thái
> kiếm, pivot) nằm ở `<id>/00_PHAN_TICH.md`. Codex đọc file này trước khi làm bất kỳ phiếu nào.

## 0. Bối cảnh game

- Thể loại: action RPG side-scrolling, đội 3 người, nhìn ngang 2D. Nhân vật mặc định quay mặt sang **phải**; hướng trái do
  engine lật ngang. Mọi chi tiết bất đối xứng (vũ khí ở bên nào, giáp vai một bên, lọn tóc cam) phải **nhất quán** khi lật:
  đã có `anim_flip.gif` trong `_preview/` để soát.
- Nhịp chiến đấu nhanh, đòn đánh đọc rõ ở cỡ nhỏ. Hitbox KHÔNG vẽ vào hình: game bật hitbox theo frame trúng đòn
  (`frame_jobs.py` tính từ `data/skills/`), nên **pose trúng đòn phải đọc rõ** (kiếm duỗi hết, giữ một nhịp).
- Canvas mỗi frame **384×384**, nền trong suốt; chân ở **y = 336**, tâm thân **x = 192**; nhân vật đứng cao khoảng 280 px
  (đo từ idle đã duyệt). Tên file `{id}_{animation}_{NNN}.png` đánh số từ 000.

## 1. Phân tích model gốc (làm một lần cho mỗi nhân vật)

Đã có sẵn ở `<id>/00_PHAN_TICH.md`: tỉ lệ chibi, nét viền, kiểu đổ bóng, bảng màu, tóc, mặt, trang phục, vũ khí và trạng thái
vũ khí, góc nhìn, lớp (layer) từng bộ phận, pivot. Đọc trước khi tạo ảnh. Nếu ảnh tham chiếu mâu thuẫn nhau (vd kiếm cầm
tay ở ảnh 3/4 nhưng đeo lưng ở idle), **idle đã duyệt là chuẩn cho nhìn ngang**; báo owner thay vì tự chọn.

## 2. Bảo toàn ngoại hình (quan trọng nhất)

- Không thiết kế lại nhân vật. Không đổi kiểu tóc, màu tóc, khuôn mặt, mắt, biểu cảm mặc định.
- Biểu cảm chỉ đổi theo trạng thái (hét khi tụ lực, nhắm mắt khi bị đánh), giữ đúng kiểu vẽ mắt / miệng của model gốc;
  mặt biểu cảm có sẵn trong bảng bộ phận (số 04, 05).
- Không đổi trang phục, giáp, phụ kiện, vũ khí; không đổi tỉ lệ chibi đầu : thân : tay : chân.
- Không tự ý thêm hay xóa chi tiết. Squash & stretch chỉ ở mức rất nhẹ, có kiểm soát, và trở về đúng hình gốc.
- Chỉ được đổi: tư thế, vị trí các bộ phận, biểu cảm theo trạng thái.

## 3. Yêu cầu chuyển động

Mỗi đòn có 3 giai đoạn rõ: **Startup** (lấy đà), **Active** (khoảnh khắc đánh trúng), **Recovery** (thu hồi). Phiếu ghi sẵn
frame nào thuộc giai đoạn nào (tính từ thời gian kỹ năng).

- Áp dụng: anticipation, follow-through, overlapping action (tóc, vạt áo, đuôi áo trễ nhịp so với thân), ease in / ease out,
  chuyển động theo cung (arcs), giữ frame (hold) có chủ đích ở lúc va chạm để tăng cảm giác lực.
- Tay chân ngắn kiểu chibi vẫn phải đọc rõ động tác. Không xuyên thân / kiếm; thứ tự lớp tay chân gần – xa camera luôn đúng.
- Hình bóng (silhouette) từng pose phải đủ rõ để phân biệt chém, nhảy, bị đánh chỉ bằng bóng đen.
- Animation lặp (idle, run, hold_charge): frame cuối nối khít frame đầu. Animation không lặp: có điểm bắt đầu / kết thúc rõ.
- Chuyển trạng thái mượt: pose đầu của đòn gần với thế đứng / chạy mà đòn đó nối vào; pose cuối gần thế đứng.
- Vệt chém, hào quang, lửa, bụi, tia sáng **không vẽ vào frame nhân vật** (làm riêng ở `assets/vfx/`, có thể dùng pixelfx).

## 4. Giữ nguyên phong cách đồ họa

Giữ độ dày và màu nét viền, kiểu đổ bóng cel shading, vị trí highlight tóc / mắt, bảng màu; không đổi sắc độ giữa các frame,
không làm mờ, không đổi nét giữa các frame. Không 3D, không realistic, không đổi tỉ lệ chibi. Đặt hai frame bất kỳ cạnh nhau
vẫn như cùng một họa sĩ vẽ. Ảnh tham chiếu bắt buộc đính kèm mỗi lần tạo ảnh: **idle đã duyệt** (khóa nét + màu + góc nhìn
ngang), ảnh gốc 3/4, hình kiếm; từ lần gọi thứ 2 trong một animation, đính kèm thêm dải vừa tạo.

## 5. Xuất file và tích hợp (đã có công cụ, không tự làm tay)

1. `tools/frames/slice_strip.py` cắt dải thành frame chuẩn, cùng tỉ lệ với idle (`--like idle`), vào `art_review/`.
2. `tools/frames/check_frames.py` kiểm: đủ frame, 384×384, alpha, chân 336, không bị cắt mép, tỉ lệ so với idle; sinh
   `sheet.png` (đường chân, tâm, frame trúng đòn viền đỏ), `anim.gif` (đúng fps), `anim_flip.gif` (lật trái).
3. Owner duyệt từng animation. Chỉ khi owner nói "duyệt <animation>" mới chạy `tools/frames/approve_frames.py`: chép vào
   `assets/`, cập nhật `frames_manifest.json` (số frame, fps, loop), ghi `docs/ASSET_LICENSES.md` mục 2.1.
4. fps: Idle 8–12, Run 12–15, đòn đánh / kỹ năng 12–24 (chọn tự động theo thời lượng kỹ năng). State machine, cancel window,
   hitbox đã có trong code và `data/skills/`: **không tạo JSON atlas hay state machine mới**.

## 6. Tự kiểm tra trước khi gửi owner

1. Còn giống hoàn toàn model gốc không? 2. Bộ phận nào đổi kích thước, tỉ lệ chibi, biến dạng? 3. Nét viền, bảng màu, đổ
bóng đồng nhất giữa các frame? 4. Chuyển động tự nhiên, liền mạch, đọc rõ ở cỡ in-game? 5. Chân / tâm nhất quán giữa các
frame và so với idle? 6. Lật sang trái còn đúng (kiếm không nhảy tay)? 7. Có xuyên vật thể, sai lớp, lệch khớp? 8. Tích hợp
được vào game (check ĐẠT)? Sai lệch ngoại hình thì sửa lại frame đó từ ảnh gốc.

## 7. Nguyên tắc thực hiện

- Không thay model gốc; không động tới tài nguyên, gameplay, chỉ số, trang bị, giao diện không liên quan.
- Mỗi lần **một animation**, dừng ở `art_review/` chờ owner duyệt. Không ghi đè asset đã có (tạo bản mới hoặc `--replace`
  khi owner đồng ý). Không commit khi chưa duyệt.
- Walk, guard, victory, death trong prompt gốc của owner: game chưa có các trạng thái đó nên chưa có phiếu; thêm vào
  `tools/frames/jobs/<id>.json` khi game có.
