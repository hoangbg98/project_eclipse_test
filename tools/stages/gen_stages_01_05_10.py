"""Sinh màn 1-5 → 1-10 của Chương 1 (owner 2026-11-15 "viết tiếp từ ải 1-5 đến ải 1-10 kèm cốt truyện, prompt ảnh").

Chạy (thư mục gốc dự án):  python -X utf8 -I tools/stages/gen_stages_01_05_10.py

Sinh / cập nhật:
  data/stages/stage_01_05.json … stage_01_10.json
  data/enemies/boss_henchman_01.tres     — boss 1-10: kẻ đeo mặt nạ trong bộ giáp (2 pha)
  data/tutorial/battle_barks.json        — thoại ch01_5_* … ch01_10_* (thêm / ghi đè theo id)
  localization/vi.po, en.po              — STAGE_01_0X_*, BOSS_HENCHMAN_01, BARK_CH01_X_*
  docs/prompts/stages/STAGE_01_0X_BACKGROUND.md (1-5 → 1-10) — prompt ảnh nền 3 lớp
Hàm chung: tools/stages/stage_gen.py (check_layout tự kiểm tra hố / sân khóa / quái / đích).

Cốt truyện (owner 2026-11-15): golem ở 1-1 chỉ chặn đường; kẻ chủ mưu Chương 1 là tay sai đeo mặt nạ (người mặc giáp
của một Quản lý dưới trướng thủ lĩnh mã 00); Lò Mẹ vẫn lạnh tới khi hạ hắn ở 1-10 (clip kết chương ch01_end).
  1-5 Rừng Cây Chết      — hắn cắm cọc ấn tín hiệu 00 khắp rừng để gọi Cặn chặn đường.
  1-6 Cầu Đá Treo        — hắn phá cầu đá cổ của thủ vệ sau lưng; nhảy qua các nhịp gãy.
  1-7 Trạm Thủ Vệ Bỏ Hoang — dấu ba vòng đá; hốc lõi thủ vệ bị tháo: lõi golem lấy từ đây.
  1-8 Trại Mặt Nạ        — trại của hắn, cột kênh trắng đen hút nhiệt Lò Mẹ; bản ghi: tắt lò đêm nhật thực, là đêm nay.
  1-9 Đường Về Cửa Lò    — đêm xuống, nhật thực đầy dần, Cặn dày đặc; thấy bóng người ở cửa lò.
  1-10 Cửa Lò Mẹ         — boss: kẻ đeo mặt nạ (2 pha), sau đó clip kết chương.
Không mở bí mật mới ngoài chương (B6): chỉ "có một mạng kênh 00 và người của nó cố ý dập lửa".
Số cân bằng là số Claude đặt (tự chủ chi tiết nhỏ), chỉnh ở đây rồi chạy lại.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))   # chạy với -I vẫn tìm thấy stage_gen
import stage_gen as sg  # noqa: E402

GEN = "gen_stages_01_05_10.py"
S1, S2, BOSS = "enemy_slime_01", "enemy_slime_02", "boss_henchman_01"
E, K, R = "char_fire_01", "char_wind_01", "char_lightning_01"


def wave(t, lock, *enemies):
    return {"trigger_col": t, "lock_cols": list(lock), "enemies": list(enemies)}


# asc: Tinh thể nâng bậc vũ khí (owner 2026-11-15: rơi từ ải; số do Claude đặt). 5★ cần 2 + 4 + 6 = 12 để đủ 3 bậc.
def rew(gold, cexp, exp, small, ore, asc=1):
    return {"gold": gold, "captain_exp": cexp, "exp": exp,
            "materials": {"mat_exp_small": small, "mat_enhance_ore": ore, "mat_weapon_ascend": asc}}


def first(gems, medium, ore, asc=1):
    return {"gems": gems, "materials": {"mat_exp_medium": medium, "mat_enhance_ore": ore, "mat_weapon_ascend": asc}}


def barks(n, lines):
    """lines: (sự kiện, arg, người nói, khóa đuôi, vi, en, neo_vi, neo_en, delay)."""
    out, text = [], {}
    for on, arg, spk, tail, vi, en, nvi, nen, delay in lines:
        key = "BARK_CH01_%d_%s" % (n, tail)
        b = {"id": "ch01_%d_%s" % (n, tail.lower()), "on": on}
        if arg is not None:
            b["arg"] = arg
        if delay:
            b["delay"] = delay
        b["speaker"], b["text"] = spk, key
        text[key] = (vi, en)
        if spk != "neo":
            b["neo_text"] = key + "_NEO"
            text[key + "_NEO"] = (nvi, nen)
        out.append(b)
    return out, text


STAGES = [
    # ---------------------------------------------------------------- 1-5
    {"id": "stage_01_05", "code": "1-5", "name_vi": "Rừng Cây Chết", "name_en": "Dead Grove",
     "desc": ("Dấu chân tay sai dẫn lên rừng cây chết trên sườn vách. Hắn cắm cọc ấn khắp rừng để gọi Cặn chặn đường. "
              "Dọn đàn Cặn và lần tiếp dấu hắn.",
              "The henchman's tracks lead up into a dead grove on the cliff slope. He has planted seal stakes all over "
              "it to call Dregs onto the path. Clear them and keep following his trail."),
     "design": "Rừng ngoài trời, 4 hố (2 có platform), 3 đợt (3 / 4 / 5 quái), không boss: tới bìa rừng (goal_col).",
     "w": 240, "level": 12, "objectives": (300, 20),
     "pits": [(36, 39), (70, 74), (118, 121), (168, 172)],
     "blocks": [(56, 57, 2), (150, 152, 1)],
     "platforms": [(11, 71, 73), (11, 169, 171), (9, 46, 50), (10, 90, 94), (9, 140, 144), (10, 196, 200)],
     "checkpoints": [52, 130, 180],
     "waves": [wave(18, (12, 32), (S1, 20), (S1, 24), (S1, 28)),
               wave(96, (88, 114), (S1, 92), (S2, 98), (S1, 104), (S2, 110)),
               wave(200, (192, 226), (S2, 196), (S1, 202), (S2, 208), (S1, 214), (S2, 220))],
     "goal_col": 232, "rewards": rew(1600, 600, 800, 5, 4), "first_clear": first(100, 3, 3),
     "barks": [
         ("stage_start", None, "neo", "START", "Tín hiệu 00 yếu, lặp lại đều. Như có thứ gì cắm khắp khu rừng.",
          "A weak 00 signal, repeating steadily. Like something's planted all over this grove.", "", "", 0),
         ("wave_started", 0, K, "WAVE1", "Cây chết hết rồi, đến lá khô cũng không xào xạc.",
          "Every tree is dead. Not even the dry leaves rustle.", "Cặn tro bị tín hiệu lạ kéo tới.",
          "The strange signal is pulling the ash Dregs in.", 0),
         ("checkpoint", 1, R, "CP1", "Cọc đá này có vòng trắng đen! Hắn cắm cái này để gọi Cặn à?",
          "This stone stake has a black-and-white ring! He planted these to call the Dregs?",
          "Cọc ấn mang tín hiệu 00. Nó đang gọi Cặn tới.", "A seal stake carrying the 00 signal. It's calling Dregs.", 0),
         ("wave_started", 1, "neo", "WAVE2", "Thêm một bầy, có cả Cặn lớn.", "Another pack, big Dregs included.", "", "", 0),
         ("checkpoint", 2, E, "CP2", "Nhổ hết đống cọc này. Không để hắn dùng rừng làm hàng rào.",
          "Pull up every one of these stakes. He doesn't get to use the grove as a fence.",
          "Đã ghi vị trí các cọc ấn.", "Seal stake positions logged.", 0),
         ("wave_started", 2, R, "WAVE3", "Bầy cuối rồi! Dọn xong là thấy đường!", "Last pack! Clear it and the path opens!",
          "Bầy Cặn cuối cùng quanh cọc ấn lớn.", "The last pack is around the big seal stake.", 0),
         ("wave_cleared", 2, K, "CLEAR", "Tín hiệu tắt rồi. Đi tiếp thôi, hắn chưa xa đâu.",
          "The signal's gone. Let's move, he can't be far.", "Các cọc ấn đã tắt. Ra bìa rừng để hoàn tất.",
          "The seal stakes are dead. Head to the edge of the grove to finish.", 0),
     ],
     "art": {
         "far": ("Trời xám cam, Mặt Trời Khuyết, vách Lò Mẹ lạnh tối ở xa, sườn núi tro",
                 "Hazy grey-orange sky, the Eclipsed Sun on the left third, ash falling straight down in still air. Far "
                 "away on the right, the dark, cold cliff of the Mother Hearth; grey mountain slopes below."),
         "mid": ("Rừng cây chết thân bạc, cọc đá khắc vòng trắng đen phát sáng yếu",
                 "A grove of dead silver-grey trees with bare twisted branches, ash on every bough; here and there a "
                 "carved stone stake with a faintly glowing half-white, half-black ring sigil, pulsing softly."),
         "near": ("Thân cây gãy, rễ khô, gốc cây cháy đen",
                  "Dark foreground silhouettes: broken trunks, dry roots and charred stumps along the bottom edge, a "
                  "few hanging dead branches from the top corners. Keep the middle readable."),
         "setting_en": "Setting: a dead grove on the slope above the Ashen Valley; the Mother Hearth is cold, there is "
                       "no wind, and grey ash falls straight down.",
         "continuity": "nối tiếp 1-4 (vách Lò Mẹ): lên cao hơn, vẫn **chưa có gió**, Lò Mẹ **lạnh**. Cọc ấn trắng-đen "
                       "cùng kiểu vòng với mảnh ấn trong golem (ô truyện `ch01_golem_05/06`).",
         "refs": "nền 1-4 đã duyệt trong assets/backgrounds/stages/stage_01_04/ (nếu có) để giữ nét, bảng màu, Mặt "
                 "Trời Khuyết; ô truyện assets/story/ch01/ch01_golem_06.png (nếu có) cho kiểu vòng trắng-đen.",
     }},
    # ---------------------------------------------------------------- 1-6
    {"id": "stage_01_06", "code": "1-6", "name_vi": "Cầu Đá Treo", "name_en": "Hanging Stone Bridge",
     "desc": ("Đường duy nhất qua vực là cây cầu đá cổ của thủ vệ, nay sụt nhiều nhịp: tay sai đã phá cầu sau lưng hắn. "
              "Nhảy qua các nhịp gãy và dọn đàn Cặn.",
              "The only way across the chasm is the guardians' ancient stone bridge, now missing many spans: the "
              "henchman wrecked it behind him. Leap the broken spans and clear the Dregs."),
     "design": "Cầu qua vực, 7 hố có platform (rơi thì về điểm neo), 3 đợt (3 / 5 / 6 quái), không boss: tới đầu cầu.",
     "w": 260, "level": 14, "objectives": (320, 22),
     "pits": [(30, 33), (48, 53), (66, 71), (100, 104), (140, 145), (160, 165), (186, 190)],
     "blocks": [(84, 85, 1)],
     "platforms": [(11, 49, 52), (11, 67, 70), (11, 101, 103), (11, 141, 144), (11, 161, 164), (11, 187, 189),
                   (9, 56, 60), (9, 150, 154)],
     "checkpoints": [42, 124, 176],
     "waves": [wave(14, (8, 28), (S1, 18), (S1, 22), (S1, 26)),
               wave(112, (106, 138), (S1, 110), (S2, 116), (S1, 122), (S2, 128), (S1, 134)),
               wave(204, (196, 250), (S2, 202), (S1, 208), (S2, 216), (S1, 224), (S2, 232), (S1, 240))],
     "goal_col": 254, "rewards": rew(1700, 650, 850, 6, 4), "first_clear": first(100, 3, 4),
     "barks": [
         ("stage_start", None, "neo", "START", "Cầu đá của thủ vệ, nhiều nhịp đã sụt. Rơi xuống thì tôi kéo về điểm neo.",
          "The guardians' stone bridge, many spans collapsed. If you fall, I'll pull you back to the anchor.", "", "", 0),
         ("wave_started", 0, R, "WAVE1", "Cầu gãy thế này thì để tớ! Nhảy là nghề của tớ.",
          "Broken bridge? Leave it to me! Jumping's my specialty.", "Cặn tro chặn đầu cầu.",
          "Ash Dregs are blocking the bridgehead.", 0),
         ("checkpoint", 1, E, "CP1", "Vết chém mới trên trụ cầu. Hắn cố ý phá cho sập.",
          "Fresh cuts on the pillar. He broke it down on purpose.", "Trụ cầu có vết phá còn mới.",
          "The pillar shows fresh damage.", 0),
         ("wave_started", 1, K, "WAVE2", "Giữa cầu không có chỗ lùi. Đánh gọn, đừng để bị đẩy xuống.",
          "No room to back off mid-bridge. Fight clean, don't get knocked off.",
          "Giữ thăng bằng. Cặn lớn đẩy lùi rất mạnh.", "Keep your footing. Big Dregs knock you back hard.", 0),
         ("checkpoint", 2, R, "CP2", "Thấy đầu cầu bên kia rồi!", "I can see the far end of the bridge!",
          "Còn một đoạn cầu nữa.", "One more stretch of bridge.", 0),
         ("wave_started", 2, "neo", "WAVE3", "Bầy Cặn lớn chặn đầu cầu bên kia.",
          "A pack of big Dregs is blocking the far bridgehead.", "", "", 0),
         ("wave_cleared", 2, E, "CLEAR", "Qua được rồi. Hắn tưởng phá cầu là cắt đuôi được bọn mình à.",
          "We made it. He thought wrecking a bridge would shake us off?",
          "Đã qua vực. Tiến tới đầu cầu để hoàn tất.", "Chasm crossed. Head to the bridgehead to finish.", 0),
     ],
     "art": {
         "far": ("Vực sâu mù sương, vách đá đối diện, Mặt Trời Khuyết, thung lũng tro rất xa phía dưới",
                 "A deep misty chasm between two grey cliffs, the Eclipsed Sun on the left third in a hazy grey-orange "
                 "sky, the ash valley far, far below, ash hanging in still air."),
         "mid": ("Trụ cầu đá cổ khắc dấu ba vòng đá, xích sắt đứt, nhịp cầu gãy treo lơ lửng",
                 "Massive ancient stone bridge pillars carved with a three-stacked-stone-ring emblem, broken bridge "
                 "spans hanging at angles, snapped iron chains dangling, fresh pale cut marks on one pillar."),
         "near": ("Dây xích, mảnh đá vỡ, lan can cầu gãy",
                  "Dark foreground silhouettes: chain links and broken stone railing pieces along the bottom edge, a "
                  "snapped chain hanging from the top corner. Keep the middle readable."),
         "setting_en": "Setting: an ancient stone bridge built by the stone guardians across a deep chasm high above "
                       "the Ashen Valley; the bridge has been deliberately broken in places; no wind, ash falls "
                       "straight down.",
         "continuity": "nối tiếp 1-5: cùng độ cao, cùng trời xám cam, **chưa có gió**. Dấu ba vòng đá giống lưng golem "
                       "và hầm 1-3 (thủ vệ xây cầu).",
         "refs": "nền 1-5 đã duyệt trong assets/backgrounds/stages/stage_01_05/ (nếu có); dấu ba vòng đá theo nền "
                 "1-3 (assets/backgrounds/stages/stage_01_03/) hoặc ô truyện ch01_end_11 (nếu có).",
     }},
    # ---------------------------------------------------------------- 1-7
    {"id": "stage_01_07", "code": "1-7", "name_vi": "Trạm Thủ Vệ Bỏ Hoang", "name_en": "Abandoned Guardian Post",
     "desc": ("Bên kia vực là trạm canh cổ của thủ vệ, khắc dấu ba vòng đá. Tay sai đã ghé đây trước. Vào trong, tìm "
              "xem hắn lấy đi thứ gì.",
              "Across the chasm stands an ancient guardian outpost carved with the three-ring mark. The henchman got "
              "here first. Go inside and find out what he took."),
     "design": "Trong trạm có trần đá, 3 hố, 3 đợt (3 / 3 / 5 quái, nhiều Slime tro lớn), không boss: ra lối sau.",
     "w": 240, "level": 16, "objectives": (300, 20),
     "ceiling": [(1, 60, 3), (61, 130, 2), (131, 238, 3)],
     "pits": [(40, 43), (92, 95), (150, 154)],
     "blocks": [(60, 62, 2), (120, 121, 1), (186, 187, 1)],
     "platforms": [(11, 151, 153), (10, 50, 54), (9, 104, 108), (10, 170, 174)],
     "checkpoints": [48, 100, 160],
     "waves": [wave(18, (12, 36), (S1, 20), (S2, 26), (S1, 32)),
               wave(68, (64, 90), (S2, 72), (S1, 78), (S2, 84)),
               wave(194, (190, 228), (S2, 196), (S1, 202), (S2, 208), (S1, 214), (S2, 220))],
     "goal_col": 232, "rewards": rew(1800, 700, 900, 6, 5), "first_clear": first(100, 3, 4),
     "barks": [
         ("stage_start", None, "neo", "START", "Trạm canh của thủ vệ. Dấu ba vòng đá, giống trên lưng golem.",
          "A guardian outpost. Three stone rings, same as on the golem's back.", "", "", 0),
         ("wave_started", 0, K, "WAVE1", "Chỗ này từng có nhiều thủ vệ đứng canh. Giờ trống trơn.",
          "Many guardians used to stand watch here. Now it's empty.", "Cặn tro làm tổ trong trạm.",
          "Ash Dregs are nesting in the outpost.", 0),
         ("checkpoint", 1, E, "CP1", "Hốc tường này trống. Lõi của thủ vệ bị tháo đi rồi.",
          "This wall niche is empty. The guardian's core was pulled out.", "Các hốc chứa lõi thủ vệ đều trống.",
          "Every guardian core niche is empty.", 0),
         ("wave_started", 1, R, "WAVE2", "Hắn lấy lõi thủ vệ để làm gì chứ?!", "What does he want with guardian cores?!",
          "Cặn lớn bám quanh hốc lõi.", "Big Dregs are clinging around the core niches.", 0),
         ("checkpoint", 2, K, "CP2", "Golem ở cửa lò… chắc cũng bị gắn lõi từ đây rồi sai đi.",
          "The golem at the Hearth… its core probably came from here, then it was sent off.",
          "Lõi golem ở cửa lò có thể đến từ trạm này.", "The golem's core may have come from this outpost.", 0),
         ("wave_started", 2, "neo", "WAVE3", "Bầy cuối ở lối ra phía sau trạm.",
          "The last pack is at the outpost's back exit.", "", "", 0),
         ("wave_cleared", 2, E, "CLEAR", "Lấy lõi, sai thủ vệ, dập lửa. Hắn tính hết từ trước.",
          "Take a core, send a guardian, kill the fire. He planned all of it.",
          "Trạm đã sạch. Ra lối sau để hoàn tất.", "The outpost is clear. Take the back exit to finish.", 0),
     ],
     "art": {
         "far": ("Tường đá trong trạm, hốc tường lớn trống rỗng, ánh sáng lọt qua khe trần",
                 "The deep interior wall of an ancient guardian outpost carved from grey stone: rows of large empty "
                 "niches where stone guardian cores once sat, thin shafts of hazy orange light from cracks above."),
         "mid": ("Cột đá khắc dấu ba vòng đá, giá đỡ lõi thủ vệ bị tháo, dây xích thả",
                 "Carved stone columns bearing a three-stacked-stone-ring emblem, empty stone cradles with fresh pry "
                 "marks where guardian cores were removed, iron chains hanging loose, a fallen stone guardian arm."),
         "near": ("Đá vỡ, mảnh thủ vệ đá, bậc thềm sụt",
                  "Dark foreground silhouettes: rubble and broken pieces of stone guardians along the bottom edge, a "
                  "cracked archway edge in a top corner. Keep the central 60% height clear."),
         "near_alpha": "giữa ảnh trong suốt", "near_alpha_en": "transparent middle",
         "setting_en": "Setting: inside an abandoned outpost of the ancient stone guardians, carved into the rock above "
                       "the Ashen Valley; cold, dusty, silent, lit by faint orange light through cracks.",
         "continuity": "nối tiếp 1-6 (cùng dấu ba vòng đá, cùng đá xám); trong nhà nên không thấy trời. Hốc lõi trống "
                       "có vết cạy **còn mới** (tay sai vừa lấy).",
         "refs": "nền 1-3 (hầm, có trần) và 1-6 đã duyệt trong assets/backgrounds/stages/ (nếu có) để giữ đá và dấu "
                 "ba vòng đá.",
     }},
    # ---------------------------------------------------------------- 1-8
    {"id": "stage_01_08", "code": "1-8", "name_vi": "Trại Mặt Nạ", "name_en": "Masked Camp",
     "desc": ("Dấu vết dẫn tới trại tạm của tay sai trong hẻm đá. Giữa trại là cột kênh trắng đen đang hút hơi ấm của Lò "
              "Mẹ. Phá trại và tìm ra kế hoạch của hắn.",
              "The trail leads to the henchman's camp in a rocky gorge. In its middle, a black-and-white channel pylon "
              "is siphoning the Mother Hearth's heat. Wreck the camp and uncover his plan."),
     "design": "Hẻm đá ngoài trời, 4 hố, 3 đợt (4 / 5 / 6 quái), không boss: ra lối hẻm.",
     "w": 260, "level": 18, "objectives": (330, 22),
     "pits": [(34, 37), (78, 82), (130, 134), (182, 186)],
     "blocks": [(60, 61, 2), (140, 141, 1), (166, 167, 2)],
     "platforms": [(11, 79, 81), (11, 131, 133), (11, 183, 185), (9, 44, 48), (10, 100, 104), (9, 150, 154),
                   (10, 214, 218)],
     "checkpoints": [50, 120, 176],
     "waves": [wave(16, (10, 32), (S1, 18), (S1, 22), (S2, 26), (S1, 30)),
               wave(90, (84, 128), (S1, 92), (S2, 98), (S1, 104), (S2, 112), (S1, 120)),
               wave(196, (190, 252), (S2, 198), (S1, 206), (S2, 214), (S1, 222), (S2, 230), (S1, 238))],
     "goal_col": 255, "rewards": rew(1900, 750, 950, 7, 5), "first_clear": first(100, 4, 4),
     "barks": [
         ("stage_start", None, "neo", "START", "Cột kênh phía trước đang hút nhiệt về một mạng khác. Định dạng 00.",
          "The pylon ahead is siphoning heat into another network. Format 00.", "", "", 0),
         ("wave_started", 0, E, "WAVE1", "Trại của hắn! Không để sót chỗ nào.", "His camp! Leave nothing standing.",
          "Cặn tro canh quanh trại.", "Ash Dregs are guarding the camp.", 0),
         ("checkpoint", 1, K, "CP1", "Bản ghi trên bàn: \"Tắt lò vào đêm nhật thực đầy nhất.\" Là đêm nay.",
          "A note on the table: \"Kill the Hearth on the night of the deepest eclipse.\" That's tonight.",
          "Bản ghi ghi hạn: đêm nay.", "The note gives a deadline: tonight.", 0),
         ("wave_started", 1, R, "WAVE2", "Đêm nay á?! Vậy phải nhanh lên!", "Tonight?! Then we have to hurry!",
          "Cặn lớn bảo vệ cột kênh.", "Big Dregs are guarding the pylon.", 0),
         ("checkpoint", 2, "neo", "CP2", "Đã ngắt một nhánh cột kênh. Lò Mẹ hết bị hút thêm.",
          "One branch of the pylon is cut. The Hearth isn't being drained any further.", "", "", 0),
         ("wave_started", 2, E, "WAVE3", "Phá nốt chỗ này rồi về cửa lò. Hắn sẽ ở đó.",
          "Finish this, then back to the Hearth gate. He'll be there.", "Bầy cuối canh lối ra của trại.",
          "The last pack guards the camp exit.", 0),
         ("wave_cleared", 2, K, "CLEAR", "Cột kênh đổ rồi. Hắn chỉ còn cách tự ra mặt.",
          "The pylon's down. Now he has to show himself.", "Trại đã bị phá. Ra lối hẻm để hoàn tất.",
          "The camp is wrecked. Head out through the gorge to finish.", 0),
     ],
     "art": {
         "far": ("Hẻm đá hẹp, trời chạng vạng, Mặt Trời Khuyết bị che thêm",
                 "A narrow rocky gorge under a dusk sky turning violet-orange, the Eclipsed Sun with a larger dark bite "
                 "than before, ash hanging in still air."),
         "mid": ("Trại tạm: lều vải than, hòm gỗ, giữa trại cột kênh trắng đen cao phát sáng",
                 "A makeshift camp: charcoal-grey canvas tents, wooden crates, a cold campfire, and in the middle a tall "
                 "black-and-white channel pylon made of stacked rings, glowing and pulling thin threads of orange heat "
                 "out of the ground toward its top."),
         "near": ("Hòm, cọc lều, dây thừng, vũ khí dựng",
                  "Dark foreground silhouettes: crates, tent stakes and ropes, a rack of hooked black glaives along the "
                  "bottom edge. Keep the middle readable."),
         "setting_en": "Setting: the masked henchman's temporary camp hidden in a rocky gorge above the Ashen Valley "
                       "at dusk; the Eclipsed Sun is noticeably more covered than before; no wind.",
         "continuity": "nối tiếp 1-7; **chạng vạng** (trời bắt đầu tím), Mặt Trời Khuyết bị che **nhiều hơn** các màn "
                       "trước. Cột kênh cùng kiểu vòng trắng-đen như cọc ấn 1-5; lưỡi móc đen giống vũ khí tay sai.",
         "refs": "nền 1-5 (cọc ấn) đã duyệt trong assets/backgrounds/stages/stage_01_05/ (nếu có); thiết kế tay sai "
                 "docs/prompts/characters/HENCHMAN_DESIGN.md (ảnh đã duyệt, nếu có) cho kiểu lưỡi móc.",
     }},
    # ---------------------------------------------------------------- 1-9
    {"id": "stage_01_09", "code": "1-9", "name_vi": "Đường Về Cửa Lò", "name_en": "Road Back to the Gate",
     "desc": ("Đêm xuống, nhật thực đầy dần. Đường mòn đêm dẫn ngược về cửa Lò Mẹ, nơi tay sai đang chờ. Cặn tro dày đặc "
              "hơn bao giờ hết.",
              "Night falls as the eclipse deepens. The night trail leads back down to the Mother Hearth's gate, where "
              "the henchman is waiting. The ash Dregs are thicker than ever."),
     "design": "Đường mòn đêm, 5 hố, 3 đợt (4 / 4 / 6 quái, đợt cuối 3 Slime tro lớn), không boss: tới cửa lò.",
     "w": 270, "level": 20, "objectives": (340, 22),
     "pits": [(32, 35), (64, 69), (104, 108), (150, 155), (196, 200)],
     "blocks": [(56, 57, 1), (140, 141, 2)],
     "platforms": [(11, 65, 68), (11, 105, 107), (11, 151, 154), (11, 197, 199), (9, 44, 48), (10, 84, 88),
                   (9, 126, 130), (10, 170, 174)],
     "checkpoints": [46, 118, 184],
     "waves": [wave(14, (8, 30), (S1, 16), (S2, 20), (S1, 24), (S1, 28)),
               wave(78, (72, 102), (S2, 80), (S1, 86), (S2, 92), (S1, 98)),
               wave(212, (206, 262), (S2, 212), (S1, 220), (S2, 228), (S1, 236), (S2, 244), (S1, 252))],
     "goal_col": 265, "rewards": rew(2000, 800, 1000, 7, 6), "first_clear": first(100, 4, 5),
     "barks": [
         ("stage_start", None, "neo", "START", "Mặt Trời Khuyết đang bị che thêm. Vùng Thực dày lên theo từng phút.",
          "The Eclipsed Sun is being covered further. The Hollow Zone thickens by the minute.", "", "", 0),
         ("wave_started", 0, R, "WAVE1", "Tối đen mà Cặn cứ trồi lên mãi!", "It's pitch black and the Dregs keep coming!",
          "Cặn tro dày đặc. Giữ nhịp.", "The Dregs are dense. Keep your rhythm.", 0),
         ("checkpoint", 1, K, "CP1", "Gió vẫn chưa về… Lò mà tắt hẳn đêm nay thì cả làng…",
          "Still no wind… If the Hearth dies tonight, the whole village…", "Nhiệt Lò Mẹ chỉ còn 4%.",
          "The Hearth's heat is down to 4%.", 0),
         ("wave_started", 1, E, "WAVE2", "Không dừng. Cứ thế mà xuyên qua.", "No stopping. We push straight through.",
          "Hai Cặn lớn chắn đường.", "Two big Dregs block the path.", 0),
         ("checkpoint", 2, R, "CP2", "Thấy cửa lò rồi! Có người đứng trước cửa!",
          "I can see the Hearth gate! Someone's standing in front of it!",
          "Phát hiện tín hiệu kênh 00 ở cửa lò.", "Channel 00 signal detected at the Hearth gate.", 0),
         ("wave_started", 2, "neo", "WAVE3", "Bầy cuối trước cửa lò. Sau đó là hắn.",
          "The last pack before the gate. Then it's him.", "", "", 0),
         ("wave_cleared", 2, E, "CLEAR", "Xong. Giờ thì tới lượt ngươi.", "Done. Now it's your turn.",
          "Đường đã thông. Tiến tới cửa lò để hoàn tất.", "The way is open. Head to the Hearth gate to finish.", 0),
     ],
     "art": {
         "far": ("Trời đêm, nhật thực gần đầy (vành sáng mảnh), vách Lò Mẹ tối phía xa",
                 "A night sky in deep indigo, the Eclipsed Sun almost fully covered, only a thin pale orange crescent "
                 "ring left; faint stars; far away on the right, the dark silhouette of the Mother Hearth cliff."),
         "mid": ("Sườn đồi đêm, đường mòn đá, đá tảng và cây chết đen",
                 "Night hillside with a stone trail winding down, boulders and black dead trees, the cold faint violet "
                 "glow of the Hollow Zone haze pooling in the hollows."),
         "near": ("Đá tảng, cỏ khô, cọc đánh dấu đường",
                  "Dark foreground silhouettes: boulders, dry grass tufts and old wooden trail markers along the bottom "
                  "edge. Keep the middle readable."),
         "setting_en": "Setting: a night trail descending back toward the Mother Hearth's gate in the Ashen Valley; the "
                       "eclipse is almost total; cold, dark, no wind, violet Hollow Zone haze in the low ground.",
         "continuity": "nối tiếp 1-8: **đêm**, Mặt Trời Khuyết gần như bị che hết (chỉ còn vành mảnh), vẫn **chưa có "
                       "gió**. Khớp đêm ở ô truyện kết chương (`ch01_end_14`).",
         "refs": "nền 1-8 đã duyệt trong assets/backgrounds/stages/stage_01_08/ (nếu có); nền 1-2 (thung lũng, Lò Mẹ "
                 "lạnh) để giữ dáng vách Lò Mẹ.",
     }},
    # ---------------------------------------------------------------- 1-10
    {"id": "stage_01_10", "code": "1-10", "name_vi": "Cửa Lò Mẹ", "name_en": "The Hearth Gate",
     "desc": ("Trước cửa Lò Mẹ lạnh tối, kẻ đeo mặt nạ chờ sẵn trong bộ giáp của hắn. Hạ hắn trước khi lửa tắt hẳn.",
              "Before the cold, dark gate of the Mother Hearth, the masked henchman waits in his armor. Bring him down "
              "before the fire dies for good."),
     "design": "Cửa lò, 2 hố, 2 đợt (3 / 3 quái), boss kẻ đeo mặt nạ 2 pha ở sân cột 152–206; qua màn phát clip ch01_end.",
     "w": 210, "level": 22, "objectives": (360, 25), "end_clip": "ch01_end",
     "pits": [(40, 44), (96, 100)],
     "blocks": [(70, 71, 1)],
     "platforms": [(11, 41, 43), (11, 97, 99), (9, 60, 64), (10, 120, 124)],
     "checkpoints": [50, 110, 146],
     "waves": [wave(18, (12, 36), (S1, 20), (S2, 26), (S1, 32)),
               wave(80, (74, 94), (S2, 78), (S1, 84), (S2, 90))],
     "boss": {"id": BOSS, "trigger_col": 158, "lock_cols": [152, 206], "col": 190},
     "rewards": rew(2400, 1000, 1200, 8, 6, 2), "first_clear": first(300, 5, 6, 3),
     "barks": [
         ("stage_start", None, "neo", "START", "Đêm nhật thực. Nhiệt Lò Mẹ: 2%. Còn rất ít thời gian.",
          "The eclipse night. Hearth heat: 2%. We're almost out of time.", "", "", 0),
         ("wave_started", 0, K, "WAVE1", "Hắn thả Cặn ra câu giờ. Đừng mắc bẫy, dọn nhanh!",
          "He's using Dregs to stall us. Don't fall for it, clear them fast!", "Cặn tro chắn đường tới cửa lò.",
          "Ash Dregs block the way to the gate.", 0),
         ("wave_started", 1, R, "WAVE2", "Đống đá golem kìa… Chỗ này là nơi mọi chuyện bắt đầu.",
          "The golem's rubble… This is where it all started.", "Đây là chỗ golem đã đổ.",
          "This is where the golem fell.", 0),
         ("boss_started", None, E, "BOSS", "Ngươi sai golem, lấp mạch lửa, phá cầu. Hôm nay dừng ở đây!",
          "You sent the golem, sealed the vein, wrecked the bridge. It ends here!",
          "Mục tiêu: kẻ đeo mặt nạ. Hắn mặc giáp, đánh rất nặng.", "Target: the masked henchman. Armored, hits hard.",
          0.4),
         ("boss_started", None, "neo", "BOSS_B", "Giáp của hắn nhận lệnh qua kênh 00. Đánh vỡ giáp là cắt được kênh.",
          "His armor takes orders through channel 00. Break the armor and the channel goes with it.", "", "", 3.0),
         ("boss_phase", 2, "neo", "PHASE2", "Giáp quá tải! Hắn đang dồn tro vào lưỡi móc.",
          "His armor is overloading! He's packing ash into the glaive.", "", "", 0),
         ("boss_phase", 2, K, "QUAKE", "Sóng tro chạy hai phía, nhảy lên!", "Ash waves both ways, jump!",
          "Sóng tro chạy hai bên! Nhảy lên để tránh nhé.", "Ash waves both ways! Jump to avoid them.", 2.8),
     ],
     "art": {
         "far": ("Đêm nhật thực đầy, vành sáng mảnh; vách Lò Mẹ khổng lồ, cửa lò tối om",
                 "Night of the deepest eclipse: an indigo sky, the Eclipsed Sun reduced to a thin bright ring; the "
                 "gigantic carved furnace gate of the Mother Hearth fills the right half, dark and cold, a barely "
                 "visible dying ember deep inside."),
         "mid": ("Sân đá trước cửa lò, đá vỡ của golem, cột kênh trắng đen nhỏ cắm quanh",
                 "The stone forecourt before the furnace gate: huge broken boulders of the fallen stone golem, and a few "
                 "small black-and-white ring pylons planted around, faintly glowing."),
         "near": ("Đá vụn, mảnh golem, xích lò",
                  "Dark foreground silhouettes: rubble and golem fragments along the bottom edge, old iron furnace "
                  "chains hanging from the top corner. Keep the middle readable."),
         "setting_en": "Setting: the forecourt of the Mother Hearth, a gigantic furnace carved into the cliff of the "
                       "Ashen Valley, on the night of the deepest eclipse; the furnace is cold, there is no wind.",
         "continuity": "nối tiếp 1-9 (**đêm**, nhật thực gần đầy); **cùng nơi** với ô truyện `ch01_golem_01` và "
                       "`ch01_end_01` (cửa lò, đá vỡ golem). Sau trận, clip kết chương cho lò cháy lại.",
         "refs": "ô truyện assets/story/ch01/ch01_golem_01.png và ch01_end_01.png (nếu có) để khớp cửa lò và đá vỡ "
                 "golem; nền 1-9 đã duyệt trong assets/backgrounds/stages/stage_01_09/ (nếu có).",
     }},
]

BOSS_TEXT = {"BOSS_HENCHMAN_01": ("Kẻ Đeo Mặt Nạ", "The Masked Henchman")}

BOSS_TRES = """[gd_resource type="Resource" script_class="BossDef" load_steps=20 format=3]

[ext_resource type="Script" path="res://scripts/enemies/boss_def.gd" id="1"]
[ext_resource type="Script" path="res://scripts/characters/combat_stats.gd" id="2"]
[ext_resource type="Script" path="res://scripts/combat/skill_def.gd" id="3"]
[ext_resource type="Script" path="res://scripts/combat/hit_def.gd" id="4"]
[ext_resource type="Script" path="res://scripts/enemies/boss_phase_def.gd" id="5"]

[sub_resource type="Resource" id="h_sweep"]
script = ExtResource("4")
at_ms = 600.0
duration_ms = 160.0
atk_ratio = 1.4
sc_multiplier = 1.0
shape = 2
rect_size = Vector2(360.0, 150.0)
offset = Vector2(160.0, -90.0)
knockback_px = 200.0
detached = false
travel_px = 0.0

[sub_resource type="Resource" id="sweep"]
script = ExtResource("3")
id = "boss_henchman_01.sweep"
key = "attack"
animation = "sweep"
hit_kind = 8
startup_ms = 600.0
active_ms = 160.0
recovery_ms = 650.0
move_px = 40.0
move_from_ms = 600.0
move_to_ms = 760.0
super_armor = true
hits = Array[ExtResource("4")]([SubResource("h_sweep")])
metadata/source = "Chém quét lưỡi móc: báo hiệu 600 ms, 140% ATK, vùng 360x150 trước mặt, đẩy lùi 200 px"

[sub_resource type="Resource" id="h_dash"]
script = ExtResource("4")
at_ms = 550.0
duration_ms = 350.0
atk_ratio = 1.2
sc_multiplier = 1.0
shape = 2
rect_size = Vector2(180.0, 200.0)
offset = Vector2(60.0, -100.0)
knockback_px = 240.0
detached = false
travel_px = 0.0

[sub_resource type="Resource" id="dash"]
script = ExtResource("3")
id = "boss_henchman_01.dash"
key = "attack"
animation = "dash"
hit_kind = 8
startup_ms = 550.0
active_ms = 350.0
recovery_ms = 700.0
move_px = 460.0
move_from_ms = 550.0
move_to_ms = 900.0
super_armor = true
hits = Array[ExtResource("4")]([SubResource("h_dash")])
metadata/source = "Lao móc: báo hiệu 550 ms, lao 460 px trong 350 ms, 120% ATK, đẩy lùi 240 px"

[sub_resource type="Resource" id="h_wave_f"]
script = ExtResource("4")
at_ms = 800.0
duration_ms = 650.0
atk_ratio = 1.3
sc_multiplier = 1.0
shape = 2
rect_size = Vector2(150.0, 90.0)
offset = Vector2(110.0, -45.0)
knockback_px = 160.0
detached = true
travel_px = 640.0

[sub_resource type="Resource" id="h_wave_b"]
script = ExtResource("4")
at_ms = 800.0
duration_ms = 650.0
atk_ratio = 1.3
sc_multiplier = 1.0
shape = 2
rect_size = Vector2(150.0, 90.0)
offset = Vector2(-110.0, -45.0)
knockback_px = 160.0
detached = true
travel_px = -640.0

[sub_resource type="Resource" id="ash_wave"]
script = ExtResource("3")
id = "boss_henchman_01.ash_wave"
key = "attack"
animation = "ash_wave"
hit_kind = 8
startup_ms = 800.0
active_ms = 200.0
recovery_ms = 700.0
move_px = 0.0
move_from_ms = 0.0
move_to_ms = 0.0
super_armor = true
hits = Array[ExtResource("4")]([SubResource("h_wave_f"), SubResource("h_wave_b")])
metadata/source = "Sóng tro (pha 2): cắm lưỡi móc, báo hiệu 800 ms, hai sóng chạy hai phía 640 px, 130% ATK mỗi sóng"

[sub_resource type="Resource" id="h_sweep2"]
script = ExtResource("4")
at_ms = 450.0
duration_ms = 160.0
atk_ratio = 1.5
sc_multiplier = 1.0
shape = 2
rect_size = Vector2(380.0, 160.0)
offset = Vector2(170.0, -90.0)
knockback_px = 220.0
detached = false
travel_px = 0.0

[sub_resource type="Resource" id="sweep_fast"]
script = ExtResource("3")
id = "boss_henchman_01.sweep"
key = "attack"
animation = "sweep"
hit_kind = 8
startup_ms = 450.0
active_ms = 160.0
recovery_ms = 500.0
move_px = 40.0
move_from_ms = 450.0
move_to_ms = 610.0
super_armor = true
hits = Array[ExtResource("4")]([SubResource("h_sweep2")])
metadata/source = "Chém quét nhanh (pha 2): báo hiệu 450 ms, 150% ATK"

[sub_resource type="Resource" id="h_dash2"]
script = ExtResource("4")
at_ms = 450.0
duration_ms = 350.0
atk_ratio = 1.3
sc_multiplier = 1.0
shape = 2
rect_size = Vector2(180.0, 200.0)
offset = Vector2(60.0, -100.0)
knockback_px = 260.0
detached = false
travel_px = 0.0

[sub_resource type="Resource" id="dash_fast"]
script = ExtResource("3")
id = "boss_henchman_01.dash"
key = "attack"
animation = "dash"
hit_kind = 8
startup_ms = 450.0
active_ms = 350.0
recovery_ms = 600.0
move_px = 520.0
move_from_ms = 450.0
move_to_ms = 800.0
super_armor = true
hits = Array[ExtResource("4")]([SubResource("h_dash2")])
metadata/source = "Lao móc nhanh (pha 2): báo hiệu 450 ms, lao 520 px, 130% ATK"

[sub_resource type="Resource" id="stats"]
script = ExtResource("2")
max_hp = 80000.0
atk = 650.0
def = 420.0
crit_rate = 0.0
crit_damage = 0.5
cdr = 0.0

[sub_resource type="Resource" id="phase1"]
script = ExtResource("5")
hp_ratio_below = 1.0
attacks = Array[ExtResource("3")]([SubResource("sweep"), SubResource("dash")])
attack_cooldown_sec = 1.5
attack_range = 300.0
move_speed_multiplier = 1.0

[sub_resource type="Resource" id="phase2"]
script = ExtResource("5")
hp_ratio_below = 0.5
attacks = Array[ExtResource("3")]([SubResource("ash_wave"), SubResource("sweep_fast"), SubResource("dash_fast")])
attack_cooldown_sec = 1.0
attack_range = 320.0
move_speed_multiplier = 1.3

[resource]
script = ExtResource("1")
id = "boss_henchman_01"
name_key = "BOSS_HENCHMAN_01"
stats = SubResource("stats")
sc_max = 1200.0
sc_decay_delay_sec = 3.0
sc_decay_per_sec = 70.0
move_speed = 170.0
gravity = 2400.0
patrol_radius = 0.0
patrol_pause_sec = 0.5
detect_range = 2000.0
lose_range = 4000.0
attack_range = 300.0
attack_cooldown_sec = 1.5
stagger_sec = 0.0
stagger_push_px = 0.0
death_fade_sec = 1.2
placeholder_color = Color(0.36, 0.37, 0.4, 1)
phases = Array[ExtResource("5")]([SubResource("phase1"), SubResource("phase2")])
phase_transition_sec = 1.2
metadata/source = "Boss 1-10 kẻ đeo mặt nạ (Claude đặt, tools/stages/gen_stages_01_05_10.py): HP 80000, ATK 650, DEF 420, SC 1200, nhanh hơn golem; pha 2 khi HP <= 50%"
"""


def main():
    text = dict(BOSS_TEXT)
    with open(os.path.join(sg.ROOT, "data/enemies/%s.tres" % BOSS), "w", encoding="utf-8", newline="\n") as f:
        f.write(BOSS_TRES)
    for s in STAGES:
        s["generator"] = GEN
        n = int(s["code"].split("-")[1])
        up = s["id"].upper()
        text["%s_NAME" % up] = (s["name_vi"], s["name_en"])
        text["%s_DESC" % up] = s["desc"]
        bk, bt = barks(n, s["barks"])
        text.update(bt)
        sg.write_json("data/stages/%s.json" % s["id"], sg.build_stage(s))
        sg.merge_barks(s["id"], bk)
        doc = sg.write_backdrop_doc(s, s["art"])
        print("%s %-22s %3d cột, %d đợt%s → %s" % (s["code"], s["name_vi"], s["w"], len(s["waves"]),
                                                   " + boss" if "boss" in s else "", doc))
    sg.write_text(text)


if __name__ == "__main__":
    main()
