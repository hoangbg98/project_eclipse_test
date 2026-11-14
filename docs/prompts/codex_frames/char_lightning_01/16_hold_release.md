# Phiếu 16 — Raikiba / `hold_release`

> Sinh tự động bởi `tools/frames/gen_prompts.py` từ `tools/frames/jobs/char_lightning_01.json` và `data/skills/`.
> Sửa phiếu ở file JSON rồi chạy lại, không sửa tay file này.

## Thông số (khớp thời gian trong game)

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/char_lightning_01/hold_release/` |
| Số frame | **6** (tạo trong 1 lần, mỗi lần frame 000–005) |
| fps / lặp | 15 fps, lặp liền mạch |
| Thời lượng | 400 ms |
| Frame trúng đòn | — |
| Song đao | **mỗi tay một đao**, cầm xuôi, lưỡi hướng ra trước; không cất đao, không đổi tay |
| Đứng đất | có: chân ở y = 336 mọi frame |

**Động tác:** Lôi Quang Loạn Vũ (lặp): đứng tại chỗ xoay người liên tục, hai đao thay nhau chém chéo lên – chéo xuống quanh người như cối xay. Game giữ vòng này tối đa 1,2 s (8 nhịp chém), thả nút thì dừng; đoạn lao tới và chùm tia chéo vàng là chuyển động / VFX của game. Lặp liền.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png` | Ảnh đứng toàn thân của owner (số 1): khóa thiết kế, màu, tỉ lệ chibi, hai đao |
| `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_48_pose_dung_song_dao.png` | Pose mẫu đứng cầm song đao (số 48): chuẩn góc nhìn ngang và cách cầm đao |
| `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_33_dao_1.png` | Đao sét (số 33): giữ đúng hình lưỡi, chuôi, vòng chuôi |
| `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_50_pose_lao_chem.png` | Pose mẫu lao chém (số 50) |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `hold_release` cho Raikiba (char_lightning_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/char_lightning_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/char_lightning_01/16_hold_release.md. Giữ đúng ngoại hình model gốc, song đao theo mục Song đao của phiếu.

1. Tạo ảnh bằng skill imagegen, 1 lần gọi (6 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (nhiều lần gọi: thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/char_lightning_01/hold_release/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py char_lightning_01 hold_release <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 0.95× lúc đứng; sai thì thêm --ref-frame / --ref-ratio)
3. Ghi art_review/char_lightning_01/hold_release/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py char_lightning_01 hold_release — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo danh sách trong phiếu (mục Tự kiểm tra). Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/char_lightning_01/hold_release/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG sửa frames_manifest.json, KHÔNG commit. Chờ tôi trả lời "duyệt hold_release".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py char_lightning_01 hold_release, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: Raikiba hold_release frames (AI)". Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME character as the reference images: Raikiba, chibi anime lightning dual-dagger fighter (about 2.5 heads tall, big head, short limbs): spiky messy silver-white hair with bright lemon-yellow streaks in the bangs and at the tips, teal eyes, serious cool face; sleeveless black high-collar zip-up vest with thin yellow lightning-bolt piping; black leather arm bands with small silver buckles on the upper arms; black fingerless gloves with black wraps around the wrists and forearms; black belt with a silver buckle; baggy black cargo pants with yellow lightning stripes and hanging black straps; light grey combat boots with yellow laces. Weapons: two identical curved jagged daggers (black-and-gold kris-like blades with thin yellow lightning veins, black-wrapped grips and a small ring pommel), one in EACH hand.
Keep the exact design, proportions (chibi, big head, short limbs), colors, dark outline thickness and colour (2-3 px), and 2-3 tone cel shading of the references.
The standing dual-dagger pose reference (number 48) is the ground truth for the side view; the full-body reference is the ground truth for design and colors. The references contain yellow lightning glow: do NOT copy the glow, draw the character and daggers only.
Do NOT redesign: same hair, face, eyes, outfit, armor, accessories and two daggers; no added or removed details.
The character faces RIGHT in every frame, full body visible, same scale in every frame.
One single horizontal row of exactly 6 poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no shadow, no text, no numbers, no frame borders.
No visual effects (no lightning bolts, electric sparks, yellow glow, slash arcs, afterimages, speed lines): character and two daggers only.

Animation: Blade flurry loop: rooted in place, the body keeps twisting while the two daggers alternate rapid diagonal up and down slashes all around like a whirlwind, hair whipping with the spin. Loops seamlessly (last pose leads into the first).
Two daggers: one dagger in EACH hand at all times (forward grip, blades pointing forward), never sheathed, never swapped between hands; keep the exact dagger design.
Looping animation: the last pose must lead smoothly back into the first pose.
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
