"""Tổng hợp âm thanh tạm (placeholder) bằng code cho các sự kiện chưa có file của owner.
Chạy: python -X utf8 -I tools/gen_placeholder_sfx.py
Ra: assets/placeholders/placeholder_sfx_gacha_5star.wav — chuông ngân đi lên khi ra thẻ 5★ ở màn Chiêu mộ.
AudioRouter dùng file placeholder_* khi chưa có assets/audio/sfx/{id}; bản Release loại *placeholder_* nên im lặng.
Chỉ dùng thư viện chuẩn (wave, math, random có seed).
"""
import math
import os
import random
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "placeholders")
RATE = 44100


def bell(freq, t, decay):
    # Tiếng chuông: cơ bản + hai họa âm lệch (không nguyên lần) tắt nhanh hơn.
    env = math.exp(-t * decay)
    return env * (math.sin(2 * math.pi * freq * t) * 0.6
                  + math.sin(2 * math.pi * freq * 2.01 * t) * 0.25 * math.exp(-t * 2.0)
                  + math.sin(2 * math.pi * freq * 3.98 * t) * 0.12 * math.exp(-t * 4.0))


def gacha_5star():
    rnd = random.Random(5)
    dur = 2.2
    n = int(RATE * dur)
    buf = [0.0] * n
    # Arpeggio đi lên: C6 E6 G6 C7, cách nhau 0.09 s.
    for k, f in enumerate([1046.5, 1318.5, 1568.0, 2093.0]):
        start = int(RATE * 0.09 * k)
        for i in range(start, n):
            t = (i - start) / RATE
            buf[i] += bell(f, t, 2.2) * 0.32
    # Lấp lánh: các chấm cao ngẫu nhiên (seed cố định) trong 1.2 s đầu.
    for _ in range(28):
        start = int(RATE * rnd.uniform(0.05, 1.2))
        f = rnd.uniform(2600, 5200)
        for i in range(start, min(n, start + int(RATE * 0.35))):
            t = (i - start) / RATE
            buf[i] += math.sin(2 * math.pi * f * t) * math.exp(-t * 14) * 0.06
    # Tiếng vang đơn giản (hai đường trễ).
    for delay, gain in ((int(RATE * 0.11), 0.28), (int(RATE * 0.23), 0.16)):
        for i in range(n - 1, delay - 1, -1):
            buf[i] += buf[i - delay] * gain
    peak = max(abs(x) for x in buf) or 1.0
    fade = int(RATE * 0.3)
    frames = bytearray()
    for i, x in enumerate(buf):
        v = x / peak * 0.85
        if i > n - fade:
            v *= (n - i) / fade
        frames += struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767))
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, "placeholder_sfx_gacha_5star.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(frames))


gacha_5star()
print("ok")
