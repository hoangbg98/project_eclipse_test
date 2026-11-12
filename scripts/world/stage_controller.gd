class_name StageController
extends Node2D
## Màn chơi thật (M6; README "Exploration and stages", 15.7): bản đồ + đội + các đợt quái + checkpoint + boss
## + hoàn thành / thất bại + phần thưởng. Nội dung màn nằm trong data/stages/{id}.json (StageMap.data):
##   waves: [{trigger_col, lock_cols: [trái, phải], enemies: [{id, col}]}]   đợt quái, khóa sân tới khi hạ hết
##   boss:  {id, trigger_col, lock_cols, col}                                 đấu trường boss (khóa camera)
##   rewards / first_clear_rewards: định dạng PlayerProfile.grant()
## Rơi hố → về checkpoint gần nhất đã qua. Cả đội gục → thất bại. Hạ boss → hoàn thành, trao thưởng, lưu.

signal wave_started(index: int)
signal wave_cleared(index: int)
signal boss_started(boss: BossController)
signal checkpoint_reached(position: Vector2)
signal stage_cleared(summary: Dictionary)
signal stage_failed

enum Phase { EXPLORE, WAVE, BOSS, CLEARED, FAILED }

const STAGE_DATA := "res://data/stages/%s.json"
const ENEMY_SCENES := {
	"enemy_slime_01": preload("res://scenes/enemies/enemy_slime.tscn"),
	"boss_golem_01": preload("res://scenes/enemies/boss_golem.tscn"),
}
const WALL_THICKNESS := 64.0

@export var stage_id := "stage_01"
## Rơi thấp hơn đáy bản đồ bao nhiêu thì về checkpoint (px).
@export var kill_margin := 400.0
## Để test tự đặt đội / chỉ số; rỗng thì lấy từ SaveService (hoặc đội khởi đầu).
var party_ids := PackedStringArray()
var stats_provider: Callable
## true: lấy màn từ GameConfig.selected_stage_id (màn chọn màn đặt trước khi mở scene).
var use_selected_stage := true
## false: không đọc / ghi SaveService (test).
var use_save := true

var map: StageMap
var tiles: TileMapLayer
var party: PartyManager
var player: PlayerController
var feedback: HitFeedback
var hud: BattleHud
var profile: PlayerProfile

var phase := Phase.EXPLORE
## Số đợt đã hạ xong.
var waves_cleared := 0
var enemies: Array[EnemyController] = []
var boss: BossController
var respawn_point := Vector2.ZERO
var elapsed_sec := 0.0
var last_summary: Dictionary = {}

var _walls: Array[StaticBody2D] = []
var _checkpoints_left: Array[Vector2] = []

@onready var camera: FollowCamera = $Camera


func _ready() -> void:
	var gc := get_tree().root.get_node_or_null("GameConfig")
	if use_selected_stage and gc and "selected_stage_id" in gc and str(gc.selected_stage_id) != "":
		stage_id = gc.selected_stage_id
	map = StageMap.load_from(STAGE_DATA % stage_id)
	for e in map.errors:
		push_error("StageController: %s" % e)
	if not map.errors.is_empty():
		return
	tiles = map.build_layer()
	add_child(tiles)
	move_child(tiles, 0)
	respawn_point = map.spawn_position()
	for c in map.checkpoint_cells:
		_checkpoints_left.append(map.cell_feet(c))
	_checkpoints_left.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)

	var save := _save()
	if save:
		profile = PlayerProfile.new(save.data)
		if party_ids.is_empty():
			party_ids = profile.party_ids()
		if not stats_provider.is_valid():
			stats_provider = profile.stats_of
	if party_ids.is_empty():
		party_ids = PackedStringArray(SaveSchema.STARTER_CHARACTERS)

	party = PartyManager.new()
	party.name = "Party"
	add_child(party)
	party.stats_provider = stats_provider
	party.setup(party_ids, self, respawn_point)
	party.party_defeated.connect(_on_party_defeated)
	party.switched.connect(func(_f: CharacterRuntime, _t: CharacterRuntime, _m: String) -> void: _bind_player())

	camera.set_bounds(map.bounds_px())
	feedback = HitFeedback.new()
	feedback.name = "HitFeedback"
	feedback.camera = camera
	add_child(feedback)
	hud = BattleHud.new()
	hud.name = "BattleHud"
	hud.party = party
	add_child(hud)
	var touch := get_node_or_null("TouchControls") as TouchControls
	if touch:
		touch.party = party
		for a: StringName in [&"switch_1", &"switch_2"]:
			if touch.buttons.has(a):
				touch.buttons[a].visible = false
	_bind_player()


func _save() -> Node:
	return get_tree().root.get_node_or_null("SaveService") if use_save and is_inside_tree() else null


func _bind_player() -> void:
	player = party.active_controller()
	camera.follow(player)
	feedback.player = player
	var overlay := get_node_or_null("DebugOverlay")
	if overlay:
		overlay.player = player
		overlay.party = party


# ---------- Dữ liệu màn ----------

func waves() -> Array:
	return map.data.get("waves", []) if map else []


func wave_count() -> int:
	return waves().size()


func boss_data() -> Dictionary:
	return map.data.get("boss", {}) if map else {}


func enemies_alive() -> int:
	return enemies.size()


# ---------- Vòng lặp ----------

func _physics_process(delta: float) -> void:
	if map == null or not map.errors.is_empty() or player == null:
		return
	if phase in [Phase.CLEARED, Phase.FAILED]:
		return
	elapsed_sec += delta
	_check_fall()
	_check_checkpoints()
	if phase == Phase.EXPLORE:
		_check_triggers()


func _check_fall() -> void:
	if player.global_position.y > map.bounds_px().end.y + kill_margin:
		player.global_position = respawn_point
		player.velocity = Vector2.ZERO
		camera.follow(player)


func _check_checkpoints() -> void:
	while not _checkpoints_left.is_empty() and player.global_position.x >= _checkpoints_left[0].x:
		respawn_point = _checkpoints_left.pop_front()
		checkpoint_reached.emit(respawn_point)


func _check_triggers() -> void:
	var px := player.global_position.x
	if waves_cleared < wave_count():
		var w: Dictionary = waves()[waves_cleared]
		if px >= map.col_x(int(w.get("trigger_col", 0))):
			_start_wave(waves_cleared)
	elif boss == null and not boss_data().is_empty():
		if px >= map.col_x(int(boss_data().get("trigger_col", 0))):
			_start_boss()


# ---------- Đợt quái ----------

func _start_wave(index: int) -> void:
	var w: Dictionary = waves()[index]
	phase = Phase.WAVE
	_lock(w.get("lock_cols", []))
	for e: Dictionary in w.get("enemies", []):
		_spawn(str(e.get("id", "")), int(e.get("col", 0)))
	wave_started.emit(index)
	if enemies.is_empty():
		_on_wave_done()


func _spawn(id: String, col: int) -> EnemyController:
	var scene: PackedScene = ENEMY_SCENES.get(id)
	if scene == null:
		push_error("StageController: không có scene cho quái '%s'" % id)
		return null
	var e: EnemyController = scene.instantiate()
	e.enemy_id = id
	e.position = map.ground_feet(col)
	add_child(e)
	enemies.append(e)
	e.died.connect(_on_enemy_died)
	return e


func _on_enemy_died(dead: EnemyController) -> void:
	enemies.erase(dead)
	if phase == Phase.WAVE and enemies.is_empty():
		_on_wave_done()
	elif phase == Phase.BOSS and dead == boss:
		_on_boss_defeated()


func _on_wave_done() -> void:
	var index := waves_cleared
	waves_cleared += 1
	_unlock()
	phase = Phase.EXPLORE
	wave_cleared.emit(index)


# ---------- Boss ----------

func _start_boss() -> void:
	var b := boss_data()
	phase = Phase.BOSS
	_lock(b.get("lock_cols", []))
	boss = _spawn(str(b.get("id", "")), int(b.get("col", 0))) as BossController
	if boss == null:
		_on_boss_defeated()
		return
	boss_started.emit(boss)
	_audio_music("boss")


func _on_boss_defeated() -> void:
	_unlock()
	_finish_cleared()


# ---------- Khóa sân (tường vô hình + giới hạn camera) ----------

func is_locked() -> bool:
	return not _walls.is_empty()


func _lock(cols: Array) -> void:
	_unlock()
	if cols.size() != 2:
		return
	var left := map.col_x(int(cols[0]))
	var right := map.col_x(int(cols[1]) + 1)
	var b := map.bounds_px()
	for x in [left - WALL_THICKNESS * 0.5, right + WALL_THICKNESS * 0.5]:
		var wall := StaticBody2D.new()
		wall.name = "ArenaWall"
		wall.collision_layer = PhysicsLayers.bit(PhysicsLayers.WORLD)
		wall.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(WALL_THICKNESS, b.size.y * 3.0)
		shape.shape = rect
		wall.add_child(shape)
		wall.position = Vector2(x, b.position.y + b.size.y * 0.5)
		add_child(wall)
		_walls.append(wall)
	camera.set_bounds(Rect2i(int(left), b.position.y, int(right - left), b.size.y))


func _unlock() -> void:
	for w in _walls:
		w.queue_free()
	_walls.clear()
	if map:
		camera.set_bounds(map.bounds_px())


# ---------- Kết thúc ----------

func _on_party_defeated() -> void:
	if phase in [Phase.CLEARED, Phase.FAILED]:
		return
	phase = Phase.FAILED
	_freeze_all()
	last_summary = {"victory": false, "time_sec": elapsed_sec, "stage_id": stage_id}
	stage_failed.emit()
	_audio_sfx("stage_fail")
	_show_result()


func _finish_cleared() -> void:
	phase = Phase.CLEARED
	_freeze_all()
	var summary := {"victory": true, "time_sec": elapsed_sec, "stage_id": stage_id, "first_clear": false,
			"rewards": {}, "first_clear_rewards": {}, "best_time": false}
	var save := _save()
	if save and profile:
		var stages: Dictionary = save.data["progress"]["stages"]
		var prev: Variant = stages.get(stage_id)
		var first := not (prev is Dictionary and bool(prev.get("cleared", false)))
		summary["rewards"] = profile.grant(map.data.get("rewards", {}))
		if first:
			summary["first_clear"] = true
			summary["first_clear_rewards"] = profile.grant(map.data.get("first_clear_rewards", {}))
		var best := elapsed_sec
		if prev is Dictionary and float(prev.get("best_time_sec", 0.0)) > 0.0:
			best = minf(best, float(prev["best_time_sec"]))
		summary["best_time"] = first or best == elapsed_sec
		stages[stage_id] = {"cleared": true, "best_time_sec": best}
		save.save_game()
	last_summary = summary
	stage_cleared.emit(summary)
	_audio_sfx("stage_clear")
	_show_result()


func _audio_sfx(event: String) -> void:
	var audio := get_tree().root.get_node_or_null("AudioRouter")
	if audio:
		audio.play_event(event)


func _audio_music(event: String) -> void:
	var audio := get_tree().root.get_node_or_null("AudioRouter")
	if audio:
		audio.play_event_music(event)


func _freeze_all() -> void:
	party.use_player_input = false
	if player:
		player.use_player_input = false
		player.intent.clear()
		player.intent.move_x = 0.0
	for e in enemies:
		e.freeze(1e9)


func _show_result() -> void:
	var pause := get_node_or_null("PauseMenu")
	if pause and "enabled" in pause:
		pause.enabled = false
	var screen := get_node_or_null("ResultScreen")
	if screen and screen.has_method("show_result"):
		screen.show_result(last_summary)
