# Ảnh nền màn 1-5 "Rừng Cây Chết" (3 lớp parallax)

> Màn `stage_01_05` (sinh bởi `tools/stages/gen_stages_01_05_10.py`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/stage_01_05.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/gen_stages_01_05_10.py` rồi chạy lại.

## Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_05/bg_stage_01_05_far.png` | 0.1 | Trời xám cam, Mặt Trời Khuyết, vách Lò Mẹ lạnh tối ở xa, sườn núi tro | Không (phủ kín) |
| Giữa | `.../bg_stage_01_05_mid.png` | 0.3 | Rừng cây chết thân bạc, cọc đá khắc vòng trắng đen phát sáng yếu | Có |
| Gần | `.../bg_stage_01_05_near.png` | 0.6 | Thân cây gãy, rễ khô, gốc cây cháy đen | Có (trên ~55% trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: nối tiếp 1-4 (vách Lò Mẹ): lên cao hơn, vẫn **chưa có gió**, Lò Mẹ **lạnh**. Cọc ấn trắng-đen cùng kiểu vòng với mảnh ấn trong golem (ô truyện `ch01_golem_05/06`).

## Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: a dead grove on the slope above the Ashen Valley; the Mother Hearth is cold, there is no wind, and grey ash falls straight down. Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level, keep it plain.
```

## Lớp xa — `bg_stage_01_05_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. Hazy grey-orange sky, the Eclipsed Sun on the left third, ash falling straight down in still air. Far away on the right, the dark, cold cliff of the Mother Hearth; grey mountain slopes below.
```

## Lớp giữa — `bg_stage_01_05_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). A grove of dead silver-grey trees with bare twisted branches, ash on every bough; here and there a carved stone stake with a faintly glowing half-white, half-black ring sigil, pulsing softly.
```

## Lớp gần — `bg_stage_01_05_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Dark foreground silhouettes: broken trunks, dry roots and charred stumps along the bottom edge, a few hanging dead branches from the top corners. Keep the middle readable.
```

## Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-5 theo docs/prompts/stages/STAGE_01_05_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: nền 1-4 đã duyệt trong assets/backgrounds/stages/stage_01_04/ (nếu có) để giữ nét, bảng màu, Mặt Trời Khuyết; ô truyện assets/story/ch01/ch01_golem_06.png (nếu có) cho kiểu vòng trắng-đen.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_05/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_05/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-5":
   - chép vào assets/backgrounds/stages/stage_01_05/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-5: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

## Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_05/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-5 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.
