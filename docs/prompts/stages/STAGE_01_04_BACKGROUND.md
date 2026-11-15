# Ảnh nền màn 1-4 "Vách Lò Mẹ" (3 lớp parallax)

> Màn `stage_01_04` (sinh bởi `tools/stages/gen_stage_01_04.py`) đọc 3 ảnh nền theo `backdrop` trong
> `data/stages/stage_01_04.json`. Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm.
> Quy cách chung: xem `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách).

## Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_04/bg_stage_01_04_far.png` | 0.08 | Trời, Mặt Trời Khuyết, toàn cảnh thung lũng nhìn từ trên cao, làng Lò Than nhỏ xa | Không (phủ kín) |
| Giữa | `.../bg_stage_01_04_mid.png` | 0.3 | Vách đá của Lò Mẹ, ống thông khí tạc vào đá, bị đá và tro lấp kín | Có |
| Gần | `.../bg_stage_01_04_near.png` | 0.6 | Gờ đá, xích sắt, cọc gỗ và dây thừng, cờ vải rủ xuống | Có (trên ~55% trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật nổi lên.
- Liền mạch với 1-2 / 1-3: cùng thung lũng tro, nay nhìn **từ trên vách cao**; Lò Mẹ **vẫn lạnh**
  (cốt truyện owner 2026-11-15), ống thông khí bị lấp cố ý, **chưa có gió**: tro rơi thẳng, cờ vải rủ. Gió chỉ trở lại
  ở clip kết chương (cuối 1-10).

## Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: a narrow path high on the cliff that holds the Mother
Hearth, a gigantic furnace carved into the rock above the Ashen Valley; the furnace has gone cold, there is no wind,
and grey ash falls straight down. Slightly desaturated, low contrast. No characters, no creatures, no text, no
logo, no watermark. The image must tile seamlessly horizontally (left and right edges match). The bottom 18% will be
covered by the ground tiles of the level, keep it plain.
```

## Lớp xa — `bg_stage_01_04_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. Wide sky in warm grey-orange, the Eclipsed Sun on the left third, ash hanging in the still
air. Far below, a panoramic view of the grey ash valley with a winding dirt road and the tiny
roofs of Coalhearth Village with thin chimney smoke rising straight up, distant mountain ridges along the horizon.
```

## Lớp giữa — `bg_stage_01_04_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). The rugged dark rock face of the Hearth cliff with large
ancient vents carved into it at regular intervals, each deliberately packed with rubble and ash, old soot
stains around the vent mouths, a faint cold glow deep behind the rubble, a few stone stairways cut into the rock.
```

## Lớp gần — `bg_stage_01_04_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Dark foreground silhouettes: jagged rock ledges, iron chains and
wooden posts with ropes along the path, a few tattered cloth banners hanging limp in the still air. Shapes stay low
so the play area stays readable.
```

## Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-4 theo docs/prompts/stages/STAGE_01_04_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: nền màn 1-2 đã duyệt trong assets/backgrounds/stages/stage_01_02/ (nếu có) để giữ cùng
   nét vẽ, bảng màu, Mặt Trời Khuyết, dáng làng Lò Than và Lò Mẹ.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_04/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_04/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-4":
   - chép vào assets/backgrounds/stages/stage_01_04/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-4: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

## Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_04/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-4 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.
