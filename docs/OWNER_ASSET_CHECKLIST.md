# Checklist owner cần chuẩn bị

> Lập ngày 2026-11-11 sau Milestone 1. Không mục nào **đang chặn** việc code:
> khi thiếu, Claude dùng placeholder (`placeholder_*`) và làm tiếp. Cột "Cần trước"
> cho biết lúc nào thiếu sẽ bắt đầu ảnh hưởng.
>
> Đánh dấu `[x]` khi xong. Quy tắc gốc: README 2.1, 2.2, 17.4.

## A. Quyết định (chỉ cần trả lời, không cần vẽ)

| | Việc | Cần trước | Ghi chú |
|---|---|---|---|
| [x] | **Tỉ lệ gacha** — banner nhân vật | M5-4 | Owner trả lời 2026-11-12 (mục A1), đã vào `data/banners/banner_char_kael.tres` |
| [ ] | **Tỉ lệ tiếp tế vũ khí / vết thánh**: các số cộng lại khác 100% | Banner tiếp tế | Xem câu hỏi ở mục A2 |
| [ ] | **Hạng S / A / B của từng nhân vật** và nhân vật đề cử của banner | Banner nhân vật | Đang tạm: S = Aether, Kael, Lyra; A = Seraphine, Noctis; B = Terra; banner đầu đề cử Kael |
| [ ] | Tên thật thay Aether (`char_fire_01`) và Noctis (`char_dark_01`) | Trước khi công khai | Trùng tên nhân vật nổi tiếng; chỉ đổi data |
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

Tiếp tế vũ khí + vết thánh (CHƯA làm): vũ khí 4★ 2.87%, vết thánh 4★ "mỗi cái 14%", vũ khí 3★ 10.7%, vết thánh 3★
"mỗi cái 13%", nguyên liệu 58%; pity cứng vũ khí 60; 10 lượt chắc chắn 1 món 4★, ưu tiên vết thánh. Các số này cộng lại
khác 100%: nếu "mỗi cái" là cho từng ô Đầu / Thân / Chân thì tổng 152.57%; nếu là tổng cả 3 ô thì 98.57%. Cần owner sửa.

"Không vượt quá cấp người chơi" được làm thành **cấp đội trưởng**: nhân vật không lên cấp quá cấp đội trưởng; đội trưởng
lên cấp bằng EXP đội trưởng khi qua màn.

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
