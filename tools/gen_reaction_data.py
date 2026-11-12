"""Sinh 15 ReactionDef (data/reactions/{a}_{b}.tres) từ CHARACTER_SKILLS mục 8.4 và thêm khóa dịch tên phản ứng.
Chạy: python -X utf8 tools/gen_reaction_data.py   (ghi đè file .tres; file .po chỉ thêm khóa còn thiếu)
"""
import io
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data", "reactions")
FIRST_HIT, SELF, HIGHEST_HP = 0, 1, 2
CIRCLE = 1


def hit(ratio, radius, at=0, dur=100, tick=0, sc=1.0, knock=0, pull=False, statuses=()):
    return dict(at_ms=float(at), duration_ms=float(dur), atk_ratio=float(ratio), sc_multiplier=float(sc),
                shape=CIRCLE, radius_px=float(radius), offset=(0.0, -80.0), knockback_px=float(knock),
                pull_to_origin=pull, detached=True, tick_interval_ms=float(tick), statuses=list(statuses))


# (cặp, tên vi, tên en, chế độ, tầm, vùng đòn, tán xạ, trạng thái bản thân, hồi đội, xóa hiệu ứng xấu, nguồn)
R = [
    ("fire_wind", "Hỏa Lốc", "Firestorm", FIRST_HIT, 0, [hit(1.80, 260, statuses=[("burn", 5.0, -1)])], 0, [], 0, 0,
     "Hỏa + Phong: 180% ATK bán kính 260, Cháy 5s mọi kẻ địch trong vùng"),
    ("fire_lightning", "Quá Tải", "Overload", FIRST_HIT, 0, [hit(2.20, 220, sc=2.0, knock=200)], 0, [], 0, 0,
     "Hỏa + Lôi: 220% ATK bán kính 220, đẩy lùi 200 px, SC x2"),
    ("fire_light", "Nhật Thiêu", "Solar Scorch", FIRST_HIT, 0,
     [hit(1.60, 200, statuses=[("judgment", 5.0, -1)]), hit(0.20, 200, at=100, dur=3000, tick=500)], 0, [], 0, 0,
     "Hỏa + Quang: 160% ATK bán kính 200 + vùng lửa thánh 3s (20% mỗi 0.5s), Phán quyết 5s"),
    ("fire_dark", "Thiêu Hồn", "Soulburn", FIRST_HIT, 0,
     [hit(1.50, 220, statuses=[("burn", 5.0, 1.0), ("curse", 5.0, -1)])], 0, [], 0, 0,
     "Hỏa + Ám: 150% ATK bán kính 220, Cháy 5s tick gấp đôi (16%), Nguyền 5s"),
    ("fire_earth", "Dung Nham", "Magma", FIRST_HIT, 0,
     [hit(1.40, 200), hit(0.24, 200, at=100, dur=3000, tick=500, statuses=[("slow", 0.7, 0.30)])], 0, [], 0, 0,
     "Hỏa + Địa: 140% ATK bán kính 200 + vùng dung nham 3s (24% mỗi 0.5s), Chậm 30% trong vùng"),
    ("wind_lightning", "Bão Sét", "Thunderstorm", FIRST_HIT, 0,
     [hit(0.70, 110, at=i * 300, statuses=[("lightning_mark", -1, -1)]) for i in range(4)], 400, [], 0, 0,
     "Phong + Lôi: 4 tia x 70% = 280% rơi ngẫu nhiên trong 400 px mỗi 0.3s, mỗi tia 1 Dấu Sét"),
    ("wind_light", "Thanh Phong", "Gentle Breeze", SELF, 0, [hit(1.00, 240)], 0, [("wind_step", 5.0, 0.15)], 0.08, 1,
     "Phong + Quang: 100% ATK bán kính 240 tại nhân vật vào sân, hồi cả đội 8% HP tối đa, xóa 1 hiệu ứng xấu, +15% tốc độ 5s"),
    ("wind_dark", "Lốc Oán", "Wailing Vortex", FIRST_HIT, 0,
     [hit(0.30, 300, dur=1600, tick=400, knock=120, pull=True, statuses=[("curse", 4.0, -1)])], 0, [], 0, 0,
     "Phong + Ám: 4 nhịp x 30% = 120% bán kính 300 mỗi 0.4s, kéo kẻ địch vào tâm, Nguyền 4s"),
    ("wind_earth", "Bão Cát", "Sandstorm", FIRST_HIT, 0,
     [hit(0.15, 280, dur=4000, tick=500, statuses=[("slow", 0.7, 0.30), ("sand_blind", 4.0, 0.20)])], 0, [], 0, 0,
     "Phong + Địa: 8 nhịp x 15% = 120% trong 4s bán kính 280, Chậm 30%, Mù cát -20% sát thương 4s"),
    ("lightning_light", "Thần Phạt", "Divine Smite", HIGHEST_HP, 500, [hit(2.60, 0, sc=1.5, statuses=[("judgment", 6.0, -1)])],
     0, [], 0, 0, "Lôi + Quang: 260% ATK lên 1 mục tiêu HP cao nhất trong 500 px, Phán quyết 6s, SC x1.5"),
    ("lightning_dark", "Điện Hồn", "Soul Shock", FIRST_HIT, 0,
     [hit(1.70, 240, statuses=[("curse", 6.0, -1), ("slow", 3.0, 0.40)])], 0, [], 0, 0,
     "Lôi + Ám: 170% ATK bán kính 240, Nguyền 6s, Chậm 40% 3s"),
    ("lightning_earth", "Từ Chấn", "Magnetic Quake", FIRST_HIT, 0, [hit(2.00, 240, sc=2.5)], 0, [], 0, 0,
     "Lôi + Địa: 200% ATK bán kính 240, SC x2.5"),
    ("light_dark", "Nhật Thực", "Eclipse", FIRST_HIT, 0,
     [hit(2.00, 350, statuses=[("judgment", 5.0, -1), ("curse", 5.0, -1)])], 0, [], 0, 0,
     "Quang + Ám: 200% ATK bán kính 350, Phán quyết và Nguyền 5s"),
    ("light_earth", "Thánh Giáp", "Holy Aegis", SELF, 0, [hit(1.20, 200)], 0,
     [("shield", 6.0, 0.12), ("earth_guard", 6.0, 0.20)], 0, 0,
     "Quang + Địa: 120% ATK bán kính 200 tại nhân vật vào sân, Khiên 12% HP tối đa 6s, Giáp Địa -20% 6s"),
    ("dark_earth", "Địa Táng", "Earthen Tomb", FIRST_HIT, 0,
     [hit(1.80, 200, statuses=[("root", 2.0, -1), ("curse", 4.0, -1)])], 0, [], 0, 0,
     "Ám + Địa: 180% ATK bán kính 200, Trói 2.0s (boss 0.8s), Nguyền 4s"),
]


def fmt(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, tuple):
        return "Vector2(%s, %s)" % (float(v[0]), float(v[1]))
    if isinstance(v, float):
        return repr(v)
    if isinstance(v, int):
        return str(v)
    return '"%s"' % v


def st_sub(sid, s):
    return ('[sub_resource type="Resource" id="%s"]\nscript = ExtResource("3")\nstatus_id = "%s"\nduration = %s\n'
            'magnitude = %s\n' % (sid, s[0], float(s[1]), float(s[2])))


os.makedirs(OUT, exist_ok=True)
for key, vi, en, mode, rng, hits, scatter, self_st, heal, cleanse, source in R:
    subs, hit_ids, self_ids = [], [], []
    for i, h in enumerate(hits):
        st_ids = []
        for j, s in enumerate(h.pop("statuses")):
            st_ids.append("st_%d_%d" % (i, j))
            subs.append(st_sub(st_ids[-1], s))
        body = ['[sub_resource type="Resource" id="hit_%d"]' % i, 'script = ExtResource("2")']
        body += ["%s = %s" % (k, fmt(v)) for k, v in h.items()]
        body.append('statuses = Array[ExtResource("3")]([%s])' % ", ".join('SubResource("%s")' % s for s in st_ids))
        subs.append("\n".join(body) + "\n")
        hit_ids.append("hit_%d" % i)
    for j, s in enumerate(self_st):
        self_ids.append("self_%d" % j)
        subs.append(st_sub(self_ids[-1], s))
    a, b = key.split("_")
    lines = ['[gd_resource type="Resource" script_class="ReactionDef" load_steps=%d format=3]' % (len(subs) + 4), "",
             '[ext_resource type="Script" path="res://scripts/party/reaction_def.gd" id="1"]',
             '[ext_resource type="Script" path="res://scripts/combat/hit_def.gd" id="2"]',
             '[ext_resource type="Script" path="res://scripts/combat/status_application.gd" id="3"]', ""]
    lines += subs
    lines += ["[resource]", 'script = ExtResource("1")', 'id = "reaction.%s"' % key,
              'elements = PackedStringArray("%s", "%s")' % (a, b), 'name_key = "REACTION_%s"' % key.upper(),
              "target_mode = %d" % mode, "target_range_px = %s" % float(rng),
              'hits = Array[ExtResource("2")]([%s])' % ", ".join('SubResource("%s")' % h for h in hit_ids),
              "scatter_radius_px = %s" % float(scatter),
              'self_statuses = Array[ExtResource("3")]([%s])' % ", ".join('SubResource("%s")' % s for s in self_ids),
              "team_heal_max_hp_ratio = %s" % float(heal), "team_cleanse_count = %d" % cleanse,
              'metadata/source = "Mục 8.4 %s"' % source]
    with io.open(os.path.join(OUT, key + ".tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")

for po, idx in (("vi.po", 1), ("en.po", 2)):
    p = os.path.join(ROOT, "localization", po)
    s = io.open(p, encoding="utf-8").read()
    add = ""
    for row in R:
        k = "REACTION_%s" % row[0].upper()
        if 'msgid "%s"' % k not in s:
            add += '\nmsgid "%s"\nmsgstr "%s"\n' % (k, row[idx])
    if add:
        io.open(p, "w", encoding="utf-8", newline="\n").write(s.rstrip("\n") + "\n\n# Phản ứng nguyên tố (mục 8.4)" + add)
print("ok", len(R))
