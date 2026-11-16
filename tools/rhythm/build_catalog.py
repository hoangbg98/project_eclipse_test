"""Dựng danh mục bài nhạc cho chế độ nhịp điệu (M10): sinh bản nốt từ file nhạc + ghi catalog.json.

Owner 2026-11-16: bản nốt do tool tự sinh từ nhạc; ải boss dùng bản cố định (server/music/fixed/).

Dùng (ở thư mục gốc dự án):
  python -X utf8 -I tools/rhythm/build_catalog.py              # dựng tất cả (nhạc thử còn thiếu thì tạo)
  python -X utf8 -I tools/rhythm/build_catalog.py --freeze-boss  # sinh lại và GHI ĐÈ bản cố định của bài boss

Đầu vào : server/music/songs.json, file nhạc trong server/music/ (.wav đọc trực tiếp; .ogg/.mp3 cần ffmpeg trong PATH)
Đầu ra  : server/music/charts/<song>_<chart>.json, server/music/catalog.json (sha256 + kích thước từng file)
Bản cố định server/music/fixed/<song>_<chart>.json (nếu có) được dùng thay cho bản sinh — sửa tay được.

Thuật toán (docs/design/RHYTHM_MODE.md mục 5): STFT -> spectral flux 3 dải (trầm / giữa / cao) -> lưới phách
(bpm cho sẵn hoặc tự đoán bằng tự tương quan) -> chọn điểm lưới có nhấn mạnh theo độ khó -> làn: trầm = dưới,
giữa/cao = trên, cả hai cùng mạnh = cả hai -> đoạn ngân dài = nốt giữ, đoạn dồn trống = nốt ấn liên tục ->
giãn cách tối thiểu theo độ khó. Không có ngẫu nhiên: cùng file nhạc => cùng bản nốt.
"""
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import wave

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_test_music  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
MUSIC = os.path.join(ROOT, "server", "music")
N_FFT = 1024
HOP = 256

# Thông số từng độ khó. grid: số điểm lưới / phách; keep: tỉ lệ điểm lưới có nhấn được giữ (theo phân vị);
# gap: giãn cách tối thiểu (giây); both: tỉ lệ tối đa nốt "cả hai"; hold/mash: có sinh không.
PROFILES = {
    "easy": {"grid": 2, "keep": 0.30, "gap": 0.42, "both": 0.06, "hold": True, "mash": True, "min_level": 1},
    "normal": {"grid": 2, "keep": 0.55, "gap": 0.26, "both": 0.12, "hold": True, "mash": True, "min_level": 4},
    "hard": {"grid": 4, "keep": 0.72, "gap": 0.10, "both": 0.18, "hold": True, "mash": True, "min_level": 7},
    "boss": {"grid": 4, "keep": 1.0, "gap": 0.08, "both": 0.3, "hold": True, "mash": True, "min_level": 11},
}
# Hai nốt CÙNG làn phải cách nhau ít nhất chừng này (giây, tính từ lúc nốt trước kết thúc) để hitbox không đè nhau
# (owner 2026-11-16). Khớp RhythmRules.min_note_gap() = 2 × ring_radius / note_speed (2 × 72 / 800 = 0.18), cộng dư
# một chút; game cũng tự bỏ nốt vi phạm (RhythmChart.enforce_spacing). Nốt khác làn được xen sát hơn ("gap").
LANE_GAP = 0.19
DEFAULT_CHARTS = ["easy", "normal", "hard"]


# ---------- Đọc âm thanh ----------

def read_audio(path):
    """Trả về (mẫu mono float32, tần số lấy mẫu)."""
    if path.lower().endswith(".wav"):
        with wave.open(path, "rb") as w:
            sr, ch, width, n = w.getframerate(), w.getnchannels(), w.getsampwidth(), w.getnframes()
            raw = w.readframes(n)
        if width == 2:
            x = np.frombuffer(raw, "<i2").astype(np.float32) / 32768.0
        elif width == 1:
            x = (np.frombuffer(raw, np.uint8).astype(np.float32) - 128) / 128.0
        elif width == 4:
            x = np.frombuffer(raw, "<i4").astype(np.float32) / 2147483648.0
        else:
            raise SystemExit(f"{path}: WAV {width * 8}-bit chưa hỗ trợ")
        if ch > 1:
            x = x.reshape(-1, ch).mean(axis=1)
        return x, sr
    ff = shutil.which("ffmpeg")
    if not ff:
        raise SystemExit(f"{path}: cần ffmpeg trong PATH để đọc file không phải WAV")
    with tempfile.TemporaryDirectory() as d:
        out = os.path.join(d, "a.wav")
        subprocess.run([ff, "-v", "error", "-y", "-i", path, "-ac", "1", "-ar", "22050", out], check=True)
        return read_audio(out)


# ---------- Phân tích ----------

def analyse(x, sr):
    win = np.hanning(N_FFT).astype(np.float32)
    n_frames = 1 + max(0, (len(x) - N_FFT) // HOP)
    frames = np.lib.stride_tricks.as_strided(x, shape=(n_frames, N_FFT), strides=(x.strides[0] * HOP, x.strides[0]))
    spec = np.abs(np.fft.rfft(frames * win, axis=1))
    spec = np.log1p(spec * 10.0)
    freqs = np.fft.rfftfreq(N_FFT, 1.0 / sr)
    bands = {"low": (20, 150), "mid": (150, 2000), "high": (2000, sr / 2)}
    flux, energy = {}, {}
    for k, (lo, hi) in bands.items():
        m = (freqs >= lo) & (freqs < hi)
        b = spec[:, m]
        d = np.diff(b, axis=0, prepend=b[:1])
        f = np.maximum(d, 0).sum(axis=1)
        flux[k] = f / (np.percentile(f, 99) or 1.0)
        e = b.mean(axis=1)
        energy[k] = e / (np.percentile(e, 99) or 1.0)
    times = (np.arange(n_frames) * HOP + N_FFT / 2) / sr
    m = (freqs >= 200) & (freqs < 2000)
    sub = spec[:, m]
    peak_bin = sub.argmax(axis=1)
    peak_mag = sub.max(axis=1)
    return times, flux, energy, (peak_bin, peak_mag)


def estimate_bpm(flux, sr):
    onset = flux["low"] + flux["mid"] + flux["high"]
    onset = onset - onset.mean()
    ac = np.correlate(onset, onset, mode="full")[len(onset) - 1:]
    fps = sr / HOP
    best, best_bpm = -1, 120.0
    for bpm in np.arange(70, 181, 0.5):
        lag = fps * 60.0 / bpm
        i = int(round(lag))
        if i + 1 >= len(ac):
            continue
        v = ac[i] + 0.5 * ac[min(len(ac) - 1, 2 * i)]
        if v > best:
            best, best_bpm = v, bpm
    return float(best_bpm)


def beat_offset(times, flux, bpm):
    onset = flux["low"] * 1.5 + flux["mid"] + flux["high"] * 0.5
    beat = 60.0 / bpm
    best, best_off = -1, 0.0
    for off in np.arange(0, beat, 0.005):
        grid = np.arange(off, times[-1], beat)
        idx = np.clip(np.searchsorted(times, grid), 0, len(times) - 1)
        v = onset[idx].sum()
        if v > best:
            best, best_off = v, off
    return float(best_off)


def peak_near(times, arr, t, w=0.03):
    a, b = np.searchsorted(times, t - w), np.searchsorted(times, t + w)
    return float(arr[a:max(b, a + 1)].max()) if a < len(arr) else 0.0


# ---------- Sinh nốt ----------

def find_mash(times, flux, grid_t, bpm):
    """Đoạn dồn trống: ≥ 8 điểm lưới 1/4 liên tiếp có nhấn ở dải giữa/cao."""
    step = 60.0 / bpm / 4
    pts = np.arange(grid_t[0], grid_t[-1], step)
    s = np.array([max(peak_near(times, flux["mid"], t), peak_near(times, flux["high"], t)) for t in pts])
    strong = s > max(0.25, np.percentile(s, 60))
    spans, i = [], 0
    while i < len(pts):
        if strong[i]:
            j = i
            while j + 1 < len(pts) and strong[j + 1]:
                j += 1
            if j - i + 1 >= 12:
                spans.append((float(pts[i]), float(pts[j] + step)))
            i = j + 1
        else:
            i += 1
    return spans


def find_holds(times, spec_info, bpm):
    """Đoạn ngân: cao độ nổi trội (dải 200-2000 Hz) giữ nguyên ≥ 1.2 phách; cho phép trống chen ngắn (≤ 4 frame)."""
    beat = 60.0 / bpm
    peak_bin, peak_mag = spec_info
    thr = np.percentile(peak_mag, 60)
    holds = []
    n = len(times)
    i = 1
    while i < n:
        if peak_mag[i] > thr and peak_bin[i] != peak_bin[i - 1]:
            j, gap, last = i + 1, 0, i
            while j < n:
                if abs(int(peak_bin[j]) - int(peak_bin[i])) <= 1 and peak_mag[j] > thr * 0.7:
                    gap, last = 0, j
                else:
                    gap += 1
                    if gap > 4:
                        break
                j += 1
            dur = times[last] - times[i]
            if dur >= beat * 1.2:
                beats = int(dur / beat * 2) / 2
                holds.append((float(times[i]), min(beats * beat, 4 * beat)))
                i = last + 1
                continue
        i += 1
    return holds


def make_chart(path, song, chart_key):
    prof = PROFILES[chart_key]
    x, sr = read_audio(path)
    times, flux, energy, pitch = analyse(x, sr)
    bpm = float(song.get("bpm") or estimate_bpm(flux, sr))
    beat = 60.0 / bpm
    off = beat_offset(times, flux, bpm)
    duration = len(x) / sr
    step = beat / prof["grid"]
    grid = np.arange(off, duration - 1.0, step)
    grid = grid[grid >= 1.5]
    low = np.array([peak_near(times, flux["low"], t) for t in grid])
    upp = np.array([max(peak_near(times, flux["mid"], t), peak_near(times, flux["high"], t)) for t in grid])
    strength = np.maximum(low, upp)
    on_beat = (np.round((grid - off) / beat * prof["grid"]) % prof["grid"] == 0)
    strength = strength * np.where(on_beat, 1.15, 1.0)
    thr = np.percentile(strength[strength > 0.12], 100 * (1 - prof["keep"])) if np.any(strength > 0.12) else 1.0

    events = []  # (t, kind, lane, dur, hits)
    blocked = []
    if prof["mash"]:
        for a, b in find_mash(times, flux, grid, bpm):
            if b - a >= beat * 2:
                dur = round(b - a - beat * 0.25, 3)
                hits = max(4, int(dur * {"easy": 4, "normal": 5, "hard": 7, "boss": 7}[chart_key]))
                events.append((a, "mash", "up", dur, hits))
                blocked.append((a - 0.3, a + dur + 0.35))
    if prof["hold"]:
        for a, dur in find_holds(times, pitch, bpm):
            # Canh đầu nốt giữ vào lưới.
            a = off + round((a - off) / step) * step
            if any(b0 <= a <= b1 or b0 <= a + dur <= b1 for b0, b1 in blocked):
                continue
            lane = "up"
            if chart_key in ("hard", "boss") and peak_near(times, flux["low"], a) > 0.6:
                lane = "both"
            events.append((a, "hold", lane, round(dur - beat * 0.25, 3), 0))
            blocked.append((a - 0.25, a + dur + 0.2))
    both_count = 0
    taps = []
    for i, t in enumerate(grid):
        if strength[i] < thr or any(b0 <= t <= b1 for b0, b1 in blocked):
            continue
        lo, up = low[i], upp[i]
        if lo > 0.55 and up > 0.55 and min(lo, up) / max(lo, up) > 0.7:
            lane = "both"
        elif lo >= up:
            lane = "down"
        else:
            lane = "up"
        taps.append([float(t), lane, float(strength[i]), "down" if lo >= up else "up"])
    # Giới hạn tỉ lệ "cả hai": giữ những nốt mạnh nhất.
    both_idx = sorted([i for i, e in enumerate(taps) if e[1] == "both"], key=lambda i: -taps[i][2])
    cap = int(len(taps) * prof["both"])
    for k, i in enumerate(both_idx):
        if k >= cap:
            taps[i][1] = taps[i][3]
        else:
            both_count += 1
    for t, lane, _, _ in taps:
        events.append((t, "tap", lane, 0.0, 0))
    # Giãn cách: ưu tiên nốt giữ / ấn liên tục, rồi tap theo thời gian.
    events.sort(key=lambda e: (e[0], 0 if e[1] != "tap" else 1))
    notes = []
    end = -1e9
    lane_end = {"up": -1e9, "down": -1e9}
    for t, kind, lane, dur, hits in events:
        gap = prof["gap"] if kind == "tap" else max(prof["gap"], 0.3)
        if t < end + gap:
            continue
        lanes = ("up", "down") if lane == "both" else (lane,)
        if any(t < lane_end[l] + LANE_GAP for l in lanes):
            continue
        n = {"t": round(t, 3), "lane": lane, "kind": kind}
        if kind != "tap":
            n["dur"] = round(max(dur, beat * 0.5), 3)
        if kind == "mash":
            n["hits"] = hits
        notes.append(n)
        end = t + (n.get("dur", 0.0))
        for l in lanes:
            lane_end[l] = end
    # Mức độ khó hiển thị: theo mật độ (nốt / giây trong phần có nốt).
    span = max(1.0, (notes[-1]["t"] - notes[0]["t"]) if notes else 1.0)
    density = len(notes) / span
    level = int(np.clip(round(density * 2.6), prof["min_level"], 12))
    return {
        "format": 1,
        "song_id": song["id"],
        "difficulty": chart_key,
        "level": level,
        "bpm": round(bpm, 2),
        "offset_sec": round(off, 3),
        "duration_sec": round(duration, 3),
        "generator": {"tool": "tools/rhythm/build_catalog.py", "version": 1, "both_notes": both_count},
        "notes": notes,
    }


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def write_json(path, obj):
    tmp = path + ".part"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1)
        f.write("\n")
    os.replace(tmp, path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--music-dir", default=MUSIC)
    ap.add_argument("--freeze-boss", action="store_true", help="sinh lại bản cố định của bài boss")
    a = ap.parse_args()
    music = a.music_dir
    with open(os.path.join(music, "songs.json"), encoding="utf-8") as f:
        songs = json.load(f)["songs"]
    charts_dir = os.path.join(music, "charts")
    fixed_dir = os.path.join(music, "fixed")
    os.makedirs(charts_dir, exist_ok=True)
    os.makedirs(fixed_dir, exist_ok=True)
    out_songs = []
    for s in songs:
        audio = os.path.join(music, s["file"])
        if not os.path.exists(audio):
            if "synth" not in s:
                print(f"BỎ QUA {s['id']}: thiếu file nhạc {s['file']}")
                continue
            gen_test_music.write_wav(audio, gen_test_music.render(s["synth"], float(s["bpm"])))
            print(f"đã tạo nhạc thử {s['file']}")
        keys = list(DEFAULT_CHARTS) + (["boss"] if s.get("boss") else [])
        charts = {}
        for key in keys:
            name = f"{s['id']}_{key}.json"
            fixed = os.path.join(fixed_dir, name)
            if key == "boss" and (a.freeze_boss or not os.path.exists(fixed)):
                write_json(fixed, make_chart(audio, s, key))
                print(f"đã ghi bản cố định {name}")
            if os.path.exists(fixed):
                with open(fixed, encoding="utf-8") as f:
                    chart = json.load(f)
            else:
                chart = make_chart(audio, s, key)
            out = os.path.join(charts_dir, name)
            write_json(out, chart)
            kinds = {}
            for n in chart["notes"]:
                kinds[n["kind"]] = kinds.get(n["kind"], 0) + 1
            charts[key] = {"file": name, "sha256": sha256(out), "bytes": os.path.getsize(out),
                           "level": chart["level"], "notes": len(chart["notes"])}
            bpm = chart["bpm"]
            print(f"  {name}: {len(chart['notes'])} nốt {kinds}, mức {chart['level']}")
        x, sr = read_audio(audio)
        out_songs.append({
            "id": s["id"], "title": s["title"], "artist": s.get("artist", ""), "bpm": bpm,
            "duration_sec": round(len(x) / sr, 2), "license": s.get("license", ""), "boss": bool(s.get("boss", False)),
            "audio": {"file": s["file"], "sha256": sha256(audio), "bytes": os.path.getsize(audio)},
            "charts": charts,
        })
    write_json(os.path.join(music, "catalog.json"), {"format": 1, "songs": out_songs})
    print(f"catalog.json: {len(out_songs)} bài")
    return 0


if __name__ == "__main__":
    sys.exit(main())
