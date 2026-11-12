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

## 2026-11-11 — M1-7 Bộ lọc export, preset Windows + Android debug

- **Milestone / task:** 1 / M1-7
- **Trạng thái:** TESTED (đóng gói PCK; chưa xuất được `.exe`/`.apk` vì máy chưa cài export templates)
- **File tạo:** `export_presets.cfg` với 3 preset:

| Preset | Đầu ra | Loại khỏi gói |
|---|---|---|
| Windows Desktop (dev) | `build/windows/ProjectEclipse.exe` | `docs/*`, `tests/*`, `addons/gdUnit4/*` |
| Windows Release | `build/windows-release/ProjectEclipse.exe` | như trên + `*placeholder_*` |
| Android Debug | `build/android/ProjectEclipse-debug.apk` | `docs/*`, `tests/*`, `addons/gdUnit4/*` |

- **Đã chạy:**
  - `Godot_v4.6.3 --headless --path . --export-pack "<preset>" <file>.pck` cho cả 3 preset (có tạm một file `assets/placeholders/placeholder_probe.png` để thử lọc, đã xóa sau đó).
  - Nạp từng PCK vào một project trống bằng `ProjectSettings.load_resource_pack` rồi liệt kê file thật trong gói.
- **Kết quả thật:** cả 3 lệnh mã thoát 0. Không gói nào chứa file trong `docs/` hay `tests/`. Hai preset debug có file placeholder thử; preset Release không có. Gói chứa scene, script đã biên dịch, `vi.po`/`en.po`, 6 `frames_manifest.json`.
- **Quyết định tạm (đổi được):**
  - Bản dev/debug **giữ** `placeholder_*` vì game cần chúng khi animation còn `frames: 0`; chỉ bản Release loại bỏ (theo FOLDER_STRUCTURE "Loại khỏi export").
  - Android: chỉ `arm64-v8a`, không dùng Gradle build, chế độ toàn màn hình, tên gói tạm `com.projecteclipse.dev` (**owner chốt tên gói thật trước khi phát hành**; đổi sau khi đã cài lên máy sẽ thành app khác).
  - Windows: `application/modify_resources=false` để không cần công cụ rcedit; icon `.exe` làm sau.
- **Hạn chế đã biết:**
  - Chưa cài export templates 4.6.3 (thư mục `%APPDATA%\Godot\export_templates\4.6.3.stable` không có) nên chưa xuất được `.exe`/`.apk`; cài ở M1-8.
  - Cache UID trong gói (`.godot/uid_cache.bin`) vẫn ghi tên đường dẫn của `docs/`, `tests/` dưới dạng chuỗi, nhưng không có file nội dung. Chấp nhận được ở giai đoạn này.
  - Android Debug cần keystore debug và JDK/SDK (M1-8).

## 2026-11-11 — M1-8 Hướng dẫn cài đặt xuất bản (phần 1)

- **Milestone / task:** 1 / M1-8
- **Trạng thái:** BLOCKED — chờ owner cài export templates, JDK 17, Android SDK và cắm điện thoại
- **File tạo:**
  - `docs/ANDROID_SETUP.md`: 6 bước (templates, JDK 17, Android SDK, điện thoại, build/cài, bảng thử 9 mục trên máy thật) và mẫu báo kết quả.
  - `tools/check_build_env.ps1`: script chỉ đọc, báo `[OK]`/`[THIẾU]` cho Godot, templates, JDK, SDK, keystore, điện thoại. Lưu UTF-8 **có BOM** (PowerShell 5.1 cần BOM để đọc tiếng Việt; nếu editor nào lưu lại mất BOM thì chữ sẽ lỗi).
- **Đã chạy:** `powershell -ExecutionPolicy Bypass -File tools\check_build_env.ps1`
- **Kết quả thật (tình trạng máy):**
  - OK: Godot 4.6.3, keystore debug (`%APPDATA%\Godot\keystores\debug.keystore`).
  - THIẾU: export templates 4.6.3 (Windows và Android); Android SDK (Editor trỏ tới `%LOCALAPPDATA%\Android\Sdk` nhưng thư mục không tồn tại), không có platform-tools, build-tools, platforms.
  - JDK: Editor đang trỏ JDK 25 (Liberica); tài liệu Godot khuyến nghị JDK 17, script đánh dấu THIẾU cho tới khi đổi.
  - Có adb cũ 30.0.3 ở `C:\Windows\adb.exe`, có thể xung đột với adb của SDK.
- **Chưa làm:** build `.exe`/`.apk` và thử trên điện thoại (cần các bước trên).
- **Ghi chú:** số phiên bản SDK trong hướng dẫn (API 35, Build-Tools 35.0.1) theo tài liệu Godot 4.x, chưa đối chiếu được trên máy; nếu hộp thoại Export báo khác thì làm theo hộp thoại.

## 2026-11-11 — M1-8 Build Windows debug (phần 2)

- **Milestone / task:** 1 / M1-8
- **Trạng thái:** Windows: TESTED. Android: vẫn BLOCKED (chờ JDK 17, Android SDK, điện thoại).
- **Owner đã làm:** import project vào Project Manager, mở editor; cài export templates 4.6.3 bằng **Install from File** (tải `.tpz` thủ công vì Godot báo "Can't connect to the mirror", editor đang ở chế độ Offline).
- **Editor tự sửa `project.godot`:** định dạng lại và bỏ `window/handheld/orientation=0` (0 = ngang là mặc định nên không đổi hành vi). Đã commit nguyên trạng.
- **Đã chạy:**
  - `Godot_v4.6.3 --headless --path . --export-debug "Windows Desktop" build/windows/ProjectEclipse.exe`
  - `build/windows/ProjectEclipse.console.exe --headless --verbose --quit-after 2000`
- **Kết quả thật:**
  - Xuất thành công, mã thoát 0: `ProjectEclipse.exe` (~96 MB, PCK nhúng) và `ProjectEclipse.console.exe`. Cảnh báo duy nhất: "Unable to open Android 'build-tools' directory" (do chưa có SDK, không ảnh hưởng Windows).
  - Chạy bản build: nạp `vi.po`, `en.po`, 4 autoload, Boot rồi Title; không có dòng lỗi/cảnh báo; mã thoát 0.
- **Chưa kiểm chứng:** chạy có cửa sổ và thao tác bằng chuột/bàn phím trên bản `.exe` (owner mở `build/windows/ProjectEclipse.exe`).

## 2026-11-11 — Quyết định: hoãn Android, tập trung Windows

- **Owner quyết định:** build APK debug và thử trên điện thoại để sau; ưu tiên bản Windows.
- **Ảnh hưởng:**
  - M1 coi là xong khi bản Windows build và chạy được (đã đạt, xem M1-8 phần 2). Phần Android của M1-8 chuyển sang **PENDING (hoãn)**.
  - Vẫn giữ: preset Android Debug, nén ETC2/ASTC, khung điều khiển cảm ứng, xử lý phím Back, để không phải làm lại.
  - Phải làm lại phần Android trước M2-4 (đo bộ nhớ texture) và chậm nhất trước M7. Các kiểm tra chỉ làm được trên máy thật dồn về lúc đó.
  - Còn mở của M1: M1-6 (GdUnit4, chờ owner duyệt plugin).

## 2026-11-11 — M1-6 GdUnit4 + test headless

- **Milestone / task:** 1 / M1-6
- **Trạng thái:** TESTED
- **Owner duyệt:** cài GdUnit4 ("Làm M1-6").
- **Plugin:** GdUnit4 **6.2.3**, MIT, từ kho chính thức `godot-gdunit-labs/gdUnit4` (zip mã nguồn của tag `v6.2.3`, 475 KB, SHA-256 ghi trong ASSET_LICENSES). README của bản này ghi tương thích Godot 4.6.3. Chỉ chép `addons/gdUnit4/` (272 file, 1,8 MB: GDScript, scene, ảnh, mẫu báo cáo HTML; không có file thực thi). Đã đọc `runtest.cmd` và `bin/GdUnitCmdTool.gd` trước khi dùng.
- **File tạo/sửa:**
  - `addons/gdUnit4/` (plugin); `project.godot` thêm `[editor_plugins]` bật plugin.
  - `tests/unit/core/test_game_config.gd` (6 test), `tests/unit/input/test_input_router.gd` (7 test).
  - `tools/run_tests.ps1`: chạy GdUnit4 + mọi test khói, in bảng ĐẠT/LỖI, mã thoát 0 nếu tất cả đạt (UTF-8 có BOM).
  - `.gitignore` thêm `/reports/` (báo cáo HTML/XML của GdUnit4).
  - `docs/ASSET_LICENSES.md`: cập nhật dòng GdUnit4.
- **Đã chạy:**
  - `Godot --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode -rd reports`
  - Một test cố tình sai (`1 + 1 == 3`) trong thư mục tạm, rồi xóa.
  - `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1`
  - `--export-pack` cho cả 3 preset, nạp vào project trống và đếm file.
- **Kết quả thật:**
  - GdUnit4: 13/13 đạt, 0 lỗi, 0 orphan, mã thoát 0.
  - Test cố tình sai: báo FAILED, mã thoát 100 (runner bắt được lỗi thật).
  - `run_tests.ps1`: GdUnit4 + 3 test khói đều ĐẠT, mã thoát 0.
  - Cả 3 gói export: 0 file trong `addons/`, `tests/`, `docs/`; 20 file trong `scripts/`.
- **Hạn chế đã biết:**
  - GdUnit4 cảnh báo: chạy headless thì InputEvent không truyền qua engine, nên test tương tác UI bằng sự kiện phải chạy có cửa sổ. Test khói hiện dùng `push_input`/`action_press` nên vẫn chạy được headless.
  - Test khói (`tests/smoke/`) chưa chuyển sang GdUnit4; giữ nguyên vì đang chạy tốt. Test mới từ M2 viết bằng GdUnit4.
  - Plugin bật trong editor: lần mở editor tới sẽ có tab GdUnit; chưa kiểm tra bằng mắt.

### Milestone 1: tổng kết

| Task | Trạng thái |
|---|---|
| M1-0 Chuyển thư mục | VERIFIED |
| M1-1 project.godot | TESTED |
| M1-2 Autoload | TESTED |
| M1-3 Boot → Title → Hub | TESTED (owner đã mở editor) |
| M1-4 InputRouter + cảm ứng | TESTED (headless) |
| M1-5 Localization | TESTED |
| M1-6 GdUnit4 | TESTED |
| M1-7 Export presets | TESTED (PCK) |
| M1-8 Windows build | TESTED; **Android hoãn** theo quyết định owner |

Điều kiện xong M1 (bản đã sửa): project mở không lỗi, luồng scene và input chạy, bản Windows build và chạy được — **đạt**, chờ owner xác nhận bằng mắt.

## 2026-11-11 — Thêm pixelfx (tư liệu VFX) và thiết lập Codex

- **Trạng thái:** IMPLEMENTED (render thử được; chưa có sprite sheet nào trong game)
- **Owner yêu cầu:** đưa kho https://github.com/patch-gg/pixelfx vào dự án làm tư liệu VFX; cho Codex (đã cài trên máy) làm việc trong dự án.
- **pixelfx:**
  - MIT. Thư viện JavaScript (244 hiệu ứng là code), xuất sprite sheet PNG + JSON kiểu Aseprite cho Godot bằng Node (`v26.13.0` có sẵn trên máy).
  - Chép vào `tools/pixelfx/` + `.gdignore`; nguồn, SHA-256 và phạm vi chép ở `tools/pixelfx/UPSTREAM.md`. Không chép `gallery/` (font không thuộc MIT), GIF minh họa, `.github/`, `.claude-plugin/`.
  - Đã đọc trước khi chạy: `tools/lib/fxlib.mjs` chỉ gọi `ffmpeg` (tùy chọn, cho GIF/MP4); `tools/serve.mjs` chỉ mở gallery ở localhost. Không gọi mạng khi render.
  - Skill pixelfx cài ở `.claude/skills/pixelfx/` (Claude) và `.agents/skills/pixelfx/` (Codex), nguyên văn upstream.
  - `docs/ASSET_LICENSES.md`: thêm dòng pixelfx và bảng 1.1 cho từng sprite sheet sẽ dùng.
- **Codex:** owner chọn "Codex làm việc trong dự án". Tạo `AGENTS.md` (quy tắc, lệnh test/build, quy ước, asset, quyết định đang hiệu lực, cách làm chung nhiều agent); `CLAUDE.md` chỉ gồm `@AGENTS.md` để hai agent dùng chung một bộ quy tắc.
- **Đã chạy:**
  - `node tools/render.mjs fire/fire-ring --sheet` (trong `tools/pixelfx/`): 118 frame, 224×128, 30 fps, pivot (112, 92); đã xem `contact.png`, hiệu ứng hiển thị đúng.
  - `tools/run_tests.ps1`: GdUnit4 + 3 test khói đều ĐẠT, mã thoát 0 (thư mục mới không ảnh hưởng project).
- **Hạn chế đã biết:**
  - Hiệu ứng pixelfx là pixel art độ phân giải thấp; nhân vật cao ~256 px trên canvas 384. Cần phóng to (nearest) và owner xem phong cách có hợp nét vẽ nhân vật không (OD-2).
  - Chưa kiểm tra Codex có nhận skill trong `.agents/skills/` hay không (owner mở dự án trong Codex để xem).
  - Chưa có importer Godot cho JSON của pixelfx; làm khi cần VFX (M3-7).

## 2026-11-11 — M2-1 AnimationSetBuilder

- **Milestone / task:** 2 / M2-1
- **Trạng thái:** TESTED
- **File tạo/sửa:**
  - `scripts/characters/animation_set_builder.gd` (`class_name AnimationSetBuilder`): đọc `frames_manifest.json` → `SpriteFrames` (fps, loop, số frame từ manifest); `frames: 0` hoặc thiếu file → placeholder và ghi lỗi, không crash; `validate_frame_counts()` so số PNG với `frames` và phát hiện đánh số hở; `sprite_offset()` đặt chân (192, 336) đúng gốc node → `(0, -144)`.
  - `assets/placeholders/placeholder_character_384.png` + `tools/gen_placeholders.gd` (script sinh ảnh, chạy tay).
  - `tests/unit/characters/test_animation_set_builder.gd` (13 test).
  - `export_presets.cfg`: cả 3 preset loại thêm `tools/*` (thư mục này giờ có `.gd`).
  - `docs/ASSET_LICENSES.md`: ghi placeholder.
- **Đã chạy:** `tools/gen_placeholders.gd` (đã xem ảnh: thân đứng đúng vạch chân, mũi hướng phải); `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 26/26 đạt (13 mới), 3 test khói đạt, mã thoát 0. Test kiểm tra: 6 manifest thật có đủ animation theo README 17.4 (số đòn thường/trên không từng nhân vật), số PNG khớp `frames` (hiện tất cả 0), fps/loop đúng manifest, animation chưa giao dùng placeholder; với dữ liệu giả trong `user://`: frame nạp đúng thứ tự, thiếu frame → placeholder + lỗi, đánh số hở bị bắt, thiếu thư mục/manifest/JSON hỏng/giá trị âm đều báo lỗi.
- **Hạn chế đã biết:**
  - Chưa có scene nào dùng builder; nhân vật lên màn ở M2-2/M2-3.
  - Bản **Windows Release** loại `placeholder_*`, nên nếu còn animation `frames: 0` thì animation đó rỗng (không hiện gì). Chỉ build Release khi đã đủ hình.
  - Chưa gom frame thành atlas, chưa chọn chế độ lọc/nén cho ảnh nhân vật; quyết khi có frame thật và đo bộ nhớ (M2-4).
  - `validate_frame_counts()` chỉ chạy được khi phát triển (bản export không còn PNG gốc).

## 2026-11-11 — M2-2 State machine + controller di chuyển

- **Milestone / task:** 2 / M2-2
- **Trạng thái:** TESTED (headless, input giả; chưa điều khiển bằng tay)
- **File tạo:**
  - `scripts/player/movement_config.gd` (`MovementConfig`) + `data/config/movement_default.tres`: tốc độ chạy, gia tốc đất/không, độ cao nhảy + thời gian lên đỉnh (trọng lực và vận tốc nhảy **suy ra**), hệ số rơi, hệ số cắt nhảy, coyote 0.10 s, bộ đệm nhảy 0.12 s, thời gian Land.
  - `scripts/player/player_intent.gd` (`PlayerIntent`): input của một tick (move_x, giữ nhảy, bộ đệm nhảy theo thời gian vật lý); đọc từ action của InputRouter.
  - `scripts/player/state_machine.gd` (`StateMachine`), `states/player_state.gd`, `states/movement_states.gd`: `idle`, `run`, `jump_up`, `fall`, `land` (tên trùng animation).
  - `scripts/player/player_controller.gd` (`PlayerController`, CharacterBody2D) + `scenes/player/player_character.tscn`: gốc node ở chân; capsule 80×240; dựng SpriteFrames bằng AnimationSetBuilder; lật hướng bằng `flip_h`; placeholder tô màu nguyên tố; signal `state_changed`, `jumped`, `landed`.
  - `tests/unit/player/test_player_movement.gd` (12 test).
- **Đã chạy:** `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 38/38 đạt (12 mới), 3 test khói đạt, mã thoát 0. Test: rơi → đáp → đứng đúng mặt sàn (±2 px); chạy đạt đúng `run_speed`, analog 0.5 → nửa tốc độ, đổi hướng lật sprite, thả nút dừng và giữ hướng; nhảy giữ nút đạt `jump_height` ±4 %; nhả sau 3 tick cao < 50 %; không nhảy đôi trên không; coyote: nhảy được ở nửa cửa sổ, bị từ chối khi quá cửa sổ; bộ đệm: nhấn ~70 ms trước khi chạm đất thì nhảy ngay khi chạm, nhấn quá sớm thì bỏ.
- **Lỗi tìm thấy và sửa:** lần chạy đầu đỉnh nhảy chỉ 306 px thay vì 320 (sai số tích phân, mất khoảng v·dt/2). Sửa controller: cộng trọng lực hai nửa quanh `move_and_slide` (tích phân điểm giữa); nay đúng độ cao cấu hình.
- **Hạn chế đã biết:**
  - Chưa có màn chơi nào đặt nhân vật; chưa thử cảm giác bằng tay (M2-3).
  - Bộ đệm nhảy của controller tính theo thời gian vật lý (`PlayerIntent`), tách khỏi bộ đệm thời gian thật của `InputRouter`; đòn đánh/né sau này dùng cùng cách.
  - Chưa có platform một chiều, platform di chuyển, dốc; làm cùng stage ở M2-3 nếu cần.
  - Mọi nhân vật dùng chung `movement_default.tres`; cấu hình riêng từng nhân vật làm khi có `CharacterDef`.

## 2026-11-11 — M2-3 Stage thử nghiệm + camera

- **Milestone / task:** 2 / M2-3
- **Trạng thái:** TESTED (headless). **Chờ owner chơi thử trong Godot** để chấm cảm giác.
- **File tạo/sửa:**
  - `data/stages/test_stage.json`: bản đồ ký tự 112×17 ô (ô 64 px): cột cao 1–4 ô + bậc 5 ô sát cột 4 ô, hố rộng 3/4/5 ô, 3 platform một chiều xếp tầng. Sửa layout bằng file này.
  - `scripts/world/stage_map.gd` (`StageMap`): đọc/kiểm tra bản đồ, dựng `TileMapLayer` + TileSet (va chạm layer 1, platform một chiều).
  - `scripts/world/follow_camera.gd` (`FollowCamera`): bám mượt, nhìn trước 220 px theo hướng mặt, vùng chết dọc lệch (lên 360 px, xuống 64 px), khóa trong biên màn.
  - `scripts/world/test_stage.gd` + `scenes/stages/test_stage.tscn`: đặt nhân vật tại `P`, camera, hồi sinh khi rơi hố, overlay debug, điều khiển cảm ứng (chỉ hiện trên máy cảm ứng).
  - `scripts/ui/debug_overlay.gd`: phím + state/vận tốc/chạm đất/FPS; chỉ ở bản debug; F3 bật/tắt.
  - Hub: tab Battle có nút **Màn thử nghiệm** (tạm, thay ở M7). Khóa dịch `HUB_TEST_STAGE`, `STAGE_HINT` (vi/en).
  - `assets/placeholders/placeholder_tiles_64.png` (sinh bằng `tools/gen_placeholders.gd`).
  - Test: `tests/unit/world/test_test_stage.gd` (11), `tests/smoke/m2_stage_check.gd` (màn chạy bằng vòng lặp thật). Test i18n quét thêm `scenes/stages`.
- **Đã chạy:** `tools/run_tests.ps1`; export "Windows Desktop"; nạp PCK vào project trống kiểm tra file.
- **Kết quả thật:**
  - GdUnit4 49/49 đạt (11 mới), 4 test khói đạt, mã thoát 0. Kiểm: bản đồ đọc đúng, bản đồ lỗi bị báo (ký tự lạ, hàng lệch, 2 điểm P); nhân vật đứng đúng y = 896; nhảy xuyên platform một chiều từ dưới và đứng trên nó (y = 704); khối đặc chặn đường chạy; rơi hố → hồi sinh tại P; camera nhìn trước ±220 px theo hướng; nhảy cao nhất không làm camera nhấp nhô (< 1 px); bước khỏi platform camera theo xuống 192 px; camera không lộ ngoài biên.
  - Bản build Windows có đủ bản đồ, config, scene, placeholder; không có `tools/`, `tests/`.
- **Lỗi tìm thấy và sửa:**
  - Bản đồ: bậc 5 ô (= độ cao nhảy tối đa) chặn đường → đặt sát cột 4 ô thành bậc thang.
  - Camera: vùng chết dọc 180 px < độ cao nhảy 320 px → camera nhấp nhô mỗi cú nhảy; đổi sang vùng chết lệch lên 360 / xuống 64.
- **Phát hiện cần lưu ý:** cửa sổ **hẹp hơn 16:9** (4:3, hoặc kéo cửa sổ Windows cao) với stretch `expand` làm khung nhìn cao hơn 1080; bản đồ cao 1088 px sẽ lộ khoảng trống trên/dưới. Cần quyết ở M6/M7: bản đồ cao hơn, hoặc khóa tỉ lệ tối thiểu 16:9 (viền cho màn hẹp).
- **Hạn chế đã biết:** chưa có parallax, platform di chuyển, dốc, rơi xuyên platform (chưa có action "xuống"); nền một màu.

## 2026-11-11 — Sửa lỗi: nút Màn thử nghiệm không hiện ở tab Battle

- **Trạng thái:** TESTED
- **Owner báo:** chơi thử trong Godot, tab Chiến đấu chỉ hiện "Battle (work in progress)", không có nút vào màn thử nghiệm.
- **Nguyên nhân:** khi làm M2-3, dòng `_test_stage.visible = tab_name == "BattleTab"` trong `scripts/ui/hub.gd` không được ghi: script Python tôi dùng để sửa file thay chuỗi không khớp và **không báo lỗi**. Test không bắt được vì chỉ mở thẳng màn thử nghiệm, không đi qua Hub.
- **Sửa:** thêm lại dòng đó. `tests/smoke/m1_flow_check.gd` thêm 6 bước: nút ẩn ở Home, hiện ở Battle, ẩn lại khi về Home, bấm vào màn thử nghiệm, Esc về Hub, Esc về Title.
- **Đã chạy:** test khói luồng **trước** khi sửa → báo FAIL đúng chỗ; **sau** khi sửa → 15/15 đạt; `tools/run_tests.ps1` → tất cả đạt.
- **Bài học:** sửa file bằng thay chuỗi phải kiểm tra lại kết quả (grep dòng mới) hoặc dùng công cụ Edit báo lỗi khi không khớp; mỗi đường vào màn chơi cần test đi qua đúng nút bấm.

## 2026-11-11 — Ngôn ngữ mặc định: tiếng Việt

- **Owner quyết định:** mặc định tiếng Việt, không theo ngôn ngữ Windows/Android (ảnh chụp owner: Windows tiếng Anh nên game hiện tiếng Anh).
- **Sửa:** `GameConfig._ready()` đặt `DEFAULT_LANGUAGE = "vi"`; thử ngôn ngữ khác bằng tham số người dùng `-- --lang=en` (tham số `--language` của Godot bị engine dùng trước nên script không đọc được). Sau này ngôn ngữ đã lưu trong Cài đặt sẽ thay mặc định (M5-1/M7).
- **Tài liệu:** sửa dòng M1-5 ở bảng mốc thử trong `IMPLEMENTATION_ROADMAP.md`, mục 9 bảng thử Android trong `ANDROID_SETUP.md`.
- **Test:** thêm 2 test (giả lập locale `en_US` → vẫn tiếng Việt; đọc tham số `--lang=`); GdUnit4 nhóm core 8/8 đạt.
- **Ghi chú:** editor đã lưu lại `scenes/main/boot.tscn` (owner mở/lưu), trong đó nền `Background` lệch `offset_left = 4`, `offset_top = -6`... — có thể do kéo nhầm; đã báo owner, chưa hoàn tác.

## 2026-11-11 — M2-4 hoãn

- **Trạng thái:** PENDING (hoãn). Đo bộ nhớ texture cần điện thoại Android và frame thật; owner đang hoãn Android và chưa giao frame. Ghi trong `IMPLEMENTATION_ROADMAP.md`. Chuyển sang M3-1.

## 2026-11-11 — M3-1 CombatRules + StatusDef

- **Milestone / task:** 3 / M3-1
- **Trạng thái:** TESTED
- **File tạo/sửa:**
  - `scripts/combat/combat_rules.gd` (`CombatRules`) + `data/config/combat_rules.tres`: Q1 (hệ số cấp 0.06, K = 500), Q2 (chí mạng 5% / +50%), Q3 (trần giảm DEF 40%), trần CDR 40%, EN/UG/lượt né theo mục 0, dự bị EN +1/s và UG 30% theo **ghi đè 8.1**, né hoàn hảo (150 ms, chậm 30% trong 0.6 s, hoàn 1 lượt, ICD 1.0 s), Q6 `revive_enabled = false`; `validate()`.
  - `scripts/combat/status_def.gd` (`StatusDef`): loại, cách cộng (REFRESH/STACKS), thời gian mặc định, hệ số boss, kháng sau khi hết, tick, độ mạnh + ý nghĩa, cờ (chặn di chuyển/hành động, kháng khựng, tính là hiệu ứng nguyên tố cho Liên kết của Kael), sự kiện đủ tầng; `validate()`, `tick_count()`, `duration_for()`.
  - `data/statuses/*.tres` (11): burn, slow, lightning_mark, judgment, curse, earth_guard, root, stun (mục 0); sand_blind, shield, taunt (Q4). Mỗi file có `metadata/source` ghi nguồn số liệu.
  - `scripts/combat/status_library.gd` (`StatusLibrary`): nạp thư mục bằng `ResourceLoader.list_directory` (xử lý `.remap` khi export), kiểm id = tên file.
  - `GameConfig`: nạp `combat_rules` và `statuses` khi khởi động, báo lỗi ra log.
  - Khóa dịch `STATUS_*` (11, vi/en).
  - `tests/unit/combat/test_combat_data.gd` (16 test).
- **Đã chạy:** `tools/run_tests.ps1`; export PCK và nạp trong project trống.
- **Kết quả thật:** GdUnit4 67/67 đạt (16 mới), 4 test khói đạt, mã thoát 0. Trong bản export, thư mục `data/statuses` chứa `*.tres.remap` (liệt kê thường sẽ không thấy gì); `list_directory` trả đúng 11 tên, nạp được `stun` (2.0 s) và `combat_rules` (K = 500).
- **Giá trị Claude tự đặt (owner chỉnh):**
  - `damage_taken_reduction_cap = 0.80`: đặc tả chỉ ghi "cap đặt trong config".
  - `taunt.boss_duration_multiplier = 0.5` (theo Terra 3 s → boss 1.5 s; kỹ năng khác có thể ghi đè, vd ảo ảnh của Seraphine boss miễn).
  - `slow.default_magnitude = 0.30` (mức phổ biến nhất; kỹ năng ghi X% riêng).
  - `sand_blind.counts_as_elemental = true` (mục 8.3 liệt kê "..." nên chưa chắc; xác nhận khi làm LinkTracker M4-3).
- **Hạn chế đã biết:** mới là dữ liệu tĩnh; áp/làm mới/hết hạn/tick do `StatusController` (chưa làm); `LinkRules` (mục 8.2, 8.3) làm ở M4-3.

## 2026-11-12 — M3-2 Hitbox / Hurtbox theo track AnimationPlayer

- **Milestone / task:** 3 / M3-2
- **Trạng thái:** TESTED (headless; chưa có đòn đánh nào trong game để xem bằng mắt — M3-5)
- **File tạo/sửa:**
  - `scripts/combat/physics_layers.gd` (`PhysicsLayers`): lớp 1 thế giới, 2 thân người chơi, 3 thân quái, 4/5 hitbox người chơi/quái, 6/7 hurtbox người chơi/quái; hàm bit/mask theo phe. Không sửa `project.godot` (editor đang mở có thể ghi đè).
  - `scripts/combat/hit_info.gd` (`HitInfo`): hit_id, phe, người đánh, skill_id, % ATK, sức choáng, vị trí, hướng/độ đẩy.
  - `scripts/combat/hitbox.gd` (`Hitbox`): tắt mặc định; `activate(keep_hit_id)` cấp hit_id mới (bộ đếm toàn cục) hoặc giữ id cũ cho đòn nhiều nhịp chỉ trúng một lần; quét vùng chồng mỗi tick vật lý; signal `hit_landed`.
  - `scripts/combat/hurtbox.gd` (`Hurtbox`): nhận mỗi hit_id một lần, bỏ qua cùng phe và chính chủ; đang bất tử → `hit_evaded` và vẫn ghi nhớ id (hết bất tử giữa chừng không bị chính lần chém đó trúng); quên id sau 3 s; đồng hồ thay được để test.
  - `scripts/combat/hitbox_track.gd` (`HitboxTrack`): frame + fps → cửa sổ giây; dựng track method gọi activate/deactivate; cửa sổ chồng/rỗng/vượt độ dài bị bỏ và báo lỗi.
  - `scenes/player/player_character.tscn`: thêm `Hurtbox` (phe người chơi, cùng capsule thân).
  - `AGENTS.md`: thêm quy ước lớp va chạm và Hitbox/Hurtbox.
  - `tests/unit/combat/test_hitbox_hurtbox.gd` (15 test).
- **Đã chạy:** `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 82/82 đạt (15 mới), 4 test khói đạt, mã thoát 0. Kiểm: ghép phe đúng lớp; mỗi lần bật trúng 1 lần dù gọi nhiều lần; giữ id không trúng lại, bật mới thì trúng; id không trùng giữa hitbox; cùng phe/chính chủ bị bỏ; bất tử né cả lần chém; quên id sau 3 s; HitInfo đúng (sức choáng 0.7 × 1.5, hướng đẩy theo hướng mặt); AnimationPlayer bật đúng frame 3–4, tắt ở khởi động và hồi phục; 3 cửa sổ → 3 hit_id → 3 lần trúng; **vật lý thật**: chồng nhau 6 frame chỉ trúng 1 lần, bật lại trúng lần 2, ngoài tầm không trúng.
- **Lỗi tìm thấy và sửa:**
  - Lớp con tên `Window` trùng lớp có sẵn của Godot → đổi thành `HitWindow`.
  - Test đặt Hitbox và Hurtbox cùng một node cha → kiểm tra "không tự đánh mình" chặn đúng; sửa test cho mỗi Hurtbox một chủ riêng.
  - Đợi thời gian thật trong GdUnit không ổn định (`create_timer(..., ignore_time_scale)` trả về ngay) → Hurtbox dùng đồng hồ thay được, test dùng đồng hồ giả.
- **Hạn chế đã biết:**
  - Bộ nhớ hit_id tính theo thời gian thật; khi có hit-stop/tạm dừng (M3-7) cần xem lại.
  - Hai Hitbox của cùng một đòn (hai vùng chạm) chưa dùng chung hit_id; làm khi kỹ năng cần.
  - Chưa tính sát thương (M3-3) và chưa có máu (M3-4).

## 2026-11-12 — M3-3 DamageCalculator

- **Milestone / task:** 3 / M3-3
- **Trạng thái:** TESTED
- **File tạo:**
  - `scripts/core/random_source.gd` (`RandomSource`): RNG có seed, `chance()`, lưu/khôi phục trạng thái; lớp `Fixed` trả giá trị cố định để test ép chí mạng.
  - `scripts/combat/damage_calculator.gd` (`DamageCalculator`): hàm thuần `compute()` theo ARCHITECTURE mục 5 (Q1 hệ số cấp + K = 500, Q2 chí mạng, Q3 giảm DEF khác tên cộng dồn, trần 40%, trần giảm sát thương nhận từ CombatRules); `heal()`; trả `Result` kèm từng hệ số (raw, bonus, dealt, mitigation, crit, taken).
  - `tests/unit/combat/test_damage_calculator.gd` (19 test).
- **Đã chạy:** `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 101/101 đạt (19 mới), 4 test khói đạt, mã thoát 0. Ví dụ đã kiểm bằng số tính tay: ATK 1000, đòn 70%, DEF 500 → 350; cấp 10 → 539; chí mạng → 525; Nguyền 15% + 20% → 606; 45% → trần 40% → 625; Nguyền áp hai lần vẫn tính một lần → 541; Giáp Địa 35% + 40% → 125, thêm 15% → trần 80% → 100; Mù cát → 400; đủ mọi yếu tố → 446; hồi máu 1000×50% + 10000×3% = 800, cấp 3 → 896; 10 000 roll với seed: chí mạng trong 4–6 %.
- **Diễn giải Claude thêm (owner xác nhận):**
  - **Mù cát** (−20% sát thương kẻ địch gây ra) không có trong công thức ARCHITECTURE → thêm hệ số riêng `dealt = 1 − Σ%giảm sát thương gây ra` (chặn 0..1), không gộp vào `bonus`.
  - **Hồi máu** (mục 0: "% ATK + % HP tối đa của mục tiêu") tăng theo cấp kỹ năng như sát thương, không chí mạng, không bị DEF.
  - Làm tròn `round()` (0.5 làm tròn ra xa 0); không có sát thương tối thiểu 1 (đòn 0 ATK gây 0).
  - Sức choáng (SC) chưa tính ở đây; làm cùng quái và thanh SC ở M3-6.

## 2026-11-12 — M3-4 ResourceComponent + CooldownController

- **Milestone / task:** 3 / M3-4
- **Trạng thái:** TESTED
- **File tạo:**
  - `scripts/combat/resource_component.gd` (`ResourceComponent`, RefCounted + `tick`): HP (nhận sát thương trả lượng thực mất; mất HP cộng UG 0.3 mỗi 1% HP tối đa; gục một lần; không hồi khi đã gục), hồi máu trả phần thừa (cho khiên của Seraphine), EN (+2/s trên sân, +1/s dự bị, trần 100, tiêu EN từ chối an toàn khi thiếu), UG (trần 100, báo `ultimate_ready` một lần, `use_ultimate` về 0), `register_hit(kind)` cộng EN/UG theo loại đòn và trả lượng UG để chia 30% cho dự bị, 2 lượt né hồi 4 s/lượt có CDR (trần 40%), hoàn lượt khi né hoàn hảo.
  - `scripts/combat/cooldown_controller.gd` (`CooldownController`, RefCounted + `tick`): đăng ký khóa (Kĩ năng thường, vũ khí, SI-CD…), CDR áp khi bắt đầu hồi với trần 40%, khóa có thể không chịu CDR, `reduce()` rút CD riêng không bị trần CDR nhưng có mức tối đa mỗi chu kỳ, `progress()` cho vòng hồi HUD, signal bắt đầu/sẵn sàng.
  - `tests/unit/combat/test_resources_cooldowns.gd` (20 test).
- **Đã chạy:** `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 121/121 đạt (20 mới), 4 test khói đạt, mã thoát 0.
- **Lỗi tìm thấy và sửa:** trừ 0.1 s tám mươi lần khỏi 8.0 s còn dư ~1e-15 s → hồi chiêu chậm "sẵn sàng" một khung hình. CooldownController coi phần dư < 1 µs là 0.
- **Diễn giải Claude chọn (owner xác nhận):**
  - "+3 EN / +2 UG mỗi đòn trúng" tính **một lần mỗi nhát (hit_id)**, không nhân theo số kẻ địch trúng, để đòn diện rộng không nạp quá nhanh.
  - CDR "chốt" lúc bắt đầu hồi: đổi CDR giữa chừng không ảnh hưởng chu kỳ đang chạy.
  - Hồi sinh tắt (Q6): đã gục thì không hồi máu, không hồi EN, không né.
- **Hạn chế đã biết:** chưa nối với nhân vật/HUD (cần SkillRunner, M3-5); HP tối đa tạm truyền vào, sau lấy từ `CharacterDef`; chia UG 30% cho dự bị do PartyManager làm ở M4.

## 2026-11-12 — M3-5 phần 1: nền kỹ năng, StatusController, đòn thường + né Aether, hình nộm

- **Milestone / task:** 3 / M3-5 (phần 1/3)
- **Trạng thái:** TESTED (headless). **Owner chơi thử được**: màn thử nghiệm có 2 hình nộm, J đánh, L/Shift né.
- **File tạo:**
  - Dữ liệu kỹ năng: `scripts/combat/skill_def.gd` (`SkillDef`: pha ms, EN, CD, vùng gây đòn, di chuyển, bất tử, kháng khựng, nối đòn), `hit_def.gd` (`HitDef`: thời điểm, % ATK, SC, hình cung/tròn/chữ nhật, đẩy lùi, trạng thái, vùng tách bay/tick), `status_application.gd`.
  - `scripts/characters/combat_stats.gd`, `character_def.gd` + `data/characters/char_fire_01.tres` (**chỉ số tạm: HP 12000, ATK 1000, DEF 500** — README chưa có).
  - `data/skills/char_fire_01/normal_1..4.tres`, `dodge.tres` (sinh bằng `tools/gen_aether_data.py`, ghi nguồn ở `metadata/source`).
  - `scripts/combat/status_controller.gd` (`StatusController`): áp/làm mới (giữ mức mạnh hơn)/cộng tầng, nhịp sát thương, hết hạn, kháng sau Choáng, boss, gộp chỉ số cho DamageCalculator.
  - `scripts/combat/combatant.gd` (`Combatant`): chỉ số + ResourceComponent + CooldownController + StatusController; nhận đòn từ Hurtbox, tính sát thương bằng chỉ số người đánh, áp trạng thái, cộng EN/UG một lần mỗi hit_id, sát thương Cháy (không chí mạng).
  - `scripts/combat/skill_runner.gd` (`SkillRunner`): dựng một animation/kỹ năng với track bật Hitbox (HitboxTrack), tiêu EN, hồi chiêu, khóa hướng, di chuyển, bất tử, nối đòn + reset 0.8 s, huỷ bằng né nửa sau hồi phục. `detached_hit.gd` cho sóng lửa / vệt lửa.
  - Player: state `attack`, `dodge` (`scripts/player/states/combat_states.gd`); `PlayerIntent` đệm mọi nút, đòn thường tính khi **nhả** nút (giữ ≥ 400 ms để dành cho đòn giữ); controller nạp `CharacterDef`.
  - Hình nộm: `scenes/world/training_dummy.tscn` (HP 200 000, DEF 500, hồi đầy sau 3 s không bị đánh, hiện máu/DPS/trạng thái), `scripts/ui/floating_number.gd`; bản đồ thêm ký tự `D`.
  - Hitbox tự vẽ vùng khi bật (cam trong suốt) thay VFX tạm.
  - Dòng debug: HP/EN/UG/lượt né/hồi chiêu, kỹ năng đang chạy.
  - Test: `test_status_controller.gd` (9), `test_aether_basic.gd` (12).
- **Đã chạy:** `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 142/142 đạt (21 mới), 4 test khói đạt, mã thoát 0. Kiểm: tổng Hỏa Trảm 355% ATK; đòn 1 trúng hình nộm đúng 1 lần = 350; chuỗi 4 đòn ra 350, 375, 425 rồi kiếm 425 + sóng 200, áp Cháy; Cháy 3 s = 6 nhịp × 40; chuỗi reset sau 0.8 s; mỗi đòn tiến 40 px; né lướt 280 px, bất tử trong 40–220 ms, theo hướng đang giữ; vệt lửa 2 × 125 và không nạp EN; hết lượt không né được; né chỉ huỷ được nửa sau hồi phục.
- **Lỗi tìm thấy và sửa:**
  - `SkillRunner` xoá đòn đã xếp hàng trước khi đọc → chuỗi không nối quá đòn 1. Sửa: đọc hàng đợi trước khi dừng đòn.
  - `_ready` của node con chạy trước cha → Combatant dựng tài nguyên với chỉ số mặc định. Thêm `auto_setup`, controller gọi `setup()` sau khi gán chỉ số.
  - `StatusController.tick` viết lần đầu rối → viết lại: thời gian trôi → phát nhịp đến hạn (kể cả nhịp đúng lúc hết hạn) → xét hết hạn.
- **Diễn giải Claude chọn (owner xác nhận):**
  - "Nối đòn nếu bấm trong 260 ms cuối pha hồi phục" nhưng đòn 1–2 chỉ hồi phục 160 ms → tính **260 ms cuối cả đòn**; đòn kế chạy khi đòn hiện tại kết thúc (chỉ né mới huỷ được hồi phục).
  - Đòn thường tính khi **nhả** nút (vì giữ ≥ 400 ms là đòn giữ).
  - Sóng lửa đòn 4 bay 220 px trong 300 ms; cả kiếm và sóng đều áp Cháy 3 s, SC ×1.5.
  - Vệt lửa khi né không nạp EN/UG (`HitKind.NONE`).
- **Chưa làm (phần 2–3):** giữ nút, trên không, đáp đất; kỹ năng, kỹ năng vũ khí, tuyệt kỹ, nội tại Nhiệt, né hoàn hảo — Hơi Nóng.

## 2026-11-12 — M3-5 phần 2: đòn giữ, trên không, đáp đất (Aether)

- **Milestone / task:** 3 / M3-5 (phần 2/3)
- **Trạng thái:** TESTED (headless). Owner chơi thử được: giữ J để nạp, J khi nhảy, J khi đang rơi cao để lao xuống.
- **File tạo/sửa:**
  - `data/skills/char_fire_01/hold_1.tres`, `hold_2.tres`, `air_1.tres`, `air_2.tres`, `landing.tres` (thêm vào `tools/gen_aether_data.py`).
  - `SkillDef`: `cooldown_group` (hold_1/hold_2 chung khóa "hold"), `extra_en_on_hit`, cửa sổ tắt trọng lực, `keep_momentum`, thông số nạp (`charge_start_ms`, `charge_level_ms`, `charge_move_slow`), lao xuống (`dive_speed_px`, `min_height_px`, `pre_dive_ms`).
  - State `charge` (nạp, đi chậm 40%) và `plunge` (treo 60 ms, lao 1400 px/s, chạm đất chạy kỹ năng `landing`).
  - Controller: chọn đòn trên không/đáp đất, đếm đòn trên không mỗi lần nhảy, đo độ cao bằng tia xuống đất, cấp nạp theo thời gian giữ.
  - SkillRunner: nối đòn cho mọi kỹ năng có `next_skill` (air_1 → air_2); EN cộng thêm truyền qua Hitbox/HitInfo tới Combatant (cả vùng tách).
  - Gợi ý phím cập nhật.
  - `tests/unit/combat/test_aether_air_hold.gd` (12 test).
- **Đã chạy:** `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 154/154 đạt (12 mới), 4 test khói đạt, mã thoát 0. Kiểm: giữ < 400 ms → đòn thường; giữ 750 ms → Cấp 1 = 800 sát thương, +6 EN; giữ 550 ms → đòn thường; giữ 1550 ms → Cấp 2 = 1400, kháng khựng, Cháy; đang nạp chạy 270 px/s (chậm 40%); hồi 1 s dùng chung cho hai cấp; 2 đòn trên không mỗi lần nhảy, chạm đất đếm lại; đòn trên không 2 treo (vy = 0); lao từ cao 500 px chạm đất đúng y = 896, nổ 700, Cháy; thấp < 200 px hoặc chưa có đòn trên không thì không lao.
- **Diễn giải Claude chọn (owner xác nhận):**
  - Nhả trong 400–700 ms (đã nạp nhưng chưa tới Cấp 1) → **đòn thường**.
  - Đang giữ nút mà đòn giữ còn hồi chiêu → không nạp; nhả ra không có đòn (chưa xử lý thành đòn thường).
  - Đáp đất: bấm đánh **khi đang rơi**, đã có ≥ 1 đòn trên không, cao ≥ 200 px. Đang bay lên → đòn trên không thứ 2.
  - Cấp 1 "khựng", đòn trên không 2 "đẩy xuống 30°", đáp đất "miễn đẩy lùi": cần phản ứng của quái → làm ở M3-6 (đã có cờ `plunging`, `super_armor`).

## 2026-11-12 — M3-5 phần 3: kỹ năng, vũ khí, tuyệt kỹ, nội tại Aether — M3-5 xong

- **Milestone / task:** 3 / M3-5 (phần 3/3)
- **Trạng thái:** TESTED (headless). **Owner chơi thử được** đủ bộ Aether: U kỹ năng, I vũ khí, O tuyệt kỹ (cần UG đầy).
- **File tạo/sửa:**
  - `data/skills/char_fire_01/skill.tres` (Liệt Diễm Luân: 25 EN, CD 6 s, 4 nhịp 80/80/80/110% bán kính 200, Cháy 4 s, kháng khựng), `weapon.tres` (Thiên Hỏa Nhất Kích: 35 EN, CD 12 s, lướt 400 px 220% + Nung chảy −10% DEF 5 s, bất tử khi lướt, vết chém nổ chậm 1.0 s 130%), `ultimate.tres` (Viêm Hoàng Tuyệt Trảm: 100 UG, khóa 2 s **tính từ khi kết thúc**, mục tiêu gần nhất trong 500 px, 5 × 120% + nổ 500%, Cháy 6 s, bất tử).
  - Trạng thái riêng Aether: `heat` (Nhiệt, 5 tầng, 6 s), `melt` (Nung chảy), `phoenix` (Hỏa Hoàng +20% sát thương 8 s), `hot_breath` (Hơi Nóng). Tổng 15 trạng thái.
  - Kit nhân vật: `scripts/characters/kits/fire_kit.gd` + `fire_kit_config.gd` + `data/characters/char_fire_01_kit.tres`; `CharacterDef.kit_script/kit_config`. Kit làm: Nhiệt khi đòn trực tiếp trúng mục tiêu đang Cháy (ICD 0.3 s, +4% ATK/tầng), 5 tầng → Kĩ năng thường/vũ khí +25% và tiêu tầng, đạt 5 tầng −1.0 s CD kỹ năng (ICD 6 s), ≥ 3 tầng nạp UG ×1.2; đòn cơ bản trúng mục tiêu Cháy −0.2 s CD kỹ năng (tối đa 2.0 s/chu kỳ); hạ gục mục tiêu Cháy −2.0 s CD vũ khí (tối đa 4.0 s); Hơi Nóng; Hỏa Hoàng thêm sóng lửa cho đòn thường.
  - Chung: `HitDef.delay_ms`, `at_target`; `SkillDef.ug_cost`, `target_range_px`, `cooldown_starts_on_end`; SkillRunner tìm kẻ địch gần nhất (nhóm `combatants`); `HitInfo` ghi trạng thái mục tiêu trước đòn và cờ hạ gục; buff `damage_dealt_up`; `ResourceComponent.ug_gain_multiplier`.
  - Né hoàn hảo (chung mọi nhân vật) trong PlayerController: đòn tới trong 150 ms đầu khung bất tử → kẻ đánh chậm 30% 0.6 s, hoàn 1 lượt né, ICD 1.0 s, signal `perfect_dodged`.
  - Nút U/I/O trong `combat_transition` (trên đất và trên không); HUD debug hiện trạng thái của Aether; gợi ý phím.
  - `tests/unit/combat/test_aether_skills.gd` (15 test).
- **Đã chạy:** `tools/run_tests.ps1`; export "Windows Desktop" và chạy bản build headless.
- **Kết quả thật:** GdUnit4 169/169 đạt (15 mới), 4 test khói đạt, mã thoát 0. Bản build Windows xuất được (~97 MB), chạy không lỗi/cảnh báo.
  Số đã kiểm: kỹ năng 400, 400, 416, 572 (Nhiệt cộng giữa chừng); thiếu EN bị từ chối; vũ khí lướt 400 px, 1100 rồi nổ 684 (đã −10% DEF); tuyệt kỹ 5 × 600 + 2500, cho Hỏa Hoàng, khóa 2 s sau khi kết thúc; không có mục tiêu thì đặt trước mặt; Nhiệt +4% ATK (1040); 5 Nhiệt → kỹ năng 500, 500, 520, 715 và tiêu tầng; ≥ 3 Nhiệt UG ×1.2; né hoàn hảo hoàn lượt, làm chậm kẻ đánh, không mất máu, đòn thường kế tiếp 455 và áp Cháy; Hỏa Hoàng: đòn 1 420 + sóng 240.
- **Lỗi tìm thấy và sửa:** tuyệt kỹ bắt đầu khóa 2 s lúc tung chiêu, nhưng tuyệt kỹ dài 2.8 s nên khóa vô nghĩa → thêm `cooldown_starts_on_end`. Một số kỳ vọng ban đầu trong test sai vì chưa tính nội tại Nhiệt cộng giữa các nhịp — đã sửa theo đặc tả.
- **Diễn giải Claude chọn (owner xác nhận):**
  - Nhiệt chỉ tích từ **đòn đánh trực tiếp**, nhịp Cháy không tính (nếu không sẽ tự đầy).
  - Né hoàn hảo = đòn tới trong 150 ms đầu khung bất tử (Aether: 40–190 ms của cú né).
  - Sóng lửa của Hỏa Hoàng: tài liệu không ghi % → dùng sóng đòn 4 (40% ATK).
  - Hỏa Hoàng áp khi tuyệt kỹ **kết thúc**, kể cả khi không trúng ai.
  - Vết chém của vũ khí nổ dạng chữ nhật 400 × 280 dọc đường lướt (gần đúng "bán kính 140 dọc đường").
  - Kỹ năng/vũ khí/tuyệt kỹ dùng được cả trên không; chỉ dùng được từ trạng thái tự do (không huỷ đòn thường).
- **Chưa làm (để M3-6/M3-7/M4):** dừng thời gian 600 ms + ảnh cut-in của tuyệt kỹ; khựng/đẩy lùi/sức choáng lên quái; không cho đổi nhân vật khi đang tuyệt kỹ chuỗi đòn; hiệu ứng hình (hiện đang vẽ vùng gây đòn màu cam thay VFX).

## 2026-11-12 — M3-6 Quái thường (slime)

- **Milestone / task:** 3 / M3-6
- **Trạng thái:** TESTED (headless). Owner chơi thử được: 3 slime trong màn thử nghiệm (sau dãy cột và sau dãy hố).
- **File tạo/sửa:**
  - `scripts/enemies/enemy_def.gd` (`EnemyDef`) + `data/enemies/enemy_slime_01.tres` (**placeholder do Claude đặt**: HP 6000, ATK 400, DEF 300, SC 300, tốc độ 160, phát hiện 700 px, tầm đánh 170 px, nghỉ 1.5 s; đòn cắn báo hiệu 500 ms, lao 60 px, 100% ATK, đẩy 120 px).
  - `scripts/enemies/enemy_controller.gd` (`EnemyController`) + `scenes/enemies/enemy_slime.tscn`: tuần tra ± 200 px có nghỉ → đuổi khi thấy → đánh (thân chuyển cam khi báo hiệu) → hồi → đuổi; trúng đòn: khựng 0.25 s (ngắt được trong pha khởi động, không ngắt khi đòn đã có hiệu lực), đẩy lùi; SC đầy → Choáng (thân xanh, chữ "Choáng"), kháng 8 s; SC tự giảm sau 2 s không bị đánh; chết → mờ 0.6 s rồi xoá; thanh HP nhỏ hiện khi bị đánh + thanh SC.
  - `CombatRules`: `player_stagger_sec` 0.3, `knockback_time_sec` 0.15, `sc_points_per_ratio` 100 (SC = % ATK của đòn).
  - `EventBus`: `enemy_stunned`, `enemy_defeated` (cho Liên kết ở M4-3).
  - Người chơi: state `hurt` (khựng + đẩy lùi), `down` (gục); không khựng khi kỹ năng có kháng khựng hoặc đang lao xuống; `restore_full()`.
  - Màn thử nghiệm: ký tự `E` trong bản đồ; quái hồi sau 5 s; người chơi gục đứng dậy đầy máu sau 1.5 s (chỉ ở màn thử nghiệm).
  - `AGENTS.md`: quy ước không gọi thẳng tên autoload trong script gameplay.
  - `tests/unit/enemies/test_enemy_slime.gd` (14 test).
- **Đã chạy:** `tools/run_tests.ps1`; export Windows + chạy bản build.
- **Kết quả thật:** GdUnit4 183/183 đạt (14 mới), 4 test khói đạt, mã thoát 0; bản build chạy không lỗi. Kiểm: tuần tra trong ± 200 px; thấy người chơi thì đuổi và quay mặt; báo hiệu ≥ 24 khung (0.4 s) rồi trúng người chơi 200, người chơi khựng và bị đẩy lùi, hết khựng sau 0.3 s; kỹ năng kháng khựng vẫn mất máu nhưng không bị ngắt; né tránh được đòn; **né hoàn hảo trước đòn thật**: slime bị chậm, Aether có Hơi Nóng, không mất máu; đánh trúng khi slime đang báo hiệu → khựng, đòn bị huỷ; SC đầy → Choáng, phát `enemy_stunned`, kháng 8 s sau đó; đòn 70% → 70 SC; SC giảm sau 2 s; chết phát `enemy_defeated` rồi biến mất; hạ slime đang Cháy rút 2 s CD vũ khí Aether; người chơi gục không điều khiển được, đứng dậy đầy máu.
- **Lỗi tìm thấy và sửa:** gọi `EventBus.x` trực tiếp làm test khói (`--script`) không biên dịch được → lấy autoload qua đường dẫn.
- **Diễn giải Claude chọn (owner xác nhận):**
  - "SC bằng % ATK của đòn" → đòn 70% ATK gây 70 điểm SC; thanh slime 300.
  - Khựng chỉ ngắt được pha khởi động (báo hiệu); khi đòn đã có hiệu lực thì không ngắt.
  - Quái không chặn đường người chơi (đi xuyên nhau); chỉ va chạm với địa hình.
  - SC không tích khi đang Choáng và trong 8 s kháng.
- **Hạn chế đã biết:** quái chưa nhảy/đi vòng qua bậc (đứng dưới chân cột); chưa có thưởng khi hạ (M5/M6); hướng đẩy xuống 30° của đòn trên không 2 chưa làm (đẩy ngang); hiệu ứng hình tạm (đa giác màu).

## 2026-11-12 — Quy tắc làm việc: tự chủ chi tiết nhỏ

- **Owner quyết định:** từ M3-7, agent tự quyết chi tiết kỹ thuật; không hỏi về màu sắc, tên biến, cấu trúc folder, kích thước nút, số frame animation, thông số cân bằng nhỏ. Ghi vào `AGENTS.md` mục 6 và bộ nhớ của Claude. Từ đây các lựa chọn như vậy ghi trong mục **"Quyết định Claude chọn"** của từng task, không còn mục "owner xác nhận" cho chi tiết nhỏ.

## 2026-11-12 — M3-7 Phản hồi đòn (hit feedback)

- **Milestone / task:** 3 / M3-7
- **Trạng thái:** TESTED (headless). **Mốc owner chơi thử trong Godot** (cảm giác đòn).
- **File tạo/sửa:**
  - `scripts/combat/hit_feedback.gd` (`HitFeedback`) + `hit_feedback_config.gd` + `data/config/hit_feedback.tres`: nghe `EventBus`; hit-stop bằng `Engine.time_scale = 0` khôi phục theo **thời gian thật**; rung camera; số sát thương; đếm combo (HUD góc phải); dừng thời gian kẻ địch + cut-in khi tuyệt kỹ.
  - `EventBus`: `hit_landed`, `dot_landed`, `ultimate_started`. `Combatant` phát `hit_landed`/`dot_landed`; PlayerController phát `ultimate_started`.
  - `FollowCamera.add_shake/update_shake` (rung theo thời gian thật, dùng `offset` nên không ảnh hưởng vị trí bám).
  - `FloatingNumber`: 4 kiểu (thường trắng, chí mạng vàng to, Cháy cam nhỏ, người chơi mất máu đỏ), nảy rồi mờ; không dùng ngẫu nhiên. Hình nộm không tự hiện số nữa (gom về HitFeedback).
  - Kẻ địch, hình nộm: nhóm `time_stoppable`, hàm `freeze(giây)`.
  - Aether chớp trắng 0.1 s khi bị đánh.
  - `SkillDef.name_key`, `time_stop_ms`; tuyệt kỹ Aether: 600 ms, tên "Viêm Hoàng Tuyệt Trảm".
  - Màn thử nghiệm tạo HitFeedback.
  - `tests/unit/combat/test_hit_feedback.gd` (10 test).
- **Đã chạy:** `tools/run_tests.ps1`; export Windows + chạy bản build.
- **Kết quả thật:** GdUnit4 193/193 đạt (10 mới), 4 test khói đạt, mã thoát 0; bản build chạy không lỗi. Kiểm: thời lượng hit-stop nhẹ 45 / nặng 70 / chí mạng +10 / trần 80 ms; hit-stop dừng và tự khôi phục theo thời gian thật (đo 60–200 ms cho 70 ms); nhiều hit-stop chồng lấy mức dài nhất (~70 ms, không phải 160); tắt được; đánh trúng thật → hit-stop + rung + số + combo 1; combo ngắt sau 2 s; người chơi bị đánh → combo về 0, số đỏ; Cháy hiện số cam; tuyệt kỹ → slime đứng im ~600 ms và cut-in hiện rồi tắt. 183 test cũ vẫn đạt khi bật hit-stop (khung vật lý dừng theo nên test đếm khung vẫn đúng thời gian game).
- **Quyết định Claude chọn:**
  - Hit-stop nhẹ 45 ms, nặng 70 ms (đòn ≥ 120% ATK hoặc SC ×1.5), chí mạng +10, trần 80; người chơi bị đánh 60 ms.
  - Hit-stop dừng toàn bộ thời gian game (đơn giản, đúng tinh thần "dừng mọi thứ"); nhiều đòn cùng lúc lấy mức dài nhất.
  - Rung: nhẹ 4 px 0.08 s, nặng 10 px 0.15 s, bị đánh 9 px 0.14 s.
  - Combo đếm **mỗi lần trúng một mục tiêu**; ngắt sau 2 s hoặc khi bị đánh; hiện từ 2 đòn.
  - Cut-in tạm: nền tối + dải màu lửa + tên chiêu trượt vào từ phải; dừng thời gian áp cho kẻ địch và hình nộm (Aether vẫn chạy pha khởi động, đang bất tử).
- **Hạn chế đã biết:** chưa có âm thanh trúng đòn (M7, chờ SFX); VFX vẫn là đa giác; phản ứng nguyên tố (hit-stop 60 ms, tên phản ứng 0.8 s) làm ở M4-5.

## 2026-11-12 — M4-1 PartyManager + M4-2 CharacterRuntime cho dự bị

- **Milestone / task:** 4 / M4-1, M4-2
- **Trạng thái:** TESTED (headless). Chưa thử bằng tay (mốc chơi thử của M4 là M4-4 / M4-7).
- **File tạo/sửa:**
  - `scripts/party/party_manager.gd` (`PartyManager`): đội 3 người, 1 người trên sân; chuyển bằng `switch_1`/`switch_2` (Q/1, E/2); chờ chung 1.0 s; khóa khi tuyệt kỹ chuỗi đòn; không chuyển sang người đã gục; giữ lệnh chuyển 0.15 s nếu chưa chuyển được (mục 8.11); dự bị nhận 30% UG; người trên sân gục → tự đưa người còn sống đầu tiên vào; cả đội gục → `party_defeated`. Signal `switched`, `switch_rejected`, `member_down`.
  - `scripts/party/character_runtime.gd` (`CharacterRuntime`): giữ PlayerController của từng thành viên; ở dự bị node bị **gỡ khỏi cây** (không có trên sân, không AI, không bị nhắm) nhưng `tick_reserve` vẫn chạy tài nguyên, hồi chiêu, trạng thái, kit (Nhiệt...).
  - `PlayerController`: `leave_field`, `enter_field`, `tick_reserve`, `is_switch_locked`.
  - `ResourceComponent`: signal `ug_gained`; `add_ug(amount, apply_multiplier)`; nhân vật đã gục không nhận UG.
  - `SkillDef.locks_switch`; tuyệt kỹ Aether bật (cả `tools/gen_aether_data.py`, chạy lại ra đúng file).
  - `CombatRules` + `combat_rules.tres`: `switch_cooldown_sec` 1.0, `switch_input_buffer_sec` 0.15, `down_auto_switch_sec` 1.0.
  - `data/characters/char_lightning_01.tres` (Kael), `char_wind_01.tres` (Lyra): chỉ số tạm, chỉ di chuyển; khóa dịch `CHAR_LIGHTNING_01`, `CHAR_WIND_01` (vi + en).
  - `EnemyController`: mục tiêu rời sân (node ngoài cây) → nhắm người mới trên sân.
  - Màn thử nghiệm: đội Aether / Kael / Lyra qua PartyManager; camera, HitFeedback, debug bám người trên sân; thành viên gục ở dự bị đứng dậy sau 1.5 s; cả đội gục thì hồi cả đội.
  - `tests/unit/party/test_party_manager.gd` (20 test); sửa `test_enemy_slime.gd::test_player_down_then_revives_in_test_stage` theo hành vi mới.
- **Đã chạy:** `godot --headless --import`; `tools/run_tests.ps1`; `python tools/gen_aether_data.py` (so diff); export Windows Desktop.
- **Kết quả thật:** GdUnit4 213/213 đạt (20 mới), 0 orphan, 4 test khói đạt, mã thoát 0; export mã 0. Kiểm: chỉ người trên sân ở trong cây và nhóm `player`; chuyển giữ vị trí và hướng, camera/HitFeedback đổi theo; chuyển lần hai trong 1.0 s bị từ chối, sau 1.0 s được; bấm sớm 0.1 s thì lệnh được giữ và chuyển, quá 0.15 s thì bỏ; trong tuyệt kỹ Aether bị khóa, xong thì mở; không chuyển sang người gục; dự bị EN +1/s, trên sân +2/s; dự bị nhận 30% UG (dùng hệ số của người trên sân, không nhân hệ số của dự bị); hồi chiêu và Nhiệt của Aether vẫn chạy khi ở dự bị; Aether gục → 1.0 s sau người còn sống kế tiếp vào sân; cả đội gục phát `party_defeated`; slime đổi mục tiêu sang người mới; node dự bị được giải phóng cùng màn.
- **Quyết định Claude chọn:**
  - Dự bị = node PlayerController gỡ khỏi cây (không ẩn/tắt trong cây), để tự động ra khỏi nhóm `player`/`combatants`, không va chạm, không xử lý input.
  - Icon dự bị theo thứ tự trong đội, bỏ người trên sân (đội Aether, Kael, Lyra: lúc đầu icon 1 = Kael, icon 2 = Lyra).
  - Người trên sân gục: tự đưa người dự bị còn sống đầu tiên vào sau 1.0 s, vào mặc định, không tính chờ chung. Đặc tả chưa ghi trường hợp này.
  - Phần UG chia cho dự bị tính trên lượng người trên sân nhận **trước khi chặn trần** (người trên sân đầy UG thì dự bị vẫn nhận).
  - Chỉ số tạm Kael HP 10500 / ATK 950 / DEF 450, Lyra HP 9500 / ATK 800 / DEF 400.
- **Hạn chế đã biết:** chưa có Kĩ năng vào sân, SI-CD, Liên kết (M4-3, M4-4); animation vào/ra sân chưa có (đổi tức thì); Kael, Lyra chưa đánh được (M4-6); chưa có HUD icon dự bị (M4-7), tạm nhận biết người trên sân qua màu placeholder (Aether đỏ cam, Kael vàng, Lyra xanh ngọc); nút cảm ứng switch_1/2 đã có từ M1 nhưng chưa có icon.

## 2026-11-12 — M4-3 LinkTracker: 6 điều kiện Liên kết, cửa sổ 6.0 s, SI-CD

- **Milestone / task:** 4 / M4-3
- **Trạng thái:** TESTED (headless). Chưa thấy được bằng mắt (vòng sáng là M4-7).
- **File tạo/sửa:**
  - `scripts/party/link_tracker.gd` (`LinkTracker`): điều kiện của từng nhân vật lấy từ `CharacterDef.link_condition`; người trên sân làm việc đó → cửa sổ `link_window_sec` (6.0 s) của người dự bị có điều kiện đó mở (làm mới nếu đang mở). Vòng sáng = cửa sổ còn + SI-CD đã hồi + chưa gục. Mức vào sân: Liên kết / Thường / mặc định; Thường và Liên kết bắt đầu SI-CD; Liên kết +15 UG, +10 EN cho người vào sân. SI-CD là khóa `switch_in` trong CooldownController của từng nhân vật (đếm cả khi dự bị, chịu CDR chung, trần 40%).
  - `PartyManager`: tạo LinkTracker; cấp sự kiện từ EventBus (`enemy_stunned`, `enemy_defeated`, `status_applied`) và từ người trên sân (`perfect_dodged`, kỹ năng vũ khí/tuyệt kỹ bắt đầu); `mode_for()`, `last_switch_mode`; signal `switched(from, to, mode)`; phát `character_switched`, `link_window_opened/closed` lên EventBus.
  - `EventBus`: `status_applied`, `link_window_opened`, `link_window_closed`, `character_switched`.
  - `StatusController.applied_from(status_id, source)`; `Combatant` chuyển lên `EventBus.status_applied`.
  - `CharacterDef`: `link_condition`, `switch_in_cd_sec`. Dữ liệu 6 nhân vật theo bảng 8.3 (Aether Choáng 10 s, Lyra né hoàn hảo 9 s, Kael hiệu ứng nguyên tố 8 s, Seraphine HP thấp 12 s, Noctis hạ gục 11 s, Terra vũ khí/tuyệt kỹ 12 s).
  - Hồ sơ tạm `char_light_01`, `char_dark_01`, `char_earth_01` (chỉ số tạm, chưa có kỹ năng; ngoài slice Q5) để test đủ 6 điều kiện; khóa dịch `CHAR_LIGHT_01`, `CHAR_DARK_01`, `CHAR_EARTH_01` (vi + en).
  - `CombatRules`: `link_window_sec` 6.0, `link_low_hp_ratio` 0.5, `link_hp_loss_ratio` 0.25, `link_hp_loss_window_sec` 3.0, `link_bonus_ug` 15, `link_bonus_en` 10.
  - `tests/unit/party/test_link_tracker.gd` (23 test).
- **Đã chạy:** `godot --headless --import`; `tools/run_tests.ps1`; export Windows Desktop.
- **Kết quả thật:** GdUnit4 236/236 đạt (23 mới), 0 orphan, 4 test khói đạt, mã thoát 0; export mã 0. Kiểm: dữ liệu 6 nhân vật khớp bảng 8.3, đủ 6 điều kiện; SI-CD hồi sẵn lúc đầu, vào Thường bắt đầu 8 s, đếm khi dự bị, vào mặc định khi chưa hồi và không bắt đầu lại; CDR 25% → 6 s, CDR 90% bị chặn 40% → 4.8 s; cửa sổ mở đúng 6.0 s rồi đóng (5.9 s còn, 6.1 s hết), lặp lại thì làm mới không phát lại; sự kiện của người dự bị / không phải người chơi bị bỏ qua; điều kiện của chính người trên sân không mở gì; cửa sổ còn mà SI-CD chưa hồi → không sáng, vào mặc định; hai icon sáng cùng lúc, chọn một chỉ tiêu cửa sổ đó; Liên kết +10 EN +15 UG, SI-CD bắt đầu, EventBus báo "linked"; Thường không cộng; tự đổi khi gục là mặc định. Từng điều kiện: Kael (Cháy lên hình nộm do người trên sân; Nhiệt tự buff, Choáng, nguồn là người dự bị: không tính), Lyra (né hoàn hảo của người trên sân), Seraphine (HP ≤ 50%; mất 26% trong 2 s; mất 40% trải hơn 3 s thì không; HP thấp kéo dài giữ vòng sáng), Noctis (hạ gục), Terra (vũ khí, tuyệt kỹ; kỹ năng thường không), người dự bị đã gục không sáng. Trong trận thật: Aether đánh thường có Hơi Nóng áp Cháy → icon Kael sáng.
- **Lỗi tìm thấy và sửa (trong test):** SI-CD của người đang trên sân đếm theo khung vật lý chứ không theo `party.tick` → sửa kỳ vọng; lượng HP mất được ghi ở tick kế tiếp → test thêm 1 tick nhỏ; Aether vừa dịch chỗ còn đang rơi nên ra đòn trên không → chờ chạm đất.
- **Quyết định Claude chọn:**
  - Cửa sổ chỉ mở cho người **đang dự bị** lúc sự kiện xảy ra; chuyển sang ai (bất kể mức) thì cửa sổ của người đó đóng.
  - Seraphine "HP ≤ 50%" là trạng thái kéo dài: còn đúng thì cửa sổ được làm mới liên tục. Lượng mất tính tổng các lần giảm HP (hồi máu không trừ lại).
  - Kael: chỉ tính trạng thái có `counts_as_elemental` (Cháy, Chậm, Dấu Sét, Nguyền, Phán quyết, Trói, Nung chảy, Mù cát) áp lên phe khác; Choáng không tính.
  - Tự đổi khi người trên sân gục: vào mặc định, không tiêu SI-CD.
  - +15 UG của vào sân Liên kết vẫn chia 30% cho dự bị như mọi UG khác.
  - Hồ sơ tạm Seraphine HP 10000 / ATK 750, Noctis 10000 / 900, Terra 14000 / 750 / DEF 650.
- **Hạn chế đã biết:** chưa có Kĩ năng vào sân và cơ chế giảm SI-CD riêng của từng nhân vật (M4-4); chưa có phản ứng nguyên tố (M4-5); chưa có HUD vòng sáng (M4-7), nên chưa thấy được trong game.
