# Prompt mẫu: Codex tạo frame animation Aether (thay placeholder)

Dùng trong ứng dụng Codex trên PC, sau khi đã mở thư mục `C:\Dev\PROJECT_ECLIPSE` và chọn tin cậy (trust).
Codex đọc `AGENTS.md`, nên quy tắc ảnh AI, nơi lưu và cách ghi nguồn đã có sẵn; prompt dưới đây chỉ thêm phần riêng cho frame.

## 1. Ảnh tham chiếu đính kèm

Kéo các file này vào khung chat Codex (Claude đã chọn):

| Ảnh | Đường dẫn | Dùng để |
|---|---|---|
| Ảnh đứng toàn thân (bắt buộc) | `assets/characters/char_fire_01/portrait/char_fire_01_portrait_full.png` | Khóa thiết kế: tỉ lệ chibi, màu, trang phục, kiếm cầm tay trái ảnh |
| Pose mẫu | `assets/characters/char_fire_01/rig_parts/char_fire_01_part_58_pose_pose_mau.png` đến `..._64_...` | Tư thế đứng, chạy, lướt (60), nhảy (61), đáp đất (62) |
| Kiếm | `assets/characters/char_fire_01/rig_parts/char_fire_01_part_44_weapon_kiem_lua.png` | Giữ đúng hình kiếm |
| Mặt biểu cảm (khi cần) | `..._part_04_face_mat_ha_mieng_het.png` (hét: tụ lực), `..._part_05_face_mat_nham_mat_dau.png` (bị đánh) | Biểu cảm theo động tác |

Không cần đính kèm cả 64 bộ phận; 3–5 ảnh là đủ, ảnh đứng toàn thân luôn có mặt.

## 2. Prompt gửi Codex (dán nguyên khối, thay phần trong `< >`)

```text
Tạo frame animation cho Aether (char_fire_01) để thay placeholder, đợt này: <tên animation, vd idle>.
Đọc AGENTS.md (mục "Ảnh do AI tạo") và assets/characters/char_fire_01/frames_manifest.json trước.

Bước 1 — Tạo ảnh bằng skill imagegen (công cụ tích hợp, không dùng CLI):
- Dùng ảnh đính kèm làm tham chiếu thiết kế; KHÔNG đổi màu tóc, trang phục, kiếm, tỉ lệ chibi.
- Mỗi lần gọi tạo MỘT dải ngang <N> frame của đúng một animation, theo prompt ảnh ở mục 3 bên dưới
  (tôi dán kèm). Animation dài hơn 6 frame thì chia nhiều lần, lần sau đính kèm dải trước để giữ liền mạch.
- Nền trong suốt. Nếu không ra nền trong được: nền một màu #FF00FF rồi dùng scripts/remove_chroma_key.py của skill.

Bước 2 — Cắt và chuẩn hóa (viết script Python trong tools/sprite_parts/slice_strip.py, chạy bằng python -I):
- Tách dải thành từng frame theo vùng không trong suốt (không chia đều theo chiều ngang nếu các pose rộng hẹp khác nhau).
- Mỗi frame đặt vào canvas 384×384 trong suốt, nhân vật quay mặt sang PHẢI, chân (điểm thấp nhất của đế ủng
  khi đứng trên đất) ở y = 336, tâm thân x = 192. Frame trên không (jump_up, fall, air_*): giữ đúng độ cao
  tương đối giữa các frame, không kéo chân về 336.
- Cùng một tỉ lệ phóng cho mọi frame của mọi animation: chiều cao nhân vật đứng thẳng (đỉnh tóc tới đế ủng)
  = 280 px (hitbox trong game tính theo thân 256 px, CHARACTER_SKILLS mục 0; tóc chibi cao hơn một chút). Phóng bằng lọc nearest hoặc lanczos, không làm mờ viền.
- Tên file: assets/characters/char_fire_01/frames/<animation>/char_fire_01_<animation>_<NNN>.png, đánh số từ 000.
  Không ghi đè file đã có; nếu thư mục đã có frame thì hỏi tôi.

Bước 3 — Cập nhật dự án:
- frames_manifest.json: đặt "frames" = số frame thật của animation đó (giữ fps, loop).
- docs/ASSET_LICENSES.md mục 2.1: một dòng cho thư mục animation (công cụ + model, prompt rút gọn, ảnh tham chiếu, ngày).
- Chạy: powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (phải mã thoát 0).
- Ghi docs/DEVELOPMENT_LOG.md theo mẫu trong AGENTS.md, rồi commit "Art: Aether <animation> frames (AI)".
- Gửi tôi ảnh ghép các frame trên nền tối (contact sheet) để duyệt.
```

## 3. Prompt ảnh cho từng animation

Prompt ảnh viết bằng tiếng Anh (mô hình ảnh bám tiếng Anh tốt hơn). Mỗi lần dùng **phần chung + một dòng animation**.

**Phần chung (luôn dán):**

```text
2D game sprite sheet of the SAME character as the reference image: Aether, chibi anime swordsman,
spiky crimson hair with one orange streak, amber eyes, black cropped jacket with red-and-gold trim and
flame motifs, white shirt, red-gold shoulder pauldron, dark red trousers, black fingerless gloves,
black boots with orange soles, flame-patterned red-gold sword. Keep the exact design, colors, line art
(dark brown outline 2-3 px) and cel shading of the reference.
Side-scrolling action game, character faces RIGHT, full body visible in every frame, same scale in every frame.
One horizontal row of {N} frames, evenly spaced with clear empty gaps between frames, no overlap.
Transparent background. No ground, no shadow, no text, no numbers, no frame borders.
No visual effects baked in (no fire trails, slash arcs, sparks or glow): character and sword only.
```

**Một dòng theo animation** (số frame theo `CHARACTER_SKILLS.md`; thay `{N}` ở phần chung):

| Animation (thư mục) | N | Dòng mô tả |
|---|---|---|
| `idle` | 6 | `Idle breathing loop: relaxed fighting stance, sword held low in the hand nearest the viewer, slight shoulder rise and fall, hair sways; frame 6 flows back into frame 1.` |
| `run` | 8 | `Run cycle loop: leaning forward, sword trailing behind, full stride with clear contact, down, passing and up poses; frame 8 flows into frame 1.` |
| `jump_up` | 3 | `Jump take-off: crouch, push off the ground, rising with knees tucked.` |
| `fall` | 3 | `Falling: body slightly arched, hair and jacket blown upward, legs reaching down.` |
| `land` | 3 | `Landing: feet touch down, knees bend to absorb impact, recover to stance.` |
| `attack_1` | 6 | `Combo hit 1: horizontal slash from right to left: wind-up, swing, follow-through, recover.` |
| `attack_2` | 6 | `Combo hit 2: rising upward slash from low to high, body lifting with the swing.` |
| `attack_3` | 6 | `Combo hit 3: spinning thrust, turning the body and stabbing the sword straight forward.` |
| `attack_4` | 8 | `Combo hit 4 finisher: small hop and heavy vertical overhead slash down into the ground.` |
| `dodge` | 5 | `Dash dodge: lean forward, burst forward low to the ground, hair and coat streaming back, skid to a stop.` |
| `hold_charge` | 4 | `Charging loop: low crouch, sword pulled back behind the body, shouting face (use the open-mouth face reference).` |
| `hold_release` | 8 | `Charged release: long step forward with a big rising slash from low to high, then recover.` |
| `air_1` | 5 | `Mid-air slash 1: horizontal slash while doing a light flip in the air.` |
| `air_2` | 5 | `Mid-air slash 2: diagonal downward slash from high above.` |
| `landing_attack` | 6 | `Plunge attack: sword pointing down, diving straight down (2 frames), stabbing into the ground on impact (4 frames).` |
| `skill_1` | 10 | `Spinning skill: full 360-degree body spin with the sword sweeping a wide circle, final frame plants the sword horizontally.` |
| `skill_2` | 12 | `Weapon skill: braced stance with sword level, piercing dash forward, stops at the end and half-sheathes the sword.` |
| `ultimate` | 18 | `Ultimate: leaps high raising the sword overhead, dives down for five rapid slashes, ends in a powerful landing pose. Split into 3 calls of 6 frames.` |
| `switch_in` | 8 | `Entrance attack: dashes in from behind, leaps and slashes diagonally downward, sword planted into the ground, stands up ready.` |
| `switch_out` | 3 | `Exit: turns away and starts to dissolve into light (body fading), 3 frames.` |
| `hurt` | 3 | `Hit reaction: flinches backward, eyes shut in pain (use the pained face reference), recovers.` |
| `knockback` | 3 | `Knocked back: thrown backward off balance, sliding, regaining footing.` |
| `down` | 6 | `Knocked down: falls backward to the ground, lies down, then pushes up to get back up.` |

**Thứ tự gợi ý:** `idle` → `run` → `attack_1..4` → `dodge` → `jump_up/fall/land` → phần còn lại.
`idle` làm trước để khóa tỉ lệ và màu; các đợt sau đính kèm frame `idle_000` làm tham chiếu thêm.

## 4. Duyệt kết quả (owner)

- Mở Godot (F5 → Game mới → Chiến đấu → Màn thử nghiệm): animation đã có frame sẽ thay viên nang xám.
- Lỗi hay gặp với ảnh AI: chân trượt giữa các frame, kiếm đổi tay, màu lệch, frame thừa/thiếu.
  Báo lại số frame lỗi; nhờ Codex tạo lại riêng frame đó (đính kèm frame trước và sau).
- Hiệu ứng lửa, vệt kiếm làm riêng sau (thư mục `vfx/`, có thể dùng pixelfx), không vẽ chung vào frame.
