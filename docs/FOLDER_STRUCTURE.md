# Cấu trúc thư mục

> Theo README mục 7. Cột "Hiện có" phản ánh workspace ngày 2026-11-11.

```text
PROJECT_ECLIPSE/
├── project.godot                 (M1)
├── README.md                     ✔ đặc tả dự án
├── .gitignore / .gitattributes   ✔
├── addons/                       (M1, gdUnit4 nếu được duyệt; mỗi plugin ghi vào ASSET_LICENSES)
├── assets/
│   ├── characters/{id}/          ✔ 6 nhân vật
│   │   ├── frames/{animation}/   ✔ thư mục rỗng (.gitkeep)
│   │   ├── portrait/             ✔ rỗng
│   │   ├── vfx/                  ✔ rỗng
│   │   └── frames_manifest.json  ✔ frames = 0
│   ├── placeholders/             ✔ rỗng (M1–M2)
│   ├── enemies/ bosses/ environments/ ui/ vfx/ audio/ fonts/   (khi cần)
├── scenes/
│   ├── main/        boot, title, hub, loading
│   ├── player/      player_character.tscn
│   ├── characters/  hiệu ứng riêng nhân vật (vùng, đạn…)
│   ├── enemies/ bosses/ stages/
│   └── ui/          hud/, menus/, widgets/
├── scripts/
│   ├── core/        autoload: game_config, event_bus, scene_router, save_service…
│   ├── input/       input_router, touch_controls
│   ├── player/      controller, states/
│   ├── characters/  character_runtime, animation_set_builder
│   ├── combat/      hitbox, hurtbox, damage_calculator, status_controller…
│   ├── party/       party_manager, link_tracker, reaction_resolver
│   ├── enemies/ bosses/ world/ progression/ inventory/ equipment/
│   ├── gacha/ quests/ save/ audio/ ui/
├── data/
│   ├── config/      combat_rules.tres, link_rules.tres
│   ├── characters/  {id}.tres
│   ├── skills/{id}/ {key}.tres  (normal, dodge, passive, hold, air, landing, skill, weapon, ultimate, switch_in)
│   ├── reactions/   {a}_{b}.tres (15)
│   ├── statuses/ enemies/ items/ equipment/ banners/ stages/
├── resources/       theme, SpriteFrames sinh ra
├── shaders/
├── localization/    file dịch (.csv/.po)
├── tests/           GdUnit4: unit/, integration/
└── docs/
    ├── design/CHARACTER_SKILLS.md   ✔ nguồn sự thật về kỹ năng (owner)
    ├── reference/                   ✔ 3 ảnh, chỉ để tham khảo, LOẠI KHỎI EXPORT
    └── *.md                         ✔ tài liệu dự án (README mục 11)
```

## Quy ước đặt tên

| Loại | Quy ước | Ví dụ |
|---|---|---|
| Script, scene, resource | `snake_case` | `party_manager.gd`, `combat_rules.tres` |
| Class GDScript (`class_name`) | `PascalCase` | `PartyManager` |
| Signal, hàm, biến | `snake_case` | `character_switched` |
| Hằng số | `UPPER_SNAKE` | `MAX_PARTY_SIZE` |
| Nhân vật | Data ID trung tính | `char_fire_01` |
| Kỹ năng | `{id}.{key}` | `char_fire_01.switch_in` |
| Frame | `{id}_{animation}_{NNN}.png` từ `000` | `char_fire_01_attack_1_000.png` |
| Placeholder | tiền tố `placeholder_` và liệt kê trong ASSET_LICENSES | `placeholder_enemy_slime.png` |
| Khóa dịch | `UPPER_SNAKE` theo màn hình | `HUD_PAUSE`, `TITLE_NEW_GAME` |

## Loại khỏi export

`docs/`, `tests/`, `addons/gdUnit4/` và mọi file `placeholder_*` không được
đưa vào bản phát hành (cấu hình bộ lọc export ở M1).
