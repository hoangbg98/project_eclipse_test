"""Hàm dùng chung để sinh SkillDef .tres (gen_aether_data.py, gen_switch_in_data.py)."""
import os

# ResourceComponent.HitKind
NORMAL, HOLD, AIR, LANDING, SKILL, WEAPON, ULTIMATE, SWITCH_IN, NONE = range(9)
ARC, CIRCLE, RECT = range(3)


def fmt(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(float(v)) if isinstance(v, float) else str(v)
    if isinstance(v, tuple):
        return "Vector2(%s, %s)" % (float(v[0]), float(v[1]))
    return '"%s"' % v


def hit(at, dur, ratio, shape=ARC, radius=140, arc=120, tilt=0, rect=(100, 100), offset=(0, -120),
        sc=1.0, knock=0, statuses=(), detached=False, travel=0, tick=0, **extra):
    return dict(at_ms=float(at), duration_ms=float(dur), atk_ratio=float(ratio), sc_multiplier=float(sc),
                shape=shape, radius_px=float(radius), arc_deg=float(arc), arc_tilt_deg=float(tilt),
                rect_size=rect, offset=offset, knockback_px=float(knock), statuses=list(statuses),
                detached=detached, travel_px=float(travel), tick_interval_ms=float(tick), **extra)


def write_skill(name, skill, hits, source, skill_dir):
    ext = ['[ext_resource type="Script" path="res://scripts/combat/skill_def.gd" id="1"]',
           '[ext_resource type="Script" path="res://scripts/combat/hit_def.gd" id="2"]',
           '[ext_resource type="Script" path="res://scripts/combat/status_application.gd" id="3"]']
    subs, hit_ids = [], []
    for i, h in enumerate(hits):
        st_ids = []
        for j, st in enumerate(h.pop("statuses")):
            sid, dur, mag = st[0], st[1], st[2]
            st_id = "st_%d_%d" % (i, j)
            st_ids.append(st_id)
            extra = "on_self = true\n" if len(st) > 3 and st[3] else ""
            subs.append('[sub_resource type="Resource" id="%s"]\nscript = ExtResource("3")\nstatus_id = "%s"\n'
                        'duration = %s\nmagnitude = %s\n%s' % (st_id, sid, float(dur), float(mag), extra))
        hid = "hit_%d" % i
        hit_ids.append(hid)
        body = ['[sub_resource type="Resource" id="%s"]' % hid, 'script = ExtResource("2")']
        body += ["%s = %s" % (k, fmt(v)) for k, v in h.items()]
        body.append('statuses = Array[ExtResource("3")]([%s])' % ", ".join('SubResource("%s")' % s for s in st_ids))
        subs.append("\n".join(body) + "\n")
    lines = ['[gd_resource type="Resource" script_class="SkillDef" load_steps=%d format=3]' % (len(ext) + len(subs) + 1), ""]
    lines += [e for e in ext] + [""]
    lines += subs
    lines += ["[resource]", 'script = ExtResource("1")']
    lines += ["%s = %s" % (k, fmt(v)) for k, v in skill.items()]
    lines.append('hits = Array[ExtResource("2")]([%s])' % ", ".join('SubResource("%s")' % h for h in hit_ids))
    lines.append('metadata/source = "%s"' % source)
    os.makedirs(skill_dir, exist_ok=True)
    with open(os.path.join(skill_dir, name + ".tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
