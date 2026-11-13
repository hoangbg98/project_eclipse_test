# Phiếu 22 — Enkiba / `switch_out`

> Sinh tự động bởi `tools/frames/gen_prompts.py` từ `tools/frames/jobs/char_fire_01.json` và `data/skills/`.
> Sửa phiếu ở file JSON rồi chạy lại, không sửa tay file này.

## Thông số (khớp thời gian trong game)

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/char_fire_01/switch_out/` |
| Số frame | **3** (tạo trong 1 lần, mỗi lần frame 000–002) |
| fps / lặp | 12 fps, không lặp |
| Thời lượng | 250 ms |
| Frame trúng đòn | — |
| Kiếm | **cầm trong tay** (đã rút sẵn từ frame đầu) |
| Đứng đất | có: chân ở y = 336 mọi frame |

**Động tác:** Rời sân: quay người, lùi về sau, kiếm vẫn cầm tay (hiệu ứng tan biến làm bằng VFX, không vẽ).

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `assets/characters/char_fire_01/portrait/char_fire_01_portrait_full.png` | Ảnh gốc của owner: khuôn mặt, tóc, trang phục và CÁCH CẦM KIẾM (kiếm luôn cầm tay, mũi kiếm hạ xuống trước) |
| `assets/characters/char_fire_01/rig_parts/char_fire_01_part_44_weapon_kiem_lua.png` | Kiếm lửa (số 44): giữ đúng hình kiếm |
| `assets/characters/char_fire_01/frames/idle/char_fire_01_idle_000.png` | Idle cũ (nhìn ngang quay phải): CHỈ để khóa nét viền, màu, tỉ lệ chibi, góc nhìn ngang. BỎ QUA thanh kiếm đeo sau lưng — kiếm phải cầm tay |
| `assets/characters/char_fire_01/frames/idle/char_fire_01_idle_003.png` | Idle cũ, pose khác: tóc, áo đung đưa (cũng bỏ qua kiếm sau lưng) |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `switch_out` cho Enkiba (char_fire_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/char_fire_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/char_fire_01/22_switch_out.md. Giữ đúng ngoại hình model gốc, kiếm theo mục Kiếm của phiếu.

1. Tạo ảnh bằng skill imagegen, 1 lần gọi (3 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (nhiều lần gọi: thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/char_fire_01/switch_out/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py char_fire_01 switch_out <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng; sai thì thêm --ref-frame / --ref-ratio)
3. Ghi art_review/char_fire_01/switch_out/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py char_fire_01 switch_out — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo danh sách trong phiếu (mục Tự kiểm tra). Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/char_fire_01/switch_out/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG sửa frames_manifest.json, KHÔNG commit. Chờ tôi trả lời "duyệt switch_out".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py char_fire_01 switch_out, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: Enkiba switch_out frames (AI)". Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME character as the reference images: Enkiba, chibi anime swordsman (about 2.5 heads tall, big head, short limbs): spiky crimson hair with one bright orange streak at the front, amber eyes, serious calm face; black cropped short-sleeved jacket with gold trim and flame motifs, open at the chest over a white shirt; ONE red-and-gold pauldron on the shoulder nearest the viewer; black fingerless gloves with gold marks; dark red trousers; black boots with gold trim and orange soles; a gold flame-shaped belt buckle; a long red-and-orange flame-patterned coat tail hanging behind the hips. Weapon: a flame-patterned red-gold sword (gold crossguard, orange gem). The sword is ALWAYS DRAWN: it is held in the hand nearest the viewer in EVERY frame of EVERY animation, exactly as in the original portrait. There is NO scabbard and NOTHING on the back: never draw the sword sheathed or worn on the back.
Keep the exact design, proportions (chibi, big head, short limbs), colors, dark outline thickness and colour (2-3 px), and 2-3 tone cel shading of the references.
The older idle reference frames are the ground truth ONLY for the side view, line art, proportions and colors; IGNORE the sword on their back - in your frames the sword is always in the hand.
Do NOT redesign: same hair, face, eyes, outfit, armor, accessories and sword; no added or removed details.
The character faces RIGHT in every frame, full body visible, same scale in every frame.
One single horizontal row of exactly 3 poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no shadow, no text, no numbers, no frame borders.
No visual effects (no fire trails, slash arcs, sparks, glow, speed lines): character and sword only.

Animation: Exit: turn away and step back out of the fight (no dissolve effect drawn). The sword stays in the near hand.
Sword: the sword is DRAWN and held in the hand in front of the body in every pose (it is not on the back); keep its exact flame design.
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
