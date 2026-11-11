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
