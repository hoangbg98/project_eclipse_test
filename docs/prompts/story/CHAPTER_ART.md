# Ảnh map chương và thẻ chương (ChatGPT)

> Sinh bởi `tools/story/gen_chapters.py`. Mỗi chương có **một tranh dài** làm nền map (người chơi kéo ngang liền mạch)
> và **một ảnh thẻ** ở màn chọn chương. Ảnh thật lưu ở `assets/story/chapters/` đúng tên, game tự thay placeholder.
> Ảnh AI phải ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1 trước khi commit.

## Cách làm tranh map dài

ChatGPT không tạo được ảnh rất dài một lần: tạo **nhiều ảnh ngang 1536×1024 nối tiếp** (mỗi ảnh nói rõ "continues
seamlessly from the previous image, same horizon line and lighting"), rồi ghép trong Photoshop thành một dải, co về chiều
cao 1080 px và đúng chiều rộng ghi dưới đây. Làm mờ nhẹ (Gaussian ~6–12 px) để nút ải nổi lên trên nền.

Phong cách chung: *anime 2D background painting, soft painterly, wide panoramic side view, horizon at about 60% height,
no characters, no text, slightly desaturated so UI on top stays readable; the Eclipsed Sun (pale orange sun with a dark
bite missing from one side) appears in the sky.*

## Chương 1 — Thung Lũng Tro Tàn (10 ải, 1 phần)

- **Tranh map:** `assets/story/chapters/map_ch01.png` — **3240 × 1080 px** (placeholder `placeholder_map_ch01.png`).
  Ghép khoảng 3 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch01.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, a grey ash-covered valley with a dirt road winding toward a cliff carved with a gigantic dark furnace (the Mother Hearth), dead trees, ash falling, a small village at the valley mouth. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, a grey ash-covered valley with a dirt road winding toward a cliff carved with a gigantic dark furnace (the Mother Hearth), dead trees, ash falling, a small village at the valley mouth, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```

## Chương 2 — Xưởng Đá Ngủ (12 ải, 1 phần)

- **Tranh map:** `assets/story/chapters/map_ch02.png` — **3800 × 1080 px** (placeholder `placeholder_map_ch02.png`).
  Ghép khoảng 3 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch02.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, high stone plateau with ancient guardian workshops carved into rock, giant dormant stone golem statues, cranes and forges, misty. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, high stone plateau with ancient guardian workshops carved into rock, giant dormant stone golem statues, cranes and forges, misty, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```

## Chương 3 — Thành Tháp Sét Câm (15 ải, 1 phần)

- **Tranh map:** `assets/story/chapters/map_ch03.png` — **4640 × 1080 px** (placeholder `placeholder_map_ch03.png`).
  Ghép khoảng 4 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch03.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, a city of tall lightning-rod towers under a dark storm-less sky, power lines gone dead, empty streets, unlit windows. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, a city of tall lightning-rod towers under a dark storm-less sky, power lines gone dead, empty streets, unlit windows, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```

## Chương 4 — Thánh Đường Ngọn Đèn Cuối (20 ải, 2 phần)

- **Tranh map:** `assets/story/chapters/map_ch04.png` — **6400 × 1080 px** (placeholder `placeholder_map_ch04.png`).
  Ghép khoảng 5 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch04.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, a white marble sanctuary on a hill holding one great lamp of light, pilgrims' road, warm glow against a dim sky. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, a white marble sanctuary on a hill holding one great lamp of light, pilgrims' road, warm glow against a dim sky, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```

## Chương 5 — Rừng Không Bóng (24 ải, 2 phần)

- **Tranh map:** `assets/story/chapters/map_ch05.png` — **7520 × 1080 px** (placeholder `placeholder_map_ch05.png`).
  Ghép khoảng 6 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch05.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, a deep forest where nothing casts a shadow, pale flat light, eerie silver trees, ancient pillar ruins half buried. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, a deep forest where nothing casts a shadow, pale flat light, eerie silver trees, ancient pillar ruins half buried, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```

## Chương 6 — Đỉnh Gió Lặng (26 ải, 2 phần)

- **Tranh map:** `assets/story/chapters/map_ch06.png` — **8080 × 1080 px** (placeholder `placeholder_map_ch06.png`).
  Ghép khoảng 6 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch06.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, a towering wind mountain with dead still clouds, rope bridges, wind shrines, a summit with a broken ring-shaped pillar. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, a towering wind mountain with dead still clouds, rope bridges, wind shrines, a summit with a broken ring-shaped pillar, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```

## Chương 7 — Nhật Thực (30 ải, 2 phần)

- **Tranh map:** `assets/story/chapters/map_ch07.png` — **9200 × 1080 px** (placeholder `placeholder_map_ch07.png`).
  Ghép khoảng 7 ảnh 1536×1024 nối tiếp.
- **Thẻ chương:** `assets/story/chapters/card_ch07.png` — **380 × 600 px** (dọc), tạo bằng ChatGPT ở 1024×1536 rồi cắt.

```text
Map (each segment): Anime 2D background painting, panoramic side view, inside the eclipse: a vast dark sky with the bitten sun overhead, floating fragments of the seventh pillar, a bright ring of light. Horizon at ~60% height, no characters, no text.
The Eclipsed Sun (pale orange sun with a dark bite missing from one side) in the sky. Continues seamlessly from the
previous segment, same horizon line and lighting.
```

```text
Card: Anime 2D key art, vertical, inside the eclipse: a vast dark sky with the bitten sun overhead, floating fragments of the seventh pillar, a bright ring of light, seen from a dramatic angle, the Eclipsed Sun above; leave the bottom 25% calmer
(the game draws the title there). No text, no logo.
```
