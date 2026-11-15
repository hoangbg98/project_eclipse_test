# Ảnh nền màn 1-3 "Hầm Than Ngầm" (3 lớp parallax)

> Màn `stage_01_03` (sinh bởi `tools/stages/gen_stage_01_03.py`) đọc 3 ảnh nền theo `backdrop` trong
> `data/stages/stage_01_03.json`. Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm.
> Quy cách giống màn 1-2: xem `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách).

## Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_03/bg_stage_01_03_far.png` | 0.1 | Vách hầm sâu tối, vỉa than, mạch lửa ngầm le lói | Không (phủ kín) |
| Giữa | `.../bg_stage_01_03_mid.png` | 0.25 | Cột chống gỗ, đường ray xe goòng, dấu khắc ba vòng đá | Có |
| Gần | `.../bg_stage_01_03_near.png` | 0.55 | Đá nhũ, xe goòng lật, đèn mỏ treo, đống than | Có (giữa ảnh trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**, khoảng **15% trên cùng bị trần
  hầm che** (màn có trần đá 2–3 ô).
- Không nhân vật, không quái, không chữ. Tối nhưng đủ sáng để nhân vật và quái nổi lên (nền trung bình, không đen kịt).
- Liền mạch với 1-2: làng Lò Than nằm **ngay phía trên**; ánh cam ấm từ đèn mỏ và mạch lửa ngầm đang nguội (đỏ cam
  mờ trong khe đá). Cốt truyện owner 2026-11-15: mạch lửa bị **lấp bằng đá vụn còn mới** (kẻ đeo mặt nạ làm), lớp
  giữa có một đoạn chèn đá sáng màu hơn đá cũ. Dấu **ba vòng đá chồng nhau** phải giống dấu trên lưng golem ở ô truyện `ch01_end_11`.

## Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt). Setting: old coal mine tunnels dug by ancient stone guardians,
right beneath Coalhearth Village at the mouth of the Ashen Valley. Cool grey-blue rock lit by warm orange lantern
light; a buried fire vein glows faintly red-orange in cracks, nearly gone cold; fine ash drifting. Slightly
desaturated, medium-low contrast, mid-tone (not pitch black) so characters stay readable. No characters, no creatures,
no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match). The bottom
18% will be covered by the ground tiles and the top 15% by the rock ceiling of the level, keep both plain.
```

## Lớp xa — `bg_stage_01_03_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. A deep cavern wall with layered black coal seams, distant tunnel mouths fading into
darkness, thin glowing red-orange fissures of the cooling fire vein running horizontally, faint ash haze.
```

## Lớp giữa — `bg_stage_01_03_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). Timber support frames and crossbeams at regular intervals,
an old minecart rail track on a ledge, and carved into one rock pillar a simple emblem of three overlapping stone
rings (ancient guardian workshop mark), weathered, softly lit by a lantern.
```

## Lớp gần — `bg_stage_01_03_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent middle (PNG with alpha). Dark foreground silhouettes: stalactites hanging from the top
edge, an overturned minecart and coal piles along the bottom edge, iron mining lanterns hanging on chains with small
warm flames. Keep the central 60% height clear so the play area stays readable.
```

## Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-3 theo docs/prompts/stages/STAGE_01_03_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: nền màn 1-2 đã duyệt trong assets/backgrounds/stages/stage_01_02/ (nếu có) để giữ cùng
   nét vẽ, bảng màu; ô truyện assets/story/ch01/ch01_end_11.png (nếu có) cho dấu ba vòng đá.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   rock style as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_03/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_03/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải trần (15% trên) và dải đất (18% dưới) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-3":
   - chép vào assets/backgrounds/stages/stage_01_03/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-3: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

## Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_03/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-3 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.
