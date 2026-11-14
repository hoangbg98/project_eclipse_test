extends SceneTree
## Chụp clip truyện tranh để soát bằng mắt (cần cửa sổ, không --headless):
##   <godot> --path . -s tools/screenshot_story.gd -- [id clip, mặc định ch01_open]
## Chụp lúc trang 1 và trang 3 đã hiện đủ ô, và thẻ chương; ảnh ra build/screenshots/story_<id>_<tên>.png.
## Không ghi save thật.

## [tên ảnh, trang (0-based, -1 = thẻ chương)]
const SHOTS := [["page1", 0], ["page3", 2], ["card", -1]]

var _clip: StoryClip
var _t := 0.0
var _step := 0
var _id := "ch01_open"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_id = args[0]


func _ready_to_shoot(page: int) -> bool:
	if page < 0:
		return _clip.state == StoryClip.State.CARD
	var ps: Array = _clip.current_page().get("panels", [])
	return _clip.page_index == page and _clip.panel_index == ps.size() - 1 and _clip.state == StoryClip.State.LINE


func _process(delta: float) -> bool:
	_t += delta
	if _clip == null:
		root.get_node("SaveService").store = SaveStore.new("user://screenshot_story_tmp")
		_clip = (load("res://scenes/main/story_clip.tscn") as PackedScene).instantiate()
		_clip.clip_id = _id
		_clip.navigate_enabled = false
		root.add_child(_clip)
		return false
	if _step >= SHOTS.size():
		return true
	if _t < 0.5:
		return false
	if not _ready_to_shoot(SHOTS[_step][1]):
		_clip.advance()
		_t = 0.15
		return false
	if _t >= 1.6:
		var out := "res://build/screenshots/story_%s_%s.png" % [_id, SHOTS[_step][0]]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
		root.get_texture().get_image().save_png(out)
		print("saved ", out)
		_step += 1
		_t = 0.0
	return false
