"""Xóa nền ô caro "giả trong suốt" vẽ sẵn trong ảnh (kiểu ảnh AI), giữ quầng sáng mờ, xuất PNG trong suốt.

  python -I tools/ui/remove_checker_bg.py <ảnh vào> <thư mục làm việc (ngoài dự án)>

Các bước (thư mục remove_checker_bg/), viết cho ảnh joystick owner 2026-11-14 (vòng HUD tâm (628, 424), bán kính
~400 px; ảnh khác cần sửa tâm / bán kính trong từng bước):
  1. joy_extract2: khớp lưới ô caro, phân loại ô sáng/tối TỪNG Ô (ảnh AI lệch nhịp), tách màu theo nền từng pixel.
  2. joy_extract5: trong đĩa kính màu (ảnh AI pha nền không đúng vật lý), đo biên độ ô caro theo ô so với ô kề,
     trừ đi; độ đục = 1 - biên độ/nửa chênh lệch nền.
  3. joy_final: sửa ô còn lệch + lọc giữ cạnh trong đĩa, bỏ mảnh lạ ngoài bán kính.
  4. joy_extract6: quầng ngoài đĩa, hồi quy bậc hai từng pixel (khớp độ cong quầng) + ghép với bước 3.
  5. joy_rim: làm mịn dải mép đĩa theo hệ cực (trung vị theo góc ±12°).
  6. joy_glow: lọc giữ cạnh nhẹ cho quầng, cắt khung vuông quanh tâm.
  7. joy_polish: quầng mờ ép về sắc xanh của nét sáng (hết vệt xám trên nền sáng).
Kết quả: <thư mục>/out/joystick_final.png → đưa vào tools/ui/split_joystick.py.
"""
import os
import subprocess
import sys

HERE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "remove_checker_bg")
src, work = sys.argv[1], sys.argv[2]
out = os.path.join(work, "out")
os.makedirs(out, exist_ok=True)
for step in ("joy_extract2", "joy_extract5", "joy_final", "joy_extract6", "joy_rim", "joy_glow", "joy_polish"):
    args = [out] if step in ("joy_rim", "joy_glow", "joy_polish") else [src, out]
    subprocess.run([sys.executable, "-I", "-X", "utf8", os.path.join(HERE, step + ".py")] + args, check=True)
print("xong:", os.path.join(out, "joystick_final.png"))
