"""Sinh clip truyện tranh mở / kết chương (owner 2026-11-14) từ kịch bản ở file này.

Chạy (thư mục gốc dự án):  python -X utf8 -I tools/story/gen_story_clips.py

Sinh ra:
  data/story/<clip>.json                          — trang, ô (đa giác, khung 1920x1080), thoại theo khóa chữ
  localization/vi.po, en.po                       — khóa STORY_<CLIP>_* (thêm mới hoặc ghi đè chữ của khóa đã có)
  assets/placeholders/story/placeholder_<ảnh>.png — ảnh tạm đúng kích thước ô, đánh số, vẽ viền vùng hiển thị
  docs/prompts/story/CH01_PANELS.md               — prompt ChatGPT cho từng ô + kích thước để chỉnh bằng Photoshop

Ảnh thật đặt ở assets/story/ch01/<ảnh>.png (đúng tên, cùng tỉ lệ khung; game tự co giãn). Game tìm ảnh thật trước,
rồi tới placeholder, cuối cùng tự vẽ ô xám. Sửa câu chữ ở đây rồi chạy lại (không sửa tay trong .po).
"""
import io
import json
import os
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
W, H = 1920, 1080

# ---------- Bố cục trang (khung thiết kế 1920x1080; vùng truyện y 40..800, dưới là hộp thoại) ----------
LAYOUTS = {
    # 3 ô: trên rộng (thang), dưới chia chéo hai ô
    "A": [[(40, 40), (1880, 40), (1880, 360), (40, 420)],
          [(40, 444), (1000, 413), (940, 800), (40, 800)],
          [(1024, 412), (1880, 384), (1880, 800), (964, 800)]],
    # 3 ô: trái cao (thang), phải hai ô chồng
    "B": [[(40, 40), (760, 40), (700, 800), (40, 800)],
          [(784, 40), (1880, 40), (1880, 380), (754, 420)],
          [(752, 444), (1880, 404), (1880, 800), (724, 800)]],
    # 2 ô chia chéo mạnh
    "C": [[(40, 40), (1300, 40), (900, 800), (40, 800)],
          [(1324, 40), (1880, 40), (1880, 800), (924, 800)]],
    # 3 ô: tam giác trên-trái, dải chéo giữa, tam giác dưới-phải
    "D": [[(40, 40), (1160, 40), (40, 660)],
          [(1200, 40), (1880, 40), (1880, 140), (720, 800), (40, 800), (40, 704)],
          [(1880, 180), (1880, 800), (760, 800)]],
    # 1 ô cả trang
    "E": [[(40, 40), (1880, 40), (1880, 800), (40, 800)]],
    # 2 ô trên / dưới, cạnh chéo
    "F": [[(40, 40), (1880, 40), (1880, 360), (40, 460)],
          [(40, 484), (1880, 384), (1880, 800), (40, 800)]],
    # 4 ô lưới lệch
    "G": [[(40, 40), (940, 40), (925, 404), (40, 424)],
          [(964, 40), (1880, 40), (1880, 384), (949, 403)],
          [(40, 448), (924, 428), (904, 800), (40, 800)],
          [(948, 427), (1880, 408), (1880, 800), (928, 800)]],
}
ENTER = ["left", "up", "right", "down"]
CLIP_LABEL = {"ch01_open": "Mở chương", "ch01_golem": "Cuối ải 1-1", "ch01_end": "Kết chương (cuối ải 1-10)"}

# ---------- Nhân vật (mô tả cho prompt) ----------
E, K, R, N = "char_fire_01", "char_wind_01", "char_lightning_01", "neo"
HM = "henchman"   # tay sai: người mặc giáp của một Quản lý dưới trướng thủ lĩnh mã 00 (chưa có tên; thoại dùng "unknown")
CHAR_DESC = {
    HM: "the masked henchman — a tall suit-wearer in dark ash-grey plated armor with dull orange seams, a smooth "
        "faceless black visor (face never shown), a tattered charcoal cloak, a small half-white half-black ring "
        "emblem on the chest; wields a heavy black hooked glaive",
    E: "Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a "
       "red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade",
    K: "Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal "
       "eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and "
       "a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon",
    R: "Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious "
       "look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm "
       "bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in "
       "each hand",
    N: "NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin "
       "rotating arcs, no face, no limbs",
}
CHAR_REF = {
    E: "assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png",
    K: "assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png",
    R: "assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png",
}
STYLE = ("Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 "
         "tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions "
         "(not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land "
         "under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. "
         "No text, no letters, no speech bubbles, no panel borders, no watermark.")

# ---------- Kịch bản ----------
# Mỗi trang: {"layout", "panels": [ {"chars", "vi" (mô tả cảnh), "en" (cảnh cho prompt), "lines": [(người nói, vi, en)]} ]}
# hoặc {"card": (tiêu đề vi, en, dòng phụ vi, en)}. Người nói: Data ID, "neo", "narration", "unknown" (???).
CLIPS = {
    "ch01_open": {
        "summary": ("Lửa Lò Mẹ tắt dần, còn Golem Đá Cổ thức dậy chắn cửa lò. Xuyên qua thung lũng, vượt qua thủ vệ "
                    "và tìm ra vì sao lửa tắt trước khi quá muộn.",
                    "The Mother Hearth's fire is fading, and the Ancient Stone Golem has woken to block its gate. Cross "
                    "the valley, get past the guardian and find out why the fire is dying before it's too late."),
        "pages": [
            {"layout": "A", "panels": [
                {"chars": [], "vi": "Toàn cảnh cửa thung lũng xám tro, đường dốc xuống, tro rơi thẳng đứng; Mặt Trời "
                 "Khuyết trên trời; cuối thung lũng là vách đá có cửa lò khổng lồ tối om.",
                 "en": "Wide establishing shot of a grey ash-covered valley seen from its mouth: a dirt road sloping "
                       "down, ash falling straight down with no wind, the Eclipsed Sun in a hazy orange sky, and far "
                       "away a cliff with a gigantic dark furnace gate carved into the rock. A faint violet haze line "
                       "crosses the ground (the edge of the Hollow Zone).",
                 "lines": [("narration", "Thung Lũng Tro Tàn.", "The Ashen Valley.")]},
                {"chars": [R], "vi": "Raikiba phanh trượt ngay trước vạch mờ tím, chồm người nhìn vào, ngạc nhiên.",
                 "en": "Raikiba skids to a stop right before the violet haze line, leaning forward to peer into the "
                       "silent valley, surprised, dust kicked up behind him.",
                 "lines": [(R, "Tới rồi! …Ơ. Sao im thế này?", "We're here! …Huh. Why is it so quiet?")]},
                {"chars": [K], "vi": "Kazeyumi giơ một tay dò gió, nét mặt nghiêm; tro rơi thẳng quanh cô.",
                 "en": "Kazeyumi raises one open hand to feel for wind, serious expression, ash falling perfectly "
                       "straight around her, her cape hanging still.",
                 "lines": [(K, "Không có gió. Tro rơi thẳng xuống như rơi trong nhà kín.",
                            "No wind at all. The ash falls straight down, like inside a closed room.")]},
            ]},
            {"layout": "B", "panels": [
                {"chars": [E], "vi": "Enkiba đứng cạnh biển gỗ cháy xém chỉ về làng; đốm than cuối cùng trên biển vừa tắt.",
                 "en": "Tall shot: Enkiba stands beside a half-burnt wooden signpost pointing down the road; the last "
                       "red ember on the sign has just gone out, a thin wisp of smoke rising. Melancholic.",
                 "lines": [(E, "Lò Mẹ ở cuối đường này.", "The Mother Hearth is at the end of this road.")]},
                {"chars": [R], "vi": "Raikiba quay sang Enkiba, nhướng mày.",
                 "en": "Raikiba turns toward Enkiba (off-panel) with a raised eyebrow, half-teasing, half-curious.",
                 "lines": [(R, "Đây là quê cậu à? Hồi ở Lò Nanh cậu kể suốt.",
                            "This is your hometown? You talked about it all the time back at the Fang Forge.")]},
                {"chars": [E], "vi": "Cận mặt Enkiba nhìn xa, lo lắng, ánh tro phản chiếu trong mắt.",
                 "en": "Close-up of Enkiba looking into the distance, worried, grey ash reflected in his amber eyes.",
                 "lines": [(E, "Ừ. Lửa ở đây từng cao hơn mái nhà. Giờ thì… cậu nhìn đi.",
                            "Yeah. The fires here used to burn higher than the rooftops. Now… just look.")]},
            ]},
            {"layout": "D", "panels": [
                {"chars": [N, E, K, R], "vi": "NEO trồi lên lơ lửng phía trước, vòng sáng xoay; ba người nhìn vào nó.",
                 "en": "NEO rises into frame in the foreground, its cyan ring glowing and spinning; behind it Enkiba, "
                       "Kazeyumi and Raikiba look at it, lit by its light.",
                 "lines": [(N, "Phát hiện ranh giới Vùng Thực. Mật độ nguyên tố phía trước chỉ còn 12%.",
                            "Hollow Zone boundary detected. Elemental density ahead is down to 12%.")]},
                {"chars": [K, R], "vi": "Kazeyumi nghiêm mặt; Raikiba gãi đầu, giọt mồ hôi.",
                 "en": "Two-shot: Kazeyumi with a serious face, arms crossed; Raikiba scratching the back of his head, "
                       "sheepish sweat drop.",
                 "lines": [(K, "Đủ nuôi một bộ giáp. Không đủ cho ba.", "Enough to sustain one suit. Not three."),
                           (R, "Vậy là đúng như bản hướng dẫn nói hả? Tớ… đọc lướt thôi.",
                            "So it's like the manual said? I… only skimmed it.")]},
                {"chars": [K, N], "vi": "Kazeyumi quay ra phía người xem (Quản lý), NEO lơ lửng bên cạnh.",
                 "en": "Kazeyumi faces the viewer directly (as if talking to the Manager behind the camera), NEO "
                       "floating at her shoulder.",
                 "lines": [(K, "Một người ra sân, hai người chờ trong kênh của Neo. Quản lý quyết định ai ra.",
                            "One of us takes the field, two wait in Neo's channel. The Manager decides who goes out."),
                           (N, "Khi kênh của ai đó cộng hưởng, tôi sẽ báo. Đổi đúng lúc ấy, hai nguyên tố sẽ chạm nhau.",
                            "When someone's channel resonates, I'll signal. Switch right then and two elements collide."),
                           (R, "Rồi nổ chứ gì! Phần đó thì tớ nhớ.", "And then boom! That part I remember.")]},
            ]},
            {"layout": "C", "panels": [
                {"chars": [], "vi": "Cuối thung lũng: trong bóng tối trước cửa Lò Mẹ, hai đốm mắt cam đỏ sáng lên trên "
                 "một khối đá khổng lồ.",
                 "en": "Dramatic shot down the valley: in the darkness before the giant furnace gate, two orange-red "
                       "eyes light up on a towering stone silhouette — the Ancient Stone Golem, cracks glowing faintly. "
                       "The ground trembles, ash jumps.",
                 "lines": [(N, "Tín hiệu lớn ở cuối thung lũng. Một thủ vệ đá… nó đang đứng chắn cửa Lò Mẹ.",
                            "Large signal at the end of the valley. A stone guardian… it's standing in front of the Hearth's gate."),
                           (E, "Golem Đá Cổ…? Nó canh Lò Mẹ cả trăm năm, chưa từng nhúc nhích.",
                            "The Ancient Stone Golem…? It's guarded the Hearth for a hundred years and never moved.")]},
                {"chars": [K], "vi": "Kazeyumi nheo mắt nhìn về cuối thung lũng.",
                 "en": "Kazeyumi narrows her eyes toward the far end of the valley, hand on her bow.",
                 "lines": [(K, "Lửa không tự tắt nhanh vậy đâu. Có ai đó đang dập nó.",
                            "Fire doesn't die this fast on its own. Someone is putting it out.")]},
            ]},
            {"layout": "G", "panels": [
                {"chars": [R, K], "vi": "Những khối tro xám nhỏ trồi lên, nảy về phía cuối thung lũng; Raikiba chỉ tay.",
                 "en": "Small grey ash-slime blobs with faint ember specks pop out of the ash and hop toward the far "
                       "end of the valley; Raikiba points at them, Kazeyumi beside him.",
                 "lines": [(R, "Còn mấy cục tro biết nhảy kia là gì?", "And what are those hopping lumps of ash?"),
                           (K, "Cặn. Nguyên tố thừa vón lại. Chúng bị kéo về phía lò, chắn hết đường.",
                            "Dregs. Leftover elements clumped together. They're being pulled toward the Hearth, blocking the road.")]},
                {"chars": [E], "vi": "Enkiba bước tới vạch mờ, giơ kiếm, lưỡi kiếm bén lửa.",
                 "en": "Enkiba steps up to the haze line and raises his sword; a flame ignites along the blade, "
                       "determined face, low angle.",
                 "lines": [(E, "Quản lý. Lò Mẹ mà tắt hẳn thì Vùng Thực nuốt luôn làng tớ. Cho bọn tớ vào.",
                            "Manager. If the Hearth goes out, the Hollow Zone swallows my village. Send us in.")]},
                {"chars": [N], "vi": "NEO sáng cam đều, như gật đầu.",
                 "en": "Close-up of NEO glowing a steady warm orange, as if nodding in agreement.",
                 "lines": [(N, "Đã ghi mục tiêu. Chờ lệnh xuất kích của Quản lý.",
                            "Objective logged. Awaiting the Manager's order to deploy.")]},
                {"chars": [K, R, N], "vi": "Kazeyumi và Raikiba tan thành hạt sáng xanh ngọc và vàng, bay vào NEO.",
                 "en": "Kazeyumi and Raikiba dissolve into teal and yellow light particles that stream into NEO; "
                       "Raikiba gives a thumbs-up, Kazeyumi a small smile.",
                 "lines": [(R, "Cần chạy nhanh thì gọi tớ.", "Call me when you need speed."),
                           (K, "Còn tớ nhắc trước: đừng để bị đánh trúng nhiều quá.",
                            "And a reminder from me: don't take too many hits.")]},
            ]},
            {"card": ("Chương 1 — Thung Lũng Tro Tàn", "Chapter 1 — The Ashen Valley",
                      "Mục tiêu: xuyên qua thung lũng, vượt qua Golem Đá Cổ đang chắn cửa Lò Mẹ.",
                      "Objective: cross the valley and get past the Ancient Stone Golem blocking the Hearth's gate.")},
        ],
    },
    "ch01_golem": {
        "summary": ("Golem đổ, nhưng Lò Mẹ vẫn lạnh: thủ vệ chỉ bị sai tới chặn đường. Trong đá vỡ có mảnh ấn kênh mã 00, "
                    "và một kẻ đeo mặt nạ đứng nhìn từ trên vách rồi bỏ đi. Kẻ dập lửa thật vẫn ở trong thung lũng.",
                    "The golem falls, but the Mother Hearth stays cold: the guardian was only sent to block the way. In "
                    "the rubble lies a channel seal coded 00, and a masked figure watches from the cliff before "
                    "leaving. Whoever is putting out the fire is still in the valley."),
        "pages": [
            {"layout": "F", "panels": [
                {"chars": [E], "vi": "Golem đổ sụp thành từng khối đá trước cửa Lò Mẹ lạnh tối; Enkiba thở dốc, kiếm hạ xuống.",
                 "en": "Wide shot: the Ancient Stone Golem collapses into huge boulders in front of the cold, dark mouth "
                       "of the gigantic Mother Hearth carved into the cliff; dust and ash billow; Enkiba stands panting, "
                       "sword lowered, seen from behind.",
                 "lines": [(N, "Thủ vệ đã ngừng hoạt động. Mở kênh: mọi người ra được rồi.",
                            "The guardian has shut down. Opening the channel: everyone can come out.")]},
                {"chars": [R, K], "vi": "Raikiba và Kazeyumi hiện ra từ hạt sáng; Raikiba ngồi phịch xuống, Kazeyumi nhìn lên lò.",
                 "en": "Raikiba and Kazeyumi materialize from teal and yellow light particles; Raikiba flops down on a "
                       "rock grinning, while Kazeyumi already looks up at the furnace with a frown.",
                 "lines": [(R, "Phù… Xong rồi chứ?", "Phew… We're done, right?"),
                           (K, "Chưa. Nhìn lò kìa.", "Not yet. Look at the Hearth.")]},
            ]},
            {"layout": "C", "panels": [
                {"chars": [E, N], "vi": "Enkiba ngước nhìn cửa lò vẫn lạnh ngắt; NEO lơ lửng bên cạnh, ánh xanh nhạt.",
                 "en": "Enkiba looks up at the still-cold, dark furnace mouth; NEO floats beside him glowing a pale, "
                       "uncertain cyan. No fire anywhere.",
                 "lines": [(E, "Lò Mẹ vẫn lạnh…", "The Hearth is still cold…"),
                           (N, "Thủ vệ không hút lửa. Nó chỉ đứng chắn cửa lò.",
                            "The guardian wasn't draining the fire. It was only blocking the gate.")]},
                {"chars": [K], "vi": "Kazeyumi quỳ một gối, đặt tay lên đầu đá của golem.",
                 "en": "Kazeyumi kneels on one knee and gently lays her hand on the golem's broken stone head; its eye "
                       "sockets are dark now. Quiet, sorrowful mood.",
                 "lines": [(K, "Nó không ác. Có kẻ sai nó tới chặn bọn mình.",
                            "It wasn't evil. Someone sent it to stop us.")]},
            ]},
            {"layout": "B", "panels": [
                {"chars": [R], "vi": "Raikiba nhặt từ đống đá một chiếc đĩa nhỏ phát sáng trắng đen.",
                 "en": "Tall shot: Raikiba crouches among the golem rubble holding up a small disc that glows half white, "
                       "half black, with a ring pattern; puzzled look.",
                 "lines": [(R, "Cái gì đây? Trông giống vòng sáng của Neo ghê.", "What's this? It looks a lot like Neo's ring.")]},
                {"chars": [N], "vi": "Cận chiếc đĩa; NEO lại gần, vòng sáng nhiễu loạn.",
                 "en": "Close-up of the white-and-black disc with its ring sigil; NEO hovers right next to it, its cyan "
                       "ring glitching and flickering.",
                 "lines": [(N, "Mảnh ấn kênh… định dạng trùng với tôi. Nguồn lệnh: 00.",
                            "A channel seal fragment… same format as mine. Command source: 00."),
                           (K, "Neo của chúng ta đâu phải số 00.", "Our Neo isn't number 00.")]},
                {"chars": [E], "vi": "Enkiba nghiêm mặt, siết chuôi kiếm, cửa lò lạnh phía sau.",
                 "en": "Enkiba with a grim face, gripping his sword hilt tightly, the cold dark furnace behind him.",
                 "lines": [(E, "Vậy kẻ thật sự dập lửa vẫn còn trong thung lũng.",
                            "Then whoever is really putting out the fire is still in this valley.")]},
            ]},
            {"layout": "A", "panels": [
                {"chars": [HM], "vi": "Trên đỉnh vách phía trên Lò Mẹ, một kẻ mặc giáp xám tro, mặt nạ đen trơn, đứng nhìn xuống "
                 "rồi quay lưng.",
                 "en": "Wide shot from below: high on the cliff edge above the cold Mother Hearth stands the masked "
                       "henchman against the hazy sky and the Eclipsed Sun, looking down, cloak hanging still, already "
                       "half-turned to leave.",
                 "lines": [("unknown", "Thủ vệ chỉ để câu giờ. Báo với Quản lý: lò sẽ tắt đúng hẹn.",
                            "The guardian was only to buy time. Tell the Manager: the Hearth will die on schedule.")]},
                {"chars": [R], "vi": "Raikiba bật dậy chỉ tay lên vách.",
                 "en": "Raikiba springs up and points sharply up at the cliff, shouting, daggers in his other hand.",
                 "lines": [(R, "Trên kia! Có người!", "Up there! Someone's there!")]},
                {"chars": [E, N], "vi": "Enkiba nhìn theo, quyết tâm; NEO sáng đỏ cảnh báo.",
                 "en": "Enkiba glares up toward the now-empty cliff edge, determined; NEO beside him glows a warning red.",
                 "lines": [(E, "Đuổi theo. Phải tìm ra hắn trước khi Lò Mẹ tắt hẳn.",
                            "After him. We have to find him before the Hearth goes out for good."),
                           (N, "Đã ghi dấu kênh lạ. Chờ lệnh của Quản lý.",
                            "Unknown channel trace logged. Awaiting the Manager's orders.")]},
            ]},
            {"card": ("Ải 1-1 — Hoàn thành", "Stage 1-1 — Complete",
                      "Tiếp theo: lần theo kẻ đeo mặt nạ qua Thung Lũng Tro Tàn.",
                      "Next: follow the masked figure through the Ashen Valley.")},
        ],
    },
    "ch01_end": {
        "summary": ("Kẻ đeo mặt nạ bị đánh bại và bị rút về một kênh lạ. Lò Mẹ cháy lại, làng an toàn. Hai mảnh ấn mã 00 "
                    "cho thấy hắn chỉ là tay sai của một Quản lý khác, dưới trướng thủ lĩnh mã 00. Manh mối dẫn tới "
                    "Cao nguyên Thủ Vệ.",
                    "The masked henchman is defeated and pulled back through a strange channel. The Mother Hearth burns "
                    "again and the village is safe. Two seals coded 00 show he was only the henchman of another Manager, "
                    "serving the leader known as 00. The trail leads to the Guardian Highlands."),
        "pages": [
            {"layout": "F", "panels": [
                {"chars": [E, HM], "vi": "Trước cửa Lò Mẹ lạnh tối; kẻ đeo mặt nạ quỳ gối, giáp nứt vỡ; Enkiba chĩa kiếm.",
                 "en": "Wide shot: before the cold, dark mouth of the Mother Hearth, the masked henchman kneels on one "
                       "knee, his ash-grey armor cracked and smoking, glaive dropped; Enkiba stands over him, flaming "
                       "sword pointed at him.",
                 "lines": [(N, "Giáp của hắn đã vỡ. Vùng Thực loãng rồi: mọi người ra được.",
                            "His suit is broken. The Hollow Zone has thinned: everyone can come out.")]},
                {"chars": [R, K], "vi": "Raikiba và Kazeyumi hiện ra từ hạt sáng; Raikiba ngồi phịch xuống.",
                 "en": "Raikiba and Kazeyumi materialize from teal and yellow light particles; Raikiba flops down to sit "
                       "on a rock, exhausted but grinning.",
                 "lines": [(R, "Phù… Tên này còn lì hơn cả con golem.", "Phew… This guy was tougher than the golem.")]},
            ]},
            {"layout": "C", "panels": [
                {"chars": [HM, K], "vi": "Kẻ đeo mặt nạ ngẩng lên cười khẩy; Kazeyumi giương cung.",
                 "en": "The masked henchman lifts his faceless visor toward them in mockery; Kazeyumi draws her bow at "
                       "him, cold expression.",
                 "lines": [("unknown", "Thắng một tay sai thì đã sao. Quản lý của ta chỉ cần lò này tắt một đêm.",
                            "So you beat a henchman. My Manager only needed this Hearth dark for one night."),
                           (K, "Quản lý của ngươi là ai?", "Who is your Manager?")]},
                {"chars": [HM, E, N], "vi": "Kẻ đeo mặt nạ tan thành hạt sáng trắng đen, bị kéo đi; Enkiba vươn tay chụp hụt.",
                 "en": "The henchman dissolves into black-and-white light particles that are sucked away into nothing; "
                       "Enkiba lunges and grabs only empty air; NEO's ring flickers.",
                 "lines": [(E, "Đứng lại!", "Stop!"),
                           (N, "Hắn bị rút về một kênh khác. Định dạng… 00.",
                            "He was pulled back into another channel. Format… 00.")]},
            ]},
            {"layout": "D", "panels": [
                {"chars": [E], "vi": "Kiếm bén lửa của Enkiba chạm vào miệng lò.",
                 "en": "Close-up: the tip of Enkiba's flaming sword touches the stone lip of the furnace mouth; a single "
                       "spark catches.",
                 "lines": [(E, "Dậy đi. Tới lượt cậu rồi.", "Wake up. It's your turn now.")]},
                {"chars": [E, R], "vi": "Lò Mẹ bùng cháy rực rỡ, đốm lửa bay lên; Raikiba nhảy cẫng lên.",
                 "en": "The Mother Hearth roars back to life with a huge warm orange glow, embers rising into the sky; "
                       "Enkiba lowers his sword, smiling; Raikiba jumps for joy in the foreground.",
                 "lines": [(E, "…Cháy rồi.", "…It's burning."), (R, "Cháy rồi! Cháy thật rồi!", "It's burning! It's really burning!")]},
                {"chars": [K, N], "vi": "Kazeyumi mỉm cười, đốm lửa bay ngang theo gió vừa trở lại.",
                 "en": "Kazeyumi smiles with her eyes closed as embers drift sideways on a returning breeze, her "
                       "ponytail and cape lifting; NEO glows calm green.",
                 "lines": [(K, "Gió cũng về rồi. Nghe này.", "The wind is back too. Listen."),
                           (N, "Ranh giới Vùng Thực đã lùi 2 km. Làng Lò Than an toàn rồi.",
                            "The Hollow Zone boundary has receded 2 km. Coalhearth Village is safe.")]},
            ]},
            {"layout": "B", "panels": [
                {"chars": [R], "vi": "Raikiba giơ hai chiếc đĩa trắng đen: một từ golem, một hắn đánh rơi.",
                 "en": "Tall shot: Raikiba holds up two small discs glowing half white, half black, one in each hand, "
                       "comparing them; the burning hearth lights the scene warmly.",
                 "lines": [(R, "Hắn làm rơi cái này. Giống hệt cái trong golem.",
                            "He dropped this. Same as the one in the golem.")]},
                {"chars": [N], "vi": "Cận hai chiếc đĩa; NEO lại gần, vòng sáng nhiễu loạn.",
                 "en": "Close-up of the two white-and-black discs side by side with their ring sigils; NEO hovers next "
                       "to them, its cyan ring glitching.",
                 "lines": [(N, "Cả hai cùng nguồn lệnh 00. Golem và tên đó nhận lệnh từ cùng một mạng kênh.",
                            "Both share command source 00. The golem and that man took orders from the same channel network."),
                           (K, "Tay sai, rồi Quản lý của hắn, rồi kẻ mang mã 00…",
                            "A henchman, then his Manager, then whoever carries code 00…")]},
                {"chars": [E], "vi": "Enkiba nghiêm mặt, siết chuôi kiếm.",
                 "en": "Enkiba with a grim face, gripping his sword hilt tightly, the burning hearth behind him.",
                 "lines": [(E, "Tớ sẽ lần ra từng người một. Không ai được dập lửa của làng tớ nữa.",
                            "I'll track down every one of them. Nobody puts out my village's fire again.")]},
            ]},
            {"layout": "A", "panels": [
                {"chars": [K], "vi": "Tấm giáp lưng golem lật lên: dấu khắc ba vòng đá chồng nhau.",
                 "en": "Wide shot: Kazeyumi has flipped over a large back-plate of the golem rubble, revealing an "
                       "engraved crest of three stacked stone rings.",
                 "lines": [(K, "Dấu này tớ từng thấy trên bản đồ. Xưởng làm thủ vệ trên cao nguyên đá.",
                            "I've seen this mark on maps. The guardian workshop up on the stone highlands."),
                           (K, "Muốn sai được thủ vệ thì chắc chúng đã ghé đó trước.",
                            "To command a guardian, they must have gone there first.")]},
                {"chars": [R], "vi": "Raikiba nhét hai chiếc đĩa vào túi, cười.",
                 "en": "Raikiba tucks the two discs into his pocket with a confident grin, ready to go.",
                 "lines": [(R, "Đi luôn hả? Chân tớ vẫn còn nóng.", "Heading out right away? My legs are still warmed up.")]},
                {"chars": [E, N], "vi": "Enkiba nhìn lại Lò Mẹ đang cháy rồi quay đi.",
                 "en": "Enkiba glances back at the blazing hearth over his shoulder, then turns toward the road; NEO "
                       "glows orange beside him.",
                 "lines": [(E, "Đi. Lò Mẹ cháy lại rồi. Tớ không để nơi nào khác tắt như vậy nữa.",
                            "Let's go. The Hearth burns again. I won't let anywhere else go dark like this."),
                           (N, "Đã ghi tọa độ: Cao nguyên Thủ Vệ. Chờ lệnh của Quản lý.",
                            "Coordinates logged: the Guardian Highlands. Awaiting the Manager's orders.")]},
            ]},
            {"layout": "E", "panels": [
                {"chars": [], "vi": "Đêm, đỉnh vách đá trên thung lũng; Lò Mẹ cháy sáng phía dưới; một bóng người cầm "
                 "vòng sáng trắng đen giống Neo (Quản lý của tay sai).",
                 "en": "Night. On a cliff top above the valley stands a lone silhouette (pure black shape, face never "
                       "shown, long coat moving in the wind), holding a glowing white-and-black ring device like NEO; "
                       "far below, the Mother Hearth burns bright orange. Ominous, quiet.",
                 "lines": [("unknown", "Tay sai thua rồi à. Không sao. Báo với 00: thủ vệ trên cao nguyên còn nhiều.",
                            "So the henchman lost. No matter. Tell 00: there are plenty more guardians on the highlands.")]},
            ]},
            {"card": ("Chương 1 — Hoàn thành", "Chapter 1 — Complete",
                      "Chương 2: Xưởng Đá Ngủ — sắp ra mắt", "Chapter 2: The Sleeping Stone Workshop — coming soon")},
        ],
    },
}


# ---------- Sinh ----------

def bbox(poly):
    xs = [p[0] for p in poly]
    ys = [p[1] for p in poly]
    return min(xs), min(ys), max(xs), max(ys)


def gen_size(w, h):
    r = w / h
    if r >= 1.25:
        return "1536×1024 (ngang)"
    if r <= 0.8:
        return "1024×1536 (dọc)"
    return "1024×1024 (vuông)"


def font(size):
    for f in ("arialbd.ttf", "arial.ttf", "DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            continue
    return ImageFont.load_default()


def font_regular(size):
    for f in ("arial.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            continue
    return ImageFont.load_default()


class Rows:
    """Khoảng x của đa giác (đã thu vào) ở từng hàng, tính một lần; bề ngang chữ tối đa `max_w`."""

    def __init__(self, mask, max_w):
        self.h = mask.height
        self.max_w = max_w
        self.spans = []
        for y in range(mask.height):
            b = mask.crop((0, y, mask.width, y + 1)).getbbox()
            self.spans.append((b[0], b[2]) if b else None)

    def span(self, y0, y1):
        lo, hi = 0, 1 << 30
        for y in (int(y0), int((y0 + y1) / 2), int(y1)):
            if y < 0 or y >= self.h or self.spans[y] is None:
                return None
            lo, hi = max(lo, self.spans[y][0]), min(hi, self.spans[y][1])
        if hi - lo <= 40:
            return None
        if hi - lo > self.max_w:                     # dòng quá dài khó đọc: thu về giữa khoảng
            mid = (lo + hi) / 2
            lo, hi = mid - self.max_w / 2, mid + self.max_w / 2
        return lo, hi


def _flow(mask, top, rows):
    """Xếp các dòng [(font, text, color, wrap)] từ hàng `top`, mỗi dòng canh giữa theo bề ngang đa giác tại hàng đó.
    Trả về [(x giữa, y, font, chữ, màu)] hoặc None nếu không vừa."""
    out, y = [], top
    for f, text, color, wrap in rows:
        lh = f.size * 1.32
        words = text.split(" ") if wrap else [text]
        while words:
            sp = mask.span(y, y + lh)
            if sp is None:
                return None
            avail = sp[1] - sp[0]
            line = words[0]
            if f.getlength(line) > avail:
                return None
            n = 1
            while n < len(words) and f.getlength(line + " " + words[n]) <= avail:
                line += " " + words[n]
                n += 1
            words = words[n:]
            out.append(((sp[0] + sp[1]) / 2, y, f, line, color))
            y += lh
        y += 6
    return out


def placeholder(path, num, name, poly, w, h, shape, desc):
    """Ảnh tạm đúng kích thước ô: vùng hiện (xám) chứa số ô + diễn biến cảnh; vùng bị cắt gạch chéo."""
    x0, y0 = bbox(poly)[:2]
    local = [(p[0] - x0, p[1] - y0) for p in poly]
    img = Image.new("RGB", (w, h), (36, 38, 46))
    d = ImageDraw.Draw(img)
    for i in range(-h, w, 28):                       # gạch chéo = vùng bị cắt
        d.line([(i, 0), (i + h, h)], fill=(52, 54, 64), width=6)
    d.polygon(local, fill=(96, 104, 122))
    d.line(local + [local[0]], fill=(255, 216, 77), width=6)
    # Vùng đặt chữ: đa giác thu vào ~28 px.
    from PIL import ImageFilter
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.polygon(local, fill=255)
    md.rectangle([0, 0, w - 1, h - 1], outline=0, width=2)   # mép ảnh cũng là biên khi thu vùng chữ
    mask = Rows(mask.filter(ImageFilter.MinFilter(57)), max(320, w * 0.62))
    cy = sum(p[1] for p in local) / len(local)
    best = None
    for size in range(54, 13, -2):
        rows = [(font(int(size * 1.9)), "%02d" % num, (255, 255, 255), False),
                (font(size), "DIỄN BIẾN", (255, 216, 77), False),
                (font_regular(size), desc, (240, 242, 250), True),
                (font_regular(max(12, int(size * 0.7))), "%s · %d×%d px · %s" % (name, w, h, shape), (200, 205, 220), True)]
        for top in range(0, h, 4):
            fl = _flow(mask, top, rows)
            if fl is None:
                continue
            mid = (fl[0][1] + fl[-1][1] + fl[-1][2].size) / 2
            if best is None or abs(mid - cy) < best[0]:
                best = (abs(mid - cy), fl)
        if best:
            break
    if best:
        for cx, y, f, text, color in best[1]:
            d.text((cx, y), text, font=f, fill=color, anchor="ma")
    img.save(path)


def esc(t):
    return t.replace("\\", "\\\\").replace('"', '\\"')


def main():
    keys = {}
    doc = []
    num = 0
    os.makedirs(os.path.join(ROOT, "data/story"), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "assets/placeholders/story"), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "docs/prompts/story"), exist_ok=True)
    shape_names = {3: "tam giác", 4: "tứ giác (thang / bình hành)", 6: "lục giác (dải chéo)"}
    for clip_id, clip in CLIPS.items():
        up = clip_id.upper()
        out = {"_comment": "Sinh bởi tools/story/gen_story_clips.py — sửa ở đó rồi chạy lại.",
               "id": clip_id, "design_size": [W, H], "image_dir": "res://assets/story/ch01",
               "placeholder_dir": "res://assets/placeholders/story",
               "summary": "STORY_%s_SUMMARY" % up, "pages": []}
        keys["STORY_%s_SUMMARY" % up] = clip["summary"]
        doc.append("\n## %s — %s\n" % (clip_id, CLIP_LABEL[clip_id]))
        pn = 0
        for page in clip["pages"]:
            if "card" in page:
                t_vi, t_en, s_vi, s_en = page["card"]
                k = "STORY_%s_CARD" % up
                keys[k + "_TITLE"] = (t_vi, t_en)
                keys[k + "_SUB"] = (s_vi, s_en)
                out["pages"].append({"card": {"title": k + "_TITLE", "sub": k + "_SUB"}})
                continue
            pn += 1
            polys = LAYOUTS[page["layout"]]
            assert len(polys) == len(page["panels"]), (clip_id, pn)
            pg = {"layout": page["layout"], "panels": []}
            doc.append("\n### Trang %d (bố cục %s)\n" % (pn, page["layout"]))
            for i, (poly, p) in enumerate(zip(polys, page["panels"])):
                num += 1
                local_n = len([1 for _ in pg["panels"]]) + 1
                idx = sum(len(x.get("panels", [])) for x in out["pages"]) + local_n
                name = "%s_%02d" % (clip_id, idx)
                x0, y0, x1, y1 = bbox(poly)
                w, h = x1 - x0, y1 - y0
                lines = []
                for j, (spk, vi, en) in enumerate(p["lines"], 1):
                    k = "STORY_%s_%s_%d" % (up, name.split("_")[-1], j)
                    keys[k] = (vi, en)
                    lines.append({"speaker": spk, "text": k})
                pg["panels"].append({"image": name, "poly": [list(q) for q in poly],
                                     "enter": ENTER[(num - 1) % len(ENTER)], "desc": p["vi"], "lines": lines})
                shape = shape_names.get(len(poly), "đa giác")
                placeholder(os.path.join(ROOT, "assets/placeholders/story/placeholder_%s.png" % name), idx, name, poly,
                            w, h, shape, p["vi"])
                chars = [c for c in p["chars"] if c in CHAR_DESC]
                refs = [CHAR_REF[c] for c in chars if c in CHAR_REF]
                prompt = "%s\n\nScene: %s" % (STYLE, p["en"])
                if chars:
                    prompt += "\n\nCharacters:\n" + "\n".join("- " + CHAR_DESC[c] for c in chars)
                prompt += ("\n\nComposition: final image %dx%d px (aspect %.2f:1). The visible area is a %s panel; keep "
                           "the main subject inside it (see the numbered placeholder)." % (
                               w, h, w / h, {3: "triangular", 4: "slanted quadrilateral", 6: "diagonal band"}.get(len(poly), "polygon")))
                doc.append("\n#### %s — ô %02d — `%s.png`\n" % (CLIP_LABEL[clip_id],
                                                                 idx, name))
                doc.append("- **Kích thước ảnh:** %d × %d px (1×; khuyến nghị làm 2× = %d × %d rồi lưu, game tự co). "
                           "Tạo bằng ChatGPT ở %s rồi cắt / co cho đúng tỉ lệ trong Photoshop.\n" % (w, h, w * 2, h * 2, gen_size(w, h)))
                doc.append("- **Hình ô:** %s. Placeholder: `assets/placeholders/story/placeholder_%s.png` (vùng xám = "
                           "phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop "
                           "để canh chủ thể.\n" % (shape, name))
                doc.append("- **Cảnh:** %s\n" % p["vi"])
                if lines:
                    doc.append("- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** " + " / ".join(
                        "%s: “%s”" % (sp, vi) for (sp, vi, _en) in p["lines"]) + "\n")
                if refs:
                    doc.append("- **Ảnh tham chiếu đính kèm khi tạo:** " + ", ".join("`%s`" % r for r in refs) + "\n")
                doc.append("- **Lưu thành:** `assets/story/ch01/%s.png`\n\n```text\n%s\n```\n" % (name, prompt))
            out["pages"].append(pg)
        with io.open(os.path.join(ROOT, "data/story/%s.json" % clip_id), "w", encoding="utf-8", newline="\n") as f:
            f.write(json.dumps(out, ensure_ascii=False, indent="\t") + "\n")

    head = """# Prompt ChatGPT cho truyện tranh Chương 1 (mở chương, cuối ải 1-1, kết chương)

> Sinh bởi `tools/story/gen_story_clips.py` — sửa kịch bản ở đó rồi chạy lại. Owner 2026-11-14: clip dẫn truyện là
> các trang truyện tranh, mỗi trang 1–4 ô (vuông, thang, tam giác...) hiện dần, hết trang thì xóa để sang trang mới.

## Cách làm

1. Mở một cuộc trò chuyện mới với ChatGPT (công cụ tạo ảnh). **Đính kèm ảnh tham chiếu** ghi ở từng ô (lấy trong dự án)
   để giữ đúng thiết kế nhân vật. Có thể gửi đoạn "Bối cảnh dự án" bên dưới một lần ở đầu cuộc trò chuyện.
2. Dán prompt của ô (khối `text`). Chọn khung gần nhất theo mục "Tạo bằng ChatGPT ở ...".
3. Trong Photoshop: mở placeholder đúng số làm lớp dưới, đặt ảnh lên, co / cắt cho khớp **đúng kích thước** ghi ở ô
   (hoặc gấp đôi), giữ chủ thể trong vùng xám. Không cần cắt theo hình ô: game tự cắt theo đa giác.
4. Lưu PNG đúng tên vào `assets/story/ch01/`. Game tự dùng ảnh thật thay placeholder, không cần sửa code.
5. Ảnh AI được dùng trong bản phát hành (owner 2026-11-12) nhưng **phải ghi từng file** vào `docs/ASSET_LICENSES.md`
   mục 2.1 (file, công cụ + model, prompt rút gọn, ảnh tham chiếu, ngày) trước khi commit; khai báo nội dung AI trên store.
6. Không vẽ chữ, bóng thoại hay viền ô vào ảnh: game tự hiện thoại và viền.

## Bối cảnh dự án (gửi ChatGPT một lần)

```text
I'm making illustrated story panels for PROJECT ECLIPSE, an original anime-style 2D action RPG. The world lies under the
"Eclipsed Sun": a pale orange sun with a dark bite missing from one side. Where its shadow falls, a "Hollow Zone"
forms and the elements fade: fire dies to ash, the wind stops. Leftover elements clump into small "Dregs" (slime
blobs) and ancient stone guardians go berserk. The player is an unseen Manager who carries NEO, a small floating AI
device (a glowing cyan ring with a light core), which deploys one suit-wearer at a time into the zone.
Chapter 1, "The Ashen Valley": Enkiba (fire, sword), Kazeyumi (wind, bow) and Raikiba (lightning, twin daggers) enter
a grey ash valley where the Mother Hearth, a giant furnace carved into a cliff that keeps Coalhearth Village alive, is
dying. The Ancient Stone Golem was sent to block its gate; the real culprit is a masked henchman in dark ash-grey armor
(faceless black visor), serving another Manager under a leader known only as "00". Keep every character faithful to
the reference images I attach.
Style for all panels: color manga panel, clean line art, cel shading, cinematic lighting. No text or speech bubbles.
```
"""
    with io.open(os.path.join(ROOT, "docs/prompts/story/CH01_PANELS.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write(head + "".join(doc))

    for path, idx in (("localization/vi.po", 0), ("localization/en.po", 1)):
        full = os.path.join(ROOT, path)
        s = io.open(full, encoding="utf-8").read()
        add = []
        for k, v in keys.items():
            val = esc(v[idx])
            pat = re.compile(r'(msgid "%s"\nmsgstr ")[^\n]*(")\n' % re.escape(k))
            if pat.search(s):
                s = pat.sub(lambda m: m.group(1) + val + m.group(2) + "\n", s)
            else:
                add.append('msgid "%s"\nmsgstr "%s"\n' % (k, val))
        if add:
            s = s.rstrip("\n") + "\n\n" + "\n".join(add)
        io.open(full, "w", encoding="utf-8", newline="\n").write(s)
    print("ô:", num, "khóa chữ:", len(keys))


if __name__ == "__main__":
    main()
