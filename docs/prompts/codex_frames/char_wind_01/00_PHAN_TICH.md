# Phân tích model Kazeyumi (char_wind_01, giáp Đôi Cánh Của Gió)

> Do Claude quan sát từ tờ bộ phận gốc của owner (2026-11-14). Màu ghi "đo" lấy từ pixel ảnh toàn thân
> `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`; còn lại ước lượng bằng mắt. Phần 1 của
> `../PROMPT_GOC.md` yêu cầu đọc file này. Chưa có idle đã duyệt: **làm `idle` trước**, các animation sau canh chiều cao theo nó.

## Tỉ lệ và nét vẽ

- Chibi khoảng **2.5 đầu**: đầu to, thân ngắn, tay chân ngắn; ủng cao tới gối, cây cung cao gần bằng người.
- Nét viền nâu đen #1C1E14 (đo), dày khoảng 2–3 px ở canvas 384; cel shading 2–3 tầng, không gradient mềm.
- Mục tiêu chiều cao đứng **~280 px** trong canvas 384×384 (như Enkiba), chân ở y = 336, tâm x = 192. Cung và đuôi tóc được
  phép vượt khung người nhưng không ra khỏi canvas.

## Bảng màu chính

| Vùng | Màu |
|---|---|
| Tóc xanh bạc hà | #84C3A9, sáng #9DC9B3, bóng #587C6F (đo) |
| Da | #EDCBB1, sáng #EFDCC6 (đo) |
| Mắt | xanh lục lam ~#3E8C7E (ước lượng) |
| Áo chẽn cổ cao | trắng ngà #F0ECDB (đo), viền vàng ~#D2A94A, dấu lá xanh |
| Áo choàng một vai, váy xếp ly | xanh lục lam đậm #2A4B42 – #43786B (đo); khóa áo choàng tròn màu vàng |
| Dây da chéo, túi, bao tay, ống tên | nâu #5D4F40 (đo), khóa vàng |
| Quần ngắn trong váy | đen |
| Ủng | trắng ngà, viền xanh lục lam, dây nâu, cánh nhỏ trắng ở cổ chân |
| Kẹp tóc | lông vũ trắng + ngọc xanh lục lam |
| Cung | kem – vàng, quấn dây xanh lục lam, đính hạt kim cương, ruy băng xanh lá ở chuôi |
| Mũi tên | thân nâu nhạt, lông trắng, đầu bạc |

## Các bộ phận và thứ tự lớp (từ xa → gần camera, khi quay phải)

1. Đuôi tóc, tóc sau, ống tên sau lưng, áo choàng (phần sau)
2. Tay xa (tay **kéo dây** khi bắn), chân xa
3. Thân: áo chẽn, dây da chéo, thắt lưng + túi, váy
4. Chân gần, ủng gần
5. Tay gần + bao tay + **cây cung** (tay trước, chĩa về mục tiêu bên phải)
6. Áo choàng phần vắt qua vai, khóa vàng
7. Đầu: mặt, tóc trước, lọn tóc hai bên, kẹp lông vũ

Biểu cảm mặc định: dịu, tự tin, miệng hơi mỉm. Mặt có sẵn trong bảng bộ phận (`rig_parts/source/refs/`): số 01 mặc định,
05 tức giận / tập trung (tụ lực), 06 đau (bị đánh), 47 nghiêng hét (tuyệt kỹ).

## Luôn cầm cung, mũi tên là vật thể của game

- Kazeyumi **cầm cung ở mọi frame** (cả idle, chạy, nhảy, bị đánh, ngã). Không cất cung, không đổi tay.
- Hai trạng thái trong phiếu:
  - `ready`: cung cầm hạ thấp ở tay trước, dây thả lỏng, không lắp tên.
  - `shoot`: tay trước giương cung chĩa về mục tiêu (bên phải), tay sau kéo dây tới má với mũi tên lắp sẵn, rồi thả.
- **Không vẽ mũi tên đã bay đi**: sau frame thả dây, game tự sinh đạn (projectile) và VFX gió. Chỉ vẽ tên khi đang lắp / kéo.
- Pose kéo cung nhìn ngang quay phải (ảnh số 57) là chuẩn góc nhìn và cách cầm.

## Góc nhìn và pivot

- Ảnh toàn thân là 3/4 nhìn chính diện; **animation vẽ nhìn ngang quay phải** — lấy pose 54 – 59 làm mẫu góc nhìn.
- Pivot = giữa hai bàn chân, đường chân y = 336. Animation trên không giữ độ cao tương đối giữa các frame, không kéo chân về 336.
- Điểm dễ sai khi lật: cung ở tay trước (gần camera), áo choàng vắt **một** vai, kẹp lông vũ một bên đầu. Soát bằng `anim_flip.gif`.

## Thời gian kỹ năng và phiếu bổ sung

- Đã có đủ SkillDef trong `data/skills/char_wind_01/`; phiếu lấy số frame / fps từ đó (riêng `landing_attack` giữ 70/80/220 ms
  như bản đã duyệt, `skill_2` ghi `hits_ms` theo 6 phát tên).
- Phiếu bổ sung 2026-11-14: `hold_release_2` (Xuyên Phong Tiễn cấp 2, nạp đủ 1,6 s) và `air_2` (phát thứ hai trên không).
  Khi chưa có hình, game mượn `hold_release` / `air_1` (`PlayerController.animation_or_fallback`).
