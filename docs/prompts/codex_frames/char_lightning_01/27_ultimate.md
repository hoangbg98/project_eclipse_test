# Phiếu 27 — Raikiba / `ultimate`

> Sinh tự động bởi `tools/frames/gen_prompts.py` từ `tools/frames/jobs/char_lightning_01.json` và `data/skills/`.
> Sửa phiếu ở file JSON rồi chạy lại, không sửa tay file này.

## Thông số (khớp thời gian trong game)

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/char_lightning_01/ultimate/` |
| Số frame | **22** (tạo trong 4 lần, mỗi lần frame 000–005, frame 006–011, frame 012–016, frame 017–021) |
| fps / lặp | 8 fps, không lặp |
| Thời lượng | 2700 ms — khởi động / hiệu lực / hồi phục 800/1500/400 ms |
| Frame trúng đòn | 006, 007, 008, 009, 010, 011, 012, 013, 014, 015, 016 |
| Song đao | **mỗi tay một đao**, cầm xuôi, lưỡi hướng ra trước; không cất đao, không đổi tay |
| Đứng đất | không: frame thấp nhất chạm y = 336, frame khác giữ độ cao tương đối |

**Động tác:** Lôi Thần Quyết: (khởi động 800 ms) đứng gồng, mắt lóe, hai đao giơ chéo trước mặt; (chuỗi 1 100 ms) liên tục xuất hiện ở các tư thế chém khác nhau — chém xuống, chém ngang, chém hất, đâm — mỗi pose một hướng; (sét 400 ms) bật nhảy lên, hai đao chĩa thẳng lên trời; (hồi phục 400 ms) đáp xuống thủ thế. Dịch chuyển, đường chéo vàng, cột sét, cut-in là VFX / ảnh riêng.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png` | Ảnh đứng toàn thân của owner (số 1): khóa thiết kế, màu, tỉ lệ chibi, hai đao |
| `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_48_pose_dung_song_dao.png` | Pose mẫu đứng cầm song đao (số 48): chuẩn góc nhìn ngang và cách cầm đao |
| `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_33_dao_1.png` | Đao sét (số 33): giữ đúng hình lưỡi, chuôi, vòng chuôi |
| `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_52_pose_tu_set.png` | Pose mẫu tụ sét (số 52) |
| `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_06_mat_la_het.png` | Mặt la hét (số 6) |

## Giai đoạn từng frame

| Frame | Giai đoạn |
|---|---|
| 000 | Khởi động (lấy đà) |
| 001 | Khởi động (lấy đà) |
| 002 | Khởi động (lấy đà) |
| 003 | Khởi động (lấy đà) |
| 004 | Khởi động (lấy đà) |
| 005 | Khởi động (lấy đà) |
| 006 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 007 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 008 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 009 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 010 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 011 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 012 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 013 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 014 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 015 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 016 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 017 | Hồi phục (thu về) |
| 018 | Hồi phục (thu về) |
| 019 | Hồi phục (thu về) |
| 020 | Hồi phục (thu về) |
| 021 | Hồi phục (thu về) |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `ultimate` cho Raikiba (char_lightning_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/char_lightning_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/char_lightning_01/27_ultimate.md. Giữ đúng ngoại hình model gốc, song đao theo mục Song đao của phiếu.

1. Tạo ảnh bằng skill imagegen, 4 lần gọi (6 pose, 6 pose, 5 pose, 5 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (nhiều lần gọi: thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/char_lightning_01/ultimate/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py char_lightning_01 ultimate <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng; sai thì thêm --ref-frame / --ref-ratio)
3. Ghi art_review/char_lightning_01/ultimate/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py char_lightning_01 ultimate — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo danh sách trong phiếu (mục Tự kiểm tra). Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/char_lightning_01/ultimate/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG sửa frames_manifest.json, KHÔNG commit. Chờ tôi trả lời "duyệt ultimate".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py char_lightning_01 ultimate, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: Raikiba ultimate frames (AI)". Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME character as the reference images: Raikiba, chibi anime lightning dual-dagger fighter (about 2.5 heads tall, big head, short limbs): spiky messy silver-white hair with bright lemon-yellow streaks in the bangs and at the tips, teal eyes, serious cool face; sleeveless black high-collar zip-up vest with thin yellow lightning-bolt piping; black leather arm bands with small silver buckles on the upper arms; black fingerless gloves with black wraps around the wrists and forearms; black belt with a silver buckle; baggy black cargo pants with yellow lightning stripes and hanging black straps; light grey combat boots with yellow laces. Weapons: two identical curved jagged daggers (black-and-gold kris-like blades with thin yellow lightning veins, black-wrapped grips and a small ring pommel), one in EACH hand.
Keep the exact design, proportions (chibi, big head, short limbs), colors, dark outline thickness and colour (2-3 px), and 2-3 tone cel shading of the references.
The standing dual-dagger pose reference (number 48) is the ground truth for the side view; the full-body reference is the ground truth for design and colors. The references contain yellow lightning glow: do NOT copy the glow, draw the character and daggers only.
Do NOT redesign: same hair, face, eyes, outfit, armor, accessories and two daggers; no added or removed details.
The character faces RIGHT in every frame, full body visible, same scale in every frame.
One single horizontal row of exactly {n} poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no shadow, no text, no numbers, no frame borders.
No visual effects (no lightning bolts, electric sparks, yellow glow, slash arcs, afterimages, speed lines): character and two daggers only.

Animation: Ultimate: tense power-up stance with glowing eyes and both daggers crossed in front of the face, then a rapid sequence of distinct teleport-slash poses (downward chop, horizontal cut, rising slash, thrust), then leap up with both daggers pointing straight at the sky, then land back in the ready stance.
This call: poses {a}–{b} of 22 (describe only this part of the motion; continue exactly from the attached previous strip).
Two daggers: one dagger in EACH hand at all times (forward grip, blades pointing forward), never sheathed, never swapped between hands; keep the exact dagger design.
Phase map (poses counted from 1): wind-up 1-6, impact 7-17 (clear extended pose, readable silhouette, brief hold), recovery 18-22.
Impact poses (blades fully swung through the target, arms extended): poses 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 of 22, counting from 1.
```

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống hoàn toàn ảnh gốc (tóc bạc vàng, mặt, áo ba lỗ cổ cao, đai tay, găng, thắt lưng, quần túi hộp, ủng xám dây vàng, hai đao, màu)?
2. Tỉ lệ chibi giữ nguyên, không bộ phận nào phình / co / biến dạng?
3. Nét viền, bảng màu, kiểu đổ bóng đồng nhất giữa các frame?
4. Động tác đọc rõ ở cỡ nhỏ, có lấy đà – đánh – thu về; bóng đen từng pose phân biệt được?
5. `check_frames.py` ĐẠT: chân ở 336, tâm 192, không bị cắt mép?
6. `anim_flip.gif` (lật trái) vẫn đúng: đao không nhảy tay, mỗi tay luôn một đao, chi tiết lệch một bên nhất quán?
7. Không xuyên vật thể, tay / chân gần – xa camera đúng lớp?
8. Không vẽ hiệu ứng (tia sét, ánh vàng, vệt chém, bóng mờ) vào frame nhân vật?
