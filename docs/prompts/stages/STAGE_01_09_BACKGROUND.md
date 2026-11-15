# Ảnh nền màn 1-9 "Đường Về Cửa Lò" (3 lớp parallax)

> Màn `stage_01_09` (sinh bởi `tools/stages/gen_stages_01_05_10.py`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/stage_01_09.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/gen_stages_01_05_10.py` rồi chạy lại.

## Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_09/bg_stage_01_09_far.png` | 0.1 | Trời đêm, nhật thực gần đầy (vành sáng mảnh), vách Lò Mẹ tối phía xa | Không (phủ kín) |
| Giữa | `.../bg_stage_01_09_mid.png` | 0.3 | Sườn đồi đêm, đường mòn đá, đá tảng và cây chết đen | Có |
| Gần | `.../bg_stage_01_09_near.png` | 0.6 | Đá tảng, cỏ khô, cọc đánh dấu đường | Có (trên ~55% trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: nối tiếp 1-8: **đêm**, Mặt Trời Khuyết gần như bị che hết (chỉ còn vành mảnh), vẫn **chưa có gió**. Khớp đêm ở ô truyện kết chương (`ch01_end_14`).

## Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: a night trail descending back toward the Mother Hearth's gate in the Ashen Valley; the eclipse is almost total; cold, dark, no wind, violet Hollow Zone haze in the low ground. Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level, keep it plain.
```

## Lớp xa — `bg_stage_01_09_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. A night sky in deep indigo, the Eclipsed Sun almost fully covered, only a thin pale orange crescent ring left; faint stars; far away on the right, the dark silhouette of the Mother Hearth cliff.
```

## Lớp giữa — `bg_stage_01_09_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). Night hillside with a stone trail winding down, boulders and black dead trees, the cold faint violet glow of the Hollow Zone haze pooling in the hollows.
```

## Lớp gần — `bg_stage_01_09_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Dark foreground silhouettes: boulders, dry grass tufts and old wooden trail markers along the bottom edge. Keep the middle readable.
```

## Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-9 theo docs/prompts/stages/STAGE_01_09_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: nền 1-8 đã duyệt trong assets/backgrounds/stages/stage_01_08/ (nếu có); nền 1-2 (thung lũng, Lò Mẹ lạnh) để giữ dáng vách Lò Mẹ.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_09/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_09/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-9":
   - chép vào assets/backgrounds/stages/stage_01_09/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-9: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

## Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_09/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-9 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.
