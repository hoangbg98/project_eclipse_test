"""Sinh phiếu prompt cho Codex, mỗi animation một file, từ tools/frames/jobs/{id}.json + dữ liệu game.

  python -I tools/frames/gen_prompts.py char_fire_01

Ghi docs/prompts/codex_frames/{id}/README.md (quy trình + bảng trạng thái) và NN_{anim}.md (phiếu dán cho Codex).
Chạy lại sau khi sửa phiếu, đổi thời gian kỹ năng hoặc duyệt xong một animation (để cập nhật trạng thái).
"""
import io
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import frame_jobs as F  # noqa: E402

COMMON_EN = """2D side-scrolling action game sprite strip of the SAME character as the reference images: {design}
Keep the exact design, proportions (chibi, big head, short limbs), colors, dark outline thickness and colour (2-3 px), and 2-3 tone cel shading of the references.
The older idle reference frames are the ground truth ONLY for the side view, line art, proportions and colors; IGNORE the sword on their back - in your frames the sword is always in the hand.
Do NOT redesign: same hair, face, eyes, outfit, armor, accessories and sword; no added or removed details.
The character faces RIGHT in every frame, full body visible, same scale in every frame.
One single horizontal row of exactly {n} poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: {bg}. No ground line, no shadow, no text, no numbers, no frame borders.
No visual effects (no fire trails, slash arcs, sparks, glow, speed lines): character and sword only."""

BG_TRANSPARENT = "fully transparent"
BG_CHROMA = "solid flat magenta #FF00FF everywhere outside the character (used as a chroma key)"


def status(cid, anim):
    m = F.load_manifest(cid)
    if int(m["animations"].get(anim, {}).get("frames", 0)) > 0:
        return "Đã duyệt — **cần làm lại**" if F.load_jobs(cid)["animations"][anim].get("redo_reason") else "Đã duyệt"
    d = F.review_dir(cid, anim)
    if os.path.isdir(d) and any(f.endswith(".png") for f in os.listdir(d)):
        return "Chờ owner duyệt"
    return "Chưa làm"


def card(cid, jobs, idx, anim):
    job = jobs["animations"][anim]
    p = F.plan(cid, anim)
    rp = "assets/characters/%s/" % cid
    refs = list(jobs["refs_always"]) + [[rp + r if not r.startswith("assets/") else r, why] for r, why in job.get("refs", [])]
    calls = p["calls"]
    lines = ["# Phiếu %02d — %s / `%s`" % (idx, jobs["display_name"], anim), "",
             "> Sinh tự động bởi `tools/frames/gen_prompts.py` từ `tools/frames/jobs/%s.json` và `data/skills/`." % cid,
             "> Sửa phiếu ở file JSON rồi chạy lại, không sửa tay file này.", ""] + (
             ["> **CẦN LÀM LẠI:** " + job["redo_reason"], ""] if job.get("redo_reason") else []) + [
             "## Thông số (khớp thời gian trong game)", "",
             "| Mục | Giá trị |", "|---|---|",
             "| Thư mục chờ duyệt | `art_review/%s/%s/` |" % (cid, anim),
             "| Số frame | **%d** (tạo trong %d lần, mỗi lần %s) |" % (p["frames"], len(calls),
                                                                  ", ".join("frame %03d–%03d" % c for c in calls)),
             "| fps / lặp | %d fps, %s |" % (p["fps"], "lặp liền mạch" if p["loop"] else "không lặp"),
             "| Thời lượng | %s ms%s |" % (int(p["duration_ms"]), (" — khởi động / hiệu lực / hồi phục " + p["timing"]) if p["timing"] else ""),
             "| Frame trúng đòn | %s |" % (", ".join("%03d" % i for i in p["active_frames"]) or "—"),
             "| Kiếm | %s |" % ("**đeo sau lưng** như idle đã duyệt" if p["sword"] == "sheathed" else "**cầm trong tay** (đã rút sẵn từ frame đầu)"),
             "| Đứng đất | %s |" % ("có: chân ở y = 336 mọi frame" if p["grounded"] else "không: frame thấp nhất chạm y = 336, frame khác giữ độ cao tương đối"),
             "", "**Động tác:** " + job["motion_vi"], "",
             "## Ảnh đính kèm cho Codex", "",
             "| File | Dùng để |", "|---|---|"]
    lines += ["| `%s` | %s |" % (r, why) for r, why in refs]
    if any(p["phases"]):
        names = {"startup": "Khởi động (lấy đà)", "active": "Hiệu lực (đánh trúng — pose đọc rõ, giữ một nhịp)", "recovery": "Hồi phục (thu về)"}
        lines += ["", "## Giai đoạn từng frame", "", "| Frame | Giai đoạn |", "|---|---|"]
        lines += ["| %03d | %s |" % (i, names[ph]) for i, ph in enumerate(p["phases"])]
    lines += ["", "## Prompt dán cho Codex", "", "```text"]
    lines += [
        "Việc: tạo frame animation `%s` cho %s (%s), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo)," % (anim, jobs["display_name"], cid),
        "docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/%s/00_PHAN_TICH.md rồi phiếu" % cid,
        "docs/prompts/codex_frames/%s/%02d_%s.md. Giữ đúng ngoại hình model gốc, kiếm theo mục Kiếm của phiếu." % (cid, idx, anim),
        "",
        "1. Tạo ảnh bằng skill imagegen, %d lần gọi (%s). Mỗi lần: một hàng ngang đúng số pose của lần đó," % (
            len(calls), ", ".join("%d pose" % (b - a + 1) for a, b in calls)),
        "   dùng prompt ảnh tiếng Anh bên dưới (nhiều lần gọi: thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;",
        "   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.",
        "2. Chép các dải đã chọn vào art_review/%s/%s/_strips/ rồi cắt:" % (cid, anim),
        "   python -I tools/frames/slice_strip.py %s %s <dải 1> [<dải 2> ...]%s [--chroma FF00FF]" % (cid, anim, "" if anim == "idle" else " --like idle"),
        ("   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame %d, cao %.2f× lúc đứng; sai thì thêm --ref-frame / --ref-ratio)"
         % (p["ref_frame"], p["ref_ratio"])) if anim != "idle" else "   (idle: chiều cao đứng 280 px)",
        "3. Ghi art_review/%s/%s/meta.json: {\"tool\": \"Codex imagegen\", \"model\": \"<model>\"," % (cid, anim),
        "   \"prompt\": \"<prompt rút gọn>\", \"refs\": [<ảnh tham chiếu đã đính kèm>], \"date\": \"YYYY-MM-DD\"}",
        "   (giữ các khóa scale/strips mà slice_strip.py đã ghi).",
        "4. Kiểm tra: python -I tools/frames/check_frames.py %s %s — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi." % (cid, anim),
        "5. Tự soát theo danh sách trong phiếu (mục Tự kiểm tra). Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.",
        "6. DỪNG: gửi tôi art_review/%s/%s/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ." % (cid, anim),
        "   KHÔNG chép vào assets/, KHÔNG sửa frames_manifest.json, KHÔNG commit. Chờ tôi trả lời \"duyệt %s\"." % anim,
        "7. Khi tôi duyệt: python -I tools/frames/approve_frames.py %s %s%s, chạy" % (cid, anim, " --replace" if job.get("redo_reason") else ""),
        "   powershell -ExecutionPolicy Bypass -File tools\\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,",
        "   commit \"Art: %s %s frames (AI)\". Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra." % (jobs["display_name"], anim),
        "```", "",
        "## Prompt ảnh (tiếng Anh, mỗi lần gọi)", "", "```text",
        COMMON_EN.format(design=jobs["design_en"], n=str(p["frames"]) if len(calls) == 1 else "{n}", bg=BG_TRANSPARENT), "",
        "Animation: " + job["prompt_en"],
    ]
    if len(calls) > 1:
        lines.append("This call: poses {a}–{b} of %d (describe only this part of the motion; continue exactly from the attached previous strip)." % p["frames"])
    lines.append("Sword: " + ("the sword stays SHEATHED on the back, hilt above the near shoulder, exactly as in the idle reference frames."
                              if p["sword"] == "sheathed" else
                              "the sword is DRAWN and held in the hand in front of the body in every pose (it is not on the back); keep its exact flame design."))
    if any(p["phases"]):
        def span(name):
            idx_ = [i + 1 for i, ph in enumerate(p["phases"]) if ph == name]
            return "%d-%d" % (idx_[0], idx_[-1]) if idx_ else "none"
        lines.append("Phase map (poses counted from 1): wind-up %s, impact %s (clear extended pose, readable silhouette, brief hold), recovery %s." % (
            span("startup"), span("active"), span("recovery")))
    if p["active_frames"]:
        lines.append("Impact poses (sword fully extended at the moment of the hit): poses %s of %d, counting from 1." % (
            ", ".join(str(i + 1) for i in p["active_frames"]), p["frames"]))
    if p["loop"]:
        lines.append("Looping animation: the last pose must lead smoothly back into the first pose.")
    lines += ["```", "", "## Tự kiểm tra trước khi gửi owner", "",
              "1. Mọi frame còn giống hoàn toàn ảnh gốc (tóc, mặt, áo, giáp vai, găng, ủng, kiếm, màu)?",
              "2. Tỉ lệ chibi giữ nguyên, không bộ phận nào phình / co / biến dạng?",
              "3. Nét viền, bảng màu, kiểu đổ bóng đồng nhất giữa các frame?",
              "4. Động tác đọc rõ ở cỡ nhỏ, có lấy đà – đánh – thu về; bóng đen từng pose phân biệt được?",
              "5. `check_frames.py` ĐẠT: chân ở 336, tâm 192, không bị cắt mép?",
              "6. `anim_flip.gif` (lật trái) vẫn đúng: kiếm không nhảy tay, chi tiết lệch một bên nhất quán?",
              "7. Không xuyên vật thể, tay / chân gần – xa camera đúng lớp?",
              "8. Không vẽ hiệu ứng (lửa, vệt chém, tia sáng) vào frame nhân vật?", ""]
    return "\n".join(lines)


def main(argv=None):
    cid = (argv or sys.argv[1:])[0]
    jobs = F.load_jobs(cid)
    out = os.path.join(F.ROOT, "docs", "prompts", "codex_frames", cid)
    os.makedirs(out, exist_ok=True)
    rows = []
    for idx, anim in enumerate(jobs["order"], 1):
        name = "%02d_%s.md" % (idx, anim)
        with io.open(os.path.join(out, name), "w", encoding="utf-8", newline="\n") as f:
            f.write(card(cid, jobs, idx, anim))
        p = F.plan(cid, anim)
        rows.append("| %02d | [`%s`](%s) | %d | %d | %s | %s |" % (idx, anim, name, p["frames"], p["fps"],
                    ", ".join("%03d" % i for i in p["active_frames"]) or "—", status(cid, anim)))
    readme = [
        "# Frame %s (%s) — làm từng animation, owner duyệt từng cái" % (jobs["display_name"], cid), "",
        "> Sinh bởi `python -I tools/frames/gen_prompts.py %s`. Bảng trạng thái cập nhật khi chạy lại." % cid, "",
        "## Quy trình", "",
        "Đọc trước: [`../PROMPT_GOC.md`](../PROMPT_GOC.md) (prompt gốc chuyển thể từ file của owner) và [`00_PHAN_TICH.md`](00_PHAN_TICH.md) (phân tích model).", "",
        "1. Owner mở Codex trên PC tại `C:\\Dev\\PROJECT_ECLIPSE`, mở phiếu của animation kế tiếp (bảng dưới, theo thứ tự),",
        "   kéo các ảnh tham chiếu ghi trong phiếu vào khung chat, dán khối **Prompt dán cho Codex**.",
        "2. Codex tạo ảnh → `slice_strip.py` cắt về canvas chuẩn trong `art_review/` → `check_frames.py` kiểm và tạo",
        "   `_preview/sheet.png`, `anim.gif`, `anim_flip.gif` → **dừng, gửi owner xem**. Chưa có gì vào game.",
        "3. Owner xem: đạt thì trả lời `duyệt <animation>`; chưa đạt thì chỉ ra frame cần sửa (vd \"frame 003 kiếm đổi tay\").",
        "4. Sau khi duyệt, Codex (hoặc Claude) chạy `approve_frames.py`: chép vào `assets/characters/%s/frames/`," % cid,
        "   cập nhật `frames_manifest.json`, ghi `docs/ASSET_LICENSES.md` mục 2.1, chạy test, ghi nhật ký, commit.",
        "5. Mở Godot (F5 → Màn thử nghiệm) xem trong game. Muốn thay bản đã duyệt: `approve_frames.py ... --replace`",
        "   (bản cũ chuyển sang `art_review/%s/_replaced/`, không xóa)." % cid, "",
        "`slice_strip.py --like idle` canh chiều cao theo idle trong assets (idle cũ vẫn đo được ~281 px; làm lại idle trước để có bản chuẩn kiếm cầm tay).",
        "Hiệu ứng (lửa, vệt kiếm, phượng hoàng, cut-in) làm riêng ở `assets/vfx/`, không vẽ vào frame nhân vật.",
        "Thư mục `art_review/` không vào git và không vào game (`.gdignore`).", "",
        "## Danh sách animation", "",
        "| # | Animation | Frame | fps | Frame trúng đòn | Trạng thái |", "|---|---|---|---|---|---|"] + rows + [
        "", "Số frame / fps của đòn đánh tính từ thời gian kỹ năng (`data/skills/%s/`) để hình khớp hitbox." % cid,
        "Walk, guard, victory, death chưa có trạng thái trong game nên chưa có phiếu.",
        "Enkiba **luôn rút kiếm** (kiếm cầm tay ở mọi frame, owner 2026-11-13): xem `00_PHAN_TICH.md`.", ""]
    with io.open(os.path.join(out, "README.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(readme))
    print("Đã ghi %d phiếu vào %s" % (len(rows), out))


if __name__ == "__main__":
    main()
