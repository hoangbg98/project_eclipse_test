# Ảnh nền màn 1-8 "Trại Mặt Nạ" (3 lớp parallax)

> Màn `stage_01_08` (sinh bởi `tools/stages/gen_stages_01_05_10.py`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/stage_01_08.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/gen_stages_01_05_10.py` rồi chạy lại.

## Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_08/bg_stage_01_08_far.png` | 0.1 | Hẻm đá hẹp, trời chạng vạng, Mặt Trời Khuyết bị che thêm | Không (phủ kín) |
| Giữa | `.../bg_stage_01_08_mid.png` | 0.3 | Trại tạm: lều vải than, hòm gỗ, giữa trại cột kênh trắng đen cao phát sáng | Có |
| Gần | `.../bg_stage_01_08_near.png` | 0.6 | Hòm, cọc lều, dây thừng, vũ khí dựng | Có (trên ~55% trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: nối tiếp 1-7; **chạng vạng** (trời bắt đầu tím), Mặt Trời Khuyết bị che **nhiều hơn** các màn trước. Cột kênh cùng kiểu vòng trắng-đen như cọc ấn 1-5; lưỡi móc đen giống vũ khí tay sai.

## Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: the masked henchman's temporary camp hidden in a rocky gorge above the Ashen Valley at dusk; the Eclipsed Sun is noticeably more covered than before; no wind. Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level, keep it plain.
```

## Lớp xa — `bg_stage_01_08_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. A narrow rocky gorge under a dusk sky turning violet-orange, the Eclipsed Sun with a larger dark bite than before, ash hanging in still air.
```

## Lớp giữa — `bg_stage_01_08_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). A makeshift camp: charcoal-grey canvas tents, wooden crates, a cold campfire, and in the middle a tall black-and-white channel pylon made of stacked rings, glowing and pulling thin threads of orange heat out of the ground toward its top.
```

## Lớp gần — `bg_stage_01_08_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Dark foreground silhouettes: crates, tent stakes and ropes, a rack of hooked black glaives along the bottom edge. Keep the middle readable.
```

## Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-8 theo docs/prompts/stages/STAGE_01_08_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: nền 1-5 (cọc ấn) đã duyệt trong assets/backgrounds/stages/stage_01_05/ (nếu có); thiết kế tay sai docs/prompts/characters/HENCHMAN_DESIGN.md (ảnh đã duyệt, nếu có) cho kiểu lưỡi móc.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_08/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_08/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-8":
   - chép vào assets/backgrounds/stages/stage_01_08/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-8: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

## Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_08/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-8 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.
