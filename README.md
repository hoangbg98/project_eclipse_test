# PROJECT ECLIPSE

## README --- Technical Project Specification & Implementation Guide

> **Project type:** Anime-style 2D side-scrolling Action RPG\
> **Target platforms:** Windows PC and Android\
> **Engine:** Godot 4.6.3 (locked --- see Section 2)\
> **Primary language:** GDScript\
> **Development mode:** Offline-first, single-player\
> **Document status:** Baseline specification, Revision 4 --- use this
> as the project's implementation reference. Owner decisions are
> incorporated in Section 2 and recorded in the Revision History at the
> end of this document.

------------------------------------------------------------------------

## 1. Project Overview

PROJECT ECLIPSE is an anime-style 2D side-scrolling action RPG combining
platforming, real-time combat, character collection, party switching,
and RPG progression.

The player owns a team of three characters, but **only one character is on
the field at a time**. The other two are reserve characters, shown as
icons in the top-right corner of the HUD; they do not act while in
reserve. Switching brings a reserve character in with a **switch-in
skill**. When the on-field character has just met that reserve
character's link condition (for example breaking an enemy's stagger or a
perfect dodge), the icon glows and the switch-in triggers an **elemental
reaction**. There are no switch-out skills.

The first release is designed for offline single-player play. Character
recruitment uses in-game resources and simulated gacha mechanics;
real-money payments and online services are outside the initial scope.

### Core design pillars

1.  **Responsive action combat:** readable hit feedback, responsive
    controls, clear skill states and meaningful character switching.
2.  **Three-character team play:** distinct combat roles, linked
    switch-ins, elemental reactions and tactical switching.
3.  **Anime presentation:** expressive character sprites, animation,
    layered environments and polished visual effects.
4.  **RPG progression:** character growth, equipment, inventory, quests
    and rewards.
5.  **Offline-first architecture:** local data, local saves and no
    mandatory network dependency.
6.  **Cross-platform delivery:** shared gameplay systems for Windows and
    Android.

------------------------------------------------------------------------

## 2. Locked Technical Decisions

  Area                 Decision
  -------------------- ----------------------------------------------------
  Visual style         Anime 2D; not pixel art
  Camera/gameplay      2D side-scrolling action RPG with platforming
  Engine               Godot 4.6.3, locked for the whole project (no engine upgrade without owner approval)
  Language             GDScript
  Platforms            Windows PC + Android
  Player party         Three characters (one on the field, two in reserve)
  Active character     One player-controlled character
  Reserve characters   Two inactive characters shown as HUD icons; no AI, no actions
  Switching            Real-time switching with a switch-in skill (no switch-out skill)
  Elemental reactions  Triggered only by a Linked switch-in (docs/design/CHARACTER_SKILLS.md, Section 8)
  Game mode            Offline, single-player first
  Recruitment          Offline gacha using non-monetary in-game resources
  Architecture         Modular, component-based and data-driven
  Save system          Versioned local save data
  UI                   Responsive landscape layout
  PC input             Keyboard, mouse and gamepad
  Android input        Multitouch virtual joystick and action buttons
  Animation            Frame-by-frame 2D sprites (see Section 2.2)
  Hitboxes             Driven by AnimationPlayer tracks, not by code timers
  Test framework       GdUnit4 (plugin; version must match Godot 4.6.3 --- verify at Milestone 1)
  Gacha rates          Fixed values in config; published; never altered randomly at runtime
  Commercial intent    Yes --- see Section 2.1
  Localization         All player-visible text through tr() from the first UI screen

**Existing-project rule:** Before creating or changing the project,
inspect the current workspace. If it already uses a functioning engine
or architecture, document the current state and propose a migration only
when technically justified. Do not replace or delete existing work
without explicit approval.

### 2.1 Commercial, licensing and asset rules

The project is intended for commercial release.

-   **Asset ownership.** The owner supplies or draws all art, UI, VFX,
    music, SFX and fonts, and has confirmed commercial licenses for every
    external font, music and SFX file in use.
-   **No unrecorded third-party content.** Claude must not add any
    third-party asset, font, audio, code or plugin without explaining why
    and recording its source and license in `docs/ASSET_LICENSES.md`.
-   **Placeholders.** Until final assets arrive, Claude may use
    placeholders (colored shapes, generated tones). Every placeholder is
    named `placeholder_*` and listed so it can be replaced. Placeholders
    are never shipped.
-   **Names.** Character display names are working names. Code and data
    reference characters by neutral IDs (for example `char_fire_01`),
    never by display name, so renaming is a data-only change. Two roster
    names (Aether, Noctis) match well-known third-party characters and
    must be replaced with original names before any public release.
-   **Gacha.** Rates are fixed in `data/banners/`. The rates shown to the
    player are generated from the same config the roll logic uses. No
    hidden, adaptive or randomly changing odds; the only modifiers
    allowed are the documented pity, rate-up and guarantee rules. The
    first release uses non-monetary in-game resources only. If real-money
    currency is ever added, a separate review of store policies and local
    law (odds disclosure, age rating, regional restrictions) must happen
    before implementation.
-   **Open-source notices.** Godot (MIT) and every plugin license notice
    must be included in an in-game credits/licenses screen.
-   **Release order.** Development happens on PC, with an Android build
    tested from Milestone 1. A Windows release may precede Android; the
    gameplay code is shared either way.

### 2.2 Sprite and animation technical specification

Animation is frame-by-frame. The owner supplies the frames; the number of
frames per animation differs per character and is stored in character
data, never hardcoded.

**Display basis:** landscape 1920x1080 logical viewport, scaled to the
device (final stretch/aspect settings decided in Milestone 1).

  Asset type         Frame canvas   Notes
  ------------------ -------------- -------------------------------------
  Playable char      384x384 px     Standing height about 256 px
  Regular enemy      384x384 px     256x256 px allowed for small enemies
  Boss               768x768 px     Same layout rules, scaled 2x
  Portraits, UI      Owner-defined  Not covered by this spec
  VFX                Owner-defined  Separate layers, not baked into frames

Rules:

-   Every frame of one character uses the identical canvas size.
-   Pivot is bottom-center. The feet baseline is fixed at y = 336 px and
    the horizontal center at x = 192 px in all animations, so no
    per-frame offset code is needed.
-   Frames are drawn facing right; facing left uses `flip_h`.
-   PNG with transparency. File naming:
    `{id}_{animation}_{NNN}.png`, for example
    `char_fire_01_attack_1_003.png`.
-   Standard animation names: `idle`, `run`, `jump_up`, `fall`, `land`,
    `attack_1` to `attack_n` (normal attack hits), `dodge`,
    `hold_charge` (loop), `hold_release`, `air_1` to `air_n`,
    `landing_attack`, `skill_1` (normal skill), `skill_2` (weapon skill),
    `ultimate`, `switch_in` (the switch-in skill; replaces the default
    entry animation), `switch_out` (3-frame exit, no skill), `hurt`,
    `knockback`, `down`. Characters may omit or add animations. The
    folder layout, the mapping to skill keys and the per-character
    `frames_manifest.json` are defined in Section 17.4.
-   Frame timing (FPS) is stored per animation in data. Suggested start:
    12 fps for loops, 12 to 24 fps for attacks.
-   Hitboxes and hurtboxes are enabled by AnimationPlayer tracks keyed to
    animation frames (startup, active, recovery). They are not baked into
    the sprite images.
-   Weapon swings or effects that would exceed the canvas go in the VFX
    layer instead of enlarging the character canvas.
-   **Android memory (planning estimate, to be confirmed on a real
    device in Milestone 2):** import textures with VRAM compression
    (ASTC or ETC2, which must be enabled in the project's import settings
    for Android) and pack frames into atlases. At 384x384 with ASTC 4x4
    (about 1 byte per pixel), 150 frames is roughly 22 MB per character.
    If measurements exceed budget, reduce frame count, use ASTC 6x6, or
    lower the canvas size.

### 2.3 Scope of the first commercial build

The first commercial milestone is the vertical slice in Section 9.
These features remain in the specification but do not gate the first
build and are deferred until the slice is stable:

-   Quests and quest interface.
-   Equipment enhancement.
-   Input rebinding.
-   Translations other than the source language (text must still go
    through `tr()` from the start).
-   Characters beyond the three used in the slice (the data model must
    still support the full roster).

### 2.4 Reference materials

UI, UX and gameplay direction is defined in Section 15, and the
autonomy rules for day-to-day decisions are in Section 16. Read both
before designing any screen or gameplay feel. Reference screenshots
are stored in `docs/reference/` and are for study only (see 15.1).
Character skills, switch-in skills and the elemental reaction table are
defined in `docs/design/CHARACTER_SKILLS.md`; Section 17 explains how
that file, the frame folders and the manifests link together.

------------------------------------------------------------------------

## 3. Gameplay and Combat Design

### 3.1 Party system

-   The party contains exactly three equipped characters in the initial
    design.
-   **Only one character is on the field.** It alone receives movement
    and combat input.
-   The other two are reserve characters. They have no AI, are not on the
    field and do not act.
-   Reserve characters appear as two icons in the top-right corner of the
    HUD: portrait, small HP bar, switch-cooldown ring and a link glow
    ring (Section 17.5).
-   Switching must be responsive and must not corrupt the current combat
    state.
-   Each character keeps their own HP, energy (EN), ultimate gauge (UG),
    cooldowns and statuses. Timers keep running while in reserve.
    Reserve characters regain EN at half rate and receive 30% of the UG
    the active character gains.
-   Define clear behavior for switching while airborne, attacking,
    stunned, knocked back or using a skill. Switching is locked during
    chain-type ultimates and for a downed character.

### 3.2 Combat framework

Implement combat as reusable systems rather than character-specific
hardcoded logic.

Required systems:

-   Hitbox and hurtbox handling.
-   Damage calculation and damage types.
-   Attack startup, active and recovery phases.
-   Hit reaction, knockback, stagger and invulnerability windows where
    applicable.
-   Skill execution, cooldown and energy consumption.
-   Buffs, debuffs and status effects.
-   Elemental damage and elemental reactions (Section 3.3).
-   Target detection and combat feedback.
-   Combat events/signals for UI, audio and VFX, including the events
    that open link windows (stagger break, perfect dodge, status applied,
    kill, low HP, weapon skill or ultimate used).

### 3.3 Character switching and switch-in skills

Full rules and numbers are in `docs/design/CHARACTER_SKILLS.md`,
Section 8. The party system must support:

-   Tapping a reserve icon to switch, with a global 1.0 s wait between
    switches.
-   A per-character switch-in skill with its own cooldown (SI-CD) that
    keeps counting down while in reserve.
-   Two levels: **Normal**, and **Linked** when the icon's glow ring is
    lit.
-   **Link conditions:** an event performed by the on-field character
    within the last 6.0 s (for example staggering an enemy, a perfect
    dodge, applying an elemental status, a kill, low HP, or using a
    weapon skill or ultimate). The ring shows only when the condition was
    met and the SI-CD is ready.
-   **Elemental reactions:** a Linked switch-in produces the reaction of
    the pair (leaving element, entering element). There are 15 pairs and
    a shared 5.0 s ICD.
-   No switch-out skill, only a 3-frame exit animation.
-   Per-character state preservation, cooldown and resource validation,
    and safe handling when the requested character is unavailable or
    incapacitated.

### 3.4 Reserve characters (no AI)

-   Reserve characters never act on their own. The earlier support-AI
    design is removed from scope.
-   Effects a character already created (zones, storms, statuses on
    enemies, shields) keep running after that character leaves the field.
-   Buffs and zones meant for allies apply to the on-field character
    while it stands in the zone, and to a character who enters while the
    effect is still active (remaining duration).
-   Heals meant for the whole team also heal reserve characters.

### 3.5 Platforming and world interaction

The player controller must support:

-   Horizontal movement.
-   Jumping and variable jump behavior if appropriate.
-   Falling and landing.
-   Ground detection.
-   Ledge and platform collision.
-   Moving platforms or environmental hazards where required.
-   Interaction points, checkpoints and stage transitions.

------------------------------------------------------------------------

## 4. Initial Character Roster

These are provisional examples for building and testing the data model.
They are not a limit on the final roster.

**Naming note:** all names here are working names. See Section 2.1
before any public release.

| Character | Data ID | Element | Role | Weapon |
|---|---|---|---|---|
| Aether | `char_fire_01` | Fire | Main DPS | Sword |
| Lyra | `char_wind_01` | Wind | Support | Bow |
| Kael | `char_lightning_01` | Lightning | Sub-DPS | Dual Blades |
| Seraphine | `char_light_01` | Light | Healer | Staff |
| Noctis | `char_dark_01` | Dark | Control | Scythe |
| Terra | `char_earth_01` | Earth | Tank | Greatsword |

Code, data and frame folders use the Data ID only, never the working
name.

Each character should be data-driven and define, at minimum:

-   Unique ID and display name.
-   Element and combat role.
-   Base stats and growth parameters.
-   Weapon type.
-   Animation references.
-   Normal attack configuration.
-   Skills and ultimate ability.
-   Energy and cooldown parameters.
-   Passive abilities.
-   Switch-in skill and link condition (Section 3.3).
-   Portrait, sprite and VFX references.
-   Unlock and progression metadata.

Do not embed character-specific balance values directly into shared
combat code. Store tunable values in Godot Resources or another clearly
defined data format.

------------------------------------------------------------------------

## 5. Required Game Systems

Implement the following systems as independent modules with documented
dependencies.

### Core and input

-   Application bootstrap and scene flow.
-   Global configuration.
-   Input abstraction.
-   Keyboard/mouse/gamepad mappings.
-   Android multitouch controls.
-   Input rebinding where feasible.
-   Pause and focus handling.

### Player and animation

-   Character movement controller.
-   Player state machine.
-   Ground/air state handling.
-   Animation state integration.
-   Sprite facing and movement feedback.
-   Interaction controller.

### Characters and combat

-   Character definition and runtime instance.
-   Stats and stat modifiers.
-   Health and energy.
-   Hitbox/hurtbox.
-   Damage calculation.
-   Attack and skill execution.
-   Cooldowns and status effects.
-   Elemental reactions.
-   Combat feedback and event dispatch.

### Party and switching

-   Party roster and slot management.
-   Active-character management (one on the field).
-   Character switching with the 1.0 s global wait.
-   Switch-in skills, SI-CD and link conditions.
-   Elemental reaction table (15 pairs) and reaction ICD.
-   Reserve icon state: HP, SI-CD ring, link glow ring.

### Enemies and bosses

-   Enemy base architecture.
-   Enemy state machine.
-   Detection and attack behavior.
-   Damage and stagger handling.
-   Boss phase controller.
-   Boss telegraphs and arena rules.
-   Rewards and encounter completion.

### World and stages

-   Stage loading and unloading.
-   Tile and collision layers.
-   Parallax and layered backgrounds.
-   Platforms and hazards.
-   Checkpoints.
-   Interactables.
-   Stage objectives and completion.
-   Camera boundaries and transitions.

### RPG progression

-   Character leveling.
-   Experience and resources.
-   Equipment and inventory.
-   Equipment enhancement where appropriate.
-   Quests and objectives.
-   Reward distribution.
-   Unlock conditions.

### Gacha and recruitment

-   Offline recruitment simulation.
-   Banner configuration.
-   Rarity and drop-rate configuration.
-   Pity counter.
-   Rate-up behavior.
-   Guarantee rules.
-   Recruitment history.
-   Currency validation and consumption.
-   Deterministic test hooks for verifying probability and pity
    behavior.

All rates and guarantees must be visible in configuration and
documented. Never bury probability logic inside UI scripts.

Additional rules (owner decision):

-   Rates are fixed in config and are not changed randomly at runtime.
-   The UI displays rates generated from the same config used by the
    roll logic.
-   Tests use a seeded random source so results are reproducible.
-   Currency is non-monetary in the first release (see Section 2.1).

### Save and data

-   Versioned local save format.
-   Save/load service.
-   Schema version and migration strategy.
-   Safe handling of missing or invalid data.
-   Backup or recovery behavior where practical.
-   Save integrity checks.
-   Explicit separation between static game definitions and player-owned
    progression data.

### UI, audio and presentation

-   Main menu.
-   Character selection and party management.
-   HUD.
-   Character switch interface.
-   Skill and cooldown indicators.
-   Inventory and equipment screens.
-   Quest interface.
-   Gacha/recruitment interface.
-   Settings and controls.
-   Pause and confirmation dialogs.
-   Audio manager and VFX routing.
-   Localization-ready text handling.

------------------------------------------------------------------------

## 6. Architecture Rules

1.  Keep gameplay logic separate from UI presentation.
2.  Use modular scenes and reusable components.
3.  Use data-driven character, enemy, skill, item and banner
    definitions.
4.  Use signals/events for cross-system communication where appropriate.
5.  Avoid circular dependencies between systems.
6.  Keep platform-specific input and presentation code behind shared
    interfaces.
7.  Avoid giant manager scripts that own unrelated systems.
8.  Make balance values configurable rather than hardcoded.
9.  Keep save data separate from static definitions and runtime scene
    nodes.
10. Document public APIs, signals, data schemas and system dependencies.
11. Prefer small, testable implementation steps over large unverified
    code dumps.
12. Do not introduce plugins or third-party dependencies without
    explaining why they are needed.

### Suggested high-level data flow

`Input → Player Controller → State/Action → Combat System → Damage/Status → Character/Enemy Runtime State → Events → UI/VFX/Audio`

Party switching:

`Switch Input → Party Manager → Validate Target (alive, 1.0 s wait, not locked) → Check SI-CD and Link Window → Transition Active Slot → Play Switch-in Skill (Normal or Linked) → Resolve Elemental Reaction (Linked only) → Update HUD`

Recruitment:

`Recruitment Request → Validate Currency → Banner Rules → Drop/Pity/Guarantee Resolution → Grant Character/Item → Update History → Save`

------------------------------------------------------------------------

## 7. Suggested Folder Structure

Adapt this structure to the existing project rather than forcing a
destructive reorganization.

``` text
PROJECT_ECLIPSE/
├── project.godot
├── README.md
├── addons/            (third-party plugins such as gdUnit4; each documented)
├── assets/
│   ├── characters/
│   │   └── {character id}/      (e.g. char_fire_01; see Section 17.4)
│   │       ├── frames/{animation}/
│   │       ├── portrait/
│   │       ├── vfx/
│   │       └── frames_manifest.json
│   ├── placeholders/
│   ├── enemies/
│   ├── bosses/
│   ├── environments/
│   ├── ui/
│   ├── vfx/
│   ├── audio/
│   └── fonts/
├── scenes/
│   ├── main/
│   ├── player/
│   ├── characters/
│   ├── enemies/
│   ├── bosses/
│   ├── stages/
│   └── ui/
├── scripts/
│   ├── core/
│   ├── input/
│   ├── player/
│   ├── characters/
│   ├── combat/
│   ├── party/
│   ├── enemies/
│   ├── bosses/
│   ├── world/
│   ├── progression/
│   ├── inventory/
│   ├── equipment/
│   ├── gacha/
│   ├── quests/
│   ├── save/
│   ├── audio/
│   └── ui/
├── data/
│   ├── characters/
│   ├── enemies/
│   ├── skills/
│   ├── items/
│   ├── equipment/
│   ├── banners/
│   └── stages/
├── resources/
├── shaders/
├── localization/
├── tests/
└── docs/
    ├── design/
    │   └── CHARACTER_SKILLS.md   (owner-supplied; see Section 17.2)
    └── reference/            (study only; excluded from export)
```

------------------------------------------------------------------------

## 8. Cross-Platform Requirements

### Windows PC

-   Keyboard and mouse support.
-   Gamepad support.
-   Configurable input actions.
-   Window and display settings.
-   UI scaling for common landscape resolutions.

### Android

-   Multitouch virtual joystick.
-   Dedicated attack, jump, skill and switch controls.
-   Touch targets sized for practical use.
-   Responsive landscape UI.
-   Handle pause/resume and application focus changes.
-   Avoid excessive draw calls, oversized textures and unnecessary
    runtime allocations.
-   Test on a real Android device in addition to the editor.
-   Build and run an Android debug build from Milestone 1 onward, and
    re-test on a real device at the end of every milestone.

### Shared-code principle

Gameplay rules, combat calculations, character data, progression and
save schemas should be shared. Platform-specific code should be limited
to input, display, platform integration and performance adaptations.

------------------------------------------------------------------------

## 9. Development Roadmap

Work in milestones. Do not attempt to build the entire game in one pass.

  -----------------------------------------------------------------------
  Milestone               Scope                   Exit condition
  ----------------------- ----------------------- -----------------------
  0                       Inspect workspace and   Existing files and
                          establish architecture  engine are understood;
                                                  baseline docs exist

  1                       Core foundation         Project boots; scene
                                                  flow and input
                                                  abstraction work

  2                       Player and animation    One character moves,
                                                  jumps and animates
                                                  reliably

  3                       Combat foundation       Attacks, hit detection,
                                                  damage and enemy
                                                  reactions work

  4                       Three-character party   One-on-field switching,
                                                  switch-in skills and
                                                  elemental reactions work

  5                       RPG and recruitment     Progression, inventory,
                                                  save/load and offline
                                                  gacha work

  6                       World and encounters    One complete stage and
                                                  one boss encounter work

  7                       UI and polish           Core screens, feedback,
                                                  audio and platform
                                                  controls are integrated

  8                       QA and release          Acceptance tests pass
                          preparation             on Windows and Android;
                                                  known issues documented
  -----------------------------------------------------------------------

### Recommended first playable vertical slice

Build this before expanding the roster or content:

-   One fully playable character.
-   Two reserve characters with switch-in skills.
-   One basic enemy type.
-   One compact side-scrolling stage.
-   One boss with at least two readable phases.
-   Character switching, switch-in skills and elemental reactions.
-   Basic combat loop and rewards.
-   Minimal HUD and pause interface.
-   Local save/load.

Only expand the content after this slice is stable and testable.

------------------------------------------------------------------------

## 10. Acceptance Criteria

A feature is not complete merely because code has been generated. It
must be implemented, integrated and verified.

### Test tooling

Automated tests use GdUnit4 and are run headless where possible.
Combat damage, cooldowns, save/load and gacha logic must have
automated tests. Anything that needs a real Android device or visual
inspection cannot be verified by Claude: it stays `TESTED` or
`BLOCKED` until the owner supplies the result as evidence.

### Core

-   [ ] Project opens in the selected Godot 4.x version without blocking
    errors.
-   [ ] Main scene loads and transitions correctly.
-   [ ] Input works on the intended platform.

### Player and combat

-   [ ] Movement, jumping, falling and landing behave consistently.
-   [ ] Attack input triggers the correct animation and hit detection.
-   [ ] Damage is applied once per valid hit according to the configured
    rules.
-   [ ] Health, energy and cooldown values update correctly.
-   [ ] Invalid actions are rejected safely.

### Party

-   [ ] Three party slots can be configured.
-   [ ] Only one character is on the field; reserve characters do not
    act and receive no input.
-   [ ] Reserve icons show HP and the SI-CD ring.
-   [ ] The link glow ring appears only when the character's link
    condition happened within 6.0 s and the SI-CD is ready.
-   [ ] A Linked switch-in triggers the correct reaction for each of
    the 15 element pairs; the 5.0 s reaction ICD is respected.
-   [ ] A Normal switch-in triggers no reaction; a switch-in that hits
    nothing triggers no damage reaction.
-   [ ] Switching is locked during chain-type ultimates and for a downed
    character, and handles unavailable characters safely.

### Enemies and boss

-   [ ] Enemies detect and engage the player according to their AI
    configuration.
-   [ ] Enemy damage, defeat and rewards work.
-   [ ] Boss phases transition under the correct conditions.
-   [ ] Boss telegraphs are readable and attacks can be handled by the
    player.

### Progression and recruitment

-   [ ] Character progression updates stats correctly.
-   [ ] Inventory and equipment changes persist.
-   [ ] Recruitment consumes the correct resource.
-   [ ] Drop, pity, rate-up and guarantee rules pass deterministic
    tests.
-   [ ] Recruitment history is saved and loaded correctly.

### Save and platforms

-   [ ] Save/load preserves the required player state.
-   [ ] Invalid or older save data is handled without crashing.
-   [ ] Windows controls work.
-   [ ] Android touch controls work on a real device.
-   [ ] UI remains usable at supported landscape resolutions.

Criteria for the deferred features in Section 2.3 do not gate the first
build.

Record test evidence and unresolved issues. Do not mark a criterion
complete without a test or other explicit verification.

------------------------------------------------------------------------

## 11. Required Project Documentation

Create and maintain these files in `docs/`:

  -----------------------------------------------------------------------
  File                                Purpose
  ----------------------------------- -----------------------------------
  `PROJECT_OVERVIEW.md`               Vision, scope, core loop and design
                                      pillars

  `ARCHITECTURE.md`                   System architecture, modules and
                                      interfaces

  `SYSTEM_DEPENDENCIES.md`            Dependency relationships and
                                      event/data flow

  `FOLDER_STRUCTURE.md`               Folder and file organization

  `IMPLEMENTATION_ROADMAP.md`         Milestones, tasks and dependencies

  `ACCEPTANCE_TESTS.md`               Test cases and pass/fail criteria

  `DEVELOPMENT_LOG.md`                Actual progress, changed files,
                                      tests and blockers

  `ASSET_LICENSES.md`                 Source, license and proof for every
                                      external asset, font, audio file
                                      and plugin

  `UI_UX_SPEC.md`                     Screen inventory, navigation, HUD
                                      layout and UX rules, derived from
                                      Section 15

  `design/CHARACTER_SKILLS.md`        Owner-supplied source of truth for
                                      skills, switch-in skills, link
                                      conditions and the reaction table
                                      (Section 17.2)
  -----------------------------------------------------------------------

### Development log format

For each task, record:

-   Date.
-   Milestone and task ID.
-   Status: `IMPLEMENTED`, `TESTED`, `VERIFIED` or `BLOCKED`.
-   Files created or modified.
-   Commands or test procedures executed.
-   Actual test results.
-   Errors, warnings and known limitations.
-   Remaining work.
-   Next three priorities.

Use statuses accurately: - `IMPLEMENTED`: code or assets have been
added. - `TESTED`: a test or manual procedure has been run. -
`VERIFIED`: the expected result was observed and evidence recorded. -
`BLOCKED`: progress cannot continue because of a documented dependency
or issue.

Do not use `VERIFIED` as a synonym for "the code looks correct".

------------------------------------------------------------------------

## 12. Working Protocol for Claude Code / Claude Opus

Use this README as the baseline project specification.

### Owner context

-   The owner is new to Godot. Explain setup steps (installing Godot
    4.6.3, GdUnit4, Android export templates, JDK/SDK) one at a time
    and briefly explain each new GDScript or Godot concept when it is
    first used.
-   The owner creates the UI, final art, VFX and assets. Claude builds
    the systems and placeholders, and does not produce final art.

### Before implementation

1.  Inspect the complete project workspace.
2.  Identify the engine version, current folder structure, existing
    scenes, scripts, assets and project settings.
3.  Identify what already works and what is incomplete.
4.  Preserve existing work.
5.  Report architectural conflicts or missing prerequisites before
    making major changes.
6.  Create or update the required documentation files.
7.  Propose a milestone-sized implementation plan.

### During implementation

1.  Work on one milestone or a small, coherent task group at a time.
2.  State the files that will be created or changed.
3.  Implement the smallest complete vertical slice for the task.
4.  Integrate the code into the project rather than leaving disconnected
    examples.
5.  Run relevant static checks, project launch checks and tests.
6.  Fix errors introduced by the implementation before moving on.
7.  Update `DEVELOPMENT_LOG.md` with actual outcomes.
8.  Keep architecture and acceptance criteria synchronized with
    implementation.

### Reporting format after each task

``` text
TASK:
MILESTONE:
STATUS: IMPLEMENTED / TESTED / VERIFIED / BLOCKED

CHANGES:
- Files created:
- Files modified:
- Systems affected:

VALIDATION:
- Commands or procedures run:
- Test results:
- Errors/warnings:

REMAINING:
- Known issues:
- Unimplemented requirements:

NEXT THREE PRIORITIES:
1.
2.
3.
```

### Strict execution rules

-   Do not claim a build, test, export or device run succeeded unless it
    was actually executed and the result was observed.
-   Do not fabricate screenshots, logs, test output or performance
    measurements.
-   Do not silently skip failed tests.
-   Do not replace the project architecture without explaining the
    impact and obtaining approval for a destructive change.
-   Do not generate the whole game in one response.
-   Do not create placeholder systems and label them production-ready.
-   If a requirement is ambiguous, identify the ambiguity and recommend
    a concrete default.
-   If a task is too large, divide it into verifiable subtasks.
-   Prefer stable, maintainable implementations over premature
    optimization.

------------------------------------------------------------------------

## 13. Definition of Done

A milestone is complete only when:

1.  Its scope has been implemented in the actual project.
2.  The work is integrated with the existing architecture.
3.  Relevant tests or manual validation procedures have been executed.
4.  Acceptance criteria have been updated with evidence-based status.
5.  Known defects and limitations are documented.
6.  `DEVELOPMENT_LOG.md` reflects the actual state.
7.  The next milestone can begin without relying on undocumented
    assumptions.

------------------------------------------------------------------------

## 14. Immediate Starting Instruction

> **Status: DEFERRED.** The owner has decided not to start work yet.
> Do not begin Milestone 0 or any implementation until the owner
> gives an explicit go-ahead. When work is started, the instruction
> below applies. Before Milestone 0 is written, also read Sections 15,
> 16 and 17, and complete the kickoff checklist in Section 17.6.

**Start with Milestone 0. Do not begin by generating gameplay systems.**

Inspect the existing workspace and return:

1.  Current project structure.
2.  Engine and version detected.
3.  Existing systems and their current state.
4.  Missing or conflicting requirements.
5.  Recommended architecture based on the actual workspace.
6.  A milestone-sized implementation plan.
7.  The documentation files that should be created or updated.

After the inspection report, wait for approval before performing
destructive changes or major architectural migration. If no project
exists yet, propose the minimal Godot 4.x project foundation and its
initial file structure.

------------------------------------------------------------------------

## 15. Reference Study: UI, UX and Gameplay Direction

### 15.1 Purpose and legal boundary

These references exist so the first implementation matches the owner's
intended experience with fewer corrections.

-   The references appear to come from *Houkai Gakuen 2 / Honkai Impact
    2nd* (based on the owner's wiki link; the screenshots use the Chinese
    client).
-   **Study patterns only.** Do not copy assets, characters, icons,
    text, color palettes or layouts 1:1. The screenshots contain
    third-party licensed characters; none may appear in this project.
-   The project needs its own visual identity. The owner draws the final
    UI, art and effects. Claude builds working screens and a reusable UI
    theme with placeholders that the owner can restyle without code
    changes.
-   Files in `docs/reference/` are never imported as game assets and must
    be excluded from export builds.

| Reference | Content | Reliability |
|---|---|---|
| `ref_01_battle_hud.jpg` | Battle HUD on a phone | Read from the screenshot |
| `ref_02_character_equipment.webp` | Character / equipment screen | Read from the screenshot |
| `ref_03_home_hub.jpg` | Home hub screen | Read from the screenshot |
| Wiki: Characters/Playable | Progression and gacha patterns | Read from the wiki page |
| Gameplay video (owner link, YouTube `zMiPszGFFgk`) | Combat feel | **Not readable by Claude.** Do not invent video content. The owner will list mechanics or timestamps worth copying in spirit. |

### 15.2 Observations from the screenshots

**Battle HUD (`ref_01`)**

-   Landscape. Top-left: heart icon with a wide HP bar. Next to it, a
    rounded counter bubble (ammo in the reference; in this project use
    the active character's energy or skill resource).
-   Top-right: round pause button. Below it, a short-lived "kills" tag
    (in this project: hit/combo counter that fades).
-   Bottom-left: large translucent virtual joystick with a glowing ring.
    Bottom-right: round neon-style action buttons with clear icons.
-   Each character has a soft blob shadow on the ground.
-   Feedback is rich: muzzle smoke, ejected casings, star bursts, drifting
    petals as ambient particles.
-   The reference lets characters move in depth across a wide ground
    area. This project defaults to side-scrolling with platforming
    (Section 3.5). See open decision OD-1.

**Home hub (`ref_03`)**

-   Full-screen key illustration of characters as the background, with UI
    overlaid on top.
-   Top-left player card: circular avatar with a colored ring, level,
    name, stamina bar with `current/max`, gold, premium currency and a
    `+` button.
-   Top-right main navigation: six tabs, each icon plus label. The
    selected tab is brighter and glows; others are dimmed.
-   Left edge: small utility icons (codex, chat). Right edge: event/gift
    icon with a label. Bottom-right: event banner with a portrait and a
    fullscreen toggle.
-   The screenshot is ultra-wide with side bars: the layout must handle
    wide screens and notches.

**Character / equipment screen (`ref_02`)**

-   The same top bar stays visible on every hub screen. A large back
    arrow sits top-left. Tabs can show a small notification dot.
-   Left side: large character display with the equipped weapon, on a
    light background with faint geometric ring patterns.
-   Right side: a panel with three character portrait cards. The selected
    card has gold corner brackets. Below: character name, rarity stars
    and a description.
-   Weakness to avoid: the description text is clipped at the bottom of
    the panel. Use a scrollable area or truncation with "more".

**Progression patterns from the wiki (patterns only, no numbers)**

-   Account level is separate from character level. It raises max
    stamina, base HP and an equipment weight limit.
-   Stamina is spent to enter stages.
-   Most characters can use any weapon, with character skills favoring
    certain weapon types.
-   A layered skill-upgrade system: points are earned by fighting, only
    one skill per layer is active, switching costs points, and new
    actions unlock at level milestones.
-   Milestone "EX" upgrades that cost materials.
-   Cosmetic character skins.
-   Banner design: a permanent pool plus rotating featured characters that
    share a rate-up pool, with pity.

### 15.3 What to adopt, defer or avoid

| Pattern | Decision |
|---|---|
| Persistent top bar (profile, currency, nav tabs) on hub screens | Adopt now |
| Back arrow top-left on sub-screens | Adopt now |
| Selected-tab highlight and notification dots driven by real state | Adopt now |
| Large character display plus card carousel for character selection | Adopt now |
| Joystick bottom-left, round action buttons bottom-right | Adopt now |
| Hit/combo counter that fades | Adopt now |
| Layered skill-upgrade system | Adopt after the vertical slice |
| Equipment slots | Adopt now (basic) |
| Equipment weight limit | Optional, config flag, default off |
| Stamina gating stages | Optional, config flag, default off (OD-3) |
| Skins | Defer; data model must allow them |
| Permanent plus rotating banner with pity | Adopt (rates fixed, Section 2.1) |
| Shop with real-money currency | Do not adopt in the first release |
| Social / friends | Do not adopt in the first release |
| Ammo and gun mechanics | Do not adopt (combat follows Section 3) |
| Reference characters, names, text, icons | Do not use |

All numbers (levels, stamina, HP, rates) must be original and live in
config. Never reuse the reference game's values.

### 15.4 Screen inventory and navigation

The owner supplies final visuals. Claude implements each screen as a
working scene with real data.

| Screen | Purpose and key elements | First build |
|---|---|---|
| Boot / loading | Logo, progress, version | Yes |
| Title | Continue, New Game, Settings | Yes |
| Home hub | Key art background, profile card, currency, nav tabs | Yes |
| Battle select | Stage list, rewards preview, start | Yes |
| Party select | Three slots, character cards, role and element info | Yes |
| Battle HUD | See 15.5 | Yes |
| Pause | Resume, Settings, Quit with confirmation | Yes |
| Result | Rewards, EXP, retry, return to hub | Yes |
| Character list / detail | Large display, card carousel, stats, skills | Yes |
| Equipment / inventory | Slots, item list, compare, equip | Yes (basic) |
| Recruit (gacha) | Banner, rates button, pity counter, 1x and 10x, history, skippable reveal | Yes |
| Settings | Audio, controls, language, graphics | Yes |
| Skill upgrade | Layered skill selection | After slice |
| Shop, Social, Codex, Mail, Quest | Not in the first build | No |

Navigation rules:

-   Hub tabs for the first build: Home, Battle, Characters/Equipment,
    Recruit, Settings. Tabs for unbuilt features are hidden, not shown
    disabled.
-   Every sub-screen has a back control and supports the platform's back
    action (Android back button / Escape key).
-   Screen transitions take 150 to 250 ms. Scene loading above 2 s shows
    a progress indicator.

### 15.5 Battle HUD specification

Required elements (placement may follow the reference; Claude chooses
exact positions and keeps them in one theme file):

-   Active character: portrait, HP bar, energy bar (top-left).
-   **Two reserve icons in the top-right corner:** portrait, small HP
    bar, SI-CD radial fill and a link glow ring; tap to switch. Minimum
    touch target 140 px. Ring specification in Section 17.5.
-   Skill buttons with radial cooldown fill and number; ultimate button
    with an energy ring that shows when ready.
-   Attack, jump and dash controls. Switching is done with the reserve
    icons.
-   Pause button, placed away from the reserve icons (for example next
    to the active character card).
-   Hit/combo counter that fades after about 2 to 3 seconds without
    hits, placed so it does not overlap the reserve icons.
-   Boss HP bar at top-center with phase markers. Regular enemies show a
    small HP bar when damaged.
-   Floating damage numbers: element color, larger for critical hits.

Touch rules (Android):

-   Floating joystick option in the left half of the screen, with a dead
    zone and an optional fixed mode in Settings.
-   The joystick finger must never block action buttons (independent
    multitouch).
-   Minimum touch target: 128 logical px at the 1920x1080 base. The main
    attack button is the largest (about 170 px). These are starting
    values to confirm on a real device.
-   Keep thumb zones clear: no HUD elements over the lower corners except
    controls.
-   Honor the device safe area and notches. For 18:9 to 21:9 screens,
    extend backgrounds and anchor UI to safe-area corners. Never
    stretch the UI and never show black bars.
-   Input buffering of 100 to 150 ms for attack, jump and switch.
-   The reserve icons are far from the thumb. Use large touch targets,
    accept the tap through the input buffer, and test on a real device.
    If they prove hard to use, add a Settings option to move them
    (OD-6).

### 15.6 UX rules

-   **Every button works.** No fake buttons, menus or features. Every
    displayed number comes from real game state.
-   Pressed buttons give feedback: slight scale-down plus sound.
-   Spending currency (recruit pulls, enhancement) needs a confirmation
    step that states the cost.
-   Text never clips. Panels scroll. Allow 30 to 40 percent text growth
    for translations (English, Vietnamese, Chinese).
-   Recruit screen: rates are always one tap away and generated from
    config; the pity counter is visible; the reveal animation can be
    skipped; a 10-pull shows a result grid; duplicate handling is stated
    clearly.
-   Notification dots appear only for real, claimable or unseen states
    and clear when seen.
-   Currency chips with a `+` button must lead to a working destination
    or be hidden.

### 15.7 Gameplay feel targets

Starting defaults, all tunable in config and refined through playtests.

-   Platforming: coyote time 80 to 120 ms, variable jump height, input
    buffering as above.
-   Combat feedback on every hit: hit flash, short hit-stop (40 to 80
    ms), small camera shake, knockback, damage number and sound.
-   Attack phases (startup, active, recovery) are readable and cancel
    rules are documented per character data.
-   Ultimate: short (under about 1.5 s) presentation. Gameplay input
    stays responsive afterwards.
-   Only one character is on screen. Switch-in presentations stay
    under about 1 s, reaction effects use a 60 ms hit-stop and the
    reaction name shows for 0.8 s, so combat stays readable.
-   Boss attacks have a visible telegraph of at least 0.4 s, readable at
    phone size.
-   Camera: smooth follow with look-ahead and arena locks for bosses.
-   Environment: soft blob shadows under characters and ambient particles
    that fit the stage theme (for example petals, dust, leaves).
-   First stage: about 3 to 5 minutes, with 2 to 3 enemy waves and a
    boss, ending on a result screen with rewards.

### 15.8 Open decisions

Claude uses the default until the owner answers.

| ID | Question | Default |
|---|---|---|
| OD-1 | Movement plane: pure side-scroll platforming, or depth lanes like `ref_01`? | Side-scroll platforming (Section 3.5) |
| OD-2 | Chibi or standard anime proportions? | Owner decides through art; no code impact |
| OD-3 | Use a stamina/energy system to gate stages? | Off (config flag) |
| OD-4 | Which mechanics or timestamps from the gameplay video should be matched in spirit? | None until the owner lists them |
| OD-5 | Weapons: fixed per character, or equippable by any character? | Fixed per character (Section 4). **Owner 2026-11-14:** a weapon is locked to the character's weapon type (`weapon_type`); stigmata can be worn by any character. See `docs/design/EQUIPMENT_5STAR.md` section 5.1 |
| OD-6 | Position of the reserve icons | Top-right (owner decision); Settings option to move them if testing shows they are hard to reach |

------------------------------------------------------------------------

## 16. Autonomous Development Mode

This mode applies after the owner approves Milestone 0 (Section 14). The
Milestone 0 approval gate still stands.

**Claude decides without asking** (record each decision in
`DEVELOPMENT_LOG.md`):

-   Colors, placeholder art, variable and node names.
-   Folder substructure and script organization.
-   Exact UI positions and sizes within Section 15.
-   Number of placeholder frames and effects.
-   Small balance values in config.
-   Test structure inside GdUnit4.

**Claude must stop and ask when:**

-   A Locked Technical Decision (Section 2) would change.
-   A plugin, third-party asset or license is involved.
-   A character or product name could conflict with existing IP.
-   Monetization, currency or gacha rules would change.
-   A skill rule or number in `docs/design/CHARACTER_SKILLS.md` would
    change (tuning goes to data and the log; the file changes only with
    owner approval).
-   The specification contradicts itself or an open decision (Section
    15.8) blocks the work.

**Working loop for every milestone:**

1.  Implement the milestone scope.
2.  Run the project and check the console for errors and warnings.
3.  Run automated tests (GdUnit4).
4.  Play the milestone's flow; fix bugs; retest.
5.  Polish feedback and UI behavior.
6.  Test save and load.
7.  Report in `DEVELOPMENT_LOG.md`. Mark items needing a real device as
    pending owner verification.

**Priorities:** PLAYABLE over FEATURE COUNT. Finish and stabilize a
system before starting the next one. Every important gameplay action
has visual feedback. Never add features only for display.

**Do not build:**

-   A game that is only menus, buttons and numbers. Combat is the center
    of gameplay.
-   Corporate dashboard or generic web-style UI.
-   Fake buttons, fake menus or placeholder screens presented as
    finished.

**Self-play checklist before finishing the vertical slice:**

Start game → hub → choose stage → choose party → battle: move, jump,
attack, use a skill, switch character, take damage, defeat enemies →
boss, both phases → result and rewards → recruit pull → save → quit →
reload → continue with progress intact. If any step fails, fix it before
reporting completion.

------------------------------------------------------------------------

## 17. Project Kickoff Pack: Files, Folders and Linking

### 17.1 Source-of-truth files and reading order

Claude Code reads these in order before Milestone 0:

| Order | File or folder | Role |
|---|---|---|
| 1 | `README.md` (this file) | Architecture, rules, working protocol |
| 2 | `docs/design/CHARACTER_SKILLS.md` | Source of truth for every skill, switch-in skill, link condition and elemental reaction |
| 3 | `assets/characters/{id}/frames_manifest.json` | Frame counts, FPS and animation list per character |
| 4 | `docs/reference/` | UI and gameplay references (study only) |
| 5 | `assets/characters/{id}/frames/` | The owner's frames, once delivered |

If files disagree: Section 8 of `CHARACTER_SKILLS.md` overrides its own
Sections 0 to 7. `CHARACTER_SKILLS.md` wins over this README on skill
rules and numbers. This README wins on architecture, folders and working
protocol.

### 17.2 Linking the character skills file

-   Path: `docs/design/CHARACTER_SKILLS.md`.
-   The owner exports the skills document
    (https://claude.ai/artifact/FwEx875pUtQBokmqiGtdeP) as Markdown and
    saves it at that path. The kickoff pack ships a stub there.
-   **Stub rule:** if the first line of the file is `<!-- STUB -->`,
    Claude Code stops and asks the owner to export the document. It
    never invents skill data.
-   Skill IDs follow `{character id}.{key}`. Keys: `normal`, `dodge`,
    `passive`, `hold`, `air`, `landing`, `skill`, `weapon`, `ultimate`,
    `switch_in`.

How the file becomes data:

| Part of the skills file | Becomes |
|---|---|
| Section 0 (resources, CDR cap, perfect dodge, shared statuses) | `data/config/combat_rules.tres` |
| Sections 1 to 6 (per-character skills) | `data/skills/{id}/{key}.tres` |
| Sections 8.2, 8.3, 8.5 to 8.10 (switch-in, link conditions, SI-CD) | `data/skills/{id}/switch_in.tres` and `data/config/link_rules.tres` |
| Section 8.4 (reaction table) | `data/reactions/{element_a}_{element_b}.tres` |

Rules:

-   Never hardcode numbers from the file in scripts.
-   Balance changes go to data, are recorded in `DEVELOPMENT_LOG.md`, and
    are written back to the skills file only after owner approval.
-   Frame counts in the skills file are suggestions. The real counts live
    in each `frames_manifest.json`.

### 17.3 Character IDs

| Working name | Data ID | Element | Frame folder |
|---|---|---|---|
| Aether | `char_fire_01` | Fire | `assets/characters/char_fire_01/` |
| Lyra | `char_wind_01` | Wind | `assets/characters/char_wind_01/` |
| Kael | `char_lightning_01` | Lightning | `assets/characters/char_lightning_01/` |
| Seraphine | `char_light_01` | Light | `assets/characters/char_light_01/` |
| Noctis | `char_dark_01` | Dark | `assets/characters/char_dark_01/` |
| Terra | `char_earth_01` | Earth | `assets/characters/char_earth_01/` |

### 17.4 Frame folders and manifest

Layout (one tree per character, already created in the kickoff pack):

``` text
assets/characters/char_fire_01/
├── frames/
│   ├── idle/
│   ├── attack_1/
│   ├── ...                one folder per animation
│   └── switch_out/
├── portrait/
├── vfx/
└── frames_manifest.json
```

File naming inside a folder: `{id}_{animation}_{NNN}.png`, numbered from
`000`, for example `char_fire_01_attack_1_000.png`. All frames of a
character use the same canvas (Section 2.2).

Mapping between skill keys and animation folders:

| Skill key | Animation folders | Notes |
|---|---|---|
| `normal` | `attack_1` to `attack_n` | One folder per combo hit |
| `dodge` | `dodge` | |
| `passive` | none | VFX only |
| `hold` | `hold_charge` (loop), `hold_release` | |
| `air` | `air_1` to `air_n` | |
| `landing` | `landing_attack` | The plunge strike, not the plain `land` |
| `skill` | `skill_1` | Normal skill |
| `weapon` | `skill_2` | Weapon skill |
| `ultimate` | `ultimate` | Cut-in portrait is separate UI art |
| `switch_in` | `switch_in` | Replaces the default 4-frame entry |
| exit | `switch_out` | 3 frames, no skill |
| basic | `idle`, `run`, `jump_up`, `fall`, `land`, `hurt`, `knockback`, `down` | |

Combo folders created per character:

| Character | Normal attack folders | Air attack folders |
|---|---|---|
| Aether | `attack_1` to `attack_4` | `air_1`, `air_2` |
| Lyra | `attack_1` to `attack_3` | `air_1` |
| Kael | `attack_1` to `attack_5` | `air_1` to `air_3` |
| Seraphine | `attack_1` to `attack_3` | `air_1` |
| Noctis | `attack_1` to `attack_4` | `air_1`, `air_2` |
| Terra | `attack_1` to `attack_3` | `air_1` |

`frames_manifest.json` (already generated per character, values to be
filled by the owner):

-   `frames: 0` means the frames are not delivered yet. Claude Code uses
    a placeholder from `assets/placeholders/` and keeps going.
-   `fps` and `loop` per animation. Defaults: 12 fps for loops, 24 fps
    for attacks.
-   `skill_key` links each animation to the skill that uses it.
-   `frames_delivered` is set to `true` by the owner when the character's
    art is complete.

When the owner delivers frames:

1.  Copy the PNGs into the matching `frames/{animation}/` folder.
2.  Set `frames` (and `fps` if needed) for that animation in the
    manifest.
3.  Claude Code builds the `SpriteFrames` resource from the manifest and
    adds a GdUnit4 check that the PNG count in each folder equals
    `frames`. A mismatch fails the test.
4.  Timings in the skills file are adjusted to the real frame counts
    through data, not code.

### 17.5 Reserve icon and link ring (HUD)

-   Icon: portrait, small HP bar, SI-CD radial fill, minimum touch target
    140 px, top-right corner.
-   Link glow ring: a ring around the icon, colored by the character's
    element. It fades in over 150 ms, pulses every 0.8 s (scale 1.0 to
    1.12, brightness 0.6 to 1.0) and has small particles orbiting it. A
    thin arc around it shrinks with the remaining 6.0 s window. On expiry
    it fades out over 300 ms; when used it bursts for 200 ms. A short
    sound plays when it lights.
-   The ring is visible only when the link condition happened within the
    last 6.0 s and the SI-CD is ready. Two icons may glow at once.
-   Placeholder color tokens (the owner replaces them with final art):

| Element | Token | Hex |
|---|---|---|
| Fire | `ring_fire` | `#FF6A3D` |
| Wind | `ring_wind` | `#3DDBB5` |
| Lightning | `ring_lightning` | `#FFD93D` |
| Light | `ring_light` | `#FFF2B8` |
| Dark | `ring_dark` | `#A855F7` |
| Earth | `ring_earth` | `#D99A3E` |

### 17.6 Kickoff checklist and first prompt

Before giving the go-ahead for Milestone 0:

-   [ ] Godot 4.6.3 is installed.
-   [ ] `docs/design/CHARACTER_SKILLS.md` is the real export, not the
    stub.
-   [ ] `docs/reference/` contains the three reference images.
-   [ ] `assets/characters/*/frames_manifest.json` exist (frames may be
    `0`; placeholders are used).
-   [ ] The owner has chosen original character names, or accepts the
    working names for development only (Section 2.1).
-   [ ] The owner has given an explicit go-ahead.

First message to paste into Claude Code:

``` text
Read README.md completely (Sections 1 to 17), then
docs/design/CHARACTER_SKILLS.md, then every
assets/characters/*/frames_manifest.json. Follow Section 14: run
Milestone 0 only (inspection report and documentation plan). Do not
write gameplay code yet. If CHARACTER_SKILLS.md is still the stub, stop
and tell me. Ask me about anything unclear before assuming.
```

------------------------------------------------------------------------

## Revision History

  Revision   Changes
  ---------- -------------------------------------------------------------
  1          Baseline specification.
  2          Locked Godot 4.6.3 and GdUnit4. Fixed frame-by-frame sprite
             specification and AnimationPlayer-driven hitboxes. Fixed
             gacha rates in config with published rates. Added commercial,
             licensing and asset rules, `ASSET_LICENSES.md`, first-build
             scope, owner context, and Android-from-Milestone-1 testing.
             Milestone 0 marked as deferred until owner approval.

  3          Added Section 15 (reference study of UI, UX and gameplay
             from owner screenshots and wiki), Section 16 (autonomous
             development mode), `docs/reference/` images, and
             `UI_UX_SPEC.md` to the documentation list. Gameplay video
             content was not readable and is listed as open decision
             OD-4.

  4          Changed to one character on the field with two reserve
             icons (Sections 1, 3, 4, 5, 6, 9, 10, 15.5, 15.7). Added
             switch-in skills, link conditions, glow ring and the elemental
             reaction table (by reference to the skills file). Removed
             support AI. Added Section 17 (kickoff pack: skills-file
             linking, character IDs, frame folders and manifests, HUD
             ring, checklist, first prompt), updated animation names and
             the folder tree, and added OD-6.
