"""Đưa frame ĐÃ ĐƯỢC OWNER DUYỆT từ art_review/ vào game. Chỉ chạy khi owner nói rõ "duyệt <animation>".

  python -I tools/frames/approve_frames.py char_fire_01 idle [--replace]

Làm theo thứ tự, dừng ở lỗi đầu tiên (không thay đổi gì nếu lỗi):
1. check_frames.py phải ĐẠT cho thư mục chờ duyệt;
2. art_review/{id}/{anim}/meta.json phải có tool, model, prompt, refs, date (Codex ghi khi tạo ảnh);
3. thư mục assets/characters/{id}/frames/{anim}/ phải trống (AGENTS.md: không ghi đè asset). --replace chuyển
   bản cũ sang art_review/{id}/_replaced/{anim}_{giờ}/ trước khi chép bản mới (không xóa);
4. chép frame vào assets/, cập nhật frames_manifest.json (frames, fps, loop, frames_delivered);
5. thêm một dòng vào docs/ASSET_LICENSES.md mục 2.1 (bắt buộc với ảnh AI).
Sau đó: chạy tools/run_tests.ps1, ghi DEVELOPMENT_LOG, commit "Art: {tên} {anim} frames (AI)".
"""
import argparse
import datetime
import io
import json
import os
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_frames  # noqa: E402
import frame_jobs as F  # noqa: E402

META_KEYS = ["tool", "model", "prompt", "refs", "date"]
LICENSE_HEADER = "### 2.1 Ảnh do AI tạo"


def fail(msg):
    print("KHÔNG DUYỆT ĐƯỢC:", msg)
    return 1


def add_license_row(base, character_id, anim, frames, meta, display):
    p = os.path.join(base or F.ROOT, "docs", "ASSET_LICENSES.md")
    with io.open(p, encoding="utf-8") as f:
        lines = f.read().split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith(LICENSE_HEADER))
    # Bảng đầu tiên sau tiêu đề mục 2.1.
    head = next(i for i in range(start, len(lines)) if lines[i].startswith("| File"))
    end = head + 2
    while end < len(lines) and lines[end].startswith("|"):
        end += 1
    refs = ", ".join("`%s`" % os.path.basename(r) for r in meta["refs"])
    prompt = str(meta["prompt"]).replace("|", "/").replace("\n", " ")
    row = "| `assets/characters/%s/frames/%s/` (%d frame) — %s | %s / %s | %s | %s | %s | %s |" % (
        character_id, anim, frames, display, meta["tool"], meta["model"], prompt, refs, meta.get("author", "Codex"),
        meta["date"])
    body = [l for l in lines[head + 2:end] if not l.startswith("| — (chưa có)")]
    body = [l for l in body if ("/frames/%s/`" % anim) not in l or character_id not in l] + [row]
    lines[head + 2:end] = body
    with io.open(p, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("character_id")
    ap.add_argument("anim")
    ap.add_argument("--replace", action="store_true")
    ap.add_argument("--base")
    args = ap.parse_args(argv)
    cid, anim, base = args.character_id, args.anim, args.base

    p, src, errors, _, _ = check_frames.check(cid, anim, False, base)
    if errors:
        return fail("frame chờ duyệt chưa đạt kiểm tra: " + "; ".join(errors))
    meta_path = os.path.join(src, "meta.json")
    if not os.path.exists(meta_path):
        return fail("thiếu %s (tool, model, prompt, refs, date)" % meta_path)
    with io.open(meta_path, encoding="utf-8") as f:
        meta = json.load(f)
    missing = [k for k in META_KEYS if not meta.get(k)]
    if missing:
        return fail("meta.json thiếu: %s" % ", ".join(missing))

    dst = F.frames_dir(cid, anim, base)
    existing = [f for f in os.listdir(dst) if f.endswith(".png")] if os.path.isdir(dst) else []
    if existing and not args.replace:
        return fail("%s đã có %d frame. Không ghi đè; muốn thay thì owner xác nhận rồi chạy lại với --replace." %
                    (dst, len(existing)))
    if existing:
        stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        keep = os.path.join(base or F.ROOT, "art_review", cid, "_replaced", "%s_%s" % (anim, stamp))
        os.makedirs(keep, exist_ok=True)
        for f in os.listdir(dst):
            shutil.move(os.path.join(dst, f), os.path.join(keep, f))
        print("Bản cũ chuyển sang", keep)
    os.makedirs(dst, exist_ok=True)
    for i in range(p["frames"]):
        name = F.frame_name(cid, anim, i)
        shutil.copy2(os.path.join(src, name), os.path.join(dst, name))

    manifest = F.load_manifest(cid, base)
    spec = manifest["animations"].setdefault(anim, {"skill_key": None})
    spec.update(frames=p["frames"], fps=p["fps"], loop=p["loop"])
    manifest["frames_delivered"] = True
    with io.open(F.manifest_path(cid, base), "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
        f.write("\n")

    jobs = F.load_jobs(cid, base)
    add_license_row(base, cid, anim, p["frames"], meta, jobs.get("display_name", cid))
    meta["approved"] = datetime.date.today().isoformat()
    with io.open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
    print("ĐÃ DUYỆT %s / %s: %d frame, %d fps → %s" % (cid, anim, p["frames"], p["fps"], dst))
    print("Tiếp: powershell -ExecutionPolicy Bypass -File tools\\run_tests.ps1, ghi DEVELOPMENT_LOG, commit.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
