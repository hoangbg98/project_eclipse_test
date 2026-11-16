# Chế độ nhịp điệu — Ải nguyên liệu (M10)

Owner 2026-11-16: thêm cách chơi mới để bớt nhàm chán (không chỉ đánh quái / cốt truyện / gacha). Bắt đầu ở
**ải nguyên liệu**: rơi nhiều nguyên liệu tăng cấp hơn ải thường, gồm **5 ải con**, ải cuối là **boss với màn chơi cố
định**; qua cả 5 mở **chế độ Vô tận** (chọn bài). Lối chơi theo thể loại game nhịp điệu chạy ngang hai làn (tham khảo
cơ chế chung của thể loại); hình, nhạc, tên đều là của dự án.

Owner chọn (2026-11-16): bản nốt **tool tự sinh từ nhạc**; nhạc làm / thử do **Claude sinh**, thay nhạc thật sau;
không có mạng thì **tải về rồi lưu cache** (bài đã tải chơi được ngoại tuyến).

## 1. Luồng

Xuất kích → thẻ **Ải nguyên liệu** → `RhythmMaterialScreen` (5 thẻ N-1…N-5 + thẻ Vô tận) → (tải nhạc + bản nốt nếu
chưa có) → `RhythmStage` → kết quả (thưởng) → Chơi lại / Thoát.
Vô tận: `RhythmSongListScreen` — tab Dễ / Thường / Khó / Yêu thích, mỗi dòng: số thứ tự, tên bài, tác giả, vương
miện theo hạng tốt nhất (S = 3, A = 2, B = 1), mức độ khó, kỷ lục, tim yêu thích, nút Chơi.

**Người mới** (owner 2026-11-16): ải N-1 chậm nhất (550 px/s), chỉ có nốt ấn 1 lần, và lần đầu chơi có **hướng dẫn
ngay trong ải** (`data/rhythm/tutorial.json`): 4 bước luyện làn trên → làn dưới → xen kẽ → cả hai, quái chậm, không mất
HP, trúng đủ thì sang bước sau, chưa đủ thì làm lại; có nút "Bỏ qua hướng dẫn"; xong thì đếm ngược vào bài. Rắn Ngân
(nốt giữ) và quái trống (ấn liên tục) bắt đầu từ N-2, lần đầu chơi N-2 có dòng giới thiệu lúc đếm ngược (dài thêm 3 s).
Không nốt nào xuất hiện trước giây 1.5 của bài.

## 2. Điều khiển

| | Bàn phím | Tay cầm | Cảm ứng |
|---|---|---|---|
| Đánh trên | D, F, ↑ | Y, LB | chạm nửa trái màn |
| Đánh dưới | J, K, ↓ | A, RB | chạm nửa phải màn |
| Tạm dừng | P, Esc | Start | nút ‖ |

Action `rhythm_up` / `rhythm_down` trong `InputRouter`. Nhiều phím cùng làn: nhả hết mới tính là nhả.

## 3. Luật chấm (`RhythmJudge`, số trong `data/rhythm/rhythm_rules.tres`)

- Mỗi nốt đòi **đúng một trong 3 lựa chọn**: trên, dưới, hoặc cả hai (hai phím cách nhau ≤ `chord_window` = 60 ms).
  Lần ấn đầu trong cửa sổ quyết định; **chọn nhầm = SAI**: mất `wrong_damage` HP, mất combo.
  Nốt một làn cũng chờ `chord_window` để biết người chơi có ấn thêm làn kia không.
- **Chấm theo độ khớp hitbox** (owner 2026-11-16): quái to hơn gấp đôi vòng chấm (`enemy.ring_ratio` = 2.2 trong
  `data/ui/rhythm_layout.json`), giữa thân có **hitbox vàng** cùng bán kính với vòng chấm (`ring_radius` = 72 px).
  Khi còn xa, hitbox nhấp nháy to / nhỏ theo nhịp; từ lúc chạm vòng thì đúng bằng vòng, vào giữa vòng là khít.
  Lúc ấn, tỉ lệ diện tích hitbox nằm trong vòng quyết định:

  | Mức | Điều kiện | Lệch (với `note_speed` 800 px/s) | Điểm |
  |---|---|---|---|
  | Perfect | khít (chồng ≥ `perfect_overlap` = 85 %) | ≤ ~21 ms | 200 |
  | Great | chồng ≥ 3/4 | ≤ ~36 ms | 150 |
  | Good | chồng ≥ 1/2 | ≤ ~73 ms | 100 |
  | Normal | đã qua viền vào trong vòng | < 180 ms | 50 |
  | Miss | chỉ chạm viền ngoài (dày `ring_rim` = 10 px) | 180–192 ms | mất HP, mất combo |

  Xa hơn nữa (hitbox chưa chạm vòng): ấn không sao. Lệch đổi ra ms theo `note_speed`: quái chạy chậm thì cửa sổ rộng hơn.
  Perfect, Great, Good, Normal đều giữ combo; Normal không cộng Fever. Độ chính xác = (Perfect + Great × 0.75 +
  Good × 0.5 + Normal × 0.25) / tổng.
- Để nốt trôi qua: **Miss**, mất `miss_damage` HP.
- **Tốc độ tăng dần theo ải** (owner 2026-11-16, `note_speed` trong `data/rhythm/material_stages.json`):

  | Ải | N-1 | N-2 | N-3 | N-4 | N-5 boss | Vô tận Dễ / Thường / Khó |
  |---|---|---|---|---|---|---|
  | Tốc độ (px/s) | 550 (×0.7) | 750 | 850 | 950 | 1050 (×1.3) | 700 / 850 / 1000 |
  | Bản nốt (độ khó) | easy (2) | normal (5) | hard (8) | hard (10) | boss (11) | theo độ khó chọn |

  Vòng chấm, viền và hitbox phóng theo tốc độ (`RhythmRules.for_speed`) nên cửa sổ ms của 5 mức **giữ nguyên** ở mọi ải:
  nhanh hơn = ít thời gian nhìn (quái từ mép màn tới vòng: ~2.8 s ở N-1, ~1.5 s ở N-5) và nốt dày hơn, nhưng Perfect
  luôn ±21 ms — nhanh tay nhanh mắt là đạt được. Quái to theo vòng (đường kính vòng × `enemy.ring_ratio` 2.1).
- **Hitbox không đè nhau**: hai nốt cùng làn cách nhau ≥ 2 × bán kính / tốc độ (180 ms) tính từ lúc nốt trước kết thúc;
  game tự bỏ nốt vi phạm (`RhythmChart.enforce_spacing`), tool sinh nốt cũng giữ `LANE_GAP` = 0.19 s. Ảnh quái được
  phép chồng lên nhau; nốt khác làn xen sát tới ~80–100 ms ở bản Khó / boss.
- **Thời điểm ấn chính xác**: mỗi lần nhận phím, game đọc lại đồng hồ nhạc ngay lúc đó (không dùng giá trị của frame
  trước, vốn lệch tới ~16 ms ở 60 fps).
- **Ấn 1 lần** (tap). **Giữ** (hold): chấm đầu thanh như tap, rồi giữ (các) phím tới cuối thanh; thả sớm hơn
  `hold_release_tolerance` = gãy (Trượt, mất `hold_break_damage`). Nốt giữ tính 2 đơn vị chấm.
- **Ấn liên tục** (mash): trong thời gian nốt, mỗi lần ấn đúng làn +điểm; cuối nốt chấm theo số lần / yêu cầu
  (≥ 100 % Perfect, ≥ 50 % Great, thấp hơn Miss). Mash "cả hai" nhận phím làn nào cũng được.
- Combo cộng điểm (`combo_bonus_step`, trần `combo_bonus_cap`). **Fever**: thanh đầy (Perfect +2, Great +1.5, Good +1 / 100) →
  8 s điểm ×1.5.
- HP về 0 = thất bại (không thưởng). Hạng theo độ chính xác: S ≥ 95 %, A ≥ 90 %,
  B ≥ 80 %, C ≥ 70 %, còn lại D.

## 4. Dữ liệu

- Ải: `data/rhythm/material_stages.json` (bài, bản nốt, boss, thưởng, thưởng lần đầu, thưởng Vô tận theo độ khó,
  hệ số theo hạng). Ải mở lần lượt; Vô tận mở khi qua `rhythm_mat_05`.
- Save: `data["rhythm"] = {records: {khóa: {cleared, best_score, best_rank, best_combo, best_accuracy, plays}},
  favorites: [id bài]}`; khóa = id ải hoặc `endless:<bài>:<độ khó>` (`RhythmProgress`). Save cũ thiếu mục này được
  `SaveSchema.sanitize` thêm vào (không đổi version).
- Bản nốt (JSON): `{"format": 1, "song_id", "difficulty", "level", "bpm", "offset_sec", "duration_sec",
  "notes": [{"t", "lane": up|down|both, "kind": tap|hold|mash, "dur", "hits"}]}`. Nốt không chồng thời gian
  (game bỏ nốt chồng).
- Danh mục máy chủ `catalog.json`: `{"format": 1, "songs": [{id, title, artist, bpm, duration_sec, license, boss,
  audio: {file, sha256, bytes}, charts: {easy|normal|hard|boss: {file, sha256, bytes, level, notes}}}]}`.

## 5. Máy chủ và tool

- `server/music/songs.json` (trong git): danh sách bài. Nhạc, `charts/`, `catalog.json` sinh ra, không vào git.
- `python -X utf8 -I tools/rhythm/build_catalog.py`: tạo nhạc thử còn thiếu (`gen_test_music.py`), sinh bản nốt
  3 độ khó cho mỗi bài, ghi `catalog.json` (sha256). Bài boss: bản cố định `server/music/fixed/<bài>_boss.json`
  (trong git, sửa tay được; `--freeze-boss` để sinh lại).
- Thuật toán sinh nốt: STFT → spectral flux 3 dải (trầm < 150 Hz, giữa, cao > 2 kHz) → lưới phách (bpm cho sẵn hoặc
  tự đoán bằng tự tương quan, pha chọn theo tổng nhấn) → giữ các điểm lưới nhấn mạnh nhất theo tỉ lệ của độ khó →
  làn: trầm = dưới, giữa/cao = trên, cả hai cùng mạnh = cả hai (giới hạn tỉ lệ) → đoạn cao độ giữ ≥ 1.2 phách = giữ,
  ≥ 12 điểm 1/16 liên tiếp có nhấn = ấn liên tục → giãn cách tối thiểu. Không ngẫu nhiên.
- `server/gateway.mjs` (Node, cổng 7360): `/music/<file>` phát file; còn lại chuyển tới Nakama 7350 (kể cả
  websocket). `start_local.ps1` bật, `tunnel.ps1` trỏ đường hầm vào cổng này; game mặc định `http://127.0.0.1:7360`.
- Game: `RhythmLibrary` tải `catalog.json`, nhạc + bản nốt về `user://rhythm_cache/`, kiểm sha256; mất mạng dùng
  danh mục đã lưu. Nạp nhạc lúc chạy: `.wav`, `.ogg`, `.mp3`.

## 6. Thêm nhạc thật

1. Chép file nhạc (có quyền dùng thương mại) vào `server/music/`, thêm mục vào `songs.json` (bỏ `synth`; `bpm` nếu
   biết). File không phải WAV cần `ffmpeg` trong PATH để tool đọc.
2. Chạy `build_catalog.py`; xem số nốt / mức in ra; chỉnh `PROFILES` nếu cần.
3. Ghi giấy phép vào `docs/ASSET_LICENSES.md`. Muốn bản nốt cố định: chép từ `charts/` sang `fixed/` rồi sửa tay.

## 7. Còn thiếu / sau này

Quái ưu tiên 1 đã có frame riêng và được `RhythmStage` nối: Dơi Nốt, Sên Nhịp, Song Âm, Rắn Ngân, Trống Đá và boss
Nhật Thực. Còn thiếu: nền riêng, âm hiệu ứng khi đánh, chỉnh độ trễ (offset) trong Cài đặt, trình soạn nốt, giới hạn
số lượt / ngày (nếu owner muốn), tốc độ nốt tùy chọn.
