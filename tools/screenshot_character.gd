extends SceneTree
## Chụp màn Nhân vật ở 6 trạng thái theo 6 ảnh tham chiếu (cần cửa sổ, không chạy --headless):
##   <godot> --path . -s tools/screenshot_character.gd
## Ảnh ra build/screenshots/character_<n>_<tên>.png. Dữ liệu tạm trong bộ nhớ; KHÔNG ghi save.

const SHOTS := [
	["1_overview", "overview", ""],
	["2_weapon", "tab", "weapon"],
	["3_stigma", "tab", "stigma"],
	["4_level", "tab", "level"],
	["5_skill_tree", "tab", "skill"],
	["6_skill_detail", "skill", "ultimate"],
	["7_filter", "filter", "S"],
]

var _frames := 0
var _screen: CharacterScreen
var _index := 0


func _prepare() -> void:
	var save := root.get_node_or_null("SaveService")
	var data := SaveSchema.default_data()
	data["account"]["level"] = 30
	var p := PlayerProfile.new(data)
	p.inventory.add_currency("gold", 12345)
	p.inventory.add_material("mat_exp_small", 5)
	p.inventory.add_material("mat_exp_medium", 2)
	p.inventory.equip("char_fire_01", p.inventory.add_equipment("eq_weapon_flame"))
	p.inventory.equip("char_fire_01", p.inventory.add_equipment("eq_stigma_top_elite"))
	p.inventory.equip("char_fire_01", p.inventory.add_equipment("eq_stigma_mid_guardian"))
	p.progression.add_exp("char_fire_01", 1500)
	p.progression.add_fragments("char_fire_01", 6)
	for id in ["char_lightning_01", "char_wind_01", "char_earth_01"]:
		p.progression.unlock(id)
	if save:
		save.data = data
	_screen = (load("res://scenes/main/character_screen.tscn") as PackedScene).instantiate()
	_screen.profile = p
	_screen.save_enabled = false
	root.add_child(_screen)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_prepare()
		return false
	if _frames % 12 == 2:
		if _index >= SHOTS.size():
			return true
		var s: Array = SHOTS[_index]
		match str(s[1]):
			"overview":
				_screen.view = CharacterScreen.View.OVERVIEW
				_screen.refresh()
			"tab":
				_screen.open_tab(str(s[2]))
			"skill":
				_screen.open_skill(str(s[2]))
			"filter":
				_screen.view = CharacterScreen.View.OVERVIEW
				_screen.filter_open = true
				_screen.toggle_filter("rank", str(s[2]))
	if _frames % 12 == 10:
		var out := "res://build/screenshots/character_%s.png" % str(SHOTS[_index][0])
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
		root.get_texture().get_image().save_png(out)
		print("saved ", out)
		_index += 1
	return false
