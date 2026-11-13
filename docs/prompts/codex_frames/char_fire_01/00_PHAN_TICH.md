# Phân tích model Enkiba (char_fire_01, giáp Hỏa Diễm Mãnh Liệt)

> Do Claude quan sát từ ảnh gốc và idle đã duyệt (2026-11-13); màu có ghi "đo" là lấy từ pixel của `idle_000`, còn lại là
> ước lượng bằng mắt. Phần 1 của `../PROMPT_GOC.md` yêu cầu đọc file này.

## Tỉ lệ và nét vẽ

- Chibi khoảng **2.5 đầu**: đầu to, thân ngắn, tay chân ngắn; bàn tay và ủng to rõ.
- Nét viền nâu sẫm / đen, dày khoảng 2–3 px ở canvas 384, **không** đổi màu viền theo vùng; cel shading 2–3 tầng, highlight
  tóc và mắt rõ; không gradient mềm.
- Idle đã duyệt cao **273–291 px** (trung bình ~281) trong canvas 384×384, chân ở y = 336, tâm x = 192.

## Bảng màu chính

| Vùng | Màu |
|---|---|
| Tóc đỏ thẫm | #9D2A27 (tối #6B1E1D, đo) |
| Lọn tóc cam phía trước | cam sáng ~#E8731F (ước lượng) |
| Mắt | hổ phách ~#E0A030 (ước lượng) |
| Da | #F5D7C0 (bóng #D49366, đo) |
| Áo khoác, găng, ủng | đen #1A110F – #382A23 (đo), viền vàng ~#D9A441 |
| Áo sơ mi | trắng ngà |
| Quần, đuôi áo | đỏ sẫm #6B1E1D (đo); đuôi áo có hoa văn lửa đỏ – cam |
| Giáp vai | đỏ #8C1F22 (đo) + viền vàng |
| Đế ủng | cam |
| Khóa thắt lưng | vàng, hình ngọn lửa |
| Kiếm | thân đỏ – cam hoa văn lửa, chắn kiếm vàng, ngọc cam |

## Các bộ phận và thứ tự lớp (từ xa → gần camera, khi quay phải)

1. Tóc sau, đuôi áo sau (vạt áo dài hoa văn lửa), **kiếm đeo lưng** (chuôi và ngọc nhô lên trên vai gần)
2. Tay xa, chân xa
3. Thân: sơ mi, áo khoác, thắt lưng
4. Chân gần, ủng gần
5. Tay gần + găng
6. Giáp vai (chỉ **một**, ở vai gần camera)
7. Đầu: mặt, tóc trước, lọn cam, các lọn rời

Biểu cảm mặc định: nghiêm, miệng mím, lông mày hơi chau. Mặt biểu cảm sẵn trong bảng bộ phận: số 04 (há miệng hét, dùng khi
tụ lực / tuyệt kỹ), 05 (nhắm mắt đau, dùng khi bị đánh).

## Hai trạng thái của kiếm (quyết định cho animation)

- **Kiếm đeo lưng** (idle đã duyệt): chéo sau lưng, chuôi vàng và ngọc cam nhô trên vai gần. Dùng cho idle, run, jump_up,
  fall, land, dodge, hurt, knockback, down, switch_out.
- **Kiếm cầm tay** (ảnh gốc 3/4): cầm ở tay gần camera, lưỡi dài hướng về trước / xuống. Dùng cho mọi đòn đánh, kỹ năng,
  tụ lực, tiếp đất đánh, tuyệt kỹ, vào sân. Frame đầu của các animation này đã có kiếm trong tay (khoảnh khắc rút kiếm
  nằm ngoài khung hình), và `skill_2` kết thúc bằng tra kiếm nửa chừng ra sau lưng.
- **Chưa quyết (hỏi owner khi cần):** có làm animation rút kiếm / tra kiếm riêng giữa idle và đòn đánh hay không. Hiện kiếm
  "xuất hiện" ngay, chấp nhận được cho bản đầu.

## Góc nhìn và pivot

- Ảnh gốc là 3/4 nhìn nghiêng phải; idle đã duyệt là **nhìn ngang quay phải** — chuẩn cho mọi animation.
- Pivot = giữa hai bàn chân (tâm trọng tâm phần chân 35% dưới của hình), đường chân y = 336. Animation trên không giữ độ cao
  tương đối giữa các frame, không kéo chân về 336.
- Điểm dễ sai khi lật: kiếm đeo lưng, giáp vai một bên, lọn tóc cam bên trái mặt. Soát bằng `anim_flip.gif`.
