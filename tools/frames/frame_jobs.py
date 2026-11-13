"""Phiếu việc tạo frame (tools/frames/jobs/{id}.json) + số liệu tính từ dữ liệu game.

Số frame, fps, frame trúng đòn của animation có kỹ năng được TÍNH từ SkillDef (data/skills/{id}/{skill}.tres):
- thời lượng = khởi động + hiệu lực + hồi phục (ms), đúng thời gian game giữ nhân vật trong đòn;
- fps chọn trong FPS_CHOICES sao cho số frame gần `target_frames` nhất (frames = thời lượng × fps);
- frame trúng đòn = các frame phủ cửa sổ [at_ms, at_ms + duration_ms) của từng HitDef.
Animation không có kỹ năng dùng `target_frames` và `fps` trong phiếu.

Chỉ dùng thư viện chuẩn. Dùng chung cho gen_prompts.py, slice_strip.py, check_frames.py, approve_frames.py.
"""
import io
import json
import math
import os
import re
import sys

# In tiếng Việt ra console Windows (cp1252) khi chạy bằng python -I (bỏ qua PYTHONUTF8).
for _s in (sys.stdout, sys.stderr):
    if hasattr(_s, "reconfigure"):
        _s.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FPS_CHOICES = [8, 10, 12, 15, 18, 20, 24]
CANVAS = 384
PIVOT_X = 192
BASELINE_Y = 336
MAX_FRAMES_PER_CALL = 6


def root(path=""):
    return os.path.join(ROOT, *path.replace("\\", "/").split("/")) if path else ROOT


def load_jobs(character_id, base=None):
    p = os.path.join(base or ROOT, "tools", "frames", "jobs", character_id + ".json")
    with io.open(p, encoding="utf-8") as f:
        return json.load(f)


def load_manifest(character_id, base=None):
    p = manifest_path(character_id, base)
    with io.open(p, encoding="utf-8") as f:
        return json.load(f)


def manifest_path(character_id, base=None):
    return os.path.join(base or ROOT, "assets", "characters", character_id, "frames_manifest.json")


def read_skill(character_id, skill_file, base=None):
    """Đọc thời gian từ SkillDef .tres (định dạng văn bản của Godot)."""
    p = os.path.join(base or ROOT, "data", "skills", character_id, skill_file + ".tres")
    with io.open(p, encoding="utf-8") as f:
        s = f.read()

    def num(key, default=0.0):
        m = re.search(r"^%s = ([-\d.]+)" % key, s, re.M)
        return float(m.group(1)) if m else default

    # Chỉ tính hit do kiếm chém (gồm chém tại mục tiêu của tuyệt kỹ). Hit bay đi (travel_px > 0, sóng lửa) hoặc nổ trễ
    # (delay_ms > 0) không quyết định pose trúng đòn; nếu không còn hit nào thì dùng cửa sổ [khởi động, khởi động + hiệu lực).
    hits = []
    for block in s.split("[sub_resource")[1:]:
        m = re.search(r"^at_ms = ([\d.]+)\nduration_ms = ([\d.]+)", block, re.M)
        if not m:
            continue
        travel = re.search(r"^travel_px = ([\d.]+)", block, re.M)
        delay = re.search(r"^delay_ms = ([\d.]+)", block, re.M)
        flies = re.search(r"^detached = true", block, re.M) and (
            (travel and float(travel.group(1)) > 0) or (delay and float(delay.group(1)) > 0))
        if not flies:
            hits.append((float(m.group(1)), float(m.group(2))))
    startup, active = num("startup_ms", 100.0), num("active_ms", 100.0)
    if not hits:
        hits = [(startup, active)]
    return {"startup_ms": startup, "active_ms": active, "recovery_ms": num("recovery_ms", 200.0), "hits": hits}


def plan(character_id, anim, base=None):
    """Số liệu của một animation: frames, fps, loop, duration_ms, active_frames, grounded, skill."""
    jobs = load_jobs(character_id, base)
    job = jobs["animations"][anim]
    manifest = load_manifest(character_id, base)
    loop = bool(job.get("loop", manifest["animations"].get(anim, {}).get("loop", False)))
    target = int(job["target_frames"])
    out = {"anim": anim, "loop": loop, "grounded": bool(job.get("grounded", True)), "skill": job.get("skill"),
           "active_frames": [], "duration_ms": None}
    if job.get("skill"):
        sk = read_skill(character_id, job["skill"], base)
        total = sk["startup_ms"] + sk["active_ms"] + sk["recovery_ms"]
        best = min(FPS_CHOICES, key=lambda f: (abs(total * f / 1000.0 - target), -f))
        frames = max(1, int(round(total * best / 1000.0)))
        active = set()
        for at, dur in sk["hits"]:
            first = int(math.floor(at * best / 1000.0))
            last = int(math.ceil((at + dur) * best / 1000.0)) - 1
            for i in range(first, min(last, frames - 1) + 1):
                active.add(i)
        out.update(frames=frames, fps=best, duration_ms=total, active_frames=sorted(active),
                   timing="%d/%d/%d ms" % (sk["startup_ms"], sk["active_ms"], sk["recovery_ms"]))
    else:
        fps = int(job.get("fps", 12))
        out.update(frames=target, fps=fps, duration_ms=round(target * 1000.0 / fps), timing=None)
    out["calls"] = calls(out["frames"])
    out["phases"] = phases(out["frames"], out["active_frames"])
    out["sword"] = job.get("sword", "drawn")
    out["ref_frame"] = int(job.get("ref_frame", 0))
    out["ref_ratio"] = float(job.get("ref_ratio", 1.0))
    return out


def phases(frames, active):
    """Giai đoạn từng frame: startup / active / recovery (rỗng nếu animation không có đòn đánh)."""
    if not active:
        return [None] * frames
    first, last = min(active), max(active)
    return ["startup" if i < first else ("active" if i <= last else "recovery") for i in range(frames)]


def idle_height(character_id, base=None):
    """Chiều cao trung bình (px) của nhân vật đứng, đo từ idle: bản đã duyệt trong assets, không có thì bản chờ duyệt."""
    from PIL import Image
    for d in (frames_dir(character_id, "idle", base), review_dir(character_id, "idle", base)):
        if not os.path.isdir(d):
            continue
        hs = []
        for name in sorted(os.listdir(d)):
            if name.endswith(".png"):
                bb = Image.open(os.path.join(d, name)).convert("RGBA").getchannel("A").point(
                    lambda v: 255 if v >= 16 else 0).getbbox()
                if bb:
                    hs.append(bb[3] - bb[1])
        if hs:
            return sum(hs) / len(hs)
    return None


def calls(frames):
    """Chia số frame thành các lần gọi tạo ảnh, mỗi lần tối đa MAX_FRAMES_PER_CALL, chia đều."""
    n = max(1, math.ceil(frames / MAX_FRAMES_PER_CALL))
    base, extra = divmod(frames, n)
    out, start = [], 0
    for i in range(n):
        size = base + (1 if i < extra else 0)
        out.append((start, start + size - 1))
        start += size
    return out


def review_dir(character_id, anim, base=None):
    return os.path.join(base or ROOT, "art_review", character_id, anim)


def frames_dir(character_id, anim, base=None):
    return os.path.join(base or ROOT, "assets", "characters", character_id, "frames", anim)


def frame_name(character_id, anim, i):
    return "%s_%s_%03d.png" % (character_id, anim, i)
