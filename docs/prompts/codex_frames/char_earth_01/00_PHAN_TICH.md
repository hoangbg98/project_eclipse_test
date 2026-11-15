# Phân tích model Iwagane (char_earth_01, giáp Thần Kiếm Nham Thạch)

> Do Claude quan sát từ tờ bộ phận gốc của owner (2026-11-15) và tên bộ phận owner đã điền ở trang
> "Bảng tên bộ phận Iwagane". Màu ước lượng bằng mắt từ `rig_parts/source/refs/char_earth_01_ref_01_toan_than.png`.
> Phần 1 của `../PROMPT_GOC.md` yêu cầu đọc file này. Chưa có idle đã duyệt: **làm `idle` trước**,
> các animation sau canh chiều cao theo nó.

## Tỉ lệ và nét vẽ

- Iwagane là **nữ, lớn tuổi nhất nhóm, dáng cao** (owner 2026-11-15): người trưởng thành cuối hai mươi, mặt điềm tĩnh, không trẻ con.
- Chibi khoảng **3 đầu** (cao hơn các nhân vật khác ~2.5 đầu): đầu vẫn to, nhưng thân và chân dài hơn; thân chắc, vai giáp to tròn; ủng to.
- Pose mẫu nhỏ (52–57) khóa nét chibi, giáp và cỡ kiếm; khi vẽ frame cho chân dài hơn mẫu một chút. Ảnh toàn thân (số 1)
  cao gần 4 đầu, chỉ dùng để khóa chi tiết và màu.
- Nét viền nâu sẫm gần đen, dày khoảng 2–3 px ở canvas 384; cel shading 2–3 tầng, highlight kim loại trên giáp đồng.
- Mục tiêu chiều cao đứng **~300 px** trong canvas 384×384 (các nhân vật khác ~280 px, Iwagane cao nhất nhóm), chân ở y = 336, tâm x = 192.
  Đại kiếm dài gần bằng người: được vượt khung người nhưng không ra khỏi canvas (khi vung qua đầu có thể phải thu nhỏ góc vung).

## Bảng màu chính (ước lượng)

| Vùng | Màu |
|---|---|
| Tóc | nâu sẫm ~#553629, bóng nâu đen |
| Da | rám nắng ~#C98B5E |
| Mắt | hổ phách vàng ~#D99A3E |
| Sẹo | đỏ nâu, chữ X ở má phải + vài vết xước mảnh |
| Giáp vai, giáp ngực, vambrace, ống chân | đồng ~#B58A4E, bóng nâu ~#6A4B2C |
| Mảng xanh trên giáp, áo trong, váy | xanh rêu ô liu ~#5E6B32 |
| Tabard trước | nâu sẫm ~#523628, viền răng cưa và chữ rune màu be |
| Ủng | da nâu, mũi thép xám |
| Đại kiếm | lưỡi đá xám nâu sần, chữ rune vàng mảnh dọc giữa; chắn kiếm đồng chạm hoa văn; chuôi quấn da nâu; đuôi chuôi hình thoi bằng đồng có viên đá vàng |

## Các bộ phận và thứ tự lớp (từ xa → gần camera, khi quay phải)

Tên theo trang điền tên (số trong ngoặc là số khung trên tờ bộ phận).

1. Tóc sau (10, 11, 12), lọn tóc rời (13)
2. Tay xa + găng (18–23, 26–27, 30–31, 34–35), giáp cẳng tay xa (28, 29), chân xa + giáp ống chân + ủng (32–33, 36–37)
3. Thân: áo trong (16 trước / 17 sau), giáp ngực + cổ áo (15), váy giáp + thắt lưng + vải rune (25), mảnh giáp/da (46–51)
4. Chân gần, ủng gần
5. Tay gần + giáp vai (14) + giáp cẳng tay (24) + **đại kiếm** (38; 39 là chuôi khi lưỡi bị che)
6. Đầu: mặt (2–7, 41–45), tóc trước (8), bím tóc (9) rủ trước vai phải

Biểu cảm mặc định: nghiêm, quyết đoán. Mặt có sẵn (`rig_parts/source/refs/`): 02 bình thường, 04 nhắm mắt (bị đánh, ngã),
05 ngạc nhiên (bị hất), 06 hét (đòn kết, Kĩ năng vũ khí, tuyệt kỹ), 07 cười nhếch (khiêu khích). Mặt trong tờ bộ phận là
**đầu chưa có tóc**: chỉ lấy nét mặt.

## Đại kiếm

- Iwagane **luôn cầm đại kiếm**: tay gần (phải) nắm chuôi; đòn nặng (đòn 3, trên không, đáp đất, kĩ năng, tuyệt kỹ) cầm **hai tay**.
  Không buông kiếm, không cất, không chuyển hẳn sang tay xa.
- Lúc đứng: mũi kiếm chúc xuống cạnh chân như pose 52. Lúc chạy / nhảy: vác kiếm lên vai.
- `hold_charge` (Thủ Thế Đại Địa): **kiếm cắm đất** trước người làm khiên, hai tay giữ chuôi; `hold_release` frame đầu vẫn cắm, sau đó rút lên chém.
- Chữ rune trên lưỡi là hoa văn của kiếm (nét vàng mảnh), **không phát sáng**. Ảnh tham chiếu 56, 57 có vệt chém trắng, đá bay
  và tia vàng: **không vẽ** vào frame; game thêm VFX riêng (sóng đá, gai đá, giáp đá, nứt đất, kiếm đá khổng lồ của tuyệt kỹ).
- Kiếm nặng: mọi đòn có lấy đà rõ, dồn trọng lượng, vung hết đà; chậm hơn Enkiba / Raikiba.

## Góc nhìn và pivot

- Ảnh toàn thân (số 1) và pose 52, 53 nhìn 3/4 chính diện; **animation vẽ nhìn ngang quay phải** — lấy 54 (thủ kiếm),
  55 (lao tới), 56 (chém xoáy), 57 (tụ lực) làm mẫu góc nhìn ngang.
- Pivot = giữa hai bàn chân, đường chân y = 336. Animation trên không giữ độ cao tương đối giữa các frame, không kéo chân về 336.
- Điểm dễ sai khi lật: **bím tóc luôn ở vai phải**, **sẹo X ở má phải**, kiếm không nhảy tay. Quay phải thì má phải và vai phải
  là phía gần camera nên bím tóc và sẹo phải thấy rõ. Soát bằng `anim_flip.gif`.

## Ghi chú theo kỹ năng

- Số frame / fps / frame trúng đòn tính từ `data/skills/char_earth_01/` (đã có đủ SkillDef).
- `hold_charge` lặp 4 frame (game giữ tới 2,5 s, dựng kiếm 120 ms nằm trong frame đầu). `hold_release` dùng SkillDef `hold_slash`
  (140/90/300 ms); bản yếu `hold_slash_weak` cùng thời gian, dùng chung hình.
- `skill_2` (Thạch Phá Thiên Kích) hiệu lực dài 500 ms: giữ thế đè kiếm trong lúc gai đá chạy (VFX), không vung thêm.
- `ultimate` 650 / 1 200 / 500 ms → 19 frame ở 8 fps, tạo trong nhiều lần gọi. Ba đợt sóng chấn nằm trong pha hiệu lực:
  người rung theo từng đợt, kiếm vẫn cắm đất.
- `switch_in` (Đại Địa Giáng Thế) bắt đầu trên không, kết thúc chạm đất.
