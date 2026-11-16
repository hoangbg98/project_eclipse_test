# Lộ trình triển khai

> Theo README mục 9. Mỗi task có ID `M{n}-{k}`. Trạng thái dùng đúng nghĩa ở
> README 11: `PENDING`, `IMPLEMENTED`, `TESTED`, `VERIFIED`, `BLOCKED`.

## Milestone 0 — Kiểm tra workspace, kiến trúc

| ID | Task | Trạng thái |
|---|---|---|
| M0-0 | Báo cáo kiểm tra workspace | TESTED |
| M0-1 | Repo git riêng, `.gitignore`, đổi tên `README.md` | IMPLEMENTED |
| M0-2 | 9 tài liệu trong `docs/` | IMPLEMENTED |

**Điều kiện xong:** tài liệu nền tồn tại; owner duyệt kiến trúc.

## Milestone 1 — Nền tảng

| ID | Task | Phụ thuộc |
|---|---|---|
| M1-0 | (Khuyến nghị) Chuyển dự án sang đường dẫn không dấu cách, vd `C:\Dev\PROJECT_ECLIPSE\` | — |
| M1-1 | `project.godot`: 1920×1080 ngang, stretch, nén ASTC/ETC2, renderer | M0 |
| M1-2 | Autoload `GameConfig`, `EventBus`, `SceneRouter` | M1-1 |
| M1-3 | Scene Boot → Title → Hub (tối thiểu, nút thật), nút Back/Esc | M1-2 |
| M1-4 | `InputRouter` + InputMap (bàn phím, tay cầm), khung điều khiển cảm ứng | M1-2 |
| M1-5 | Localization: `tr()` + file dịch nguồn | M1-3 |
| M1-6 | GdUnit4 (cần owner duyệt) + 1 test headless | M1-1 |
| M1-7 | Bộ lọc export, preset Windows + Android debug | M1-1 |
| M1-8 | Hướng dẫn owner cài JDK/SDK/export templates; build APK debug; owner chạy trên máy thật | M1-7 |

**Điều kiện xong:** project mở không lỗi, luồng scene và input chạy; bản Windows build và chạy được.

> **Hoãn (owner quyết định 2026-11-11):** build APK debug và thử trên điện thoại
> (phần Android của M1-8) để sau, **tập trung bản Windows trước**. Hướng dẫn đã sẵn
> trong `docs/ANDROID_SETUP.md`. Làm lại trước M2-4 (đo bộ nhớ texture Android) và
> chậm nhất trước M7 (điều khiển cảm ứng hoàn chỉnh). Mọi kiểm tra chỉ-máy-thật
> (cảm ứng, phím Back, dấu tiếng Việt trên Android) dồn về lúc đó.

## Milestone 2 — Người chơi và animation

| ID | Task |
|---|---|
| M2-1 | `AnimationSetBuilder`: manifest → `SpriteFrames`, placeholder khi `frames: 0`; test đếm PNG = `frames` |
| M2-2 | State machine + controller: chạy, nhảy (coyote 80–120 ms, nhảy cao thấp), rơi, đáp |
| M2-3 | Stage thử nghiệm (tile, va chạm, platform), camera follow + look-ahead |
| M2-4 | Đo bộ nhớ texture trên Android (owner) — **hoãn** cùng Android (2026-11-11); làm khi có frame thật và máy Android |

## Milestone 3 — Combat cơ bản

| ID | Task |
|---|---|
| M3-1 | `CombatRules`, `StatusDef` từ CHARACTER_SKILLS mục 0 + Q1–Q4 |
| M3-2 | Hitbox/Hurtbox theo track AnimationPlayer, một lần trúng mỗi `hit_id` |
| M3-3 | `DamageCalculator` + test |
| M3-4 | `ResourceComponent` (HP/EN/UG/lượt né), `CooldownController` (CDR trần 40%) + test |
| M3-5 | Bộ kỹ năng đầy đủ của `char_fire_01` (data-driven) |
| M3-6 | Quái thường: state machine, phát hiện, tấn công, khựng, Choáng (thanh SC) |
| M3-7 | Phản hồi đòn: hit-stop, flash, rung camera, số sát thương, combo counter |

## Milestone 4 — Đội 3 người

| ID | Task |
|---|---|
| M4-1 | `PartyManager`: một người trên sân, chờ chung 1.0s, khóa chuyển |
| M4-2 | `CharacterRuntime` cho dự bị: timer chạy, EN +1/s, UG 30% |
| M4-3 | `LinkTracker`: 6 điều kiện, cửa sổ 6.0s, SI-CD |
| M4-4 | Switch-in Thường / Liên kết / mặc định cho Kael, Lyra, Aether |
| M4-5 | 15 `ReactionDef` + `ReactionResolver` (ICD 5.0s, boss ×0.5) + test đủ 15 cặp |
| M4-6 | Kael, Lyra: di chuyển, đòn thường, né (Q5) |
| M4-7 | HUD icon dự bị: HP, vòng SI-CD, vòng sáng Liên kết (README 17.5) |

## Milestone 5 — RPG và chiêu mộ

| ID | Task | Ghi chú |
|---|---|---|
| M5-1 | `SaveService` đầy đủ: version, migration, backup, checksum + test | |
| M5-2 | Cấp nhân vật, EXP, tài nguyên | |
| M5-3 | Kho đồ, trang bị cơ bản | |
| M5-4 | Gacha: banner, pity, rate-up, bảo hiểm, lịch sử, test có seed | **BLOCKED: chờ tỉ lệ từ owner** |

## Milestone 6 — Thế giới và trận đấu

Màn đầu (3–5 phút, 2–3 đợt quái, checkpoint, parallax), boss 2 phase
(telegraph ≥ 0.4s, khóa camera), phần thưởng, màn kết quả.

## Milestone 7 — UI và hoàn thiện

Hub, chọn màn, chọn đội, nhân vật, trang bị, chiêu mộ, cài đặt, pause; âm
thanh; điều khiển cảm ứng hoàn chỉnh; safe area; credits/giấy phép.

## Milestone 8 — QA và chuẩn bị phát hành

Chạy toàn bộ ACCEPTANCE_TESTS trên Windows và Android, checklist tự chơi
(README 16), ghi lỗi tồn đọng. Đổi tên Aether/Noctis trước khi công khai.

## Milestone 9 — Trực tuyến (owner 2026-11-16)

Nạp tiền bằng chuyển khoản QR thủ công, QTV phát quà bằng tool máy chủ. Máy chủ Nakama + PostgreSQL;
giai đoạn thử chạy trên máy owner qua đường hầm trycloudflare.com. Hướng dẫn vận hành: `server/README.md`.

| ID | Task | Ghi chú |
|---|---|---|
| M9-1 | Máy chủ thử trên máy owner (portable), đường hầm trycloudflare, đăng nhập thiết bị, mã người chơi, ví máy chủ, tool phát quà `grant.ps1`, màn Trực tuyến | |
| M9-1b | Màn Đăng nhập sau Boot: tạo tài khoản (tên + email + mật khẩu), đăng nhập bằng tên / email, ghi nhớ phiên, chơi ngoại tuyến | |
| M9-2 | Gộp ví máy chủ với save: ngọc / vé do máy chủ giữ, gacha quay trên máy chủ | Cần owner chốt gói nạp |
| M9-3 | Cloud save: mỗi tài khoản một thế giới trên máy chủ, gửi sau mỗi lần lưu, chống ghi đè giữa hai thiết bị, mang save ngoại tuyến lên | Làm trước M9-2 (owner 2026-11-16) |
| M9-6 | Chat trong game: phòng Thế giới, nhắn riêng, bạn bè, chặn / báo cáo, lọc từ, cấm chat (QTV) | Định hướng owner: mỗi người một thế giới, nối nhau qua chat, không co-op. Đã làm (TESTED) |
| M9-7 | Quên mật khẩu / xác minh email | Cần dịch vụ gửi mail |
| M9-4 | Hộp thư quà trong game, lịch sử nạp cho người chơi | |
| M9-5 | Chuyển lên VPS (docker-compose), tên miền + Cloudflare Tunnel cố định, backup tự động | Trước khi nhận tiền thật |

## Milestone 10 — Chế độ nhịp điệu: ải nguyên liệu (owner 2026-11-16)

Thiết kế: `docs/design/RHYTHM_MODE.md`. Owner chọn: bản nốt tool tự sinh từ nhạc; Claude sinh nhạc thử; nhạc tải từ
máy chủ rồi lưu cache.

| ID | Task | Ghi chú |
|---|---|---|
| M10-1 | Lõi chấm (đúng 1 trong 3: trên / dưới / cả hai; ấn, giữ, ấn liên tục; HP, combo, fever, hạng), bản nốt, tiến độ + thưởng trong save, tool sinh nhạc thử + sinh bản nốt, cổng vào máy chủ phát `/music/`, tải + cache + sha256, màn Ải nguyên liệu (5 ải, boss cố định), màn chơi, danh sách bài Vô tận | |
| M10-2 | Hình riêng (quái, boss, nền, hiệu ứng), âm đánh trúng, chỉnh độ trễ âm thanh trong Cài đặt, tốc độ nốt | Cần owner duyệt hình |
| M10-3 | Nhạc thật (có giấy phép), chỉnh tay bản nốt boss; trình soạn nốt nếu cần | Cần nhạc của owner |

## Mốc owner nên mở Godot để thử

> Quy ước làm việc: **trước khi bắt đầu task nằm ở một mốc dưới đây, Claude nhắc
> owner** là task đó có thể xem/chơi thử trong Godot (F5), kèm cách thử và kết quả
> mong đợi. Test tự động không thay được việc xem bằng mắt và cảm giác điều khiển.

| Sau task | Thử gì trong Godot | Kết quả mong đợi |
|---|---|---|
| M1-3 (đã có) | F5: Boot → Title → Hub, Back/Esc | Luồng chạy, nút Tiếp tục bị xám |
| M1-5 (đã có) | Mặc định tiếng Việt; thử tiếng Anh: `Godot_v4.6.3-stable_win64.exe --path . -- --lang=en` | Chữ chuyển tiếng Anh |
| M2-3 | Stage thử nghiệm: chạy, nhảy, platform, camera; bật `force_visible` để thấy điều khiển cảm ứng | Cảm giác di chuyển, vùng chạm không chồng nhau |
| M3-5, M3-7 | Đánh quái bằng bộ kỹ năng Aether; hit-stop, rung camera, số sát thương | Cảm giác đòn đánh, kỹ năng khớp CHARACTER_SKILLS |
| M4-4, M4-7 | Đổi 3 nhân vật, switch-in Liên kết, HUD icon dự bị | Vòng SI-CD, vòng sáng Liên kết hiển thị đúng |
| M6 | Chơi hết màn đầu và boss 2 phase | Màn 3–5 phút, telegraph boss rõ |
| M7 | Duyệt toàn bộ UI, đổi ngôn ngữ trong Cài đặt | Hub, chọn màn/đội, trang bị, chiêu mộ |
| M10-1 | Bật máy chủ (`start_local.ps1`), F5 → Xuất kích → Ải nguyên liệu → N-1; đánh bằng D/F (trên), J/K (dưới) | Nốt khớp nhạc, cảm giác cửa sổ chấm, độ khó 5 ải |

Máy thật (không thay bằng Godot trên PC): M1-8 (APK, cảm ứng, phím Back, dấu tiếng
Việt), M2-4 (bộ nhớ texture Android), M8 (QA đầy đủ).
