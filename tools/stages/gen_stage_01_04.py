"""Sinh màn 1-4 "Vách Lò Mẹ" (stage_01_04) — owner 2026-11-15 "làm tiếp màn 1-4".

Chạy (thư mục gốc dự án):  python -X utf8 -I tools/stages/gen_stage_01_04.py
Sinh / cập nhật: data/stages/stage_01_04.json, thoại ch01_4_* trong data/tutorial/battle_barks.json,
STAGE_01_04_* / BARK_CH01_4_* trong localization/vi.po, en.po. Hàm chung: tools/stages/stage_gen.py.

Truyện (owner 2026-11-15): mạch lửa ngầm đã thông (1-3) mà Lò Mẹ vẫn không cháy: ống thông khí trên vách bị kẻ đeo
mặt nạ lấp cố ý. Đội leo đường vách hẹp, dọn Cặn, thấy dấu chân mới của hắn chạy lên cao. Gió vẫn chưa về (gió chỉ
trở lại khi Lò Mẹ cháy, ở clip kết chương 1-10). Không mở bí mật mới. Màn ngoài trời, nhiều hố có platform bắc qua (rơi thì về điểm neo), không boss: hạ hết 3 đợt rồi
lên đỉnh vách (goal_col).
Số cân bằng là số Claude đặt (tự chủ chi tiết nhỏ), chỉnh ở đây rồi chạy lại.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))   # chạy với -I vẫn tìm thấy stage_gen
import stage_gen as sg  # noqa: E402

STAGE_ID = "stage_01_04"
W = 240
SPAWN = 3
CHECKPOINTS = [44, 140, 186]
GOAL_COL = 235
PITS = [(34, 37), (58, 63), (88, 92), (128, 133), (160, 163), (190, 193)]
BLOCKS = [(68, 70, 2), (148, 149, 1)]
PLATFORMS = [(11, 59, 62), (11, 89, 91), (11, 129, 132), (11, 191, 192),
             (9, 48, 52), (10, 74, 78), (9, 150, 154), (10, 170, 174)]

WAVES = [
    {"trigger_col": 18, "lock_cols": [12, 32], "enemies": [("enemy_slime_01", 20), ("enemy_slime_01", 24),
                                                           ("enemy_slime_01", 28)]},
    {"trigger_col": 102, "lock_cols": [96, 126], "enemies": [("enemy_slime_02", 106), ("enemy_slime_01", 112),
                                                             ("enemy_slime_02", 118), ("enemy_slime_01", 122)]},
    {"trigger_col": 208, "lock_cols": [204, 230], "enemies": [("enemy_slime_02", 210), ("enemy_slime_01", 214),
                                                              ("enemy_slime_02", 218), ("enemy_slime_01", 222),
                                                              ("enemy_slime_02", 226)]},
]

TEXT = {
    "STAGE_01_04_NAME": ("Vách Lò Mẹ", "Hearth Cliff"),
    "STAGE_01_04_DESC": ('Ống thông khí trên vách Lò Mẹ bị lấp cố ý nên lò không thở được. Leo đường vách hẹp, dọn đàn Cặn và lần theo kẻ đã lấp ống.',
                         "The vents on the Mother Hearth's cliff were deliberately blocked, so the Hearth can't breathe. Climb the narrow cliff path, clear the Dregs and follow whoever blocked them."),
    "BARK_CH01_4_START": ('Ống thông khí trên vách bị lấp. Lò không thở được thì không cháy nổi.',
                          "The cliff vents are blocked. If the Hearth can't breathe, it can't burn."),
    "BARK_CH01_4_WAVE1": ('Không có gió… mà ống lại bị lấp kín. Chuyện này không tự nhiên.',
                          "No wind… and the vents sealed shut. This isn't natural."),
    "BARK_CH01_4_WAVE1_NEO": ("Cặn tro bị hơi nóng của lò hút tới.", "The Hearth's heat is drawing the ash Dregs in."),
    "BARK_CH01_4_CP1": ("Cao thế này mà rơi thì… thôi, khỏi nghĩ.", "Falling from up here would be… nope, not thinking about it."),
    "BARK_CH01_4_CP1_NEO": ("Đường vách hẹp. Cẩn thận chỗ sụt.", "The cliff path is narrow. Watch the drops."),
    "BARK_CH01_4_WAVE2": ("Cặn lớn bám quanh miệng ống thông khí. Dọn sạch để lò thở.",
                          "Big Dregs are clinging to the vent mouth. Clear them so the Hearth can breathe."),
    "BARK_CH01_4_CP2": ('Dấu chân trên gờ đá, còn mới. Hắn vừa đi qua.',
                        'Footprints on the ledge, still fresh. He just came through.'),
    "BARK_CH01_4_CP2_NEO": ('Phát hiện dấu vết mới trên gờ đá.',
                            'Fresh traces detected on the ledge.'),
    "BARK_CH01_4_WAVE3": ("Đỉnh vách rồi! Dọn nốt đám này là xong!", "We're at the top! Clear this lot and we're done!"),
    "BARK_CH01_4_WAVE3_NEO": ("Ống thông khí cuối cùng. Dọn sạch đàn Cặn.", "Last vent. Clear out the Dregs."),
    "BARK_CH01_4_CLEAR": ('Ống thông rồi. Nhưng dấu chân hắn chạy lên cao hơn nữa.',
                          'The vents are clear. But his tracks lead even higher.'),
    "BARK_CH01_4_CLEAR_NEO": ("Mọi ống thông khí đã thông. Lên đỉnh vách để hoàn tất.",
                              "All vents are clear. Head to the clifftop to finish."),
}

BARKS = [
    {"id": "ch01_4_start", "on": "stage_start", "speaker": "neo", "text": "BARK_CH01_4_START"},
    {"id": "ch01_4_wave1", "on": "wave_started", "arg": 0, "speaker": "char_wind_01", "text": "BARK_CH01_4_WAVE1",
     "neo_text": "BARK_CH01_4_WAVE1_NEO"},
    {"id": "ch01_4_cp1", "on": "checkpoint", "arg": 1, "speaker": "char_lightning_01", "text": "BARK_CH01_4_CP1",
     "neo_text": "BARK_CH01_4_CP1_NEO"},
    {"id": "ch01_4_wave2", "on": "wave_started", "arg": 1, "speaker": "neo", "text": "BARK_CH01_4_WAVE2"},
    {"id": "ch01_4_cp2", "on": "checkpoint", "arg": 2, "speaker": "char_fire_01", "text": "BARK_CH01_4_CP2",
     "neo_text": "BARK_CH01_4_CP2_NEO"},
    {"id": "ch01_4_wave3", "on": "wave_started", "arg": 2, "speaker": "char_lightning_01", "text": "BARK_CH01_4_WAVE3",
     "neo_text": "BARK_CH01_4_WAVE3_NEO"},
    {"id": "ch01_4_clear", "on": "wave_cleared", "arg": 2, "speaker": "char_wind_01", "text": "BARK_CH01_4_CLEAR",
     "neo_text": "BARK_CH01_4_CLEAR_NEO"},
]


def stage():
    return {
        "id": STAGE_ID,
        "name": "Màn 1-4 — Vách Lò Mẹ",
        "name_key": "STAGE_01_04_NAME",
        "code": "1-4",
        "chapter": 1,
        "description": "Sinh bởi tools/stages/gen_stage_01_04.py. Đường vách ngoài trời, 6 hố (4 hố có platform bắc "
                       "qua), 3 đợt quái (đợt cuối 3 Slime tro lớn), 3 checkpoint, không boss: hạ hết đợt rồi lên đỉnh "
                       "vách (goal_col).",
        "desc_key": "STAGE_01_04_DESC",
        "recommended_level": 10,
        "objectives": [
            {"id": "time", "type": "time_max", "value": 300, "gold": 300},
            {"id": "hits", "type": "hits_taken_max", "value": 20, "gold": 300},
            {"id": "downs", "type": "downs_max", "value": 0, "gold": 400},
        ],
        "tile_size": 64,
        "legend": sg.LEGEND,
        "backdrop": sg.backdrop(STAGE_ID, (0.08, 0.3, 0.6)),
        "waves": sg.waves(WAVES),
        "goal_col": GOAL_COL,
        "rewards": {"gold": 1500, "captain_exp": 550, "exp": 750,
                    "materials": {"mat_exp_small": 5, "mat_enhance_ore": 4}},
        "first_clear_rewards": {"gems": 100, "materials": {"mat_exp_medium": 3, "mat_enhance_ore": 3}},
        "rows": sg.rows(W, PITS, BLOCKS, PLATFORMS, SPAWN, CHECKPOINTS),
    }


def main():
    sg.write_json("data/stages/%s.json" % STAGE_ID, stage())
    sg.merge_barks(STAGE_ID, BARKS)
    sg.write_text(TEXT)
    print("%s: %d hàng × %d cột, %d đợt, %d checkpoint" % (STAGE_ID, sg.H, W, len(WAVES), len(CHECKPOINTS)))


if __name__ == "__main__":
    main()
