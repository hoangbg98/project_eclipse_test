# Frame Enkiba (char_fire_01) — làm từng animation, owner duyệt từng cái

> Sinh bởi `python -I tools/frames/gen_prompts.py char_fire_01`. Bảng trạng thái cập nhật khi chạy lại.

## Quy trình

Đọc trước: [`../PROMPT_GOC.md`](../PROMPT_GOC.md) (prompt gốc chuyển thể từ file của owner) và [`00_PHAN_TICH.md`](00_PHAN_TICH.md) (phân tích model).

1. Owner mở Codex trên PC tại `C:\Dev\PROJECT_ECLIPSE`, mở phiếu của animation kế tiếp (bảng dưới, theo thứ tự),
   kéo các ảnh tham chiếu ghi trong phiếu vào khung chat, dán khối **Prompt dán cho Codex**.
2. Codex tạo ảnh → `slice_strip.py` cắt về canvas chuẩn trong `art_review/` → `check_frames.py` kiểm và tạo
   `_preview/sheet.png`, `anim.gif`, `anim_flip.gif` → **dừng, gửi owner xem**. Chưa có gì vào game.
3. Owner xem: đạt thì trả lời `duyệt <animation>`; chưa đạt thì chỉ ra frame cần sửa (vd "frame 003 kiếm nhảy tay").
4. Sau khi duyệt, Codex (hoặc Claude) chạy `approve_frames.py`: chép vào `assets/characters/char_fire_01/frames/`,
   cập nhật `frames_manifest.json`, ghi `docs/ASSET_LICENSES.md` mục 2.1, chạy test, ghi nhật ký, commit.
5. Mở Godot (F5 → Màn thử nghiệm) xem trong game. Muốn thay bản đã duyệt: `approve_frames.py ... --replace`
   (bản cũ chuyển sang `art_review/char_fire_01/_replaced/`, không xóa).

`slice_strip.py --like idle` canh chiều cao theo idle trong assets (idle cũ vẫn đo được ~281 px; làm lại idle trước để có bản chuẩn kiếm cầm tay).
Hiệu ứng (lửa, vệt kiếm, phượng hoàng, cut-in) làm riêng ở `assets/vfx/`, không vẽ vào frame nhân vật.
Thư mục `art_review/` không vào git và không vào game (`.gdignore`).

## Danh sách animation

| # | Animation | Frame | fps | Frame trúng đòn | Trạng thái |
|---|---|---|---|---|---|
| 01 | [`idle`](01_idle.md) | 6 | 8 | — | Đã duyệt |
| 02 | [`run`](02_run.md) | 8 | 12 | — | Đã duyệt |
| 03 | [`attack_1`](03_attack_1.md) | 6 | 18 | 001, 002 | Đã duyệt |
| 04 | [`attack_2`](04_attack_2.md) | 6 | 18 | 001, 002 | Đã duyệt |
| 05 | [`attack_3`](05_attack_3.md) | 6 | 15 | 001, 002 | Đã duyệt |
| 06 | [`attack_4`](06_attack_4.md) | 7 | 12 | 001, 002, 003 | Đã duyệt |
| 07 | [`dodge`](07_dodge.md) | 5 | 15 | 000, 001, 002, 003, 004 | Đã duyệt |
| 08 | [`jump_up`](08_jump_up.md) | 3 | 12 | — | Đã duyệt |
| 09 | [`fall`](09_fall.md) | 3 | 12 | — | Đã duyệt |
| 10 | [`land`](10_land.md) | 3 | 12 | — | Đã duyệt |
| 11 | [`hurt`](11_hurt.md) | 4 | 12 | — | Đã duyệt |
| 12 | [`knockback`](12_knockback.md) | 3 | 12 | — | Đã duyệt |
| 13 | [`down`](13_down.md) | 6 | 12 | — | Đã duyệt |
| 14 | [`hold_charge`](14_hold_charge.md) | 4 | 12 | — | Đã duyệt |
| 15 | [`hold_release`](15_hold_release.md) | 9 | 12 | 001, 002, 003 | Đã duyệt |
| 16 | [`air_1`](16_air_1.md) | 5 | 18 | 001, 002 | Đã duyệt |
| 17 | [`air_2`](17_air_2.md) | 5 | 12 | 001, 002 | Đã duyệt |
| 18 | [`landing_attack`](18_landing_attack.md) | 6 | 15 | 000, 001 | Đã duyệt |
| 19 | [`skill_1`](19_skill_1.md) | 10 | 10 | 001, 002, 003, 004, 005, 006 | Đã duyệt |
| 20 | [`skill_2`](20_skill_2.md) | 13 | 18 | 002, 003, 004, 005, 006 | Đã duyệt |
| 21 | [`switch_in`](21_switch_in.md) | 7 | 12 | 002, 003, 004 | Đã duyệt |
| 22 | [`switch_out`](22_switch_out.md) | 3 | 12 | — | Đã duyệt |
| 23 | [`ultimate`](23_ultimate.md) | 22 | 8 | 007, 009, 011, 013, 015, 017, 018 | Đã duyệt |

Số frame / fps của đòn đánh tính từ thời gian kỹ năng (`data/skills/char_fire_01/`, hoặc `CHARACTER_SKILLS.md` khi chưa có) để hình khớp hitbox.
Walk, guard, victory, death chưa có trạng thái trong game nên chưa có phiếu.
Enkiba **luôn rút kiếm** (kiếm cầm tay ở mọi frame, owner 2026-11-13): xem `00_PHAN_TICH.md`.
