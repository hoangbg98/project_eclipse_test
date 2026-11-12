# Kiểm thử nghiệm thu

> Theo README mục 10. **Auto** = test GdUnit4 / test khói chạy headless. **Thủ công** =
> Claude chạy game và quan sát. **Owner** = cần máy Android thật hoặc kiểm
> tra bằng mắt; Claude không tự đánh dấu, owner cung cấp bằng chứng.
>
> Trạng thái: `NOT RUN`, `PASS`, `FAIL`, `BLOCKED`. Không đánh `PASS` nếu chưa
> có bằng chứng (lệnh, kết quả, ngày).

## Lần chạy gần nhất: 2026-11-12 (Milestone 8, commit sau `db7c9ec`)

- Lệnh: `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1` → **GdUnit4 402/402 đạt, 5 test khói đạt, mã thoát 0**.
- `godot --headless --path . --editor --quit` → mã thoát 0, không có dòng ERROR / SCRIPT / WARNING.
- `godot --headless --path . --export-debug "Windows Desktop" build/windows/ProjectEclipse.exe` → mã thoát 0; `ProjectEclipse.console.exe --headless` khởi động không có lỗi script.
- **Claude không chơi game bằng tay.** "Thủ công" ở bảng dưới được thay bằng test khói điều khiển bằng input giả lập
  (`tests/smoke/m8_playthrough_check.gd`) và 6 ảnh chụp màn hình Claude đã xem (`tools/screenshot_*.gd`).
  Cảm giác điều khiển, độ khó, thời lượng màn và việc "đọc được bằng mắt" vẫn cần owner xác nhận: các dòng đó để `PASS (auto)` kèm ghi chú, không phải `VERIFIED`.

## Core

| ID | Tiêu chí | Cách kiểm | Trạng thái | Bằng chứng |
|---|---|---|---|---|
| AT-CORE-01 | Project mở trong Godot 4.6.3 không có lỗi chặn | Thủ công: editor headless `--quit` | PASS | Mã thoát 0, log không có ERROR (2026-11-12) |
| AT-CORE-02 | Scene chính nạp và chuyển cảnh đúng | Auto | PASS | `m1_flow_check`, `m8_playthrough_check`: Boot → Title → Hub → Màn 1 → Hub → Title |
| AT-CORE-03 | Input chạy trên nền tảng đích | Auto (PC) / Owner (Android) | PASS (PC, auto) · NOT RUN (Android) | `m1_input_check`; `m8`: chạy, nhảy, đánh, kỹ năng, đổi người bằng action. Bàn phím / tay cầm thật: owner |

## Người chơi và combat

| ID | Tiêu chí | Cách kiểm | Trạng thái | Bằng chứng |
|---|---|---|---|---|
| AT-PLY-01 | Di chuyển, nhảy, rơi, đáp nhất quán | Auto + Owner | PASS (auto) | `tests/unit/player/*`, `m2_stage_check`. Cảm giác điều khiển: owner đã thử M2-3 ("ổn") |
| AT-PLY-02 | Nút tấn công kích hoạt đúng animation và hitbox | Auto + Owner | PASS (auto) | `test_aether_basic`, `test_aether_skills`, `test_aether_air_hold`, `test_kael_lyra`. Animation thật chưa có (placeholder) |
| AT-CMB-01 | Sát thương áp đúng một lần mỗi lần trúng hợp lệ | Auto | PASS | `test_hitbox_hurtbox` |
| AT-CMB-02 | Công thức sát thương khớp CombatRules | Auto | PASS | `test_damage_calculator` |
| AT-CMB-03 | HP, EN, UG, CD cập nhật đúng; CDR không vượt 40% | Auto | PASS | `test_resources_cooldowns` |
| AT-CMB-04 | Rút CD riêng không vượt trần mỗi chu kỳ | Auto | PASS | `test_resources_cooldowns`, `test_aether_skills`, `test_switch_in` (SI-CD −3 s tối đa) |
| AT-CMB-05 | Hành động không hợp lệ bị từ chối an toàn | Auto | PASS | `test_aether_skills`, `test_resources_cooldowns`, `test_touch_audio` (nút mờ khi thiếu EN) |
| AT-CMB-06 | Trạng thái: thời lượng, làm mới, tick, kháng Choáng 8s | Auto | PASS | `test_status_controller`, `test_enemy_slime` |

## Đội

| ID | Tiêu chí | Cách kiểm | Trạng thái | Bằng chứng |
|---|---|---|---|---|
| AT-PTY-01 | Cấu hình được 3 slot | Auto | PASS | `test_hub_panels` (chọn đội 1–3, lưu), `test_progression_inventory` |
| AT-PTY-02 | Chỉ một người trên sân; dự bị không hành động, không nhận input | Auto | PASS | `test_party_manager` (dự bị nằm ngoài cây scene) |
| AT-PTY-03 | Icon dự bị hiển thị HP và vòng SI-CD | Auto + ảnh chụp | PASS (auto) | `test_battle_hud`; ảnh `build/screenshots/test_stage.png` Claude đã xem. Owner chưa xem trong game |
| AT-PTY-04 | Vòng sáng chỉ hiện khi điều kiện trong 6.0s **và** SI-CD đã hồi | Auto | PASS | `test_link_tracker`, `test_battle_hud` |
| AT-PTY-05 | Chuyển Liên kết sinh đúng phản ứng cho cả 15 cặp; ICD 5.0s | Auto | PASS (một phần) | `test_reactions`: đủ 15 cặp trong resolver, ICD 5.0 s. Qua chuyển nhân vật thật mới test 3 cặp của Aether / Kael / Lyra (3 nhân vật kia ngoài slice) |
| AT-PTY-06 | Bảng phản ứng có đủ 15 cặp, không thiếu, không trùng | Auto | PASS | `test_reactions::test_all_15_pairs_exist_once_and_valid` |
| AT-PTY-07 | Chuyển Thường không sinh phản ứng; switch-in trượt không sinh phản ứng | Auto | PASS | `test_reactions` |
| AT-PTY-08 | Khóa chuyển trong tuyệt kỹ chuỗi đòn và với nhân vật đã gục; chờ chung 1.0s | Auto | PASS | `test_party_manager` |
| AT-PTY-09 | Dự bị: EN +1/s, nhận 30% UG; timer cá nhân vẫn chạy | Auto | PASS | `test_party_manager` |

## Kẻ địch và boss

| ID | Tiêu chí | Cách kiểm | Trạng thái | Bằng chứng |
|---|---|---|---|---|
| AT-ENM-01 | Quái phát hiện và giao chiến theo cấu hình AI | Auto | PASS (auto) | `test_enemy_slime`; `m8`: quái đánh trúng nhân vật |
| AT-ENM-02 | Sát thương, hạ gục, phần thưởng của quái | Auto | PASS (một phần) | Sát thương và hạ gục: `test_enemy_slime`. Thưởng trao theo màn, không theo từng quái (`test_stage_controller`) |
| AT-BOS-01 | Boss chuyển phase đúng điều kiện | Auto | PASS | `test_boss`, `m8` |
| AT-BOS-02 | Telegraph boss ≥ 0.4s, đọc được ở cỡ điện thoại | Auto + Owner | PASS (≥ 0.4 s, auto) · NOT RUN (đọc được trên điện thoại) | `test_boss`: mọi đòn ≥ 400 ms, đo thật ≥ 24 khung. Ảnh `stage_01_boss.png` có vùng báo hiệu. Owner xem trên máy thật |

## Tiến trình và chiêu mộ

| ID | Tiêu chí | Cách kiểm | Trạng thái | Bằng chứng |
|---|---|---|---|---|
| AT-PRG-01 | Lên cấp cập nhật chỉ số đúng | Auto | PASS | `test_progression_inventory` |
| AT-PRG-02 | Thay đổi kho đồ và trang bị được lưu | Auto | PASS | `test_progression_inventory`, `test_hub_panels` |
| AT-GCH-01 | Chiêu mộ trừ đúng tài nguyên | Auto | PASS (logic) · BLOCKED (banner thật) | `test_gacha_service` với banner dựng trong test. Chưa có `data/banners/*` vì chờ tỉ lệ từ owner |
| AT-GCH-02 | Tỉ lệ, pity, rate-up, bảo hiểm qua test có seed | Auto | PASS (logic) · BLOCKED (banner thật) | Như trên |
| AT-GCH-03 | Lịch sử chiêu mộ lưu và nạp đúng | Auto | PASS | `test_gacha_service`, `test_hub_panels` |
| AT-GCH-04 | Bảng tỉ lệ hiển thị sinh từ cùng config với logic quay | Auto | PASS | `test_gacha_service::test_rates_table_*`, `test_hub_panels` |

## Save và nền tảng

| ID | Tiêu chí | Cách kiểm | Trạng thái | Bằng chứng |
|---|---|---|---|---|
| AT-SAV-01 | Save/load giữ nguyên state cần thiết | Auto | PASS | `test_save_store`, `m8` (đọc lại từ đĩa sau khi qua màn) |
| AT-SAV-02 | Save hỏng hoặc cũ được xử lý không crash | Auto | PASS | `test_save_store` (backup, checksum, migration v1 → v2, 9 kiểu file rác) |
| AT-PLT-01 | Điều khiển Windows (bàn phím, tay cầm) | Owner | NOT RUN | Action đã gán phím và tay cầm (`m1_input_check`); cần owner cầm thử, nhất là tay cầm |
| AT-PLT-02 | Điều khiển cảm ứng trên máy Android thật | Owner | NOT RUN | Android hoãn (quyết định owner 2026-11-11) |
| AT-PLT-03 | UI dùng được ở 16:9 → 21:9, tôn trọng safe area | Thủ công + Owner | NOT RUN | Có `UiKit.safe_margins` (test) và HUD trận đã áp; chưa chụp / thử ở 21:9, menu chưa áp lề an toàn |
| AT-ANM-01 | Số PNG trong mỗi thư mục frame = `frames` trong manifest | Auto | PASS | `test_animation_set_builder::test_real_frame_counts_match_folders` (hiện mọi animation `frames: 0`) |

## Checklist tự chơi (README 16)

Start → hub → chọn màn → chọn đội → chiến đấu (di chuyển, nhảy, đánh, kỹ năng,
chuyển người, nhận sát thương, hạ quái) → boss 2 phase → kết quả + thưởng →
chiêu mộ → lưu → thoát → mở lại → tiếp tục với tiến trình còn nguyên.

Trạng thái: **PASS (auto, trừ chiêu mộ)** — `tests/smoke/m8_playthrough_check.gd`, 38/38 bước, 2026-11-12.
Bước chiêu mộ BLOCKED (chưa có banner). Test hạ phần lớn quái bằng sát thương trực tiếp sau khi xác nhận
đòn đánh từ input có tác dụng, nên **chưa ai chơi hết màn bằng tay**: owner chơi thử là bước còn thiếu.

Tiêu chí của các tính năng hoãn (README 2.3) không chặn bản đầu.
