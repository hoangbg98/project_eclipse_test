# Thiết kế "Kẻ Đeo Mặt Nạ" (tay sai, boss ải 1-10)

> Cốt truyện owner 2026-11-15: kẻ chủ mưu Chương 1 là **tay sai (người mặc giáp) của một Quản lý dưới trướng thủ lĩnh
> mã 00**. Chưa có tên (thoại hiện "???", tên boss tạm "Kẻ Đeo Mặt Nạ"). Hình dưới đây là **đề xuất của Claude**;
> owner đổi được — sửa cả `CHAR_DESC["henchman"]` trong `tools/story/gen_story_clips.py` rồi chạy lại.
> Vẽ thiết kế này **trước** các ô truyện có hắn (`ch01_golem_07`, `ch01_end_01..04`) và nền 1-8: các ảnh đó đính kèm
> bản thiết kế đã duyệt làm tham chiếu.

## Khóa thiết kế

| Mục | Mô tả |
|---|---|
| Dáng | Cao, gầy, vai rộng nhờ giáp; đứng hơi khom, bình thản, không bao giờ vội |
| Giáp | Tấm giáp xám tro (ash-grey) mờ, đường nối **cam xỉn** như than sắp tắt; giáp vai bất đối xứng (vai trái to hơn) |
| Mặt | **Mặt nạ đen trơn, không mắt, không miệng** — không bao giờ lộ mặt, kể cả khi giáp vỡ (end_01..04) |
| Áo choàng | Màu than, rách mép, dài tới bắp chân |
| Huy hiệu | Vòng tròn nhỏ **nửa trắng nửa đen** trên ngực (cùng kiểu mảnh ấn kênh 00) |
| Vũ khí | **Lưỡi móc** (glaive) cán dài đen, lưỡi cong như móc câu |
| Hiệu ứng | Tro xám rỉ ra từ khe giáp khi ra đòn; pha 2: khe giáp sáng cam mạnh hơn, tro cuộn quanh lưỡi móc |
| Phân biệt | Không giống Enkiba (đỏ cam, áo khoác) hay golem (khối đá thô): kim loại phẳng, lạnh, gọn |

## Bảng thiết kế — `assets/characters/boss_henchman_01/design/boss_henchman_01_sheet.png`

Tạo 1536×1024 (ngang). Ảnh AI phải ghi vào `docs/ASSET_LICENSES.md` mục 2.1.

```text
Original character design sheet for PROJECT ECLIPSE, an anime-style 2D action RPG. Clean anime line art, cel shading
with 2-3 tones, neutral light grey background, no text, no logo, no watermark.
Character: "the masked henchman", an adult suit-wearer (gender ambiguous), tall and lean, broad armored shoulders,
calm slightly hunched stance. Dull ash-grey plated armor with seams glowing a faint dim orange like dying embers,
asymmetric pauldrons (left larger), a smooth faceless black visor-mask with no eyes and no mouth, a tattered
charcoal-grey cloak reaching the calves, a small half-white half-black ring emblem on the chest. Weapon: a long
black glaive with a hooked curved blade.
Show: full body front view, full body side view, full body back view, plus a close-up of the mask and the chest
emblem, plus the glaive alone. Same colors and proportions in every view.
```

## Chân dung — `assets/characters/boss_henchman_01/portrait/boss_henchman_01_portrait.png`

Dùng cho thẻ boss / băng thoại "???". Tạo 1024×1024.

```text
Anime 2D portrait of the masked henchman from the attached design sheet: bust shot, three-quarter view, smooth
faceless black visor-mask catching a cold rim light, ash-grey armor with dim orange glowing seams, tattered charcoal
cloak collar, ash particles drifting. Dark moody background in deep indigo with a thin eclipse ring of light.
No text, no logo, no watermark. Faithful to the attached design sheet.
```

## Tư thế chiến đấu (tham chiếu cho animation sau này)

```text
Anime 2D action pose of the masked henchman from the attached design sheet, facing right, side view, feet on a flat
ground line, holding the hooked black glaive low behind him ready to sweep, ash leaking from armor seams.
Transparent or plain light grey background. No text. Faithful to the attached design sheet.
```

> Game hiện vẽ boss bằng hình tạm (`scenes/enemies/boss_henchman.tscn`: thân xám, mặt nạ đen, đường nối cam, lưỡi móc
> đen). Khi có frame animation thật cho kẻ địch sẽ làm phiếu frame riêng như nhân vật (README 17.4).
