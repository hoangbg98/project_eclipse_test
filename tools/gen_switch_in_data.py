"""Sinh Kĩ năng vào sân (switch_in Thường, switch_in_linked Liên kết) cho Aether, Lyra, Kael
từ CHARACTER_SKILLS mục 8.5–8.7: python tools/gen_switch_in_data.py
CẢNH BÁO: ghi đè data/skills/{id}/switch_in*.tres. Buff bản thân và giảm SI-CD nằm trong
data/characters/{id}.tres (SwitchInDef), sửa tay.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skill_data_lib import CIRCLE, RECT, SWITCH_IN, hit, wind_arrow, write_skill  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def skill_dir(cid):
    return os.path.join(ROOT, "data", "skills", cid)


def base(cid, linked, s, a, r, **kw):
    sid = "switch_in_linked" if linked else "switch_in"
    d = dict(id="%s.%s" % (cid, sid), key="switch_in", animation="switch_in", hit_kind=SWITCH_IN,
             startup_ms=float(s), active_ms=float(a), recovery_ms=float(r))
    d.update(kw)
    return sid, d


# --- Aether — Hỏa Ảnh Đột Kích (8.5): lao tối đa 350 px tới kẻ địch gần nhất trong 500 px (ưu tiên đang Choáng),
#     chém xuống bán kính 180. Thường 130% + Cháy 3s; Liên kết 190% + Cháy 5s, kẻ đang Choáng +30%.
#     220/120/260, bất tử 0–340. ---
for linked in (False, True):
    sid, d = base("char_fire_01", linked, 220, 120, 260, target_range_px=500.0, approach_target=True,
                  approach_max_px=350.0, approach_stop_px=80.0, target_prefer="stun",
                  move_from_ms=0.0, move_to_ms=220.0, invuln_from_ms=0.0, invuln_to_ms=340.0)
    extra = dict(bonus_vs_status="stun", bonus_vs_status_ratio=0.30) if linked else {}
    write_skill(sid, d, [hit(220, 120, 1.90 if linked else 1.30, shape=CIRCLE, radius=180, offset=(40, -100),
                             statuses=[("burn", 5.0 if linked else 3.0, -1.0)], **extra)],
                "Mục 8.5 Hỏa Ảnh Đột Kích (%s): lao 350/500 px ưu tiên Choáng, bán kính 180, %s, 220/120/260, bất tử 0-340"
                % ("Liên kết" if linked else "Thường",
                   "190% + Cháy 5s, Choáng +30%" if linked else "130% + Cháy 3s"),
                skill_dir("char_fire_01"))

# --- Lyra — Phong Dực Giáng Tiễn (8.6): 3 tên hình quạt ±15°, tầm 700 px. Thường 3×40%, Liên kết 3×60%.
#     Tên cuối đẩy lùi 100 px + Chậm 25% (Thường 2s, Liên kết 3s). 180/200/220, bất tử 0–380.
#     Ba tên bắn lần lượt trong pha hiệu lực (180, 230, 280 ms): chếch lên, chếch xuống, rồi thẳng (tên cuối). ---
for linked in (False, True):
    sid, d = base("char_wind_01", linked, 180, 200, 220, invuln_from_ms=0.0, invuln_to_ms=380.0)
    ratio = 0.60 if linked else 0.40
    arrows = []
    for i, angle in enumerate((-15.0, 15.0, 0.0)):
        last = i == 2
        arrows.append(hit(180 + i * 50, 300, ratio, shape=RECT, rect=(70, 24), offset=(50, -150),
                          detached=True, travel=700, knock=100 if last else 0,
                          statuses=[("slow", 3.0 if linked else 2.0, 0.25)] if last else [],
                          travel_angle_deg=angle, **wind_arrow()))
    write_skill(sid, d, arrows,
                "Mục 8.6 Phong Dực Giáng Tiễn (%s): 3 tên ±15° tầm 700, %s, tên cuối đẩy 100 + Chậm 25%% %s, 180/200/220, bất tử 0-380"
                % ("Liên kết" if linked else "Thường", "3x60%" if linked else "3x40%", "3s" if linked else "2s"),
                skill_dir("char_wind_01"))

# --- Kael — Lôi Ảnh Tập Kích (8.7): dịch chuyển tới kẻ địch gần nhất trong 600 px (ưu tiên đang mang hiệu ứng),
#     chém chữ X bán kính 150. Thường 2×55% + 1 Dấu Sét; Liên kết 2×80% + 2 Dấu Sét. 120/100/180, bất tử 0–220. ---
for linked in (False, True):
    sid, d = base("char_lightning_01", linked, 120, 100, 180, target_range_px=600.0, approach_target=True,
                  approach_max_px=600.0, approach_stop_px=70.0, teleport=True, target_prefer="elemental",
                  invuln_from_ms=0.0, invuln_to_ms=220.0)
    ratio = 0.80 if linked else 0.55
    mark = [("lightning_mark", -1.0, -1.0)]
    write_skill(sid, d, [hit(120, 50, ratio, shape=CIRCLE, radius=150, offset=(20, -100), statuses=mark),
                         hit(170, 50, ratio, shape=CIRCLE, radius=150, offset=(20, -100),
                             statuses=mark if linked else [])],
                "Mục 8.7 Lôi Ảnh Tập Kích (%s): dịch chuyển 600 px ưu tiên hiệu ứng, chữ X bán kính 150, %s, 120/100/180, bất tử 0-220"
                % ("Liên kết" if linked else "Thường", "2x80% + 2 Dấu Sét" if linked else "2x55% + 1 Dấu Sét"),
                skill_dir("char_lightning_01"))

print("ok")
