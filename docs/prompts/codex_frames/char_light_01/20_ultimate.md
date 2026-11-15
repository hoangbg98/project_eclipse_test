# Phiếu 20 — Hikarine / `ultimate`

> Sinh tự động bởi `tools/frames/gen_prompts.py` từ `tools/frames/jobs/char_light_01.json` và `data/skills/`.
> Sửa phiếu ở file JSON rồi chạy lại, không sửa tay file này.

## Thông số (khớp thời gian trong game)

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/char_light_01/ultimate/` |
| Số frame | **14** (tạo trong 3 lần, mỗi lần frame 000–004, frame 005–009, frame 010–013) |
| fps / lặp | 10 fps, không lặp |
| Thời lượng | 1400 ms — khởi động / hiệu lực / hồi phục 700/300/400 ms |
| Frame trúng đòn | 007, 008, 009 |
| Gậy phép | **cầm gậy ở tay gần**: gậy luôn trong tay, đòn mạnh thì hai tay; không buông, không đổi sang tay xa |
| Đứng đất | không: frame thấp nhất chạm y = 336, frame khác giữ độ cao tương đối |

**Động tác:** Thiên Sứ Giáng Lâm: (khởi động 700 ms) chắp tay ôm gậy cầu nguyện, rồi dang hai tay, bay lên cao dần (vẽ cao hơn mặt đất, khoảng 200 px trong game do engine nâng; trong frame chỉ thấy chân rời đất), gậy giơ cao ở tay gần; (hiệu lực 300 ms) dang rộng hai tay, ngửa đầu, hô lớn, giữ pose; (hồi phục 400 ms) hạ tay, ôm gậy về trước ngực. 6 cánh sáng, vòng ma pháp, lông vũ, cut-in là VFX / ảnh riêng: không vẽ cánh.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `assets/characters/char_light_01/rig_parts/source/refs/char_light_01_ref_01_toan_than.png` | Ảnh đứng toàn thân của owner (số 1): khóa thiết kế, màu, tóc dài, vòng miện, áo, đai xanh, gậy |
| `assets/characters/char_light_01/rig_parts/source/refs/char_light_01_ref_42_pose_dung_cam_gay.png` | Pose mẫu đứng cầm gậy (số 42): chuẩn tỉ lệ chibi nhỏ và cách cầm gậy |
| `assets/characters/char_light_01/rig_parts/source/refs/char_light_01_ref_27_gay_phep.png` | Gậy phép mặt trời (số 27): giữ đúng hình vòng mặt trời, quả cầu, thân gậy vàng |
| `assets/characters/char_light_01/rig_parts/source/refs/char_light_01_ref_47_pose_tung_phep.png` | Pose mẫu giơ gậy tung phép (số 47) |
| `assets/characters/char_light_01/rig_parts/source/refs/char_light_01_ref_07_mat_het.png` | Mặt hét / niệm phép (số 7) |

## Giai đoạn từng frame

| Frame | Giai đoạn |
|---|---|
| 000 | Khởi động (lấy đà) |
| 001 | Khởi động (lấy đà) |
| 002 | Khởi động (lấy đà) |
| 003 | Khởi động (lấy đà) |
| 004 | Khởi động (lấy đà) |
| 005 | Khởi động (lấy đà) |
| 006 | Khởi động (lấy đà) |
| 007 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 008 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 009 | Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp) |
| 010 | Hồi phục (thu về) |
| 011 | Hồi phục (thu về) |
| 012 | Hồi phục (thu về) |
| 013 | Hồi phục (thu về) |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `ultimate` cho Hikarine (char_light_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/char_light_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/char_light_01/20_ultimate.md. Giữ đúng ngoại hình model gốc, gậy phép theo mục Gậy phép của phiếu.

1. Tạo ảnh bằng skill imagegen, 3 lần gọi (5 pose, 5 pose, 4 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (nhiều lần gọi: thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/char_light_01/ultimate/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py char_light_01 ultimate <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng; sai thì thêm --ref-frame / --ref-ratio)
3. Ghi art_review/char_light_01/ultimate/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py char_light_01 ultimate — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo danh sách trong phiếu (mục Tự kiểm tra). Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/char_light_01/ultimate/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG sửa frames_manifest.json, KHÔNG commit. Chờ tôi trả lời "duyệt ultimate".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py char_light_01 ultimate, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: Hikarine ultimate frames (AI)". Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME character as the reference images: Hikarine, chibi anime light-element healer girl (about 2.5 heads tall, big head, short limbs): extremely long wavy platinum-blonde (pale cream) hair reaching below the knees, a thin golden circlet across the forehead with a small V-shaped centre piece and a tiny gem, warm light-brown eyes, soft gentle kind face; a white high-collared priestess robe with gold trim and gold vine embroidery, a small gold star emblem on the chest, very wide white bell sleeves with ornate gold hems, a pale blue cloth sash tied at the waist with a big bow on her left hip and two long tails hanging down, a long white layered skirt with a pale lavender-grey underskirt and a long white front panel decorated with gold ornaments, white knee-high boots with gold trim. Weapon: a tall slender golden staff about as tall as she is, with an ornate curled gold collar below the head; the head is a spiked golden sun ring holding a round solid pale-yellow orb.
Keep the exact design, proportions (chibi, big head, short limbs), colors, dark outline thickness and colour (2-3 px), and 2-3 tone cel shading of the references.
The small standing pose reference (number 42) is the ground truth for the chibi proportions and the staff size; the full-body reference is the ground truth for design and colors. Several references show large golden glows, light rings, rays or a light shield: do NOT copy them, draw the character and the staff only.
The orb in the sun ring is part of the staff: draw it as a solid pale-yellow sphere with at most a tiny soft highlight, no large halo or light rays.
Her hair is extremely long (below the knees): keep its length and volume in every frame, it trails behind and follows the motion with a slight delay.
Asymmetric details must stay on the same body side in every frame: the sash bow and its tails are on her left hip; the staff stays in the near hand.
Do NOT redesign: same hair, face, eyes, outfit, armor, accessories and sun staff; no added or removed details.
The character faces RIGHT in every frame, full body visible, same scale in every frame.
One single horizontal row of exactly {n} poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no shadow, no text, no numbers, no frame borders.
No visual effects (no light rays, glowing halos, magic circles, light particles, feathers, wings, sun orbs flying away, light beams, slash arcs, speed lines): character and sun staff only.

Animation: Ultimate: start in a short prayer holding the staff to the chest, then spread both arms and rise upward (feet leaving the ground; the game moves her up, keep her inside the canvas), the staff raised high in the near hand; at the peak open both arms wide, head tilted up, shouting (shouting face reference), hold the pose; then lower the arms and bring the staff back to the chest. Do NOT draw wings, magic circles or feathers: they are separate effects.
This call: poses {a}–{b} of 14 (describe only this part of the motion; continue exactly from the attached previous strip).
Sun staff: the sun staff is always held in the near hand (both hands for strong spells); never dropped, never switched to the far hand only; keep the exact staff design and its length (about as tall as her body).
Phase map (poses counted from 1): wind-up 1-7, impact 8-10 (clear extended pose, readable silhouette, brief hold), recovery 11-14.
Impact poses (the staff head pushed fully forward or upward and held for a beat at the moment the spell is released): poses 8, 9, 10 of 14, counting from 1.
```

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống hoàn toàn ảnh gốc (tóc vàng nhạt dài quá gối, vòng miện vàng, áo trắng cổ đứng viền vàng, tay áo rộng, đai xanh có nơ, váy nhiều lớp, ủng trắng, gậy mặt trời, màu)?
2. Tỉ lệ chibi giữ nguyên, không bộ phận nào phình / co / biến dạng?
3. Nét viền, bảng màu, kiểu đổ bóng đồng nhất giữa các frame?
4. Động tác đọc rõ ở cỡ nhỏ, có lấy đà – đánh – thu về; bóng đen từng pose phân biệt được?
5. `check_frames.py` ĐẠT: chân ở 336, tâm 192, không bị cắt mép?
6. `anim_flip.gif` (lật trái) vẫn đúng: gậy không nhảy tay, nơ đai luôn ở cùng một bên hông, chi tiết lệch một bên nhất quán?
7. Không xuyên vật thể, tay / chân gần – xa camera đúng lớp?
8. Không vẽ hiệu ứng (tia sáng, hào quang, vòng ma pháp, hạt sáng, lông vũ, cánh sáng, quả cầu bay đi) vào frame nhân vật?
