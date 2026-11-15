"""Sinh màn 1-3 "Hầm Than Ngầm" (stage_01_03) — owner 2026-11-15 "làm tiếp màn 1-3".

Chạy (thư mục gốc dự án):  python -X utf8 -I tools/stages/gen_stage_01_03.py
Sinh / cập nhật: data/stages/stage_01_03.json, thoại ch01_3_* trong data/tutorial/battle_barks.json,
STAGE_01_03_* / BARK_CH01_3_* trong localization/vi.po, en.po. Hàm chung: tools/stages/stage_gen.py.

Truyện: giữ được cổng làng (1-2), nhưng tro vẫn rỉ lên từ hầm than cũ dưới làng, nơi mạch lửa ngầm chạy qua
("Lửa ngầm tắt thì đá cũng nứt", 1-1). Trong hầm có dấu ba vòng đá giống trên lưng golem: thủ vệ đã đào hầm này
(nhắc lại manh mối Chương 1, không mở bí mật mới), dẫn sang Cao Nguyên Thủ Vệ ở Chương 2.
Màn không boss: hạ hết 3 đợt (đợt cuối là ổ Cặn, 3 Slime tro lớn) rồi ra cửa hầm (goal_col).
Số cân bằng là số Claude đặt (tự chủ chi tiết nhỏ), chỉnh ở đây rồi chạy lại.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))   # chạy với -I vẫn tìm thấy stage_gen
import stage_gen as sg  # noqa: E402

STAGE_ID = "stage_01_03"
W = 220
SPAWN = 3
CHECKPOINTS = [62, 120, 160]
GOAL_COL = 214
PITS = [(38, 41), (70, 75), (126, 128), (134, 136)]
BLOCKS = [(56, 58, 2), (142, 143, 1)]
PLATFORMS = [(11, 44, 47), (9, 50, 54), (11, 71, 74), (10, 92, 96), (11, 130, 132), (9, 150, 154), (10, 184, 188)]
CEILING = [(1, 30, 3), (31, 68, 2), (69, 118, 3), (119, 165, 2), (166, 218, 3)]   # trần hầm (cột, sâu)

WAVES = [
    {"trigger_col": 16, "lock_cols": [10, 36], "enemies": [("enemy_slime_01", 22), ("enemy_slime_01", 27),
                                                           ("enemy_slime_02", 32)]},
    {"trigger_col": 86, "lock_cols": [80, 114], "enemies": [("enemy_slime_01", 90), ("enemy_slime_02", 96),
                                                            ("enemy_slime_01", 102), ("enemy_slime_02", 108)]},
    {"trigger_col": 172, "lock_cols": [166, 206], "enemies": [("enemy_slime_02", 176), ("enemy_slime_01", 182),
                                                              ("enemy_slime_02", 190), ("enemy_slime_01", 196),
                                                              ("enemy_slime_02", 202)]},
]

TEXT = {
    "STAGE_01_03_NAME": ("Hầm Than Ngầm", "Coal Tunnels"),
    "STAGE_01_03_DESC": ("Tro vẫn rỉ lên từ hầm than cũ dưới làng, nơi mạch lửa ngầm chảy qua. Xuống hầm, phá ổ Cặn "
                         "tro trước khi mạch lửa nguội hẳn.",
                         "Ash still seeps up from the old coal tunnels under the village, where the buried fire vein "
                         "runs. Go down and break the Dreg nest before the vein goes cold."),
    "BARK_CH01_3_START": ("Nhiệt dưới lòng đất đang tụt. Cặn tro trôi lên từ chính hầm này.",
                          "The heat underground is dropping. The ash Dregs are coming up from these tunnels."),
    "BARK_CH01_3_WAVE1": ("Tối om thế này mà chúng vẫn tìm ra tụi mình à?!", "It's pitch dark and they still found us?!"),
    "BARK_CH01_3_WAVE1_NEO": ("Cặn tro phía trước. Chúng bám theo hơi ấm.", "Ash Dregs ahead. They follow warmth."),
    "BARK_CH01_3_CP1": ("Mạch lửa ngầm chạy qua đây. Nó nguội gần hết rồi.",
                        "The fire vein runs through here. It's almost cold."),
    "BARK_CH01_3_CP1_NEO": ("Mạch lửa ngầm gần như đã nguội.", "The buried fire vein has nearly gone cold."),
    "BARK_CH01_3_WAVE2": ("Có gió lùa từ sâu bên trong. Cặn đang kéo theo nó.",
                          "There's a draft from deep inside. The Dregs are riding it."),
    "BARK_CH01_3_WAVE2_NEO": ("Hai khối Cặn lớn. Né đòn cắn rồi phản công.", "Two big Dregs. Dodge the bite, then counter."),
    "BARK_CH01_3_CP2": ("Dấu ba vòng đá… giống hệt trên lưng golem. Thủ vệ đã đào hầm này.",
                        "Three stone rings… same as the golem's back. The guardians dug these tunnels."),
    "BARK_CH01_3_CP2_NEO": ("Dấu khắc ba vòng đá, trùng với dấu trên lưng golem.",
                            "A three-ring stone carving, matching the mark on the golem's back."),
    "BARK_CH01_3_WAVE3": ("Ổ Cặn ở cuối hầm. Phá nó thì tro thôi trôi lên làng.",
                          "The Dreg nest is at the end of the tunnel. Break it and the ash stops reaching the village."),
    "BARK_CH01_3_CLEAR": ("Mạch lửa ấm lại rồi. Làng sẽ ổn thôi.", "The vein is warming up. The village will be fine."),
    "BARK_CH01_3_CLEAR_NEO": ("Ổ Cặn đã tan. Ra cửa hầm để hoàn tất.", "The nest is gone. Head for the tunnel exit to finish."),
}

BARKS = [
    {"id": "ch01_3_start", "on": "stage_start", "speaker": "neo", "text": "BARK_CH01_3_START"},
    {"id": "ch01_3_wave1", "on": "wave_started", "arg": 0, "speaker": "char_lightning_01", "text": "BARK_CH01_3_WAVE1",
     "neo_text": "BARK_CH01_3_WAVE1_NEO"},
    {"id": "ch01_3_cp1", "on": "checkpoint", "arg": 1, "speaker": "char_fire_01", "text": "BARK_CH01_3_CP1",
     "neo_text": "BARK_CH01_3_CP1_NEO"},
    {"id": "ch01_3_wave2", "on": "wave_started", "arg": 1, "speaker": "char_wind_01", "text": "BARK_CH01_3_WAVE2",
     "neo_text": "BARK_CH01_3_WAVE2_NEO"},
    {"id": "ch01_3_cp2", "on": "checkpoint", "arg": 2, "speaker": "char_wind_01", "text": "BARK_CH01_3_CP2",
     "neo_text": "BARK_CH01_3_CP2_NEO"},
    {"id": "ch01_3_wave3", "on": "wave_started", "arg": 2, "speaker": "neo", "text": "BARK_CH01_3_WAVE3"},
    {"id": "ch01_3_clear", "on": "wave_cleared", "arg": 2, "speaker": "char_fire_01", "text": "BARK_CH01_3_CLEAR",
     "neo_text": "BARK_CH01_3_CLEAR_NEO"},
]


def stage():
    return {
        "id": STAGE_ID,
        "name": "Màn 1-3 — Hầm Than Ngầm",
        "name_key": "STAGE_01_03_NAME",
        "code": "1-3",
        "chapter": 1,
        "description": "Sinh bởi tools/stages/gen_stage_01_03.py. Hầm có trần, 4 hố, 3 đợt quái (đợt cuối 3 Slime tro "
                       "lớn), 3 checkpoint, không boss: hạ hết đợt rồi ra cửa hầm (goal_col).",
        "desc_key": "STAGE_01_03_DESC",
        "recommended_level": 8,
        "objectives": [
            {"id": "time", "type": "time_max", "value": 270, "gold": 300},
            {"id": "hits", "type": "hits_taken_max", "value": 20, "gold": 300},
            {"id": "downs", "type": "downs_max", "value": 0, "gold": 400},
        ],
        "tile_size": 64,
        "legend": sg.LEGEND,
        "backdrop": sg.backdrop(STAGE_ID, (0.1, 0.25, 0.55)),
        "waves": sg.waves(WAVES),
        "goal_col": GOAL_COL,
        "rewards": {"gold": 1400, "captain_exp": 500, "exp": 700,
                    "materials": {"mat_exp_small": 5, "mat_enhance_ore": 3}},
        "first_clear_rewards": {"gems": 100, "materials": {"mat_exp_medium": 2, "mat_enhance_ore": 3}},
        "rows": sg.rows(W, PITS, BLOCKS, PLATFORMS, SPAWN, CHECKPOINTS, CEILING),
    }


def main():
    sg.write_json("data/stages/%s.json" % STAGE_ID, stage())
    sg.merge_barks(STAGE_ID, BARKS)
    sg.write_text(TEXT)
    print("%s: %d hàng × %d cột, %d đợt, %d checkpoint" % (STAGE_ID, sg.H, W, len(WAVES), len(CHECKPOINTS)))


if __name__ == "__main__":
    main()
