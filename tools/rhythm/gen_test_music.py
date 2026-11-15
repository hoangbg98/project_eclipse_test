"""Sinh nhạc thử (điện tử đơn giản) cho chế độ nhịp điệu (M10).

Owner 2026-11-16: Claude sinh nhạc thử để làm và thử chế độ nhịp điệu; nhạc thật thay sau.
Chỉ dùng numpy + thư viện chuẩn. Kết quả: WAV 22 050 Hz, 16-bit, mono. Cùng spec + seed => cùng file.

Spec (mục "synth" trong server/music/songs.json):
  {"seed": n, "root": nốt MIDI gốc, "scale": "minor"|"major"|"dorian"|..., "sections": [[tên, số ô nhịp], ...]}
Các đoạn:
  intro / outro : trống nhẹ + pad
  verse         : trống, bass, arpeggio nhẹ
  chorus        : trống đầy, bass, lead 16 nốt, pad
  hold          : nốt lead ngân dài 1-2 phách (để sinh nốt giữ)
  roll          : dồn trống snare 16 / 32 nốt (để sinh nốt ấn liên tục)

Dùng: python -X utf8 tools/rhythm/gen_test_music.py <songs.json> [--only id] [--out-dir dir]
"""
import argparse
import json
import os
import sys
import wave

import numpy as np

SR = 22050

SCALES = {
    "major": [0, 2, 4, 5, 7, 9, 11],
    "minor": [0, 2, 3, 5, 7, 8, 10],
    "dorian": [0, 2, 3, 5, 7, 9, 10],
    "phrygian": [0, 1, 3, 5, 7, 8, 10],
    "mixolydian": [0, 2, 4, 5, 7, 9, 10],
    "harmonic_minor": [0, 2, 3, 5, 7, 8, 11],
}
# Vòng hợp âm theo bậc (0 = bậc I).
PROGRESSIONS = [[0, 5, 3, 4], [0, 3, 4, 3], [0, 6, 5, 4], [5, 3, 0, 4]]


def midi_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def env_exp(n, decay):
    t = np.arange(n) / SR
    return np.exp(-t / decay)


def kick(n):
    t = np.arange(n) / SR
    f = 40 + 90 * np.exp(-t / 0.04)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * env_exp(n, 0.16)


def snare(n, rng):
    t = np.arange(n) / SR
    noise = rng.standard_normal(n)
    noise = noise - np.concatenate([[0], noise[:-1]]) * 0.6  # bỏ bớt trầm
    tone = np.sin(2 * np.pi * 185 * t) * env_exp(n, 0.05)
    return (noise * env_exp(n, 0.09) * 0.55 + tone * 0.5)


def hat(n, rng):
    noise = rng.standard_normal(n)
    hp = noise - np.concatenate([[0], noise[:-1]])
    return hp * env_exp(n, 0.025) * 0.25


def saw(freq, n, bright=1.0):
    t = np.arange(n) / SR
    out = np.zeros(n)
    for k in range(1, 9):
        out += ((-1) ** (k + 1)) * np.sin(2 * np.pi * freq * k * t) / k * (bright ** (k - 1))
    return out * 0.6


def square(freq, n):
    t = np.arange(n) / SR
    out = np.zeros(n)
    for k in (1, 3, 5, 7):
        out += np.sin(2 * np.pi * freq * k * t) / k
    return out * 0.7


def add(buf, start, sig, gain):
    if start >= len(buf):
        return
    end = min(len(buf), start + len(sig))
    buf[start:end] += sig[: end - start] * gain


def render(spec, bpm):
    rng = np.random.default_rng(int(spec.get("seed", 1)))
    root = int(spec.get("root", 57))
    scale = SCALES.get(spec.get("scale", "minor"), SCALES["minor"])
    sections = spec["sections"]
    beat = 60.0 / bpm
    total_bars = sum(int(b) for _, b in sections)
    n_total = int((total_bars * 4 + 2) * beat * SR)
    drums = np.zeros(n_total)
    bass = np.zeros(n_total)
    lead = np.zeros(n_total)
    pad = np.zeros(n_total)
    prog = PROGRESSIONS[int(rng.integers(len(PROGRESSIONS)))]

    def deg_note(deg, octave=0):
        return root + scale[deg % 7] + 12 * (deg // 7 + octave)

    def at(b):  # phách -> mẫu
        return int(round(b * beat * SR))

    # Giai điệu lặp: 16 bậc ngẫu nhiên theo seed, mỗi đoạn biến tấu nhẹ.
    motif = [int(x) for x in rng.integers(0, 8, 16)]
    bar0 = 0
    for name, bars in sections:
        bars = int(bars)
        for bar in range(bars):
            b0 = (bar0 + bar) * 4
            chord = prog[(bar0 + bar) % 4]
            # --- Trống ---
            if name in ("intro", "outro"):
                for q in range(4):
                    add(drums, at(b0 + q), kick(at(0.5)), 0.8 if q % 2 == 0 else 0.0)
                    add(drums, at(b0 + q + 0.5), hat(at(0.25), rng), 0.8)
            elif name == "roll":
                add(drums, at(b0), kick(at(0.5)), 0.9)
                steps = 16 if bar < bars - 1 else 32
                for s in range(steps):
                    add(drums, at(b0 + s * 4.0 / steps), snare(at(0.12), rng), 0.45 + 0.4 * s / steps)
            else:
                full = name == "chorus"
                for q in range(4):
                    if q in (0, 2) or (full and q == 3 and bar % 2 == 1):
                        add(drums, at(b0 + q), kick(at(0.5)), 1.0)
                    if q in (1, 3):
                        add(drums, at(b0 + q), snare(at(0.25), rng), 0.75)
                    for h in (0.0, 0.5) if not full else (0.0, 0.25, 0.5, 0.75):
                        add(drums, at(b0 + q + h), hat(at(0.12), rng), 0.7)
            # --- Bass: nốt 8 ---
            if name not in ("intro",):
                bn = deg_note(chord, -2)
                for e in range(8):
                    if name == "outro" and e % 2:
                        continue
                    sig = saw(midi_hz(bn + (12 if e % 4 == 3 else 0)), at(0.45), bright=0.5) * env_exp(at(0.45), 0.18)
                    add(bass, at(b0 + e * 0.5), sig, 0.45)
            # --- Pad: hợp âm ngân cả ô nhịp ---
            if name in ("intro", "chorus", "hold", "outro"):
                n = at(4.0)
                ch = np.zeros(n)
                for d in (0, 2, 4):
                    ch += np.sin(2 * np.pi * midi_hz(deg_note(chord + d)) * np.arange(n) / SR)
                fade = np.minimum(1.0, np.minimum(np.arange(n) / (0.3 * SR), (n - np.arange(n)) / (0.3 * SR)))
                add(pad, at(b0), ch * fade, 0.07)
            # --- Lead ---
            if name == "chorus":
                for s in range(16):
                    if s % 4 == 3 and rng.random() < 0.4:
                        continue
                    deg = chord + motif[(s + bar * 3) % 16]
                    sig = saw(midi_hz(deg_note(deg, 1)), at(0.24), bright=0.8) * env_exp(at(0.24), 0.07)
                    add(lead, at(b0 + s * 0.25), sig, 0.22)
            elif name == "verse":
                for e in range(8):
                    if e % 2 == 1 and rng.random() < 0.5:
                        continue
                    deg = chord + (0, 2, 4, 7)[e % 4]
                    sig = square(midi_hz(deg_note(deg, 1)), at(0.4)) * env_exp(at(0.4), 0.09)
                    add(lead, at(b0 + e * 0.5), sig, 0.12)
            elif name == "hold":
                # Hai nốt ngân 2 phách / ô nhịp (nốt giữ).
                for h in (0, 2):
                    n = at(1.9)
                    deg = chord + motif[(bar * 2 + h) % 16] % 5
                    env = np.minimum(1.0, np.arange(n) / (0.01 * SR)) * np.exp(-np.arange(n) / SR / 3.0)
                    env[-at(0.08):] *= np.linspace(1, 0, at(0.08))
                    add(lead, at(b0 + h), square(midi_hz(deg_note(deg, 1)), n) * env, 0.16)
        bar0 += bars
    mix = drums * 0.55 + bass + lead + pad
    # Nén nhẹ + chuẩn hóa.
    mix = np.tanh(mix * 1.2)
    peak = np.max(np.abs(mix)) or 1.0
    mix = mix / peak * 0.89
    # Fade out 1 s cuối.
    f = min(len(mix), SR)
    mix[-f:] *= np.linspace(1, 0, f)
    return mix


def write_wav(path, samples):
    data = (np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes()
    tmp = path + ".part"
    with wave.open(tmp, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    os.replace(tmp, path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("songs_json")
    ap.add_argument("--only", default="")
    ap.add_argument("--out-dir", default="")
    ap.add_argument("--force", action="store_true", help="ghi đè file đã có")
    a = ap.parse_args()
    with open(a.songs_json, encoding="utf-8") as f:
        songs = json.load(f)["songs"]
    out_dir = a.out_dir or os.path.dirname(os.path.abspath(a.songs_json))
    made = 0
    for s in songs:
        if "synth" not in s or (a.only and s["id"] != a.only):
            continue
        path = os.path.join(out_dir, s["file"])
        if os.path.exists(path) and not a.force:
            print(f"có sẵn: {s['file']}")
            continue
        mix = render(s["synth"], float(s["bpm"]))
        write_wav(path, mix)
        made += 1
        print(f"đã tạo {s['file']}: {len(mix) / SR:.1f} s, {os.path.getsize(path) // 1024} KB")
    print(f"xong, tạo {made} file")
    return 0


if __name__ == "__main__":
    sys.exit(main())
