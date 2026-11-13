# Checklist owner cần chuẩn bị

> Lập ngày 2026-11-11 sau Milestone 1. Không mục nào **đang chặn** việc code:
> khi thiếu, Claude dùng placeholder (`placeholder_*`) và làm tiếp. Cột "Cần trước"
> cho biết lúc nào thiếu sẽ bắt đầu ảnh hưởng.
>
> Đánh dấu `[x]` khi xong. Quy tắc gốc: README 2.1, 2.2, 17.4.

## A. Quyết định (chỉ cần trả lời, không cần vẽ)

| | Việc | Cần trước | Ghi chú |
|---|---|---|---|
| [x] | **Tỉ lệ gacha** — banner nhân vật | M5-4 | Owner trả lời 2026-11-12 (mục A1), đã vào `data/banners/banner_char_terra.tres` (đổi tên khi đổi banner đầu sang Iwagane) |
| [x] | **Tỉ lệ tiếp tế vũ khí / vết thánh** (owner 2026-11-13: vết thánh 3★ tăng lên 14.43% cho đủ 100%) | Banner tiếp tế | Đã làm, mục A2 |
| [x] | **Hạng S / A / B của từng nhân vật** và nhân vật đề cử của banner | Banner nhân vật | Owner 2026-11-13: S = Enkiba, Iwagane; A = Hikarine, Yomigari; B = Raikiba, Kazeyumi; banner đầu đề cử Iwagane (tạm, mục A2) |
| [x] | Tên thật thay tên trùng nhân vật nổi tiếng | Trước khi công khai | Owner đổi 2026-11-13: Enkiba, Kazeyumi, Raikiba, Hikarine, Yomigari, Iwagane (bảng ở mục A2) |
| [ ] | **Ảnh banner chiêu mộ** (mỗi banner 2 ảnh: banner lớn 1301×839, ảnh nhỏ 390×226) | Khi muốn thay ảnh tạm | Thêm file `{id banner}_banner.png` / `_thumb.png` vào `assets/ui/recruit/`, không sửa code; xem `assets/ui/recruit/README.md`. Chữ, nút, màu chỉnh ở `data/ui/recruit_screen_layout.json` |
| [ ] | Tên gói Android thật (thay `com.projecteclipse.dev`) | Khi làm lại Android | Đổi sau khi đã cài lên máy = app khác |
| [ ] | **Khai báo nội dung AI tạo** trên trang store (Steam: mục "AI Generated Content Disclosure" khi nộp bản build) | Trước khi nộp lên store | Owner cho phép ảnh AI vào bản phát hành (2026-11-12); danh sách file ở `docs/ASSET_LICENSES.md` mục 2.1. Kiểm tra điều khoản thương mại của dịch vụ tạo ảnh với tài khoản đang dùng |
| [ ] | OD-1 đến OD-6 (README 15.8) | Không gấp | Đang dùng mặc định: side-scroll; vũ khí cố định; không stamina; icon dự bị góc trên-phải |

### A1. Câu hỏi gacha

1. Có mấy bậc độ hiếm (ví dụ 3★/4★/5★)? Mỗi bậc tỉ lệ gốc bao nhiêu %?
2. Pity cứng: bao nhiêu lượt chắc chắn ra bậc cao nhất? Có pity mềm (tăng dần tỉ lệ từ lượt nào) không?
3. Pity riêng cho bậc thứ hai (ví dụ 4★ mỗi 10 lượt)?
4. Rate-up: nhân vật rate-up chiếm bao nhiêu % khi ra bậc cao nhất? Lần sau trượt có bảo hiểm 100% không?
5. Pity có chuyển giữa các banner không?
6. Giá một lượt / mười lượt bằng tiền tệ trong game (không phải tiền thật ở bản đầu).

### A2. Câu trả lời gacha của owner (2026-11-12) và chỗ còn hỏi

Banner nhân vật (đã làm): S 1.5% (chỉ 1 nhân vật đề cử), A 16.3%, B 10.874%, phần còn lại (71.326%) là nguyên liệu tăng
cấp nhân vật, nguyên liệu nâng bậc vũ khí, vàng. Pity cứng S 100 lượt; từ lượt 80 tỉ lệ S +10% (Claude hiểu là cộng
một lần, thành 11.5%). Quay 10 lượt chắc chắn ≥ 1 nhân vật A. Pity chuyển sang banner nhân vật kế tiếp. Giá 280 / 2520
Ngọc. Nhân vật trùng đổi thành mảnh (Claude đặt: S 25, A 10, B 5) để tiến cấp S → S1 → S2 → S3.

Tiếp tế vũ khí + vết thánh (đã làm, owner 2026-11-13): vũ khí 4★ 2.87%, vết thánh 4★ 14%, vũ khí 3★ 10.7%,
vết thánh 3★ **14.43%** (owner: tăng cho khớp 100%), nguyên liệu 58%; mỗi số là tổng cả nhóm. Pity cứng vũ khí 4★ 60;
10 lượt chắc chắn 1 món 4★, ưu tiên vết thánh. Đề cử: vũ khí 4★ + bộ vết thánh 4★ của nhân vật đang đề cử.

Owner 2026-11-13: pity mềm cộng một lần (+10% từ lượt 80) là đúng. Hạng tạm: **S = Aether, Terra**; A = Seraphine,
Noctis; **B = Kael, Lyra**. Hướng dẫn sau này: lượt x10 miễn phí đầu tiên **bắt buộc có 1 Kael**, 9 lượt còn lại là
nguyên liệu tăng cấp (đã có dữ liệu `data/tutorial/starter_pull.tres` và `GachaService.pull_starter`, chưa gắn vào UI).

**Cấp người chơi** (owner 2026-11-13): người chơi là "người quản lý", không có hình trong game, lên cấp qua nhiệm vụ và
phó bản; cấp nhân vật không vượt cấp người chơi. Trong code vẫn tên `account` / `captain_*`; hiện mới có EXP khi qua màn
(chưa có hệ thống nhiệm vụ).

Owner 2026-11-13: banner đầu tiên đề cử **Iwagane — Thần Kiếm Nham Thạch** (Terra cũ); banner tiếp tế đi kèm đề cử
Đại kiếm Dung Nham 4★ + bộ Ấn Nham Thạch 4★ (đồ do Claude đặt tên và chỉ số tạm). Iwagane chưa có kỹ năng.

**Tên mới (owner 2026-11-13).** Mỗi CharacterDef là một **giáp**; một nhân vật có thể có nhiều giáp, hạng khác nhau:

| Data ID | Nhân vật (tên cũ) | Giáp | Hạng |
|---|---|---|---|
| `char_fire_01` | Enkiba (Aether) | Hỏa Diễm Mãnh Liệt | S |
| `char_wind_01` | Kazeyumi (Lyra) | Đôi Cánh Của Gió | B |
| `char_lightning_01` | Raikiba (Kael) | Nanh Của Lôi Thần | B |
| `char_light_01` | Hikarine (Seraphine) | Ánh Sáng Thiên Giới | A |
| `char_dark_01` | Yomigari (Noctis) | Lưỡi Hái Hắc Ám | A |
| `char_earth_01` | Iwagane (Terra) | Thần Kiếm Nham Thạch | S |

## B. Hình nhân vật (frame-by-frame)

**Quy cách chung** (mọi frame của một nhân vật giống nhau):

- PNG nền trong suốt, canvas **384×384**, nhân vật cao khoảng 256 px.
- Chân đặt ở **y = 336**, tâm ngang **x = 192**, ở mọi animation.
- Vẽ **hướng sang phải** (game tự lật khi quay trái).
- Vũ khí/hiệu ứng vượt khỏi canvas thì tách sang VFX, không phóng canvas.
- Tên file: `{id}_{animation}_{NNN}.png`, đánh số từ `000`.
  Ví dụ `char_fire_01_attack_1_000.png`.

**Cách giao:**

1. Chép PNG vào `assets/characters/{id}/frames/{animation}/`.
2. Mở `assets/characters/{id}/frames_manifest.json`, sửa `frames` của animation đó thành số file (và `fps` nếu muốn khác mặc định: vòng lặp 12, đòn đánh 24).
3. Khi đủ bộ của nhân vật: đặt `frames_delivered` thành `true`.
4. Báo Claude; test sẽ báo lỗi nếu số PNG khác `frames`.

### B1. Ưu tiên 1 — Aether (`char_fire_01`), đủ bộ cho bản chơi thử

| | Animation | Dùng cho |
|---|---|---|
| [ ] | `idle`, `run`, `jump_up`, `fall`, `land` | Di chuyển (**nên có trước M2-3** để thử cảm giác) |
| [ ] | `attack_1` … `attack_4` | Đòn thường |
| [ ] | `dodge` | Né |
| [ ] | `hold_charge` (lặp), `hold_release` | Giữ nút đánh |
| [ ] | `air_1`, `air_2` | Đánh trên không |
| [ ] | `landing_attack` | Đòn đáp đất |
| [ ] | `skill_1`, `skill_2` | Kỹ năng thường, kỹ năng vũ khí |
| [ ] | `ultimate` | Tuyệt kỹ |
| [ ] | `switch_in`, `switch_out` (3 frame) | Vào/ra sân |
| [ ] | `hurt`, `knockback`, `down` | Bị đánh |

23 animation. Cần trước M3-5 (bộ kỹ năng Aether); phần di chuyển nên có từ M2-3.

### B2. Ưu tiên 2 — Kael và Lyra (bộ rút gọn, theo Q5)

| | Nhân vật | Animation |
|---|---|---|
| [ ] | Kael (`char_lightning_01`) | `idle`, `run`, `jump_up`, `fall`, `land`, `attack_1`…`attack_5`, `dodge`, `switch_in`, `switch_out`, `hurt`, `knockback`, `down` |
| [ ] | Lyra (`char_wind_01`) | `idle`, `run`, `jump_up`, `fall`, `land`, `attack_1`…`attack_3`, `dodge`, `switch_in`, `switch_out`, `hurt`, `knockback`, `down` |

Cần trước M4-4 (đổi nhân vật). Các folder khác (skill, ultimate…) để trống cũng được.

### B3. Sau bản chơi thử

Seraphine (`char_light_01`), Noctis (`char_dark_01`), Terra (`char_earth_01`): chưa cần.

## C. Hình khác

| | Việc | Quy cách | Cần trước |
|---|---|---|---|
| [ ] | Portrait Aether, Kael, Lyra | Tự chọn kích thước; bản nhỏ hiển thị ≥ 140 px trên HUD | M4-7 (icon dự bị) |
| [ ] | Ảnh cut-in tuyệt kỹ Aether | Tự chọn | M3-5 |
| [ ] | VFX: đường chém, nổ, vùng, đạn | Lớp riêng, không vẽ chung vào frame nhân vật; dạng sprite sheet hoặc frame PNG | M3-7 |
| [ ] | 1–2 quái thường | 384×384 (quái nhỏ được 256×256), cùng quy tắc chân/hướng | M3-6 |
| [ ] | 1 boss | 768×768, cùng quy tắc (nhân 2) | M6 |
| [ ] | Tile màn đầu + nền parallax 2–3 lớp | Tự chọn; báo kích thước tile | M6 (bản thô từ M2-3) |
| [ ] | Key art nền Hub, logo game | Tự chọn, nền 1920×1080 | M7 |
| [ ] | Icon UI (tiền tệ, tab, nút) | Tự chọn, nên SVG hoặc PNG ≥ 2× | M7 |

## D. Font, nhạc, âm thanh

| | Việc | Lưu ý | Cần trước |
|---|---|---|---|
| [ ] | Font chính | **Phải có đủ dấu tiếng Việt** và giấy phép thương mại; gửi kèm file giấy phép | M7 (sớm hơn càng tốt) |
| [ ] | Nhạc: tiêu đề, hub, màn, boss | Giấy phép thương mại | M7 |
| [ ] | SFX: đánh trúng, né, kỹ năng, nút UI, vòng Liên kết sáng | Giấy phép thương mại | M3-7 / M7 |

Mọi file bên ngoài (font, nhạc, SFX) phải ghi nguồn và giấy phép vào
`docs/ASSET_LICENSES.md`. Gửi Claude thông tin, Claude ghi giúp.

### D1. Tên file âm thanh game đang chờ (M7-3)

Code đã gắn sẵn; chỉ cần đặt file đúng tên là có tiếng, thiếu file nào thì sự kiện đó im lặng.
Muốn đổi tên hoặc gán lại: sửa `data/config/audio_events.json` (không sửa code).

| Thư mục | File (đuôi `.ogg` hoặc `.mp3` cho nhạc; `.wav` hoặc `.ogg` cho SFX) | Phát khi |
|---|---|---|
| `assets/audio/music/` | `music_menu` | Màn Title và Hub |
| | `music_stage` | Trong màn chơi |
| | `music_boss` | Vào đấu trường boss |
| `assets/audio/sfx/` | `sfx_hit`, `sfx_hit_crit` | Đòn trúng kẻ địch (thường / chí mạng) |
| | `sfx_player_hurt` | Nhân vật bị đánh trúng |
| | `sfx_enemy_stunned`, `sfx_enemy_down` | Kẻ địch bị Choáng / bị hạ |
| | `sfx_switch`, `sfx_switch_linked` | Đổi nhân vật (thường / Liên kết) |
| | `sfx_link_ready` | Vòng sáng Liên kết bật lên |
| | `sfx_reaction` | Phản ứng nguyên tố nổ |
| | `sfx_ultimate` | Bắt đầu tuyệt kỹ |
| | `sfx_stage_clear`, `sfx_stage_fail` | Qua màn / thất bại |

Nhạc cần lặp thì bật Loop trong tab Import của Godot cho file đó.

## E. Thứ tự gợi ý

1. Trả lời **tỉ lệ gacha** (mục A1). Đây là chỗ duy nhất đang bị chặn.
2. Vẽ **Aether: idle, run, jump_up, fall, land** để thử cảm giác ở M2-3.
3. Vẽ phần còn lại của **Aether**, kèm 1 quái thường và VFX đòn đánh.
4. **Kael, Lyra** bộ rút gọn, kèm portrait 3 nhân vật.
5. Màn đầu, boss, UI, font, âm thanh.
