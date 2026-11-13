# Công cụ gửi quà thử nghiệm

Gửi thẳng ngọc, vàng, vật phẩm, trang bị, nhân vật, mảnh và cấp người chơi vào tài khoản để thử game (gacha, tăng cấp,
cường hóa, tiến cấp, kỹ năng...) mà không phải quay hay đi màn. **Chỉ để thử**: bảng trong game chỉ có ở bản debug.

Có hai cách dùng chung một lõi (`scripts/debug/debug_gift.gd`) và một file gói quà mẫu (`data/debug/gift_presets.json`).

## 1. Trong game (tức thì, không cần thoát game)

1. Chạy game bản debug (F5 trong Godot, hoặc bản build debug).
2. Hub → tab **Cài đặt** → nút **Quà thử nghiệm (debug)** ở bên phải.
3. Bấm một **gói quà mẫu**, hoặc gõ quà tùy chọn vào ô rồi bấm **Gửi** (hoặc Enter).
4. Khung dưới ghi quà đã gửi hoặc lỗi; dòng trạng thái trên cùng hiện ngọc, vàng, cấp, số nhân vật, số trang bị. Quà được
   lưu ngay vào save.

Bản Release không có nút này (và thư mục `data/debug/` bị loại khỏi export Release).

## 2. Dòng lệnh (khi game đã đóng)

```bash
powershell -ExecutionPolicy Bypass -File tools\give_gift.ps1 gems=5000 equip:all preset:level_up
powershell -ExecutionPolicy Bypass -File tools\give_gift.ps1 --list
powershell -ExecutionPolicy Bypass -File tools\give_gift.ps1 preset:everything --dry-run
```

- Ghi vào save thật (`user://saves`, cùng chỗ game đọc). **Đóng game trước**: game đang mở sẽ ghi đè khi thoát.
- `--list`: in gói quà mẫu và mọi ID (vật phẩm, trang bị, nhân vật).
- `--dry-run`: chạy thử, không ghi save. `--save-dir=<thư mục>`: ghi vào thư mục save khác.
- Mã thoát 0 = đã gửi, 1 = lỗi (không đổi gì), 2 = không tìm thấy Godot (truyền `-Godot <đường dẫn>`).

## Cú pháp quà

Các mục cách nhau bằng dấu cách hoặc dấu phẩy. Có lỗi cú pháp hoặc ID lạ thì **không áp gì cả** (không áp nửa chừng).

| Mục | Ý nghĩa |
|---|---|
| `gems=5000`, `gold=100000` | Ngọc, vàng |
| `item:mat_exp_small=5` | Vật phẩm / nguyên liệu (thiếu `=N` là 1); `item:all=10` cho mọi loại |
| `equip:eq_weapon_flame=2` | Trang bị, mỗi món một bản (`=N` cho N bản); `equip:all` cho mọi món |
| `char:char_earth_01` | Mở khóa nhân vật; `char:all` cho tất cả |
| `frag:char_fire_01=50` | Mảnh nhân vật (tự mở khóa nhân vật nếu chưa có); `frag:all=100` cho tất cả |
| `captain=50` | Nâng cấp người chơi lên **ít nhất** cấp này (không bao giờ hạ cấp); `captain_exp=300` cộng EXP |
| `preset:rich` | Gói quà mẫu trong file JSON; gói có thể gọi gói khác |

## Gói quà mẫu có sẵn

`rich` (50 000 ngọc + 500 000 vàng), `gacha_10x10` (25 200 ngọc), `level_up` (sách EXP + cấp người chơi 50),
`enhance` (nguyên liệu cường hóa), `gear` (mỗi trang bị một món), `all_characters`, `promotion` (100 mảnh mỗi nhân vật),
`everything` (tất cả các gói trên). Sửa hoặc thêm gói ở `data/debug/gift_presets.json` (mỗi gói: `title` và `gift` theo
cú pháp trên), không cần sửa code.

## Lưu ý

- Quà đi thẳng vào dữ liệu, bỏ qua mọi luật (kể cả giới hạn cấp nhân vật theo cấp người chơi khi mở khóa); dùng `captain=`
  để nâng cấp người chơi trước nếu muốn thử tăng cấp nhân vật.
- Lịch sử chiêu mộ, pity và các tiến độ khác không bị đổi.
- Muốn bắt đầu lại từ đầu: màn Title → Game mới.
