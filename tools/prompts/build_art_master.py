"""Gộp mọi prompt tạo ảnh game thành một file: docs/prompts/ART_MASTER.md (owner 2026-11-15).

Chạy (thư mục gốc dự án):  python -X utf8 -I tools/prompts/build_art_master.py

Đọc thẳng data của game để lập danh sách ảnh cần làm (và đánh dấu ảnh đã có trong dự án):
  data/story/ch01_*.json          — ô truyện tranh (tên ảnh, đa giác → kích thước)
  data/story/chapters.json        — tranh map chương + thẻ chương
  data/stages/*.json (backdrop)   — ảnh nền 3 lớp từng màn
rồi nối các tài liệu prompt chi tiết (giữ nguyên nội dung, hạ hai cấp tiêu đề):
  docs/prompts/characters/HENCHMAN_DESIGN.md, docs/prompts/story/CH01_PANELS.md,
  docs/prompts/story/CHAPTER_ART.md, docs/prompts/stages/STAGE_*_BACKGROUND.md
Chạy lại sau khi sửa kịch bản / thêm màn / thêm ảnh để file tổng luôn khớp.
"""
import datetime
import glob
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = "docs/prompts/ART_MASTER.md"


def res(p):
    return os.path.join(ROOT, p.replace("res://", ""))


def exists(p):
    return os.path.exists(res(p))


def load(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return json.load(f)


def read(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return f.read()


def demote(md):
    """Hạ mọi tiêu đề markdown hai cấp để nằm dưới mục "## N." của file tổng (bỏ qua khối code)."""
    out, code = [], False
    for line in md.split("\n"):
        if line.startswith("```"):
            code = not code
        if not code and re.match(r"#{1,4} ", line):
            line = "##" + line
        out.append(line)
    return "\n".join(out)


def mark(p):
    return "✅ đã có" if exists(p) else "⬜ chưa có"


def story_rows():
    rows = []
    for path in sorted(glob.glob(os.path.join(ROOT, "data/story/ch*_*.json"))):
        clip = json.load(open(path, encoding="utf-8"))
        if "pages" not in clip:
            continue
        for page in clip["pages"]:
            for p in page.get("panels", []):
                xs = [q[0] for q in p["poly"]]
                ys = [q[1] for q in p["poly"]]
                w, h = max(xs) - min(xs), max(ys) - min(ys)
                f = "%s/%s.png" % (clip["image_dir"], p["image"])
                rows.append((p["image"], f.replace("res://", ""), "%d×%d (2×: %d×%d)" % (w, h, w * 2, h * 2),
                             p["desc"], mark(f)))
    return rows


def chapter_rows():
    data = load("data/story/chapters.json")
    rows = []
    for c in data["chapters"]:
        for kind, key, size in (("map", "map_image", "%d×1080" % c["map_width"]), ("thẻ", "card_image", "380×600")):
            f = "%s/%s.png" % (data["art_dir"], c[key])
            rows.append(("Ch.%d %s" % (c["num"], kind), f.replace("res://", ""), size, mark(f)))
    return rows


def stage_rows():
    rows = []
    for path in sorted(glob.glob(os.path.join(ROOT, "data/stages/stage_*.json"))):
        st = json.load(open(path, encoding="utf-8"))
        for layer in st.get("backdrop", []):
            f = layer["image"]
            rows.append((str(st.get("code", "")), os.path.basename(f), f.replace("res://", ""), mark(f)))
    return rows


HEAD = """# Tổng hợp prompt tạo ảnh game — PROJECT ECLIPSE

> Sinh bởi `tools/prompts/build_art_master.py` lúc {now} — **không sửa tay**: sửa tài liệu gốc (đường dẫn ghi ở
> đầu mỗi phần) rồi chạy lại công cụ. Một file duy nhất để đưa cho Codex / ChatGPT tạo toàn bộ ảnh Chương 1.
> Ảnh AI được dùng trong bản phát hành (owner 2026-11-12) nhưng **mỗi file phải ghi vào `docs/ASSET_LICENSES.md`
> mục 2.1** trước khi commit; khai báo nội dung AI trên store.

## Mục lục

1. Cách dùng + prompt chính gửi Codex
2. Kinh thánh phong cách (style bible) và khóa nhân vật
3. Dòng thời gian liền mạch Chương 1 (trạng thái từng màn)
4. Danh sách ảnh cần làm ({total} ảnh, {done} đã có)
5. Phần A — Thiết kế nhân vật mới (Kẻ Đeo Mặt Nạ)
6. Phần B — Truyện tranh Chương 1 (ô truyện)
7. Phần C — Tranh map chương và thẻ chương
8. Phần D — Ảnh nền màn chơi (1-1 → 1-10)

## 1. Cách dùng

**Thứ tự làm** (ảnh sau dùng ảnh trước làm tham chiếu, nên đừng đảo):

| Lô | Nội dung | Lý do đứng ở đây | Từ khóa duyệt |
|---|---|---|---|
| 1 | Phần A: bảng thiết kế + chân dung Kẻ Đeo Mặt Nạ | Ô truyện và nền 1-8 cần tham chiếu hắn | `duyệt tay sai` |
| 2 | Phần D: nền 1-1 rồi 1-2 (thung lũng, Lò Mẹ lạnh) | Đặt bảng màu, Mặt Trời Khuyết, dáng Lò Mẹ cho mọi ảnh sau | `duyệt nền 1-1`, `duyệt nền 1-2` |
| 3 | Phần B: ô truyện `ch01_open` (15 ô) | Mở chương | `duyệt trang N` |
| 4 | Phần B: ô truyện `ch01_golem` (10 ô) | Cuối 1-1, lần đầu thấy tay sai | `duyệt trang N` |
| 5 | Phần D: nền 1-3 → 1-9 theo thứ tự | Mỗi màn tham chiếu màn trước | `duyệt nền 1-X` |
| 6 | Phần D: nền 1-10 + Phần B: ô `ch01_end` (14 ô) | Cùng nơi (cửa lò), làm liền để khớp | `duyệt nền 1-10`, `duyệt trang N` |
| 7 | Phần C: tranh map + thẻ Chương 1 | Tổng hợp cảnh đã chốt | `duyệt map 1` |

**Prompt chính gửi Codex** (đã liên kết dự án; dán nguyên khối):

```text
Việc: tạo ảnh game theo docs/prompts/ART_MASTER.md, làm theo bảng "Thứ tự làm" (mục 1), mỗi lần MỘT lô.
Đọc trước: AGENTS.md (mục 4 "Ảnh do AI tạo"), mục 2 và 3 của ART_MASTER.md (style bible, khóa nhân vật, dòng thời
gian liền mạch). Mục 4 liệt kê từng file cần làm, đường dẫn, kích thước và trạng thái; bỏ qua file đã "✅ đã có".
Với mỗi lô:
1. Tạo ảnh bằng image_gen. Luôn đính kèm ảnh tham chiếu nhân vật ghi ở từng prompt và ảnh đã duyệt của lô / ô / lớp
   liền trước (cùng cảnh). Thêm vào prompt câu nối liền mạch lấy từ mục 3 (giờ trong ngày, Lò Mẹ lạnh/cháy, gió,
   độ che của Mặt Trời Khuyết).
2. Chép ảnh gốc vào art_review/<loại>/<id>/raw/ (art_review không vào git). Cắt / co đúng kích thước ở mục 4; ô truyện
   giữ chủ thể trong vùng xám của placeholder; nền lặp ngang liền mạch, mid/near giữ alpha.
3. Ghép ảnh xem trước vào art_review/.../_preview/ (trang truyện 1920x1080 đặt ô theo đa giác; nền ghép 3 lớp lặp 2
   lần). DỪNG, gửi tôi đường dẫn preview, chờ từ khóa duyệt của lô (cột cuối bảng).
4. Khi tôi duyệt: chép vào đúng đường dẫn ở mục 4 (không ghi đè file đã có: tạo -v2 và hỏi), chạy
   C:\\Godot\\4.6.3\\Godot_v4.6.3-stable_win64_console.exe --headless --path . --import, ghi từng file vào
   docs/ASSET_LICENSES.md mục 2.1, chạy powershell -ExecutionPolicy Bypass -File tools\\run_tests.ps1 (mã thoát 0),
   chạy python -X utf8 -I tools/prompts/build_art_master.py (cập nhật trạng thái), ghi docs/DEVELOPMENT_LOG.md,
   commit (không push). Rồi mới sang lô kế.
Không vẽ chữ, bóng thoại, viền ô, logo, watermark. Không bắt chước nhân vật / thương hiệu bên thứ ba.
Trả lời tôi bằng tiếng Việt.
```

Không dùng Codex: mỗi phần bên dưới có prompt dán thẳng vào ChatGPT và mục "Thay tay" (đặt file đúng tên rồi
`--import`). Game tự thay placeholder khi có ảnh thật, không cần sửa code.

## 2. Style bible và khóa nhân vật

**Phong cách chung:** anime 2D, nét sạch, cel shading 2–3 tông, ánh sáng điện ảnh, hơi giảm bão hòa; tỉ lệ nhân vật
anime chuẩn (không chibi). Thế giới dưới **Mặt Trời Khuyết**: mặt trời cam nhạt bị khuyết một mảng tối. Không chữ,
không logo, không watermark. Nền màn chơi: vẽ phẳng nhìn ngang, đường chân trời ~60%, tương phản thấp để nhân vật nổi.

| Nhân vật | Khóa thiết kế | Ảnh tham chiếu trong dự án |
|---|---|---|
| Enkiba (lửa, kiếm) | Nam 16–19, tóc gai đỏ cam, mắt hổ phách, áo khoác ngắn đen viền lửa đỏ, giáp vai đỏ, áo trắng, quần đỏ, kiếm lưỡi cam vân lửa | `assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png` |
| Kazeyumi (gió, cung) | Nữ 16–19, tóc xanh ngọc buộc cao có lông vũ trắng, áo kem viền xanh, áo choàng ngắn xanh đậm, váy xếp ly, ống tên, cung gỗ quấn ruy băng | `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png` |
| Raikiba (sét, song dao) | Nam 16–19, tóc gai trắng bạc ánh vàng chanh, mắt xanh lục, áo cổ cao không tay xanh navy, quần túi hộp sọc vàng, găng hở ngón, hai dao cong răng cưa đen-vàng | `assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png` |
| NEO | Thiết bị AI nhỏ bằng bàn tay: vòng sáng cyan quanh lõi trắng, hai cung mảnh xoay, không mặt, không tay chân | (mô tả trong prompt) |
| Kẻ Đeo Mặt Nạ (tay sai, boss 1-10) | Giáp xám tro đường nối cam xỉn, mặt nạ đen trơn không mắt miệng, áo choàng than rách, huy hiệu vòng trắng-đen, lưỡi móc đen | Phần A (vẽ trước) |
| Golem Đá Cổ (boss 1-1) | Khối đá khổng lồ, khe nứt sáng nhẹ, hai mắt cam đỏ; khi đổ thành đá vỡ nằm trước cửa lò tới hết chương | ô truyện `ch01_open_10`, `ch01_golem_01` |
| Cặn tro (quái) | Khối tro xám nhỏ như slime, đốm than li ti; Cặn lớn: to, nâu xám, nặng nề | ô truyện `ch01_open_12` |
| Dấu ba vòng đá | Ba vòng đá chồng nhau khắc nổi (dấu xưởng thủ vệ) — giống nhau ở lưng golem, hầm 1-3, cầu 1-6, trạm 1-7 | ô truyện `ch01_end_11` |
| Vòng trắng-đen (kênh 00) | Vòng nửa trắng nửa đen — mảnh ấn trong golem, cọc ấn 1-5, cột kênh 1-8, huy hiệu tay sai | ô truyện `ch01_golem_05/06` |

## 3. Dòng thời gian liền mạch Chương 1

Cốt truyện (owner 2026-11-15): golem ở 1-1 chỉ là thủ vệ bị sai tới chặn đường; kẻ chủ mưu là **tay sai đeo mặt nạ**
(người mặc giáp của một Quản lý dưới trướng thủ lĩnh mã 00); Lò Mẹ chỉ cháy lại sau khi hạ hắn ở 1-10.

| Đoạn | Nơi | Giờ | Lò Mẹ | Gió / tro | Mặt Trời Khuyết | Ghi chú liền mạch |
|---|---|---|---|---|---|---|
| Clip `ch01_open` | Cửa thung lũng | Chiều mù | Lạnh tối | Không gió, tro rơi thẳng | Khuyết như thường | Vạch mờ tím Vùng Thực |
| 1-1 (boss golem) | Thung lũng → cửa lò | Chiều | Lạnh | Không gió | Như thường | — |
| Clip `ch01_golem` | Cửa lò | Chiều muộn | **Lạnh** | Không gió | Như thường | Golem đổ thành đá vỡ; đĩa trắng-đen thứ nhất; tay sai trên vách |
| 1-2 Làng Lò Than | Cửa thung lũng | Chiều muộn | Lạnh | Không gió | Như thường | Đèn, khói bếp le lói |
| 1-3 Hầm Than Ngầm | Dưới làng | (trong hầm) | Lạnh | — | — | Mạch lửa bị lấp đá mới; dấu ba vòng đá |
| 1-4 Vách Lò Mẹ | Vách cao | Chiều muộn | Lạnh | Không gió, cờ rủ | Như thường | Ống thông khí bị lấp |
| 1-5 Rừng Cây Chết | Sườn trên vách | Hoàng hôn sớm | Lạnh | Không gió | Che hơn một chút | Cọc ấn vòng trắng-đen |
| 1-6 Cầu Đá Treo | Vực cao | Hoàng hôn | Lạnh | Không gió | Che hơn | Cầu bị phá, dấu ba vòng đá |
| 1-7 Trạm Thủ Vệ | Trong trạm | (trong nhà) | — | — | — | Hốc lõi trống, vết cạy mới |
| 1-8 Trại Mặt Nạ | Hẻm đá | Chạng vạng tím | Bị hút nhiệt | Không gió | Che **nhiều** | Cột kênh trắng-đen; lưỡi móc đen |
| 1-9 Đường Về Cửa Lò | Đường mòn | **Đêm** | Gần tắt (4%) | Không gió, sương tím | Gần đầy (vành mảnh) | Thấy bóng người ở cửa lò |
| 1-10 Cửa Lò Mẹ (boss tay sai) | Cửa lò | **Đêm nhật thực** | 2% | Không gió | Vành sáng mảnh | Đá vỡ golem như clip `ch01_golem` |
| Clip `ch01_end` | Cửa lò → vách đá | Đêm | **Cháy lại** từ ô 05–06 | **Gió về** từ ô 07 | Vành sáng | Hai đĩa trắng-đen; ô 14 bóng Quản lý trên vách |

## 4. Danh sách ảnh cần làm

### Phần A — nhân vật

| Ảnh | File | Kích thước | Trạng thái |
|---|---|---|---|
{henchman}

### Phần B — ô truyện ({n_story} ô)

| Ô | File | Kích thước (1×, 2×) | Cảnh | Trạng thái |
|---|---|---|---|---|
{story}

### Phần C — map và thẻ chương

| Ảnh | File | Kích thước | Trạng thái |
|---|---|---|---|
{chapters}

### Phần D — nền màn chơi (3840×2160, lặp ngang)

| Màn | Lớp | File | Trạng thái |
|---|---|---|---|
{stages}
"""


def table(rows):
    return "\n".join("| " + " | ".join(str(c).replace("|", "/") for c in r) + " |" for r in rows)


def main():
    hm = [("Bảng thiết kế", "assets/characters/boss_henchman_01/design/boss_henchman_01_sheet.png", "1536×1024"),
          ("Chân dung", "assets/characters/boss_henchman_01/portrait/boss_henchman_01_portrait.png", "1024×1024")]
    hm_rows = [(a, f, s, mark(f)) for a, f, s in hm]
    st, ch, sd = story_rows(), chapter_rows(), stage_rows()
    all_marks = [r[-1] for r in hm_rows + st + ch + sd]
    head = HEAD.format(now=datetime.date.today().isoformat(), total=len(all_marks),
                       done=sum(1 for m in all_marks if m.startswith("✅")), n_story=len(st),
                       henchman=table(hm_rows), story=table(st), chapters=table(ch), stages=table(sd))
    parts = [head]
    parts.append("\n## 5. Phần A — Thiết kế nhân vật mới\n\n> Nguồn: `docs/prompts/characters/HENCHMAN_DESIGN.md`\n\n"
                 + demote(read("docs/prompts/characters/HENCHMAN_DESIGN.md")))
    panels = read("docs/prompts/story/CH01_PANELS.md")
    parts.append("\n## 6. Phần B — Truyện tranh Chương 1\n\n> Nguồn: `docs/prompts/story/CH01_PANELS.md` (sinh bởi "
                 "`tools/story/gen_story_clips.py`)\n\n" + demote(panels))
    parts.append("\n## 7. Phần C — Tranh map chương và thẻ chương\n\n> Nguồn: `docs/prompts/story/CHAPTER_ART.md` "
                 "(sinh bởi `tools/story/gen_chapters.py`)\n\n" + demote(read("docs/prompts/story/CHAPTER_ART.md")))
    def stage_order(p):                       # STAGE_01_BACKGROUND (1-1) trước STAGE_01_02 … STAGE_01_10
        m = re.match(r"STAGE_(\d+)(?:_(\d+))?_BACKGROUND", os.path.basename(p))
        return (int(m.group(1)), int(m.group(2) or 1)) if m else (999, 0)

    stages = sorted(glob.glob(os.path.join(ROOT, "docs/prompts/stages/STAGE_*_BACKGROUND.md")), key=stage_order)
    body = "\n## 8. Phần D — Ảnh nền màn chơi\n"
    for p in stages:
        rel = os.path.relpath(p, ROOT).replace("\\", "/")
        body += "\n> Nguồn: `%s`\n\n" % rel + demote(read(rel)) + "\n"
    parts.append(body)
    text = "\n".join(parts).rstrip("\n") + "\n"
    with open(os.path.join(ROOT, OUT), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("%s: %d ảnh (%d đã có), %d dòng" % (OUT, len(all_marks),
                                            sum(1 for m in all_marks if m.startswith("✅")), text.count("\n")))


if __name__ == "__main__":
    main()
