# Phiếu 01 — Enkiba / `idle`

> Sinh tự động bởi `tools/frames/gen_prompts.py` từ `tools/frames/jobs/char_fire_01.json` và `data/skills/`.
> Sửa phiếu ở file JSON rồi chạy lại, không sửa tay file này.

## Thông số (khớp thời gian trong game)

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/char_fire_01/idle/` |
| Số frame | **6** (tạo trong 1 lần, mỗi lần frame 000–005) |
| fps / lặp | 8 fps, lặp liền mạch |
| Thời lượng | 750 ms |
| Frame trúng đòn | — |
| Đứng đất | có: chân ở y = 336 mọi frame |

**Động tác:** Đứng thủ thế thả lỏng, kiếm cầm thấp, vai nhấp nhô theo nhịp thở, tóc và vạt áo đung đưa nhẹ. Lặp liền: frame cuối nối frame đầu.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `assets/characters/char_fire_01/portrait/char_fire_01_portrait_full.png` | Khóa thiết kế: tỉ lệ chibi, màu, trang phục, tay cầm kiếm |
| `assets/characters/char_fire_01/rig_parts/char_fire_01_part_16_pose_anh_dung_tong_the_tham_chieu.png` | Ảnh đứng tổng thể (bảng bộ phận số 16) |
| `assets/characters/char_fire_01/rig_parts/char_fire_01_part_44_weapon_kiem_lua.png` | Kiếm lửa (số 44): giữ đúng hình kiếm |
| `assets/characters/char_fire_01/rig_parts/char_fire_01_part_58_pose_pose_mau.png` | Pose mẫu đứng (số 58) |
| Frame `idle` đã duyệt (nếu có): `assets/characters/char_fire_01/frames/idle/char_fire_01_idle_000.png` | Khóa tỉ lệ và màu cho các animation sau |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `idle` cho Enkiba (char_fire_01), MỘT animation này thôi. Đọc AGENTS.md (mục Ảnh do AI tạo)
và file docs/prompts/codex_frames/char_fire_01/01_idle.md trước khi làm.

1. Tạo ảnh bằng skill imagegen, 1 lần gọi (6 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (nhiều lần gọi: thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/char_fire_01/idle/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py char_fire_01 idle <dải 1> [<dải 2> ...] [--chroma FF00FF]
   (animation khác idle: thêm --scale <số> lấy từ art_review/char_fire_01/idle/meta.json để cùng tỉ lệ với idle)
3. Ghi art_review/char_fire_01/idle/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py char_fire_01 idle — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo danh sách trong phiếu (mục Tự kiểm tra). Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/char_fire_01/idle/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG sửa frames_manifest.json, KHÔNG commit. Chờ tôi trả lời "duyệt idle".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py char_fire_01 idle, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: Enkiba idle frames (AI)". Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME character as the reference images: Enkiba, chibi anime swordsman (about 2.5 heads tall): spiky crimson hair with one orange streak, amber eyes, black cropped jacket with red-and-gold trim and flame motifs, white shirt, a single red-gold shoulder pauldron, dark red trousers, black fingerless gloves, black boots with orange soles, flame-patterned red-gold sword held in the same hand as in the reference.
Keep the exact design, proportions (chibi), colors, line art thickness and colour, and cel shading of the references.
Do NOT redesign: same hair, face, eyes, outfit, armor, accessories and sword; no added or removed details.
The character faces RIGHT in every frame, full body visible, same scale in every frame.
One single horizontal row of exactly 6 poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no shadow, no text, no numbers, no frame borders.
No visual effects (no fire trails, slash arcs, sparks, glow, speed lines): character and sword only.

Animation: Idle breathing loop: relaxed but ready fighting stance, sword held low, chest and shoulders rise and fall slightly, hair and jacket hem sway gently (secondary motion). The last frame flows seamlessly back into the first.
Looping animation: the last pose must lead smoothly back into the first pose.
```

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống hoàn toàn ảnh gốc (tóc, mặt, áo, giáp vai, găng, ủng, kiếm, màu)?
2. Tỉ lệ chibi giữ nguyên, không bộ phận nào phình / co / biến dạng?
3. Nét viền, bảng màu, kiểu đổ bóng đồng nhất giữa các frame?
4. Động tác đọc rõ ở cỡ nhỏ, có lấy đà – đánh – thu về; bóng đen từng pose phân biệt được?
5. `check_frames.py` ĐẠT: chân ở 336, tâm 192, không bị cắt mép?
6. `anim_flip.gif` (lật trái) vẫn đúng: kiếm không nhảy tay, chi tiết lệch một bên nhất quán?
7. Không xuyên vật thể, tay / chân gần – xa camera đúng lớp?
8. Không vẽ hiệu ứng (lửa, vệt chém, tia sáng) vào frame nhân vật?
