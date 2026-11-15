# Máy chủ PROJECT ECLIPSE (Nakama) — hướng dẫn vận hành

Giai đoạn 1 (M9-1): đăng nhập bằng thiết bị, mã người chơi 8 số, ví trên máy chủ (`gems`, `gold`),
tool phát quà cho QTV (nạp bằng chuyển khoản QR thủ công). Ví máy chủ **chưa** gộp với save trên máy.

## Thành phần

| File | Việc |
|---|---|
| `setup_local.ps1` | Tải bản portable Nakama, PostgreSQL, cloudflared vào `server/.runtime/` (không vào git), tạo khóa bí mật, khởi tạo DB. Chạy 1 lần. |
| `start_local.ps1` | Bật PostgreSQL (cổng 5433) + Nakama (API 7350, trang quản trị 7351). `-Lan`: mở 7350 cho máy cùng mạng LAN. |
| `tunnel.ps1` | Mở đường hầm `https://....trycloudflare.com` tới 7350, in địa chỉ. Địa chỉ **đổi mỗi lần chạy**. |
| `stop_local.ps1` | Tắt đường hầm, Nakama, PostgreSQL. Dữ liệu giữ nguyên. |
| `grant.ps1` | Tool QTV: tra cứu người chơi theo mã, phát / thu hồi tiền. |
| `modules/index.js` | Module máy chủ (RPC `eclipse_profile`, `admin_find`, `admin_grant`). Sửa xong phải khởi động lại Nakama. |
| `nakama/config.yml` | Cấu hình chung, không chứa khóa. |
| `docker-compose.yml`, `.env.example` | Dùng khi chuyển lên VPS Linux. |

Khóa bí mật của máy thử ở `server/.runtime/secrets.json`: **không gửi cho ai, không commit**.
`http_key` trong file đó cho phép phát quà, ai có nó là phát quà được.

## Chạy thử nghiệm (máy Windows của owner)

```
powershell -ExecutionPolicy Bypass -File server\setup_local.ps1    (1 lần)
powershell -ExecutionPolicy Bypass -File server\start_local.ps1
powershell -ExecutionPolicy Bypass -File server\tunnel.ps1         (in địa chỉ trycloudflare)
```

Người thử: mở game → **Trực tuyến (thử nghiệm)** → dán địa chỉ → **Kết nối** → thấy mã người chơi.

Trang quản trị Nakama: `http://127.0.0.1:7351` (chỉ trên máy chạy server), tài khoản `admin`,
mật khẩu = `console_password` trong `secrets.json`.

Kiểm tra nhanh từ dòng lệnh (game → máy chủ):

```
C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --script res://tools/online_e2e.gd -- --server=https://xxx.trycloudflare.com
```

## Quy trình nạp QR thủ công (QTV)

1. Người chơi chuyển khoản, nội dung ghi **mã người chơi** (vd `ECL 32354120`).
2. QTV xem sao kê, lấy **mã giao dịch** của ngân hàng.
3. Tra cứu rồi phát:

```
powershell -ExecutionPolicy Bypass -File server\grant.ps1 -Code 32354120
powershell -ExecutionPolicy Bypass -File server\grant.ps1 -Code 32354120 -Gems 600 -Ref FT26321ABC -Operator ten_qtv -Note "goi 50k"
```

- Mỗi `-Ref` chỉ phát được **một lần**: phát nhầm lần hai máy chủ báo lỗi.
- Số âm = thu hồi (chuyển khoản lỗi). Mỗi lần phát lưu bản ghi (collection `admin_grant`) và sổ ví (wallet ledger),
  xem trong trang quản trị.
- Số lượng mỗi gói (bao nhiêu ngọc cho bao nhiêu tiền) là quyết định của owner, chưa có trong dữ liệu.

## Giới hạn giai đoạn 1

- Đường hầm trycloudflare: chỉ để thử, địa chỉ đổi mỗi lần, không cam kết ổn định.
- Máy chủ sống theo máy tính của owner: tắt máy / ngủ / Windows Update khởi động lại = người chơi mất kết nối.
- Chưa backup tự động. Sao lưu tay: `server\.runtime\pgsql\bin\pg_dump.exe -h 127.0.0.1 -p 5433 -U nakama nakama > backup.sql`.
- Mỗi bản cài game = một tài khoản (mã thiết bị ngẫu nhiên trong `user://online_device.cfg`); cài lại / xóa dữ liệu
  game = tài khoản mới. Liên kết email / khôi phục tài khoản để giai đoạn sau.
