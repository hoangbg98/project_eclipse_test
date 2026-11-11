# PROJECT ECLIPSE — Tổng quan dự án

> Nguồn: `README.md` (đặc tả, Revision 4) và `docs/design/CHARACTER_SKILLS.md`.
> Tài liệu này tóm tắt; khi có mâu thuẫn, hai file nguồn thắng (README 17.1).

## Tầm nhìn

Game **2D side-scrolling Action RPG phong cách anime** (không phải pixel art),
chơi offline một người, phát hành thương mại trên **Windows PC** và
**Android**. Engine **Godot 4.6.3**, ngôn ngữ **GDScript**.

## Trụ cột thiết kế

1. Combat phản hồi nhanh: đòn đánh dễ đọc, điều khiển nhạy, trạng thái kỹ năng rõ ràng.
2. Đội 3 người: **một người trên sân**, hai người dự bị ở icon góc trên phải;
   chuyển người bằng switch-in skill, Liên kết sinh phản ứng nguyên tố.
3. Trình bày anime: sprite vẽ tay theo frame, cảnh nhiều lớp, VFX chăm chút.
4. Tiến trình RPG: cấp nhân vật, trang bị, kho đồ, phần thưởng.
5. Offline-first: dữ liệu và save cục bộ, không bắt buộc mạng.
6. Đa nền tảng: chung code gameplay cho Windows và Android.

## Vòng lặp chơi cốt lõi

```
Hub → chọn màn → chọn đội 3 người → chiến đấu (di chuyển, nhảy, đánh,
kỹ năng, né, chuyển người, phản ứng) → boss → kết quả + phần thưởng →
nâng cấp / trang bị / chiêu mộ (gacha offline) → lưu → màn tiếp theo
```

## Phạm vi bản thương mại đầu tiên (vertical slice, README 9 và 2.3)

| Thành phần | Nội dung |
|---|---|
| Nhân vật chơi đầy đủ | `char_fire_01` (Aether, Hỏa) — đủ bộ kỹ năng |
| Hai nhân vật dự bị | `char_lightning_01` (Kael), `char_wind_01` (Lyra) — switch-in, di chuyển, đòn thường, né (quyết định Q5, xem DEVELOPMENT_LOG) |
| Phản ứng có trong slice | Hỏa+Lôi (Quá Tải), Hỏa+Phong (Hỏa Lốc), Phong+Lôi (Bão Sét); data model hỗ trợ đủ 15 cặp |
| Kẻ địch | 1 loại quái thường |
| Màn chơi | 1 màn side-scroll ngắn (3–5 phút, 2–3 đợt quái) |
| Boss | 1 boss, ít nhất 2 phase dễ đọc |
| Khác | HUD tối thiểu, pause, kết quả + phần thưởng, save/load, gacha offline |

**Hoãn sau slice:** quest, nâng cấp trang bị, đổi phím, bản dịch ngoài ngôn ngữ
gốc (chữ vẫn qua `tr()`), nhân vật ngoài 3 người của slice (data model vẫn hỗ
trợ cả 6).

## Đội hình (tên tạm, chỉ dùng trong phát triển)

| Tên tạm | Data ID | Nguyên tố | Vai trò | Vũ khí |
|---|---|---|---|---|
| Aether | `char_fire_01` | Hỏa | Main DPS | Kiếm |
| Lyra | `char_wind_01` | Phong | Support | Cung |
| Kael | `char_lightning_01` | Lôi | Sub-DPS | Song đao |
| Seraphine | `char_light_01` | Quang | Healer | Trượng |
| Noctis | `char_dark_01` | Ám | Control | Lưỡi hái |
| Terra | `char_earth_01` | Địa | Tank | Đại kiếm |

Code và data chỉ dùng Data ID. **Aether** và **Noctis** trùng tên nhân vật nổi
tiếng của bên thứ ba: phải đổi trước khi phát hành công khai (README 2.1).

## Ngoài phạm vi bản đầu

Tiền thật, cửa hàng, mạng xã hội, chơi online, AI cho nhân vật dự bị.
