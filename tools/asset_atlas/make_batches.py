# Chia JSON seed (do scan_assets.py tạo) thành các lô <= 50 lệnh ghi cho ArtifactData "batch".
#
# Lần đầu (database trống):
#   python -X utf8 tools/asset_atlas/make_batches.py
# Đồng bộ lại khi site đã có dữ liệu người dùng (KHÔNG ghi đè yêu cầu, checklist, brief, bản tải lên):
#   1. ArtifactData list collection "assets" (limit 1000) với out_dir = build/asset_atlas/db
#   2. python -X utf8 tools/asset_atlas/make_batches.py --db build/asset_atlas/db
#
# Quy tắc gộp (--db): repo là nguồn sự thật cho ảnh trong repo (path, spec, các bản pv/), site là nguồn
# sự thật cho mọi thứ người dùng làm trên site (brief, yêu cầu, checklist, tag, lịch sử, bản tải lên).
# Trạng thái: repo "approved" (frame đã vào assets/) thắng; còn lại giữ trạng thái trên site.
import argparse, glob, json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
ap = argparse.ArgumentParser()
ap.add_argument("--out", default=os.path.join(ROOT, "build", "asset_atlas"))
ap.add_argument("--db", default=None, help="thư mục out_dir của ArtifactData list (chứa assets/<id>.json)")
ap.add_argument("--versions", default=None,
                help='JSON {"<doc_id>": version} chép từ kết quả ArtifactData list (bắt buộc khi có --db)')
args = ap.parse_args()
if args.db and not args.versions:
    raise SystemExit("Thiếu --versions: ghi bảng {doc_id: version} từ kết quả ArtifactData list ra file JSON.")
VERS = json.load(open(args.versions, encoding="utf-8")) if args.versions else {}
out = os.path.abspath(args.out)
seed = os.path.join(out, "seed")
merged_dir = os.path.join(out, "merged")
os.makedirs(merged_dir, exist_ok=True)

def load_db(d):
    """Đọc các file ArtifactData đã lưu; chấp nhận dạng {id, data, version} hoặc thân tài liệu trần."""
    res = {}
    if not d:
        return res
    for p in glob.glob(os.path.join(d, "**", "*.json"), recursive=True):
        doc = json.load(open(p, encoding="utf-8"))
        body = doc.get("data") if isinstance(doc.get("data"), dict) else doc
        aid = os.path.basename(p)[:-5]
        res[aid] = (body, doc.get("version") or VERS.get(aid))
    return res

def merge(repo, site):
    m = dict(repo)
    for k in ("brief", "requests", "qa", "exp", "tags", "history", "placeholder", "placeholder_note",
              "scene", "style", "category", "name", "project"):
        if k in site:
            m[k] = site[k]
    repo_srcs = {v.get("src") for v in repo.get("versions", [])}
    extra = [v for v in site.get("versions", []) if v.get("blob") or v.get("src") not in repo_srcs]
    # giữ nhãn/trạng thái người dùng đặt cho các bản repo
    site_by_src = {v.get("src"): v for v in site.get("versions", []) if v.get("src")}
    vs = []
    for v in repo.get("versions", []):
        sv = site_by_src.get(v.get("src"))
        vs.append({**v, "state": sv["state"]} if sv and "state" in sv else v)
    taken = {v["id"] for v in vs}
    n = max([int(str(x["id"])[1:]) for x in vs + extra if str(x.get("id", "")).startswith("v") and str(x["id"])[1:].isdigit()] or [0])
    for v in extra:
        if v["id"] in taken:
            n += 1
            v = {**v, "id": f"v{n}"}
        taken.add(v["id"])
        vs.append(v)
    m["versions"] = vs
    cur_site = site.get("current")
    if repo.get("status") == "approved" and site.get("status") != "approved":
        m["status"] = "approved"
        m["current"] = repo.get("current")
        if not repo.get("placeholder"):
            m["placeholder"], m["placeholder_note"] = False, ""
        m["versions"] = [{**v, "state": "current" if v["id"] == m["current"] else ("option" if v.get("state") == "current" else v.get("state"))} for v in vs]
        m["history"] = list(m.get("history", [])) + [{"at": repo["updated"], "text": "Đồng bộ repo: frame đã vào assets/, chuyển sang Đã duyệt"}]
    else:
        m["status"] = site.get("status", repo.get("status"))
        if cur_site and any(v["id"] == cur_site for v in vs):
            m["current"] = cur_site
    return m

db = load_db(args.db)
fs = sorted(f for f in os.listdir(seed) if f.endswith(".json") and not f.startswith("_"))
w = []
if not db:  # database trống: tạo luôn tài liệu dự án
    w.append({"op": "set", "collection": "projects", "doc_id": "eclipse", "file_path": os.path.join(seed, "_project_eclipse.json")})
changed = new = 0
for f in fs:
    aid = f[:-5]
    repo = json.load(open(os.path.join(seed, f), encoding="utf-8"))
    entry = {"op": "set", "collection": "assets", "doc_id": aid}
    if aid in db:
        site, ver = db[aid]
        body = merge(repo, site)
        strip = lambda d: json.dumps({k: v for k, v in d.items() if k != "updated"}, sort_keys=True, ensure_ascii=False)
        if strip(body) == strip(site):
            continue
        p = os.path.join(merged_dir, f)
        json.dump(body, open(p, "w", encoding="utf-8"), ensure_ascii=False)
        entry["file_path"] = p
        if not ver:
            raise SystemExit(f"Không có version cho {aid} trong --versions.")
        entry["if_version"] = ver
        changed += 1
    else:
        entry["file_path"] = os.path.join(seed, f)
        new += 1
    w.append(entry)

for old in glob.glob(os.path.join(out, "batch*.json")):
    os.remove(old)
for i in range(0, len(w), 50):
    with open(os.path.join(out, f"batch{i // 50}.json"), "w", encoding="utf-8") as fh:
        json.dump(w[i:i + 50], fh)
print(f"{new} mục mới, {changed} mục cập nhật, {len(w)} lệnh ghi, {(len(w) + 49) // 50} lô trong {out}")
