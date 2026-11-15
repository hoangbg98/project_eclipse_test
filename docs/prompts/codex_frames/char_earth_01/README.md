# Frame Iwagane (char_earth_01) — làm từng animation, owner duyệt từng cái

> Sinh bởi `python -I tools/frames/gen_prompts.py char_earth_01`. Bảng trạng thái cập nhật khi chạy lại.

## Quy trình

Đọc trước: [`../PROMPT_GOC.md`](../PROMPT_GOC.md) (prompt gốc chuyển thể từ file của owner) và [`00_PHAN_TICH.md`](00_PHAN_TICH.md) (phân tích model).

1. Owner mở Codex trên PC tại `C:\Dev\PROJECT_ECLIPSE`, mở phiếu của animation kế tiếp (bảng dưới, theo thứ tự),
   kéo các ảnh tham chiếu ghi trong phiếu vào khung chat, dán khối **Prompt dán cho Codex**.
2. Codex tạo ảnh → `slice_strip.py` cắt về canvas chuẩn trong `art_review/` → `check_frames.py` kiểm và tạo
   `_preview/sheet.png`, `anim.gif`, `anim_flip.gif` → **dừng, gửi owner xem**. Chưa có gì vào game.
3. Owner xem: đạt thì trả lời `duyệt <animation>`; chưa đạt thì chỉ ra frame cần sửa (vd "frame 003 kiếm nhảy tay, bím tóc và sẹo luôn ở cùng một bên người").
4. Sau khi duyệt, Codex (hoặc Claude) chạy `approve_frames.py`: chép vào `assets/characters/char_earth_01/frames/`,
   cập nhật `frames_manifest.json`, ghi `docs/ASSET_LICENSES.md` mục 2.1, chạy test, ghi nhật ký, commit.
5. Mở Godot (F5 → Màn thử nghiệm) xem trong game. Muốn thay bản đã duyệt: `approve_frames.py ... --replace`
   (bản cũ chuyển sang `art_review/char_earth_01/_replaced/`, không xóa).

`slice_strip.py --like idle` canh chiều cao theo idle trong assets cho mọi animation sau: **làm `idle` trước**.
Hiệu ứng (sóng đá, gai đá, vết nứt đất, bụi đất, giáp đá, tảng đá rơi, sóng chấn, cut-in) làm riêng ở `assets/vfx/`, không vẽ vào frame nhân vật.
Thư mục `art_review/` không vào git và không vào game (`.gdignore`).

## Danh sách animation

| # | Animation | Frame | fps | Frame trúng đòn | Trạng thái |
|---|---|---|---|---|---|
| 01 | [`idle`](01_idle.md) | 6 | 8 | — | Chưa làm |
| 02 | [`run`](02_run.md) | 8 | 12 | — | Chưa làm |
| 03 | [`attack_1`](03_attack_1.md) | 6 | 12 | 002, 003 | Chưa làm |
| 04 | [`attack_2`](04_attack_2.md) | 6 | 12 | 002, 003 | Chưa làm |
| 05 | [`attack_3`](05_attack_3.md) | 8 | 10 | 002, 003 | Chưa làm |
| 06 | [`dodge`](06_dodge.md) | 5 | 10 | 000, 001, 002, 003 | Chưa làm |
| 07 | [`jump_up`](07_jump_up.md) | 3 | 12 | — | Chưa làm |
| 08 | [`fall`](08_fall.md) | 3 | 12 | — | Chưa làm |
| 09 | [`land`](09_land.md) | 3 | 12 | — | Chưa làm |
| 10 | [`hurt`](10_hurt.md) | 4 | 12 | — | Chưa làm |
| 11 | [`knockback`](11_knockback.md) | 3 | 12 | — | Chưa làm |
| 12 | [`down`](12_down.md) | 6 | 12 | — | Chưa làm |
| 13 | [`hold_charge`](13_hold_charge.md) | 4 | 12 | — | Chưa làm |
| 14 | [`hold_release`](14_hold_release.md) | 6 | 12 | 001, 002 | Chưa làm |
| 15 | [`air_1`](15_air_1.md) | 5 | 12 | 001, 002 | Chưa làm |
| 16 | [`landing_attack`](16_landing_attack.md) | 6 | 12 | 000, 001, 002, 003 | Chưa làm |
| 17 | [`skill_1`](17_skill_1.md) | 7 | 12 | 002, 003 | Chưa làm |
| 18 | [`skill_2`](18_skill_2.md) | 10 | 8 | 002, 003, 004, 005, 006 | Chưa làm |
| 19 | [`switch_in`](19_switch_in.md) | 8 | 10 | 002, 003, 004 | Chưa làm |
| 20 | [`switch_out`](20_switch_out.md) | 3 | 12 | — | Chưa làm |
| 21 | [`ultimate`](21_ultimate.md) | 19 | 8 | 005, 006 | Chưa làm |

Số frame / fps của đòn đánh tính từ thời gian kỹ năng (`data/skills/char_earth_01/`, hoặc `CHARACTER_SKILLS.md` khi chưa có) để hình khớp hitbox.
Walk, guard, victory, death chưa có trạng thái trong game nên chưa có phiếu.
Iwagane **luôn cầm đại kiếm** (tay gần, đòn nặng hai tay); `hold_charge` cắm kiếm xuống đất làm khiên. Kiếm rất to và nặng: động tác chậm, có đà, dồn trọng lượng. Xem `00_PHAN_TICH.md`.
`hold_charge` là vòng chắn lặp (game giữ tới 2,5 s); nhả nút thì chạy `hold_release` (xoay kiếm chém ngang). Sóng đá, gai đá, giáp đá, nứt đất là VFX của game.
Ảnh tham chiếu cắt từ tờ bộ phận theo tên owner đã điền ở trang "Bảng tên bộ phận Iwagane" (`rig_parts/source/refs/`, công cụ `tools/sprite_parts/cut_refs.py`).
