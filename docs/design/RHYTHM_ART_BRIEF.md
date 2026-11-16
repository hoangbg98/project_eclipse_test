# Chế độ nhịp điệu — mô tả quái và danh sách ảnh cần có (M10-2)

Dùng cho owner / họa sĩ / Codex imagegen. Hiện màn chơi vẽ tạm bằng code (`scripts/ui/rhythm/rhythm_stage.gd`);
có ảnh thì thay vào. Thiết kế là của dự án: **không** bắt chước nhân vật, quái, giao diện hay phong cách nhận diện của game
khác (kể cả game nhịp điệu dùng làm tham khảo cơ chế).

## 1. Bối cảnh

Nhật Thực làm méo âm nhạc của thế giới, sinh ra **Âm Ảnh**: những sinh vật nhỏ làm từ nốt nhạc bị nhuộm bóng tối.
Chúng chạy theo nhịp bài hát lao về phía giáp của người chơi. Đánh trúng đúng nhịp thì Âm Ảnh vỡ thành nốt nhạc sáng
(trả lại âm thanh cho thế giới). Kẻ cầm đầu là boss **Nhật Thực** ở ải N-5.

Phong cách chung: chibi, viền rõ, thân tối (tím than `#2A1B4A`) với **một màu phát sáng theo làn** để người chơi nhìn
là biết phải ấn phím nào:

| Làn | Màu phát sáng | Phím |
|---|---|---|
| Trên | xanh lơ `#5FD7FF` | D / F / ↑ |
| Dưới | hồng `#FF5FA8` | J / K / ↓ |
| Cả hai | vàng `#FFD84D` | ấn cả hai |

Màu sáng nằm ở mắt, viền và chi tiết nổi bật (≥ 25 % diện tích), thân giữ tối để nổi trên nền. Quái lao **từ phải sang
trái**, nên **vẽ quay mặt sang TRÁI** (khác frame nhân vật vẽ hướng phải).

## 2. Các loại quái (mỗi loại = một kiểu nốt)

### 2.1 Dơi Nốt — nốt ấn 1 lần, làn trên
Con dơi tròn cỡ nắm tay, thân là một nốt móc đơn (♪), đuôi móc nhạc cong lên, hai cánh màng mỏng viền xanh lơ, một mắt
to phát sáng, răng nanh nhỏ. Bay vỗ cánh nhanh, hơi nhấp nhô.

### 2.2 Sên Nhịp — nốt ấn 1 lần, làn dưới
Sinh vật nhầy tròn bẹt có hai chân ngắn, trên đầu cắm một nốt đen như cái sừng, mắt hồng, miệng rộng. Nảy bật theo nhịp
khi chạy trên mặt đường, để lại vệt sáng hồng ngắn.

### 2.3 Song Âm — nốt "cả hai"
Hai sinh vật song sinh (một bay ở làn trên, một chạy ở làn dưới) nối nhau bằng **dây khuông nhạc vàng** căng dọc giữa
hai làn. Hình như Dơi Nốt + Sên Nhịp nhưng viền vàng và đeo chung một cái chuông nhỏ. Dây khuông là chi tiết bắt buộc:
nó báo người chơi phải ấn cả hai.

### 2.4 Rắn Ngân — nốt giữ (làn trên, dưới hoặc cả hai)
Con rắn dài làm từ một nốt ngân: **đầu** là nốt tròn trắng có mắt, **thân** là khuông nhạc kéo dài (độ dài = thời gian
giữ, game tự kéo giãn), **đuôi** là dấu lặng nhỏ. Khi người chơi đang giữ, thân bị "hút" dần vào vạch chấm và phát
sáng mạnh hơn. Bản "cả hai": hai con song song nối dây vàng như Song Âm.

### 2.5 Trống Đá — nốt ấn liên tục
Con quái to (gấp ~2.5 lần quái thường) hình cái trống có vỏ đá, mặt trống là cái bụng, hai tay dùi trống nhỏ. Đứng lì
ở vạch chấm, mỗi lần bị đánh thì lõm bụng và nứt thêm; hết thời gian thì vỡ tung (nếu đánh đủ) hoặc nhảy qua người chơi
(nếu không đủ). Có số đếm lần còn lại hiện ở bụng (game tự viết số).

### 2.6 Boss Nhật Thực — ải N-5
Một vầng mặt trời bị nuốt: đĩa đen lớn, vành lửa cam `#FFB347` cháy quanh (quầng nhật hoa), hai mắt đỏ `#FF4D6D`,
miệng răng cưa. Hai tay là hai vầng trăng khuyết lơ lửng, dùng như gậy chỉ huy dàn nhạc. Đứng (lơ lửng) ở mép phải màn
suốt bài, nhịp đập theo BPM, **ném** Âm Ảnh ra (mỗi nốt bay ra từ tay boss). Không bị đánh trực tiếp; mất máu theo số
nốt người chơi đánh trúng, cuối bài vỡ tan nếu người chơi qua ải.

### 2.7 Biến thể theo ải (không bắt buộc, làm sau)
N-1 lửa (đốm than trên thân), N-2 gió (lá xoáy), N-3 sấm (tia điện), N-4 ánh sáng (hào quang). Chỉ là phụ kiện vẽ thêm;
**màu phát sáng theo làn giữ nguyên**.

## 3. Danh sách ảnh

Quy cách chung: PNG nền trong suốt, tâm khung = tâm quái (riêng Sên Nhịp, Trống Đá: chân ở đáy khung, cách đáy 10 %).
Đặt vào `assets/rhythm/...`, tên `{id}_{anim}_{NNN}.png` (NNN từ 000). Ảnh AI: ghi từng file vào
`docs/ASSET_LICENSES.md` mục 2.1.

### Ưu tiên 1 — đủ để thay hình tạm

| # | id / file | Khung | Animation (frame, fps) | Ghi chú |
|---|---|---|---|---|
| 1 | `rh_bat` (Dơi Nốt) | 256×256 | `fly` 6 f, 12 fps lặp; `die` 5 f, 20 fps | hiển thị ~110 px |
| 2 | `rh_slime` (Sên Nhịp) | 256×256 | `run` 6 f, 12 fps lặp; `die` 5 f, 20 fps | hiển thị ~110 px |
| 3 | `rh_twin` (Song Âm) | 256×256 ×2 con | `fly`/`run` 6 f lặp; `die` 5 f | có thể vẽ lại từ 1 và 2 viền vàng + chuông |
| 4 | `rh_twin_chain.png` | 64×256 | 1 ảnh, lặp dọc | dây khuông vàng nối 2 làn |
| 5 | `rh_serpent_head` | 256×256 | `idle` 4 f lặp; `bite` (lúc đang giữ) 4 f lặp | màu trung tính, game tô theo làn |
| 6 | `rh_serpent_body.png` | 128×96 | 1 ảnh, **lặp ngang liền mạch** | khuông nhạc 5 dòng |
| 7 | `rh_serpent_tail.png` | 96×96 | 1 ảnh | dấu lặng |
| 8 | `rh_drum` (Trống Đá) | 512×512 | `idle` 4 f lặp; `hit` 3 f, 24 fps; `crack` 3 mức nứt (ảnh tĩnh); `burst` 6 f; `escape` 6 f | hiển thị ~260 px |
| 9 | `rh_boss_eclipse` | 768×768 | `idle` 8 f, 10 fps lặp; `throw` 6 f; `hurt` 3 f; `defeat` 10 f | hiển thị ~480 px |
| 10 | Nền 3 lớp mỗi ải ×5 | 1920×1080 | `far`, `mid` (cuộn ngang liền mạch), `ground` 1920×260 lặp ngang | mặt đường ở y = 830 |

### Ưu tiên 2 — hiệu ứng và giao diện

| # | File | Khung | Ghi chú |
|---|---|---|---|
| 11 | `rh_fx_perfect` | 256×256, 8 f | nổ nốt nhạc sáng (hồng `#FF6FD8`) |
| 12 | `rh_fx_great` | 256×256, 6 f | nhỏ hơn, xanh `#6FD3FF` |
| 13 | `rh_fx_miss` | 256×256, 5 f | khói xám, không lấp lánh |
| 14 | `rh_target_ring.png` | 160×160 | vòng chấm ở vạch đánh (2 làn dùng chung) |
| 15 | `rh_judge_{perfect,great,miss,wrong}.png` | 480×120 | chữ chấm có viền (hoặc giữ chữ font như hiện tại) |
| 16 | `rh_hud_frame.png` | 860×140 | khung thanh HP + Fever ở đáy màn |
| 17 | `rh_icon_crown_{on,off}.png`, `rh_icon_heart_{on,off}.png`, `rh_icon_level.png` | 96×96 | biểu tượng màn danh sách Vô tận |
| 18 | `rh_card_stage_{1..5}.png` | 640×1040 | ảnh thẻ 5 ải ở màn Ải nguyên liệu (thẻ N-5 có boss) |
| 19 | `rh_card_endless.png` | 3400×400 | băng thẻ Vô tận |

### Âm thanh (kèm theo, không phải ảnh)
Tiếng đánh trúng trên / dưới (2 tiếng khác nhau, < 150 ms), tiếng Trống Đá bị đánh, tiếng sai / trượt, tiếng Fever bật.

## 4. Gợi ý prompt (Codex imagegen)

Dùng ảnh Enkiba (`assets/characters/char_fire_01/portrait/`) làm tham chiếu phong cách. Mẫu:
"Chibi game enemy sprite, original design, a round bat whose body is a single eighth note, membrane wings outlined in
glowing cyan #5FD7FF, one big glowing eye, small fangs, dark violet body #2A1B4A, thick clean outline, facing left,
transparent background, centered, 256x256, consistent with the reference character's art style."
Mỗi lần một quái, owner duyệt rồi mới làm animation (giống quy trình frame nhân vật).
