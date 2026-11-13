# Phiếu 06 — Kazeyumi / `dodge`

> Sinh tự động bởi `tools/frames/gen_prompts.py` từ `tools/frames/jobs/char_wind_01.json` và `data/skills/`.
> Sửa phiếu ở file JSON rồi chạy lại, không sửa tay file này.

## Thông số (khớp thời gian trong game)

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/char_wind_01/dodge/` |
| Số frame | **6** (tạo trong 1 lần, mỗi lần frame 000–005) |
| fps / lặp | 20 fps, không lặp |
| Thời lượng | 300 ms — khởi động / hiệu lực / hồi phục 30/160/110 ms |
| Frame trúng đòn | 000, 001, 002, 003 |
| Cung | cầm cung suốt vòng lộn; bắn **một tên** về phía trước ở giữa vòng lộn |
| Đứng đất | không: frame thấp nhất chạm y = 336, frame khác giữ độ cao tương đối |

**Động tác:** Lộn Gió Lùi: nhún chân, lộn ngược một vòng về sau, tóc và áo choàng tung, giữa vòng lộn bắn một tên về phía trước, tiếp đất bằng một chân.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png` | Ảnh đứng toàn thân của owner: khóa thiết kế, màu, tỉ lệ chibi, cung, ống tên |
| `assets/characters/char_wind_01/rig_parts/source/refs/char_wind_01_ref_57_pose_keo_cung.png` | Pose mẫu kéo cung nhìn ngang quay phải: chuẩn góc nhìn và cách cầm cung |
| `assets/characters/char_wind_01/rig_parts/source/refs/char_wind_01_ref_39_cung.png` | Cây cung (số 39): giữ đúng hình cung |
| `assets/characters/char_wind_01/rig_parts/source/refs/char_wind_01_ref_58_pose_nhay_ban.png` | Pose mẫu nhảy bắn (số 58) |

## Giai đoạn từng frame

| Frame | Giai đoạn |
|---|---|
| 000 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 001 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 002 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 003 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 004 | Hồi phục (thu về) |
| 005 | Hồi phục (thu về) |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `dodge` cho Kazeyumi (char_wind_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/char_wind_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/char_wind_01/06_dodge.md. Giữ đúng ngoại hình model gốc, cung theo mục Cung của phiếu.

1. Tạo ảnh bằng skill imagegen, 1 lần gọi (6 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (nhiều lần gọi: thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/char_wind_01/dodge/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py char_wind_01 dodge <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 0.85× lúc đứng; sai thì thêm --ref-frame / --ref-ratio)
3. Ghi art_review/char_wind_01/dodge/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py char_wind_01 dodge — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo danh sách trong phiếu (mục Tự kiểm tra). Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/char_wind_01/dodge/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG sửa frames_manifest.json, KHÔNG commit. Chờ tôi trả lời "duyệt dodge".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py char_wind_01 dodge, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: Kazeyumi dodge frames (AI)". Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME character as the reference images: Kazeyumi, chibi anime wind archer girl (about 2.5 heads tall, big head, short limbs): long wavy mint-green hair tied in a high ponytail with loose side locks, a white feather hair ornament with a teal gem on one side of the head, teal eyes, gentle confident face; sleeveless ivory high-collar tunic with gold trim and small green leaf marks, crossed brown leather straps with a gold buckle and small belt pouches, a dark teal cape hanging from one shoulder with a round gold clasp; short pleated teal skirt over black shorts; brown leather arm bracers; ivory knee-high boots with teal trim, brown straps and small white wings at the ankles; a brown quiver of white-fletched arrows on her back. Weapon: a tall cream-and-gold recurve bow with teal wrapping, small diamond inlays and a green ribbon near the grip.
Keep the exact design, proportions (chibi, big head, short limbs), colors, dark outline thickness and colour (2-3 px), and 2-3 tone cel shading of the references.
The side-view drawing pose reference (facing right, bow in the front hand) is the ground truth for the side view; the full-body reference is the ground truth for design and colors.
Do NOT redesign: same hair, face, eyes, outfit, armor, accessories and bow; no added or removed details.
The character faces RIGHT in every frame, full body visible, same scale in every frame.
One single horizontal row of exactly 6 poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no shadow, no text, no numbers, no frame borders.
No visual effects (no wind trails, glowing arrows, flying leaves, sparks, speed lines): character and bow only.

Animation: Back-flip dodge: crouch, flip backward in one full circle (moving away from the target), hair and cape flaring, at the top of the flip shoot one arrow forward to the right, land on one foot.
Bow: the bow is held in the FRONT hand pointing toward the target on the right, the back hand draws the string to the cheek with a nocked arrow, then releases; after the release draw NO flying arrow (the game spawns the projectile); keep the exact bow design.
Phase map (poses counted from 1): wind-up none, impact 1-4 (clear extended pose, readable silhouette, brief hold), recovery 5-6.
Impact poses (string just released, bow arm fully extended toward the target): poses 1, 2, 3, 4 of 6, counting from 1.
```

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống hoàn toàn ảnh gốc (tóc đuôi ngựa, kẹp lông vũ, mặt, áo, áo choàng, dây da, bao tay, ủng cánh, cung, ống tên, màu)?
2. Tỉ lệ chibi giữ nguyên, không bộ phận nào phình / co / biến dạng?
3. Nét viền, bảng màu, kiểu đổ bóng đồng nhất giữa các frame?
4. Động tác đọc rõ ở cỡ nhỏ, có lấy đà – đánh – thu về; bóng đen từng pose phân biệt được?
5. `check_frames.py` ĐẠT: chân ở 336, tâm 192, không bị cắt mép?
6. `anim_flip.gif` (lật trái) vẫn đúng: cung không nhảy tay, áo choàng và kẹp tóc nhất quán một bên, chi tiết lệch một bên nhất quán?
7. Không xuyên vật thể, tay / chân gần – xa camera đúng lớp?
8. Không vẽ hiệu ứng (gió, mũi tên phát sáng, lá bay) vào frame nhân vật?
