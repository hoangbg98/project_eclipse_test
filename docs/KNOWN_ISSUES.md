# Việc tồn đọng trước khi phát hành

> Lập ngày 2026-11-12 ở Milestone 8. Cập nhật khi đóng hoặc thêm mục.
> Trạng thái test lúc lập: GdUnit4 402/402, 5 test khói đạt (`tools\run_tests.ps1`).

## A. Chờ owner (Claude / Codex không tự làm được)

| # | Việc | Chặn gì | Ghi chú |
|---|---|---|---|
| A1 | **Chơi thử bằng tay** Màn 1 và boss trong Godot (F5) | Xác nhận cảm giác đòn, độ khó, thời lượng 3–5 phút | Chưa ai chơi hết màn; mọi thứ mới qua test tự động và 6 ảnh chụp. Mốc thử: M3-7, M4-4/M4-7, M6, M7 |
| A2 | **Chiêu mộ**: đã có banner nhân vật + tiếp tế theo số owner; còn chờ owner xác nhận nhân vật đề cử (đang là Aether) và làm hướng dẫn dùng lượt x10 miễn phí (Kael) | Tab Chiêu mộ, hướng dẫn | `data/banners/`, `data/tutorial/starter_pull.tres` |
| A3 | **Hình nhân vật**: frame animation Aether (rồi Kael, Lyra) | Game vẫn dùng viên nang placeholder | Đã có 64 bộ phận Aether trong `assets/characters/char_fire_01/rig_parts/`; prompt cho Codex ở `docs/prompts/CODEX_AETHER_FRAMES.md` |
| A4 | **Âm thanh**: 3 bài nhạc + 13 SFX | Game im lặng | Tên file chờ sẵn ở OWNER_ASSET_CHECKLIST D1 |
| A5 | **Font** có đủ dấu tiếng Việt + giấy phép; art UI, nền màn, tile, VFX | Giao diện dùng mặc định của Godot | |
| A6 | **Android**: cài JDK/SDK, build APK, thử trên máy thật | AT-PLT-02, AT-BOS-02 (đọc telegraph trên điện thoại) | Hoãn theo quyết định 2026-11-11; nhắc lại trước khi phát hành |
| A7 | ~~Đổi tên nhân vật~~ — **xong** 2026-11-13: Enkiba, Kazeyumi, Raikiba, Hikarine, Yomigari, Iwagane (tên cũ chỉ còn trong tài liệu thiết kế và chú thích code) | Công khai | `localization/*.po` |
| A8 | **Khai báo nội dung AI** trên store, kiểm tra điều khoản thương mại của công cụ tạo ảnh | Nộp lên store | OWNER_ASSET_CHECKLIST mục A |
| A9 | Xác nhận các **số khởi điểm** Claude đặt | Cân bằng | Chỉ số nhân vật, quái, boss, đường EXP, giá cường hóa, thưởng màn: đều nằm trong `data/`, có ghi `metadata/source` |

## B. Hạn chế đã biết trong code (làm tiếp được không cần owner)

| # | Hạn chế | Mức | Ở đâu |
|---|---|---|---|
| B1 | Chỉ có 1 loại quái thường (slime) và 1 boss; quái chưa nhảy / đi vòng qua bậc | Nội dung | `scripts/enemies/` |
| B2 | Raikiba (Kael), Kazeyumi (Lyra) mới có đòn thường, né, vào sân (slice Q5); Hikarine, Yomigari, Iwagane chỉ có hồ sơ tạm — Iwagane đang là nhân vật đề cử của banner đầu | Phạm vi | `data/skills/`, `data/characters/` |
| B3 | 12 / 15 phản ứng chỉ test qua resolver vì 3 nhân vật kia chưa có Kĩ năng vào sân | Kiểm thử | `tests/unit/party/test_reactions.gd` |
| B4 | Tên Lyra bay thẳng ngang, chưa tự nhắm ±25°; chuỗi đòn Kael reset 0.8 s (đặc tả 0.7 s) | Nhỏ | `tools/gen_kael_lyra_data.py`, `SkillRunner.COMBO_RESET_SEC` |
| B5 | Chưa có animation vào sân / ra sân, VFX thật; vùng đòn hiện bằng đa giác màu | Hình ảnh | chờ A3, A5 |
| B6 | Menu chưa áp lề an toàn (mới áp cho HUD trận); chưa thử tỉ lệ 21:9 | AT-PLT-03 | `UiKit.apply_safe_area` |
| B7 | Chưa có tùy chọn đổi vị trí icon dự bị và joystick cố định (README 15.6, OD-6) | Tùy chọn | `SettingsPanel` |
| B8 | Chưa có danh sách kho đồ riêng, màn chọn màn riêng, nhiệm vụ (quests), điều kiện mở khóa | Tính năng | Hub |
| B9 | Chưa tự lưu định kỳ trong màn; thoát giữa màn mất tiến độ màn đó (có hỏi xác nhận) | Thiết kế | `StageController` |
| B10 | Cấp kỹ năng chưa có cách nâng (hệ số 6% mỗi cấp đã có trong công thức) | Tính năng | `Progression` |
| B11 | Checksum save chỉ chống hỏng file / sửa tay đơn giản, không chống gian lận | Chấp nhận (game offline) | `SaveStore` |
| B12 | Màn thử nghiệm cũ (`test_stage`) không có menu Tạm dừng; debug overlay dài đè lên HUD ở cửa sổ hẹp | Chỉ bản debug | F3 để ẩn |
| B13 | Đổi ngôn ngữ trong Hub: nhãn dựng bằng code ở tab khác chỉ đổi khi mở lại tab | Nhỏ | `hub.gd` |
| B14 | Bản Release (`Windows Release`) chưa build thử; preset loại `*placeholder_*` nên cần art thật trước | Phát hành | `export_presets.cfg` |

## C. Đã soát, không phải lỗi

- Khi tắt ngang bản build console, engine in "Unreferenced static string": thông báo dọn dẹp của Godot, không ảnh hưởng game.
- `ERROR: Parse JSON failed` trong log test: do test cố ý nạp file JSON hỏng (`test_broken_json_is_reported`).
- `Remote Debugger: Unable to connect` khi chạy GdUnit4 headless: do tham số `--remote-debug tcp://127.0.0.1:0` theo hướng dẫn của GdUnit4.
