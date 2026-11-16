# Máy chủ PROJECT ECLIPSE (Nakama) — hướng dẫn vận hành

Giai đoạn 1 (M9-1, M9-3, M9-6): tài khoản (tên + email + mật khẩu, màn Đăng nhập khi mở game), mã người chơi 8 số, ví trên máy chủ (`gems`, `gold`),
tool phát quà cho QTV (nạp bằng chuyển khoản QR thủ công), cloud save, chat. Ví máy chủ **chưa** gộp với save trên máy.

## Thành phần

| File | Việc |
|---|---|
| `setup_local.ps1` | Tải bản portable Nakama, PostgreSQL, cloudflared vào `server/.runtime/` (không vào git), tạo khóa bí mật, khởi tạo DB. Chạy 1 lần. |
| `start_local.ps1` | Bật PostgreSQL (cổng 5433), cổng vào `gateway.mjs` (7360) + Nakama (API 7350, trang quản trị 7351). `-Lan`: mở cổng vào cho máy cùng mạng LAN. |
| `tunnel.ps1` | Mở đường hầm `https://....trycloudflare.com` tới cổng vào 7360, in địa chỉ. Địa chỉ **đổi mỗi lần chạy**. |
| `gateway.mjs` | Cổng vào (Node.js, cổng 7360): `/music/` phát nhạc + bản nốt của chế độ nhịp điệu (M10), mọi đường dẫn khác chuyển tới Nakama. Game mặc định gọi `http://127.0.0.1:7360`. |
| `music/` | Chế độ nhịp điệu: `songs.json` (danh sách bài), nhạc, `charts/`, `catalog.json` (sinh bằng `python -X utf8 -I tools/rhythm/build_catalog.py`), `fixed/` (bản nốt cố định ải boss). Xem `docs/design/RHYTHM_MODE.md`. |
| `stop_local.ps1` | Tắt đường hầm, Nakama, PostgreSQL. Dữ liệu giữ nguyên. |
| `grant.ps1` | Tool QTV: tra cứu người chơi theo mã, nạp theo gói (`-Pack`), phát / thu hồi tay, mở lại thưởng nạp lần đầu, sửa thẻ tháng. |
| `moderate.ps1` | Tool QTV kiểm duyệt chat: xem báo cáo, đánh dấu đã xử lý, cấm / gỡ cấm chat. |
| `tests/topup_smoke.mjs` | Kiểm tra module nạp tiền trên máy chủ thật bằng Node: `node server/tests/topup_smoke.mjs` (**tăng kỳ thưởng nạp lần đầu toàn máy chủ**, người chơi thật được thưởng lần đầu thêm một lần). |
| `tests/chat_smoke.mjs` | Kiểm tra module chat trên máy chủ thật bằng Node (không cần Godot): `node server/tests/chat_smoke.mjs`. |
| `modules/index.js` | Module máy chủ (RPC `eclipse_profile`, `admin_find`, `admin_grant`, `save_get`, `save_put`, `chat_find`, `chat_report`, `admin_chat_*`; hook chat). Sửa xong phải khởi động lại Nakama. |
| `nakama/config.yml` | Cấu hình chung, không chứa khóa. |
| `docker-compose.yml`, `.env.example` | Dùng khi chuyển lên VPS Linux. |

Khóa bí mật của máy thử ở `server/.runtime/secrets.json`: **không gửi cho ai, không commit**.
`http_key` trong file đó cho phép phát quà, ai có nó là phát quà được.

## Chạy thử nghiệm (máy Windows của owner)

```
powershell -ExecutionPolicy Bypass -File server\setup_local.ps1    (1 lần)
python -X utf8 -I tools\rhythm\build_catalog.py                    (1 lần, và mỗi khi thêm / đổi bài nhạc)
powershell -ExecutionPolicy Bypass -File server\start_local.ps1
powershell -ExecutionPolicy Bypass -File server\tunnel.ps1         (in địa chỉ trycloudflare)
```

Người thử: mở game → màn **Đăng nhập** hiện sau logo → **Đổi** (cạnh dòng "Máy chủ") → dán địa chỉ → **Lưu**
→ thẻ **Tạo tài khoản** (tên 3–20 ký tự không dấu, email, mật khẩu ≥ 8 ký tự) → vào game. Mã người chơi xem ở
nút **Tài khoản** trên màn Title. "Ghi nhớ đăng nhập" bật thì lần sau tự vào; "Chơi ngoại tuyến" bỏ qua máy chủ.

Máy chủ coi như dịch vụ ngoài dự án Godot: game chỉ biết địa chỉ (`default_server_url` trong
`data/config/online_config.json`, người chơi đổi được). Khi có tên miền / VPS cố định, sửa `default_server_url`
rồi build lại là người chơi không phải nhập gì. Tắt màn Đăng nhập: `"login_on_start": false`; chạy game với
tham số `-- --offline` cũng bỏ qua.

Trang quản trị Nakama: `http://127.0.0.1:7351` (chỉ trên máy chạy server), tài khoản `admin`,
mật khẩu = `console_password` trong `secrets.json`.

Kiểm tra nhanh từ dòng lệnh (game → máy chủ):

```
C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . --script res://tools/online_e2e.gd -- --server=https://xxx.trycloudflare.com
```

## Cloud save (M9-3): mỗi tài khoản một thế giới

- Máy chủ giữ bản gốc save của từng tài khoản (storage `save`/`main`, chỉ ghi qua RPC `save_put`). Bản trước mỗi lần
  ghi nằm ở `save_backup`/`prev`: QTV khôi phục được trong trang quản trị (Storage) khi người chơi báo mất dữ liệu.
- Trên máy người chơi: bản đệm riêng từng tài khoản ở `user://saves_online/<user_id>/`; save ngoại tuyến
  (`user://saves`) giữ nguyên, dùng khi bấm "Chơi ngoại tuyến".
- Lần đầu đăng nhập mà tài khoản chưa có save và máy có save ngoại tuyến: game hỏi mang lên hay bắt đầu mới.
- Mỗi lần game lưu, save gửi lên sau 2 giây. Mất mạng thì giữ trên máy, tự gửi lại mỗi 30 giây và ở lần đăng nhập sau.
- Hai thiết bị cùng chơi một tài khoản: thiết bị gửi bản cũ bị từ chối ("Tài khoản vừa được chơi ở thiết bị khác"),
  ngừng gửi; đăng nhập lại sẽ lấy bản trên máy chủ. Không bao giờ ghi đè bản mới hơn.
- Save vẫn do game tạo ra nên người chơi sửa được trước khi gửi (chưa chống gian lận). Ngọc / gacha chuyển lên máy
  chủ ở M9-2.

## Chat (M9-6): phòng Thế giới + nhắn riêng, không co-op

Định hướng: mỗi người một thế giới riêng, nối nhau chỉ qua chat. Game mở bảng Chat bằng biểu tượng bong bóng ở sảnh
(chấm đỏ = có tin nhắn riêng / lời mời kết bạn chưa đọc). Chat chạy trên websocket của Nakama (đi qua cổng vào 7360 và
đường hầm trycloudflare, đã thử `wss`).

- **Phòng Thế giới** (một phòng chung, lưu lịch sử, game tải 50 tin gần nhất) và **nhắn riêng** giữa hai người. Game **không**
  tạo được phòng khác (máy chủ chặn). Người nhận nhắn riêng được báo bằng thông báo của Nakama (cả khi đang offline).
- **Bạn bè**: thêm theo mã người chơi 8 số hoặc bấm tên ở phòng Thế giới; mời / chấp nhận / từ chối / xóa. **Chặn**: người bị
  chặn không nhắn riêng được (máy chủ từ chối) và tin của họ ẩn khỏi phòng chung ở máy người chặn.
- **Chống lạm dụng** (ở máy chủ, `modules/index.js`): tối đa 200 ký tự, giãn cách 0,8 giây giữa hai tin, lọc từ cấm
  (che bằng `*`; danh sách `BAD_WORDS_ACCENT` / `BAD_WORDS_FOLDED` ở đầu mục Chat, sửa rồi khởi động lại Nakama), cấm chat theo thời gian.
- **Báo cáo**: người chơi bấm tên → Báo cáo → chọn lý do. QTV xem và xử lý:

```
powershell -ExecutionPolicy Bypass -File server\moderate.ps1 -Reports
powershell -ExecutionPolicy Bypass -File server\moderate.ps1 -Resolve <id báo cáo> -Operator ten_qtv
powershell -ExecutionPolicy Bypass -File server\moderate.ps1 -Mute <mã người chơi 8 số> -Minutes 60 -Reason "spam" -Operator ten_qtv
powershell -ExecutionPolicy Bypass -File server\moderate.ps1 -Mute <mã> -Minutes 0 -Operator ten_qtv     (gỡ cấm)
```

  Báo cáo ghi tên người báo cáo, người bị báo cáo, lý do và nội dung tin. Muốn biết mã người chơi của người bị báo cáo: trang quản
  trị Nakama (Accounts, tìm theo tên; mã nằm trong metadata `code`). Cấm vĩnh viễn tài khoản: dùng "Ban" trong trang quản trị.
- Thử máy chủ chat không cần mở game: `node server/tests/chat_smoke.mjs`. Thử cả game + máy chủ:
  `<godot> --headless --path . --script res://tools/chat_e2e.gd -- --server=<địa chỉ>`.

## Nạp tiền (M9-2): chuyển khoản QR thủ công, QTV phát gói

**Người chơi:** Hub → Tiếp tế → thẻ **Nạp** (cần đăng nhập). Màn hiện bảng giá (lấy từ máy chủ), gói nào còn thưởng nạp lần đầu, thẻ tháng,
và phần thanh toán: **mã QR VietQR** (game tự vẽ, không gọi dịch vụ ngoài) + ngân hàng / số tài khoản / số tiền / nội dung chuyển khoản
`ECL <mã người chơi>` (có nút Chép). Chuyển khoản xong, màn tự kiểm tra mỗi 20 giây; QTV phát xong là Ngọc tự vào kho và báo "Đã nhận".

**QTV:** xem sao kê (số tiền, mã giao dịch, nội dung có mã người chơi), rồi:

```
powershell -ExecutionPolicy Bypass -File server\grant.ps1 -List
powershell -ExecutionPolicy Bypass -File server\grant.ps1 -Code 32354120 -State
powershell -ExecutionPolicy Bypass -File server\grant.ps1 -Code 32354120 -Pack gems_660 -Paid 140000 -Ref FT26321ABC -Operator ten_qtv
```

- **Bảng giá** = `data/shop/topup_packs.json` (nguồn ảnh `docs/reference/topup_price_table.png`). Sửa file rồi chạy `grant.ps1` với `-Pack` là máy chủ
  có giá mới (script tự đẩy lên); game lấy bảng giá từ máy chủ nên **đổi giá không cần build lại**. `price: null` = chưa mở bán (thẻ tháng đang vậy).
- `-Paid` phải **đúng giá gói**, sai thì máy chủ từ chối (`-Force` khi đã thỏa thuận). Mỗi `-Ref` (mã giao dịch ngân hàng) chỉ dùng **một lần**.
- **Thưởng nạp lần đầu**: gói Ngọc nạp lần đầu (mỗi tài khoản, mỗi gói) được thêm đúng số Ngọc của gói (330 → 660). Máy chủ tự tính.
  Muốn mở lại cho mọi người (kỳ mới, không có lịch cố định): `grant.ps1 -ResetFirstBonus -Operator ten_qtv`.
  Gói Nhật Hoa (`corona_*`) chưa có thưởng lần đầu (`first_bonus: false` trong dữ liệu).
- **Thẻ tháng** (`-Pack card_30`, chưa có giá): mỗi thẻ +30 lượt nhận, mỗi ngày (giờ VN, 0h) nhận 1 lượt +30 Ngọc, cứ mỗi 15 lượt nhận thêm 500
  (một thẻ 30 lượt = 30×30 + 2×500 = 1900 Ngọc). Lượt không nhận không mất. Mua cộng dồn tối đa 180 lượt. Sửa khi có sự cố:
  `grant.ps1 -Code <mã> -CardLeft 20 -CardTotal 10 -CardDay 2026-11-15 -Operator ten_qtv`.
- **Ngọc**: ví máy chủ (`wallet.gems`) chỉ tăng khi nạp / nhận thẻ; game cộng phần chênh vào save (`online.applied.gems`) nên không cộng hai lần
  và an toàn khi tắt game giữa chừng. QTV thu hồi bằng số âm (`-Gems -100`), game trừ lại (không xuống dưới 0).
- **Nhật Hoa** (`corona`, tên hiển thị tạm, chỉ có qua nạp): nằm ở ví máy chủ, chưa có chỗ tiêu (vật phẩm độc quyền chưa thiết kế).
- Thông tin nhận tiền (`payment` trong bảng giá): ngân hàng, mã BIN (TPBank 970423), số tài khoản, tên chủ tài khoản, tiền tố nội dung. Đổi ở file dữ liệu.
- Mỗi lần phát lưu bản ghi (collection `admin_grant`: gói, số tiền, thưởng, QTV), nhật ký ví (ledger) và lịch sử nạp của người chơi (`grant.ps1 -State`).

**Chưa quét thử bằng app ngân hàng thật:** mã QR do game tự mã hóa; đã kiểm bằng bảng chuẩn + đọc ngược, nhưng chưa quét bằng điện thoại.
Trước khi mở nạp thật hãy quét thử một lần (`build/screenshots/topup_qr.png` sinh bởi `tools/screenshot_topup.gd`) và chuyển thử số nhỏ.

## Giới hạn giai đoạn 1

- Đường hầm trycloudflare: chỉ để thử, địa chỉ đổi mỗi lần, không cam kết ổn định.
- Máy chủ sống theo máy tính của owner: tắt máy / ngủ / Windows Update khởi động lại = người chơi mất kết nối.
- Chưa backup tự động. Sao lưu tay: `server\.runtime\pgsql\bin\pg_dump.exe -h 127.0.0.1 -p 5433 -U nakama nakama > backup.sql`.
- Chat: phòng Thế giới lưu lịch sử mãi (chưa tự xóa tin cũ); chưa có kênh nhóm / bang; tin nhắn riêng chưa có xác nhận "đã xem".
- Mã người chơi nằm trong metadata công khai của tài khoản Nakama (ai biết id người dùng đều đọc được qua API). Mã chỉ để nhận
  quà nạp / kết bạn nên chấp nhận được ở bản thử; trước khi phát hành nên chuyển sang storage riêng tư.
- Chưa có quên mật khẩu / xác minh email (cần dịch vụ gửi mail). QTV đặt lại mật khẩu trong trang quản trị nếu cần.
- Đừng chạy `start_local.ps1` qua ống `| ...` (PowerShell chờ Nakama tắt mới trả về).
