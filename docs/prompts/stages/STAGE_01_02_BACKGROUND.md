# Ảnh nền màn 1-2 "Làng Lò Than" (3 lớp parallax)

> Màn `stage_01_02` (sinh bởi `tools/stages/gen_stage_01_02.py`) đọc 3 ảnh nền theo `backdrop` trong
> `data/stages/stage_01_02.json`. Thiếu ảnh nào thì bỏ lớp đó; không có ảnh nào thì game giữ nền đồi tạm.
> Không cần sửa code: chỉ đặt ảnh đúng tên rồi `--import`.

## Quy cách

| Lớp | File | Trượt | Nội dung | Nền trong suốt? |
|---|---|---|---|---|
| Xa | `assets/backgrounds/stages/stage_01_02/bg_stage_01_02_far.png` | 0.1 | Trời, Mặt Trời Khuyết, vách đá xa có Lò Mẹ **đang cháy** | Không (phủ kín) |
| Giữa | `.../bg_stage_01_02_mid.png` | 0.3 | Đồi tro, mái nhà làng Lò Than, ống khói, cối xay | Có (trời trong suốt) |
| Gần | `.../bg_stage_01_02_near.png` | 0.6 | Hàng rào gỗ, đèn lồng, cây chết, đống than | Có (trên ~55% trong suốt) |

- Kích thước: **3840 × 2160** (game co về cao 1080). Rộng có thể 3840 hoặc 7680; ảnh **lặp ngang**, mép trái và phải
  phải nối liền (Photoshop: *Filter → Other → Offset* +1920 px rồi vá đường nối).
- **18% dưới cùng bị nền đất của màn che** (mặt đất ở khoảng 83% chiều cao): đừng đặt chi tiết quan trọng ở đó.
- Không nhân vật, không quái, không chữ. Hơi giảm bão hòa, tương phản thấp để nhân vật và quái nổi trên nền.
- Liền mạch với Chương 1: màn 1-1 đi vào thung lũng tro xám; màn 1-2 diễn ra **sau khi Lò Mẹ cháy lại**, đi ngược dốc
  về làng ở cửa thung lũng. Tro vẫn còn nhưng không khí ấm hơn: ánh cam từ Lò Mẹ phía sau, khói bếp trong làng.

## Bối cảnh chung (đầu mỗi prompt)

```text
2D side-scrolling game background layer for PROJECT ECLIPSE, an original anime-style action RPG. Soft painterly anime
background art, flat side view (no perspective tilt), horizon at about 60% height. World under the "Eclipsed Sun": a
pale orange sun with a dark bite missing from one side. Setting: the mouth of the Ashen Valley, just after the giant
cliff furnace (the Mother Hearth) has been rekindled; grey ash still covers the ground but warm orange light is
returning. Slightly desaturated, low contrast. No characters, no creatures, no text, no logo, no watermark.
The image must tile seamlessly horizontally (left and right edges match). The bottom 18% will be covered by the
ground tiles of the level, keep it plain.
```

## Lớp xa — `bg_stage_01_02_far.png`

```text
[Bối cảnh chung]
Layer: FAR, fully opaque. Hazy dusk sky in grey-orange, the Eclipsed Sun high on the left third, soft ash particles in
the air. Far away on the right third, a tall cliff with a gigantic carved furnace gate glowing bright orange (the Mother
Hearth burning again), a thin column of warm smoke rising. Distant grey mountain ridges along the horizon.
```

## Lớp giữa — `bg_stage_01_02_mid.png`

```text
[Bối cảnh chung]
Layer: MIDDLE, transparent background above the hills (PNG with alpha). Gentle ash-covered hills, and on them the
small village of Coalhearth: stone-and-timber houses with dark tiled roofs, brick chimneys with thin cooking smoke,
a small water mill, warm lit windows. Buildings spaced so the layer repeats naturally.
```

## Lớp gần — `bg_stage_01_02_near.png`

```text
[Bối cảnh chung]
Layer: NEAR, transparent top 55% (PNG with alpha). Foreground silhouettes darker than the other layers: a weathered
wooden fence, a few dead trees with ash on their branches, hanging iron lanterns with small flames, piles of coal and
charred logs, a half-burnt wooden signpost. Shapes stay low so the play area stays readable.
```

## Prompt gửi Codex (đã liên kết dự án)

```text
Việc: tạo 3 ảnh nền parallax cho màn 1-2 theo docs/prompts/stages/STAGE_01_02_BACKGROUND.md.
Đọc AGENTS.md mục 4 "Ảnh do AI tạo" trước.
1. Đính kèm làm tham chiếu phong cách: assets/placeholders/story/placeholder_map_ch01.png (bố cục thung lũng),
   ảnh truyện tranh Chương 1 đã có trong assets/story/ch01/ (nếu có) để giữ cùng bảng màu, Mặt Trời Khuyết, Lò Mẹ.
2. Tạo lần lượt far → mid → near; từ lớp mid trở đi đính kèm lớp đã duyệt trước đó và ghi "same palette, lighting and
   horizon as the attached layer".
3. Chép ảnh gốc vào art_review/stages/stage_01_02/raw/. Viết tools/stages/fit_backdrop.py (Pillow): co về cao 2160,
   rộng 3840, làm mép trái/phải nối liền (trộn 128 px hai mép), mid/near giữ kênh alpha (tách nền nếu ảnh gốc không
   trong suốt). Lưu art_review/stages/stage_01_02/ và một ảnh _preview/stack.png ghép 3 lớp 2 lần lặp liền nhau.
4. DỪNG, gửi tôi _preview/stack.png. Chỉ khi tôi trả lời "duyệt nền 1-2":
   - chép vào assets/backgrounds/stages/stage_01_02/ đúng tên trong tài liệu (không ghi đè; có rồi thì -v2 và hỏi);
   - chạy C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import;
   - ghi từng file vào docs/ASSET_LICENSES.md mục 2.1; chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
     (mã thoát 0); ghi docs/DEVELOPMENT_LOG.md; commit "Stage 1-2: backdrop art" (không push).
Trả lời tôi bằng tiếng Việt.
```

## Thay tay

1. Đặt PNG đúng tên vào `assets/backgrounds/stages/stage_01_02/`.
2. Chạy `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import` (hoặc mở Godot).
3. Vào ải 1-2 để xem. Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.
4. Muốn đổi tên file / hệ số trượt: sửa `backdrop` trong `tools/stages/gen_stage_01_02.py` rồi chạy lại script.
