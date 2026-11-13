class_name SkillText
extends RefCounted
## Tên và mô tả kỹ năng cho màn Nhân vật. Mô tả sinh từ SkillDef (sát thương, tiêu hao, hồi chiêu, trạng thái, thời gian
## các pha) nên luôn khớp số trong data/; chỉ tên kỹ năng và câu mô tả nội tại nằm trong localization.
## Khóa tên: SKILL_{ID bỏ "char_" viết hoa}_{NHÓM viết hoa}, vd SKILL_FIRE_01_ULTIMATE.

const GROUP_ORDER: Array[String] = ["switch_in", "special", "passive", "skill", "ultimate", "dodge", "normal", "weapon"]
const STATUS_GROUP_PASSIVE := "passive"


static func name_key(character_id: String, group: String) -> String:
	return "SKILL_%s_%s" % [character_id.trim_prefix("char_").to_upper(), group.to_upper()]


static func skill_name(character_id: String, group: String) -> String:
	var k := name_key(character_id, group)
	var t := TranslationServer.translate(k)
	return t if t != k else TranslationServer.translate("SKILL_GROUP_" + group.to_upper())


static func group_label(group: String) -> String:
	return TranslationServer.translate("SKILL_GROUP_" + group.to_upper())


## Chữ tắt cho biểu tượng tròn khi chưa có icon: chữ cái đầu mỗi từ, tối đa 3 ("Kĩ năng vũ khí" → "KNV").
static func group_abbr(group: String) -> String:
	var out := ""
	for w in group_label(group).split(" ", false):
		out += w.substr(0, 1).to_upper()
	return out.substr(0, 3)


## Khóa file (vd "normal_2") của mọi kỹ năng thuộc nhóm, theo thứ tự tên file.
static func skills_in_group(skills: Dictionary, group: String) -> PackedStringArray:
	var keys: Array = Progression.SKILL_GROUPS.get(group, [])
	var out := PackedStringArray()
	for k: String in skills:
		var s: SkillDef = skills[k]
		if s.key in keys:
			out.append(k)
	out.sort()
	return out


## Nhãn ngắn cho một kỹ năng con: "normal_2" → "Đòn 2", "switch_in_linked" → "Liên kết".
static func sub_label(file_key: String) -> String:
	var parts := file_key.rsplit("_", true, 1)
	if parts.size() == 2 and parts[1].is_valid_int():
		var k := "SUBSKILL_" + parts[0].to_upper()
		var t := TranslationServer.translate(k)
		if t != k:
			return t % int(parts[1])
	var k2 := "SUBSKILL_" + file_key.to_upper()
	var t2 := TranslationServer.translate(k2)
	return t2 if t2 != k2 else file_key


static func _pct(v: float) -> String:
	return ("%.1f" % (v * 100.0)).trim_suffix(".0") + "%"


static func _hl(text: String) -> String:
	return "[color=#7FD4FF]%s[/color]" % text


## Mô tả BBCode của một kỹ năng ở cấp `level`. `brief`: chỉ sát thương, tiêu hao, hồi chiêu.
static func describe(s: SkillDef, level: int, rules: CombatRules, brief: bool) -> String:
	var tr := TranslationServer
	var lines := PackedStringArray()
	var mult := DamageCalculator.level_multiplier(rules, level) if rules else 1.0
	var total := s.total_atk_ratio()
	if total > 0.0:
		lines.append(tr.translate("SKILLTXT_DAMAGE") % [_hl(_pct(total * mult)), s.hits.size()])
	var cost := PackedStringArray()
	if s.en_cost > 0.0:
		cost.append(tr.translate("SKILLTXT_EN") % int(s.en_cost))
	if s.ug_cost > 0.0:
		cost.append(tr.translate("SKILLTXT_UG") % int(s.ug_cost))
	if s.cooldown_sec > 0.0:
		cost.append(tr.translate("SKILLTXT_CD") % ("%.1f" % s.cooldown_sec).trim_suffix(".0"))
	if not cost.is_empty():
		lines.append(" · ".join(cost))
	if brief:
		return "\n".join(lines)
	var statuses := PackedStringArray()
	for h in s.hits:
		for st in h.statuses:
			var nm := tr.translate("STATUS_" + st.status_id.to_upper())
			var txt := _hl(nm) + ((" %ss" % ("%.1f" % st.duration).trim_suffix(".0")) if st.duration > 0.0 else "")
			if txt not in statuses:
				statuses.append(txt)
	if not statuses.is_empty():
		lines.append(tr.translate("SKILLTXT_STATUSES") % ", ".join(statuses))
	lines.append(tr.translate("SKILLTXT_TIMING") % [int(s.startup_ms), int(s.active_ms), int(s.recovery_ms)])
	if s.invuln_from_ms >= 0.0 and s.invuln_to_ms > s.invuln_from_ms:
		lines.append(tr.translate("SKILLTXT_INVULN") % [int(s.invuln_from_ms), int(s.invuln_to_ms)])
	if s.super_armor:
		lines.append(tr.translate("SKILLTXT_SUPER_ARMOR"))
	if s.move_px != 0.0 or s.approach_target:
		lines.append(tr.translate("SKILLTXT_MOVE") % int(absf(s.approach_max_px if s.approach_target else s.move_px)))
	return "\n".join(lines)


## Mô tả nội tại (không có SkillDef): câu trong localization, số lấy từ cấu hình kit của nhân vật.
static func passive_text(def: CharacterDef) -> String:
	if def == null:
		return ""
	var tr := TranslationServer
	var key := "SKILL_%s_PASSIVE_DESC" % def.id.trim_prefix("char_").to_upper()
	var cfg := def.kit_config
	if cfg is FireKitConfig:
		var c := cfg as FireKitConfig
		return tr.translate(key) % [_pct(c.heat_atk_per_stack), _pct(c.heat_full_bonus), c.ug_bonus_heat_threshold,
				_pct(c.ug_bonus_multiplier - 1.0)]
	if cfg is LightningKitConfig:
		var k := cfg as LightningKitConfig
		var burst := k.burst.atk_ratio if k.burst else 0.0
		return tr.translate(key) % [_pct(burst), k.burst_icd_per_target_sec, _pct(k.burst_attack_speed), k.burst_attack_speed_sec]
	if cfg is WindKitConfig:
		var w := cfg as WindKitConfig
		return tr.translate(key) % [_pct(w.perfect_dodge_speed), w.perfect_dodge_speed_sec, int(w.perfect_dodge_en)]
	var t := tr.translate(key)
	return t if t != key else tr.translate("SKILLTXT_NO_PASSIVE")


## Dòng giải thích từ ngữ cho các trạng thái (nút "Giải thích từ ngữ").
static func glossary_lines(lib: StatusLibrary) -> PackedStringArray:
	var out := PackedStringArray()
	if lib == null:
		return out
	var tr := TranslationServer
	for id in lib.ids():
		var d := lib.get_status(id)
		var parts := PackedStringArray()
		if d.default_duration > 0.0:
			parts.append(tr.translate("GLOSS_DURATION") % ("%.1f" % d.default_duration).trim_suffix(".0"))
		if d.tick_interval_sec > 0.0:
			parts.append(tr.translate("GLOSS_TICK") % [_pct(d.tick_atk_ratio), ("%.1f" % d.tick_interval_sec).trim_suffix(".0")])
		if d.magnitude_meaning != "":
			parts.append(tr.translate("GLOSS_" + d.magnitude_meaning.to_upper()) % _pct(d.default_magnitude))
		if d.max_stacks > 1:
			parts.append(tr.translate("GLOSS_STACKS") % d.max_stacks)
		if d.blocks_actions:
			parts.append(tr.translate("GLOSS_BLOCKS_ACTIONS"))
		elif d.blocks_movement:
			parts.append(tr.translate("GLOSS_BLOCKS_MOVEMENT"))
		out.append("%s: %s" % [_hl(tr.translate(d.name_key)), ", ".join(parts) if not parts.is_empty() else "—"])
	return out
