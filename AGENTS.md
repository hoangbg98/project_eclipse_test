# AGENTS.md — quy tắc cho agent lập trình (Codex, Claude Code)

Dự án: **PROJECT ECLIPSE**, game action RPG 2D side-scroll, đội 3 người, Godot **4.6.3**
(GDScript). Bản thương mại; ưu tiên Windows, Android hoãn (xem bên dưới).

Owner nói **tiếng Việt**. Trả lời, viết tài liệu và nhật ký bằng tiếng Việt; thuật
ngữ kỹ thuật, tên code giữ tiếng Anh.

## 1. Nguồn sự thật (đọc trước khi làm)

1. `README.md` — đặc tả đầy đủ (mục 2 quyết định khóa, 6 kiến trúc, 9 lộ trình, 12 quy trình, 16 tự chủ, 17 asset).
2. `docs/design/CHARACTER_SKILLS.md` — kỹ năng nhân vật, phản ứng nguyên tố. **Không sửa**; giá trị cân bằng nằm trong `data/`.
3. `docs/ARCHITECTURE.md`, `docs/SYSTEM_DEPENDENCIES.md`, `docs/FOLDER_STRUCTURE.md`.
4. `docs/IMPLEMENTATION_ROADMAP.md` — task `M{n}-{k}` và trạng thái.
5. `docs/DEVELOPMENT_LOG.md` — đã làm gì, quyết định nào, còn chặn gì. **Đọc mục cuối trước khi bắt đầu.**
6. `docs/OWNER_ASSET_CHECKLIST.md` — asset/quyết định owner còn nợ.
7. `docs/KNOWN_ISSUES.md` — việc tồn đọng trước khi phát hành; `docs/ACCEPTANCE_TESTS.md` — trạng thái nghiệm thu.

Nếu tài liệu mâu thuẫn: hỏi owner, không tự chọn.

## 2. Lệnh

Godot không có trong PATH:

```
C:\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe
```

| Việc | Lệnh (chạy ở thư mục gốc dự án) |
|---|---|
| Nạp lại cache class (sau khi thêm script/`class_name`) | `<godot> --headless --path . --import` |
| **Toàn bộ test** (GdUnit4 + test khói) | `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1` |
| Chỉ GdUnit4 | `<godot> --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit --ignoreHeadlessMode -rd reports` |
| Build Windows debug | `<godot> --headless --path . --export-debug "Windows Desktop" build/windows/ProjectEclipse.exe` |
| Kiểm tra máy build | `powershell -ExecutionPolicy Bypass -File tools\check_build_env.ps1` |

Test phải đạt (mã thoát 0) trước khi báo xong. Không báo "đạt" nếu chưa chạy.

## 3. Quy tắc code

- Logic gameplay tách khỏi UI; UI chỉ đọc state và nghe signal (`EventBus`).
- **Mọi số cân bằng nằm trong data** (`.tres` trong `data/`), không viết cứng trong script.
- Nhân vật dùng **Data ID** (`char_fire_01`…), không dùng tên hiển thị trong code/data. Mỗi Data ID là một **giáp** (owner 2026-11-13); `CharacterDef.person_id` nối các giáp cùng nhân vật, `suit_key` là tên giáp. Đội không có hai giáp cùng nhân vật. Tên hiện tại: Enkiba (fire), Kazeyumi (wind), Raikiba (lightning), Hikarine (light), Yomigari (dark), Iwagane (earth) — tên cũ Aether / Lyra / Kael / Seraphine / Noctis / Terra không dùng cho chữ hiển thị nữa.
- Autoload hiện có: `GameConfig`, `EventBus`, `InputRouter`, `SceneRouter`, `AudioRouter`, `SaveService` (thứ tự trong `project.godot`). Không thêm luật gameplay vào autoload.
- Input: dùng action của `InputRouter` (`move_left/right`, `jump`, `attack`, `dodge`, `skill`, `weapon`, `ultimate`, `switch_1/2`, `pause`, `ui_back`) và `InputRouter.consume_buffered()`; không đọc phím trực tiếp.
- Chữ hiển thị: khóa `UPPER_SNAKE` qua `tr()`, thêm vào **cả** `localization/vi.po` và `en.po`.
- Đặt tên: file/hàm/biến `snake_case`, `class_name` `PascalCase`, hằng `UPPER_SNAKE`.
- Test mới viết bằng **GdUnit4** trong `tests/unit/<khu vực>/test_*.gd`.
- Ngẫu nhiên đi qua nguồn có seed để test tái lập được.
- Lớp va chạm 2D: dùng hằng số trong `scripts/combat/physics_layers.gd` (`PhysicsLayers`), không gõ số lớp tay.
- Script gameplay (combat, enemies, player, characters) **không gọi thẳng tên autoload** (`EventBus.x`, `GameConfig.x`): lấy qua `get_tree().root.get_node_or_null("EventBus")`. Lý do: test khói chạy bằng `--script` không có tên autoload lúc biên dịch. Script UI/màn hình (scenes/main) được dùng thẳng.
- Đòn đánh: `Hitbox` (bật theo track AnimationPlayer dựng bằng `HitboxTrack` từ frame + fps) → `Hurtbox` (mỗi `hit_id` trúng một lần). Không tự viết kiểm tra va chạm riêng.

## 4. Asset và giấy phép

- Owner cung cấp art, UI, VFX, nhạc, SFX, font. Khi thiếu: dùng placeholder tên `placeholder_*` trong `assets/placeholders/`, ghi vào `docs/ASSET_LICENSES.md`.
- **Không thêm** asset/code/plugin bên thứ ba nếu chưa ghi lý do, nguồn, giấy phép vào `docs/ASSET_LICENSES.md`.
- Frame nhân vật: 384×384, chân y = 336, tâm x = 192, vẽ hướng phải; tên `{id}_{animation}_{NNN}.png`; số frame/fps trong `frames_manifest.json` (README 2.2, 17.4).
- Loại khỏi export: `docs/`, `tests/`, `addons/gdUnit4/`; bản Release loại thêm `*placeholder_*`.

### Ảnh do AI tạo (Codex imagegen, owner quyết định 2026-11-12)

- Owner cho phép ảnh AI **vào bản phát hành chính thức**. Không đặt tên `placeholder_*` cho ảnh AI dùng thật.
- Codex tạo bằng skill `imagegen` (công cụ `image_gen` tích hợp, không cần API key). Ảnh mặc định nằm ở `$CODEX_HOME/generated_images/`: **phải chép** ảnh được chọn vào dự án, không để dự án trỏ ra ngoài.
- Nơi lưu và quy cách giống asset của owner: frame nhân vật vào `assets/characters/{id}/frames/` đúng README 2.2 / 17.4 (384×384, chân y = 336, tâm x = 192, vẽ hướng phải, tên `{id}_{animation}_{NNN}.png`); chân dung vào `assets/characters/{id}/portrait/`; UI, nền, splash vào `assets/ui/` hoặc `assets/backgrounds/`.
- Ảnh tham chiếu nhân vật: luôn đưa ảnh gốc của owner vào làm tham chiếu để giữ đúng thiết kế (Enkiba: `assets/characters/char_fire_01/portrait/`).
- **Frame nhân vật: mỗi lần MỘT animation, owner duyệt từng cái** (owner 2026-11-13). Đọc `docs/prompts/codex_frames/PROMPT_GOC.md` (prompt gốc của owner, chuyển thể) và `docs/prompts/codex_frames/{id}/00_PHAN_TICH.md`, rồi làm theo phiếu `docs/prompts/codex_frames/{id}/NN_{anim}.md`: tạo ảnh → `tools/frames/slice_strip.py` (animation khác idle: `--like idle`) → `art_review/{id}/{anim}/` (không vào git, không vào game) → `tools/frames/check_frames.py` phải ĐẠT → **dừng, gửi owner `_preview/`**. Chỉ khi owner trả lời "duyệt {anim}" mới chạy `tools/frames/approve_frames.py` (chép vào assets, cập nhật manifest, ghi ASSET_LICENSES 2.1), chạy test, ghi nhật ký, commit. Số frame / fps của đòn đánh tính từ `data/skills/` — không tự đổi; sửa phiếu ở `tools/frames/jobs/{id}.json` rồi chạy `gen_prompts.py`.
- Không tạo ảnh bắt chước nhân vật, logo, thương hiệu hay phong cách nhận diện được của bên thứ ba.
- **Ghi từng file** vào `docs/ASSET_LICENSES.md` mục 2.1 (file, công cụ + model, prompt rút gọn, ảnh tham chiếu, ngày). Không ghi thì không được commit.
- Không ghi đè asset đã có; tạo bản `-v2`.
- Phát hành: Steam và một số store bắt buộc khai báo nội dung AI tạo (xem `docs/OWNER_ASSET_CHECKLIST.md` mục A).

### VFX từ pixelfx

- Thư viện ở `tools/pixelfx/` (MIT, có `.gdignore` nên Godot không quét). Nguồn và phạm vi chép: `tools/pixelfx/UPSTREAM.md`.
- Skill hướng dẫn: `.agents/skills/pixelfx/SKILL.md` (Codex), `.claude/skills/pixelfx/SKILL.md` (Claude). Khi skill bảo "clone pixelfx", **không clone**: dùng `tools/pixelfx/` có sẵn, chạy lệnh trong thư mục đó, ví dụ `node tools/render.mjs fire/fire-ring --sheet`.
- Đầu ra `tools/pixelfx/records/` không vào git. Chỉ chép sprite sheet **thật sự dùng** sang `assets/vfx/pixelfx/<category>/` và ghi từng file vào `docs/ASSET_LICENSES.md`.
- Không ship hiệu ứng có vẽ hình nộm (dummy) của pixelfx; chỉ dùng phần hiệu ứng.
- Hiệu ứng pixelfx nhỏ (vd 224×128) so với nhân vật cao ~256 px: phóng to bằng lọc nearest, không nén.

## 5. Nhật ký và báo cáo

Sau mỗi task, thêm mục vào cuối `docs/DEVELOPMENT_LOG.md`:

```
## YYYY-MM-DD — M{n}-{k} Tên task
- **Milestone / task:**
- **Trạng thái:** IMPLEMENTED | TESTED | VERIFIED | BLOCKED
- **File tạo/sửa:**
- **Đã chạy:** (lệnh thật)
- **Kết quả thật:** (số liệu, mã thoát; không suy đoán)
- **Hạn chế đã biết:**
```

`VERIFIED` chỉ khi đã quan sát kết quả và có bằng chứng (vd owner thử bằng mắt).

## 6. Quyết định đang có hiệu lực

- **Tự chủ chi tiết nhỏ** (owner, 2026-11-12): agent tự quyết chi tiết kỹ thuật; **không hỏi** owner về màu sắc, tên biến, cấu trúc folder, kích thước nút, số frame animation, thông số cân bằng nhỏ. Chọn phương án hợp lý, ghi vào nhật ký mục "Quyết định Claude/Codex chọn", rồi làm tiếp. Chỉ hỏi khi là quyết định lớn hoặc cần dữ liệu chỉ owner có.

- **Android hoãn** (owner, 2026-11-11): build/thử trên Windows. Vẫn giữ code đa nền tảng (cảm ứng, phím Back, ETC2/ASTC). Nhắc owner làm lại Android trước M2-4, chậm nhất trước M7.
- **Nhắc owner thử trong Godot** trước các task ở bảng "Mốc owner nên mở Godot để thử" cuối `docs/IMPLEMENTATION_ROADMAP.md` (M2-3, M3-5/M3-7, M4-4/M4-7, M6, M7).
- Gacha: banner nhân vật, tiếp tế vũ khí / vết thánh và lượt x10 miễn phí đầu tiên (chắc chắn Kael) theo số của owner (2026-11-12/13) sinh bằng `tools/gen_banner_data.py`; không tự đặt tỉ lệ (OWNER_ASSET_CHECKLIST A2). Trang bị: 1 vũ khí (theo loại vũ khí của nhân vật) + 3 vết thánh Đầu / Thân / Chân. Cấp nhân vật ≤ **cấp người chơi** (người quản lý, không có hình; lên cấp qua nhiệm vụ, phó bản; code gọi `account` / `captain_*`).
- Script UI nằm trong scene màn chơi (ResultScreen, PauseMenu, SettingsPanel...) lấy autoload qua `UiKit.autoload("Tên")`, vì scene đó còn được nạp bằng `--script`.
- Sửa file có tiếng Việt bằng script Python: ghi script ra file rồi chạy `python -X utf8 file.py`; **không** dán qua heredoc stdin (hỏng dấu, đã làm mất dữ liệu một lần).
- Q1–Q6 (công thức sát thương, chí mạng, debuff, trạng thái, phạm vi slice, revive): xem bảng trong `docs/DEVELOPMENT_LOG.md` mục M0-2.

## 7. Làm việc chung giữa nhiều agent

- Codex và Claude Code có thể cùng làm trên repo này. **Không chạy hai agent sửa cùng lúc** trên cùng thư mục; xong việc thì commit rồi mới chuyển.
- Commit nhỏ, mỗi task một commit, thông điệp tiếng Anh dạng `M{n}-{k}: ...`. Không push, không đổi lịch sử git nếu owner chưa yêu cầu.
- Không sửa `addons/gdUnit4/` và `tools/pixelfx/` (code bên thứ ba); muốn đổi thì ghi lý do vào nhật ký.
- Không commit `build/`, `reports/`, `.godot/`, `tools/pixelfx/records/`.
