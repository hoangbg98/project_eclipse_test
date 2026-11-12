"""Sinh đòn thường + né của Kael (char_lightning_01) và Lyra (char_wind_01) theo CHARACTER_SKILLS mục 2, 3 (phạm vi Q5).
Chạy: python -X utf8 tools/gen_kael_lyra_data.py   (ghi đè normal_*.tres và dodge.tres của hai nhân vật)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skill_data_lib import NONE, NORMAL, RECT, hit, write_skill  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def base(cid, sid, key, anim, kind, s, a, r, **kw):
    d = dict(id="%s.%s" % (cid, sid), key=key, animation=anim, hit_kind=kind,
             startup_ms=float(s), active_ms=float(a), recovery_ms=float(r))
    d.update(kw)
    return d


# ================= Kael — Lôi Nhận Liên Hoàn (5 đòn): 110 px, mỗi đòn tiến 50 px =================
K = "char_lightning_01"
KD = os.path.join(ROOT, "data", "skills", K)
MARK = ("lightning_mark", -1.0, -1.0)
ratios = [0.45, 0.45, 0.55, 0.55, 1.10]
for i in range(5):
    n = i + 1
    last = n == 5
    s, a, r = (130, 90, 260) if last else (70, 50, 110)
    extra = {} if last else dict(chain_window_ms=180.0, next_skill="normal_%d" % (n + 1))
    write_skill("normal_%d" % n,
                base(K, "normal_%d" % n, "normal", "attack_%d" % n, NORMAL, s, a, r,
                     move_px=50.0, move_from_ms=0.0, move_to_ms=float(s + a), **extra),
                [hit(s, a, ratios[i], radius=110, knock=80 if last else 0, statuses=[MARK] if n in (2, 4, 5) else [])],
                "Mục 3 Lôi Nhận Liên Hoàn Đ%d: %d%%%s%s, %d/%d/%d" % (
                    n, round(ratios[i] * 100), ", 1 Dấu Sét" if n in (2, 4, 5) else "",
                    ", đẩy lùi 80 px" if last else "", s, a, r), KD)

# Né — Thiểm Điện: dịch chuyển 320 px xuyên kẻ địch, tia điện 40% trên đường đi, bất tử 20–200 ms, 20/180/100
write_skill("dodge", base(K, "dodge", "dodge", "dodge", NONE, 20, 180, 100,
            move_px=320.0, move_from_ms=20.0, move_to_ms=20.0, teleport=True, suspend_gravity=True,
            invuln_from_ms=20.0, invuln_to_ms=200.0),
            [hit(20, 120, 0.40, shape=RECT, rect=(320, 80), offset=(-160, -90), detached=True)],  # tia nối điểm đến về điểm xuất phát
            "Mục 3 Thiểm Điện: dịch chuyển 320 px, tia điện 40% trên đường đi, bất tử 20-200 ms, 20/180/100", KD)

# ================= Lyra — Phong Tiễn (3 phát): tên 1800 px/s, tối đa 700 px =================
L = "char_wind_01"
LD = os.path.join(ROOT, "data", "skills", L)
FLY = round(700 / 1800 * 1000)  # 389 ms


def arrow(at, ratio, max_targets, statuses=(), travel=700, fly=FLY):
    return hit(at, fly, ratio, shape=RECT, rect=(70, 24), offset=(50, -150), detached=True, travel=travel,
               statuses=statuses, max_targets=max_targets)


for n, (s, a, r, ratio) in enumerate([(100, 40, 140, 0.55), (100, 40, 140, 0.55), (180, 60, 260, 0.90)], start=1):
    last = n == 3
    extra = {} if last else dict(chain_window_ms=200.0, next_skill="normal_%d" % (n + 1))
    write_skill("normal_%d" % n, base(L, "normal_%d" % n, "normal", "attack_%d" % n, NORMAL, s, a, r, **extra),
                [arrow(s, ratio, 2 if last else 1, statuses=[("slow", 2.0, 0.20)] if last else [])],
                "Mục 2 Phong Tiễn P%d: %d%%, tên 1800 px/s tầm 700%s, %d/%d/%d" % (
                    n, round(ratio * 100), ", xuyên 2 mục tiêu, Chậm 20% 2s" if last else "", s, a, r), LD)

# Né — Lộn Gió Lùi: lộn về sau 240 px, bắn 1 tên về trước (tầm 500) 40%, bất tử 30–190 ms, 30/160/110
write_skill("dodge", base(L, "dodge", "dodge", "dodge", NONE, 30, 160, 110,
            move_px=-240.0, move_from_ms=30.0, move_to_ms=190.0, suspend_gravity=True,
            invuln_from_ms=30.0, invuln_to_ms=190.0),
            [arrow(110, 0.40, 1, travel=500, fly=round(500 / 1800 * 1000))],
            "Mục 2 Lộn Gió Lùi: lộn lùi 240 px, tên 40% tầm 500 px, bất tử 30-190 ms, 30/160/110", LD)
print("ok")
