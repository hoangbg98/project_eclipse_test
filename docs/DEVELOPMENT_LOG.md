# Nhật ký phát triển

> Định dạng theo README 11. Trạng thái: `IMPLEMENTED`, `TESTED`, `VERIFIED`,
> `BLOCKED`. `VERIFIED` chỉ dùng khi đã quan sát kết quả và có bằng chứng.

---

## 2026-11-11 — M0-0 Kiểm tra workspace

- **Milestone / task:** 0 / M0-0
- **Trạng thái:** TESTED
- **File tạo/sửa:** không
- **Đã chạy:**
  - Đọc toàn bộ `README` (mục 1–17), `docs/design/CHARACTER_SKILLS.md` (mục 0–8.11), 6 `frames_manifest.json`, `assets/characters/README.md`.
  - Đối chiếu tên animation trong manifest với thư mục `frames/` và bảng combo README 17.4.
  - `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --version`
- **Kết quả thật:**
  - Godot trả về `4.6.3.stable.official.7d41c59c4` (đúng phiên bản khóa). Godot không có trong PATH.
  - Không có `project.godot`, scene, script, data hay test.
  - 6 manifest khớp thư mục frame và bảng combo; mọi animation `frames: 0`, `frames_delivered: false`.
  - `CHARACTER_SKILLS.md` là bản export thật (không còn dòng STUB).
  - Repo git có sẵn nằm ở **thư mục người dùng** (`C:\Users\default...`), chưa có commit, theo dõi cả dữ liệu cá nhân.
- **Lỗi / cảnh báo:** không có lỗi. Rủi ro: repo git ở thư mục người dùng; đường dẫn có dấu cách và ngoặc.

## 2026-11-11 — M0-1 Repo riêng và đổi tên README

- **Milestone / task:** 0 / M0-1
- **Trạng thái:** IMPLEMENTED
- **File tạo/sửa:** `.git/` (repo mới, nhánh `main`), `.gitignore`, `.gitattributes`; đổi tên `README_PROJECT_ECLIPSE.md` → `README.md`.
- **Đã chạy:** `git init -b main` trong thư mục dự án; `git rev-parse --show-toplevel` trả về thư mục dự án.
- **Ghi chú:** repo ở thư mục người dùng **không bị sửa hay xóa**. Chưa có commit nào.

## 2026-11-11 — M0-2 Tài liệu nền

- **Milestone / task:** 0 / M0-2
- **Trạng thái:** IMPLEMENTED
- **File tạo:** `docs/PROJECT_OVERVIEW.md`, `ARCHITECTURE.md`, `SYSTEM_DEPENDENCIES.md`, `FOLDER_STRUCTURE.md`, `IMPLEMENTATION_ROADMAP.md`, `ACCEPTANCE_TESTS.md`, `DEVELOPMENT_LOG.md`, `ASSET_LICENSES.md`, `UI_UX_SPEC.md`.
- **Ghi chú:** tài liệu viết bằng tiếng Việt (ngôn ngữ của owner), thuật ngữ kỹ thuật giữ tiếng Anh.

### Quyết định đã được owner duyệt (2026-11-11)

| ID | Quyết định |
|---|---|
| — | Dùng tên tạm của nhân vật cho giai đoạn phát triển (đổi Aether, Noctis trước khi công khai) |
| W1 | Repo git riêng trong thư mục dự án; không đụng repo ở thư mục người dùng |
| W2 | Đổi tên README thành `README.md` |
| W3 | Khuyến nghị chuyển dự án sang đường dẫn không dấu cách trước M1 (chưa làm) |
| Q1 | Sát thương: `ATK × % × (1 + 0.06×(cấp−1)) × bonus × K/(K+DEF) × crit × giảm nhận`, K = 500 (config) |
| Q2 | Chí mạng mặc định 5% tỉ lệ, +50% sát thương (config) |
| Q3 | Debuff DEF khác tên cộng dồn, cùng tên làm mới thời gian; tổng giảm DEF tối đa 40% |
| Q4 | Thêm Mù cát, Khiên, Khiêu khích vào trạng thái dùng chung |
| Q5 | Slice: Aether đủ bộ; Kael, Lyra có switch-in + di chuyển + đòn thường + né |
| Q6 | `revive_enabled` mặc định tắt |

Các giá trị Q1–Q6 là **tuning trong data**, không sửa `CHARACTER_SKILLS.md`.

### Còn chặn / chờ

- Tỉ lệ gacha, pity, rate-up, bảo hiểm: chờ owner (chặn M5-4).
- GdUnit4: chờ owner duyệt plugin (M1-6).

### Ba ưu tiên tiếp theo

1. Owner xem tài liệu M0 và duyệt kiến trúc (điều kiện xong Milestone 0).
2. (Khuyến nghị) chuyển thư mục dự án sang `C:\Dev\PROJECT_ECLIPSE\`.
3. Bắt đầu M1: `project.godot`, autoload, luồng Boot → Title → Hub.

## 2026-11-11 — M1-0 Chuyển thư mục dự án (W3)

- **Milestone / task:** 1 / M1-0
- **Trạng thái:** VERIFIED
- **Thay đổi:** sao chép toàn bộ dự án (kể cả `.git/`) từ
  `C:\Users\default.LAPTOP-6QHN1193\Desktop\New folder (3)\PROJECT_ECLIPSE_kickoff\`
  sang `C:\Dev\PROJECT_ECLIPSE\`.
- **Đã chạy:** `cp -a`, `diff -r` giữa hai thư mục, đếm mục bằng `find`, `git status`, `git log`, `git fsck`.
- **Kết quả thật:** 451 mục ở cả hai nơi; `diff -r` chỉ báo khác `.git/index`
  (Git làm mới thông tin thời gian của file, bình thường); cây làm việc sạch;
  commit `84c6335` còn nguyên; `git fsck` không báo lỗi.
- **Còn lại:** không còn. Owner đã đồng ý xóa thư mục cũ (xem bên dưới).

### 2026-11-11 — M1-0 Xóa thư mục cũ

- **Trạng thái:** VERIFIED
- **Thay đổi:** owner xóa
  `C:\Users\default.LAPTOP-6QHN1193\Desktop\New folder (3)\PROJECT_ECLIPSE_kickoff\`.
  Nội dung bị xóa trước; thư mục rỗng ban đầu bị tiến trình khác giữ nên owner xóa nốt thủ công.
- **Kết quả thật:** đã kiểm tra, thư mục không còn trong `New folder (3)`. Bản duy nhất
  của dự án là `C:\Dev\PROJECT_ECLIPSE\`.

## 2026-11-11 — M1-1..M1-3 Nền tảng project, autoload, luồng Boot → Title → Hub

- **Milestone / task:** 1 / M1-1, M1-2, M1-3
- **Trạng thái:** TESTED (chạy headless; chưa mở bằng editor/cửa sổ thật)
- **File tạo:**
  - `project.godot` (1920×1080, stretch `canvas_items`, aspect `expand`, renderer `gl_compatibility`, bật nén ETC2/ASTC, `quit_on_go_back=false`).
  - Autoload: `scripts/core/game_config.gd`, `event_bus.gd`, `scene_router.gd`.
  - Scene: `scenes/main/boot.tscn`, `title.tscn`, `hub.tscn`; script `scripts/ui/boot.gd`, `title.gd`, `hub.gd`.
  - Test khói: `tests/smoke/m1_flow_check.gd`.
- **Đã chạy:**
  - `Godot_v4.6.3 --headless --path . --import`
  - `Godot_v4.6.3 --headless --path . --script res://tests/smoke/m1_flow_check.gd`
- **Kết quả thật:** 10/10 điều kiện đạt, mã thoát 0, không có lỗi script trong log. Luồng Boot → Title → Hub, Esc ở Hub quay về Title, Tiếp tục bị khóa vì chưa có save.
- **Quyết định tạm (đổi được):**
  - Renderer `gl_compatibility` cho cả Windows và Android (an toàn nhất cho 2D trên Android). Chốt lại khi đo máy thật ở M2-4.
  - Aspect `expand`: màn dài hơn 16:9 mở rộng khung nhìn, không viền đen (theo UI_UX_SPEC). UI cần neo theo góc/safe area ở M7.
- **Hạn chế đã biết:**
  - Chữ đang viết thẳng trong scene (tiếng Việt/Anh trộn), chưa qua `tr()`; chuyển ở M1-5.
  - Chưa quan sát bằng mắt: bố cục, kích thước nút, hiệu ứng mờ. Test chỉ kiểm tra logic luồng.
  - Phím Back Android chưa thử trên máy thật (chỉ Esc được mô phỏng).
  - Bấm nút khi đang chuyển cảnh (khoảng 0,2 s) bị bỏ qua, chưa xếp hàng.
- **Chưa làm trong M1:** M1-4 (InputRouter), M1-5 (dịch), M1-6 (GdUnit4, chờ owner duyệt), M1-7 (export), M1-8 (APK, owner chạy máy thật).

### Ba ưu tiên tiếp theo

1. Owner mở project bằng Godot 4.6.3 để xem Boot/Title/Hub bằng mắt.
2. M1-4: `InputRouter` và InputMap (bàn phím, tay cầm), khung điều khiển cảm ứng.
3. M1-5: chuyển chữ sang `tr()` và file dịch nguồn.

## 2026-11-11 — M1-4 InputRouter, InputMap, khung điều khiển cảm ứng

- **Milestone / task:** 1 / M1-4
- **Trạng thái:** TESTED (headless; chưa thử bằng phím/tay cầm/cảm ứng thật)
- **File tạo/sửa:**
  - `scripts/input/input_router.gd` (autoload `InputRouter`, đặt trước `SceneRouter`): đăng ký action bằng code, `get_move_x()`, bộ đệm input 120 ms (`consume_buffered`, `clear_buffer`).
  - `scripts/input/touch_button.gd`, `virtual_joystick.gd`, `touch_controls.gd`: joystick ảo trái, 6 nút phải, 2 nút đổi nhân vật; mỗi ngón theo dõi riêng (multitouch); chỉ hiện khi có màn hình cảm ứng hoặc `force_visible`.
  - `project.godot`: thêm autoload `InputRouter`. `SceneRouter` nay nghe action `ui_back` (trước là `ui_cancel`).
  - `tests/smoke/m1_input_check.gd` (mới); `m1_flow_check.gd` đổi sang `ui_back`.
- **Đã chạy:** `m1_flow_check.gd` và `m1_input_check.gd` bằng `Godot_v4.6.3 --headless --path . --script ...`
- **Kết quả thật:** cả hai mã thoát 0, 0 lỗi (flow 10 điều kiện; input 32 điều kiện: 12 action có phím, bộ đệm nhấn sớm/một lần/hết hạn, 2 ngón độc lập, joystick -1..1 có vùng chết, nút ≥ 128 px, các vùng chạm không chồng nhau, ẩn lớp thì nhả nút).
- **Bản đồ phím tạm (đổi được):**

| Action | Bàn phím | Tay cầm |
|---|---|---|
| move_left / right | A, D, ←, → | cần trái, D-pad trái/phải |
| jump | Space, K | A |
| attack | J | X |
| dodge | L, Shift | B |
| skill | U | Y |
| weapon | I | LB |
| ultimate | O | RB |
| switch_1 / 2 | Q, 1 / E, 2 | D-pad lên / xuống |
| pause | P | Start |
| ui_back | Esc | Back/Select |

- **Hạn chế đã biết:**
  - Action đăng ký bằng code nên chưa thấy/sửa được trong tab Input Map của editor.
  - Chưa quan sát bằng mắt hình dạng/vị trí điều khiển cảm ứng; chưa tính safe area/tai thỏ (M7).
  - Nhấn "pause" bằng Esc chưa nối vào gameplay (chưa có scene trận); hiện Esc = `ui_back`.
  - Cảm ứng thật, tay cầm thật, phím Back Android chưa thử trên thiết bị (M1-8).
  - Bố cục nút phải là sắp xếp tạm, owner chỉnh sau khi thử máy thật.

## 2026-11-11 — M1-5 Localization (`tr()` + file dịch nguồn)

- **Milestone / task:** 1 / M1-5
- **Trạng thái:** TESTED (headless; chưa xem bằng mắt trong cửa sổ game)
- **File tạo/sửa:**
  - `localization/vi.po`, `localization/en.po` (10 khóa: Title và Hub); đăng ký trong `project.godot` mục `[internationalization]`, ngôn ngữ dự phòng `vi`.
  - `scenes/main/title.tscn`, `hub.tscn`: chữ nút/nhãn đổi sang khóa `UPPER_SNAKE` (Godot tự dịch `Button`/`Label`). `scripts/ui/hub.gd` dùng `tr()` cho nội dung tab.
  - `scripts/core/game_config.gd`: thêm `LANGUAGES` và `set_language(code)` (màn Cài đặt M7 sẽ gọi).
  - `tests/smoke/m1_i18n_check.gd` (mới).
- **Đã chạy:** cả 3 test khói (`m1_flow_check`, `m1_input_check`, `m1_i18n_check`) bằng `Godot_v4.6.3 --headless --path . --script ...`
- **Kết quả thật:** cả ba mã thoát 0, 0 lỗi. Test i18n kiểm tra: vi và en cùng tập khóa; mọi khóa dịch ra khác chính nó ở cả hai ngôn ngữ; ngôn ngữ lạ bị từ chối; mọi chữ trong `scenes/main` là khóa có trong file dịch (trừ `PROJECT ECLIPSE` và `v0`); Hub ở `en` hiện "Home | (work in progress)".
- **Quyết định tạm (đổi được):**
  - Dùng `.po` thay vì `.csv`: Godot nạp thẳng, không cần bước import, dễ cho người dịch.
  - Ngôn ngữ dự phòng là tiếng Việt (ngôn ngữ của owner). Máy có locale `en` sẽ nhận tiếng Anh; locale khác nhận tiếng Việt.
- **Hạn chế đã biết:**
  - Tên thương hiệu `PROJECT ECLIPSE` và nhãn phím cảm ứng (J, U, ↑…) không dịch (cố ý).
  - Chưa có font bảo đảm hiển thị đủ dấu tiếng Việt trên mọi máy Android; dùng font mặc định của Godot, cần kiểm tra trên máy thật (M1-8).
  - Chưa có lựa chọn ngôn ngữ trong game (M7); hiện theo locale hệ thống.
  - Test chỉ quét `scenes/main`; khi thêm thư mục scene mới phải thêm vào `SCENE_DIRS` của test.
