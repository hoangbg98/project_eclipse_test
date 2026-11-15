# Ảnh nền màn 1-7 "Trạm Thủ Vệ Bỏ Hoang" (3 lớp parallax)

> Màn `stage_01_07` (sinh bởi `tools/stages/gen_stages_01_05_10.py`) đọc 3 ảnh nền theo `backdrop` trong `data/stages/stage_01_07.json`.
> Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm. Quy cách chung: xem
> `docs/prompts/stages/STAGE_01_02_BACKGROUND.md` (mục Quy cách). Tài liệu này được sinh tự động: sửa trong
> `tools/stages/gen_stages_01_05_10.py` rồi chạy lại.

## Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_07/bg_stage_01_07_far.png` | 0.1 | Tường đá trong trạm, hốc tường lớn trống rỗng, ánh sáng lọt qua khe trần | Không (phủ kín) |
| Giữa | `.../bg_stage_01_07_mid.png` | 0.3 | Cột đá khắc dấu ba vòng đá, giá đỡ lõi thủ vệ bị tháo, dây xích thả | Có |
| Gần | `.../bg_stage_01_07_near.png` | 0.6 | Đá vỡ, mảnh thủ vệ đá, bậc thềm sụt | Có (giữa ảnh trong suốt) |

- Kích thước **3840 × 2160**, lặp ngang liền mạch; **18% dưới cùng bị nền đất che**, khoảng **15% trên cùng bị trần đá che**.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa để nhân vật và quái nổi lên.
- Liền mạch: nối tiếp 1-6 (cùng dấu ba vòng đá, cùng đá xám); trong nhà nên không thấy trời. Hốc lõi trống có vết cạy **còn mới** (tay sai vừa lấy).

## Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: inside an abandoned outpost of the ancient stone guardians, carved into the rock above the Ashen Valley; cold, dusty, silent, lit by faint orange light through cracks. Slightly desaturated, low contrast. No characters,
no creatures, no text, no logo, no watermark. The image must tile seamlessly horizontally (left and right edges match).
The bottom 18% will be covered by the ground tiles of the level and the top 15% by the rock ceiling, keep it plain.
```

## Lớp xa — `bg_stage_01_07_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. The deep interior wall of an ancient guardian outpost carved from grey stone: rows of large empty niches where stone guardian cores once sat, thin shafts of hazy orange light from cracks above.
```

## Lớp giữa — `bg_stage_01_07_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background (PNG with alpha). Carved stone columns bearing a three-stacked-stone-ring emblem, empty stone cradles with fresh pry marks where guardian cores were removed, iron chains hanging loose, a fallen stone guardian arm.
```

## Lớp gần — `bg_stage_01_07_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent middle (PNG with alpha). Dark foreground silhouettes: rubble and broken pieces of stone guardians along the bottom edge, a cracked archway edge in a top corner. Keep the central 60% height clear.
```

## Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-7 theo docs/prompts/stages/STAGE_01_07_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu: nền 1-3 (hầm, có trần) và 1-6 đã duyệt trong assets/backgrounds/stages/ (nếu có) để giữ đá và dấu ba vòng đá.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_07/raw/. Dùng tools/stages/fit_backdrop.py (nếu chưa có thì viết, Pillow):
   co về 3840x2160, làm mép trái/phải nối liền, mid/near giữ kênh alpha. Lưu art_review/stages/stage_01_07/ và
   _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau, vẽ mờ dải đất (18% dưới) và dải trần (15% trên) để kiểm tra.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-7":
   - chép vào assets/backgrounds/stages/stage_01_07/ đúng tên (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-7: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

## Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_07/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-7 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.
