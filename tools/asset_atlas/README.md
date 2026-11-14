# Asset Atlas — site quản lý và duyệt asset

Site: <https://claude.ai/artifact/7R1eRJDKYHj1PbH5mz5RSS> (artifact claude.ai, riêng tư; owner chia sẻ qua menu Share).

Site đọc dữ liệu từ database của artifact (collection `assets`, `projects`). Thư mục này giữ **mã nguồn trang** và
**script quét repo** để nạp / đồng bộ dữ liệu. Không chứa luật gameplay; Godot bỏ qua thư mục (`.gdignore`).

| File | Việc |
|---|---|
| `site/asset_atlas.html` | Mã nguồn trang (HTML + JS thuần, capability `db`, `assets`, `user`). |
| `scan_assets.py` | Quét `assets/`, `art_review/`, `frames_manifest.json`, `docs/ASSET_LICENSES.md` → ảnh preview + JSON seed. |
| `make_batches.py` | Chia seed thành lô ≤ 50 lệnh ghi; với `--db` thì gộp với dữ liệu đang có trên site. |

Đầu ra mặc định ở `build/asset_atlas/` (không vào git).

## Mỗi asset là gì

- **Frame nhân vật:** một animation của một giáp (vd `char_fire_01` · `idle`). Preview là dải frame ngang, mỗi frame
  192 px (một nửa 384). Bản trong `assets/.../frames/` → "Đã duyệt"; chỉ có trong `art_review/` → "Chờ duyệt";
  chưa có frame → "Chưa làm" + placeholder `placeholder_character_384.png`. Bản cũ trong `art_review/<id>/_replaced/`
  thành phiên bản "Đã loại"; bản `art_review` khác bản game thành "Option".
- **Ảnh đơn:** chân dung, splash, icon sảnh, joystick, banner Chiêu mộ, placeholder, VFX.
- **Bộ ảnh:** icon kỹ năng HUD theo giáp, bộ phận rig Enkiba (preview là tờ ghép).
- Tự kiểm lưu trong `versions[].auto`: kích thước, RGBA, 4 góc trong suốt, dòng chân thấp nhất (`baseline`, chân = giá trị + 1,
  chuẩn 336) và tâm x mỗi frame.
- `NO_UPLOAD` trong `scan_assets.py`: ảnh không có quyền dùng (nền sảnh tạm) — vẫn có mục nhưng không đưa ảnh lên.

## Đồng bộ lại sau khi repo thay đổi (cho agent)

1. `python -X utf8 tools/asset_atlas/scan_assets.py`
2. Publish lại trang **cùng URL** kèm ảnh preview: Artifact publish, `url` = link trên, `file_path` =
   `build/asset_atlas/site/asset_atlas.html`, `root` = `build/asset_atlas/site`, `files` = mọi `pv/*.png`
   (tối đa 255 file / lần). Không cần đổi `capabilities`.
3. Lấy dữ liệu đang có: ArtifactData `list`, collection `assets`, `query.limit` 1000, `out_dir` = `build/asset_atlas/db`.
4. Ghi bảng version từ kết quả bước 3 (mỗi dòng `"<id>" <version>`) ra `build/asset_atlas/versions.json`
   dạng `{"<id>": <version>}` (file trong `out_dir` không chứa version), rồi chạy
   `python -X utf8 tools/asset_atlas/make_batches.py --db build/asset_atlas/db --versions build/asset_atlas/versions.json`
5. Với mỗi `build/asset_atlas/batchN.json`: ArtifactData `batch` với `writes` = nội dung file.

Bước 4 **không ghi đè** brief, yêu cầu sửa, checklist, tag, lịch sử, phiên bản người dùng tải lên trên site.
Asset đã vào `assets/` (repo "Đã duyệt") sẽ chuyển sang "Đã duyệt" trên site. Không xóa mục nào: asset bị xóa khỏi repo
phải xóa tay trên database.

Lần nạp đầu (database trống) bỏ bước 3 và chạy `make_batches.py` không có `--db`.

## Giới hạn

- "Quay lại phiên bản" trên site chỉ ghi quyết định; file trong repo do agent cập nhật theo.
- Ảnh tải lên từ site nằm trong kho asset của artifact (`blob`), không tự về repo.
- Database tối đa 25 000 tài liệu, mỗi tài liệu 256 KiB; ảnh tải lên tối đa 20 MB / file.
