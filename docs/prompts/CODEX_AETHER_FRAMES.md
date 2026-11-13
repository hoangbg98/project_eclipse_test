# (Thay thế) Prompt frame Aether / Enkiba

Bản prompt một khối cũ đã được thay bằng quy trình **từng animation, owner duyệt từng cái** (2026-11-13):

- Danh sách + quy trình: [`codex_frames/char_fire_01/README.md`](codex_frames/char_fire_01/README.md)
- Mỗi animation một phiếu (`01_idle.md`, `02_run.md`, …): thông số khớp thời gian kỹ năng, ảnh tham chiếu cần
  đính kèm, prompt dán cho Codex, prompt ảnh tiếng Anh, danh sách tự kiểm tra.
- Công cụ: `tools/frames/` (`gen_prompts.py`, `slice_strip.py`, `check_frames.py`, `approve_frames.py`).
