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
  - `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`
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

## 2026-11-12 — M4-4 Kĩ năng vào sân Thường / Liên kết / mặc định (Aether, Lyra, Kael)

- **Milestone / task:** 4 / M4-4
- **Trạng thái:** TESTED (headless). **Mốc owner chơi thử trong Godot** (đổi nhân vật, vào sân Liên kết).
- **File tạo/sửa:**
  - Dữ liệu `data/skills/{char_fire_01, char_wind_01, char_lightning_01}/switch_in.tres` (Thường) và `switch_in_linked.tres` (Liên kết), sinh bằng `tools/gen_switch_in_data.py`. Hàm sinh dùng chung tách ra `tools/skill_data_lib.py`; `gen_aether_data.py` dùng lại và **không ghi file nhân vật nữa** (file nhân vật sửa tay vì có dữ liệu Liên kết / vào sân). Chạy lại `gen_aether_data.py` ra đúng dữ liệu cũ.
  - `scripts/party/switch_in_def.gd` (`SwitchInDef`): buff bản thân khi vào sân (Thường / Liên kết) và cơ chế giảm SI-CD riêng (`reduce_on`, giây, tối đa mỗi chu kỳ, cửa sổ sau khi vào sân, ICD). Gắn vào `CharacterDef.switch_in`; Kael, Lyra có `skills_dir`.
  - `PartyManager`: chuyển xong thì chạy `switch_in` (Thường) / `switch_in_linked` (Liên kết) qua state Attack, áp buff bản thân, mở cửa sổ giảm SI-CD; nghe `EventBus.status_max_stacks` (Bùng nổ Sét) và `hit_dealt` của thành viên (Aether).
  - `SkillDef`: `approach_target`, `approach_max_px`, `approach_stop_px`, `teleport`, `target_prefer` ("stun" / "elemental"). `SkillRunner`: chọn mục tiêu có ưu tiên, quay về phía mục tiêu, lướt hoặc dịch chuyển tới nó.
  - `HitDef.bonus_vs_status(_ratio)` → Hitbox → HitInfo → `Combatant.receive_hit` (mục tiêu đang mang trạng thái thì thêm % sát thương). `HitDef.travel_angle_deg` cho vùng tách bay chéo (tên hình quạt, lật theo hướng nhìn).
  - Trạng thái mới `wind_step` (Gió Trợ Bước, +% tốc độ di chuyển) và `attack_speed_up` (+% tốc độ tấn công); `StatusDef.MAGNITUDE_MOVE_SPEED_UP/ATTACK_SPEED_UP`; `StatusController.move_speed_up()/attack_speed_up()`. PlayerController: tốc độ chạy × (1 + tăng − chậm); đòn cơ bản (normal, hold, air, landing) chạy nhanh theo tốc độ tấn công.
  - `EventBus.status_max_stacks`; `Combatant` chuyển `max_stacks_reached` lên bus.
  - `PlayerController.start_switch_in()`, `attack_speed_factor()`.
  - Debug overlay (F3): dòng đội "[người trên sân] Q: … E: …" kèm SI-CD, ✦ LIÊN KẾT còn bao lâu, (gục), chờ chung. Gợi ý phím thêm "Q/E đổi nhân vật". Khóa dịch mới (vi + en): `STATUS_WIND_STEP`, `STATUS_ATTACK_SPEED_UP`, `DEBUG_PARTY_DOWN`, `DEBUG_PARTY_LINK`.
  - `tests/unit/party/test_switch_in.gd` (21 test); `test_party_manager.gd::test_switch_keeps_position_and_facing` đổi sang vào mặc định (vào Thường thì Kael dịch chuyển tới mục tiêu); `test_combat_data.gd` thêm 2 trạng thái.
- **Đã chạy:** `godot --headless --import`; `tools/run_tests.ps1`; `python tools/gen_aether_data.py` (so diff: không đổi); `python tools/gen_switch_in_data.py`; export Windows Desktop.
- **Kết quả thật:** GdUnit4 257/257 đạt (21 mới), 0 orphan, 4 test khói đạt, mã thoát 0; export mã 0; không có SCRIPT ERROR khi debug overlay chạy trong test đội. Kiểm: dữ liệu 3 nhân vật khớp 8.5–8.7 (tổng % ATK Thường/Liên kết 130/190, 120/180, 110/160; timing; bất tử ≤ 500 ms; không tốn EN); vào Thường chạy `switch_in` và bất tử rồi hết; vào mặc định không chạy gì; Kael dịch chuyển tới hình nộm gần nhất (dừng cách 70 px), ưu tiên mục tiêu đang Cháy, Thường 1 Dấu Sét, Liên kết 2 Dấu Sét + 15% tốc độ tấn công 4 s; Bùng nổ Sét do Kael trong 5 s −1.0 s SI-CD, nguồn khác / quá 5 s không tính; Aether lướt 348 px (≤ 350) tới hình nộm, Cháy 3 s, ưu tiên mục tiêu đang Choáng, Liên kết +2 Nhiệt, hình nộm đang Choáng nhận đúng ×1.30 so với hình nộm kia, Cháy 5 s, SI-CD −1 s; giảm tối đa 3 s mỗi chu kỳ; đòn không phải vào sân hoặc mục tiêu không Choáng không tính; Lyra bắn 3 tên −15°, +15°, 0°, tên cuối Chậm 25%, Gió Trợ Bước 10% 3 s / Liên kết 25% 4 s, tốc độ chạy ×1.25 đúng; né hoàn hảo −1.5 s có ICD 3 s, tối đa 3 s, cửa sổ 4 s; tốc độ tấn công chỉ áp cho đòn cơ bản.
- **Lỗi tìm thấy và sửa:**
  - Heredoc Python qua stdin hỏng ký tự tiếng Việt khiến script sửa file lỗi giữa chừng; lệnh `gen_aether_data.py` chạy sau đó ghi đè `char_fire_01.tres` (mất `link_condition`). Đã khôi phục bằng `git checkout`, chuyển script sang file trong scratchpad, và bỏ phần ghi file nhân vật khỏi `gen_aether_data.py` để không lặp lại.
  - `@export_enum` không nhận giá trị rỗng → `reduce_on` là chuỗi thường.
- **Quyết định Claude chọn:**
  - Vào sân dùng **hai SkillDef** (`switch_in`, `switch_in_linked`); thiếu bản Liên kết thì dùng bản Thường.
  - Aether: lướt trong pha khởi động (0–220 ms), dừng cách mục tiêu 80 px; không có mục tiêu thì chém tại chỗ. Vùng chém tròn bán kính 180 tâm trước mặt 40 px.
  - Kael: dịch chuyển tức thì lúc bắt đầu, dừng cách mục tiêu 70 px; Thường 1 Dấu Sét ở nhát đầu, Liên kết mỗi nhát 1.
  - Lyra: ba tên bắn lần lượt (180, 230, 280 ms), thứ tự chếch lên −15°, chếch xuống +15°, thẳng 0° (tên cuối bay thẳng để đẩy lùi + Chậm trúng chắc). Tên bay 700 px trong 0.3 s. Chưa làm "lao xuống từ trên cao" và "vùng gió tiếp đất 160 px" (đặc tả không ghi sát thương / hiệu ứng riêng cho vùng).
  - Tốc độ tấn công chỉ tăng tốc đòn cơ bản (normal, hold, air, landing).
  - Tự đổi khi gục: vào mặc định (như M4-3).
- **Hạn chế đã biết:** chưa có animation vào sân / ra sân (dùng hình placeholder), chưa có VFX (vùng đòn hiện đa giác màu); Bùng nổ Sét (sát thương khi đủ 3 Dấu Sét) thuộc bộ kỹ năng Kael (M4-6), hiện chỉ có sự kiện để giảm SI-CD; chưa có phản ứng nguyên tố (M4-5); Kael, Lyra vẫn chưa đánh thường / né được (M4-6); HUD icon dự bị là M4-7 (tạm xem dòng đội trên debug overlay).

## 2026-11-12 — Asset: bộ phận rig Aether (chibi) từ sheet của owner

- **Milestone / task:** ngoài lộ trình (asset owner giao, chuẩn bị cho B1 hình nhân vật)
- **Trạng thái:** IMPLEMENTED (cắt xong, owner đã đặt tên 64/64 bộ phận; chưa ráp rig, chưa dùng trong game)
- **Owner quyết định (2026-11-12):** ảnh do AI tạo được đưa vào bản phát hành chính thức. Đã ghi vào `AGENTS.md` (mục "Ảnh do AI tạo": nơi lưu, quy cách, ghi nguồn, không bắt chước bên thứ ba), `docs/ASSET_LICENSES.md` mục 2.1, và việc khai báo nội dung AI khi lên store trong `docs/OWNER_ASSET_CHECKLIST.md` mục A (commit `b4054e6`).
- **File tạo/sửa:**
  - `assets/characters/char_fire_01/rig_parts/`: 64 PNG nền trong suốt `char_fire_01_part_{NN}_{loại}_{tên}.png` + `parts_manifest.json` (id, file, loại, tên, lớp gần/xa, ghi chú, vị trí trên sheet). `source/` (có `.gdignore`): sheet gốc và nhãn owner điền.
  - `assets/characters/char_fire_01/portrait/char_fire_01_portrait_full.png` (bộ phận 16, ảnh đứng toàn thân).
  - `tools/sprite_parts/segment_parts.py`, `cut_parts.py`, `README.md`.
  - `docs/ASSET_LICENSES.md` mục 2.
- **Cách làm:** tách vùng trên nền trắng (ngưỡng 190, lưới 4 px) → 64 khung đánh số → trang artifact "Bảng tên bộ phận Aether" để owner chọn loại / lớp / tên / ghi chú (lưu trong db của trang) → đọc lại → cắt: mỗi bộ phận chỉ giữ pixel của chính nó (khung chồng nhau như 44/45/46, 61/62 không lẫn), lấp vùng trắng kín bên trong, loang nền trắng từ mép, làm mềm viền JPEG, bỏ mảnh vụn < 2%.
- **Đã chạy:** các script trên; ghép thử toàn bộ PNG lên nền tối và bảng tiếp xúc 8×8 để soát bằng mắt (Claude); `godot --headless --import`; `tools/run_tests.ps1`.
- **Kết quả thật:** 64/64 PNG; bản ghép khớp sheet gốc; tests 257/257 + 4 test khói đạt, mã thoát 0.
- **Lỗi tìm thấy và sửa:** lần cắt đầu làm thủng áo sơ mi trắng (ô 4 px không thuộc vùng) → lấp lỗ; đáy áo hở ra nền nên vẫn còn vết → đổi sang chỉ loại pixel thuộc vùng của bộ phận *khác*; vài chấm lẻ cạnh 18, 22, 28 → bỏ mảnh vụn.
- **Quyết định Claude chọn:** thư mục `rig_parts/` cạnh `frames/`; tên file không dấu; ảnh đứng 16 làm chân dung toàn thân.
- **Hạn chế đã biết:** sheet là JPEG 1272×1236 nên bộ phận nhỏ (mặt ~130 px, kiếm ~380 px), viền có thể còn quầng nhạt trên nền tối; chưa có điểm khớp (pivot) cho rig; chưa ráp thành frame 384×384 cho `frames/`; chưa xác định ảnh có phải do AI tạo (nếu có, owner ghi vào ASSET_LICENSES 2.1). Splash art / màn tiêu đề chưa đổi.

## 2026-11-12 — M4-5 Phản ứng nguyên tố (15 ReactionDef + ReactionResolver)

- **Milestone / task:** 4 / M4-5
- **Trạng thái:** TESTED (headless)
- **File tạo/sửa:**
  - `scripts/party/reaction_def.gd` (`ReactionDef`: cặp nguyên tố, chế độ tâm FIRST_HIT / SELF / HIGHEST_HP, danh sách `HitDef`, tán xạ, buff bản thân, hồi đội, xóa hiệu ứng xấu), `reaction_resolver.gd` (`ReactionResolver`: nạp `data/reactions`, ICD chung 5.0 s, vùng đòn là `DetachedHit` do người vào sân gây).
  - `data/reactions/*.tres` (15 file, sinh bằng `tools/gen_reaction_data.py`) + 15 khóa dịch `REACTION_*` (vi + en).
  - `PartyManager`: vào sân Liên kết → chuẩn bị phản ứng của cặp (người rời, người vào); nổ tại kẻ địch đầu tiên trúng Kĩ năng vào sân; Thanh Phong / Thánh Giáp nổ ngay tại người vào sân; trượt thì không nổ và không tốn ICD. Phát `EventBus.reaction_triggered`.
  - `HitFeedback` + `scripts/ui/reaction_fx.gd`: hit-stop 60 ms, hai quả cầu màu va nhau 0.3 s, tên phản ứng 0.8 s.
  - Cơ chế mới: `HitDef.pull_to_origin` (kéo về tâm, không quá tâm); `HitInfo.boss_control_multiplier` (khống chế / Chậm lên boss ×0.5; trạng thái có hệ số boss riêng thì dùng hệ số đó; `root` boss ×0.4 → 2.0 s còn 0.8 s); khiên thật (`ResourceComponent.shield`, hấp thụ trước máu, vỡ thì mất trạng thái, hết hạn thì mất khiên); `burn` nhận `tick_bonus` (Thiêu Hồn: tick gấp đôi); `DetachedHit.spawn(..., extra_delay_sec)`.
  - `CombatRules`: `reaction_icd_sec` 5.0, `reaction_boss_control_multiplier` 0.5. `HitFeedbackConfig`: `reaction_hitstop_ms` 60, `reaction_name_sec` 0.8, `reaction_orb_sec` 0.3.
  - `tests/unit/party/test_reactions.gd` (21 test).
- **Đã chạy:** `godot --headless --import`; `python tools/gen_reaction_data.py`; `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 278/278 đạt, 4 test khói đạt, mã thoát 0. Kiểm: đủ 15 cặp, không thiếu, không trùng, đối xứng, có bản dịch; tổng % ATK khớp bảng 8.4; ICD 5.0 s chặn cả phản ứng khác; Liên kết + trúng → nổ đúng cặp tại kẻ địch đầu tiên, có sự kiện và tên hiện; vào Thường không nổ; Liên kết mà trượt không nổ, không tốn ICD; Thanh Phong nổ ngay, hồi 8% HP cả đội (kể cả dự bị), xóa 1 hiệu ứng xấu; sát thương theo ATK người vào sân (1000/950); Hỏa Lốc Cháy 5 s cả hai hình nộm; Thiêu Hồn tick 16%; Dung Nham 1 nổ + 6 nhịp, Chậm 30% chỉ khi còn vùng; Bão Sét 4 tia trễ 0/0.3/0.6/0.9 s trong ±400 px; Thần Phạt chỉ đánh mục tiêu HP cao nhất, Phán quyết 6 s; Thánh Giáp khiên 12% hấp thụ rồi vỡ, hết hạn sau 6 s; Lốc Oán kéo ~120 px về tâm, không vượt tâm; boss: Chậm 3 s → 1.5 s, Trói 2.0 s → 0.8 s, Nguyền không đổi.
- **Lỗi tìm thấy và sửa (trong test):** slime bị chặn bởi bậc địa hình ở x ≈ 1591 và đuổi người chơi giữa các nhịp kéo → chuyển sang sàn phẳng, đo ngay sau nhịp đầu.
- **Quyết định Claude chọn:** vùng kéo dài (lửa thánh, dung nham) bắt đầu 0.1 s sau cú nổ, 6 nhịp; Chậm trong vùng là Chậm 0.7 s được làm mới mỗi nhịp; Bão Sét tán xạ theo trục ngang, bán kính mỗi tia 110 px; hướng đẩy của Quá Tải theo hướng nhìn người vào sân; "xóa 1 hiệu ứng xấu" ưu tiên khống chế; vào sân mà phản ứng còn ICD thì bỏ qua (không xếp hàng).
- **Hạn chế đã biết:** hiển thị là hình tạm (hai vòng tròn màu + chữ); Seraphine, Noctis, Terra chưa có Kĩ năng vào sân nên 12 cặp có họ chỉ test được qua resolver; phản ứng với trạng thái sẵn có trên kẻ địch để sau (mục 8.11).

## 2026-11-12 — M4-6 Kael, Lyra: đòn thường, né (Q5)

- **Milestone / task:** 4 / M4-6
- **Trạng thái:** TESTED (headless)
- **File tạo/sửa:**
  - `data/skills/char_lightning_01/normal_1..5.tres`, `dodge.tres`; `data/skills/char_wind_01/normal_1..3.tres`, `dodge.tres` (sinh bằng `tools/gen_kael_lyra_data.py`).
  - `scripts/characters/kits/lightning_kit.gd` + config + `data/characters/char_lightning_01_kit.tres`: Bùng nổ Sét (đủ 3 Dấu Sét do Kael gây: 150% bán kính 140, SC ×2, xóa dấu, ICD 4 s mỗi mục tiêu, +10% tốc độ tấn công 3 s, −1 s CD vũ khí), Sét Phản khi né hoàn hảo (80% bán kính 150 tại điểm xuất phát, 2 Dấu Sét).
  - `scripts/characters/kits/wind_kit.gd` + config + `data/characters/char_wind_01_kit.tres`: né hoàn hảo → Gió Trợ Bước +25% 3 s, +5 EN.
  - `HitDef.max_targets` (tên thường dừng ở mục tiêu đầu, tên xuyên 2) → `Hitbox`.
  - `SkillRunner`: kỹ năng `teleport` không nhắm mục tiêu dịch chuyển một lần tại `move_from_ms` (né Kael), dùng `move_and_collide` nên dừng ở tường.
  - `tests/unit/combat/test_kael_lyra.gd` (12 test).
- **Đã chạy:** `python tools/gen_kael_lyra_data.py`; `godot --headless --import`; `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 290/290 đạt, 4 test khói đạt, mã thoát 0. Kiểm: Kael 5 đòn 45/45/55/55/110 = 310%, Dấu Sét ở đòn 2, 4, 5, đòn 5 đẩy 80 px, timing 70/50/110 và 130/90/260; chuỗi 5 đòn chạy liền, đủ 3 dấu thì nổ và xóa dấu, Kael +10% tốc độ tấn công; ICD 4 s theo từng mục tiêu; dấu do nguồn khác không nổ; né dịch chuyển đúng 320 px ra sau lưng hình nộm, bất tử, tia điện trúng mục tiêu trên đường; Sét Phản áp 2 dấu. Lyra 3 phát 55/55/90 = 200%, tên 1800 px/s tầm 700 (ngoài tầm thì trượt), phát 1–2 dừng ở mục tiêu đầu, phát 3 xuyên 2 và Chậm 20% 2 s; né lùi 240 px, vẫn nhìn về trước, tên 40% trúng; né hoàn hảo +25% tốc độ 3 s, +5 EN.
- **Lỗi tìm thấy và sửa:** cửa sổ lướt 30 ms của né Kael ngắn hơn hai khung hình nên chỉ đi được ~177 px → dịch chuyển tức thì một lần; tia điện của né đặt sai phía (trước mặt sau khi dịch chuyển) → nối từ điểm đến về điểm xuất phát.
- **Quyết định Claude chọn:** làm luôn Bùng nổ Sét và hiệu ứng né hoàn hảo dù Q5 chỉ ghi "đòn thường, né" (không có thì Dấu Sét vô nghĩa); cửa sổ nối đòn Kael 180 ms, Lyra 200 ms; Kael đi xuyên kẻ địch khi tiến đòn (quái không chặn đường, như M3-6).
- **Hạn chế đã biết:** tên Lyra bay thẳng ngang, chưa tự nhắm ±25°; chuỗi Kael reset sau 0.8 s (đặc tả 0.7 s; hằng số chung của SkillRunner); Lyra chưa lùi nửa bước mỗi phát; nội tại Gió Thuận, đòn giữ / trên không / kỹ năng / tuyệt kỹ của Kael và Lyra ngoài slice Q5.

## 2026-11-12 — M4-7 HUD icon dự bị (HP, vòng SI-CD, vòng sáng Liên kết)

- **Milestone / task:** 4 / M4-7. **Milestone 4 hoàn tất.**
- **Trạng thái:** TESTED (headless) + Claude đã xem một ảnh chụp màn thử nghiệm. **Mốc owner chơi thử trong Godot** (đổi 3 nhân vật, vòng sáng, phản ứng).
- **File tạo/sửa:**
  - `scripts/ui/hud_theme.gd` (`HudTheme`: vị trí, kích thước, màu, thời gian HUD gom một chỗ; token màu vòng README 17.5).
  - `scripts/ui/reserve_icon.gd` (`ReserveIcon`, 160 px ≥ 140): chân dung (ảnh `portrait/{id}_portrait_full.png` nếu có, không thì vòng màu + chữ cái), thanh HP nhỏ, quạt hồi SI-CD + số giây, vòng sáng Liên kết (hiện 150 ms, nhịp 0.8 s phóng 1.0→1.12 sáng 0.6→1.0, 3 hạt quay, cung mỏng co theo 6.0 s, mờ 300 ms khi hết, nổ 200 ms khi dùng), trạng thái gục; chạm / click để chuyển.
  - `scripts/ui/battle_hud.gd` (`BattleHud`): thẻ nhân vật trên sân góc trên-trái (tên, HP + khiên, EN, UG, lượt né) + 2 icon dự bị góc trên-phải.
  - Màn thử nghiệm tạo BattleHud, ẩn hai nút `switch_1/2` của lớp cảm ứng (icon thay thế); debug overlay dời xuống dưới thẻ nhân vật.
  - `tools/screenshot_stage.gd`: chụp ảnh màn thử nghiệm ra `build/screenshots/` (cần cửa sổ).
  - `tests/unit/ui/test_battle_hud.gd` (14 test).
- **Đã chạy:** `godot --headless --import`; `tools/run_tests.ps1`; `godot --path . --resolution 1280x720 -s tools/screenshot_stage.gd`.
- **Kết quả thật:** GdUnit4 304/304 đạt, 4 test khói đạt, mã thoát 0. Ảnh chụp: thẻ Kael (6825/10500), icon Aether có chân dung thật + vòng đỏ cam + cung đếm ngược, icon Lyra chữ "L" xanh ngọc + thanh HP 40%; dòng debug "Q: Aether ✦ LIÊN KẾT 5.6s". Test: hằng số khớp 17.5; 2 icon ≥ 140 px, không chồng nhau, sát góc trên-phải; icon theo thứ tự dự bị; HP và trạng thái gục; tỉ lệ quạt SI-CD; vòng hiện đủ sau 150 ms, nhịp và cung đúng, mờ hết sau 300 ms; cửa sổ còn mà SI-CD chưa hồi thì không sáng; hai icon sáng cùng lúc; dùng Liên kết nổ 200 ms, Thường thì không; chạm / click icon thì chuyển; chạm người đã gục bị từ chối.
- **Quyết định Claude chọn:** icon 1 (Q) bên trái, icon 2 (E) sát mép phải; chân dung cắt 42% phần trên của ảnh đứng; thanh khiên là vạch xanh nhạt dưới thanh HP.
- **Hạn chế đã biết:** chưa có âm thanh khi vòng sáng bật (M7, chờ SFX); nút kỹ năng có vòng hồi và nút Pause là M7; gợi ý phím của debug overlay dài, đè lên icon ở cửa sổ hẹp (chỉ bản debug, F3 để ẩn); nhãn hai hình nộm chồng chữ nhau (có từ M3).

## 2026-11-12 — M5-1 SaveService (version, migration, backup, checksum)

- **Milestone / task:** 5 / M5-1
- **Trạng thái:** TESTED (headless)
- **File tạo/sửa:** `scripts/save/save_schema.gd` (`SaveSchema` v2: nhân vật, đội, kho, tiền, gacha, tiến độ, cài đặt, thống kê; chuỗi migration; `sanitize`), `save_store.gd` (`SaveStore`: `user://saves/save.json` + `save.bak.json`, ghi qua file tạm, checksum SHA-256, đọc chính → backup → mặc định, giữ bản hỏng `save.corrupt.json` và bản của phiên bản mới hơn `save.newer.json`), `save_service.gd` (autoload thứ 5 `SaveService`: `data`, `load_game`, `save_game`, `new_game`, `delete_save`, `get_value/set_value`); `project.godot`; màn Title (Tiếp tục bật khi có save, Game mới tạo save); `tests/smoke/m1_flow_check.gd` (thêm luồng save); `tests/unit/save/test_save_store.gd` (14 test).
- **Đã chạy:** `godot --headless --import`; `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 318/318, 4 test khói đạt, mã thoát 0. Kiểm: chưa có save → mặc định, không tạo file; ghi rồi đọc giữ nguyên cấp, EXP, trang bị, vàng, nguyên liệu, pity, lịch sử, tiến độ, ngôn ngữ; file có version + checksum, không để lại file tạm; lần ghi sau giữ bản trước làm backup; file chính hỏng → lấy backup; sửa tay số vàng → sai checksum → mặc định, giữ bản hỏng; 9 kiểu file rác không crash; file chính hỏng không đè lên backup tốt; save v1 migrate lên v2 (vàng/ngọc vào `currencies`); save version mới hơn được để riêng nguyên vẹn; `sanitize` sửa kiểu sai, bỏ nhân vật không sở hữu khỏi đội, không cho tiền âm; lịch sử chiêu mộ giới hạn 200 mục.
- **Quyết định Claude chọn:** phần `data` lưu dạng chuỗi JSON bên trong phong bì để checksum ổn định; khi chạy headless (test) SaveService dùng `user://saves_headless` để không đụng save thật; Game mới giữ lại cài đặt; nhân vật khởi đầu là Aether, Kael, Lyra; có sẵn một migration thật v1 → v2 để chuỗi migration được test.
- **Hạn chế đã biết:** chưa tự lưu định kỳ (gọi `save_game()` ở các mốc: M5-2 trở đi); checksum chỉ chống hỏng file và sửa tay đơn giản, không phải chống gian lận; cài đặt ngôn ngữ trong save chưa được áp khi khởi động (M7).

## 2026-11-12 — M5-2 Cấp, EXP, tài nguyên + M5-3 Kho đồ, trang bị

- **Milestone / task:** 5 / M5-2, M5-3
- **Trạng thái:** TESTED (headless). Chưa có màn hình UI (M7).
- **File tạo/sửa:** `scripts/progression/`: `progression_rules.gd` (+ `data/config/progression.tres`), `item_def.gd` (+ 5 file `data/items/`), `equipment_def.gd` (+ 6 file `data/equipment/`, 3 ô weapon / armor / accessory), `def_library.gd`, `inventory.gd` (`Inventory`: tiền, nguyên liệu, trang bị, mặc / tháo / chuyển, cường hóa), `progression.gd` (`Progression`: EXP, lên cấp, dùng sách EXP, mở khóa nhân vật, `stats_for`), `player_profile.gd` (`PlayerProfile`: gom lại trên dữ liệu save, đặt đội, nhận thưởng); `tools/gen_item_data.py`; khóa dịch `ITEM_*`, `EQUIP_*`, `CURRENCY_*`, `SLOT_*`; `PlayerController.stats_override`, `PartyManager.stats_provider`, màn thử nghiệm nhận `stats_provider`; `tests/unit/progression/test_progression_inventory.gd` (18 test).
- **Đã chạy:** `python tools/gen_item_data.py`; `godot --headless --import`; `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 336/336, 4 test khói đạt, mã thoát 0. Kiểm: đường EXP 100 × L^1.5; lên nhiều cấp một lần và giữ phần dư; chạm cấp tối đa thì bỏ phần thừa; sách EXP trừ sách + vàng, thiếu thì không trừ gì; tiền không âm, tiêu thiếu bị từ chối; mặc / thay / chuyển trang bị giữa nhân vật; xóa món đang mặc thì tháo; cường hóa trừ vàng + nguyên liệu, tới cấp 10 thì dừng; cấp 1 không đồ = chỉ số gốc; cấp 11 + 3 món ra đúng công thức; món trong save không còn tồn tại thì bỏ qua; đội trong màn chơi dùng chỉ số theo hồ sơ (Aether cấp 11: ATK 1600, HP 19200); đặt đội hợp lệ; nhận thưởng trả bản tóm tắt; mọi thay đổi còn sau khi lưu rồi đọc.
- **Quyết định Claude chọn (số khởi điểm, owner chỉnh trong data):** cấp tối đa 50; EXP lên cấp = 100 × L^1.5; mỗi cấp +6% HP, +6% ATK, +5% DEF; 0.2 vàng mỗi điểm EXP; trang bị 3 ô, cường hóa tối đa +10, mỗi cấp +10% phần cộng thẳng, phí = (200 vàng, 100 điểm) × độ hiếm × (cấp + 1); vũ khí là "lõi vũ khí" cộng chỉ số (loại vũ khí cố định theo OD-5); sách EXP 100 / 500 / 2000; quặng 50 điểm, tinh thể 250 điểm.
- **Hạn chế đã biết:** chưa có UI nhân vật / trang bị (M7); chưa có nhiệm vụ (quests) và điều kiện mở khóa; cấp kỹ năng (hệ số 6% mỗi cấp đã có trong DamageCalculator) chưa có cách nâng.

## 2026-11-12 — M5-4 Chiêu mộ: logic xong, dữ liệu banner vẫn BLOCKED

- **Milestone / task:** 5 / M5-4
- **Trạng thái:** logic TESTED (headless); **dữ liệu BLOCKED** — chưa có banner nào trong `data/banners/` vì tỉ lệ thật chờ owner (OWNER_ASSET_CHECKLIST mục A1). Không tự đặt số cho game.
- **File tạo/sửa:** `scripts/gacha/gacha_tier_def.gd` (`GachaTierDef`: tỉ lệ gốc, pity cứng, pity mềm, pool `char:` / `equip:` / `item:`, rate-up, bảo hiểm sau khi trượt, đổi nhân vật trùng), `banner_def.gd` (`BannerDef`: các bậc từ hiếm xuống thường, giá đơn / gói, nhóm pity dùng chung, `validate`), `gacha_service.gd` (`GachaService`: kiểm tra tiền → quay → trao thưởng → lịch sử; `rates_table` sinh bảng hiển thị từ cùng config; `pity_count`, `is_guaranteed`); `tests/unit/gacha/test_gacha_service.gd` (15 test, banner chỉ dựng trong test).
- **Đã chạy:** `godot --headless --import`; `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 351/351, 4 test khói đạt, mã thoát 0. Kiểm (với banner test 5★ 2% / 4★ 10%): config sai bị từ chối (tổng > 100%, rate-up ngoài pool, pool rỗng, sai thứ tự, sai dạng); chưa có banner nào được ship; bảng tỉ lệ cộng đúng 100% và khớp config; giá đơn / gói; thiếu tiền hoặc số lượt lạ thì không đổi gì; cùng seed ra cùng kết quả; 30 000 lượt không pity ra 2% / 10% / 88% trong sai số; pity cứng không bao giờ vượt 50 (5★) và 10 (4★), ra đúng lượt 50 rồi về 0; pity mềm tăng đúng từng lượt; rate-up 50% + bảo hiểm → trượt thì lần sau chắc chắn trúng, dài hạn 2/3; cờ bảo hiểm lưu và xóa đúng; banner cùng nhóm dùng chung pity; trao nhân vật / trang bị / nguyên liệu, nhân vật trùng đổi nguyên liệu; lịch sử đủ trường, giới hạn 200, còn nguyên sau khi lưu và đọc.
- **Quyết định Claude chọn (thuật toán, không phải số):** pity của một bậc = số lượt kể từ lần ra đúng bậc đó; nhiều bậc cùng chạm pity cứng thì bậc hiếm hơn được ưu tiên; bậc thấp nhất nhận phần tỉ lệ còn lại; chỉ cho quay 1 lượt hoặc đúng gói `multi_count`.
- **Còn chờ owner:** trả lời 6 câu ở OWNER_ASSET_CHECKLIST mục A1 (số bậc và tỉ lệ, pity cứng / mềm, pity bậc hai, rate-up và bảo hiểm, pity có chuyển giữa banner không, giá). Có số thì chỉ cần thêm file `data/banners/*.tres`; nếu luật của owner khác thuật toán trên (vd ra 5★ thì reset cả pity 4★) sẽ chỉnh `GachaService`.
- **Hạn chế đã biết:** chưa có màn Chiêu mộ (M7); chưa có nguồn kiếm ngọc ngoài phần thưởng màn (M6).

## 2026-11-12 — Milestone 6: màn đầu, boss 2 pha, phần thưởng, màn kết quả

- **Milestone / task:** 6 (cả milestone). **Mốc owner chơi thử trong Godot** (chơi hết màn đầu và boss).
- **Trạng thái:** TESTED (headless) + Claude đã xem một ảnh chụp đấu trường boss. Chưa ai chơi hết màn bằng tay, nên **thời lượng 3–5 phút và độ khó chưa được kiểm chứng**.
- **File tạo/sửa:**
  - Boss: `scripts/enemies/boss_def.gd` (`BossDef`), `boss_phase_def.gd`, `boss_controller.gd` (`BossController` kế thừa `EnemyController`: bộ đòn theo pha, chuyển pha khi HP ≤ ngưỡng, đứng yên + bất tử `phase_transition_sec`), `data/enemies/boss_golem_01.tres` (sinh bằng `tools/gen_boss_data.py`), `scenes/enemies/boss_golem.tscn`. `EnemyController`: điểm mở rộng `_skill_table/_next_attack_key/_attack_range/_attack_cooldown/_move_speed`, vẽ vùng đòn trong pha báo hiệu (đậm dần).
  - Màn: `scripts/world/stage_controller.gd` (`StageController`: đợt quái khóa sân bằng tường vô hình + giới hạn camera, checkpoint, đấu trường boss, hoàn thành / thất bại, trao thưởng qua `PlayerProfile.grant`, ghi tiến độ và lưu), `StageMap` (ký tự `C`, `data`, `ground_feet`, `col_x`), `data/stages/stage_01.json` (sinh bằng `tools/gen_stage_01.py`: 200×17 ô, 3 đợt 3/4/5 slime, 3 checkpoint, boss), `scripts/world/parallax_backdrop.gd` (3 lớp đồi tạm), `scenes/stages/stage.tscn`.
  - UI: `scripts/ui/stage_hud.gd` (mục tiêu, đồng hồ, thông báo, thanh máu boss có vạch pha + thanh SC), `scripts/ui/result_screen.gd` (thắng / thua, thời gian, thưởng, thưởng lần đầu, lên cấp, nút Chơi lại / Về Hub).
  - `GameConfig.SCENE_STAGE`, `selected_stage_id`; Hub tab Chiến đấu có nút "Màn 1"; 20 khóa dịch mới (`tools/add_locale_keys.py`).
  - Test: `tests/unit/enemies/test_boss.gd` (8), `tests/unit/world/test_stage_controller.gd` (10). `tools/screenshot_boss.gd`.
- **Đã chạy:** `godot --headless --import`; `tools/run_tests.ps1`; `godot --path . -s tools/screenshot_boss.gd`.
- **Kết quả thật:** GdUnit4 369/369, 4 test khói đạt, mã thoát 0. Boss: dữ liệu hợp lệ, mọi đòn báo hiệu ≥ 400 ms (đo thật ≥ 24 khung trước khi trúng), không khựng, HP 51% chưa chuyển pha / 49% chuyển đúng một lần, bất tử và đứng yên 1.2 s, pha 2 chỉ dùng đòn pha 2, chết phát `enemy_defeated`. Màn: dữ liệu đúng yêu cầu (3 đợt, checkpoint, boss sau cùng); đội và chỉ số lấy từ save; đợt 1 kích hoạt ở cột 16, 3 slime, camera khóa cột 8–44, tường chặn người chơi, hạ hết thì mở; rơi hố về checkpoint gần nhất; boss có thanh máu; hạ boss → thưởng 1200 vàng + 600 EXP, lần đầu thêm 300 ngọc + 1 trang bị, tiến độ và kỷ lục ghi ra file; lần hai không có thưởng lần đầu, giữ kỷ lục cũ; cả đội gục → thất bại, không thưởng; màn kết quả hiện đúng dòng.
- **Lỗi tìm thấy và sửa:** ảnh chụp cho thấy đồng hồ đè lên tên boss và thanh máu boss chạm thẻ nhân vật → dời và thu thanh.
- **Quyết định Claude chọn (số khởi điểm, owner chỉnh trong data):** boss Golem HP 60 000 / ATK 600 / DEF 400 / SC 1000, pha 2 ở 50% (nhanh hơn 35%, thêm Địa chấn hai phía); boss ra đòn lần lượt theo danh sách; 3 đợt 3 / 4 / 5 slime; thưởng màn và thưởng lần đầu như trên; rơi hố không mất máu; thất bại không có thưởng an ủi.
- **Hạn chế đã biết:** chỉ có một loại quái thường (slime) và một boss; chưa có màn chọn màn / chọn đội (M7); Esc giữa màn về Hub mà không hỏi lại; chưa có nhạc, âm thanh; hình vẫn là placeholder; nền parallax là đồi đa giác tạm.

## 2026-11-12 — M7-1 Tạm dừng, Cài đặt, Credits, AudioRouter, safe area

- **Milestone / task:** 7 / phần 1
- **Trạng thái:** TESTED (headless). Chưa ai nhìn các màn này bằng mắt.
- **File tạo/sửa:** `scripts/core/audio_router.gd` (autoload `AudioRouter`: bus Music / SFX, âm lượng, `play_sfx` / `play_music` theo ID, thiếu file thì bỏ qua và ghi vào `missing`); `scripts/ui/ui_kit.gd` (`UiKit`: dựng control, `safe_margins`, `apply_safe_area`, `autoload`); `settings_panel.gd` (`SettingsPanel`: ngôn ngữ, 3 âm lượng, toàn màn hình; áp ngay và lưu); `credits_panel.gd` + `data/credits.json`; `pause_menu.gd` (`PauseMenu`: dừng cây scene, Tiếp tục / Cài đặt / Thoát có xác nhận, tự mở khi mất focus); `SceneRouter` hỏi nhóm `back_interceptor` trước khi quay lại; `SaveService` áp cài đặt đã lưu lúc khởi động (`--lang=` vẫn được ưu tiên); `SaveSchema.settings.fullscreen`; Title có nút Cài đặt; `BattleHud` có nút Pause (132 px, mép trái, xa icon dự bị) và áp lề an toàn; `stage.tscn` có PauseMenu; 21 khóa dịch; `tests/unit/ui/test_settings_pause.gd` (12 test).
- **Đã chạy:** `godot --headless --import`; `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 381/381, 4 test khói đạt, mã thoát 0. Kiểm: đổi ngôn ngữ áp ngay, ghi file, đọc lại đúng; thanh trượt điều khiển đúng bus, 0 = tắt tiếng, chặn 0..1; áp cài đặt từ dữ liệu đã lưu; bus Music / SFX gửi về Master; ID âm thanh chưa có file trả về false, không lỗi; tạm dừng dừng cây và tiếp tục khôi phục; Back đi từng bước (xác nhận → menu → tiếp tục); thoát phải qua bước xác nhận; màn kết quả thì không tạm dừng được; nút Pause ≥ 128 px, không chồng icon dự bị; Credits có PROJECT ECLIPSE, pixelfx (MIT), giấy phép Godot; lề an toàn quy đổi đúng theo khung thiết kế.
- **Quyết định Claude chọn:** nút Pause ở mép trái dưới thẻ nhân vật; Esc trong màn chơi mở Tạm dừng thay vì thoát thẳng; đổi ngôn ngữ ở Title thì dựng lại scene.
- **Hạn chế đã biết:** chưa có file âm thanh nào (AudioRouter im lặng; owner giao theo checklist mục D); chưa có tùy chọn đổi vị trí icon dự bị và chế độ joystick cố định (OD-6, README 15.6); lề an toàn mới áp cho HUD trận, chưa áp cho mọi màn menu; màn thử nghiệm cũ không có Tạm dừng.

## 2026-11-12 — M7-2 Các màn trong Hub: Home, Chiến đấu, Nhân vật, Chiêu mộ, Cài đặt

- **Milestone / task:** 7 / phần 2
- **Trạng thái:** TESTED (headless) + Claude đã xem ảnh chụp 3 tab (Nhân vật, Chiến đấu, Cài đặt). Chưa ai bấm thử bằng tay.
- **File tạo/sửa:** `scripts/ui/hub_panel.gd` (`HubPanel`: lớp cha, giữ `PlayerProfile` trên dữ liệu save, `refresh` / `commit` có lưu), `hub_home_panel.gd` (tiền, đội, số màn đã qua), `hub_battle_panel.gd` (chọn đội 1–3 theo thứ tự bấm, danh sách màn kèm trạng thái và kỷ lục), `hub_characters_panel.gd` (cấp, EXP, chỉ số, dùng sách EXP, đổi / cường hóa / tháo trang bị, dòng lý do khi thất bại), `hub_recruit_panel.gd` (banner trong `data/banners`, bảng tỉ lệ lấy từ `GachaService.rates_table`, quay 1 / gói, kết quả, lịch sử; chưa có banner thì báo "chưa mở"), `hub.gd` (vùng nội dung theo tab; tab Cài đặt = `SettingsPanel` + `CreditsPanel`; tab đang mở được đánh dấu); 29 khóa dịch; `tests/unit/ui/test_hub_panels.gd` (11 test); `tests/smoke/m1_i18n_check.gd` (đọc chữ của bảng mới); `tools/screenshot_hub.gd`.
- **Đã chạy:** `godot --headless --import`; `tools/run_tests.ps1`; `godot --path . -s tools/screenshot_hub.gd` (2 lần).
- **Kết quả thật:** GdUnit4 392/392, 4 test khói đạt, mã thoát 0. Kiểm: mỗi tab hiện đúng bảng; Home tóm tắt đúng; đội: bỏ / thêm đổi thứ tự, không bỏ được người cuối, không quá 3, lưu ra file; danh sách màn ẩn màn thử nghiệm, hiện kỷ lục 3:20; dùng sách EXP lên cấp và trừ vàng, lưu; thao tác thất bại hiện lý do và không đổi gì; đổi món xoay vòng, cường hóa +1, tháo thì chỉ số về gốc; Chiêu mộ chưa có banner thì báo chưa mở; với banner test, bảng tỉ lệ đúng số trong config (25% / 75%), thiếu ngọc bị từ chối, quay gói 10 trừ đúng 900 ngọc và lưu lịch sử.
- **Lỗi tìm thấy và sửa (nhờ ảnh chụp):** thanh tab không cho biết đang ở tab nào → nút tab giữ trạng thái nhấn. Công cụ chụp ảnh đặt dữ liệu mẫu quá sớm nên bị SaveService ghi đè → đặt ở khung đầu tiên.
- **Quyết định Claude chọn:** chọn đội bằng cách bấm bật / tắt từng nhân vật; "Đổi món" xoay vòng qua các món cùng ô trong kho (chưa có danh sách chọn); "Cường hóa" tự dùng nguyên liệu cường hóa đầu tiên đủ số lượng.
- **Hạn chế đã biết:** giao diện là control mặc định của Godot, chưa có theme / art; chưa có danh sách kho đồ riêng, chưa có màn chọn màn tách khỏi tab Chiến đấu (mới có 1 màn); Chiêu mộ chưa dùng được cho tới khi owner cho tỉ lệ; đổi ngôn ngữ trong Hub thì nhãn dựng bằng code ở tab khác chỉ đổi khi mở lại tab.

## 2026-11-12 — M7-3 Nút kỹ năng cảm ứng có vòng hồi + âm thanh theo sự kiện

- **Milestone / task:** 7 / phần 3. **Milestone 7 xong phần code**; phần chờ asset (font, nhạc, SFX, art UI) ghi ở "Hạn chế".
- **Trạng thái:** TESTED (headless). Chưa thử trên màn hình cảm ứng thật (Android hoãn).
- **File tạo/sửa:** `scripts/input/touch_button.gd` (quạt hồi chiêu + số giây, vòng nạp UG sáng khi đầy, mờ khi chưa dùng được, `set_state`); `scripts/input/touch_controls.gd` (`party`, `button_state()` đọc hồi chiêu / EN / UG / lượt né của người trên sân); `scripts/core/audio_router.gd` (bảng sự kiện từ `data/config/audio_events.json`, nghe EventBus: trúng đòn, bị đánh, hạ / Choáng địch, đổi nhân vật, vòng Liên kết sáng, phản ứng, tuyệt kỹ, nhạc theo scene; chống phát chồng 40 ms; `requested`); `StageController` (nhạc boss, tiếng qua màn / thất bại); `docs/OWNER_ASSET_CHECKLIST.md` mục D1 (tên file âm thanh đang chờ); `tests/unit/ui/test_touch_audio.gd` (10 test).
- **Đã chạy:** `godot --headless --import`; `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 402/402, 4 test khói đạt, mã thoát 0. Kiểm: nút kỹ năng sẵn sàng → hồi đủ vòng "6" → còn 1/4 vòng "2" → sẵn sàng; thiếu EN thì mờ (25 / 35 EN); nút tuyệt kỹ vòng 40% rồi đầy và sáng; nút né hiện số lượt, hết lượt thì mờ; đổi sang Kael thì nút kỹ năng / vũ khí / tuyệt kỹ mờ, né vẫn dùng được; `TouchControls` cập nhật nút thật; bảng âm thanh đủ 11 sự kiện + 4 nhạc; mỗi sự kiện yêu cầu đúng ID, đòn chí mạng và bị đánh có tiếng riêng, hai đòn cùng lúc không phát chồng; đổi scene yêu cầu đúng nhạc, scene lạ giữ nhạc cũ.
- **Quyết định Claude chọn:** âm thanh gắn qua EventBus (logic game không gọi AudioRouter, trừ StageController cho nhạc boss và kết quả màn); tên file theo bảng D1.
- **Hạn chế đã biết (Milestone 7):** chưa có file âm thanh, font riêng, art UI: mọi thứ dùng control và font mặc định của Godot; chưa có tiếng nút UI; chưa có tùy chọn đổi vị trí icon dự bị / joystick cố định; lề an toàn mới áp cho HUD trận; điều khiển cảm ứng chưa thử trên máy thật.

## 2026-11-12 — Milestone 8: QA và chuẩn bị phát hành (phần làm được không cần owner)

- **Milestone / task:** 8
- **Trạng thái:** TESTED. Các mục cần owner (chơi thử bằng tay, Android, asset, tỉ lệ chiêu mộ, đổi tên nhân vật) để `NOT RUN` / `BLOCKED`.
- **File tạo/sửa:** `tests/smoke/m8_playthrough_check.gd` (chơi xuyên suốt theo README 16 bằng input giả lập, 38 bước); `docs/ACCEPTANCE_TESTS.md` (trạng thái + bằng chứng cho từng tiêu chí); `docs/KNOWN_ISSUES.md` (9 việc chờ owner, 14 hạn chế trong code, 3 mục đã soát không phải lỗi); `AGENTS.md` (autoload mới, tài liệu mới, quy ước `UiKit.autoload`, cảnh báo heredoc tiếng Việt); `scripts/ui/result_screen.gd` (sửa lỗi dưới).
- **Đã chạy:** `tools/run_tests.ps1`; `godot --headless --path . --editor --quit`; export Windows Desktop + chạy `ProjectEclipse.console.exe --headless`.
- **Kết quả thật:** GdUnit4 402/402, 5 test khói đạt (thêm `m8_playthrough_check` 38/38), mã thoát 0; editor headless mã thoát 0, log sạch; export mã 0, bản build khởi động không lỗi script. Nghiệm thu: 31 tiêu chí PASS (một số ghi rõ "auto" hoặc "một phần"), AT-PLT-01/02/03 NOT RUN, chiêu mộ với banner thật BLOCKED.
- **Lỗi tìm thấy và sửa:** nút "Về Hub" ở màn kết quả dùng giá trị trả về của `SceneRouter.go_back()` (hàm bất đồng bộ) trong điều kiện → SCRIPT ERROR "async function without await" (vẫn về được Hub nhưng nhánh dự phòng không chạy đúng). Đổi sang hỏi `can_go_back()` trước. Test khói mới bắt được lỗi này; test đơn vị thì không vì không bấm nút.
- **Chưa làm được (ghi trong KNOWN_ISSUES):** Claude không chơi game bằng tay và không có máy Android; bản Release chưa build thử (preset loại placeholder, cần art thật).

## 2026-11-13 — Chiêu mộ theo số của owner, trang bị 1 vũ khí + 3 vết thánh, cấp đội trưởng, mảnh / tiến cấp, cấp kỹ năng

- **Milestone / task:** 5 (M5-2, M5-3, M5-4) — làm lại theo yêu cầu owner 2026-11-12
- **Trạng thái:** TESTED (headless)
- **Owner quyết định:** trả lời 6 câu gacha (OWNER_ASSET_CHECKLIST A2); trang bị đổi thành 1 vũ khí + 3 vết thánh Đầu / Thân / Chân (vết thánh có ảnh minh họa, không đổi ngoại hình nhân vật).
- **File tạo/sửa:**
  - Gacha: `GachaTierDef` (`tier_id`, `label_key`, `soft_pity_mode` "flat", `duplicate_fragments`, phần thưởng `gold:N`), `BannerDef` (`multi_guarantee_tiers` / `multi_guarantee_pick`, `tier()`, cho phép 2 bậc cùng số sao), `GachaService` (bảo đảm khi quay gói, pity theo khóa bậc, mảnh khi trùng); `tools/gen_banner_data.py` → `data/banners/banner_char_kael.tres`; bảng tỉ lệ trong tab Chiêu mộ hiện tên bậc và dòng bảo đảm 10 lượt.
  - Trang bị: `EquipmentDef.SLOTS` = weapon / stigma_top / stigma_mid / stigma_bot, `weapon_type`, `art`; `CharacterDef.rank`, `weapon_type`; 8 món (thêm cung Lyra, song đao Kael; giáp / phụ kiện cũ thành vết thánh).
  - Tiến trình: `Progression` có cấp đội trưởng (`account` trong save, `add_captain_exp`, `level_cap`), mảnh và tiến cấp (S → S1 → S2 → S3, +5% chỉ số mỗi bước, mảnh 10 / 20 / 25), cấp kỹ năng theo nhóm (`upgrade_skill`, 500 vàng × cấp, tối đa 10); cấp kỹ năng đi vào trận (`SkillRunner.level_provider` → `Hitbox.skill_level`); thưởng màn có `captain_exp` 400.
  - Save v3: migration đổi món cũ sang vết thánh (giữ cấp cường hóa), thêm `skills`, `fragments`, `promotion`, `account` (cấp đội trưởng = cấp cao nhất cũ để người chơi cũ không bị khóa).
  - Test mới: `tests/unit/gacha/test_owner_banner.gd` (9), `tests/unit/progression/test_captain_promotion_skills.gd` (8); sửa test cũ theo trang bị mới.
- **Đã chạy:** `python tools/gen_item_data.py`, `gen_stage_01.py`, `gen_banner_data.py`; `godot --headless --import`; `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 420/420, 5 test khói đạt, mã thoát 0. Kiểm: banner khớp số owner; pity mềm 1.5% → 11.5% từ lượt 80, 100% ở lượt 100; 1500 lượt không vượt 100; 200 lần quay 10 lượt lần nào cũng có ≥ 1 nhân vật A (bảo đảm thật sự được dùng); quay lẻ không có bảo đảm; 20 000 lượt ra A 16.3% / B 10.874% trong sai số; pity chung giữa banner nhân vật; giá 280 / 2520; Kael trùng → 25 mảnh; ra vàng 2000; đội trưởng cấp 1 giữ nhân vật ở cấp 1, lên đội trưởng thì nhân vật lên theo; sách EXP bị từ chối khi đã đầy; tiến cấp trừ mảnh, S2 → S3 cần 25, +5% ATK; cấp kỹ năng 4 vào trận thành `skill_level` 4; Aether không cầm cung; save v2 lên v3 đúng.
- **Quyết định Claude chọn (chờ owner xác nhận ở câu hỏi cuối lượt):** pity mềm cộng một lần; hạng tạm S = Aether, Kael, Lyra / A = Seraphine, Noctis / B = Terra; banner đầu đề cử Kael; phần nguyên liệu chia đều 6 loại (3 sách EXP, 2 nguyên liệu cường hóa, 2000 vàng); mảnh khi trùng 25 / 10 / 5; "không vượt quá cấp người chơi" = cấp đội trưởng.
- **Hạn chế đã biết:** banner tiếp tế vũ khí chưa có (tỉ lệ của owner cộng lại khác 100%); vết thánh chưa có hiệu ứng bộ.

## 2026-11-13 — Màn Nhân vật theo 6 ảnh tham chiếu của owner

- **Milestone / task:** 7 (M7-2, làm lại tab Nhân vật theo yêu cầu owner 2026-11-12)
- **Trạng thái:** TESTED (headless + ảnh chụp). Chưa VERIFIED: owner chưa xem bằng mắt.
- **File tạo/sửa:**
  - `data/ui/character_screen_layout.json`: **file cấu hình bố cục** (vị trí `rect` [x, y, rộng, cao] trên khung 1920×1080, `anchor` left/right/center để giữ đúng chỗ khi màn rộng hơn, cỡ chữ `font`, khóa chữ, màu, tên vùng placeholder, 8 nút cây skill). Owner sửa file này để đổi giao diện, không cần sửa code.
  - `scripts/ui/character/`: `ui_layout.gd` (đọc JSON, thiếu giá trị thì dùng mặc định), `placeholder_art.gd` (vẽ ảnh nếu có, chưa có thì vẽ hình người + tên vùng), `skill_text.gd` (tên + mô tả kỹ năng sinh từ SkillDef nên luôn khớp số trong data), `character_screen.gd` (màn chính).
  - `scenes/main/character_screen.tscn`; `GameConfig.SCENE_CHARACTER`, `selected_character_id`; tab Nhân vật ở Hub mở màn mới (bỏ `HubCharactersPanel`, chuyển test sang màn mới).
  - 130 khóa dịch vi/en (`tools/add_locale_keys.py`): tab, nút, chỉ số, nguyên tố, nhóm kỹ năng, tên kỹ năng theo `CHARACTER_SKILLS.md`, mô tả bị động, giải thích trạng thái.
  - `tools/screenshot_character.gd` (chụp 6 trạng thái vào `build/screenshots/character_*.png`).
  - Test: `tests/unit/ui/test_character_screen.gd` (21).
- **Nội dung theo ảnh:** (1) tổng quan: tên, hạng, nguyên tố · vũ khí, cấp, hàng biểu tượng, nút Xem skill, thẻ vũ khí, 3 ô vết thánh, danh sách nhân vật dưới cùng; (2) Vũ khí: tên, loại, cấp, sao, ảnh, chỉ số, Cường hóa / Đổi; (3) Vết thánh: ảnh lưng với 3 ô Đầu / Thân / Chân, khung chỉ số, 3 thẻ có nút Đổi; (4) Tăng cấp: chỉ số, Chỉ số chi tiết, EXP + sách EXP, mảnh, tiến cấp; (5) cây 8 nút kỹ năng với "+N" / "Đầy cấp"; (6) chi tiết kỹ năng: cây kỹ năng con, mô tả, Nâng cấp — N vàng, Sơ lược, Giải thích từ ngữ, chuyển trước / sau. Esc / Back lùi từng bước (bảng chọn → chi tiết kỹ năng → tab → tổng quan → Hub).
- **Đã chạy:** `godot --headless --import`; `tools/run_tests.ps1`; `godot --path . -s tools/screenshot_character.gd`.
- **Kết quả thật:** GdUnit4 437/437, 5 test khói đạt, mã thoát 0. Đã xem 6 ảnh chụp, sửa chồng chữ ở thẻ nhân vật, cây skill (nhãn nút giữa đè nút Vũ khí), tiêu đề Mảnh và chữ tắt nhóm kỹ năng ("Tấ" trùng nhau → TCT / TCĐ / KNT...).
- **Quyết định Claude chọn:** ảnh chưa có (vũ khí, vết thánh, ảnh lưng, chân dung Kael / Lyra, icon) vẽ hình người xám kèm tên vùng; nút chưa có chức năng (Hướng dẫn, Chiến thuật, Quan sát, Trang phục, Chụp ảnh, Lọc, Chuyển đổi mảnh, Minh họa) hiện "chưa có trong bản thử"; biểu tượng tròn dùng chữ tắt đầu mỗi từ; mô tả kỹ năng sinh từ data (sát thương, EN/UG, hồi chiêu, trạng thái, pha ms) thay vì câu viết tay; Lyra hiện phần bị động đang có trong code (né hoàn hảo).
- **Hạn chế đã biết:** chưa có art thật cho các vùng trên; vết thánh chưa có hiệu ứng bộ; Kael / Lyra chưa có dữ liệu kỹ năng ngoài đòn thường, né, vào sân (màn hiện "chưa có dữ liệu"); bố cục chỉ xếp theo mô tả ảnh, cần owner so trực tiếp với ảnh gốc.

## 2026-11-13 — Banner tiếp tế, hạng nhân vật mới, lượt x10 miễn phí (Kael), cấp người chơi

- **Milestone / task:** 5 (M5-2, M5-3) — theo trả lời owner 2026-11-13
- **Trạng thái:** TESTED (headless)
- **Owner quyết định:** (1) vết thánh 3★ tăng lên 14.43% cho tổng 100%; (2) hạng tạm S = Aether, Terra, B = Kael, Lyra; hướng dẫn sau này: lượt x10 miễn phí đầu tiên bắt buộc 1 Kael, còn lại nguyên liệu tăng cấp; (3) pity mềm cộng một lần là đúng; (4) "cấp người chơi" = người quản lý không có hình, lên cấp qua nhiệm vụ / phó bản.
- **File tạo/sửa:** `tools/gen_banner_data.py` (banner nhân vật đề cử Aether, banner tiếp tế, `data/tutorial/starter_pull.tres`); `data/banners/banner_char_aether.tres`, `banner_equip_aether.tres` (xóa `banner_char_kael.tres`); `tools/gen_item_data.py` + 4 vết thánh mới (bộ Viêm Hoàng 4★ Đầu / Thân / Chân, Ấn Dép Cỏ 3★ Chân); `data/characters/char_{earth,lightning,wind}_01.tres` (hạng); `BannerDef.starter_free_multi`; `GachaService.pull_starter` / `starter_available`; save thêm `gacha.starter_used`; chữ "Cấp đội trưởng" → "Cấp người chơi"; test mới `tests/unit/gacha/test_equip_and_starter_banner.gd` (6), sửa `test_owner_banner`, `test_gacha_service`, `test_hub_panels`, `test_progression_inventory`; AGENTS.md, OWNER_ASSET_CHECKLIST A2, KNOWN_ISSUES A2.
- **Đã chạy:** `python -X utf8 tools/gen_item_data.py`; `python -X utf8 tools/gen_banner_data.py`; `python -X utf8 tools/add_locale_keys.py`; `godot --headless --import`; `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 443/443, 5 test khói đạt, mã thoát 0. Kiểm: tiếp tế 2.87 / 14 / 10.7 / 14.43 / 58% cộng đúng 100%; mỗi bậc chỉ chứa đúng số sao và loại; 120 lần quay 10 lượt lần nào cũng có món 4★, lượt bảo đảm luôn là vết thánh, vũ khí 4★ không quá 60 lượt; pity tiếp tế tách khỏi pity nhân vật; lượt miễn phí không trừ Ngọc, đúng 1 Kael ở vị trí ngẫu nhiên, 9 sách EXP, dùng lần hai bị từ chối, lưu qua sanitize; tab Chiêu mộ hiện 2 banner.
- **Quyết định Claude chọn:** banner nhân vật đề cử **Aether** (S duy nhất chơi được và có đồ 4★ để đề cử; Terra chưa có kỹ năng) — chờ owner xác nhận; bộ vết thánh 4★ đề cử chiếm 50% khi ra vết thánh 4★; vật phẩm bậc nguyên liệu của tiếp tế dùng chung danh sách với banner nhân vật; lượt miễn phí dùng nhóm pity riêng "starter" (không ảnh hưởng pity thật); chỉ số 4 vết thánh mới là số tạm.
- **Hạn chế đã biết:** chưa có màn hướng dẫn nên lượt miễn phí chưa gắn UI; người chơi mới vẫn có sẵn Kael trong đội khởi đầu (giữ để test khói và màn 1 chạy) — khi làm hướng dẫn cần bỏ Kael khỏi `STARTER_CHARACTERS`; chưa có hệ thống nhiệm vụ để lên cấp người chơi.

## 2026-11-13 — Banner đầu đề cử Iwagane, đổi tên nhân vật, giáp, bộ lọc nhân vật

- **Milestone / task:** 5 (M5-2) + 7 (M7-2) — theo yêu cầu owner 2026-11-13
- **Trạng thái:** TESTED (headless + ảnh chụp)
- **Owner quyết định:** banner đầu tiên đề cử Terra; đổi tên tránh trùng: Aether → Enkiba (giáp S Hỏa Diễm Mãnh Liệt), Lyra → Kazeyumi (giáp B Đôi Cánh Của Gió), Kael → Raikiba (giáp B Nanh Của Lôi Thần), Seraphine → Hikarine (giáp A Ánh Sáng Thiên Giới), Noctis → Yomigari (giáp A Lưỡi Hái Hắc Ám), Terra → Iwagane (giáp S Thần Kiếm Nham Thạch); thêm bộ lọc nhân vật; một nhân vật có thể có nhiều giáp với hạng khác nhau.
- **File tạo/sửa:**
  - `CharacterDef.person_id`, `suit_key`, `person()`; 6 file `data/characters/*.tres`; khóa `SUIT_*`, tên `CHAR_*` mới trong `localization/*.po`.
  - `PlayerProfile.person_of` + `set_party` từ chối hai giáp cùng nhân vật.
  - Banner: `tools/gen_banner_data.py` → `banner_char_terra.tres`, `banner_equip_terra.tres` (xóa bản Aether); `tools/gen_item_data.py` + Đại kiếm Dung Nham 4★ và bộ Ấn Nham Thạch 4★ (Đầu / Thân / Chân).
  - Màn Nhân vật: dòng phụ hiện tên giáp · nguyên tố · vũ khí; nút **Lọc** mở bảng lọc theo hạng giáp, nguyên tố, nhân vật (trong nhóm "hoặc", giữa nhóm "và"), dòng "Đang hiện N/M giáp", Bỏ lọc; Esc đóng bảng; khung `filter` trong `data/ui/character_screen_layout.json`.
  - Test: `test_character_screen` (+2: tên giáp, bộ lọc), `test_progression_inventory` (+1: hai giáp cùng nhân vật), sửa test gacha / Hub theo tên và banner mới; `tools/screenshot_character.gd` thêm ảnh bảng lọc.
  - Tài liệu: AGENTS.md, OWNER_ASSET_CHECKLIST A2 (bảng tên), KNOWN_ISSUES A7 (xong), B2.
- **Đã chạy:** `python -X utf8 tools/gen_item_data.py`; `python -X utf8 tools/gen_banner_data.py`; `godot --headless --import`; `tools/run_tests.ps1`; `godot --path . -s tools/screenshot_character.gd`.
- **Kết quả thật:** GdUnit4 446/446, 5 test khói đạt, mã thoát 0. Ảnh chụp: tổng quan hiện "Enkiba", "Hỏa Diễm Mãnh Liệt · Hỏa · Kiếm", thẻ Raikiba / Kazeyumi hạng B, Iwagane hạng S; bảng lọc hạng S hiện 2/4 giáp.
- **Quyết định Claude chọn:** giữ khóa `CHAR_*` làm tên nhân vật (các giáp cùng nhân vật dùng chung tên), thêm `SUIT_*` cho tên giáp; Data ID và tên file (vd `gen_aether_data.py`, `test_kael_lyra.gd`) giữ nguyên; tên tiếng Anh của giáp do Claude dịch; banner tiếp tế: khi ra vũ khí 4★ có 50% là vũ khí đề cử (giờ có 2 vũ khí 4★); đội chọn thêm giáp trùng nhân vật thì bị từ chối im lặng như khi đội đủ 3.
- **Hạn chế đã biết:** chưa có giáp thứ hai nào cho cùng một nhân vật (cấu trúc đã sẵn, test giả lập); Iwagane được đề cử nhưng chưa có kỹ năng (B2); tài liệu thiết kế `CHARACTER_SKILLS.md` vẫn dùng tên cũ (không sửa theo quy tắc).

## 2026-11-13 — Quy trình Codex tạo frame từng animation, owner duyệt từng cái (Enkiba)

- **Milestone / task:** art pipeline (README 17, B trong OWNER_ASSET_CHECKLIST) — theo yêu cầu owner 2026-11-13
- **Trạng thái:** TESTED (công cụ chạy thử bằng ảnh giả); chưa có frame thật nào
- **Yêu cầu owner:** dựa trên file prompt "Chibi Anime SideScroll" của owner, bảng tên bộ phận Aether (artifact) và `CHARACTER_SKILLS.md`, sửa prompt để Codex tạo ảnh và thay vào dự án; làm từng động tác, owner duyệt cái nào thì thêm cái đó.
- **File tạo/sửa:**
  - `tools/frames/jobs/char_fire_01.json`: 23 phiếu (động tác tiếng Việt từ CHARACTER_SKILLS, prompt ảnh tiếng Anh, ảnh bộ phận tham chiếu theo bảng: 16 đứng, 44 kiếm, 58–62 pose, 04 mặt hét, 05 mặt đau).
  - `tools/frames/frame_jobs.py`: tính số frame / fps / frame trúng đòn từ thời gian SkillDef (vd attack_1: 320 ms → 6 frame 18 fps, trúng frame 1–2; ultimate 2800 ms → 22 frame 8 fps, chia 4 lần gọi ≤ 6 frame).
  - `tools/frames/gen_prompts.py` → `docs/prompts/codex_frames/char_fire_01/README.md` + `01_idle.md` … `23_ultimate.md` (bảng trạng thái Chưa làm / Chờ duyệt / Đã duyệt).
  - `tools/frames/slice_strip.py` (tách dải theo khoảng trống, xóa nền #FF00FF, cùng hệ số phóng — đứng 280 px, chân 336, tâm chân 192, animation trên không giữ độ cao tương đối), `check_frames.py` (kiểm + `_preview/sheet.png`, `anim.gif`, `anim_flip.gif`, frame trúng đòn viền đỏ), `approve_frames.py` (chỉ chạy khi owner duyệt: kiểm đạt, có meta.json, không ghi đè trừ `--replace` có lưu bản cũ, cập nhật manifest, ghi ASSET_LICENSES 2.1).
  - `art_review/` (`.gdignore`, thêm vào `.gitignore`); `frames_manifest.json` working_name → Enkiba; `docs/prompts/CODEX_AETHER_FRAMES.md` thành trang trỏ sang quy trình mới; AGENTS.md mục Ảnh do AI tạo.
- **Đã chạy:** `python -I tools/frames/gen_prompts.py char_fire_01`; chạy thử trên bản sao tạm (scratchpad) với dải ảnh giả nền magenta: `slice_strip.py` idle 6 frame + jump_up 3 frame (`--scale` lấy từ idle), `check_frames.py`, `approve_frames.py` (thiếu meta → từ chối, đủ meta → duyệt, chạy lại → từ chối ghi đè, `--replace` → bản cũ chuyển `_replaced/`); `tools/run_tests.ps1`.
- **Kết quả thật:** 23 phiếu sinh ra; idle / jump_up ĐẠT kiểm tra, sheet đúng đường chân 336 và tâm 192, jump_up nâng dần theo độ cao gốc; approve ghi đúng manifest (6 frame, 8 fps, lặp) và dòng ASSET_LICENSES; animation chưa có thư mục báo CHƯA ĐẠT, mã thoát 1. Test dự án: GdUnit4 446/446, 5 test khói đạt, mã thoát 0.
- **Quyết định Claude chọn:** fps chọn trong 8/10/12/15/18/20/24 sao cho số frame gần ước lượng của CHARACTER_SKILLS mà vẫn khớp thời lượng đòn; tối đa 6 pose mỗi lần gọi tạo ảnh; chiều cao đứng 280 px; tâm ngang lấy trọng tâm phần chân (35% dưới) để kiếm vươn ra không kéo lệch nhân vật; walk / guard / victory / death trong prompt của owner chưa có trạng thái trong game nên chưa có phiếu.
- **Hạn chế đã biết:** chưa thử với ảnh thật của Codex (tách pose phụ thuộc khoảng trống giữa các pose); dải nhiều lần gọi không so được độ cao giữa các dải với animation trên không; Codex có đính kèm được ảnh từ ổ đĩa hay không tùy phiên bản — phiếu ghi rõ owner kéo ảnh vào.

## 2026-11-13 — Enkiba: đưa frame idle (6 pose) vào game

- **Milestone / task:** art (B trong OWNER_ASSET_CHECKLIST), animation `idle` của char_fire_01
- **Trạng thái:** VERIFIED (kiểm tra tự động + owner yêu cầu thay vào; owner chưa xem trong Godot)
- **Owner quyết định:** thay frame idle bằng dải 6 pose owner cung cấp (ảnh nền trong suốt, sẵn 6 pose đứng).
- **File tạo/sửa:** `assets/characters/char_fire_01/frames/idle/char_fire_01_idle_000..005.png` (mới); `frames_manifest.json` (idle: 6 frame, 8 fps, lặp; `frames_delivered: true`); `docs/ASSET_LICENSES.md` mục 2.1 (một dòng, nguồn ghi "owner cung cấp"); `tests/unit/characters/test_animation_set_builder.gd` và `tests/unit/player/test_player_movement.gd` (cập nhật từ "chưa giao frame nào" sang "idle đã giao, các animation khác vẫn placeholder").
- **Đã chạy:** `slice_strip.py char_fire_01 idle` (dải 2172×724, nền trong suốt, hệ số phóng 0.4538); `check_frames.py char_fire_01 idle` → ĐẠT; `approve_frames.py char_fire_01 idle`; `tools/run_tests.ps1`.
- **Kết quả thật:** check ĐẠT (chân ở y = 336, tâm chân trong ngưỡng, không cắt mép); GdUnit4 446/446, 5 test khói đạt, mã thoát 0. Test đầu tiên hỏng vì giả định chưa có frame nào; đã sửa test theo trạng thái mới.
- **Quyết định Claude chọn:** nguồn ảnh ghi là "owner cung cấp (công cụ không rõ)" vì dải không kèm prompt hay model; hệ số phóng lấy từ frame 0 cao 280 px.
- **Hạn chế đã biết:** kiếm đang đeo sau vai, còn ảnh đứng gốc (portrait, bộ phận 16) cầm kiếm ở tay trái. Chờ owner xác nhận đây là thiết kế đúng hay cần làm lại. Nguồn công cụ tạo ảnh chưa rõ, cần owner xác nhận để ghi đúng vào giấy phép ảnh AI (ASSET_LICENSES 2.1) và khai báo khi phát hành.

## 2026-11-13 — Cập nhật bộ prompt Codex cho Enkiba (prompt gốc, phân tích model, kiếm, giai đoạn từng frame)

- **Milestone / task:** art pipeline — owner yêu cầu viết lại prompt tạo ảnh chuyển động theo skill Enkiba dựa trên file prompt gốc, thêm file vào dự án.
- **Trạng thái:** TESTED (công cụ + sinh phiếu); chưa có animation mới nào được Codex tạo
- **File tạo/sửa:**
  - `docs/prompts/codex_frames/PROMPT_GOC.md`: prompt gốc của owner chuyển thể đủ các mục (bối cảnh, phân tích model, bảo toàn ngoại hình, chuyển động 3 giai đoạn, phong cách, xuất file / tích hợp, tự kiểm tra, nguyên tắc), dùng chung mọi nhân vật; ghi rõ phần nào đã có công cụ thay (state machine, hitbox, atlas JSON không tạo mới).
  - `docs/prompts/codex_frames/char_fire_01/00_PHAN_TICH.md`: phân tích model Enkiba (tỉ lệ 2.5 đầu, nét viền, bảng màu — màu đo từ idle_000 và màu ước lượng ghi riêng, thứ tự lớp, hai trạng thái kiếm, pivot).
  - `tools/frames/jobs/char_fire_01.json`: thiết kế tiếng Anh theo idle đã duyệt; tham chiếu bắt buộc thêm idle_000, idle_003; mỗi animation có `sword` (sheathed / drawn), `ref_frame`, `ref_ratio`.
  - `tools/frames/frame_jobs.py`: giai đoạn từng frame (startup / active / recovery), `idle_height()`; chỉ tính hit do kiếm chém (loại hit bay `travel_px > 0` và nổ trễ `delay_ms > 0`: attack_4 còn 3 frame trúng đòn thay vì 5, hold_release 3 thay vì 6).
  - `tools/frames/slice_strip.py` thêm `--like idle` (canh tỉ lệ theo chiều cao idle đã duyệt, ~281 px), `--ref-frame` âm, `--ref-ratio`; `check_frames.py` cảnh báo khi pose cao nhất lệch xa idle; `gen_prompts.py` ghi mục Kiếm, bảng giai đoạn từng frame, phase map trong prompt ảnh, lệnh `--like idle`; 23 phiếu sinh lại.
  - AGENTS.md mục Ảnh do AI tạo.
- **Lỗi tìm thấy và sửa:** phiếu cũ bảo Codex dùng `--scale` của idle cho animation khác — sai vì mỗi dải ảnh AI có độ phân giải khác nhau; thay bằng `--like idle` (đo lại chiều cao pose tham chiếu của dải mới). Chạy thử: dải 6 pose giả → attack_1 phóng 0.9336, check ĐẠT (đã xóa dữ liệu thử).
- **Đã chạy:** `python -I tools/frames/gen_prompts.py char_fire_01`; thử `slice_strip.py ... --like idle` + `check_frames.py`; `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 446/446, 5 test khói đạt, mã thoát 0.
- **Quyết định Claude chọn:** kiếm đeo lưng ở idle, run, nhảy, rơi, tiếp đất, lướt, bị đánh, ngã, rời sân; kiếm cầm tay ở mọi đòn đánh, tụ lực, kỹ năng, tuyệt kỹ, vào sân; kiếm "xuất hiện" ngay ở frame đầu (không vẽ rút kiếm); `skill_2` kết thúc tra kiếm ra sau lưng; pose tham chiếu để canh tỉ lệ chọn theo từng animation (vd khuỵu = 0.8× chiều cao đứng).
- **Hạn chế đã biết:** chưa biết Codex tạo dải có đúng khoảng trống giữa pose không; kiếm đeo lưng ở idle khác ảnh gốc cầm tay (đã ghi trong 00_PHAN_TICH.md, hỏi owner có muốn làm animation rút / tra kiếm riêng); gói ZIP gửi trước đó là bản cũ (không còn cần vì Codex làm trực tiếp trong dự án).

## 2026-11-13 — Enkiba luôn rút kiếm: sửa toàn bộ phiếu prompt

- **Milestone / task:** art pipeline — owner yêu cầu Enkiba luôn ở trạng thái rút kiếm
- **Trạng thái:** TESTED (sinh phiếu + test dự án); chưa có animation mới do Codex tạo
- **Owner quyết định:** kiếm cầm tay ở mọi frame của mọi animation (không đeo lưng, không bao kiếm, không vẽ rút / tra kiếm).
- **File sửa:** `tools/frames/jobs/char_fire_01.json` (mọi animation `sword: drawn`; thiết kế tiếng Anh ghi "ALWAYS DRAWN, NOTHING on the back"; prompt các animation không đánh nhắc cách cầm kiếm: idle hạ thấp, run lưỡi xuôi ra sau, nhảy / rơi / tiếp đất / lướt / bị đánh / ngã giữ kiếm trong tay; `skill_2` kết thúc hạ kiếm xuống bên người thay vì tra kiếm; `switch_out` cầm kiếm; ảnh tham chiếu đặt ảnh gốc 3/4 và hình kiếm lên đầu, idle cũ chỉ để khóa nét / màu / tỉ lệ và bỏ qua kiếm sau lưng); `docs/prompts/codex_frames/PROMPT_GOC.md` và `char_fire_01/00_PHAN_TICH.md` (mục "Kiếm luôn rút", bỏ "hai trạng thái kiếm"); `tools/frames/gen_prompts.py` (mục `redo_reason`, `--replace` ở bước duyệt, câu tham chiếu idle); 23 phiếu và README sinh lại.
- **Idle cần làm lại:** idle đã duyệt (6 frame owner cung cấp, commit 72ad85e) có kiếm đeo lưng nên trái quy tắc mới. Giữ nguyên trong game cho tới khi owner duyệt bản mới; phiếu `01_idle.md` và bảng trạng thái ghi "cần làm lại", bước duyệt dùng `approve_frames.py ... --replace` (bản cũ chuyển sang `art_review/char_fire_01/_replaced/`). Hệ số tỉ lệ `--like idle` vẫn đo được từ idle cũ (~281 px).
- **Đã chạy:** `python -I tools/frames/gen_prompts.py char_fire_01`; `tools/run_tests.ps1`.
- **Kết quả thật:** GdUnit4 446/446, 5 test khói đạt, mã thoát 0.
- **Quyết định Claude chọn:** hạ kiếm xuống bên người ở cuối `skill_2` thay cho "tra kiếm nửa chừng" của CHARACTER_SKILLS (không sửa tài liệu thiết kế); cách cầm lấy từ ảnh gốc (tay gần camera, mũi kiếm hạ xuống trước).
- **Hạn chế đã biết:** ảnh gốc là 3/4 nên cách cầm kiếm ở góc nhìn ngang do Codex suy ra; kiếm cầm tay che một phần chân / thân ở nhiều pose, cần soát thứ tự lớp khi duyệt; idle trong game tạm thời vẫn là bản kiếm đeo lưng.

## 2026-11-13 — Art: Enkiba idle frames (AI)

- **Milestone / task:** art pipeline — tạo và duyệt animation `idle` cho `char_fire_01`, chỉ một animation.
- **Trạng thái:** TESTED (owner duyệt preview; kiểm tra frame và toàn bộ test đạt).
- **Owner duyệt:** "ok rồi thêm vào dự án nhé" sau khi xem `sheet.png`, `anim.gif` và `anim_flip.gif`.
- **File tạo/sửa:** 6 frame `assets/characters/char_fire_01/frames/idle/char_fire_01_idle_000..005.png` và sidecar `.import`; `assets/characters/char_fire_01/frames_manifest.json` (6 frame, 8 fps, loop); `docs/ASSET_LICENSES.md` mục 2.1; `art_review/char_fire_01/idle/meta.json` (ngày duyệt); bản idle cũ được giữ tại `art_review/char_fire_01/_replaced/idle_20261113_183648/`.
- **Đã chạy:** `check_frames.py char_fire_01 idle` → ĐẠT; `approve_frames.py char_fire_01 idle --replace`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1` (chạy lại ngoài sandbox sau khi Godot crash ở lần chạy sandbox).
- **Kết quả thật:** Đưa vào game 6 frame; GdUnit4 446/446, 5 smoke checks đều đạt, tổng mã thoát 0. Bản idle cũ được chuyển sang `_replaced/` thay vì xóa.
- **Quyết định Codex chọn:** dùng một dải sáu pose duy nhất, giữ kiếm rút trên tay ở cả sáu frame; metadata và giấy phép ghi model là "not exposed by the imagegen tool" vì công cụ không cung cấp tên model.
- **Hạn chế đã biết:** owner duyệt bản preview, chưa xác nhận trực tiếp trong Godot; tên model tạo ảnh không được công cụ imagegen expose.


## 2026-11-13 — Art: Enkiba run frames (AI)
- **Milestone / task:** art pipeline — đưa animation `run` đã được owner duyệt cho `char_fire_01` vào game.
- **Trạng thái:** TESTED (owner duyệt preview; kiểm tra frame và toàn bộ test đạt).
- **Owner duyệt:** "duyệt run" sau bước preview; giữ 8 frame, 12 fps, lặp.
- **File tạo/sửa:** `assets/characters/char_fire_01/frames/run/char_fire_01_run_000..007.png` và sidecar `.import`; `assets/characters/char_fire_01/frames_manifest.json` (run: 8 frame, 12 fps, lặp); `docs/ASSET_LICENSES.md` mục 2.1; `tests/unit/characters/test_animation_set_builder.gd` cập nhật kỳ vọng idle + run đã giao.
- **Đã chạy:** `python -I tools/frames/approve_frames.py char_fire_01 run`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1` (ngoài sandbox sau khi Godot crash trong sandbox).
- **Kết quả thật:** `approve_frames.py` duyệt và chép 8 frame; GdUnit4 438 test, 0 lỗi / 0 thất bại; 5 smoke check đạt; tổng mã thoát 0.
- **Quyết định Codex chọn:** cập nhật test tài nguyên để kiểm tra cả idle (6 frame) và run (8 frame) là animation đã giao, các animation còn lại tiếp tục placeholder.
- **Hạn chế đã biết:** model imagegen không được expose; frame 003 và 007 là pose trên không có kiếm sát chân/ủng (đã nêu ở preview, owner vẫn duyệt).


## 2026-11-13 — Art: Enkiba jump_up frames (AI)
- **Milestone / task:** art pipeline — đưa animation `jump_up` đã được owner duyệt cho `char_fire_01` vào game.
- **Trạng thái:** TESTED (owner duyệt preview; kiểm tra frame và toàn bộ test đạt).
- **Owner duyệt:** "duyệt jump_up thêm vào dự án"; giữ 3 frame, 12 fps, không lặp.
- **File tạo/sửa:** `assets/characters/char_fire_01/frames/jump_up/char_fire_01_jump_up_000..002.png` và sidecar `.import`; `assets/characters/char_fire_01/frames_manifest.json` (jump_up: 3 frame, 12 fps, không lặp); `docs/ASSET_LICENSES.md` mục 2.1; `tests/unit/characters/test_animation_set_builder.gd` cập nhật kỳ vọng ba animation đã giao.
- **Đã chạy:** `python -I tools/frames/approve_frames.py char_fire_01 jump_up`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1` (ngoài sandbox sau khi Godot crash trong sandbox).
- **Kết quả thật:** `approve_frames.py` duyệt và chép 3 frame; GdUnit4 446 test, 0 lỗi / 0 thất bại; 5 smoke check đạt; tổng mã thoát 0.
- **Quyết định Codex chọn:** mở rộng kiểm tra asset đã giao từ idle + run thành idle (6 frame), run (8 frame) và jump_up (3 frame); animation còn lại tiếp tục placeholder.
- **Hạn chế đã biết:** model imagegen không được expose; frame 001 giữ một chân chạm đất trong pha đẩy lên như phiếu mô tả (owner đã duyệt preview).


## 2026-11-13 — Art: Enkiba fall frames (AI)
- **Milestone / task:** art pipeline — duyệt và tích hợp animation `fall` cho `char_fire_01`.
- **Trạng thái:** TESTED (owner duyệt; frame checker và toàn bộ test đạt).
- **Owner duyệt:** "duyệt fall"; giữ 3 frame, 12 fps, không lặp.
- **File tạo/sửa:** 3 frame `assets/characters/char_fire_01/frames/fall/char_fire_01_fall_000..002.png` và sidecar `.import`; `assets/characters/char_fire_01/frames_manifest.json` (fall: 3 frame, 12 fps, không lặp); `docs/ASSET_LICENSES.md` mục 2.1; `tests/unit/characters/test_animation_set_builder.gd` cập nhật animation đã giao từ 3 lên 4 và kiểm tra fall.
- **Đã chạy:** `python -I tools/frames/check_frames.py char_fire_01 fall`; `python -I tools/frames/approve_frames.py char_fire_01 fall`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1` (chạy lại ngoài sandbox).
- **Kết quả thật:** checker ĐẠT, 3 frame; GdUnit4 446/446, 0 lỗi / 0 thất bại; 5 smoke test đạt; lệnh test mã thoát 0.
- **Quyết định Codex chọn:** giữ cấu hình trong phiếu, ghi model là "not exposed by the imagegen tool" theo metadata.
- **Hạn chế đã biết:** owner đã duyệt preview; model imagegen không được expose.


## 2026-11-13 — Art: Enkiba attack_1 frames (AI)
- **Milestone / task:** art pipeline — duyệt và tích hợp animation `attack_1` cho `char_fire_01`.
- **Trạng thái:** TESTED (owner duyệt; frame checker và toàn bộ test đạt).
- **Owner duyệt:** "duyệt attack từ 1-4"; giữ 6 frame, 18 fps, không lặp.
- **File tạo/sửa:** 6 frame `assets/characters/char_fire_01/frames/attack_1/char_fire_01_attack_1_000..005.png` và sidecar `.import`; manifest cập nhật `attack_1`; `docs/ASSET_LICENSES.md` mục 2.1; test animation builder cập nhật số animation đã giao và kiểm tra `attack_1`.
- **Đã chạy:** `python -I tools/frames/check_frames.py char_fire_01 attack_1`; `python -I tools/frames/approve_frames.py char_fire_01 attack_1`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1` (ngoài sandbox).
- **Kết quả thật:** checker ĐẠT, 6 frame; GdUnit4 446/446, 0 lỗi / 0 thất bại; 5 smoke test đạt; mã thoát 0.
- **Quyết định Codex chọn:** giữ số frame / fps từ phiếu và metadata ghi model theo thông tin công cụ cung cấp.
- **Hạn chế đã biết:** model imagegen không được expose.


## 2026-11-13 — Art: Enkiba attack_2 frames (AI)
- **Milestone / task:** art pipeline — duyệt và tích hợp animation `attack_2` cho `char_fire_01`.
- **Trạng thái:** TESTED (owner duyệt; frame checker và toàn bộ test đạt).
- **Owner duyệt:** "duyệt attack từ 1-4"; giữ 6 frame, 18 fps, không lặp.
- **File tạo/sửa:** 6 frame `assets/characters/char_fire_01/frames/attack_2/char_fire_01_attack_2_000..005.png` và sidecar `.import`; manifest cập nhật `attack_2`; `docs/ASSET_LICENSES.md` mục 2.1; test animation builder cập nhật số animation đã giao và kiểm tra `attack_2`.
- **Đã chạy:** `python -I tools/frames/check_frames.py char_fire_01 attack_2`; `python -I tools/frames/approve_frames.py char_fire_01 attack_2`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1` (ngoài sandbox).
- **Kết quả thật:** checker ĐẠT, 6 frame; GdUnit4 446/446, 0 lỗi / 0 thất bại; 5 smoke test đạt; mã thoát 0.
- **Quyết định Codex chọn:** giữ số frame / fps từ phiếu và metadata ghi model theo thông tin công cụ cung cấp.
- **Hạn chế đã biết:** model imagegen không được expose.


## 2026-11-13 — Art: Enkiba attack_3 frames (AI)
- **Milestone / task:** art pipeline — duyệt và tích hợp animation `attack_3` cho `char_fire_01`.
- **Trạng thái:** TESTED (owner duyệt; frame checker và toàn bộ test đạt).
- **Owner duyệt:** "duyệt attack từ 1-4"; giữ 6 frame, 15 fps, không lặp.
- **File tạo/sửa:** 6 frame `assets/characters/char_fire_01/frames/attack_3/char_fire_01_attack_3_000..005.png` và sidecar `.import`; manifest cập nhật `attack_3`; `docs/ASSET_LICENSES.md` mục 2.1; test animation builder cập nhật số animation đã giao và kiểm tra `attack_3`.
- **Đã chạy:** `python -I tools/frames/check_frames.py char_fire_01 attack_3`; `python -I tools/frames/approve_frames.py char_fire_01 attack_3`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1` (ngoài sandbox).
- **Kết quả thật:** checker ĐẠT, 6 frame; GdUnit4 446/446, 0 lỗi / 0 thất bại; 5 smoke test đạt; mã thoát 0.
- **Quyết định Codex chọn:** giữ số frame / fps từ phiếu và metadata ghi model theo thông tin công cụ cung cấp.
- **Hạn chế đã biết:** model imagegen không được expose; frame 002 được thu nhỏ nhẹ để vừa khung và giữ khoảng cách ở mũi kiếm như đã nêu trong preview.

## 2026-11-13 — Art: Enkiba attack_4 frames (AI)
- **Milestone / task:** art pipeline — duyệt và tích hợp animation `attack_4` cho `char_fire_01`.
- **Trạng thái:** TESTED (owner duyệt; frame checker và toàn bộ test đạt).
- **Owner duyệt:** "duyệt attack từ 1-4"; giữ 7 frame, 12 fps, không lặp.
- **File tạo/sửa:** 7 frame `assets/characters/char_fire_01/frames/attack_4/char_fire_01_attack_4_000..006.png` và sidecar `.import`; manifest cập nhật `attack_4`; `docs/ASSET_LICENSES.md` mục 2.1; test animation builder cập nhật số animation đã giao và kiểm tra `attack_4`.
- **Đã chạy:** `python -I tools/frames/check_frames.py char_fire_01 attack_4`; `python -I tools/frames/approve_frames.py char_fire_01 attack_4`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1` (ngoài sandbox).
- **Kết quả thật:** checker ĐẠT, 7 frame; GdUnit4 446/446, 0 lỗi / 0 thất bại; 5 smoke test đạt; mã thoát 0.
- **Quyết định Codex chọn:** giữ số frame / fps từ phiếu và metadata ghi model theo thông tin công cụ cung cấp.
- **Hạn chế đã biết:** model imagegen không được expose; các frame 001–003 giữ pose bổ dọc gần nhau có chủ ý để giữ nhịp tác động.

## 2026-11-13 — Làm lại màn Chiêu mộ theo bố cục màn Wish (ảnh tham chiếu của owner)

- **Milestone / task:** 7 (M7-2, làm lại tab Chiêu mộ) + 5 (hiển thị banner) — owner yêu cầu: cấu trúc banner đang thô, đổi theo ảnh, tỉ lệ để trong Chi tiết, ảnh tạm + thư mục ảnh trong dự án
- **Trạng thái:** TESTED (headless + ảnh chụp); chưa VERIFIED (owner chưa xem trong Godot)
- **File tạo/sửa:**
  - `scripts/ui/recruit_screen.gd` + `scenes/main/recruit_screen.tscn` (`RecruitScreen`): danh sách banner bên trái (thẻ đang chọn to hơn), banner lớn giữa màn (nhãn loại, tiêu đề, "Tăng xác suất!", ô cam bảo đảm 10 lượt, chú thích, nhân vật / vật phẩm đề cử + sao + nguyên tố + tên giáp + "UP!", thời gian còn lại, dòng bảo đảm), nút Cửa hàng / Chi tiết / Lịch sử, Chiêu mộ ×1 / ×10, vàng + ngọc ở góc trên, nút đóng. **Chi tiết** hiện bảng tỉ lệ (từ cùng config với logic quay), **Lịch sử** hiện 50 lượt gần nhất, **Kết quả** hiện thẻ từng lượt viền theo hạng. Esc / nút đóng lùi từng bước.
  - `scripts/ui/layout_screen.gd` (`LayoutScreen`): lớp nền dùng chung cho màn đặt vị trí theo file bố cục (CharacterScreen giữ bản dựng riêng, có thể chuyển sau).
  - `data/ui/recruit_screen_layout.json`: **file cấu hình bố cục** (vị trí, cỡ chữ, màu), cùng quy ước với màn Nhân vật.
  - `BannerDef` thêm `kind_key`, `title_key`, `banner_art`, `thumb_art`, `end_unix` (0 = không giới hạn); `tools/gen_banner_data.py` ghi các trường này; chữ mới `BANNER_KIND_*`, `BANNER_TITLE_*`, `RECRUIT_UI_*` (25 khóa vi/en).
  - **Thư mục ảnh** `assets/ui/recruit/` + `README.md` (tên file, kích thước, thứ tự tìm ảnh) + 4 ảnh tạm `placeholder_*` sinh bằng `tools/gen_recruit_placeholders.py`; ghi `docs/ASSET_LICENSES.md` mục 3.1.
  - Hub: tab Chiêu mộ mở màn mới (`GameConfig.SCENE_RECRUIT`); bỏ `HubRecruitPanel`; test cũ chuyển sang `tests/unit/ui/test_recruit_screen.gd` (15 test); `tools/screenshot_recruit.gd`.
  - Sửa kèm: bảng lọc màn Nhân vật chặn bấm xuyên xuống nút bên dưới (thêm kiểm tra vào test).
  - Cập nhật OWNER_ASSET_CHECKLIST (hạng, tên, thêm việc ảnh banner).
- **Đã chạy:** `python -X utf8 tools/gen_banner_data.py`, `tools/add_locale_keys.py`, `tools/gen_recruit_placeholders.py`; `godot --headless --import`; `tools/run_tests.ps1`; `godot --path . -s tools/screenshot_recruit.gd`.
- **Kết quả thật:** GdUnit4 458/458, 5 test khói đạt, mã thoát 0. Đã xem 5 ảnh chụp và sửa: ô cam tràn chữ, nhãn trên ảnh tạm đè chữ của màn, nhãn ảnh nhỏ bị cắt, "UP!" xa tên, tên dài ("Đại kiếm Dung Nham") xuống dòng đè hàng sao (giờ thu nhỏ chữ cho vừa một dòng), nhãn loại tràn khỏi thẻ, chú thích banner vũ khí nói nhầm về "nhân vật S".
- **Quyết định Claude chọn:** màn riêng (như màn Nhân vật) thay vì panel trong Hub; nút ×1 / ×10 luôn bấm được, thiếu ngọc thì hiện lý do thay vì làm mờ nút; nút Cửa hàng và "+" cạnh ngọc là placeholder ("chưa có trong bản thử"); tiêu đề banner nhân vật tạm "Nham Thạch Thức Tỉnh", banner vũ khí "Vũ Khí & Ấn Nham Thạch" (chữ tạm, owner đổi trong localization); thời gian còn lại ghi "Không giới hạn" vì chưa có lịch banner (đặt `end_unix` trong `.tres` để hiện đếm ngược); ảnh banner lớn 1301×839 theo khung trong ảnh tham chiếu, ảnh nhỏ 390×226 (gấp đôi ô 195×113).
- **Hạn chế đã biết:** banner hết hạn (`end_unix` đã qua) mới chỉ ghi "Đã kết thúc", chưa khóa quay; nút Cửa hàng chưa có; lượt miễn phí đầu tiên (starter) vẫn chưa gắn vào UI; chưa thử trên điện thoại (màn rộng hơn 16:9 chỉ dịch phần giữa, đã test dựng ở 2560×1080 và 1280×720); ảnh tham chiếu là Genshin Impact: chỉ học bố cục, không dùng chữ, biểu tượng hay hình của bên thứ ba.


## 2026-11-13 — Art: Enkiba ultimate frames (AI)
- **Milestone / task:** art pipeline — owner duyệt và tích hợp animation `ultimate` cho `char_fire_01`.
- **Trạng thái:** TESTED (owner duyệt; kiểm tra frame và toàn bộ test đạt).
- **Owner duyệt:** "Tất cả đều ổn. Chép nó vào dự án luôn nhé"; tích hợp 22 frame, 8 fps, không lặp.
- **File tạo/sửa:** 22 frame `assets/characters/char_fire_01/frames/ultimate/char_fire_01_ultimate_000..021.png` và sidecar `.import`; manifest cập nhật `ultimate`; `docs/ASSET_LICENSES.md` mục 2.1; test animation builder cập nhật số animation đã giao và kiểm tra `ultimate`; runner bỏ cấu hình remote debugger cổng `0` không hợp lệ.
- **Đã chạy:** `python -I tools/frames/approve_frames.py char_fire_01 ultimate` (thực thi bằng Python 3.12 cài sẵn vì `python` không có trong PATH); `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`.
- **Kết quả thật:** phê duyệt và chép 22 frame thành công; GdUnit4 458/458, 0 lỗi / 0 thất bại; 5 smoke test đạt; mã thoát 0.
- **Quyết định Codex chọn:** dùng dải đã owner xem và duyệt; test builder xác nhận 9 animation Enkiba có frame thật.
- **Hạn chế đã biết:** model imagegen không được expose; giữ tỉ lệ tham chiếu 0.80× idle để pose trên không nằm gọn trong canvas 384×384.

## 2026-11-13 — Splash art 2D của Enkiba vào màn Nhân vật (thay chibi ở 5 chỗ)

- **Milestone / task:** art + M7-2 (màn Nhân vật) — owner đưa 5 splash art 2D (không chibi) của Enkiba, yêu cầu xóa nền, phóng to hợp lý và thay vào ảnh chibi ở: nhân vật, tăng cấp, vũ khí, vết thánh, kỹ năng
- **Trạng thái:** TESTED (headless + ảnh chụp 5 tab); chưa VERIFIED (owner chưa xem trong Godot)
- **File tạo/sửa:**
  - `tools/cut_splash.py`: xóa nền trắng + cắt sát, chỉ Pillow + numpy. Nền nối mép (>= 235); lỗ kín (vùng sáng không nối mép, >= 100 px, trắng thuần: khoảng hở giữa tay – kiếm – đầu, khe giữa tay và thân); khử viền sáng trong dải 2 px sát mép; co viền 1 px + làm mượt nhẹ; cắt sát + lề 8 px.
  - `assets/characters/char_fire_01/splash/char_fire_01_splash_{overview,skill,level,stigma,weapon}.png` (PNG alpha, 581–968 px rộng, ~1500 px cao).
  - `CharacterScreen.splash(id, view_key, fallback_portrait)` và mục `art` trong `data/ui/character_screen_layout.json` (đường dẫn mẫu `{id}` / `{name}`, tên file theo màn / tab: **đổi ảnh từng tab bằng cấu hình**); thiếu file thì dùng chibi, riêng ảnh lưng của tab Vết Thánh thiếu thì hiện placeholder (không thay bằng chibi nhìn trước).
  - Layout: vùng ảnh tổng quan [610, 50, 800, 990] (cao hơn); vùng ảnh các tab [60, 0, 880, 1080] (dời phải 60 px để tóc không chạm nút Home); 3 ô Đầu / Thân / Chân chuyển sang cột bên phải ảnh lưng, đúng độ cao đầu / thân / chân; cỡ chữ ô theo cỡ ô.
  - Test: `test_character_screen` thêm 3 (splash đúng ảnh ở 5 chỗ, đổi ảnh bằng cấu hình, dự phòng chibi / placeholder); `docs/ASSET_LICENSES.md` mục 2.1 (5 dòng), `docs/OWNER_ASSET_CHECKLIST.md`.
- **Ánh xạ ảnh → màn (Claude chọn, đổi trong layout JSON):** ảnh 1 (đứng thẳng, kiếm cầm tay) → tổng quan; ảnh 2 (tư thế chiến đấu) → Skill; ảnh 3 (vác kiếm, đưa tay) → Tăng cấp; ảnh 4 (nhìn từ phía sau) → Vết Thánh; ảnh 5 (chống kiếm) → Vũ khí.
- **Đã chạy:** `python -I tools/cut_splash.py` (5 ảnh); `godot --headless --import`; `tools/run_tests.ps1`; `godot --path . -s tools/screenshot_character.gd`.
- **Kết quả thật:** GdUnit4 461/461, 5 test khói đạt, mã thoát 0. Xóa nền: 72–76% điểm ảnh là nền; đã soi viền ở độ phóng to 2× trên nền tối: không còn quầng trắng, lỗ chắn kiếm và khe tay – thân trong suốt.
- **Lỗi tìm thấy và sửa:** trong Pillow 10.2, `ImageDraw.floodfill` trên ảnh tạo từ mảng numpy không làm gì (phải `.copy()` trước) nên bước "nền nối mép" lúc đầu không chạy, tool chỉ xóa được nền nhờ nhánh tìm lỗ kín; sửa và đổi sang quy tắc theo diện tích + độ trắng, kiểm tra trên cả 5 ảnh (thành phần sáng kín lớn nhất đều là nền thật).
- **Quyết định Claude chọn:** ảnh chibi vẫn dùng cho thẻ nhân vật ở danh sách bên dưới và biểu tượng mảnh nhân vật (cắt phần đầu); ảnh splash giữ độ phân giải gốc (không thu nhỏ); ô vết thánh đặt ngoài thân nhân vật để không che ảnh; bảng chỉ số vết thánh vẫn phủ lên phần ủng (nền đen trong suốt 60%).
- **Hạn chế đã biết:** mới Enkiba có splash, 5 nhân vật còn lại vẫn chibi / placeholder; công cụ tạo splash chưa rõ nên ghi giấy phép "không rõ" (cần owner xác nhận để khai báo AI khi phát hành); nút Home chạm nhẹ tóc ở vài pose; ảnh splash ~0.5–0.8 MB mỗi file (tổng 3.5 MB), chấp nhận cho bản đầu.


## 2026-11-14 — Art: Enkiba animations dodge–switch_out (AI)
- **Milestone / task:** art pipeline — owner duyệt gộp các animation từ `dodge` đến hết, tích hợp các bản review còn chờ vào `char_fire_01`.
- **Trạng thái:** TESTED (owner duyệt; checker và toàn bộ test đạt).
- **Owner duyệt:** "duyệt tất cả động tác từ dodge đến hết". `fall` (3 frame) và `ultimate` (22 frame) đã tích hợp trước đó; lần này tích hợp 14 animation, tổng 83 frame: `dodge` 5/15 fps, `land` 3/12, `hurt` 4/12, `knockback` 3/12, `down` 6/12, `hold_charge` 4/12, `hold_release` 9/12, `air_1` 5/18, `air_2` 5/12, `landing_attack` 6/15, `skill_1` 10/10, `skill_2` 13/18, `switch_in` 7/12, `switch_out` 3/12; giữ loop và hit frame theo phiếu.
- **File tạo/sửa:** frame PNG và sidecar `.import` cho 14 animation trong `assets/characters/char_fire_01/frames/`; `frames_manifest.json`; `docs/ASSET_LICENSES.md` mục 2.1; `tests/unit/characters/test_animation_set_builder.gd` kiểm tra 23 animation đã giao cùng số frame.
- **Đã chạy:** `python -I tools/frames/check_frames.py char_fire_01 {dodge,fall,land,hurt,knockback,down,hold_charge,hold_release,air_1,air_2,landing_attack,skill_1,skill_2,switch_in,switch_out}`; `python -I tools/frames/approve_frames.py char_fire_01 <animation>` cho 14 animation; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`.
- **Kết quả thật:** checker báo ĐẠT cho mọi animation đã kiểm tra; GdUnit4 461/461, 0 lỗi / 0 thất bại; 5 smoke test đạt; mã thoát 0.
- **Quyết định Codex chọn:** tích hợp theo nguyên số frame / fps / loop của phiếu; bỏ qua thao tác chép lại `fall` và `ultimate` đã có trong dự án.
- **Hạn chế đã biết:** `air_1` checker cảnh báo tâm chân ở frame 001 (x=113) và 002 (x=89) lệch trái so với mốc x=192; giữ nguyên theo duyệt gộp của owner.

## 2026-11-14 — Công cụ gửi quà thử nghiệm vào tài khoản

- **Milestone / task:** công cụ thử game (không thuộc milestone) — owner yêu cầu tool gửi trực tiếp quà vào account để test
- **Trạng thái:** TESTED (headless + chạy thật lệnh dòng lệnh + ảnh chụp); chưa VERIFIED (owner chưa dùng trong Godot)
- **File tạo/sửa:**
  - `scripts/debug/debug_gift.gd` (`DebugGift`): cú pháp quà, gói quà mẫu, kiểm tra trước (ID lạ / cấp vượt tối đa → không áp gì), áp vào `PlayerProfile` (ngọc, vàng, vật phẩm, trang bị nhiều bản, mở khóa nhân vật, mảnh có tự mở khóa, cấp người chơi chỉ tăng, EXP người chơi), tóm tắt hiển thị, `run_args` cho dòng lệnh.
  - `scripts/ui/debug_gift_screen.gd` + `scenes/main/debug_gift_screen.tscn`: màn "Quà thử nghiệm" (nút gói quà mẫu, ô nhập quà tùy chọn giữ lại nội dung khi sửa, trạng thái tài khoản, khung kết quả); nút mở ở tab Cài đặt của Hub chỉ khi `DebugGiftScreen.available()` (`OS.is_debug_build()`).
  - `tools/give_gift.gd` + `tools/give_gift.ps1` (BOM, tắt gán theo vị trí, in UTF-8): lệnh `--list`, `--dry-run`, `--save-dir=`, mã thoát 0 / 1 / 2.
  - `data/debug/gift_presets.json` (8 gói: rich, gacha_10x10, level_up, enhance, gear, all_characters, promotion, everything); `export_presets.cfg` loại `data/debug/*` khỏi bản Release; `GameConfig.SCENE_DEBUG_GIFT`; 16 khóa dịch `DEBUG_GIFT_*`; `docs/DEBUG_GIFT.md`; AGENTS.md mục 6.
  - Test: `tests/unit/debug/test_debug_gift.gd` (22): cú pháp + lỗi, `all`, gói lồng nhau có chặn vòng, gói mẫu hợp lệ, `everything` áp đủ, áp nguyên khối hoặc không áp gì, cấp không bị hạ, lệnh dòng lệnh (không ghi khi lỗi / dry-run, cộng dồn vào save có sẵn), màn trong game (nút gói, lưu file, lỗi, ô nhập), nút Hub theo bản debug / Release.
  - `tools/screenshot_gift.gd`.
- **Đã chạy:** `godot --headless --import`; `tools\give_gift.ps1 --list`, quà lỗi, quà thật vào `user://test_give`; `tools/run_tests.ps1`; `godot --path . -s tools/screenshot_gift.gd`.
- **Kết quả thật:** lệnh dòng lệnh in đúng tiếng Việt, ID lạ → mã 1 và không ghi file; gửi thật → mã 0, file save tạo đúng; đã xem 3 ảnh chụp màn (bắt đầu, đã gửi, lỗi). GdUnit4 483/483, 5 test khói đạt, mã thoát 0.
- **Lỗi tìm thấy và sửa:** PowerShell gán mục quà đầu tiên vào tham số `-Godot` (báo "không tìm thấy Godot: gems=100") → tắt gán theo vị trí; nút gói quà bị cắt chữ vì tóm tắt dài → hiện chuỗi quà của gói.
- **Quyết định Claude chọn:** hai cách dùng (bảng trong game cho thử tức thì vì game đang mở sẽ ghi đè save do lệnh dòng lệnh sửa; lệnh dòng lệnh cho tự động hóa); quà bỏ qua mọi luật chơi (đây là công cụ debug) và không đụng tới pity, lịch sử chiêu mộ, tiến độ màn; không có nút xóa / đặt lại tài khoản (đã có "Game mới"); đặt nút ở tab Cài đặt thay vì thêm tab Hub; không dùng phím tắt (quy tắc InputRouter).
- **Hạn chế đã biết:** lệnh dòng lệnh phải chạy khi game đã đóng; chưa có quà "đặt cấp nhân vật" (dùng sách EXP + `captain=`); bản Release không có công cụ; chưa thử trên Android (hoãn).

## 2026-11-14 — Kazeyumi: tờ bộ phận và trang điền tên (wireframe)

- **Milestone / task:** art (rig bộ phận) — owner gửi tờ bộ phận cắt lớp của Kazeyumi (`char_wind_01`), yêu cầu tạo wireframe để điền tên
- **Trạng thái:** IMPLEMENTED (chờ owner điền tên)
- **File tạo/sửa:** `assets/characters/char_wind_01/rig_parts/source/char_wind_01_parts_sheet.jpg` (ảnh gốc nền trong suốt, ghép nền trắng), `char_wind_01_parts_boxes.json` (60 khung), `.gdignore`; trang artifact "Bảng tên bộ phận Kazeyumi" (https://claude.ai/artifact/NPXQcciN28KAwKk6eLMpq1, lưu từng ô vào db `labels`, giống trang của Enkiba).
- **Đã chạy:** `python -I tools/sprite_parts/segment_parts.py ... 190 0` → 59 vùng; đọc lại `labels` của trang (trống, đúng vì chưa điền).
- **Kết quả thật:** 59 vùng tách sạch; vùng 24 (áo + áo choàng bản 2) dính mảnh cẳng tay bên dưới → tách tay thành ô 60. Có gợi ý loại + tên cho cả 60 ô (thêm loại "Hiệu ứng" cho mũi tên gió số 42).
- **Lỗi tìm thấy và sửa:** ảnh gốc là WebP nền trong suốt; chuyển thẳng sang JPG làm nền thành đen nên cả tờ thành một khối → ghép lên nền trắng trước khi tách.
- **Hạn chế đã biết:** `tools/sprite_parts/cut_parts.py` đang ghi cứng `char_fire_01` trong manifest (README đã ghi), cần sửa khi cắt Kazeyumi sau khi owner điền xong.

## 2026-11-14 — Kazeyumi: phiếu prompt Codex tạo frame (21 animation)

- **Milestone / task:** art (frame nhân vật) — owner yêu cầu prompt cho Codex tạo chuyển động Kazeyumi (`char_wind_01`) theo mô tả kỹ năng, giống quy trình Enkiba
- **Trạng thái:** IMPLEMENTED (chờ Codex tạo `idle` và owner duyệt từng animation)
- **File tạo/sửa:**
  - `tools/frames/jobs/char_wind_01.json` (phiếu 21 animation), `docs/prompts/codex_frames/char_wind_01/` (00_PHAN_TICH.md + 21 phiếu + README, sinh tự động)
  - `tools/frames/frame_jobs.py`: thêm `timing_ms` / `hits_ms` cho kỹ năng chưa có SkillDef; `sword` → `weapon_state` (giữ tương thích)
  - `tools/frames/gen_prompts.py`: mọi chữ riêng của nhân vật (vũ khí, VFX, mục tự kiểm tra, ghi chú README) chuyển vào `text` trong phiếu JSON
  - `tools/frames/jobs/char_fire_01.json`: chuyển chữ Enkiba vào `text`, bỏ `redo_reason` của idle (Codex đã làm lại, commit 438bc03); phiếu Enkiba sinh lại chỉ khác trạng thái README và phiếu idle
  - Ảnh tham chiếu cắt từ tờ bộ phận: `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`, `rig_parts/source/refs/char_wind_01_ref_*.png` (13 ảnh: toàn thân, pose 54–59, cung, mũi tên, 4 mặt)
  - `assets/characters/char_wind_01/frames_manifest.json`: `working_name` Lyra → Kazeyumi
- **Đã chạy:** `python -I tools/frames/gen_prompts.py char_wind_01` (21 phiếu), `... char_fire_01` (23 phiếu); `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`
- **Kết quả thật:** test TẤT CẢ ĐẠT, mã thoát 0. Số frame tính ra: attack_1/2 5 @ 18 fps, attack_3 8 @ 15, dodge 6 @ 20, hold_release 5 @ 12, air_1 6 @ 18, landing_attack 6 @ 15, skill_1 8 @ 18, skill_2 11 @ 8, switch_in 6 @ 10, ultimate 17 @ 8 (3 lần gọi).
- **Quyết định Claude chọn:**
  - Hai trạng thái cung: `ready` (cầm hạ thấp) và `shoot` (giương bắn); không vẽ mũi tên đã bay (game sinh projectile).
  - Kỹ năng chưa có SkillDef lấy thời gian theo CHARACTER_SKILLS.md: hold_release 100/50/300, air_1 90/90/160, landing_attack 70/80/220 (vùng gió 1 500 ms là VFX), skill_1 150/60/220, skill_2 200/900/300 (6 phát cách 150 ms), ultimate 700/1000/400 (bão 5 s là VFX).
  - Chiều cao đứng mục tiêu 280 px như Enkiba.
- **Hạn chế đã biết:** khi thêm SkillDef cho các kỹ năng trên, đổi phiếu sang `skill` rồi sinh lại; màu mắt / viền vàng trong 00_PHAN_TICH là ước lượng bằng mắt.


## 2026-11-14 — Art: Kazeyumi idle frames (AI)
- **Milestone / task:** art pipeline — owner duyệt và tích hợp animation `idle` cho `char_wind_01`.
- **Trạng thái:** BLOCKED (đã tích hợp 6 frame; toàn bộ test bị Godot crash trước khi chạy test logic).
- **File tạo/sửa:** 6 frame PNG + sidecar `.import` trong `assets/characters/char_wind_01/frames/idle/`; `assets/characters/char_wind_01/frames_manifest.json`; `docs/ASSET_LICENSES.md` mục 2.1; `art_review/char_wind_01/idle/meta.json` ghi duyệt.
- **Đã chạy:** `python -I tools/frames/approve_frames.py char_wind_01 idle` (thực thi bằng Python 3.12 cài sẵn vì `python` không có trong PATH); `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`; chạy lại runner với `-Godot C:\Godot\4.6.3\Godot_v4.6.3-stable_win64.exe`; chạy riêng `C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --script res://tests/smoke/m1_flow_check.gd` để xác định lỗi.
- **Kết quả thật:** approve chép đủ 6 frame, 8 fps, lặp; manifest và giấy phép được cập nhật. Cả hai lần chạy toàn bộ test đều thoát mã 1: GdUnit4 và 5 smoke trả `-1073741819` (Windows access violation); smoke trực tiếp bằng console crash signal 11 với `no debug info in PE/COFF executable`. Smoke trực tiếp bằng executable GUI thoát mã 0 nhưng không có output; runner toàn bộ với executable GUI vẫn gặp cùng lỗi. Chưa có toàn bộ test nào được xác nhận đạt.
- **Quyết định Codex chọn:** giữ tích hợp đã được owner duyệt, ghi trạng thái `BLOCKED`; chưa commit vì điều kiện test mã thoát 0 chưa đạt.
- **Hạn chế đã biết:** cần khắc phục crash môi trường Godot / test runner rồi chạy lại toàn bộ test trước khi commit.

## 2026-11-14 — Kazeyumi, Raikiba: đủ bộ kỹ năng (giữ, trên không, đáp đất, kỹ năng, vũ khí, tuyệt kỹ)

- **Milestone / task:** combat — owner: Kazeyumi và Raikiba mới thử được đòn thường, né, vào sân; làm thêm phần còn lại
- **Trạng thái:** TESTED (chưa thử bằng mắt trong Godot)
- **File tạo/sửa:**
  - `tools/gen_wind_lightning_skills.py` (mới) sinh `data/skills/char_wind_01/{hold_1,hold_2,air_1,air_2,landing,skill,weapon,ultimate}.tres`, `data/skills/char_lightning_01/{hold_1,air_1..3,landing,skill,weapon,ultimate}.tres`, `data/statuses/storm_blessing.tres`; `tools/skill_data_lib.py` thêm `self_statuses`
  - `scripts/combat/skill_def.gd`: `fire_on_charge`, `release_ends`, `dive_angle_deg`, `self_statuses`, `blocks_normal_ms`
  - `scripts/combat/skill_runner.gd`: áp `self_statuses` khi bắt đầu; **sửa lỗi**: mỗi vùng tách một track method (hai vùng cùng `at_ms` trên một track thì key sau ghi đè key trước, vùng đầu không bao giờ sinh)
  - `scripts/player/player_controller.gd`: số đòn trên không = số kỹ năng `air_N` (bỏ trần cứng 2), khóa đòn thường, `auto_hold_skill_for`; `scripts/player/states/combat_states.gd`: đòn giữ tự chạy khi đủ nạp, nhả nút dừng sớm, lao chéo
  - Kit: `wind_kit.gd` (tên trúng kẻ địch đang Chậm −0.3 s CD Phong Vực, tối đa −3 s), `lightning_kit.gd` (Bùng nổ Sét −1 s CD Chớp Giật Liên Hoàn tối đa −3 s, +5 UG)
  - `tests/unit/combat/test_kazeyumi_raikiba_skills.gd` (12 test), `test_combat_data.gd` (thêm storm_blessing); khóa dịch `STATUS_STORM_BLESSING`
- **Đã chạy:** `python -X utf8 tools/gen_wind_lightning_skills.py`; `<godot> --headless --path . --import`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`
- **Kết quả thật:** GdUnit4 496/496, 0 lỗi / 0 thất bại; 5 smoke test đạt; mã thoát 0. Tổng % ATK khớp tài liệu: Kazeyumi giữ 180/300, trên không 135, đáp đất 120, Phong Vực 240, Liên Châu 360, Tuyệt kỹ 1000; Raikiba giữ 240, trên không 150, đáp đất 130, Chớp Giật 210, Song Lôi 200, Tuyệt kỹ 1090.
- **Quyết định Claude chọn:**
  - Kazeyumi Hạ Phong Trận: rơi 500 px/s (thả dù), vùng gió đặt ở chỗ tiếp đất. Phong Vực / Bão Tiễn: buff đồng đội áp cho người dùng lúc cast (chỉ một nhân vật trên sân), không xét đứng trong vùng. Bão kéo 37.5 px mỗi nhịp (= 150 px/s). Thiên Phong Loạt Tiễn lần 1 nối sang lần 2 bằng cửa sổ 200 ms như Enkiba.
  - Raikiba Song Lôi Phi Nhận: thân nhân vật chỉ giữ 140 + 180 ms để vẫn di chuyển được, đao bay độc lập, khóa đòn thường 800 ms. Lôi Trụy Thuấn: vệt điện Chậm 20% gộp vào vụ nổ. Lôi Thần Quyết: nhát đầu +150% ATK nếu mục tiêu có Dấu Sét (bonus_vs_status 1.875 × 80%).
- **Hạn chế đã biết:** chưa làm: nội tại Gió Thuận (buff cả đội), Liên Châu +25% trong Phong Vực, nạp UG +20% trong Phong Vực, Kazeyumi bay lên 300 px khi tuyệt kỹ, Quá Tải của Raikiba làm đòn thường áp Dấu Sét, đòn giữ Raikiba +1 EN mỗi nhịp (đang +3 theo loại đòn giữ). Animation của các chiêu mới còn placeholder (Codex chưa vẽ).

## 2026-11-14 — Kazeyumi, Raikiba: Gió Thuận, Phong Vực theo vùng, Bão Tiễn bay lên, Quá Tải

- **Milestone / task:** combat — owner: làm nốt các phần còn thiếu ở mục trước
- **Trạng thái:** TESTED (chưa thử bằng mắt trong Godot)
- **File tạo/sửa:**
  - `scripts/characters/kits/wind_kit.gd`, `wind_kit_config.gd`: nội tại Gió Thuận (trúng 3 kẻ địch khác nhau trong 4 s → cả đội +10% tốc độ di chuyển, +8% nạp EN 5 s, ICD 10 s); Phong Vực: người trên sân đứng trong vùng (bán kính 300, tâm cách 400 px, 6 s) +15% tốc độ tấn công +10% tốc độ di chuyển, Kazeyumi trong vùng: UG từ đòn thường +20%
  - `scripts/characters/kits/lightning_kit.gd`: Quá Tải — đòn thường áp Dấu Sét (đòn đã có dấu thì không áp thêm)
  - `scripts/combat/skill_def.gd` + `skill_runner.gd` + `player_controller.gd`: `rise_px` / `rise_from_ms` / `rise_to_ms` (bay lên khi tắt trọng lực); `team_combatants` (PartyManager gán) để kit buff cả đội
  - `scripts/combat/status_def.gd`, `status_controller.gd`, `resource_component.gd`, `combatant.gd`: loại chỉ số mới `en_regen_up`; `extra_en` âm được (Raikiba giữ TC +1 EN mỗi nhịp = 3 − 2)
  - `tools/gen_wind_lightning_skills.py` sinh lại kỹ năng + 5 trạng thái mới: `fair_wind`, `fair_wind_haste`, `wind_domain` (dấu kẻ địch trong Phong Vực → Liên Châu +25%), `wind_domain_haste`, `overload`; khóa dịch STATUS_* tương ứng
  - Test: `test_kazeyumi_raikiba_skills.gd` (17 test), `test_combat_data.gd`
- **Đã chạy:** `python -X utf8 tools/gen_wind_lightning_skills.py`; `python -X utf8 tools/add_locale_keys.py`; `<godot> --headless --path . --import`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`
- **Kết quả thật:** GdUnit4 501/501, 0 lỗi / 0 thất bại; 5 smoke test đạt; mã thoát 0. Tuyệt kỹ Kazeyumi đo được bay lên ~300 px sau 700 ms, bão (đặt ở mặt đất) vẫn trúng hình nộm.
- **Quyết định Claude chọn:**
  - Buff tốc độ di chuyển của Gió Thuận / Phong Vực dùng trạng thái riêng (không dùng `wind_step`) vì áp trạng thái trùng tên gộp mức cao nhất và thời gian dài nhất, sẽ kéo dài +25% của né hoàn hảo.
  - Buff trong vùng làm mới mỗi tick, hết sau 0.3 s khi rời vùng; áp cho người đang trên sân (đồng đội vào sân sau cũng nhận).
  - Bão Tiễn đặt lúc 0 ms tại mặt đất rồi bật sau 700 ms, để tâm bão ở dưới chỗ Kazeyumi bay lên. Kazeyumi chỉ treo trên không hết thời lượng kỹ năng (2.1 s) rồi rơi; bão vẫn chạy đủ 5 s.
- **Hạn chế đã biết:** buff "đồng đội trong bão" của tuyệt kỹ Kazeyumi vẫn áp cho bản thân lúc cast (chỉ một người trên sân).


## 2026-11-14 — Kazeyumi: duyệt frame `knockback` đến `ultimate`
- **Milestone / task:** art (frame nhân vật) — owner duyệt các animation từ phiếu 11 đến 21 của `char_wind_01`; gồm `knockback`, `down`, `hold_charge`, `hold_release`, `air_1`, `landing_attack`, `skill_1`, `skill_2`, `switch_in`, `switch_out`, `ultimate`.
- **Trạng thái:** BLOCKED
- **File tạo/sửa:** frame trong `assets/characters/char_wind_01/frames/{knockback,down,hold_charge,hold_release,air_1,landing_attack,skill_1,skill_2,switch_in,switch_out,ultimate}/`; `assets/characters/char_wind_01/frames_manifest.json`; `docs/ASSET_LICENSES.md` mục 2.1; `docs/DEVELOPMENT_LOG.md`.
- **Đã chạy:** `python -I tools/frames/approve_frames.py char_wind_01 <animation>` cho cả 11 animation; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`.
- **Kết quả thật:** Cả 11 animation được approve thành công. Bộ test thoát mã 1; GdUnit4 và 5 smoke test đều crash với mã `-1073741819`, runner in `error(-1): no debug info in PE/COFF executable`. Không commit vì test chưa thoát mã 0 theo yêu cầu.
- **Quyết định Codex chọn:** dùng phạm vi phiếu 11–21 (từ `knockback` tới `ultimate`) theo thứ tự số phiếu.
- **Hạn chế đã biết:** cùng lỗi Godot/test runner đã ghi ở mục trước; cần khắc phục môi trường và chạy lại toàn bộ test trước khi commit.

## 2026-11-14 — Hikarine, Yomigari, Iwagane: đủ bộ kỹ năng + kit nội tại + Kĩ năng vào sân

- **Milestone / task:** combat — owner: làm tiếp các nhân vật còn lại (trước đây ba nhân vật này chỉ có hồ sơ, chưa có kỹ năng)
- **Trạng thái:** TESTED (chưa thử bằng mắt trong Godot)
- **File tạo/sửa:**
  - `tools/gen_light_dark_earth_skills.py` (mới) sinh `data/skills/char_{light,dark,earth}_01/*` (đòn thường, né, giữ + đòn kết, trên không, đáp đất, Kĩ năng thường, vũ khí, tuyệt kỹ, vào sân Thường / Liên kết), 7 trạng thái mới (`sanctuary`, `night_king`, `stone_bone`, `guard`, `hard_armor`, `armor_break`, `stone_god`), config kit `data/characters/char_*_kit.tres`, ghi lại `data/characters/char_{light,dark,earth}_01.tres` (giữ chỉ số cũ, thêm skills_dir, kit, SwitchInDef)
  - Hồi máu: `scripts/combat/heal_def.gd`, `heal_zone.gd` (cả đội / thấp nhất / bản thân / vùng, nhiều nhịp, trễ, đi theo người hồi, xóa hiệu ứng xấu, trạng thái cho người trong vùng, hồi sinh theo `revive_enabled`); `Combatant.heal_target` + signal `heal_done`; `StatusController.cleanse`, `set_magnitude`
  - `SkillDef`: `heals`, `en_per_sec`, `move_while_active`, `release_skill`, `fall_ms`; `SkillRunner`: vùng hồi, tiêu EN theo giây, rơi sau khi bay lên; state Attack: nhả / hết EN / hết giờ → đòn kết (`PlayerController.release_skill_for`, kit quyết định được); di chuyển chậm trong đòn giữ kéo dài
  - `Combatant.receive_hit`: đòn atk_ratio 0 chỉ áp trạng thái (khiêu khích 400 px); `bonus_vs_status = "boss"` (+25% lên boss)
  - Kit: `light_kit.gd` (hồi thừa → khiên, rút CD, UG +30%, Hào Quang, rút CD vũ khí), `dark_kit.gd` (hút máu, Thu hoạch, Dạ Vương, hạ gục mục tiêu Nguyền, Phân Thân Bóng), `earth_kit.gd` (Cốt Đá, chặn / chặn hoàn hảo, nổ Cốt Đá, Thạch Thần, Phản Chấn)
  - `PlayerController.kit_event` → `PartyManager` giảm SI-CD; `SwitchInDef.REDUCE_HEAL_LOW / CURSED_KILL / PERFECT_BLOCK`
  - Test: `tests/unit/combat/test_light_dark_earth_skills.gd` (17 test); `test_combat_data.gd` (danh sách trạng thái); `test_reactions.gd` (mở Liên kết Lyra bằng LinkTracker thay cho né hoàn hảo của Hikarine, vì Hào Quang giờ hồi 3% HP cả đội)
- **Đã chạy:** `python -X utf8 tools/gen_light_dark_earth_skills.py`; `python -X utf8 tools/add_locale_keys.py`; `<godot> --headless --path . --import`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`
- **Kết quả thật:** GdUnit4 518/518, 0 lỗi / 0 thất bại; 5 smoke test đạt; mã thoát 0. Tổng % ATK khớp tài liệu (Hikarine thường 195, Thánh Ân hồi 170% ATK + 4% HP; Yomigari giữ 258, tuyệt kỹ 1150; Iwagane thường 390, đáp đất 310, tuyệt kỹ 1100).
- **Quyết định Claude chọn:**
  - Quả cầu sáng 1200 px/s; Iwagane đòn 3 = kiếm 130% + sóng đá 50%; sóng đá Thạch Phá là một vùng 500×120 đứng yên.
  - Đòn kết của đòn giữ dùng khóa `hold_end` (không phải `hold`) để không bị chọn nhầm khi nhả sớm.
  - Thủ Thế Đại Địa giảm 70% mọi hướng (chưa xét hướng); chặn hoàn hảo = đòn tới trong 200 ms đầu khi đã dựng xong.
  - Hikarine "nạp UG +30% từ việc hồi máu cho đồng đội dưới 50% HP": hồi cho người dưới 50% thì nạp UG ×1.3 trong 5 s.
  - Đêm Vĩnh Hằng: lực kéo 500 px gộp vào nhát 1 (đòn không sát thương không đẩy / kéo được).
  - Lăn Giáp, Thạch Phá: Giáp cứng là trạng thái `hard_armor` (−50%); Khiên Đá 6 s; khiên Liên kết Iwagane 6 s; cửa sổ giảm SI-CD sau khi vào sân 6 s cho cả ba.
- **Hạn chế đã biết:** AI quái chưa đọc trạng thái khiêu khích (Iwagane áp `taunt` nhưng chưa có tác dụng; ảo ảnh khiêu khích của Quang Bộ chưa làm). Đòn thường của Hikarine bay thẳng, chưa tự dẫn. Thiên Trụy Trảm chưa rơi nhanh hơn 30%. Bị Choáng chưa ngắt đòn giữ kéo dài. Hồi sinh tắt theo Q6 (`revive_enabled = false`). Animation còn placeholder.

## 2026-11-14 — Raikiba: tờ bộ phận và trang điền tên (wireframe)

- **Milestone / task:** art (rig bộ phận) — owner gửi tờ bộ phận cắt lớp của Raikiba (`char_lightning_01`), yêu cầu wireframe để điền tên
- **Trạng thái:** IMPLEMENTED (chờ owner điền tên)
- **File tạo/sửa:** `assets/characters/char_lightning_01/rig_parts/source/char_lightning_01_parts_sheet.jpg` (ảnh gốc WebP nền trong suốt, ghép nền trắng), `char_lightning_01_parts_boxes.json` (52 khung), `.gdignore`; trang artifact "Bảng tên bộ phận Raikiba" (https://claude.ai/artifact/JdGdTkh1jCwQBXTj2Cid2p, dựng từ trang Kazeyumi, lưu từng ô vào db `labels`, có gợi ý loại + tên cho cả 52 ô).
- **Đã chạy:** xóa pixel alpha < 250 (ánh sét mờ) rồi `python -I tools/sprite_parts/segment_parts.py <ảnh> ... 190 0` → 49 vùng.
- **Kết quả thật:** 42 vùng phía trên tách sạch. Hàng dưới (5 mặt nhỏ, 5 pose) chồng lên nhau và dính hiệu ứng sét → bỏ các khung gộp, đặt 10 khung bằng tay (5 mặt + 5 pose), thêm 2 khung bằng tay cho dây đai có khóa và băng cổ tay bị dính vào pose.
- **Lỗi tìm thấy và sửa:** máy không có scipy nên không tách theo alpha trực tiếp được; dùng ảnh "đặc" (bỏ pixel bán trong suốt) làm đầu vào cho công cụ tách có sẵn.
- **Hạn chế đã biết:** khung mặt nhỏ hàng dưới đè một phần lên pose 48; `tools/sprite_parts/cut_parts.py` vẫn ghi cứng `char_fire_01`, cần sửa trước khi cắt Kazeyumi / Raikiba.

## 2026-11-14 — Art: phiếu prompt Codex cho Raikiba, bổ sung phiếu Kazeyumi

- **Milestone / task:** art (frame nhân vật) — owner yêu cầu phiếu tạo chuyển động cho Raikiba và gửi các động tác Kazeyumi còn thiếu
- **Trạng thái:** IMPLEMENTED (chờ owner chạy Codex từng phiếu)
- **File tạo/sửa:**
  - Raikiba: `tools/frames/jobs/char_lightning_01.json` (25 animation), `docs/prompts/codex_frames/char_lightning_01/` (00_PHAN_TICH, README, 25 phiếu), 13 ảnh tham chiếu `assets/characters/char_lightning_01/rig_parts/source/refs/` cắt từ tờ bộ phận theo tên owner đã điền (nền trong suốt, xóa mảnh mặt nhỏ / khóa đè lên pose), `frames_manifest.json` working_name = Raikiba.
  - Kazeyumi: phiếu mới `hold_release_2` (Xuyên Phong Tiễn cấp 2) và `air_2` (phát thứ hai trên không); `hold_release`, `air_1`, `skill_1`, `skill_2`, `ultimate` đổi sang lấy thời gian từ SkillDef (số frame không đổi so với bản đã duyệt); `00_PHAN_TICH.md` cập nhật. Thêm 2 phiếu nên số thứ tự phiếu từ 15 trở đi dịch xuống.
  - `tools/gen_wind_lightning_skills.py` → `data/skills/char_wind_01/air_2.tres` animation `air_2`, `hold_2.tres` animation `hold_release_2`.
  - `scripts/player/player_controller.gd`: `animation_or_fallback()` — animation biến thể chưa có hình thì mượn bản gốc (`air_2` → `air_1`, `hold_release_2` → `hold_release`).
  - `tools/frames/frame_jobs.py`: phiếu có `skill` vẫn cho `hits_ms` ghi đè frame trúng đòn.
  - `tests/unit/player/test_animation_fallback.gd` (4 test).
- **Đã chạy:** `python -X utf8 tools/gen_wind_lightning_skills.py`, `python -I tools/frames/gen_prompts.py char_wind_01`, `... char_lightning_01`, `--import`, `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`
- **Kết quả thật:** GdUnit4 522 test, 0 lỗi; 5 test khói ĐẠT; mã thoát 0.
- **Quyết định Claude chọn:** Raikiba `hold_release` là vòng chém lặp 6 frame 15 fps (game giữ tới 1,2 s, thả nút thì dừng) thay vì tính theo thời lượng kỹ năng; `skill_2` chỉ vẽ động tác ném, từ frame ném tay không; ultimate 22 frame ở 8 fps (2,7 s theo SkillDef); `landing_attack` của Kazeyumi giữ 70/80/220 ms như bản đã duyệt (SkillDef hiện 0/80/220).
- **Hạn chế đã biết:** Raikiba chưa có animation bắt đao (`skill_2`) và nhát kết của Lôi Quang Loạn Vũ (chưa có trạng thái trong game). Ở thời điểm này 9 animation Kazeyumi (run, attack_1–3, dodge, jump_up, fall, land, hurt) còn nằm ở `art_review/` chờ owner trả lời "duyệt"; các frame / manifest / ASSET_LICENSES Codex đã sửa chưa commit, không nằm trong commit này.


## 2026-11-14 — Kazeyumi: duyệt frame `run`
- **Milestone / task:** art (frame nhân vật) — owner duyệt animation `run` của `char_wind_01`.
- **Trạng thái:** BLOCKED
- **File tạo/sửa:** `assets/characters/char_wind_01/frames/run/` (8 frame); `assets/characters/char_wind_01/frames_manifest.json`; `docs/ASSET_LICENSES.md` mục 2.1; `docs/DEVELOPMENT_LOG.md`.
- **Đã chạy:** `python -I tools/frames/approve_frames.py char_wind_01 run`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`.
- **Kết quả thật:** Approve thành công: 8 frame, 12 fps. Bộ test thoát mã 1; GdUnit4 và 5 smoke test đều crash với mã `-1073741819`, runner in `error(-1): no debug info in PE/COFF executable`. Không commit vì test chưa thoát mã 0 theo yêu cầu.
- **Hạn chế đã biết:** lỗi Godot/test runner giống lần chạy trước; cần khắc phục môi trường và chạy lại toàn bộ test trước khi commit.


## 2026-11-14 — Kazeyumi: duyệt bảy animation còn lại
- **Milestone / task:** art (frame nhân vật) — owner duyệt `jump_up`, `fall`, `land`, `attack_1`, `attack_2`, `attack_3`, `dodge` của `char_wind_01`.
- **Trạng thái:** BLOCKED
- **File tạo/sửa:** frame trong `assets/characters/char_wind_01/frames/{jump_up,fall,land,attack_1,attack_2,attack_3,dodge}/`; `assets/characters/char_wind_01/frames_manifest.json`; `docs/ASSET_LICENSES.md` mục 2.1; `docs/DEVELOPMENT_LOG.md`.
- **Đã chạy:** `python -I tools/frames/approve_frames.py char_wind_01 <animation>` cho cả bảy animation; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`.
- **Kết quả thật:** Cả bảy animation được approve thành công. Bộ test thoát mã 1; GdUnit4 và 5 smoke test crash với mã `-1073741819`, runner in `error(-1): no debug info in PE/COFF executable`. Không commit vì test chưa thoát mã 0 theo yêu cầu.
- **Quyết định Codex chọn:** vì danh sách trước đó còn tám mục ngoài `run` trong khi owner yêu cầu bảy, để `hurt` chờ duyệt riêng.
- **Hạn chế đã biết:** lỗi Godot/test runner đã tái hiện ở các lần chạy trước; cần khắc phục môi trường và chạy lại toàn bộ test trước khi commit.


## 2026-11-14 — Kazeyumi: duyệt frame `hurt`
- **Milestone / task:** art (frame nhân vật) — owner duyệt animation `hurt` của `char_wind_01`.
- **Trạng thái:** BLOCKED
- **File tạo/sửa:** `assets/characters/char_wind_01/frames/hurt/` (4 frame); `assets/characters/char_wind_01/frames_manifest.json`; `docs/ASSET_LICENSES.md` mục 2.1; `docs/DEVELOPMENT_LOG.md`.
- **Đã chạy:** `python -I tools/frames/approve_frames.py char_wind_01 hurt`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`.
- **Kết quả thật:** Approve thành công: 4 frame, 12 fps. Bộ test thoát mã 1; GdUnit4 và 5 smoke test đều crash với mã `-1073741819`, runner in `error(-1): no debug info in PE/COFF executable`. Không commit vì test chưa thoát mã 0 theo yêu cầu.
- **Hạn chế đã biết:** lỗi Godot/test runner vẫn tái hiện; cần khắc phục môi trường và chạy lại toàn bộ test trước khi commit.

## 2026-11-14 — Raikiba: nhát kết Lôi Quang Loạn Vũ và bắt đao quay về (game + phiếu Codex)

- **Milestone / task:** combat + art — owner yêu cầu đưa vào game động tác bắt đao (Song Lôi Phi Nhận) và nhát chém kết thúc (Lôi Quang Loạn Vũ), rồi cập nhật phiếu
- **Trạng thái:** TESTED
- **File tạo/sửa:**
  - `scripts/combat/skill_def.gd`: `catch_animation`, `catch_at_ms`.
  - `scripts/player/player_controller.gd`: hẹn giờ bắt vũ khí (`catch_left_sec`); tới giờ mà đang đứng yên (state idle, không chạy kỹ năng) thì phát animation bắt, xong quay lại idle; đang chạy / nhảy / đánh thì bỏ qua. Không khóa điều khiển. `_play()` trả về tên animation đã phát.
  - `tools/gen_wind_lightning_skills.py` → `data/skills/char_lightning_01/hold_1.tres` (hồi phục 0, `release_skill = "hold_finish"`), `hold_finish.tres` mới (key `hold_end`, animation `hold_end`, 0/90/220, kháng khựng, không có vùng sát thương), `weapon.tres` (`catch_animation = "weapon_catch"`, `catch_at_ms = 880`).
  - `assets/characters/char_lightning_01/frames_manifest.json` + thư mục `frames/hold_end/`, `frames/weapon_catch/` (.gitkeep).
  - Phiếu: `tools/frames/jobs/char_lightning_01.json`, `docs/prompts/codex_frames/char_lightning_01/` thêm `17_hold_end`, `24_weapon_catch` (các phiếu sau dịch số), sửa `hold_release`, `skill_2`, `00_PHAN_TICH.md`.
  - `tests/unit/combat/test_kazeyumi_raikiba_skills.gd`: đòn giữ nhả nút → `hold_finish`, hết 8 nhịp → `hold_finish`, bắt đao khi đứng yên / bỏ qua khi đang chạy.
- **Đã chạy:** `python -X utf8 tools/gen_wind_lightning_skills.py`, `python -I tools/frames/gen_prompts.py char_lightning_01`, `--import`, GdUnit4 riêng bộ Kazeyumi/Raikiba (21/21), `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`
- **Kết quả thật:** lần đầu 1 lỗi (`test_real_frame_counts_match_folders`: thiếu thư mục frame `hold_end`, `weapon_catch`) → tạo thư mục; lần hai GdUnit4 525 test, 0 lỗi; 5 test khói ĐẠT; mã thoát 0.
- **Quyết định Claude chọn:** nhát kết dùng đúng 220 ms hồi phục của tài liệu và không cộng sát thương (tổng Lôi Quang Loạn Vũ vẫn 240%); chạy cả khi nhả nút sớm lẫn khi hết 8 nhịp. Đao về tay ở 940 ms (ném 140 + đi 400 + về 400); animation bắt bắt đầu ở 880 ms để frame 001 (đao vào tay) rơi vào ~940 ms. Bắt đao chỉ phát khi đứng yên vì đây là động tác đứng, không khóa điều khiển.
- **Hạn chế đã biết:** đang chạy / nhảy lúc đao về thì không có hình bắt đao (đao lặng lẽ về tay); thời điểm bắt không co giãn theo tốc độ tấn công (Song Lôi Phi Nhận là kỹ năng vũ khí, không chịu tốc độ tấn công). Chưa thử bằng mắt trong Godot.

## 2026-11-14 — Kazeyumi: mũi tên gió (bộ phận 42) làm hình mũi tên năng lượng bắn ra

- **Milestone / task:** combat + VFX — owner yêu cầu dùng mũi tên gió (bộ phận số 42 trên trang "Bảng tên bộ phận Kazeyumi") làm mũi tên năng lượng Kazeyumi bắn ra
- **Trạng thái:** TESTED
- **File tạo/sửa:**
  - `assets/characters/char_wind_01/vfx/char_wind_01_vfx_wind_arrow.png` (165×47): cắt khung 42 từ tờ bộ phận, tách nền trắng thành trong suốt (color-to-alpha), lấp lõi sáng ở đầu tên, bỏ mảnh lạ.
  - `scripts/combat/hit_def.gd`: `projectile_sprite`, `projectile_scale`. `scripts/combat/detached_hit.gd`: vùng tách có hình thì gắn `Sprite2D` (xoay theo góc bay, lật theo hướng nhìn, ẩn tới khi bật nếu có trễ) và tắt khối màu tạm của Hitbox.
  - `tools/skill_data_lib.py` (`WIND_ARROW`, `wind_arrow()`), `tools/gen_kael_lyra_data.py`, `tools/gen_switch_in_data.py`, `tools/gen_wind_lightning_skills.py` → 11 SkillDef của `char_wind_01` (đòn thường 3, né, đòn giữ cấp 1/2, trên không 2, Liên Châu 6 tên, vào sân Thường/Liên kết): mọi vùng tên bay có hình mũi tên gió. Dữ liệu nhân vật khác không đổi.
  - `docs/ASSET_LICENSES.md` mục 2: thêm dòng file trên (chỉ commit dòng này; phần Codex đang sửa dở để nguyên).
  - `tests/unit/combat/test_kazeyumi_raikiba_skills.gd`: mọi tên bay của Kazeyumi dùng hình mũi tên gió, đao Raikiba không; bắn đòn thường sinh mũi tên hiện hình và bay về trước.
- **Đã chạy:** 3 script sinh dữ liệu trên, `--import`, GdUnit4 bộ Kazeyumi/Raikiba (23/23), `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`
- **Kết quả thật:** GdUnit4 527 test, 0 lỗi; 5 test khói ĐẠT; mã thoát 0. `git diff --stat data/` chỉ có 11 file `char_wind_01`, toàn dòng thêm.
- **Quyết định Claude chọn:** tỉ lệ vẽ 0.55 (≈91 px) cho tên thường / quạt / Liên Châu / né / vào sân, 0.7 cho đòn giữ cấp 1, 0.9 cho cấp 2 (theo khung va chạm 70 / 90 / 120 px); lọc linear khi thu nhỏ; hòa màu thường (không cộng sáng) để không bị mất trên nền sáng.
- **Hạn chế đã biết:** chưa xem bằng mắt trong Godot; quầng sáng của mũi tên bị tối đi một chút do tách từ nền trắng của ảnh JPEG. Phong Vực (tên rơi như sao băng) và Hạ Phong Trận không có vùng tên bay nên chưa có hình mũi tên.


## 2026-11-14 — Kazeyumi: duyệt frame `hold_release_2`
- **Milestone / task:** art (frame nhân vật) — owner duyệt animation `hold_release_2` của `char_wind_01`.
- **Trạng thái:** BLOCKED
- **File tạo/sửa:** `assets/characters/char_wind_01/frames/hold_release_2/` (5 frame); `assets/characters/char_wind_01/frames_manifest.json`; `docs/ASSET_LICENSES.md` mục 2.1; `docs/DEVELOPMENT_LOG.md`.
- **Đã chạy:** `python -I tools/frames/approve_frames.py char_wind_01 hold_release_2`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`.
- **Kết quả thật:** Approve thành công: 5 frame, 12 fps. Bộ test thoát mã 1; GdUnit4 và 5 smoke test đều crash với mã `-1073741819`, runner in `error(-1): no debug info in PE/COFF executable`. Không commit vì test chưa thoát mã 0 theo yêu cầu.
- **Hạn chế đã biết:** lỗi Godot/test runner vẫn tái hiện; cần khắc phục môi trường và chạy lại toàn bộ test trước khi commit.


## 2026-11-14 — Kazeyumi: duyệt frame `air_2`
- **Milestone / task:** art (frame nhân vật) — owner duyệt animation `air_2` của `char_wind_01`.
- **Trạng thái:** TESTED
- **File tạo/sửa:** `assets/characters/char_wind_01/frames/air_2/` (6 frame); `assets/characters/char_wind_01/frames_manifest.json`; `docs/ASSET_LICENSES.md` mục 2.1; `docs/DEVELOPMENT_LOG.md`.
- **Đã chạy:** `python -I tools/frames/approve_frames.py char_wind_01 air_2`; `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`.
- **Kết quả thật:** Approve thành công: 6 frame, 18 fps. Toàn bộ test thoát mã 0: GdUnit4 và cả 5 smoke test ĐẠT.
- **Hạn chế đã biết:** frame 003 có một chân duỗi thấp hơn các pose trên không còn lại; owner đã duyệt bộ frame.

## 2026-11-14 — HUD trận đấu: cụm nút kỹ năng có hồi chiêu (góc dưới-phải), thanh nhân vật giữa-dưới, icon theo giáp

- **Milestone / task:** UI chiến đấu (README 15.5) — owner đề xuất bố cục theo ảnh tham khảo: nút kỹ năng góc dưới-phải có hồi chiêu, thanh HP/EN ở dưới; icon vẽ tạm bằng code, xuất PNG để owner chỉnh; tùy chọn icon theo từng giáp
- **Trạng thái:** TESTED (đã chụp màn thử nghiệm bằng Godot có cửa sổ để soát, owner chưa xem)
- **File tạo/sửa:**
  - `tools/ui/gen_hud_icons.py` → `assets/ui/hud/skill_icons/default/{attack,jump,dodge,skill,weapon,ultimate}.png` và `assets/ui/hud/skill_icons/char_*_01/{attack,skill,weapon,ultimate}.png` (icon đánh theo loại vũ khí; kỹ năng / tuyệt kỹ theo nguyên tố). Mặc định không ghi đè file đã có.
  - `scripts/ui/hud_icons.gd` (`HudIcons`): tìm icon theo Data ID, thiếu thì dùng `default/`.
  - `scripts/input/touch_controls.gd`: cụm nút luôn hiện (PC: chỉ hiển thị, có phím tắt dưới nút, bỏ qua chuột); joystick chỉ hiện trên máy cảm ứng; icon đổi theo người trên sân; lượt né thành huy hiệu số (`badge_text`). Bố cục chuyển vào `HudTheme.SKILL_BUTTONS`.
  - `scripts/input/touch_button.gd`: vẽ đĩa tối trong mờ + icon, quạt hồi chiêu + số giây, vòng UG, tuyệt kỹ sẵn sàng nhấp nháy vàng, huy hiệu số tròn (kiểu ảnh "3" owner gửi), phím tắt.
  - `scripts/ui/battle_hud.gd`, `scripts/ui/hud_theme.gd`: thẻ nhân vật góc trên-trái → thanh giữa-dưới (chân dung tạm, tên, HP chia 3 đoạn + khiên, EN + số); nút Tạm dừng lên góc trên-trái. `scripts/ui/debug_overlay.gd` sửa chú thích.
  - `docs/ASSET_LICENSES.md` mục 2: thêm dòng icon (chỉ commit dòng này; phần Codex đang sửa dở để nguyên).
  - Test: `tests/unit/ui/test_skill_dock.gd` (4 test), `tests/unit/ui/test_touch_audio.gd` (lượt né đọc `badge_text`).
- **Đã chạy:** `python -I tools/ui/gen_hud_icons.py --force` (lần đầu), `--import`, chụp HUD bằng script SceneTree trong scratchpad (Godot có cửa sổ 1920×1080, bản PC và bản cảm ứng), `powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1`
- **Kết quả thật:** GdUnit4 531 test, 0 lỗi; 5 test khói ĐẠT; mã thoát 0. Ảnh chụp: cụm 6 nút góc dưới-phải không chồng nhau, số giây hồi trên nút U / I, vòng UG quanh O, huy hiệu lượt né trên L, thanh HP/EN giữa-dưới.
- **Quyết định Claude chọn:** bỏ các nút trong ảnh tham khảo không có trong game (nút đặc biệt có thanh 90/150, nút gọi hỗ trợ); đổi nhân vật vẫn ở hai icon dự bị góc trên-phải (README 15.5) thay vì cột chân dung bên phải; UG chỉ hiện bằng vòng quanh nút tuyệt kỹ, lượt né bằng huy hiệu trên nút né; nút nhảy cũng có icon; đường kính nút đánh 200, tuyệt kỹ 176, kỹ năng / vũ khí 150, né 140, nhảy 132 (≥ 128 px); trên PC các nút không nhận chuột.
- **Lệch tài liệu:** README 15.5 ghi thẻ nhân vật trên sân ở góc trên-trái; owner đề xuất đặt xuống dưới (2026-11-14) nên đã chuyển theo owner.
- **Hạn chế đã biết:** chân dung trên thanh HP vẫn là vòng màu + chữ đầu tên (chưa có ảnh chân dung nhỏ); icon là hình trắng đơn giản, owner sẽ vẽ lại; chưa thử trên máy cảm ứng thật.

## 2026-11-14 — Joystick: ảnh vòng HUD của owner, tách nền caro, đế + phím trung tâm

- **Milestone / task:** UI cảm ứng — owner gửi ảnh nút di chuyển (vòng HUD xanh trên nền caro vẽ sẵn), yêu cầu tách nền chính xác, giữ chi tiết xanh mờ ở rìa, không viền cứng / vệt nền cũ, rồi thay vào joystick với vòng xanh nhạt giữa hai vòng trắng trong cùng làm phím trung tâm
- **Trạng thái:** TESTED (owner chưa xem trên máy cảm ứng)
- **File tạo/sửa:**
  - `assets/ui/hud/joystick/joystick_full.png` (816×816, tâm vòng = tâm ảnh), `joystick_base.png`, `joystick_knob.png` (314×314).
  - `tools/ui/remove_checker_bg.py` + `tools/ui/remove_checker_bg/` (7 bước tách nền), `tools/ui/split_joystick.py` (cắt đế / phím ở r = 152 px, mép mềm 4 px, lấp lỗ đế bằng màu kính).
  - `scripts/input/virtual_joystick.gd` (vẽ ảnh đế + phím, độ mờ khi không chạm 0.75; thiếu ảnh thì vẽ hình tròn cũ; `knob_center()`), `scripts/ui/hud_theme.gd` (`JOYSTICK_*`).
  - `docs/ASSET_LICENSES.md` mục 2: dòng ảnh joystick (chỉ commit dòng này).
  - `tests/unit/ui/test_joystick_art.gd` (2 test).
- **Đã chạy:** các bước tách nền trong scratchpad (numpy + Pillow), `python -I -X utf8 tools/ui/split_joystick.py <ảnh sạch>`, `--import`, chụp màn thử nghiệm có cảm ứng (kéo phím sang phải), `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1`
- **Kết quả thật:** GdUnit4 533 test, 0 lỗi; 5 test khói ĐẠT; mã thoát 0. Ảnh chụp màn thử nghiệm (cảm ứng): đế vòng HUD góc dưới-trái, phím trung tâm lệch sang phải theo hướng kéo; góc ảnh trong suốt hoàn toàn.
- **Kỹ thuật / phát hiện:** nền caro của ảnh là ô 11.30 px, có chỗ lệch nhịp (ảnh AI) → phân loại sáng/tối từng ô. Đĩa kính ở giữa là kính MÀU (mỗi kênh R/G/B cho nền lọt qua một mức khác nhau, R ~37%, G ~17%, B ~13%) nên không tách được bằng một độ đục chuẩn; dùng biên độ ô caro đo theo ô + sửa ô lệch + lọc giữ cạnh. Quầng ngoài dùng hồi quy bậc hai từng pixel. Các mảng xanh đậm trong đĩa là bóng đổ ĐỤC có sẵn trong ảnh gốc (không có ô caro ở đó), giữ nguyên. Hình mờ xám hai bên và dấu lấp lánh ở góc dưới-phải nằm ngoài vòng nên đã bỏ.
- **Quyết định Claude chọn:** phím trung tâm = toàn bộ phần bên trong các cung trắng (gồm vòng trắng nhỏ ở tâm và các vòng xanh nhạt), cắt ở khe kính tối r = 152 px; phím lệch tối đa 0.42 bán kính đế; đế lấp giữa bằng màu kính trung vị.
- **Hạn chế đã biết:** kính trong đĩa có vài mảng loang nhẹ khi đặt trên nền rất sáng (trên nền tối của màn chơi không thấy); mép quầng ở vài chỗ còn bậc rất mờ ở cỡ ảnh gốc (thu nhỏ còn ~44% trong game). Owner chưa nói ảnh tạo bằng công cụ gì (nếu là AI cần ghi mục 2.1).

## 2026-11-14 — Joystick thu nhỏ 360 → 240 px

- **Milestone / task:** UI cảm ứng — owner: phím joystick to quá, che nhân vật
- **Trạng thái:** TESTED
- **File tạo/sửa:** `scripts/ui/hud_theme.gd` (`JOYSTICK_SIZE` = 240), `scripts/input/touch_controls.gd` (dùng hằng này thay cho 360 viết cứng)
- **Đã chạy:** chụp màn thử nghiệm có cảm ứng (Godot có cửa sổ 1920×1080), `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1`
- **Kết quả thật:** GdUnit4 533 test, 0 lỗi; 5 test khói ĐẠT; mã thoát 0. Ảnh chụp: joystick chiếm góc dưới-trái, phím ~92 px, không còn che thân nhân vật ở vị trí xuất phát.
- **Quyết định Claude chọn:** 240 px (2/3 cỡ cũ), lề 64 px giữ nguyên; tỉ lệ phím / đế và quãng lệch giữ nguyên.
- **Hạn chế đã biết:** chưa thử ngón tay trên máy thật; nếu vùng chạm nhỏ quá có thể tăng lại trong HudTheme.

## 2026-11-14 — Sảnh chính (Hub) mới: thẻ người chơi, cụm nút lục giác, Túi đồ, Tiếp tế, Xuất kích, Người cộng tác, Thông tin người chơi

- **Milestone / task:** UI Hub (README 15) — owner gửi 5 ảnh tham chiếu, đề xuất sắp xếp sảnh chính: giữ phần bên trái (owner chỉnh sau), bên phải có các nút Trang bị (túi đồ), Người cộng tác (tính năng riêng: tinh linh), Nhân vật (thay nút / tab Nhân vật), Tiếp tế (shop, gacha, nạp nếu online), Xuất kích (thử đội hình, cốt truyện, ải nguyên liệu); nút nhân vật góc trái mở thông tin người chơi (đổi tên, xem trang bị / vết thánh đã có và chưa có)
- **Trạng thái:** TESTED (đã chụp màn bằng Godot có cửa sổ; owner chưa xem)
- **File tạo/sửa:**
  - Tab Trang chủ: `scripts/ui/hub_home_panel.gd` (viết lại), `scripts/ui/hex_button.gd` (nút lục giác, bấm theo hình lục giác), `data/ui/hub_home_layout.json`.
  - Màn mới (`scenes/main/*.tscn` + `scripts/ui/*.gd`): `hub_screen.gd` (nền chung: Trở về, Menu, ô vàng / ngọc), `bag_screen`, `supply_screen`, `sortie_screen`, `companion_screen`, `player_screen`; bố cục `data/ui/hub_screens_layout.json`.
  - `scripts/ui/hub.gd`, `scenes/main/hub.tscn`: bỏ tab Nhân vật (thay bằng nút lục giác), đọc `GameConfig.hub_start_tab` (thẻ Đội hình ở Xuất kích mở thẳng tab Chiến đấu). `scripts/core/game_config.gd`: `SCENE_BAG/SUPPLY/SORTIE/COMPANION/PLAYER`, `hub_start_tab`.
  - Save v4: `scripts/save/save_schema.gd` (`account.name`, `clean_name`, `NAME_MAX` 16, migration 3→4), `scripts/progression/player_profile.gd` (`player_name`, `set_player_name` + lý do).
  - Icon tạm: `tools/ui/gen_hub_icons.py` → `assets/ui/hub/icons/` (11 PNG). `docs/ASSET_LICENSES.md` mục 2 (chỉ commit dòng này).
  - Chữ: 72 khóa mới trong `localization/vi.po` và `en.po` (thêm bằng script riêng vì `tools/add_locale_keys.py` đang có thay đổi chưa commit của Codex).
  - Tài liệu: `docs/design/HUB_FEATURES.md` (bản đồ màn, kế hoạch Người cộng tác, mục riêng Nạp tiền khi phát hành online).
  - Test: `tests/unit/ui/test_hub_home.gd` (10 test).
- **Đã chạy:** `python -I tools/ui/gen_hub_icons.py --force`, `--import`, chụp Hub + 5 màn (dữ liệu thật và dữ liệu giả lập có đồ), `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1`
- **Kết quả thật:** GdUnit4 543 test, 0 lỗi; 5 test khói ĐẠT; mã thoát 0.
- **Quyết định Claude chọn:** phần trái giữ nguyên nội dung cũ, chỉ dời xuống dưới thẻ người chơi; ảnh giữa là nhân vật đầu đội; Xuất kích là lục giác lớn nhất; vũ khí / vết thánh trong Bộ sưu tập tính theo loại (định nghĩa trong data/equipment); Túi đồ xếp đồ đang dùng trước rồi theo độ hiếm; tên người chơi tối đa 16 ký tự; tab Chiêu mộ trên thanh tab giữ lại (trùng Tiếp tế → Tiếp tế) chờ owner quyết; thanh tab Trang chủ / Chiến đấu / Chiêu mộ / Cài đặt giữ nguyên.
- **Hạn chế đã biết:** Shop, Ải nguyên liệu, tab Đề cử / Khiêu chiến / Event, Rèn trang bị: chỉ hiện "Sắp có / Sắp ra mắt". Người cộng tác chưa có gameplay (chờ owner quyết các điểm trong HUB_FEATURES.md). Nạp tiền chỉ là thông báo (bản offline). Icon và nền là tạm; chưa có ảnh vũ khí / vết thánh (thẻ dùng icon tạm). Chưa thử chạm trên máy cảm ứng thật.


## 2026-11-14 — Raikiba: duyệt frame `idle`
- **Milestone / task:** Tạo và duyệt animation `idle` cho `char_lightning_01` (6 frame, 8 fps, lặp).
- **Trạng thái:** TESTED
- **File tạo/sửa:** `assets/characters/char_lightning_01/frames/idle/` (6 PNG + import metadata); `assets/characters/char_lightning_01/frames_manifest.json`; `docs/ASSET_LICENSES.md` mục 2.1; `docs/DEVELOPMENT_LOG.md`.
- **Đã chạy:** `python -I tools/frames/check_frames.py char_lightning_01 idle` (ĐẠT); `python -I tools/frames/approve_frames.py char_lightning_01 idle`; `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1`.
- **Kết quả thật:** Owner duyệt `idle`; approve thành công với 6 frame, 8 fps. GdUnit4: 543 test, 0 lỗi; 5 smoke test ĐẠT; toàn bộ lệnh test thoát mã 0.
- **Hạn chế đã biết:** Phiên bản model chính xác của imagegen không được công cụ công bố; ghi rõ điều này trong metadata và giấy phép.

## 2026-11-14 — Sảnh chính bản 2: ô ghép, splash bên trái, bỏ thanh tab, bánh răng Cài đặt, đổi nền

- **Milestone / task:** UI Hub — owner thấy sảnh còn lộn xộn, gửi ảnh dự án cũ (kiểu ô ghép), ảnh splash Enkiba và ảnh nền tạm. Yêu cầu: giữ chức năng cũ, đổi vị trí / kích thước / cách xếp; bỏ thanh tab ô vuông phía trên; bỏ dòng PROJECT ECLIPSE / vàng / ngọc / đội hình / số màn bên trái, đặt splash nhân vật ở đó; thêm bánh răng Cài đặt góc phải; ô thứ 2 màn Tiếp tế đổi tên Chiêu mộ; thêm tính năng đổi nền (mua, phát trong sự kiện), nền khởi đầu tạm là ảnh thứ 3
- **Trạng thái:** TESTED (đã chụp sảnh và từng bảng nổi; owner chưa xem)
- **File tạo/sửa:**
  - Sảnh: `scenes/main/hub.tscn` (bỏ TopBar / ContentLabel, nút Màn 1 / Màn thử nghiệm dời xuống đáy bảng nổi), `scripts/ui/hub.gd` (viết lại: sảnh + bảng nổi Chiến đấu / Cài đặt / Đổi nền, Back đóng bảng nổi trước), `scripts/ui/hub_home_panel.gd` (viết lại: nền, splash, thẻ người chơi, ô tiền, nút khung tranh + bánh răng, 5 ô ghép), `scripts/ui/tile_button.gd` (ô bình hành, ảnh phủ + dải chữ màu, bấm theo hình), `data/ui/hub_home_layout.json` (viết lại). Bỏ `scripts/ui/hex_button.gd`.
  - Nền: `scripts/progression/background_def.gd`, `data/backgrounds/bg_sky_garden.tres`, `assets/placeholders/placeholder_hub_bg_sky_garden.png`, `scripts/ui/hub_background_panel.gd`; save v5 (`cosmetics.backgrounds`, `cosmetics.hub_background`, migration 4→5) trong `scripts/save/save_schema.gd`; `PlayerProfile` thêm `all_backgrounds`, `owns_background`, `hub_background`, `set_hub_background`, `unlock_background`, `buy_background`.
  - Icon: `tools/ui/gen_hub_icons.py` thêm `settings` (bánh răng), `background` (khung tranh).
  - Chữ: `SUPPLY_GACHA_TITLE` / `SUPPLY_GACHA_GO` → Chiêu mộ / Đi chiêu mộ (en Recruit / Go recruit); 14 khóa mới (nền, bánh răng).
  - Tài liệu: `docs/design/HUB_FEATURES.md` (bản đồ màn bản 2, mục Nền sảnh), `docs/ASSET_LICENSES.md` (dòng ảnh nền tạm + số icon; chỉ commit phần này).
  - Test: `tests/unit/ui/test_hub_home.gd` (sảnh ô ghép, bảng nổi, bình hành, nền), `tests/unit/ui/test_hub_panels.gd` (bỏ test dòng tóm tắt), `tests/smoke/m1_flow_check.gd` (mở bảng Chiến đấu bằng `show_tab`, Esc đóng bảng nổi), `tests/smoke/m1_i18n_check.gd` (đọc chữ ô ghép).
- **Đã chạy:** `python -I tools/ui/gen_hub_icons.py`, `--import`, chụp sảnh + 3 bảng nổi + Tiếp tế, `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1`
- **Kết quả thật:** lần đầu 1 lỗi (test v4 cố định VERSION = 4) → nới thành ≥ 4; ảnh chụp đầu cho thấy bảng nổi bị lớp sảnh (top_level) đè → bỏ top_level, sảnh phủ kín theo anchor. Lần cuối GdUnit4 543 test, 0 lỗi; 5 test khói ĐẠT; mã thoát 0.
- **Quyết định Claude chọn:** hàng trên Nhân vật + Xuất kích (lớn), hàng dưới Trang bị, Tiếp tế, Người cộng tác; ảnh ô Nhân vật / Trang bị lấy tạm splash skill / weapon của Enkiba, ô khác dùng icon; màu dải chữ theo ảnh tham chiếu; Cài đặt / Chiến đấu / Đổi nền là bảng nổi trong sảnh (không tạo màn mới); nút bánh răng / khung tranh 84 px (owner muốn icon nhỏ; nhỏ hơn mốc 128 px của README).
- **Lưu ý giấy phép:** ảnh nền thứ 3 owner gửi trùng nền sảnh của một game thương mại → để ở `assets/placeholders/` tên `placeholder_*` (bản Release tự loại), ghi KHÔNG SHIP trong ASSET_LICENSES; owner cần thay trước khi phát hành. Ảnh dự án cũ chỉ dùng làm tham khảo bố cục, không chép vào dự án.
- **Hạn chế đã biết:** chưa có Shop nên mua nền chỉ trong bảng Đổi nền; chưa có nền thứ hai để thử mua (đã thử bằng nền giả lập trong test); chưa có ảnh riêng cho ô Xuất kích / Tiếp tế / Người cộng tác; chưa thử chạm trên máy thật.


## 2026-11-14 — Raikiba: duyệt frame `run`
- **Milestone / task:** Tạo và duyệt animation `run` cho `char_lightning_01` (8 frame, 12 fps, lặp).
- **Trạng thái:** TESTED
- **File tạo/sửa:** `assets/characters/char_lightning_01/frames/run/` (8 PNG + import metadata); `assets/characters/char_lightning_01/frames_manifest.json`; `docs/ASSET_LICENSES.md` mục 2.1; `docs/DEVELOPMENT_LOG.md`.
- **Đã chạy:** `python -I tools/frames/check_frames.py char_lightning_01 run` (ĐẠT); `python -I tools/frames/approve_frames.py char_lightning_01 run`; `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1`.
- **Kết quả thật:** Owner duyệt `run`; approve thành công với 8 frame, 12 fps. GdUnit4: 554 test, 0 lỗi; 5 smoke test ĐẠT; toàn bộ lệnh test thoát mã 0.
- **Quyết định Codex chọn:** Dải đầu có nền trắng alpha thấp nên xóa lớp nền mờ trước khi cắt; dải thứ hai giữ alpha gốc.
- **Hạn chế đã biết:** Phiên bản model chính xác của imagegen không được công cụ công bố; ghi rõ điều này trong metadata và giấy phép.

## 2026-11-14 — Mục tiêu chiến đấu, màn thông tin màn chơi, đội hình splash và chọn giáp
- **Milestone / task:** UI Hub / màn chơi — owner gửi 3 ảnh tham chiếu: mỗi lần vào màn có phần mục tiêu chiến đấu, đạt mỗi mục tiêu thưởng thêm vàng; chọn giáp giữ logic cũ nhưng đổi giao diện: đang chọn = lưới giáp sở hữu + 3 vị trí nhân vật đứng idle; chọn xong = splash 3 nhân vật, chạm để chọn lại.
- **Trạng thái:** TESTED (đã chụp 3 màn; owner chưa xem trong Godot)
- **File tạo/sửa:**
  - Mục tiêu: `scripts/world/battle_objectives.gd` (mới), `scripts/world/stage_controller.gd` (đếm đòn / sát thương chịu / số lần gục, chấm khi thắng, cộng vàng, lưu mục tiêu đã đạt), `scripts/ui/result_screen.gd` (dòng mục tiêu + vàng thưởng, khung kết quả lớn hơn), `data/stages/stage_01.json` (`desc_key`, `recommended_level`, 3 mục tiêu).
  - Màn mới: `scripts/ui/stage_info_screen.gd` + `scenes/main/stage_info_screen.tscn`, `scripts/ui/party_prep_screen.gd` + `scenes/main/party_prep_screen.tscn`, `scripts/ui/party_select_screen.gd` + `scenes/main/party_select_screen.tscn`, `scripts/ui/character_art.gd` (chân dung / splash / frame idle, cắt phần trên splash).
  - Nối luồng: `scripts/core/game_config.gd` (`SCENE_STAGE_INFO`, `SCENE_PARTY_PREP`, `SCENE_PARTY_SELECT`, `prep_launch_stage`), `scripts/ui/sortie_screen.gd` (Cốt truyện → Thông tin màn; Đội hình → màn Đội hình), `scripts/progression/player_profile.gd` (`toggle_party` + mã lý do, dùng chung với `HubBattlePanel`).
  - Bố cục / chữ: `data/ui/hub_screens_layout.json` (mục `stage_info`, `party_prep`, `party_select`, màu nguyên tố), `localization/vi.po`, `en.po` (30 khóa).
  - Test: `tests/unit/world/test_battle_objectives.gd`, `tests/unit/ui/test_party_screens.gd` (mới), `tests/unit/world/test_stage_controller.gd` (vàng có thưởng mục tiêu), `tests/unit/ui/test_hub_home.gd` (đích mới của thẻ Xuất kích), `tests/smoke/m8_playthrough_check.gd` (vàng = 1200 + thưởng mục tiêu).
  - Tài liệu: `docs/design/HUB_FEATURES.md` (mục "Vào màn").
- **Đã chạy:** `--import`, chụp 3 màn bằng script SceneTree, `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1`
- **Kết quả thật:** lần đầu test khói m8 lỗi 2 bước (vàng cố định 1200, chưa tính thưởng mục tiêu) → sửa thành 1200 + thưởng (lần chạy đạt cả 3 mục tiêu, +1000). Lần cuối GdUnit4 554 test, 0 lỗi; 5 test khói ĐẠT; mã thoát 0.
- **Quyết định Claude chọn:** mục tiêu Màn 1: qua màn trong 5:00 (+300), chịu ≤ 25 đòn (+300), không ai gục (+400); thưởng vàng **mỗi lần** đạt (theo lời owner), ghi thêm "Đã đạt" khi từng đạt; đòn 0 sát thương không tính; Thông tin màn chỉ cho Cốt truyện, Thử đội hình vẫn vào thẳng; màn Đội hình mở từ thẻ Đội hình có nút Xác nhận thay cho Khai chiến; bảng Chiến đấu cũ ở sảnh giữ lại (dùng chung `toggle_party`) cho test khói và đường dự phòng; không làm thể lực, buff đội, skill đội trưởng (game chưa có).
- **Hạn chế đã biết:** chưa có ảnh xem trước màn (hiện icon); chỉ Enkiba có splash, Kazeyumi dùng chân dung chibi, Raikiba dùng frame idle; nhân vật chưa có frame idle hiện chân dung; chưa thử chạm trên máy thật.

## 2026-11-14 — Raikiba: duyệt frame `attack_1`
- **Milestone / task:** Tạo và duyệt animation `attack_1` cho `char_lightning_01` (4 frame, 18 fps, không lặp).
- **Trạng thái:** TESTED
- **File tạo/sửa:** `assets/characters/char_lightning_01/frames/attack_1/` (4 PNG + import metadata); `assets/characters/char_lightning_01/frames_manifest.json`; `docs/ASSET_LICENSES.md` mục 2.1; `docs/DEVELOPMENT_LOG.md`.
- **Đã chạy:** `python -I tools/frames/approve_frames.py char_lightning_01 attack_1`; `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1`.
- **Kết quả thật:** Owner duyệt `attack_1`; approve thành công với 4 frame, 18 fps. GdUnit4: 554 test, 0 lỗi; 5 test khói ĐẠT; mã thoát 0.
- **Quyết định Codex chọn:** giữ nguyên hai frame impact liền nhau (001–002) để thể hiện nhịp giữ pose trúng đòn theo phiếu.
- **Hạn chế đã biết:** Phiên bản model chính xác của imagegen không được công cụ công bố; ghi rõ điều này trong metadata và giấy phép.
