# Phiếu 07 — Iwagane / `jump_up`

> Sinh tự động bởi `tools/frames/gen_prompts.py` từ `tools/frames/jobs/char_earth_01.json` và `data/skills/`.
> Sửa phiếu ở file JSON rồi chạy lại, không sửa tay file này.

## Thông số (khớp thời gian trong game)

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/char_earth_01/jump_up/` |
| Số frame | **3** (tạo trong 1 lần, mỗi lần frame 000–002) |
| fps / lặp | 12 fps, không lặp |
| Thời lượng | 250 ms |
| Frame trúng đòn | — |
| Đại kiếm | **cầm đại kiếm**: tay gần (phải) nắm chuôi, đòn nặng thì cả hai tay; kiếm luôn trong tay, không đổi sang tay xa, không cất |
| Đứng đất | không: frame thấp nhất chạm y = 336, frame khác giữ độ cao tương đối |

**Động tác:** Nhảy lên: khuỵu sâu lấy đà, bật mạnh, co gối bay lên, đại kiếm vác vai. Frame 1 chân chạm đất, các frame sau cao dần.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `assets/characters/char_earth_01/rig_parts/source/refs/char_earth_01_ref_01_toan_than.png` | Ảnh đứng toàn thân của owner (số 1): khóa thiết kế, màu, tỉ lệ chibi, bím tóc, sẹo, đại kiếm |
| `assets/characters/char_earth_01/rig_parts/source/refs/char_earth_01_ref_52_pose_dung_cam_kiem.png` | Pose mẫu đứng cầm kiếm (số 52): chuẩn tỉ lệ chibi nhỏ và cách cầm kiếm |
| `assets/characters/char_earth_01/rig_parts/source/refs/char_earth_01_ref_38_kiem_da_rune.png` | Kiếm đá rune (số 38): giữ đúng hình lưỡi đá, chữ rune, chuôi, chắn kiếm, đá vàng ở đuôi chuôi |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `jump_up` cho Iwagane (char_earth_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/char_earth_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/char_earth_01/07_jump_up.md. Giữ đúng ngoại hình model gốc, đại kiếm theo mục Đại kiếm của phiếu.

1. Tạo ảnh bằng skill imagegen, 1 lần gọi (3 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (nhiều lần gọi: thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/char_earth_01/jump_up/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py char_earth_01 jump_up <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 0.80× lúc đứng; sai thì thêm --ref-frame / --ref-ratio)
3. Ghi art_review/char_earth_01/jump_up/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py char_earth_01 jump_up — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo danh sách trong phiếu (mục Tự kiểm tra). Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/char_earth_01/jump_up/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG sửa frames_manifest.json, KHÔNG commit. Chờ tôi trả lời "duyệt jump_up".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py char_earth_01 jump_up, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: Iwagane jump_up frames (AI)". Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME character as the reference images: Iwagane, chibi anime earth greatsword tank, a sturdy muscular young woman (about 2.5 heads tall, big head, short strong limbs): messy shaggy dark-brown hair with a thick braid hanging over her right shoulder and a small leather tie at its end, amber-gold eyes, tanned skin, a small red X-shaped scar on her right cheek and thin scratch scars, serious determined face; heavy bronze plate armor: big rounded bronze pauldrons with mossy olive-green panels engraved with square spiral patterns, sculpted bronze breastplate over a dark olive high-collar tunic, bronze vambraces and gauntlets, wide bronze belt with a square buckle and a small leather pouch, layered bronze tassets over an olive-green skirt, a long dark-brown cloth tabard hanging at the front with tan zigzag borders, carved rune symbols and a mountain motif at the bottom, bronze knee and shin guards with olive-green diamond panels, brown leather boots with steel toe caps. Weapon: one huge greatsword almost as tall as she is: a rough grey-brown stone blade with thin yellow carved runes along its centre line, a bronze crossguard with carved patterns, a brown leather-wrapped grip and a diamond-shaped bronze pommel holding a small yellow gem.
Keep the exact design, proportions (chibi, big head, short limbs), colors, dark outline thickness and colour (2-3 px), and 2-3 tone cel shading of the references.
The small standing pose reference (number 52) is the ground truth for the chibi proportions; the full-body reference is the ground truth for design and colors. Some references show yellow electric glow, sword trails or flying rocks: do NOT copy them, draw the character and the greatsword only.
The carved runes on the stone blade are part of the sword design (keep them as thin yellow lines), but the blade does not emit light or glow.
Asymmetric details must stay on the same body side in every frame: the braid hangs on her right side, the X scar is on her right cheek.
Do NOT redesign: same hair, face, eyes, outfit, armor, accessories and stone greatsword; no added or removed details.
The character faces RIGHT in every frame, full body visible, same scale in every frame.
One single horizontal row of exactly 3 poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no shadow, no text, no numbers, no frame borders.
No visual effects (no rock shards, flying dust, cracks in the ground, stone waves, glowing aura, amber light, slash arcs, speed lines): character and stone greatsword only.

Animation: Jump take-off: deep crouch for anticipation, powerful push off the ground, rising with knees tucked, the greatsword held on the near shoulder. Frame 1 feet on the ground, then each frame higher.
Stone greatsword: the greatsword is always held: gripped in the near (right) hand, with both hands on the grip during heavy swings; never dropped, never sheathed, never switched to the far hand only; keep the exact sword design and its huge size (blade about as long as her body).
```

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống hoàn toàn ảnh gốc (tóc nâu bù xù, bím tóc, sẹo chữ X ở má, giáp vai đồng có mảng xanh rêu, giáp ngực, vải tabard rune, váy giáp, ủng, đại kiếm đá rune, màu)?
2. Tỉ lệ chibi giữ nguyên, không bộ phận nào phình / co / biến dạng?
3. Nét viền, bảng màu, kiểu đổ bóng đồng nhất giữa các frame?
4. Động tác đọc rõ ở cỡ nhỏ, có lấy đà – đánh – thu về; bóng đen từng pose phân biệt được?
5. `check_frames.py` ĐẠT: chân ở 336, tâm 192, không bị cắt mép?
6. `anim_flip.gif` (lật trái) vẫn đúng: kiếm không nhảy tay, bím tóc và sẹo luôn ở cùng một bên người, chi tiết lệch một bên nhất quán?
7. Không xuyên vật thể, tay / chân gần – xa camera đúng lớp?
8. Không vẽ hiệu ứng (đá vụn, bụi, vết nứt, sóng đá, hào quang hổ phách, vệt chém) vào frame nhân vật?
