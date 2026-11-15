# Ảnh nền màn 1-1 "Thung Lũng Tro Tàn" (3 lớp parallax)

> Màn `stage_01` (sinh bởi `tools/stages/gen_stage_01_backdrop.py`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/stage_01.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/gen_stage_01_backdrop.py` rồi chạy lại.

## Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01/bg_stage_01_far.png` | 0.1 | Trời xám cam mù, Mặt Trời Khuyết, cuối thung lũng là vách đá có cửa Lò Mẹ khổng lồ tối om | Không (phủ kín) |
| Giữa | `.../bg_stage_01_mid.png` | 0.3 | Sườn thung lũng tro xám, đường đất dốc, cây chết, biển gỗ cháy xém | Có |
| Gần | `.../bg_stage_01_near.png` | 0.6 | Đá, gốc cây cháy, cỏ khô phủ tro | Có (trên ~55% trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: cùng nơi với ô truyện `ch01_open_01` (cửa thung lũng) và `ch01_open_10` (cuối thung lũng có golem); Lò Mẹ **lạnh**, **không gió**, tro rơi thẳng. Là nền chuẩn cho bảng màu cả Chương 1.

## Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: the Ashen Valley seen from inside, the road leading down toward the Mother Hearth, a giant furnace carved into a cliff, which has gone cold; there is no wind and grey ash falls straight down. Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level, keep it plain.
```

## Lớp xa — `bg_stage_01_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. Hazy grey-orange afternoon sky, the Eclipsed Sun on the left third, ash falling perfectly straight down. Far away at the end of the valley on the right third, a towering cliff with a gigantic carved furnace gate, dark and cold (the Mother Hearth).
```

## Lớp giữa — `bg_stage_01_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). Grey ash-covered valley slopes with a dirt road sloping down toward the far cliff, scattered dead trees, a half-burnt wooden signpost, a faint violet haze line crossing the ground (the edge of the Hollow Zone).
```

## Lớp gần — `bg_stage_01_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Dark foreground silhouettes: rocks, charred stumps and ash-covered dry grass along the bottom edge. Keep the middle readable.
```

## Prompt gửi Codex (đã liên kết dự án)

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

## Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-1 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.
