class_name CharacterDef
extends Resource
## Định nghĩa tĩnh một nhân vật (README 4). Dữ liệu ở data/characters/{id}.tres.

## Mỗi CharacterDef là một **giáp** (owner 2026-11-13): một nhân vật có thể có nhiều giáp với hạng khác nhau.
@export var id := ""
## Khóa dịch tên nhân vật (vd "Enkiba"); các giáp cùng nhân vật dùng cùng tên.
@export var name_key := ""
## Nhân vật mà giáp này thuộc về (vd "enkiba"). Đội không được có hai giáp cùng nhân vật. Rỗng = dùng `id`.
@export var person_id := ""
## Khóa dịch tên giáp (vd "Hỏa Diễm Mãnh Liệt").
@export var suit_key := ""
@export var element := ""
## Hạng nhân vật trong chiêu mộ: "S", "A" hoặc "B" (owner gán; rỗng = chưa gán, UI hiện "?").
@export var rank := ""
## Loại vũ khí dùng được ("sword", "bow", "dual_blades", "staff", "scythe", "greatsword"); khớp EquipmentDef.weapon_type.
@export var weapon_type := ""
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
## Buff và giảm SI-CD riêng của Kĩ năng vào sân (null = không có).
@export var switch_in: SwitchInDef


func person() -> String:
	return person_id if person_id != "" else id


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
