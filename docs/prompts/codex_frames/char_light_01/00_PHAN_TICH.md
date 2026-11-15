# Phân tích model Hikarine (char_light_01)

> Do Claude quan sát từ tờ bộ phận gốc của owner (2026-11-15) và tên bộ phận owner đã điền ở trang
> "Bảng tên bộ phận Hikarine". Màu ước lượng bằng mắt từ `rig_parts/source/refs/char_light_01_ref_01_toan_than.png`.
> Phần 1 của `../PROMPT_GOC.md` yêu cầu đọc file này. Chưa có idle đã duyệt: **làm `idle` trước**,
> các animation sau canh chiều cao theo nó.

## Tỉ lệ và nét vẽ

- Hikarine là healer hệ Quang, cô gái hiền, dịu dàng; vai trò hồi máu và hộ thuẫn (CHARACTER_SKILLS.md mục 4, tên cũ Seraphine).
- Chibi khoảng **2.5 đầu**: đầu to, tay chân ngắn. Pose mẫu nhỏ (42–47) khóa tỉ lệ chibi; ảnh toàn thân (số 1) cao hơn,
  chỉ dùng để khóa chi tiết và màu.
- Nét viền nâu sẫm gần đen, dày khoảng 2–3 px ở canvas 384; cel shading 2–3 tầng, highlight vàng kim trên viền áo và gậy.
- Mục tiêu chiều cao đứng **~280 px** trong canvas 384×384, chân ở y = 336, tâm x = 192. Gậy dài gần bằng người: được vượt khung
  người nhưng không ra khỏi canvas. Tóc dài quá gối làm bóng người rộng: chừa chỗ khi tóc bay.

## Bảng màu chính (ước lượng)

| Vùng | Màu |
|---|---|
| Tóc | vàng nhạt kem ~#EDE3C2, bóng ~#C9B88E, mặt trong tóc sau ngả be nâu ~#C8B391 |
| Da | hồng nhạt ~#F6DCC8 |
| Mắt | nâu sáng ~#A0705A |
| Vòng miện | vàng kim ~#C9A24A, đá nhỏ giữa trán |
| Áo, tay áo, váy ngoài, ủng | trắng ngà ~#F7F3EA, bóng xám tím nhạt |
| Viền và hoa văn | vàng kim ~#D2AE5A |
| Váy lót | xám tím nhạt ~#D3CCDD |
| Đai lưng, nơ, dải đai | xanh lam nhạt ~#A9C1DA, bóng ~#7F9CBE |
| Gậy phép | thân vàng kim, cổ gậy uốn cong; đầu là vòng mặt trời có tia nhọn, giữa là quả cầu vàng nhạt |

## Các bộ phận và thứ tự lớp (từ xa → gần camera, khi quay phải)

Tên theo trang điền tên (số trong ngoặc là số khung trên tờ bộ phận; PNG ở `rig_parts/`).

1. Tóc sau (10), lọn tóc rời (12–14)
2. Tay áo rộng xa (15 hoặc 17), cánh tay xa (20, 21), bàn tay xa (22–24), chân + ủng xa (26)
3. Thân: váy dài nhiều lớp (19), áo thân trên cổ đứng (16), đai lưng xanh có nơ (18) với hai dải đai rủ trước váy
4. Chân + ủng gần (25)
5. Tay áo rộng gần, tay gần + **gậy phép** (27; 28 là vòng mặt trời rời)
6. Đầu: mặt (2–7, 31–35), tóc hai bên mặt (11), tóc mái (8), vòng miện (9)

Biểu cảm mặc định: mỉm cười hiền. Mặt có sẵn (`rig_parts/source/refs/`): 02 bình thường, 04 nhắm mắt chắp tay (cầu nguyện),
05 nhắm mắt bình thản (chữa lành, vào sân), 06 ngạc nhiên (bị hất), 07 hét / niệm phép (đòn 3, kĩ năng vũ khí, tuyệt kỹ),
33 mệt (bị hạ gục), 35 nghiến răng (bị đánh). Mặt trong tờ bộ phận là **đầu chưa có tóc**: chỉ lấy nét mặt.

**Mảnh giáp xanh-vàng (36–41)** có trên tờ nhưng **không thấy trên ảnh toàn thân và các pose mẫu**: không vẽ vào frame.
Nếu owner muốn Hikarine mang chúng (vd một giáp khác), owner báo để sửa phần thiết kế trong `tools/frames/jobs/char_light_01.json`.

## Gậy phép

- Hikarine **luôn cầm gậy**: tay gần cầm thân gậy; phép mạnh (đòn 3, kĩ năng vũ khí, tuyệt kỹ, đáp đất) dùng **hai tay**.
  Không buông gậy, không chuyển hẳn sang tay xa.
- Lúc đứng: gậy dựng đứng cạnh người, đáy gậy chạm đất như pose 42. Lúc chạy: cầm chéo, đầu gậy chếch lên trước.
- `hold_charge` (Thánh Quang Cầu Nguyện): **hai tay chắp trước ngực ôm gậy dựng đứng**, mắt nhắm (pose 45, mặt 04).
- Quả cầu trong vòng mặt trời là một phần của gậy: vẽ quả cầu vàng nhạt đặc, không vẽ quầng sáng lớn hay tia. Ảnh 44–47 có quầng
  vàng, khiên sáng, tia sáng: **không vẽ** vào frame; game thêm VFX riêng (quả cầu bay, tia xuyên, mưa sáng, vòng cầu nguyện,
  cột sáng, mặt trời nhỏ, vùng thánh, cánh sáng).
- Đòn đánh thường là **phép bắn** (quả cầu bay 450 px): pose chạm / chĩa đầu gậy về trước và giữ một nhịp, không chém.

## Góc nhìn và pivot

- Ảnh toàn thân (số 1) và pose 42, 44, 45 nhìn 3/4 chính diện; **animation vẽ nhìn ngang quay phải** — pose 43 (bước đi) và 46
  (dựng khiên) gần góc ngang nhất, dùng làm mẫu góc nhìn.
- Pivot = giữa hai bàn chân, đường chân y = 336. Animation trên không giữ độ cao tương đối giữa các frame, không kéo chân về 336.
- Điểm dễ sai khi lật: **nơ đai xanh ở hông trái** cùng hai dải đai, gậy không nhảy tay. Vòng miện, áo, váy đối xứng.
  Soát bằng `anim_flip.gif`.

## Ghi chú theo kỹ năng

- Số frame / fps / frame trúng đòn tính từ `data/skills/char_light_01/` (đã có đủ SkillDef).
- `hold_charge` lặp 6 frame (SkillDef `hold_1`: khởi động 150 / tối đa 3 000 / hồi phục 220 ms): phiếu không gắn SkillDef vì
  hình là vòng lặp, game giữ tới khi thả nút. Không có `hold_release`.
- `air_1` và `air_2` dùng chung SkillDef thời gian và cùng animation `air_1`: chỉ một phiếu.
- `skill_2` (Thái Dương Phán Xét) không có hiệu lực tức thì (quả cầu rơi trễ 600 ms): phiếu ghi `hits_ms` để đánh dấu frame phóng quả cầu.
- `ultimate` 700 / 300 / 400 ms (vùng thánh 8 s là VFX, không thuộc hình). Game nâng nhân vật lên 200 px; trong frame chỉ cần
  chân rời đất, giữ trong canvas. Không vẽ 6 cánh sáng.
- `switch_in` (Quang Giáng Hộ Vệ, mục 8.8) bắt đầu trên không, kết thúc chạm đất, gõ đáy gậy xuống đất.
