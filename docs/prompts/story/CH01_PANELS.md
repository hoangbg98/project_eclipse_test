# Prompt ChatGPT cho truyện tranh Chương 1 (mở chương, cuối ải 1-1, kết chương)

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

## ch01_open — Mở chương

### Trang 1 (bố cục A)

#### Mở chương — ô 01 — `ch01_open_01.png`
- **Kích thước ảnh:** 1840 × 380 px (1×; khuyến nghị làm 2× = 3680 × 760 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_01.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Toàn cảnh cửa thung lũng xám tro, đường dốc xuống, tro rơi thẳng đứng; Mặt Trời Khuyết trên trời; cuối thung lũng là vách đá có cửa lò khổng lồ tối om.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** narration: “Thung Lũng Tro Tàn.”
- **Lưu thành:** `assets/story/ch01/ch01_open_01.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Wide establishing shot of a grey ash-covered valley seen from its mouth: a dirt road sloping down, ash falling straight down with no wind, the Eclipsed Sun in a hazy orange sky, and far away a cliff with a gigantic dark furnace gate carved into the rock. A faint violet haze line crosses the ground (the edge of the Hollow Zone).

Composition: final image 1840x380 px (aspect 4.84:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Mở chương — ô 02 — `ch01_open_02.png`
- **Kích thước ảnh:** 960 × 387 px (1×; khuyến nghị làm 2× = 1920 × 774 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_02.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba phanh trượt ngay trước vạch mờ tím, chồm người nhìn vào, ngạc nhiên.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Tới rồi! …Ơ. Sao im thế này?”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_02.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Raikiba skids to a stop right before the violet haze line, leaning forward to peer into the silent valley, surprised, dust kicked up behind him.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 960x387 px (aspect 2.48:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Mở chương — ô 03 — `ch01_open_03.png`
- **Kích thước ảnh:** 916 × 416 px (1×; khuyến nghị làm 2× = 1832 × 832 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_03.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi giơ một tay dò gió, nét mặt nghiêm; tro rơi thẳng quanh cô.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Không có gió. Tro rơi thẳng xuống như rơi trong nhà kín.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_03.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Kazeyumi raises one open hand to feel for wind, serious expression, ash falling perfectly straight around her, her cape hanging still.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 916x416 px (aspect 2.20:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

### Trang 2 (bố cục B)

#### Mở chương — ô 04 — `ch01_open_04.png`
- **Kích thước ảnh:** 720 × 760 px (1×; khuyến nghị làm 2× = 1440 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1024×1024 (vuông) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_04.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba đứng cạnh biển gỗ cháy xém chỉ về làng; đốm than cuối cùng trên biển vừa tắt.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Lò Mẹ ở cuối đường này.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_04.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Tall shot: Enkiba stands beside a half-burnt wooden signpost pointing down the road; the last red ember on the sign has just gone out, a thin wisp of smoke rising. Melancholic.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 720x760 px (aspect 0.95:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Mở chương — ô 05 — `ch01_open_05.png`
- **Kích thước ảnh:** 1126 × 380 px (1×; khuyến nghị làm 2× = 2252 × 760 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_05.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba quay sang Enkiba, nhướng mày.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Đây là quê cậu à? Hồi ở Lò Nanh cậu kể suốt.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_05.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Raikiba turns toward Enkiba (off-panel) with a raised eyebrow, half-teasing, half-curious.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 1126x380 px (aspect 2.96:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Mở chương — ô 06 — `ch01_open_06.png`
- **Kích thước ảnh:** 1156 × 396 px (1×; khuyến nghị làm 2× = 2312 × 792 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_06.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Cận mặt Enkiba nhìn xa, lo lắng, ánh tro phản chiếu trong mắt.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Ừ. Lửa ở đây từng cao hơn mái nhà. Giờ thì… cậu nhìn đi.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_06.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Close-up of Enkiba looking into the distance, worried, grey ash reflected in his amber eyes.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 1156x396 px (aspect 2.92:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

### Trang 3 (bố cục D)

#### Mở chương — ô 07 — `ch01_open_07.png`
- **Kích thước ảnh:** 1120 × 620 px (1×; khuyến nghị làm 2× = 2240 × 1240 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tam giác. Placeholder: `assets/placeholders/story/placeholder_ch01_open_07.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** NEO trồi lên lơ lửng phía trước, vòng sáng xoay; ba người nhìn vào nó.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Phát hiện ranh giới Vùng Thực. Mật độ nguyên tố phía trước chỉ còn 12%.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`, `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`, `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_07.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: NEO rises into frame in the foreground, its cyan ring glowing and spinning; behind it Enkiba, Kazeyumi and Raikiba look at it, lit by its light.

Characters:
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 1120x620 px (aspect 1.81:1). The visible area is a triangular panel; keep the main subject inside it (see the numbered placeholder).
```

#### Mở chương — ô 08 — `ch01_open_08.png`
- **Kích thước ảnh:** 1840 × 760 px (1×; khuyến nghị làm 2× = 3680 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** lục giác (dải chéo). Placeholder: `assets/placeholders/story/placeholder_ch01_open_08.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi nghiêm mặt; Raikiba gãi đầu, giọt mồ hôi.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Đủ nuôi một bộ giáp. Không đủ cho ba.” / char_lightning_01: “Vậy là đúng như bản hướng dẫn nói hả? Tớ… đọc lướt thôi.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`, `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_08.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Two-shot: Kazeyumi with a serious face, arms crossed; Raikiba scratching the back of his head, sheepish sweat drop.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 1840x760 px (aspect 2.42:1). The visible area is a diagonal band panel; keep the main subject inside it (see the numbered placeholder).
```

#### Mở chương — ô 09 — `ch01_open_09.png`
- **Kích thước ảnh:** 1120 × 620 px (1×; khuyến nghị làm 2× = 2240 × 1240 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tam giác. Placeholder: `assets/placeholders/story/placeholder_ch01_open_09.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi quay ra phía người xem (Quản lý), NEO lơ lửng bên cạnh.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Một người ra sân, hai người chờ trong kênh của Neo. Quản lý quyết định ai ra.” / neo: “Khi kênh của ai đó cộng hưởng, tôi sẽ báo. Đổi đúng lúc ấy, hai nguyên tố sẽ chạm nhau.” / char_lightning_01: “Rồi nổ chứ gì! Phần đó thì tớ nhớ.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_09.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Kazeyumi faces the viewer directly (as if talking to the Manager behind the camera), NEO floating at her shoulder.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 1120x620 px (aspect 1.81:1). The visible area is a triangular panel; keep the main subject inside it (see the numbered placeholder).
```

### Trang 4 (bố cục C)

#### Mở chương — ô 10 — `ch01_open_10.png`
- **Kích thước ảnh:** 1260 × 760 px (1×; khuyến nghị làm 2× = 2520 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_10.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Cuối thung lũng: trong bóng tối trước cửa Lò Mẹ, hai đốm mắt cam đỏ sáng lên trên một khối đá khổng lồ.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Tín hiệu lớn ở cuối thung lũng. Một thủ vệ đá… nó đang đứng chắn cửa Lò Mẹ.” / char_fire_01: “Golem Đá Cổ…? Nó canh Lò Mẹ cả trăm năm, chưa từng nhúc nhích.”
- **Lưu thành:** `assets/story/ch01/ch01_open_10.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Dramatic shot down the valley: in the darkness before the giant furnace gate, two orange-red eyes light up on a towering stone silhouette — the Ancient Stone Golem, cracks glowing faintly. The ground trembles, ash jumps.

Composition: final image 1260x760 px (aspect 1.66:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Mở chương — ô 11 — `ch01_open_11.png`
- **Kích thước ảnh:** 956 × 760 px (1×; khuyến nghị làm 2× = 1912 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_11.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi nheo mắt nhìn về cuối thung lũng.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Lửa không tự tắt nhanh vậy đâu. Có ai đó đang dập nó.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_11.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Kazeyumi narrows her eyes toward the far end of the valley, hand on her bow.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 956x760 px (aspect 1.26:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

### Trang 5 (bố cục G)

#### Mở chương — ô 12 — `ch01_open_12.png`
- **Kích thước ảnh:** 900 × 384 px (1×; khuyến nghị làm 2× = 1800 × 768 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_12.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Những khối tro xám nhỏ trồi lên, nảy về phía cuối thung lũng; Raikiba chỉ tay.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Còn mấy cục tro biết nhảy kia là gì?” / char_wind_01: “Cặn. Nguyên tố thừa vón lại. Chúng bị kéo về phía lò, chắn hết đường.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`, `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_12.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Small grey ash-slime blobs with faint ember specks pop out of the ash and hop toward the far end of the valley; Raikiba points at them, Kazeyumi beside him.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 900x384 px (aspect 2.34:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Mở chương — ô 13 — `ch01_open_13.png`
- **Kích thước ảnh:** 931 × 363 px (1×; khuyến nghị làm 2× = 1862 × 726 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_13.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba bước tới vạch mờ, giơ kiếm, lưỡi kiếm bén lửa.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Quản lý. Lò Mẹ mà tắt hẳn thì Vùng Thực nuốt luôn làng tớ. Cho bọn tớ vào.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_13.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Enkiba steps up to the haze line and raises his sword; a flame ignites along the blade, determined face, low angle.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 931x363 px (aspect 2.56:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Mở chương — ô 14 — `ch01_open_14.png`
- **Kích thước ảnh:** 884 × 372 px (1×; khuyến nghị làm 2× = 1768 × 744 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_14.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** NEO sáng cam đều, như gật đầu.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Đã ghi mục tiêu. Chờ lệnh xuất kích của Quản lý.”
- **Lưu thành:** `assets/story/ch01/ch01_open_14.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Close-up of NEO glowing a steady warm orange, as if nodding in agreement.

Characters:
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 884x372 px (aspect 2.38:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Mở chương — ô 15 — `ch01_open_15.png`
- **Kích thước ảnh:** 952 × 392 px (1×; khuyến nghị làm 2× = 1904 × 784 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_open_15.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi và Raikiba tan thành hạt sáng xanh ngọc và vàng, bay vào NEO.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Cần chạy nhanh thì gọi tớ.” / char_wind_01: “Còn tớ nhắc trước: đừng để bị đánh trúng nhiều quá.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`, `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_open_15.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Kazeyumi and Raikiba dissolve into teal and yellow light particles that stream into NEO; Raikiba gives a thumbs-up, Kazeyumi a small smile.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 952x392 px (aspect 2.43:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

## ch01_golem — Cuối ải 1-1

### Trang 1 (bố cục F)

#### Cuối ải 1-1 — ô 01 — `ch01_golem_01.png`
- **Kích thước ảnh:** 1840 × 420 px (1×; khuyến nghị làm 2× = 3680 × 840 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_01.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Golem đổ sụp thành từng khối đá trước cửa Lò Mẹ lạnh tối; Enkiba thở dốc, kiếm hạ xuống.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Thủ vệ đã ngừng hoạt động. Mở kênh: mọi người ra được rồi.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_01.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Wide shot: the Ancient Stone Golem collapses into huge boulders in front of the cold, dark mouth of the gigantic Mother Hearth carved into the cliff; dust and ash billow; Enkiba stands panting, sword lowered, seen from behind.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 1840x420 px (aspect 4.38:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Cuối ải 1-1 — ô 02 — `ch01_golem_02.png`
- **Kích thước ảnh:** 1840 × 416 px (1×; khuyến nghị làm 2× = 3680 × 832 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_02.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba và Kazeyumi hiện ra từ hạt sáng; Raikiba ngồi phịch xuống, Kazeyumi nhìn lên lò.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Phù… Xong rồi chứ?” / char_wind_01: “Chưa. Nhìn lò kìa.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`, `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_02.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Raikiba and Kazeyumi materialize from teal and yellow light particles; Raikiba flops down on a rock grinning, while Kazeyumi already looks up at the furnace with a frown.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 1840x416 px (aspect 4.42:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

### Trang 2 (bố cục C)

#### Cuối ải 1-1 — ô 03 — `ch01_golem_03.png`
- **Kích thước ảnh:** 1260 × 760 px (1×; khuyến nghị làm 2× = 2520 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_03.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba ngước nhìn cửa lò vẫn lạnh ngắt; NEO lơ lửng bên cạnh, ánh xanh nhạt.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Lò Mẹ vẫn lạnh…” / neo: “Thủ vệ không hút lửa. Nó chỉ đứng chắn cửa lò.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_03.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Enkiba looks up at the still-cold, dark furnace mouth; NEO floats beside him glowing a pale, uncertain cyan. No fire anywhere.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 1260x760 px (aspect 1.66:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Cuối ải 1-1 — ô 04 — `ch01_golem_04.png`
- **Kích thước ảnh:** 956 × 760 px (1×; khuyến nghị làm 2× = 1912 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_04.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi quỳ một gối, đặt tay lên đầu đá của golem.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Nó không ác. Có kẻ sai nó tới chặn bọn mình.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_04.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Kazeyumi kneels on one knee and gently lays her hand on the golem's broken stone head; its eye sockets are dark now. Quiet, sorrowful mood.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 956x760 px (aspect 1.26:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

### Trang 3 (bố cục B)

#### Cuối ải 1-1 — ô 05 — `ch01_golem_05.png`
- **Kích thước ảnh:** 720 × 760 px (1×; khuyến nghị làm 2× = 1440 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1024×1024 (vuông) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_05.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba nhặt từ đống đá một chiếc đĩa nhỏ phát sáng trắng đen.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Cái gì đây? Trông giống vòng sáng của Neo ghê.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_05.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Tall shot: Raikiba crouches among the golem rubble holding up a small disc that glows half white, half black, with a ring pattern; puzzled look.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 720x760 px (aspect 0.95:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Cuối ải 1-1 — ô 06 — `ch01_golem_06.png`
- **Kích thước ảnh:** 1126 × 380 px (1×; khuyến nghị làm 2× = 2252 × 760 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_06.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Cận chiếc đĩa; NEO lại gần, vòng sáng nhiễu loạn.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Mảnh ấn kênh… định dạng trùng với tôi. Nguồn lệnh: 00.” / char_wind_01: “Neo của chúng ta đâu phải số 00.”
- **Lưu thành:** `assets/story/ch01/ch01_golem_06.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Close-up of the white-and-black disc with its ring sigil; NEO hovers right next to it, its cyan ring glitching and flickering.

Characters:
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 1126x380 px (aspect 2.96:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Cuối ải 1-1 — ô 07 — `ch01_golem_07.png`
- **Kích thước ảnh:** 1156 × 396 px (1×; khuyến nghị làm 2× = 2312 × 792 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_07.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba nghiêm mặt, siết chuôi kiếm, cửa lò lạnh phía sau.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Vậy kẻ thật sự dập lửa vẫn còn trong thung lũng.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_07.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Enkiba with a grim face, gripping his sword hilt tightly, the cold dark furnace behind him.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 1156x396 px (aspect 2.92:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

### Trang 4 (bố cục A)

#### Cuối ải 1-1 — ô 08 — `ch01_golem_08.png`
- **Kích thước ảnh:** 1840 × 380 px (1×; khuyến nghị làm 2× = 3680 × 760 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_08.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Trên đỉnh vách phía trên Lò Mẹ, một kẻ mặc giáp xám tro, mặt nạ đen trơn, đứng nhìn xuống rồi quay lưng.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** unknown: “Thủ vệ chỉ để câu giờ. Báo với Quản lý: lò sẽ tắt đúng hẹn.”
- **Lưu thành:** `assets/story/ch01/ch01_golem_08.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Wide shot from below: high on the cliff edge above the cold Mother Hearth stands the masked henchman against the hazy sky and the Eclipsed Sun, looking down, cloak hanging still, already half-turned to leave.

Characters:
- the masked henchman — a tall suit-wearer in dark ash-grey plated armor with dull orange seams, a smooth faceless black visor (face never shown), a tattered charcoal cloak, a small half-white half-black ring emblem on the chest; wields a heavy black hooked glaive

Composition: final image 1840x380 px (aspect 4.84:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Cuối ải 1-1 — ô 09 — `ch01_golem_09.png`
- **Kích thước ảnh:** 960 × 387 px (1×; khuyến nghị làm 2× = 1920 × 774 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_09.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba bật dậy chỉ tay lên vách.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Trên kia! Có người!”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_09.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Raikiba springs up and points sharply up at the cliff, shouting, daggers in his other hand.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 960x387 px (aspect 2.48:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Cuối ải 1-1 — ô 10 — `ch01_golem_10.png`
- **Kích thước ảnh:** 916 × 416 px (1×; khuyến nghị làm 2× = 1832 × 832 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_golem_10.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba nhìn theo, quyết tâm; NEO sáng đỏ cảnh báo.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Đuổi theo. Phải tìm ra hắn trước khi Lò Mẹ tắt hẳn.” / neo: “Đã ghi dấu kênh lạ. Chờ lệnh của Quản lý.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_golem_10.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Enkiba glares up toward the now-empty cliff edge, determined; NEO beside him glows a warning red.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 916x416 px (aspect 2.20:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

## ch01_end — Kết chương (cuối ải 1-10)

### Trang 1 (bố cục F)

#### Kết chương (cuối ải 1-10) — ô 01 — `ch01_end_01.png`
- **Kích thước ảnh:** 1840 × 420 px (1×; khuyến nghị làm 2× = 3680 × 840 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_01.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Trước cửa Lò Mẹ lạnh tối; kẻ đeo mặt nạ quỳ gối, giáp nứt vỡ; Enkiba chĩa kiếm.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Giáp của hắn đã vỡ. Vùng Thực loãng rồi: mọi người ra được.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_01.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Wide shot: before the cold, dark mouth of the Mother Hearth, the masked henchman kneels on one knee, his ash-grey armor cracked and smoking, glaive dropped; Enkiba stands over him, flaming sword pointed at him.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- the masked henchman — a tall suit-wearer in dark ash-grey plated armor with dull orange seams, a smooth faceless black visor (face never shown), a tattered charcoal cloak, a small half-white half-black ring emblem on the chest; wields a heavy black hooked glaive

Composition: final image 1840x420 px (aspect 4.38:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Kết chương (cuối ải 1-10) — ô 02 — `ch01_end_02.png`
- **Kích thước ảnh:** 1840 × 416 px (1×; khuyến nghị làm 2× = 3680 × 832 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_02.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba và Kazeyumi hiện ra từ hạt sáng; Raikiba ngồi phịch xuống.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Phù… Tên này còn lì hơn cả con golem.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`, `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_02.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Raikiba and Kazeyumi materialize from teal and yellow light particles; Raikiba flops down to sit on a rock, exhausted but grinning.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 1840x416 px (aspect 4.42:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

### Trang 2 (bố cục C)

#### Kết chương (cuối ải 1-10) — ô 03 — `ch01_end_03.png`
- **Kích thước ảnh:** 1260 × 760 px (1×; khuyến nghị làm 2× = 2520 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_03.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kẻ đeo mặt nạ ngẩng lên cười khẩy; Kazeyumi giương cung.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** unknown: “Thắng một tay sai thì đã sao. Quản lý của ta chỉ cần lò này tắt một đêm.” / char_wind_01: “Quản lý của ngươi là ai?”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_03.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: The masked henchman lifts his faceless visor toward them in mockery; Kazeyumi draws her bow at him, cold expression.

Characters:
- the masked henchman — a tall suit-wearer in dark ash-grey plated armor with dull orange seams, a smooth faceless black visor (face never shown), a tattered charcoal cloak, a small half-white half-black ring emblem on the chest; wields a heavy black hooked glaive
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 1260x760 px (aspect 1.66:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Kết chương (cuối ải 1-10) — ô 04 — `ch01_end_04.png`
- **Kích thước ảnh:** 956 × 760 px (1×; khuyến nghị làm 2× = 1912 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_04.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kẻ đeo mặt nạ tan thành hạt sáng trắng đen, bị kéo đi; Enkiba vươn tay chụp hụt.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Đứng lại!” / neo: “Hắn bị rút về một kênh khác. Định dạng… 00.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_04.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: The henchman dissolves into black-and-white light particles that are sucked away into nothing; Enkiba lunges and grabs only empty air; NEO's ring flickers.

Characters:
- the masked henchman — a tall suit-wearer in dark ash-grey plated armor with dull orange seams, a smooth faceless black visor (face never shown), a tattered charcoal cloak, a small half-white half-black ring emblem on the chest; wields a heavy black hooked glaive
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 956x760 px (aspect 1.26:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

### Trang 3 (bố cục D)

#### Kết chương (cuối ải 1-10) — ô 05 — `ch01_end_05.png`
- **Kích thước ảnh:** 1120 × 620 px (1×; khuyến nghị làm 2× = 2240 × 1240 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tam giác. Placeholder: `assets/placeholders/story/placeholder_ch01_end_05.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kiếm bén lửa của Enkiba chạm vào miệng lò.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Dậy đi. Tới lượt cậu rồi.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_05.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Close-up: the tip of Enkiba's flaming sword touches the stone lip of the furnace mouth; a single spark catches.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 1120x620 px (aspect 1.81:1). The visible area is a triangular panel; keep the main subject inside it (see the numbered placeholder).
```

#### Kết chương (cuối ải 1-10) — ô 06 — `ch01_end_06.png`
- **Kích thước ảnh:** 1840 × 760 px (1×; khuyến nghị làm 2× = 3680 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** lục giác (dải chéo). Placeholder: `assets/placeholders/story/placeholder_ch01_end_06.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Lò Mẹ bùng cháy rực rỡ, đốm lửa bay lên; Raikiba nhảy cẫng lên.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “…Cháy rồi.” / char_lightning_01: “Cháy rồi! Cháy thật rồi!”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`, `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_06.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: The Mother Hearth roars back to life with a huge warm orange glow, embers rising into the sky; Enkiba lowers his sword, smiling; Raikiba jumps for joy in the foreground.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 1840x760 px (aspect 2.42:1). The visible area is a diagonal band panel; keep the main subject inside it (see the numbered placeholder).
```

#### Kết chương (cuối ải 1-10) — ô 07 — `ch01_end_07.png`
- **Kích thước ảnh:** 1120 × 620 px (1×; khuyến nghị làm 2× = 2240 × 1240 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tam giác. Placeholder: `assets/placeholders/story/placeholder_ch01_end_07.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Kazeyumi mỉm cười, đốm lửa bay ngang theo gió vừa trở lại.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Gió cũng về rồi. Nghe này.” / neo: “Ranh giới Vùng Thực đã lùi 2 km. Làng Lò Than an toàn rồi.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_07.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Kazeyumi smiles with her eyes closed as embers drift sideways on a returning breeze, her ponytail and cape lifting; NEO glows calm green.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 1120x620 px (aspect 1.81:1). The visible area is a triangular panel; keep the main subject inside it (see the numbered placeholder).
```

### Trang 4 (bố cục B)

#### Kết chương (cuối ải 1-10) — ô 08 — `ch01_end_08.png`
- **Kích thước ảnh:** 720 × 760 px (1×; khuyến nghị làm 2× = 1440 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1024×1024 (vuông) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_08.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba giơ hai chiếc đĩa trắng đen: một từ golem, một hắn đánh rơi.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Hắn làm rơi cái này. Giống hệt cái trong golem.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_08.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Tall shot: Raikiba holds up two small discs glowing half white, half black, one in each hand, comparing them; the burning hearth lights the scene warmly.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 720x760 px (aspect 0.95:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Kết chương (cuối ải 1-10) — ô 09 — `ch01_end_09.png`
- **Kích thước ảnh:** 1126 × 380 px (1×; khuyến nghị làm 2× = 2252 × 760 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_09.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Cận hai chiếc đĩa; NEO lại gần, vòng sáng nhiễu loạn.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** neo: “Cả hai cùng nguồn lệnh 00. Golem và tên đó nhận lệnh từ cùng một mạng kênh.” / char_wind_01: “Tay sai, rồi Quản lý của hắn, rồi kẻ mang mã 00…”
- **Lưu thành:** `assets/story/ch01/ch01_end_09.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Close-up of the two white-and-black discs side by side with their ring sigils; NEO hovers next to them, its cyan ring glitching.

Characters:
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 1126x380 px (aspect 2.96:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Kết chương (cuối ải 1-10) — ô 10 — `ch01_end_10.png`
- **Kích thước ảnh:** 1156 × 396 px (1×; khuyến nghị làm 2× = 2312 × 792 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_10.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba nghiêm mặt, siết chuôi kiếm.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Tớ sẽ lần ra từng người một. Không ai được dập lửa của làng tớ nữa.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_10.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Enkiba with a grim face, gripping his sword hilt tightly, the burning hearth behind him.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade

Composition: final image 1156x396 px (aspect 2.92:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

### Trang 5 (bố cục A)

#### Kết chương (cuối ải 1-10) — ô 11 — `ch01_end_11.png`
- **Kích thước ảnh:** 1840 × 380 px (1×; khuyến nghị làm 2× = 3680 × 760 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_11.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Tấm giáp lưng golem lật lên: dấu khắc ba vòng đá chồng nhau.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_wind_01: “Dấu này tớ từng thấy trên bản đồ. Xưởng làm thủ vệ trên cao nguyên đá.” / char_wind_01: “Muốn sai được thủ vệ thì chắc chúng đã ghé đó trước.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_11.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Wide shot: Kazeyumi has flipped over a large back-plate of the golem rubble, revealing an engraved crest of three stacked stone rings.

Characters:
- Kazeyumi — teenage girl (16-19), long wavy teal-green hair in a high ponytail with a white feather ornament, teal eyes, cream sleeveless tunic with teal accents, dark teal short cape, teal pleated skirt, brown leather belts and a quiver, cream boots with small wing ornaments, long wooden recurve bow wrapped with teal ribbon

Composition: final image 1840x380 px (aspect 4.84:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Kết chương (cuối ải 1-10) — ô 12 — `ch01_end_12.png`
- **Kích thước ảnh:** 960 × 387 px (1×; khuyến nghị làm 2× = 1920 × 774 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_12.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Raikiba nhét hai chiếc đĩa vào túi, cười.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_lightning_01: “Đi luôn hả? Chân tớ vẫn còn nóng.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_12.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Raikiba tucks the two discs into his pocket with a confident grin, ready to go.

Characters:
- Raikiba — teenage boy (16-19), spiky silver-white hair with lemon-yellow streaks, teal-green eyes, cool serious look, dark navy high-collar sleeveless zip top and baggy cargo pants with yellow lightning stripes, black arm bands and fingerless gloves, light grey boots with yellow laces, a serrated black-and-yellow curved dagger in each hand

Composition: final image 960x387 px (aspect 2.48:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

#### Kết chương (cuối ải 1-10) — ô 13 — `ch01_end_13.png`
- **Kích thước ảnh:** 916 × 416 px (1×; khuyến nghị làm 2× = 1832 × 832 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_13.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Enkiba nhìn lại Lò Mẹ đang cháy rồi quay đi.
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** char_fire_01: “Đi. Lò Mẹ cháy lại rồi. Tớ không để nơi nào khác tắt như vậy nữa.” / neo: “Đã ghi tọa độ: Cao nguyên Thủ Vệ. Chờ lệnh của Quản lý.”
- **Ảnh tham chiếu đính kèm khi tạo:** `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png`
- **Lưu thành:** `assets/story/ch01/ch01_end_13.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Enkiba glances back at the blazing hearth over his shoulder, then turns toward the road; NEO glows orange beside him.

Characters:
- Enkiba — teenage boy (16-19), spiky red-orange hair, amber eyes, black cropped jacket with red flame trim and a red shoulder guard, white shirt, red trousers, black boots, carries a sword with a flame-patterned orange blade
- NEO — a small floating AI device: a palm-sized glowing cyan ring around a soft white light core, two thin rotating arcs, no face, no limbs

Composition: final image 916x416 px (aspect 2.20:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```

### Trang 6 (bố cục E)

#### Kết chương (cuối ải 1-10) — ô 14 — `ch01_end_14.png`
- **Kích thước ảnh:** 1840 × 760 px (1×; khuyến nghị làm 2× = 3680 × 1520 rồi lưu, game tự co). Tạo bằng ChatGPT ở 1536×1024 (ngang) rồi cắt / co cho đúng tỉ lệ trong Photoshop.
- **Hình ô:** tứ giác (thang / bình hành). Placeholder: `assets/placeholders/story/placeholder_ch01_end_14.png` (vùng xám = phần hiện trong game, vùng gạch chéo bị cắt). Dùng placeholder làm lớp dưới trong Photoshop để canh chủ thể.
- **Cảnh:** Đêm, đỉnh vách đá trên thung lũng; Lò Mẹ cháy sáng phía dưới; một bóng người cầm vòng sáng trắng đen giống Neo (Quản lý của tay sai).
- **Thoại trên ô này (game tự hiện, không vẽ vào ảnh):** unknown: “Tay sai thua rồi à. Không sao. Báo với 00: thủ vệ trên cao nguyên còn nhiều.”
- **Lưu thành:** `assets/story/ch01/ch01_end_14.png`

```text
Anime 2D illustration in the style of a color manga panel: clean confident line art, cel shading with 2-3 tones, cinematic lighting, slightly desaturated warm palette. Characters in standard anime proportions (not chibi), faithful to the attached reference images (hair, colors, outfit, weapon). World: a fantasy land under the 'Eclipsed Sun' — a pale orange sun with a dark bite missing from one side. No text, no letters, no speech bubbles, no panel borders, no watermark.

Scene: Night. On a cliff top above the valley stands a lone silhouette (pure black shape, face never shown, long coat moving in the wind), holding a glowing white-and-black ring device like NEO; far below, the Mother Hearth burns bright orange. Ominous, quiet.

Composition: final image 1840x760 px (aspect 2.42:1). The visible area is a slanted quadrilateral panel; keep the main subject inside it (see the numbered placeholder).
```
