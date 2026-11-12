"""Thêm khóa dịch còn thiếu vào localization/vi.po và en.po (không sửa khóa đã có).
Dùng: sửa danh sách KEYS bên dưới rồi chạy  python -X utf8 tools/add_locale_keys.py
Mỗi mục: (khóa, tiếng Việt, tiếng Anh).
"""
import io
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEYS = [
    # M6 — màn chơi
    ("HUB_STAGE_01", "Màn 1", "Stage 1"),
    ("STAGE_01_NAME", "Thung lũng tro tàn", "Ashen Valley"),
    ("STAGE_OBJ_ADVANCE", "Tiến lên →", "Advance →"),
    ("STAGE_OBJ_WAVE", "Đợt %d/%d · còn %d kẻ địch", "Wave %d/%d · %d enemies left"),
    ("STAGE_OBJ_BOSS", "Hạ gục boss", "Defeat the boss"),
    ("STAGE_CHECKPOINT", "Điểm lưu", "Checkpoint"),
    ("STAGE_WAVE_CLEARED", "Đã dẹp xong", "Wave cleared"),
    ("STAGE_BOSS_PHASE", "Pha %d", "Phase %d"),
    # M6 — màn kết quả
    ("RESULT_VICTORY", "CHIẾN THẮNG", "VICTORY"),
    ("RESULT_DEFEAT", "THẤT BẠI", "DEFEAT"),
    ("RESULT_DEFEAT_HINT", "Cả đội đã gục. Thử lại nhé.", "The whole party is down. Try again."),
    ("RESULT_TIME", "Thời gian: %s", "Time: %s"),
    ("RESULT_BEST_TIME", "(kỷ lục mới)", "(new best)"),
    ("RESULT_REWARDS", "Phần thưởng", "Rewards"),
    ("RESULT_FIRST_CLEAR", "Thưởng qua màn lần đầu", "First clear bonus"),
    ("RESULT_EQUIPMENT", "Trang bị ×%d", "Equipment ×%d"),
    ("RESULT_LEVEL_UP", "%s lên %d cấp", "%s gained %d level(s)"),
    ("RESULT_RETRY", "Chơi lại", "Retry"),
    ("RESULT_TO_HUB", "Về Hub", "Back to Hub"),
]

for po, idx in (("vi.po", 1), ("en.po", 2)):
    p = os.path.join(ROOT, "localization", po)
    s = io.open(p, encoding="utf-8").read()
    add = ""
    for row in KEYS:
        if 'msgid "%s"' % row[0] not in s:
            add += '\nmsgid "%s"\nmsgstr "%s"\n' % (row[0], row[idx])
    if add:
        io.open(p, "w", encoding="utf-8", newline="\n").write(s.rstrip("\n") + "\n" + add)
    print(po, add.count("msgid"), "khóa mới")
