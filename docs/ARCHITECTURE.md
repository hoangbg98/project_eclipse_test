# Kiến trúc hệ thống

> Trạng thái: **bản thiết kế (Milestone 0)**. Chưa có code. Mỗi mục sẽ được
> cập nhật khi được hiện thực hóa và kiểm chứng. Quy tắc gốc: README mục 6.

## 1. Nguyên tắc

1. Logic gameplay tách khỏi UI. UI chỉ đọc state và nghe signal.
2. Scene nhỏ, component dùng lại được. Không có "manager khổng lồ".
3. Mọi giá trị cân bằng nằm trong data (`.tres`), không viết cứng trong script.
4. Giao tiếp chéo hệ thống qua signal (`EventBus`) hoặc tham chiếu một chiều;
   không phụ thuộc vòng.
5. Dữ liệu tĩnh (định nghĩa) ≠ dữ liệu người chơi (save) ≠ node runtime.
6. Code riêng nền tảng chỉ nằm ở input, hiển thị, tích hợp nền tảng.

## 2. Các lớp

```
┌──────────────────────── Presentation ────────────────────────┐
│ UI scenes (HUD, menus) · VFX · Audio · Camera                │
└───────────────▲──────────────────────────────▲───────────────┘
                │ signals (read-only)          │
┌───────────────┴────────── Gameplay ──────────┴───────────────┐
│ Player controller · Combat · Party · Enemies/Boss · World    │
└───────────────▲──────────────────────────────▲───────────────┘
                │ reads definitions            │ reads/writes profile
┌───────────────┴────── Data ──────┐  ┌────────┴──── Persistence ─┐
│ Resources (.tres) in data/       │  │ SaveService (JSON, ver.)  │
└──────────────────────────────────┘  └───────────────────────────┘
┌─────────────────────────── Core ─────────────────────────────┐
│ Autoloads: GameConfig · EventBus · SceneRouter · InputRouter │
│            SaveService · AudioRouter                          │
└──────────────────────────────────────────────────────────────┘
```

## 3. Autoload (singleton toàn cục)

> *Autoload* là script/scene Godot tự nạp khi game chạy và truy cập được từ mọi nơi.
> Chỉ dùng cho dịch vụ điều phối, không chứa luật gameplay.

| Autoload | Trách nhiệm | Không được làm |
|---|---|---|
| `GameConfig` | Nạp `combat_rules.tres`, `link_rules.tres`, cờ config (stamina, weight limit, revive) | Giữ state của trận |
| `EventBus` | Khai báo signal toàn cục (xem SYSTEM_DEPENDENCIES) | Chứa logic |
| `SceneRouter` | Chuyển scene, màn hình loading, chuyển cảnh 150–250 ms, nút Back | Biết nội dung scene |
| `InputRouter` | Gộp bàn phím/chuột/tay cầm/cảm ứng thành *action* chung, bộ đệm input 100–150 ms | Biết nhân vật nào đang chơi |
| `SaveService` | Đọc/ghi save có version, migration, backup, checksum | Giữ định nghĩa tĩnh |
| `TutorialGuide` | Hướng dẫn người mới: làm tối màn, chừa ô sáng quanh nút cần bấm, chặn input khác (bước do `TutorialFlow` suy từ save) | Chứa luật gameplay |
| `AudioRouter` | Phát SFX/nhạc theo bus, nghe EventBus | Quyết định gameplay |

## 4. Dữ liệu (Godot Resource)

> *Resource* là object dữ liệu của Godot, lưu thành file `.tres`, chỉnh được trong editor.

| Resource | File | Nguồn |
|---|---|---|
| `CombatRules` | `data/config/combat_rules.tres` | CHARACTER_SKILLS mục 0 + quyết định Q1–Q4 |
| `LinkRules` | `data/config/link_rules.tres` | mục 8.2, 8.3 |
| `CharacterDef` | `data/characters/{id}.tres` | README 4, mục 1–6 |
| `SkillDef` (+ lớp con theo loại) | `data/skills/{id}/{key}.tres` | mục 1–6, 8.5–8.10 |
| `ReactionDef` | `data/reactions/{a}_{b}.tres` | mục 8.4 (15 file, khóa theo cặp đã sắp xếp) |
| `StatusDef` | `data/statuses/{status}.tres` | mục 0 + Q4 |
| `EnemyDef`, `BossDef` | `data/enemies/` | Claude đặt giá trị placeholder |
| `ItemDef`, `EquipmentDef` | `data/items/`, `data/equipment/` | sau |
| `BannerDef` | `data/banners/` | **chờ owner cung cấp tỉ lệ** |
| `AnimationSet` | build từ `frames_manifest.json` | README 17.4 |

Khóa phản ứng: hai nguyên tố sắp xếp theo thứ tự cố định
`fire, wind, lightning, light, dark, earth` → ví dụ `fire_lightning`.

## 5. Combat

| Thành phần | Mô tả |
|---|---|
| `Hitbox` / `Hurtbox` (Area2D) | Hitbox bật/tắt bằng **track AnimationPlayer** theo frame (khởi động / hiệu lực / hồi phục). Mỗi lần kích hoạt có `hit_id`; một Hurtbox chỉ nhận một lần mỗi `hit_id`. |
| `DamageCalculator` | Hàm thuần (không node), test được. Công thức Q1, chí mạng Q2. |
| `StatsComponent` | Chỉ số gốc + modifier (cộng, nhân), DEF giảm theo Q3. |
| `ResourceComponent` | HP, EN, UG, lượt né; nạp theo CombatRules. |
| `CooldownController` | CD, CDR (trần 40%), cơ chế rút CD riêng có trần mỗi chu kỳ. |
| `StatusController` | Áp/làm mới/hết hạn trạng thái, tick, kháng Choáng. |
| `SkillRunner` | Chạy `SkillDef`: kiểm tra tài nguyên, phát animation, phát signal. |
| `HitFeedback` | Hit-stop, flash, rung camera, số sát thương (nghe signal). |

### Công thức sát thương (mặc định Q1–Q3, chỉnh trong config)

```
raw      = ATK × skill_percent × (1 + 0.06 × (skill_level − 1))
bonus    = 1 + tổng(% tăng sát thương) + tổng(% nhận thêm của mục tiêu, vd Phán quyết)
def_eff  = DEF × (1 − min(tổng % giảm DEF, def_reduction_cap = 0.40))
mitig    = K / (K + def_eff)                 # K = 500
crit     = (roll < crit_rate) ? (1 + crit_dmg) : 1     # mặc định 5% / +50%
taken    = 1 − min(tổng % giảm sát thương nhận, cap)   # cap đặt trong config
damage   = round(raw × bonus × mitig × crit × taken)
```

Ngẫu nhiên đi qua một `RandomSource` có seed để test tái lập được.

## 6. Party và chuyển nhân vật

```
Switch input → PartyManager → kiểm tra (còn sống, chờ chung 1.0s, không bị khóa
bởi tuyệt kỹ chuỗi đòn) → LinkTracker: SI-CD đã hồi? cửa sổ 6.0s còn?
→ đổi slot trên sân → SkillRunner chạy switch_in (Thường | Liên kết | mặc định)
→ ReactionResolver (chỉ Liên kết, ICD chung 5.0s) → EventBus → HUD
```

| Thành phần | Trách nhiệm |
|---|---|
| `PartyManager` | 3 slot, slot trên sân, khóa chuyển, tốc độ nạp EN/UG cho dự bị (EN +1/s, UG 30%). |
| `CharacterRuntime` | State riêng của mỗi nhân vật (HP, EN, UG, CD, buff, tầng Nhiệt…), vẫn chạy khi ở dự bị. |
| `LinkTracker` | Nghe sự kiện mở cửa sổ (Choáng, né hoàn hảo, áp trạng thái, hạ gục, HP thấp, dùng kỹ năng vũ khí/tuyệt kỹ), lưu mốc thời gian cho từng nhân vật dự bị. |
| `ReactionResolver` | Tra `ReactionDef` theo cặp, áp ICD, khống chế lên boss ×0.5. |

Nhân vật dự bị **không có node trên sân** và không có AI. Hiệu ứng đã tạo (vùng,
bão, trạng thái trên địch) là node độc lập, tồn tại sau khi chủ rời sân.

## 7. Nhân vật và animation

- Một scene nhân vật chung `scenes/player/player_character.tscn`; dữ liệu khác
  nhau đến từ `CharacterDef`.
- State machine người chơi: `Idle, Run, JumpUp, Fall, Land, Attack, Hold,
  Air, Landing, Dodge, Skill, Weapon, Ultimate, SwitchIn, SwitchOut, Hurt,
  Knockback, Down`.
- `SpriteFrames` được tạo từ `frames_manifest.json` (số frame, fps, loop).
  Animation có `frames: 0` dùng placeholder trong `assets/placeholders/`.
- Pivot đáy giữa (192, 336), vẽ hướng phải, quay trái bằng `flip_h`.
- Thời gian pha đòn lấy từ `SkillDef`; track AnimationPlayer cho hitbox được
  sinh từ data, nên đổi số frame không cần sửa code.

## 8. Save

- JSON trong `user://saves/`, có `schema_version`, checksum, file backup.
- Chỉ lưu dữ liệu người chơi (ID sở hữu, cấp, trang bị, tiền tệ, pity, lịch sử
  chiêu mộ, tiến độ màn, cài đặt). Không lưu định nghĩa tĩnh.
- Chuỗi migration `v1 → v2 → …`; dữ liệu hỏng hoặc thiếu → dùng backup hoặc
  mặc định, không crash.

## 9. Gacha

`BannerDef` chứa tỉ lệ, pity, rate-up, bảo hiểm. Cùng một config sinh ra bảng
tỉ lệ hiển thị và logic quay. `GachaService` không biết UI. Test dùng
`RandomSource` có seed. **Chưa có số liệu — chờ owner (blocker Milestone 5).**

## 10. UI

- Một `Theme` chung + file token (`ui/theme_tokens.tres`) để owner đổi giao
  diện mà không sửa code.
- Mọi chữ qua `tr()`; file dịch trong `localization/`.
- Chi tiết màn hình: `UI_UX_SPEC.md`.

## 11. Input

Action chung: `move_x`, `jump`, `attack` (nhấn/giữ), `dodge`, `skill`,
`weapon`, `ultimate`, `switch_1`, `switch_2`, `pause`, `ui_back`.
PC: bàn phím, chuột, tay cầm qua InputMap. Android: joystick ảo + nút
(multitouch độc lập), icon dự bị chạm để chuyển.

## 12. Quyết định mở / chờ

| Mục | Trạng thái |
|---|---|
| Tỉ lệ gacha | Chờ owner (trước M5) |
| GdUnit4 | Chờ owner duyệt plugin (M1) |
| Stretch/aspect cuối cùng | Quyết ở M1 |
| Ngân sách bộ nhớ Android | Đo trên máy thật ở M2 |
