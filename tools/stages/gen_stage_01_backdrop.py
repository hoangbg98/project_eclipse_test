"""Ảnh nền 3 lớp cho ải 1-1 (stage_01, màn viết tay từ M6) — owner 2026-11-15 muốn đủ prompt ảnh cho cả Chương 1.

Chạy (thư mục gốc dự án):  python -X utf8 -I tools/stages/gen_stage_01_backdrop.py
Sinh / cập nhật: khóa "backdrop" trong data/stages/stage_01.json (giữ nguyên mọi khóa khác, đặt sau "legend"),
docs/prompts/stages/STAGE_01_BACKGROUND.md. Hàm chung: tools/stages/stage_gen.py.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))   # chạy với -I vẫn tìm thấy stage_gen
import stage_gen as sg  # noqa: E402

SPEC = {"id": "stage_01", "code": "1-1", "name_vi": "Thung Lũng Tro Tàn", "generator": "gen_stage_01_backdrop.py",
        "scrolls": (0.1, 0.3, 0.6)}
ART = {
    "far": ("Trời xám cam mù, Mặt Trời Khuyết, cuối thung lũng là vách đá có cửa Lò Mẹ khổng lồ tối om",
            "Hazy grey-orange afternoon sky, the Eclipsed Sun on the left third, ash falling perfectly straight down. "
            "Far away at the end of the valley on the right third, a towering cliff with a gigantic carved furnace "
            "gate, dark and cold (the Mother Hearth)."),
    "mid": ("Sườn thung lũng tro xám, đường đất dốc, cây chết, biển gỗ cháy xém",
            "Grey ash-covered valley slopes with a dirt road sloping down toward the far cliff, scattered dead trees, a "
            "half-burnt wooden signpost, a faint violet haze line crossing the ground (the edge of the Hollow Zone)."),
    "near": ("Đá, gốc cây cháy, cỏ khô phủ tro",
             "Dark foreground silhouettes: rocks, charred stumps and ash-covered dry grass along the bottom edge. "
             "Keep the middle readable."),
    "setting_en": "Setting: the Ashen Valley seen from inside, the road leading down toward the Mother Hearth, a giant "
                  "furnace carved into a cliff, which has gone cold; there is no wind and grey ash falls straight down.",
    "continuity": "cùng nơi với ô truyện `ch01_open_01` (cửa thung lũng) và `ch01_open_10` (cuối thung lũng có golem); "
                  "Lò Mẹ **lạnh**, **không gió**, tro rơi thẳng. Là nền chuẩn cho bảng màu cả Chương 1.",
    "refs": "ô truyện assets/story/ch01/ch01_open_01.png (nếu có) để khớp thung lũng, Mặt Trời Khuyết và cửa Lò Mẹ.",
}


def main():
    """Chèn đúng một khóa "backdrop" (một dòng) ngay trước "waves", không đổi định dạng phần còn lại của file viết tay."""
    p = os.path.join(sg.ROOT, "data/stages/stage_01.json")
    text = open(p, encoding="utf-8").read()
    if '"backdrop"' not in text:
        line = '\t"backdrop": %s,\n' % json.dumps(sg.backdrop("stage_01", SPEC["scrolls"]), ensure_ascii=False)
        at = text.index('\t"waves": [')
        text = text[:at] + line + text[at:]
        with open(p, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
    json.loads(text)                                                    # còn là JSON hợp lệ
    print(sg.write_backdrop_doc(SPEC, ART))


if __name__ == "__main__":
    main()
