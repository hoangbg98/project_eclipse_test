# Quét asset PROJECT ECLIPSE -> ảnh preview + JSON seed cho site "Asset Atlas".
# Chạy ở thư mục gốc dự án:  python -X utf8 tools/asset_atlas/scan_assets.py [--out build/asset_atlas]
# Đầu ra (không vào git): <out>/site/asset_atlas.html, <out>/site/pv/*.png, <out>/seed/*.json
# Xem tools/asset_atlas/README.md.
import argparse, datetime, glob, hashlib, json, os, re, shutil
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
ap = argparse.ArgumentParser()
ap.add_argument("--out", default=os.path.join(ROOT, "build", "asset_atlas"))
OUT = os.path.abspath(ap.parse_args().out)
PV = os.path.join(OUT, "site", "pv")
SEED = os.path.join(OUT, "seed")
shutil.rmtree(PV, ignore_errors=True)
os.makedirs(PV, exist_ok=True)
os.makedirs(SEED, exist_ok=True)
for f in glob.glob(os.path.join(SEED, "*.json")):
    os.remove(f)
shutil.copy(os.path.join(os.path.dirname(os.path.abspath(__file__)), "site", "asset_atlas.html"),
            os.path.join(OUT, "site", "asset_atlas.html"))

# Ảnh không có quyền dùng (bên thứ ba): giữ mục trong danh sách nhưng không đưa ảnh lên site.
NO_UPLOAD = {"hub-bg-sky-garden"}

NOW = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
CHARS = {
    "char_fire_01": "Enkiba", "char_wind_01": "Kazeyumi", "char_lightning_01": "Raikiba",
    "char_light_01": "Hikarine", "char_dark_01": "Yomigari", "char_earth_01": "Iwagane",
}
FRAME = 192  # cạnh frame trong preview (một nửa 384)

def mtime(*paths):
    """Ngày sửa file mới nhất (UTC), để lần quét sau không đổi khi file không đổi."""
    t = max(os.path.getmtime(x) for x in paths)
    return datetime.datetime.fromtimestamp(t, datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def rel(p):
    return os.path.relpath(p, ROOT).replace("\\", "/")

def slug(s):
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")

# Prompt rút gọn từ ASSET_LICENSES mục 2.1
lic = {}
for line in open(os.path.join(ROOT, "docs", "ASSET_LICENSES.md"), encoding="utf-8"):
    m = re.match(r"\|\s*`([^`]+)`[^|]*\|\s*([^|]*)\|\s*([^|]*)\|", line)
    if m:
        lic[m.group(1).rstrip("/")] = (m.group(2).strip(), m.group(3).strip())

def lic_for(path):
    path = path.rstrip("/")
    return lic.get(path) or lic.get(path + "/") or None

def frame_files(d, cid, anim):
    fs = sorted(glob.glob(os.path.join(d, f"{cid}_{anim}_[0-9][0-9][0-9].png")))
    return fs

def files_hash(fs):
    h = hashlib.sha1()
    for f in fs:
        h.update(open(f, "rb").read())
    return h.hexdigest()

def analyze_frames(fs):
    """Kiểm tra tự động: kích thước, alpha, góc trong suốt, chân (baseline), tâm x."""
    sizes, base, cx, alpha_ok, corners = set(), [], [], True, True
    for f in fs:
        im = Image.open(f)
        sizes.add(im.size)
        if im.mode != "RGBA":
            alpha_ok = False
            im = im.convert("RGBA")
        a = im.getchannel("A")
        w, h = im.size
        for x, y in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
            if a.getpixel((x, y)) > 8:
                corners = False
        bbox = a.point(lambda v: 255 if v > 24 else 0).getbbox()
        if bbox:
            base.append(bbox[3] - 1)
            cx.append(round((bbox[0] + bbox[2]) / 2))
    s = sorted(sizes)
    return {
        "w": s[0][0] if s else None, "h": s[0][1] if s else None,
        "uniform": len(sizes) == 1, "rgba": alpha_ok, "corners_clear": corners,
        "baseline": base, "center_x": cx,
    }

def make_strip(fs, out):
    ims = []
    for f in fs:
        im = Image.open(f).convert("RGBA")
        im = im.resize((FRAME, round(FRAME * im.height / im.width)), Image.LANCZOS)
        ims.append(im)
    hh = max(i.height for i in ims)
    strip = Image.new("RGBA", (FRAME * len(ims), hh), (0, 0, 0, 0))
    for i, im in enumerate(ims):
        strip.paste(im, (i * FRAME, 0))
    strip.save(out, optimize=True)

def make_single(src, out, max_side=900):
    im = Image.open(src)
    im = im.convert("RGBA") if im.mode in ("RGBA", "LA", "P") else im.convert("RGB")
    if max(im.size) > max_side:
        k = max_side / max(im.size)
        im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
    im.save(out, optimize=True)

def make_sheet(fs, out, cell=128, cols=8):
    rows = (len(fs) + cols - 1) // cols
    sheet = Image.new("RGBA", (cell * min(cols, len(fs)), cell * rows), (0, 0, 0, 0))
    for i, f in enumerate(fs):
        im = Image.open(f).convert("RGBA")
        im.thumbnail((cell - 8, cell - 8), Image.LANCZOS)
        x = (i % cols) * cell + (cell - im.width) // 2
        y = (i // cols) * cell + (cell - im.height) // 2
        sheet.paste(im, (x, y), im)
    sheet.save(out, optimize=True)

def analyze_single(src):
    im = Image.open(src)
    w, h = im.size
    rgba = im.mode == "RGBA"
    corners = None
    if rgba:
        a = im.getchannel("A")
        corners = all(a.getpixel(p) <= 8 for p in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)))
    return {"w": w, "h": h, "uniform": True, "rgba": rgba, "corners_clear": corners}

assets = {}

def add(rec):
    rec.setdefault("project", "eclipse")
    rec.setdefault("requests", [])
    rec.setdefault("qa", {})
    rec.setdefault("exp", {})
    rec.setdefault("tags", [])
    rec.setdefault("placeholder", False)
    rec.setdefault("placeholder_note", "")
    rec.setdefault("brief", "")
    rec.setdefault("character", None)
    rec["updated"] = NOW
    rec.setdefault("history", [{"at": NOW, "text": "Nạp từ repo (quét tự động)"}])
    assets[rec["id"]] = rec

def version(vid, label, state, pv_name, note="", source="", auto=None, frames=None, fps=None, at=NOW):
    return {"id": vid, "label": label, "state": state, "src": f"pv/{pv_name}" if pv_name else None,
            "blob": None, "frames": frames or 1, "fps": fps, "note": note, "source": source,
            "auto": auto or {}, "at": at}

# ---------- Frame nhân vật ----------
ANIM_QA_DONE = {"design": True, "anatomy": True, "palette": True, "no_text": True, "edges": True,
                "size": True, "naming": True, "license": True, "pivot": True, "facing": True,
                "frame_count": True, "loop": True}
EXP_DONE = {"rgba": True, "alpha_zero": True, "no_halo": True, "premult": True, "canvas": True,
            "pivot": True, "naming": True, "check_tool": True, "lossless": True}

placeholder_char_pv = "placeholder-character-384.png"
make_single(os.path.join(ROOT, "assets/placeholders/placeholder_character_384.png"), os.path.join(PV, placeholder_char_pv))

for cid, cname in CHARS.items():
    man = json.load(open(os.path.join(ROOT, "assets/characters", cid, "frames_manifest.json"), encoding="utf-8"))
    for anim, a in man["animations"].items():
        aid = slug(f"{cid}-{anim}")
        game_dir = os.path.join(ROOT, "assets/characters", cid, "frames", anim)
        rev_dir = os.path.join(ROOT, "art_review", cid, anim)
        gfs = frame_files(game_dir, cid, anim)
        rfs = frame_files(rev_dir, cid, anim)
        versions, status, cur = [], "todo", None
        game_path = f"assets/characters/{cid}/frames/{anim}/"
        lrow = lic_for(game_path) or lic_for(game_path.rstrip("/"))
        # Bản cũ đã bị thay (art_review/_replaced)
        for old in sorted(glob.glob(os.path.join(ROOT, "art_review", cid, "_replaced", f"{anim}_*"))):
            ofs = frame_files(old, cid, anim)
            if not ofs:
                continue
            stamp = os.path.basename(old)[len(anim) + 1:]
            d = f"{stamp[0:4]}-{stamp[4:6]}-{stamp[6:8]}"
            vid = f"v{len(versions)+1}"
            pv = f"{aid}--{vid}.png"
            make_strip(ofs, os.path.join(PV, pv))
            versions.append(version(vid, f"Bản thử bị thay ({d})", "rejected", pv,
                                    note="Bản cũ được lưu ở art_review/_replaced khi duyệt bản mới.",
                                    source=rel(old), auto=analyze_frames(ofs), frames=len(ofs), fps=a["fps"],
                                    at=f"{d}T{stamp[9:11]}:{stamp[11:13]}:00Z"))
        meta = {}
        if os.path.exists(os.path.join(rev_dir, "meta.json")):
            meta = json.load(open(os.path.join(rev_dir, "meta.json"), encoding="utf-8"))
        if gfs:
            if rfs and files_hash(rfs) != files_hash(gfs):
                vid = f"v{len(versions)+1}"
                pv = f"{aid}--{vid}.png"
                make_strip(rfs, os.path.join(PV, pv))
                versions.append(version(vid, "Option trong art_review (khác bản game)", "option", pv,
                                        note=meta.get("prompt", ""), source=rel(rev_dir),
                                        auto=analyze_frames(rfs), frames=len(rfs), fps=a["fps"],
                                        at=(meta.get("date", "2026-11-14") + "T00:00:00Z")))
            vid = f"v{len(versions)+1}"
            pv = f"{aid}--{vid}.png"
            make_strip(gfs, os.path.join(PV, pv))
            note = (lrow[1] if lrow else "") or meta.get("prompt", "")
            src = (lrow[0] if lrow else meta.get("tool", ""))
            versions.append(version(vid, "Bản đã duyệt (đang dùng trong game)", "current", pv,
                                    note=note, source=game_path + (f" · {src}" if src else ""),
                                    auto=analyze_frames(gfs), frames=len(gfs), fps=a["fps"],
                                    at=(meta.get("date", "2026-11-13") + "T00:00:00Z")))
            status, cur = "approved", vid
        elif rfs:
            vid = f"v{len(versions)+1}"
            pv = f"{aid}--{vid}.png"
            make_strip(rfs, os.path.join(PV, pv))
            versions.append(version(vid, "Bản chờ owner duyệt (art_review)", "current", pv,
                                    note=meta.get("prompt", ""),
                                    source=f"art_review/{cid}/{anim}/ · {meta.get('tool','Codex imagegen')}",
                                    auto=analyze_frames(rfs), frames=len(rfs), fps=a["fps"],
                                    at=(meta.get("date", "2026-11-14") + "T00:00:00Z")))
            status, cur = "review", vid
        rec = {
            "id": aid, "name": f"{cname} · {anim}", "category": "Frame nhân vật", "kind": "anim",
            "character": cid, "scene": "Màn chiến đấu", "style": "Chibi anime · frame AI",
            "status": status, "path": game_path,
            "spec": {"w": 384, "h": 384, "transparent": True, "layered": False, "animation": True,
                     "frames": a["frames"], "fps": a["fps"], "loop": bool(a.get("loop")),
                     "pivot": "x 192 · chân y 336", "naming": f"{cid}_{anim}_NNN.png"},
            "versions": versions, "current": cur, "tags": [cname, anim] + ([a["skill_key"]] if a.get("skill_key") else []),
            "brief": f"{a['frames']} frame, {a['fps']} fps{', lặp' if a.get('loop') else ''}. Vẽ hướng phải, nền trong suốt, không VFX. "
                     f"Phiếu: docs/prompts/codex_frames/{cid}/ (nếu có).",
        }
        if status == "approved":
            rec["qa"] = dict(ANIM_QA_DONE)
            rec["exp"] = dict(EXP_DONE)
        if status == "todo":
            rec["placeholder"] = True
            rec["placeholder_note"] = "Trong game đang dùng placeholder_character_384.png (384×384) cho tới khi có frame thật."
            rec["placeholder_src"] = f"pv/{placeholder_char_pv}"
        add(rec)

# ---------- Ảnh đơn ----------
def single(aid, name, path, category, scene, style, status, spec, placeholder=False, pnote="", brief="",
           requests=None, character=None, tags=None, label="Bản hiện tại", note=""):
    src = os.path.join(ROOT, path)
    pv = f"{aid}--v1.png"
    make_single(src, os.path.join(PV, pv))
    lrow = lic_for(path)
    ver = version("v1", label, "current", pv, note=note or (lrow[1] if lrow else ""),
                  source=path + (f" · {lrow[0]}" if lrow else ""), auto=analyze_single(src), at=mtime(src))
    rec = {"id": aid, "name": name, "category": category, "kind": "image", "character": character,
           "scene": scene, "style": style, "status": status, "path": path, "spec": spec,
           "versions": [ver], "current": "v1", "placeholder": placeholder, "placeholder_note": pnote,
           "brief": brief, "tags": tags or [],
           "requests": [{"id": f"r{i+1}", "text": t, "at": NOW, "done": False} for i, t in enumerate(requests or [])]}
    if status == "approved":
        rec["qa"] = {k: True for k in ("design", "anatomy", "palette", "no_text", "edges", "size", "naming", "license")}
    add(rec)

def spec(w, h, transparent=True, layered=False, naming=""):
    return {"w": w, "h": h, "transparent": transparent, "layered": layered, "animation": False,
            "frames": 1, "fps": None, "loop": False, "pivot": "", "naming": naming}

for cid in ("char_fire_01", "char_wind_01"):
    cname = CHARS[cid]
    p = f"assets/characters/{cid}/portrait/{cid}_portrait_full.png"
    single(slug(f"{cid}-portrait"), f"{cname} · chân dung toàn thân", p, "Chân dung", "Màn Nhân vật",
           "Chibi anime · owner", "approved", spec(None, None, naming=f"{cid}_portrait_full.png"),
           character=cid, tags=[cname],
           brief="Ảnh đứng toàn thân, cắt sát, nền trong suốt. Dùng làm tham chiếu chính khi tạo frame AI.")
for cid in ("char_lightning_01", "char_light_01", "char_dark_01", "char_earth_01"):
    cname = CHARS[cid]
    add({"id": slug(f"{cid}-portrait"), "name": f"{cname} · chân dung toàn thân", "category": "Chân dung",
         "kind": "image", "character": cid, "scene": "Màn Nhân vật", "style": "Chibi anime · owner",
         "status": "todo", "path": f"assets/characters/{cid}/portrait/{cid}_portrait_full.png",
         "spec": spec(None, None, naming=f"{cid}_portrait_full.png"), "versions": [], "current": None,
         "tags": [cname], "placeholder": True,
         "placeholder_note": "Thư mục portrait/ còn trống; màn Nhân vật hiện không có ảnh cho giáp này.",
         "brief": "Owner cung cấp ảnh đứng toàn thân (cắt sát, nền trong suốt). Cần có trước khi tạo frame AI."})

for f in sorted(glob.glob(os.path.join(ROOT, "assets/characters/char_fire_01/splash/*.png"))):
    key = os.path.basename(f)[len("char_fire_01_splash_"):-4]
    tab = {"overview": "tổng quan", "skill": "tab Skill", "level": "tab Tăng cấp", "stigma": "tab Vết Thánh",
           "weapon": "tab Vũ khí"}.get(key, key)
    single(slug(f"char_fire_01-splash-{key}"), f"Enkiba · splash {tab}", rel(f), "Splash", "Màn Nhân vật",
           "Anime 2D toàn thân (không chibi)", "approved", spec(None, None, naming=os.path.basename(f)),
           character="char_fire_01", tags=["Enkiba", "splash"],
           brief=f"Splash art 2D không chibi cho {tab}. Xóa nền + cắt sát bằng tools/cut_splash.py.")

ICON_REQ = ["Owner vẽ lại icon thật thay bản vẽ code tạm"]
for f in sorted(glob.glob(os.path.join(ROOT, "assets/ui/hub/icons/*.png"))):
    key = os.path.basename(f)[:-4]
    single(slug(f"hub-icon-{key}"), f"Icon sảnh · {key}", rel(f), "Icon UI", "Sảnh chính",
           "Icon hình học (vẽ code)", "wip", spec(256, 256, naming=f"{key}.png"), placeholder=True,
           pnote="Icon tạm vẽ bằng tools/ui/gen_hub_icons.py; giữ tên file khi thay.", requests=ICON_REQ,
           tags=["hub", "lục giác"], brief="Icon nút lục giác ở sảnh chính, 256×256, nền trong suốt.")

for d in sorted(glob.glob(os.path.join(ROOT, "assets/ui/hud/skill_icons/*"))):
    key = os.path.basename(d)
    fs = sorted(glob.glob(os.path.join(d, "*.png")))
    aid = slug(f"skill-icons-{key}")
    pv = f"{aid}--v1.png"
    make_sheet(fs, os.path.join(PV, pv), cell=128, cols=len(fs))
    who = CHARS.get(key, "Mặc định")
    au = analyze_frames(fs)
    au.pop("baseline", None); au.pop("center_x", None)
    add({"id": aid, "name": f"Bộ icon kỹ năng HUD · {who}", "category": "HUD", "kind": "sheet",
         "character": key if key in CHARS else None, "scene": "HUD chiến đấu", "style": "Icon hình học (vẽ code)",
         "status": "wip", "path": rel(d).rstrip("/") + "/",
         "spec": {**spec(256, 256, layered=True, naming="attack.png, skill.png, ultimate.png, weapon.png"),
                  "parts": len(fs)},
         "versions": [version("v1", f"Bản tạm vẽ code ({len(fs)} icon)", "current", pv,
                              note="Claude vẽ bằng tools/ui/gen_hud_icons.py (Pillow, không AI).",
                              source=rel(d), auto=au, frames=1, at=mtime(*fs))],
         "current": "v1", "placeholder": True, "placeholder_note": "Icon tạm; owner sẽ vẽ lại, giữ nguyên tên file.",
         "requests": [{"id": "r1", "text": ICON_REQ[0], "at": NOW, "done": False}],
         "tags": [who, "HUD"], "brief": "Mỗi icon 256×256, nền trong suốt, một file mỗi nút: " +
         ", ".join(os.path.basename(x)[:-4] for x in fs) + "."})

for f in sorted(glob.glob(os.path.join(ROOT, "assets/ui/hud/joystick/*.png"))):
    key = os.path.basename(f)[:-4]
    au = analyze_single(f)
    single(slug(f"hud-{key}"), f"Joystick · {key.replace('joystick_', '')}", rel(f), "HUD", "HUD chiến đấu",
           "HUD xanh phát sáng", "review", spec(au["w"], au["h"], layered=(key != "joystick_full"), naming=f"{key}.png"),
           tags=["joystick", "cảm ứng"],
           requests=["Kiểm tra ảnh gốc có nền caro vẽ sẵn và dấu lấp lánh ở góc (ghi trong ASSET_LICENSES) đã được xóa sạch"],
           brief="Nút di chuyển cảm ứng. Tách 2 layer: đế (base) và núm (knob); bản full chỉ để tham chiếu.")

single("hub-bg-sky-garden", "Nền sảnh · Sky Garden (tạm)", "assets/placeholders/placeholder_hub_bg_sky_garden.png",
       "Nền", "Sảnh chính", "Nền phong cảnh (tạm)", "todo", spec(1080, 540, transparent=False, naming="bg_sky_garden.png"),
       placeholder=True, pnote="KHÔNG SHIP: ảnh trùng nền một game thương mại, không có quyền dùng. Bản Release tự loại *placeholder_*.",
       requests=["Thay bằng nền tự vẽ hoặc có giấy phép, rồi sửa trường image trong data/backgrounds/bg_sky_garden.tres"],
       tags=["hub", "không ship"], brief="Nền sảnh chính 1080×540 (tỉ lệ 2:1), không cần trong suốt.")
single("placeholder-character", "Nhân vật placeholder 384", "assets/placeholders/placeholder_character_384.png",
       "Placeholder", "Màn chiến đấu", "Placeholder xám", "approved", spec(384, 384, naming="placeholder_character_384.png"),
       placeholder=True, pnote="Hình nộm thay mọi giáp chưa có frame.", tags=["placeholder"],
       brief="Khung 384×384, chân y 336, tâm x 192 giống frame thật.")
single("placeholder-tiles-64", "Tile nền 64 (tạm)", "assets/placeholders/placeholder_tiles_64.png",
       "Tileset", "Màn chiến đấu", "Placeholder xám", "todo", spec(128, 64, transparent=False, naming="tiles_64.png"),
       placeholder=True, pnote="Tile tạm 64×64 cho màn chơi.", requests=["Cần tileset thật cho các ải chương 1"],
       tags=["tile", "placeholder"], brief="Lưới tile 64×64.")
# Bố cục Chiêu mộ mới (owner 2026-11-15): ảnh banner phủ phần phải màn 1590×1080; danh sách bên trái là thẻ chữ
# (ảnh thumb không còn hiện, giữ mục cũ trên site).
for grp, bid in (("char", "banner_char_terra"), ("equip", "banner_equip_terra"), ("star5", "banner_star5_earth")):
    p = f"assets/ui/recruit/placeholder_{bid}_banner.png"
    aid = slug(f"recruit-{grp}-terra-banner") if grp != "star5" else "recruit-star5-earth-banner"
    single(aid, f"Chiêu mộ · {bid} · banner", p, "Banner",
           "Chiêu mộ", "Placeholder xám", "todo", spec(1590, 1080, transparent=False, naming=f"{bid}_banner.png"),
           placeholder=True, pnote="Hình người xám kèm tên banner; thêm file đúng tên là màn tự nhận, không sửa code.",
           requests=["Owner cung cấp ảnh banner 1590×1080 (bố cục 2026-11-15: tiêu đề + chú thích bên trái, cột thông tin "
                     "bên phải, nút vàng góc phải dưới; nhân vật / vũ khí ở giữa)"],
           tags=["gacha", "banner"],
           brief="Ảnh banner phủ phần phải màn Chiêu mộ (x 330 → 1920). Hai mép trái / phải được làm tối nhẹ để đọc chữ.")
for grp in ("char", "equip"):
    p = f"assets/ui/recruit/placeholder_banner_{grp}_terra_thumb.png"
    single(slug(f"recruit-{grp}-terra-thumb"), f"Chiêu mộ · banner_{grp}_terra · thumb", p, "Banner",
           "Chiêu mộ", "Placeholder xám", "todo", spec(390, 226, transparent=False, naming=f"banner_{grp}_terra_thumb.png"),
           placeholder=True, pnote="Bố cục 2026-11-15 không còn hiện ảnh nhỏ (danh sách là thẻ chữ).",
           tags=["gacha", "banner"], brief="Không dùng ở bố cục hiện tại.")
single("recruit-result-card", "Chiêu mộ · thẻ kết quả rỗng", "assets/placeholders/placeholder_recruit_card.png", "UI",
       "Chiêu mộ", "Placeholder vẽ code", "todo", spec(336, 1240, naming="recruit_card.png"),
       placeholder=True, pnote="Khung thẻ kết quả, hiển thị 168×620; viền / quầng sáng màu độ hiếm do code vẽ.",
       requests=["Owner cung cấp khung thẻ kết quả 336×1240 (2× hiển thị), nền trong suốt ngoài khung"],
       tags=["gacha", "kết quả"], brief="Thẻ dọc rỗng dưới ảnh nhân vật / vật phẩm ở màn kết quả chiêu mộ.")
for icon, vi in (("weapon", "vũ khí"), ("stigma", "vết thánh"), ("material", "nguyên liệu"), ("gold", "vàng")):
    single(f"recruit-icon-{icon}", f"Chiêu mộ · icon tạm {vi}", f"assets/placeholders/placeholder_recruit_icon_{icon}.png",
           "Icon", "Chiêu mộ", "Placeholder vẽ code", "todo", spec(512, 512, naming=f"recruit_icon_{icon}.png"),
           placeholder=True, pnote="Dùng khi món chưa có ảnh riêng (EquipmentDef.art / vật phẩm).",
           requests=[f"Ảnh thật cho từng món {vi} (đặt EquipmentDef.art) hoặc icon chung 512×512"],
           tags=["gacha", "icon"], brief=f"Icon {vi} trên thẻ kết quả và dãy icon đề cử của banner trang bị.")

single("char-wind-01-vfx-wind-arrow", "Kazeyumi · mũi tên gió", "assets/characters/char_wind_01/vfx/char_wind_01_vfx_wind_arrow.png",
       "VFX", "Màn chiến đấu", "VFX vẽ tay (owner)", "approved", spec(165, 47, naming="char_wind_01_vfx_wind_arrow.png"),
       character="char_wind_01", tags=["Kazeyumi", "đạn"], brief="Đạn tên (HitDef.projectile_sprite). Hướng phải, nền trong suốt.")

# Rig parts Enkiba
fs = sorted(glob.glob(os.path.join(ROOT, "assets/characters/char_fire_01/rig_parts/*.png")))
pv = "char-fire-01-rig-parts--v1.png"
make_sheet(fs, os.path.join(PV, pv), cell=112, cols=8)
add({"id": "char-fire-01-rig-parts", "name": f"Enkiba · bộ phận rig ({len(fs)} phần)", "category": "Rig parts",
     "kind": "sheet", "character": "char_fire_01", "scene": "Rig nhân vật", "style": "Chibi anime · owner",
     "status": "approved", "path": "assets/characters/char_fire_01/rig_parts/",
     "spec": {**spec(None, None, layered=True, naming="char_fire_01_part_NN_<nhom>_<ten>.png"), "parts": len(fs)},
     "versions": [version("v1", f"Bộ tách từ sheet owner ({len(fs)} PNG)", "current", pv,
                          note="Tách nền và chia file bằng tools/sprite_parts/; owner đặt tên 64/64 bộ phận.",
                          source="assets/characters/char_fire_01/rig_parts/", auto={"rgba": True}, at=mtime(*fs))],
     "current": "v1", "tags": ["Enkiba", "rig", "layer"],
     "qa": {k: True for k in ("design", "edges", "naming", "license")},
     "exp": {k: True for k in ("rgba", "alpha_zero", "no_halo", "naming", "layers", "padding")},
     "brief": "Mặt, tóc, áo, tay, chân, ủng, vũ khí, giáp tách riêng từng file để ráp rig."})

for aid in NO_UPLOAD:
    rec = assets.get(aid)
    if rec:
        for v in rec["versions"]:
            if v.get("src"):
                p = os.path.join(OUT, "site", v["src"])
                if os.path.exists(p):
                    os.remove(p)
        rec["versions"], rec["current"] = [], None
        rec["placeholder_note"] += f" Ảnh không đưa lên site vì là ảnh của bên thứ ba; xem tại {rec['path']}."

for rec in assets.values():
    with open(os.path.join(SEED, rec["id"] + ".json"), "w", encoding="utf-8") as fh:
        json.dump(rec, fh, ensure_ascii=False)

json.dump({"name": "PROJECT ECLIPSE", "note": "Action RPG 2D side-scroll · Godot 4.6.3",
           "updated": NOW}, open(os.path.join(SEED, "_project_eclipse.json"), "w", encoding="utf-8"), ensure_ascii=False)

tot = sum(os.path.getsize(p) for p in glob.glob(os.path.join(PV, "*.png")))
from collections import Counter
print("assets", len(assets), Counter(r["status"] for r in assets.values()))
print("previews", len(glob.glob(os.path.join(PV, "*.png"))), round(tot / 1e6, 1), "MB")
print("max doc", max(os.path.getsize(p) for p in glob.glob(os.path.join(SEED, "*.json"))))
