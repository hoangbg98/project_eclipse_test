extends SceneTree
## Chụp ảnh các tab của Hub để soát bố cục bằng mắt (cần cửa sổ, không chạy --headless):
##   <godot> --path . -s tools/screenshot_hub.gd
## Ảnh ra build/screenshots/hub_<tab>.png. Chỉ thêm đồ vào bộ nhớ để có gì mà xem; KHÔNG ghi save.

const TABS := ["HomeTab", "BattleTab", "CharactersTab", "RecruitTab", "SettingsTab"]

var _frames := 0
var _hub: Control
var _index := 0


func _initialize() -> void:
	pass


## Gọi ở khung đầu tiên: lúc này các autoload đã chạy xong _ready (SaveService đã đọc save).
func _prepare() -> void:
	var save := root.get_node_or_null("SaveService")
	if save:
		# Dữ liệu tạm trong bộ nhớ: không đụng tới file save của người chơi.
		save.data = SaveSchema.default_data()
		var p := PlayerProfile.new(save.data)
		p.inventory.add_currency("gold", 12345)
		p.inventory.add_currency("gems", 678)
		p.inventory.add_material("mat_exp_small", 5)
		p.inventory.add_material("mat_exp_medium", 2)
		p.inventory.add_material("mat_enhance_ore", 9)
		p.inventory.equip("char_fire_01", p.inventory.add_equipment("eq_weapon_flame"))
		p.inventory.add_equipment("eq_stigma_mid_hide")
		p.progression.add_exp("char_fire_01", 1500)
		save.data["progress"]["stages"]["stage_01"] = {"cleared": true, "best_time_sec": 214.0}
	_hub = (load("res://scenes/main/hub.tscn") as PackedScene).instantiate()
	root.add_child(_hub)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_prepare()
		return false
	if _frames % 12 == 2:
		if _index >= TABS.size():
			return true
		_hub.show_tab(TABS[_index])
	if _frames % 12 == 10:
		var out := "res://build/screenshots/hub_%s.png" % String(TABS[_index]).trim_suffix("Tab").to_lower()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
		root.get_texture().get_image().save_png(out)
		print("saved ", out)
		_index += 1
	return false
