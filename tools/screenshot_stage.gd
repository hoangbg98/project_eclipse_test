extends SceneTree
## Chụp ảnh màn thử nghiệm để soát HUD bằng mắt khi không ngồi trước máy (cần cửa sổ, không chạy --headless):
##   <godot> --path . -s tools/screenshot_stage.gd -- [đường dẫn png]
## Dựng màn, mở Liên kết cho Aether (icon 1) và cho Kael mất máu, đợi ~1 s rồi lưu ảnh và thoát.

const STAGE := "res://scenes/stages/test_stage.tscn"

var _frames := 0
var _stage: Node
var _out := "res://build/screenshots/test_stage.png"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_stage = (load(STAGE) as PackedScene).instantiate()
	_stage.party_ids = PackedStringArray(["char_lightning_01", "char_fire_01", "char_wind_01"])
	root.add_child(_stage)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 20:
		var party: PartyManager = _stage.party
		party.use_player_input = false
		root.get_node("EventBus").enemy_stunned.emit(null, party.active().combatant())
		var r := party.active().resources()
		r.take_damage(r.max_hp * 0.35)
		party.members[2].resources().take_damage(party.members[2].resources().max_hp * 0.6)
		_stage.player.intent.tap_attack(0.12)
	if _frames == 75:
		var img := root.get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out.get_base_dir()))
		img.save_png(_out)
		print("saved ", ProjectSettings.globalize_path(_out), " ", img.get_size())
		return true
	return false
