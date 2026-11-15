# Prompt Gemini: ảnh nền màn Nhân vật (owner 2026-11-15)

Ảnh nền cho các màn chọn nhân vật, tăng cấp, vũ khí, chi tiết vũ khí, vết thánh, kĩ năng. Prompt viết bằng tiếng Anh
vì Gemini tạo ảnh theo tiếng Anh ổn định hơn; mỗi mục có ghi chú tiếng Việt về bố cục.

## 1. Quy cách chung

- **Tỉ lệ 16:9**, xuất **2560 × 1440 PNG** (game thu về 1920 × 1080). Nếu Gemini trả ảnh nhỏ hơn: phóng lên bằng
  công cụ upscale rồi mới cắt về 2560 × 1440.
- Game phủ kín màn, giữ tỉ lệ, cắt mép thừa. Trên màn siêu rộng 21:9, ảnh mất khoảng **12% trên + 12% dưới**, nên
  chi tiết quan trọng đặt trong dải giữa theo chiều dọc.
- **Không có chữ, logo, nhân vật, người, vũ khí, khung UI** trong ảnh. Nhân vật, vũ khí, bảng chữ do game vẽ đè lên.
- Nền phải **tối và dịu** ở vùng có bảng chữ, để chữ trắng đọc rõ. Độ sáng trung bình khoảng 20–35%.
- Không bắt chước game, thương hiệu hay phong cách họa sĩ có thật (AGENTS.md mục 4). Không ghi tên game khác vào prompt.
- Đặt file vào `assets/ui/character/backgrounds/` đúng tên ở bảng dưới. Game tự nhận, không cần sửa code. Thiếu ảnh
  của màn nào thì màn đó dùng `bg_character_default.png`; thiếu nốt thì dùng nền màu như hiện tại. Tên file đổi được ở mục
  `"backgrounds"` trong `data/ui/character_screen_layout.json`.
- Ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1: công cụ "Gemini (Google)", prompt rút gọn, ngày tạo.

| Màn | Tên file | Bố cục trên màn 1920 × 1080 |
|---|---|---|
| Chọn nhân vật (tổng quan) | `bg_character_select.png` | Nhân vật toàn thân ở giữa (x 610–1410); dải danh sách giáp ở đáy (y 840–1040); cột trái và cột phải có chữ |
| Tăng cấp | `bg_character_level.png` | Nhân vật bên trái (x 60–940); bảng chỉ số bên phải (x 915–1890) |
| Vũ khí | `bg_character_weapon.png` | Nhân vật bên trái; ảnh vũ khí lớn bên phải (x 915–1890, y 300–820) |
| Chi tiết vũ khí | `bg_weapon_detail.png` | Bảng ảnh vũ khí bên trái (x 45–970), bảng chỉ số và kĩ năng bên phải; gần như toàn màn có bảng |
| Vết thánh | `bg_character_stigma.png` | Ảnh lưng nhân vật bên trái; 3 thẻ vết thánh dọc bên phải |
| Kĩ năng (cây kĩ năng) | `bg_character_skill.png` | Nhân vật bên trái; cây 8 nút tròn bên phải, nối nhau |
| Chi tiết kĩ năng | `bg_skill_detail.png` | Cây nhánh kĩ năng bên trái (x 250–1060); bảng mô tả bên phải (x 1105–1890) |
| Dự phòng | `bg_character_default.png` | Dùng chung khi màn nào chưa có ảnh riêng |

## 2. Đoạn phong cách dùng chung

Dán đoạn này vào cuối mọi prompt bên dưới để các ảnh đồng bộ:

```
Style: polished 2D anime game UI backdrop, painterly digital art with clean shapes, soft volumetric light, subtle
film grain. Palette: deep midnight navy and indigo base (#14161F to #2A2E3E), with restrained accents of warm amber
(#FFB347) and cool cyan (#7FD4FF). Theme "eclipse": a dark sun ringed by a thin glowing corona appears only as a
faint motif. Low contrast in the areas meant for text, gentle vignette at the edges. No characters, no people, no
weapons, no text, no letters, no logos, no watermark, no UI frames or buttons. 16:9, 2560x1440.
```

## 3. Prompt từng màn

### 3.1 Chọn nhân vật: `bg_character_select.png`

Ghi chú: nhân vật đứng giữa nên phía sau giữa cần một điểm sáng nhẹ (vầng nhật thực) làm hậu cảnh. Hai bên tối hơn để
đặt chữ. Đáy ảnh là dải danh sách giáp, nên giữ phẳng và tối.

```
A grand circular observation hall at the edge of space, seen straight on. In the center background a huge eclipse:
a black disc with a thin amber-and-cyan corona, softly blurred, acting as a halo behind where a hero will stand.
Floor of polished dark glass reflecting the corona. Left and right thirds of the image fall into calm deep-blue
shadow with faint geometric panel lines. The bottom 20% is a flat, dark, almost uniform band. Floating dust motes in
the light beam. Symmetrical, calm, heroic mood.
```

### 3.2 Tăng cấp: `bg_character_level.png`

Ghi chú: nhân vật bên trái nên đặt nguồn sáng ở trái. Nửa phải là vùng bảng số liệu, cần phẳng và tối.

```
A quiet training sanctum interior, light entering from the upper left through tall narrow windows, warm amber shafts
falling on the left side of the frame. Faint holographic rings and rising particles on the left half suggest growth
and energy. The right half is a smooth, dark indigo wall with very subtle hexagonal texture, evenly lit and low
contrast for text panels.
```

### 3.3 Vũ khí: `bg_character_weapon.png`

Ghi chú: ảnh vũ khí nằm ngang ở nửa phải (khoảng y 300–820), nên vùng này cần một mặt trưng bày phát sáng nhẹ và
không có chi tiết rối.

```
An armory vault with a dark stone and steel interior. On the right half, a horizontal display alcove with a soft
cyan glow strip and a faint amber rim light, empty, waiting for a blade to be shown floating in front of it. Left
half in gentle shadow with distant racks reduced to blurred silhouettes (no visible weapons). Clean, premium,
museum-like lighting.
```

### 3.4 Chi tiết vũ khí: `bg_weapon_detail.png`

Ghi chú: gần như toàn màn bị bảng che, nên ảnh chỉ cần hoa văn mờ và ánh sáng loang. Không đặt vật thể rõ nét.

```
An abstract forge-themed backdrop: very dark indigo field with faint glowing ember particles drifting upward, a
large subtle eclipse ring in the upper left at 15% opacity, thin diagonal light streaks in amber and cyan. Mostly
flat and low detail, like a background behind information panels. Soft focus everywhere.
```

### 3.5 Vết thánh: `bg_character_stigma.png`

Ghi chú: bên phải là 3 thẻ dọc nên hợp nền có ba cột sáng hoặc ba ô kính màu mờ. Bên trái là lưng nhân vật.

```
A sacred chamber with three tall stained-glass-like light columns on the right half, abstract patterns only (no
figures), glowing faintly in indigo, violet and amber. Left half is a calm dim space with a soft spotlight from
above. Mystical, reverent mood, symmetrical columns, very low contrast behind the columns' centers.
```

### 3.6 Kĩ năng (cây kĩ năng): `bg_character_skill.png`

Ghi chú: bên phải là 8 nút tròn nối nhau, nên nền chỉ cần mạng lưới mờ hoặc chòm sao, không có hình tròn rõ (dễ nhầm
với nút bấm).

```
A cosmic star-chart backdrop: deep navy space with a faint constellation network of thin cyan lines and tiny dim
stars spread across the right half, very subtle so circles drawn on top stay readable. Left half has a soft nebula
glow in muted amber where a character will stand. Calm, intelligent, arcane-technology mood.
```

### 3.7 Chi tiết kĩ năng: `bg_skill_detail.png`

```
A close-up of an arcane circuit diagram fading into darkness: thin branching cyan light paths spreading from the
left-center toward the edges, like a skill tree drawn in light, very faint. The right 45% of the image is a smooth
dark indigo gradient with almost no detail, reserved for a text panel. Minimal, elegant.
```

### 3.8 Dự phòng: `bg_character_default.png`

```
A minimal dark backdrop: smooth midnight-indigo gradient, a faint eclipse ring (black disc with thin amber-cyan
corona) at the top center at 20% opacity, scattered tiny glowing particles, soft vignette. Almost no detail.
```

## 4. Khi ảnh chưa ưng

- Ảnh quá sáng hoặc rối: thêm `darker overall, fewer details, more empty space on the right`.
- Gemini tự vẽ người hoặc vũ khí: thêm `strictly empty scene, absolutely no figures, no swords, no objects in hands`.
- Gemini tự vẽ chữ: thêm `no typography of any kind`.
- Cần đồng bộ: tạo ảnh 3.8 trước, rồi đưa ảnh đó vào Gemini làm ảnh tham chiếu phong cách cho các ảnh còn lại.
