# Frame Raikiba (char_lightning_01) — làm từng animation, owner duyệt từng cái

> Sinh bởi `python -I tools/frames/gen_prompts.py char_lightning_01`. Bảng trạng thái cập nhật khi chạy lại.

## Quy trình

Đọc trước: [`../PROMPT_GOC.md`](../PROMPT_GOC.md) (prompt gốc chuyển thể từ file của owner) và [`00_PHAN_TICH.md`](00_PHAN_TICH.md) (phân tích model).

1. Owner mở Codex trên PC tại `C:\Dev\PROJECT_ECLIPSE`, mở phiếu của animation kế tiếp (bảng dưới, theo thứ tự),
   kéo các ảnh tham chiếu ghi trong phiếu vào khung chat, dán khối **Prompt dán cho Codex**.
2. Codex tạo ảnh → `slice_strip.py` cắt về canvas chuẩn trong `art_review/` → `check_frames.py` kiểm và tạo
   `_preview/sheet.png`, `anim.gif`, `anim_flip.gif` → **dừng, gửi owner xem**. Chưa có gì vào game.
3. Owner xem: đạt thì trả lời `duyệt <animation>`; chưa đạt thì chỉ ra frame cần sửa (vd "frame 003 đao nhảy tay, mỗi tay luôn một đao").
4. Sau khi duyệt, Codex (hoặc Claude) chạy `approve_frames.py`: chép vào `assets/characters/char_lightning_01/frames/`,
   cập nhật `frames_manifest.json`, ghi `docs/ASSET_LICENSES.md` mục 2.1, chạy test, ghi nhật ký, commit.
5. Mở Godot (F5 → Màn thử nghiệm) xem trong game. Muốn thay bản đã duyệt: `approve_frames.py ... --replace`
   (bản cũ chuyển sang `art_review/char_lightning_01/_replaced/`, không xóa).

`slice_strip.py --like idle` canh chiều cao theo idle trong assets cho mọi animation sau: **làm `idle` trước**.
Hiệu ứng (tia sét, vệt chém vàng, dấu sét, vòng điện, cột sét, cut-in) làm riêng ở `assets/vfx/`, không vẽ vào frame nhân vật.
Thư mục `art_review/` không vào git và không vào game (`.gdignore`).

## Danh sách animation

| # | Animation | Frame | fps | Frame trúng đòn | Trạng thái |
|---|---|---|---|---|---|
| 01 | [`idle`](01_idle.md) | 6 | 8 | — | Chưa làm |
| 02 | [`run`](02_run.md) | 8 | 12 | — | Chưa làm |
| 03 | [`attack_1`](03_attack_1.md) | 4 | 18 | 001, 002 | Chưa làm |
| 04 | [`attack_2`](04_attack_2.md) | 4 | 18 | 001, 002 | Chưa làm |
| 05 | [`attack_3`](05_attack_3.md) | 4 | 18 | 001, 002 | Chưa làm |
| 06 | [`attack_4`](06_attack_4.md) | 4 | 18 | 001, 002 | Chưa làm |
| 07 | [`attack_5`](07_attack_5.md) | 6 | 12 | 001, 002 | Chưa làm |
| 08 | [`dodge`](08_dodge.md) | 4 | 12 | 000, 001 | Chưa làm |
| 09 | [`jump_up`](09_jump_up.md) | 3 | 12 | — | Chưa làm |
| 10 | [`fall`](10_fall.md) | 3 | 12 | — | Chưa làm |
| 11 | [`land`](11_land.md) | 3 | 12 | — | Chưa làm |
| 12 | [`hurt`](12_hurt.md) | 4 | 12 | — | Chưa làm |
| 13 | [`knockback`](13_knockback.md) | 3 | 12 | — | Chưa làm |
| 14 | [`down`](14_down.md) | 6 | 12 | — | Chưa làm |
| 15 | [`hold_charge`](15_hold_charge.md) | 4 | 12 | — | Chưa làm |
| 16 | [`hold_release`](16_hold_release.md) | 6 | 15 | — | Chưa làm |
| 17 | [`air_1`](17_air_1.md) | 4 | 20 | 001, 002 | Chưa làm |
| 18 | [`air_2`](18_air_2.md) | 4 | 20 | 001, 002 | Chưa làm |
| 19 | [`air_3`](19_air_3.md) | 5 | 18 | 001, 002 | Chưa làm |
| 20 | [`landing_attack`](20_landing_attack.md) | 5 | 15 | 000, 001 | Chưa làm |
| 21 | [`skill_1`](21_skill_1.md) | 8 | 12 | 001, 002, 003, 004, 005 | Chưa làm |
| 22 | [`skill_2`](22_skill_2.md) | 8 | 24 | 003, 004 | Chưa làm |
| 23 | [`switch_in`](23_switch_in.md) | 6 | 15 | 001, 002, 003 | Chưa làm |
| 24 | [`switch_out`](24_switch_out.md) | 3 | 12 | — | Chưa làm |
| 25 | [`ultimate`](25_ultimate.md) | 22 | 8 | 006, 007, 008, 009, 010, 011, 012, 013, 014, 015, 016 | Chưa làm |

Số frame / fps của đòn đánh tính từ thời gian kỹ năng (`data/skills/char_lightning_01/`, hoặc `CHARACTER_SKILLS.md` khi chưa có) để hình khớp hitbox.
Walk, guard, victory, death chưa có trạng thái trong game nên chưa có phiếu.
Raikiba **luôn cầm hai đao** (mỗi tay một), trừ lúc ném đao ở `skill_2`; ảnh tham chiếu có ánh sét: không vẽ ánh sét vào frame. Xem `00_PHAN_TICH.md`.
`hold_release` là vòng chém lặp (game giữ tới 1,2 s, thả nút thì dừng); `skill_2` chỉ là động tác ném, đao bay và quay về là vật thể của game.
Ảnh tham chiếu cắt từ tờ bộ phận theo tên owner đã điền ở trang "Bảng tên bộ phận Raikiba" (`rig_parts/source/refs/`).
