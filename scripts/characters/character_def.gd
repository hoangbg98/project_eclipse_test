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
## Logic riêng của nhân vật (nội tại, rút hồi chiêu riêng...): script Node có hàm attach(player, config).
@export var kit_script: Script
## Số liệu của kit (Resource riêng theo nhân vật).
@export var kit_config: Resource

@export_group("Vào sân (mục 8.3)")
## Điều kiện Liên kết: việc nhân vật trên sân làm để icon của nhân vật này sáng (hằng số LinkTracker.COND_*).
@export_enum("enemy_stunned", "perfect_dodge", "elemental_status", "low_hp", "enemy_defeated",
		"weapon_or_ultimate") var link_condition := "enemy_stunned"
## SI-CD: hồi chiêu vào sân (s), chịu CDR chung.
@export var switch_in_cd_sec := 10.0


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
