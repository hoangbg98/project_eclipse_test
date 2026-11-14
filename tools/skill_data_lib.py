"""Hàm dùng chung để sinh SkillDef .tres (gen_aether_data.py, gen_switch_in_data.py, gen_*_skills.py)."""
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


# Mũi tên năng lượng gió của Kazeyumi (bộ phận số 42 trên tờ bộ phận), vẽ theo đạn tên (HitDef.projectile_sprite).
WIND_ARROW = "res://assets/characters/char_wind_01/vfx/char_wind_01_vfx_wind_arrow.png"


def wind_arrow(scale=0.55):
    """Trường HitDef để vẽ mũi tên gió đi theo vùng tên bay."""
    return dict(projectile_sprite=WIND_ARROW, projectile_scale=float(scale))


def hit(at, dur, ratio, shape=ARC, radius=140, arc=120, tilt=0, rect=(100, 100), offset=(0, -120),
        sc=1.0, knock=0, statuses=(), detached=False, travel=0, tick=0, **extra):
    return dict(at_ms=float(at), duration_ms=float(dur), atk_ratio=float(ratio), sc_multiplier=float(sc),
                shape=shape, radius_px=float(radius), arc_deg=float(arc), arc_tilt_deg=float(tilt),
                rect_size=rect, offset=offset, knockback_px=float(knock), statuses=list(statuses),
                detached=detached, travel_px=float(travel), tick_interval_ms=float(tick), **extra)


def heal(at, atk=0.0, hp=0.0, target="team", ticks=1, interval=0, ally_statuses=(), **extra):
    """HealDef: target "team" | "lowest" | "self" | "area" (radius_px, offset, at_target)."""
    d = dict(at_ms=float(at), atk_ratio=float(atk), max_hp_ratio=float(hp), target=target, ticks=int(ticks),
             interval_ms=float(interval), ally_statuses=list(ally_statuses))
    for k, v in extra.items():
        d[k] = float(v) if isinstance(v, int) and not isinstance(v, bool) and k not in ("cleanse",) else v
    return d


def _status_sub(st_id, st):
    extra = "on_self = true\n" if len(st) > 3 and st[3] else ""
    return ('[sub_resource type="Resource" id="%s"]\nscript = ExtResource("3")\nstatus_id = "%s"\n'
            'duration = %s\nmagnitude = %s\n%s' % (st_id, st[0], float(st[1]), float(st[2]), extra))


def _refs(ids):
    return ", ".join('SubResource("%s")' % s for s in ids)


def write_skill(name, skill, hits, source, skill_dir, self_statuses=(), heals=()):
    """self_statuses: [(id, thời gian, độ lớn)] áp lên người dùng lúc bắt đầu (SkillDef.self_statuses).
    heals: danh sách dict từ heal() (SkillDef.heals)."""
    ext = ['[ext_resource type="Script" path="res://scripts/combat/skill_def.gd" id="1"]',
           '[ext_resource type="Script" path="res://scripts/combat/hit_def.gd" id="2"]',
           '[ext_resource type="Script" path="res://scripts/combat/status_application.gd" id="3"]']
    if heals:
        ext.append('[ext_resource type="Script" path="res://scripts/combat/heal_def.gd" id="4"]')
    subs, hit_ids = [], []
    for i, h in enumerate(hits):
        h = dict(h)
        st_ids = []
        for j, st in enumerate(h.pop("statuses")):
            st_id = "st_%d_%d" % (i, j)
            st_ids.append(st_id)
            subs.append(_status_sub(st_id, st))
        hid = "hit_%d" % i
        hit_ids.append(hid)
        body = ['[sub_resource type="Resource" id="%s"]' % hid, 'script = ExtResource("2")']
        body += ["%s = %s" % (k, fmt(v)) for k, v in h.items()]
        body.append('statuses = Array[ExtResource("3")]([%s])' % _refs(st_ids))
        subs.append("\n".join(body) + "\n")
    self_ids = []
    for j, st in enumerate(self_statuses):
        st_id = "self_%d" % j
        self_ids.append(st_id)
        subs.append(_status_sub(st_id, st))
    heal_ids = []
    for i, hd in enumerate(heals):
        hd = dict(hd)
        st_ids = []
        for j, st in enumerate(hd.pop("ally_statuses")):
            st_id = "hst_%d_%d" % (i, j)
            st_ids.append(st_id)
            subs.append(_status_sub(st_id, st))
        hid = "heal_%d" % i
        heal_ids.append(hid)
        body = ['[sub_resource type="Resource" id="%s"]' % hid, 'script = ExtResource("4")']
        body += ["%s = %s" % (k, fmt(v)) for k, v in hd.items()]
        body.append('ally_statuses = Array[ExtResource("3")]([%s])' % _refs(st_ids))
        subs.append("\n".join(body) + "\n")
    lines = ['[gd_resource type="Resource" script_class="SkillDef" load_steps=%d format=3]' % (len(ext) + len(subs) + 1), ""]
    lines += [e for e in ext] + [""]
    lines += subs
    lines += ["[resource]", 'script = ExtResource("1")']
    lines += ["%s = %s" % (k, fmt(v)) for k, v in skill.items()]
    lines.append('hits = Array[ExtResource("2")]([%s])' % _refs(hit_ids))
    if self_ids:
        lines.append('self_statuses = Array[ExtResource("3")]([%s])' % _refs(self_ids))
    if heal_ids:
        lines.append('heals = Array[ExtResource("4")]([%s])' % _refs(heal_ids))
    lines.append('metadata/source = "%s"' % source)
    os.makedirs(skill_dir, exist_ok=True)
    with open(os.path.join(skill_dir, name + ".tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


def write_hitdef_resource(path, script_class, script_path, config_lines, hitdefs, source):
    """Ghi config kit (.tres) có các HitDef con. hitdefs: {tên thuộc tính: dict từ hit()}."""
    ext = ['[ext_resource type="Script" path="%s" id="1"]' % script_path,
           '[ext_resource type="Script" path="res://scripts/combat/hit_def.gd" id="2"]',
           '[ext_resource type="Script" path="res://scripts/combat/status_application.gd" id="3"]']
    subs, props = [], []
    for name, h in hitdefs.items():
        h = dict(h)
        st_ids = []
        for j, st in enumerate(h.pop("statuses")):
            st_id = "%s_st_%d" % (name, j)
            st_ids.append(st_id)
            subs.append(_status_sub(st_id, st))
        body = ['[sub_resource type="Resource" id="%s"]' % name, 'script = ExtResource("2")']
        body += ["%s = %s" % (k, fmt(v)) for k, v in h.items()]
        body.append('statuses = Array[ExtResource("3")]([%s])' % _refs(st_ids))
        subs.append("\n".join(body) + "\n")
        props.append('%s = SubResource("%s")' % (name, name))
    lines = ['[gd_resource type="Resource" script_class="%s" load_steps=%d format=3]' % (script_class, len(ext) + len(subs) + 1), ""]
    lines += ext + [""] + subs
    lines += ["[resource]", 'script = ExtResource("1")'] + list(config_lines) + props
    lines.append('metadata/source = "%s"' % source)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
