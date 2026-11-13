# Phiếu 06 — Enkiba / `attack_4`

> Sinh tự động bởi `tools/frames/gen_prompts.py` từ `tools/frames/jobs/char_fire_01.json` và `data/skills/`.
> Sửa phiếu ở file JSON rồi chạy lại, không sửa tay file này.

## Thông số (khớp thời gian trong game)

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/char_fire_01/attack_4/` |
| Số frame | **7** (tạo trong 2 lần, mỗi lần frame 000–003, frame 004–006) |
| fps / lặp | 12 fps, không lặp |
| Thời lượng | 600 ms — khởi động / hiệu lực / hồi phục 160/120/320 ms |
| Frame trúng đòn | 001, 002, 003 |
| Kiếm | **cầm trong tay** (đã rút sẵn từ frame đầu) |
| Đứng đất | có: chân ở y = 336 mọi frame |

**Động tác:** Đòn 4 (kết combo): nhảy nhẹ, bổ dọc kiếm xuống đất (sóng lửa trên mặt đất là VFX riêng, không vẽ).

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `assets/characters/char_fire_01/frames/idle/char_fire_01_idle_000.png` | Idle đã duyệt, nhìn ngang quay phải, kiếm đeo sau vai: KHÓA tỉ lệ, màu, nét viền, kiểu đổ bóng |
| `assets/characters/char_fire_01/frames/idle/char_fire_01_idle_003.png` | Idle đã duyệt, pose khác (tóc, áo đung đưa) |
| `assets/characters/char_fire_01/portrait/char_fire_01_portrait_full.png` | Ảnh gốc 3/4 của owner: khuôn mặt, kiểu tóc, hình dáng kiếm khi cầm tay |
| `assets/characters/char_fire_01/rig_parts/char_fire_01_part_44_weapon_kiem_lua.png` | Kiếm lửa (số 44): giữ đúng hình kiếm khi rút ra |

## Giai đoạn từng frame

| Frame | Giai đoạn |
|---|---|
| 000 | Khởi động (lấy đà) |
| 001 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 002 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 003 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 004 | Hồi phục (thu về) |
| 005 | Hồi phục (thu về) |
| 006 | Hồi phục (thu về) |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `attack_4` cho Enkiba (char_fire_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/char_fire_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/char_fire_01/06_attack_4.md. Giữ đúng ngoại hình model gốc, kiếm theo mục Kiếm của phiếu.

1. Tạo ảnh bằng skill imagegen, 2 lần gọi (4 pose, 3 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (nhiều lần gọi: thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/char_fire_01/attack_4/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py char_fire_01 attack_4 <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng; sai thì thêm --ref-frame / --ref-ratio)
3. Ghi art_review/char_fire_01/attack_4/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py char_fire_01 attack_4 — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo danh sách trong phiếu (mục Tự kiểm tra). Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/char_fire_01/attack_4/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG sửa frames_manifest.json, KHÔNG commit. Chờ tôi trả lời "duyệt attack_4".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py char_fire_01 attack_4, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: Enkiba attack_4 frames (AI)". Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME character as the reference images: Enkiba, chibi anime swordsman (about 2.5 heads tall, big head, short limbs): spiky crimson hair with one bright orange streak at the front, amber eyes, serious calm face; black cropped short-sleeved jacket with gold trim and flame motifs, open at the chest over a white shirt; ONE red-and-gold pauldron on the shoulder nearest the viewer; black fingerless gloves with gold marks; dark red trousers; black boots with gold trim and orange soles; a gold flame-shaped belt buckle; a long red-and-orange flame-patterned coat tail hanging behind the hips. Weapon: a flame-patterned red-gold sword with a gold crossguard and an orange gem. When sheathed it is worn diagonally on the back with the hilt above the near shoulder (exactly as in the idle reference frames); when drawn it is held in the hand in front of the body.
Keep the exact design, proportions (chibi, big head, short limbs), colors, dark outline thickness and colour (2-3 px), and 2-3 tone cel shading of the references.
The approved idle reference frames are the ground truth for the side view, line art and colors.
Do NOT redesign: same hair, face, eyes, outfit, armor, accessories and sword; no added or removed details.
The character faces RIGHT in every frame, full body visible, same scale in every frame.
One single horizontal row of exactly {n} poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no shadow, no text, no numbers, no frame borders.
No visual effects (no fire trails, slash arcs, sparks, glow, speed lines): character and sword only.

Animation: Combo finisher: small hop, heavy vertical overhead slash down into the ground, hold the impact pose briefly, recover.
This call: poses {a}–{b} of 7 (describe only this part of the motion; continue exactly from the attached previous strip).
Sword: the sword is DRAWN and held in the hand in front of the body in every pose (it is not on the back); keep its exact flame design.
Phase map (poses counted from 1): wind-up 1-1, impact 2-4 (clear extended pose, readable silhouette, brief hold), recovery 5-7.
Impact poses (sword fully extended at the moment of the hit): poses 2, 3, 4 of 7, counting from 1.
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
