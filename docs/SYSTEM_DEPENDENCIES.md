# Phụ thuộc hệ thống và luồng sự kiện

> Trạng thái: **bản thiết kế (Milestone 0)**. Cập nhật khi hiện thực hóa.

## 1. Đồ thị phụ thuộc (A → B nghĩa là A dùng B)

```
UI ───────────────► EventBus, read-only state của Gameplay
VFX / Audio ──────► EventBus
Player controller ► InputRouter, StateMachine, SkillRunner, CharacterRuntime
SkillRunner ──────► SkillDef, ResourceComponent, CooldownController, Hitbox, EventBus
Hitbox/Hurtbox ───► DamageCalculator, StatusController, EventBus
DamageCalculator ─► CombatRules, RandomSource            (không phụ thuộc node)
StatusController ─► StatusDef, EventBus
PartyManager ─────► CharacterRuntime, LinkTracker, ReactionResolver, SkillRunner
LinkTracker ──────► LinkRules, EventBus (nghe)
ReactionResolver ─► ReactionDef, DamageCalculator, StatusController
Enemy / Boss ─────► EnemyDef, StateMachine, Hurtbox, Hitbox, EventBus
Stage ────────────► EnemySpawner, Checkpoint, CameraBounds, EventBus
Progression ──────► CharacterDef, SaveService
GachaService ─────► BannerDef, RandomSource, SaveService
SaveService ──────► (không phụ thuộc gameplay)
Mọi hệ thống ─────► GameConfig (chỉ đọc)
```

Quy tắc: Data và Core không phụ thuộc Gameplay; Gameplay không phụ thuộc UI.

## 2. Thứ tự xây dựng (theo milestone)

```
M1 Core (GameConfig, EventBus, SceneRouter, InputRouter)
 └─ M2 Player (StateMachine, controller, AnimationSet từ manifest)
     └─ M3 Combat (Hitbox/Hurtbox, DamageCalculator, Resource, Cooldown, Status, Enemy cơ bản)
         └─ M4 Party (PartyManager, LinkTracker, ReactionResolver, HUD dự bị)
             └─ M5 RPG (Progression, Inventory, SaveService đầy đủ, Gacha)
                 └─ M6 World (Stage, Boss)
                     └─ M7 UI/Polish  └─ M8 QA
```

## 3. Danh mục signal (EventBus) — bản nháp

| Signal | Tham số | Phát bởi | Nghe bởi |
|---|---|---|---|
| `hit_landed` | attacker_id, target, hit_info | Hitbox | HitFeedback, ResourceComponent (nạp EN/UG), LinkTracker |
| `damage_dealt` | target, amount, element, is_crit | DamageCalculator caller | Số sát thương, combo counter |
| `status_applied` | target, status_id, source_id | StatusController | LinkTracker (Kael), VFX |
| `enemy_stunned` | enemy, source_id | Enemy | LinkTracker (Aether) |
| `enemy_defeated` | enemy, source_id | Enemy | LinkTracker (Noctis), Rewards, Stage |
| `perfect_dodge` | character_id | Dodge state | LinkTracker (Lyra), Slow-time |
| `skill_used` | character_id, skill_key | SkillRunner | LinkTracker (Terra: weapon/ultimate), HUD |
| `hp_changed` | character_id, hp, max_hp | ResourceComponent | HUD, LinkTracker (Seraphine) |
| `resource_changed` | character_id, en, ug | ResourceComponent | HUD |
| `cooldown_changed` | character_id, key, remaining, total | CooldownController | HUD |
| `link_window_opened` / `_closed` | character_id, expires_at | LinkTracker | HUD (vòng sáng) |
| `character_switched` | from_id, to_id, mode (normal/linked/default) | PartyManager | HUD, Camera, Audio |
| `reaction_triggered` | reaction_id, position | ReactionResolver | VFX, hit-stop 60 ms, tên phản ứng 0.8s |
| `boss_phase_changed` | boss, phase | Boss | HUD, Music |
| `stage_completed` | stage_id, result | Stage | SceneRouter, Rewards |
| `save_completed` / `save_failed` | slot, error | SaveService | UI |

## 4. Luồng dữ liệu chính

**Đòn đánh:**
`Input → Player state → SkillRunner → AnimationPlayer bật Hitbox → Hurtbox → DamageCalculator → Health/Status → EventBus → UI/VFX/Audio`

**Chuyển nhân vật:** xem ARCHITECTURE mục 6.

**Chiêu mộ:**
`Yêu cầu → kiểm tra tiền tệ → BannerDef → quay (pity/rate-up/bảo hiểm) → cấp nhân vật/vật phẩm → lịch sử → Save`
