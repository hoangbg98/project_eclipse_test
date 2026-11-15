# Ảnh nền màn 1-6 "Cầu Đá Treo" (3 lớp parallax)

> Màn `stage_01_06` (sinh bởi `tools/stages/gen_stages_01_05_10.py`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/stage_01_06.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/gen_stages_01_05_10.py` rồi chạy lại.

## Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_06/bg_stage_01_06_far.png` | 0.1 | Vực sâu mù sương, vách đá đối diện, Mặt Trời Khuyết, thung lũng tro rất xa phía dưới | Không (phủ kín) |
| Giữa | `.../bg_stage_01_06_mid.png` | 0.3 | Trụ cầu đá cổ khắc dấu ba vòng đá, xích sắt đứt, nhịp cầu gãy treo lơ lửng | Có |
| Gần | `.../bg_stage_01_06_near.png` | 0.6 | Dây xích, mảnh đá vỡ, lan can cầu gãy | Có (trên ~55% trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: nối tiếp 1-5: cùng độ cao, cùng trời xám cam, **chưa có gió**. Dấu ba vòng đá giống lưng golem và hầm 1-3 (thủ vệ xây cầu).

## Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: an ancient stone bridge built by the stone guardians across a deep chasm high above the Ashen Valley; the bridge has been deliberately broken in places; no wind, ash falls straight down. Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level, keep it plain.
```

## Lớp xa — `bg_stage_01_06_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. A deep misty chasm between two grey cliffs, the Eclipsed Sun on the left third in a hazy grey-orange sky, the ash valley far, far below, ash hanging in still air.
```

## Lớp giữa — `bg_stage_01_06_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). Massive ancient stone bridge pillars carved with a three-stacked-stone-ring emblem, broken bridge spans hanging at angles, snapped iron chains dangling, fresh pale cut marks on one pillar.
```

## Lớp gần — `bg_stage_01_06_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Dark foreground silhouettes: chain links and broken stone railing pieces along the bottom edge, a snapped chain hanging from the top corner. Keep the middle readable.
```

## Prompt gửi Codex (đã liên kết dự án)

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

## Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_06/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-6 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.
