extends SceneTree
## Chụp màn Chiêu mộ ở 7 trạng thái (cần cửa sổ, không chạy --headless):
##   <godot> --path . -s tools/screenshot_recruit.gd
## Ảnh ra build/screenshots/recruit_<n>_<tên>.png. Dữ liệu tạm trong bộ nhớ; KHÔNG ghi save.

const SHOTS := [
	["1_character_banner", "main", 0],
	["2_equipment_banner", "main", 1],
	["3_details", "details", 0],
	["4_results", "results", 0],
	["5_history", "history", 0],
	["6_results_mixed", "mixed", 2],
	["7_results_revealing", "revealing", 2],
]

## Kết quả giả cho cảnh 6: đủ các loại thẻ (nhân vật S mới có splash, A trùng, đồ 5★ / 4★, vật phẩm, vàng).
const MIXED := [
	{"item": "item:mat_exp_small", "rarity": 1, "tier": "MAT", "duplicate": false},
	{"item": "equip:eq_weapon_unyielding_peak", "rarity": 5, "tier": "X5", "duplicate": false},
	{"item": "equip:eq_stigma_top_bedrock", "rarity": 4, "tier": "S4", "duplicate": false},
	{"item": "char:char_fire_01", "rarity": 5, "tier": "S", "duplicate": false},
	{"item": "gold:2000", "rarity": 1, "tier": "MAT", "duplicate": false},
	{"item": "char:char_dark_01", "rarity": 4, "tier": "A", "duplicate": true},
	{"item": "equip:eq_weapon_iron", "rarity": 3, "tier": "W3", "duplicate": false},
	{"item": "equip:eq_stigma_mid_hide", "rarity": 3, "tier": "S3", "duplicate": false},
	{"item": "char:char_wind_01", "rarity": 3, "tier": "B", "duplicate": false},
	{"item": "item:mat_enhance_ore", "rarity": 1, "tier": "MAT", "duplicate": false},
]

var _frames := 0
var _screen: RecruitScreen
var _index := 0


func _prepare() -> void:
	var save := root.get_node_or_null("SaveService")
	var data := SaveSchema.default_data()
	data["currencies"]["gems"] = 8000
	data["currencies"]["gold"] = 12345
	if save:
		save.data = data
	_screen = (load("res://scenes/main/recruit_screen.tscn") as PackedScene).instantiate()
	_screen.profile = PlayerProfile.new(data)
	_screen.save_enabled = false
	root.add_child(_screen)
	_screen.service.rng = RandomSource.new(7)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_prepare()
		return false
	if _frames % 12 == 2:
		if _index >= SHOTS.size():
			return true
		var s: Array = SHOTS[_index]
		_screen.overlay = RecruitScreen.Overlay.NONE
		_screen.select(int(s[2]))
		match str(s[1]):
			"details":
				_screen.open_overlay(RecruitScreen.Overlay.DETAILS)
			"results":
				_screen.service.pull(_screen.banners[0], 10)   # tạo vài dòng lịch sử thật
				_screen.pull(10)
				_screen.skip_reveal()
			"history":
				_screen.open_overlay(RecruitScreen.Overlay.HISTORY)
			"mixed":
				_screen.last_results = MIXED.duplicate(true)
				_screen.open_overlay(RecruitScreen.Overlay.RESULTS)
				_screen.skip_reveal()
			"revealing":
				_screen.last_results = MIXED.duplicate(true)
				_screen.open_overlay(RecruitScreen.Overlay.RESULTS)
				_screen.reveal_time = 4.0   # giữa chừng: 3 thẻ đã hiện, thẻ thứ 4 đang trượt vào
	if _frames % 12 == 10:
		var out := "res://build/screenshots/recruit_%s.png" % str(SHOTS[_index][0])
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
		root.get_texture().get_image().save_png(out)
		print("saved ", out)
		_index += 1
	return false
