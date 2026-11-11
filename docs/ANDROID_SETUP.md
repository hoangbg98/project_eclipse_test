# Cài đặt để xuất bản Windows và Android (M1-8)

> Owner làm các bước cài đặt (tải file, cài phần mềm, cắm điện thoại).
> Claude chạy lệnh xuất bản khi máy sẵn sàng.
>
> Sau mỗi bước, chạy script kiểm tra (chỉ đọc, không sửa gì):
>
> ```
> powershell -ExecutionPolicy Bypass -File tools\check_build_env.ps1
> ```
>
> Khi mọi dòng là `[OK]` thì báo Claude để build.

## Tình trạng máy ngày 2026-11-11

| Thành phần | Tình trạng | Cần làm |
|---|---|---|
| Godot 4.6.3 | Có (`C:\Godot\4.6.3\`) | — |
| Export templates 4.6.3 | **Chưa có** | Bước 1 |
| JDK | Có JDK 25 (Liberica), Editor đang trỏ vào đây | Bước 2 (khuyến nghị JDK 17) |
| Android SDK | **Chưa có**; Editor trỏ tới `%LOCALAPPDATA%\Android\Sdk` nhưng thư mục không tồn tại | Bước 3 |
| Keystore debug | Có (Godot tự tạo) | — |
| adb | Có bản cũ 30.0.3 ở `C:\Windows\adb.exe` | Lưu ý ở bước 4 |

---

## Bước 1 — Export templates (cần cho cả Windows và Android)

1. Mở Godot 4.6.3 (`Godot_v4.6.3-stable_win64.exe`), mở project `C:\Dev\PROJECT_ECLIPSE`.
2. Menu **Editor → Manage Export Templates…**
3. Bấm **Download and Install**, chọn nguồn chính thức (godotengine.org / GitHub).
   File khá lớn, chờ tải xong.
4. Kiểm tra: thư mục `%APPDATA%\Godot\export_templates\4.6.3.stable\` có file
   `windows_debug_x86_64.exe` và `android_debug.apk`.

> Xong bước này Claude đã build được bản **Windows** (không cần bước 2–4).

## Bước 2 — JDK 17

Tài liệu Godot 4.6 yêu cầu **JDK 17**. JDK 25 đang cài có thể chạy được nhưng không
được hỗ trợ chính thức; nếu lỗi khi ký APK thì đây là nghi phạm đầu tiên.

1. Cài một bản OpenJDK 17 (ví dụ Liberica JDK 17 hoặc Eclipse Temurin 17). Cài song
   song với JDK 25, không cần gỡ JDK 25.
2. Trong Godot: **Editor → Editor Settings → Export → Android → Java SDK Path**,
   chọn thư mục JDK 17 (thư mục chứa `bin\java.exe`).

## Bước 3 — Android SDK

Cách dễ nhất là cài **Android Studio** (có sẵn SDK Manager):

1. Cài Android Studio, mở lần đầu, để nó cài SDK vào mặc định
   `%LOCALAPPDATA%\Android\Sdk` (Godot đang trỏ sẵn vào đây).
2. **More Actions → SDK Manager**:
   - Tab **SDK Platforms**: chọn **Android 15 (API 35)**.
   - Tab **SDK Tools** (bật *Show Package Details*):
     - **Android SDK Build-Tools 35.0.1**
     - **Android SDK Platform-Tools**
     - **Android SDK Command-line Tools (latest)**
3. Bấm Apply, chờ cài xong.
4. Trong Godot: **Editor Settings → Export → Android → Android SDK Path** phải là
   `C:\Users\<tên>\AppData\Local\Android\Sdk`.

> Số phiên bản trên lấy theo tài liệu Android của Godot 4.x. Nếu hộp thoại
> **Project → Export → Android Debug** báo thiếu gói khác, cài đúng gói nó nêu.
> Không cần NDK, CMake hay Gradle vì preset không dùng Gradle build.

## Bước 4 — Điện thoại

1. Trên điện thoại: **Cài đặt → Thông tin điện thoại**, chạm **Số hiệu bản tạo
   (Build number)** 7 lần để bật Tùy chọn nhà phát triển.
2. **Tùy chọn nhà phát triển → Gỡ lỗi USB (USB debugging)**: bật.
3. Cắm cáp USB vào máy tính, trên điện thoại chọn **Cho phép** khi được hỏi
   (tick "Luôn cho phép từ máy tính này").
4. Chạy script kiểm tra, dòng "Điện thoại qua USB" phải là `[OK]`.

**Về adb cũ ở `C:\Windows`:** nếu gặp lỗi `adb server version (...) doesn't match`,
hai bản adb đang tranh nhau. Dùng adb trong SDK
(`%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`); có thể chạy
`adb kill-server` bằng bản trong SDK rồi thử lại. Không bắt buộc xóa bản cũ.

## Bước 5 — Build và cài (Claude làm, hoặc owner tự làm)

Claude chạy:

```
Godot_v4.6.3-stable_win64_console.exe --headless --path . --export-debug "Android Debug" build/android/ProjectEclipse-debug.apk
adb install -r build/android/ProjectEclipse-debug.apk
```

Hoặc owner làm trong editor: **Project → Export → Android Debug → Export Project**
(để tick **Export With Debug**), rồi cài APK bằng `adb install -r`. Có thể bấm biểu
tượng Android ở góc trên phải editor (Remote Debug / One-click deploy) để cài và
chạy luôn khi điện thoại đang cắm.

## Bước 6 — Thử trên điện thoại

| # | Thử | Mong đợi |
|---|---|---|
| 1 | Mở app | Màn ngang, toàn màn hình, không viền đen |
| 2 | Boot | Logo + thanh tiến độ + `v0.1.0-m1`, khoảng 1 giây sau sang Title |
| 3 | Title | Nút "Tiếp tục" xám; chữ tiếng Việt **đủ dấu** (Tiếp tục, Game mới, Thoát) |
| 4 | Chạm "Game mới" | Mờ chuyển sang Hub, 5 tab bấm được, nội dung đổi theo tab |
| 5 | Phím Back của Android ở Hub | Về Title |
| 6 | Phím Back ở Title | Không thoát app, không treo |
| 7 | Nút "‹ Quay lại" ở Hub | Về Title |
| 8 | Kích thước nút | Chạm dễ bằng ngón cái, không bấm nhầm |
| 9 | Đổi ngôn ngữ máy sang English rồi mở lại app | Chữ thành tiếng Anh |

Điều khiển cảm ứng (joystick, nút đánh) **chưa có trên màn nào**, sẽ thử ở M2-3.

### Mẫu báo kết quả cho Claude

```
Máy: <hãng, model>, Android <phiên bản>, màn hình <tỉ lệ nếu biết, vd 20:9>
Cài APK: được / lỗi <thông báo>
1..9: ĐẠT / LỖI <mô tả>, ghi số mục
Ảnh chụp màn hình (nếu có lỗi hiển thị)
```
