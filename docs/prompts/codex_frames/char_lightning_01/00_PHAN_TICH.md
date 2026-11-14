# Phân tích model Raikiba (char_lightning_01, giáp Nanh Của Lôi Thần)

> Do Claude quan sát từ tờ bộ phận gốc của owner (2026-11-14) và tên bộ phận owner đã điền ở trang
> "Bảng tên bộ phận Raikiba". Màu ghi "đo" lấy từ pixel `rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`;
> còn lại ước lượng bằng mắt. Phần 1 của `../PROMPT_GOC.md` yêu cầu đọc file này. Chưa có idle đã duyệt: **làm `idle` trước**,
> các animation sau canh chiều cao theo nó.

## Tỉ lệ và nét vẽ

- Chibi khoảng **2.5 đầu**: đầu to, tóc nhọn bù xù làm đầu trông to hơn nữa; thân ngắn, quần túi hộp rộng, ủng to.
- Nét viền đen, dày khoảng 2–3 px ở canvas 384; cel shading 2–3 tầng, không gradient mềm.
- Mục tiêu chiều cao đứng **~280 px** trong canvas 384×384 (như Enkiba, Kazeyumi), chân ở y = 336, tâm x = 192.
  Đao và lọn tóc được phép vượt khung người nhưng không ra khỏi canvas.

## Bảng màu chính

| Vùng | Màu |
|---|---|
| Tóc | bạc trắng, bóng xám ~#8B8993; lọn vàng chanh #F4F430 (đo) ở mái và đuôi tóc |
| Da | #F8CCA9 (đo) |
| Mắt | xanh lục lam (ước lượng ~#2FB3A8) |
| Áo ba lỗ cổ cao khóa kéo, quần túi hộp | đen xanh #2F3140 (đo); viền / sọc tia sét vàng |
| Đai bắp tay, găng cụt ngón, băng quấn cổ tay | đen, khóa bạc nhỏ |
| Thắt lưng | đen, khóa bạc; dây đai đen thả lủng lẳng ở quần |
| Ủng | xám nhạt, đế đen, dây buộc vàng |
| Song đao | lưỡi cong răng cưa đen – vàng, gân sét vàng; chuôi quấn đen, vòng tròn ở đuôi chuôi |

## Các bộ phận và thứ tự lớp (từ xa → gần camera, khi quay phải)

Tên lấy theo trang điền tên (số trong ngoặc là số khung trên tờ bộ phận).

1. Tóc sau (8, 9), lọn tóc vàng rời (10)
2. Tay xa + găng + **đao xa** (13–18, 20–21, 34), chân xa + ủng xa (27–28, 31–32)
3. Thân: áo (11 trước / 12 sau), thắt lưng và khóa (24, 46, 47), dây đai (40, 41), quần (19)
4. Chân gần, ủng gần
5. Tay gần + găng + băng quấn (42, 44, 45) + **đao gần** (33)
6. Đầu: mặt (2–6, 35–39), tóc trước (7)

Biểu cảm mặc định: nghiêm, lạnh. Mặt có sẵn (`rig_parts/source/refs/`): 02 mặc định, 03 cười nhếch, 06 la hét (bị hất, tuyệt kỹ),
37 gồng nhắm nghiến (tụ lực), 38 hét đau (bị đánh, ngã). Mặt trong tờ bộ phận là **đầu chưa có tóc**: chỉ lấy nét mặt.

## Luôn cầm hai đao

- Raikiba **cầm mỗi tay một đao ở mọi frame** (idle, chạy, nhảy, bị đánh, ngã), cầm xuôi, lưỡi hướng ra trước. Không cất đao, không đổi tay.
- Ngoại lệ: `skill_2` (Song Lôi Phi Nhận) — từ frame ném trở đi **tay không**; đao bay vòng cung và quay về là vật thể của game.
  `weapon_catch`: frame 000 tay không, từ frame 001 đao đã về tay. Game phát nó khi đao về (~940 ms) nếu nhân vật đang đứng yên.
- Ảnh tham chiếu có ánh sét vàng quanh đao và người: **không vẽ ánh sét / tia điện / bóng mờ** vào frame; game thêm VFX riêng.

## Góc nhìn và pivot

- Ảnh toàn thân (số 1) là 3/4 nhìn chính diện; **animation vẽ nhìn ngang quay phải** — lấy pose 48 (đứng), 49 (chạy),
  50 (lao chém), 51 (lướt), 52 (tụ sét) làm mẫu góc nhìn.
- Pivot = giữa hai bàn chân, đường chân y = 336. Animation trên không giữ độ cao tương đối giữa các frame, không kéo chân về 336.
- Điểm dễ sai khi lật: mỗi tay đúng một đao (không mất đao, không hai đao một tay), lọn vàng ở mái lệch một bên. Soát bằng `anim_flip.gif`.

## Ghi chú theo kỹ năng

- Số frame / fps / frame trúng đòn tính từ `data/skills/char_lightning_01/` (đã có đủ SkillDef).
- `hold_release` (Lôi Quang Loạn Vũ) là **vòng chém lặp** 6 frame: game giữ tối đa 1,2 s và dừng khi thả nút, nên không tính
  theo thời lượng kỹ năng. Đoạn lao tới mục tiêu là chuyển động của game. Nhả nút hoặc hết 8 nhịp → `hold_end`
  (SkillDef `hold_finish`, 0/90/220 ms): nhát chém chéo xuống kết thúc, không thêm sát thương.
- `skill_2` ghi `hits_ms` = khoảnh khắc ném (đao bay là vật thể, không quyết định pose).
- `ultimate` dài 2,7 s (800 / 1 500 / 400 ms) → 22 frame ở 8 fps, tạo trong 4 lần gọi; dịch chuyển, cột sét, cut-in là VFX.
