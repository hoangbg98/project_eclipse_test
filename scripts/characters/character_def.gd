class_name CharacterDef
extends Resource
## Định nghĩa tĩnh một nhân vật (README 4). Dữ liệu ở data/characters/{id}.tres.

@export var id := ""
## Khóa dịch tên hiển thị (tên tạm, đổi trước khi công khai).
@export var name_key := ""
@export var element := ""
@export var stats: CombatStats
@export var movement: MovementConfig
## Thư mục chứa SkillDef của nhân vật.
@export_dir var skills_dir := ""


## Nạp mọi SkillDef trong skills_dir, khóa theo `key` của file (tên file không đuôi).
func load_skills() -> Dictionary:
	var out := {}
	if skills_dir.is_empty():
		return out
	for f in ResourceLoader.list_directory(skills_dir):
		if f.get_extension() not in ["tres", "res"]:
			continue
		var s := load(skills_dir.path_join(f)) as SkillDef
		if s:
			out[f.get_basename()] = s
	return out
