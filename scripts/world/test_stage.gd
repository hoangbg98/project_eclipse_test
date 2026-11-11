extends Node2D
## Màn thử nghiệm: dựng tile từ bản đồ JSON, đặt nhân vật, hình nộm (D), quái (E), camera.
## Rơi hố → về điểm xuất phát. Gục → đứng dậy đầy máu sau `player_revive_sec`. Quái chết → hồi sau `enemy_respawn_sec`.
## (Hồi sinh chỉ có ở màn thử nghiệm; trong game thật tắt theo Q6.)

const PLAYER_SCENE := preload("res://scenes/player/player_character.tscn")
const DUMMY_SCENE := preload("res://scenes/world/training_dummy.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy_slime.tscn")

@export_file("*.json") var map_path := "res://data/stages/test_stage.json"
@export var character_id := "char_fire_01"
## Rơi thấp hơn đáy bản đồ bao nhiêu thì hồi sinh (px).
@export var kill_margin := 400.0
@export var player_revive_sec := 1.5
@export var enemy_respawn_sec := 5.0
## Tắt để test tự đặt quái.
@export var spawn_enemies := true

var map: StageMap
var tiles: TileMapLayer
var player: PlayerController
var dummies: Array[TrainingDummy] = []
var enemies: Array[EnemyController] = []

var _revive_timer := -1.0
var _respawns: Array = []  # [giây còn lại, ô]

@onready var camera: FollowCamera = $Camera


func _ready() -> void:
	map = StageMap.load_from(map_path)
	for e in map.errors:
		push_error("TestStage: %s" % e)
	if not map.errors.is_empty():
		return
	tiles = map.build_layer()
	add_child(tiles)
	move_child(tiles, 0)

	for cell in map.dummy_cells:
		var d: TrainingDummy = DUMMY_SCENE.instantiate()
		d.position = map.cell_feet(cell)
		add_child(d)
		dummies.append(d)
	if spawn_enemies:
		for cell in map.enemy_cells:
			spawn_enemy(cell)

	player = PLAYER_SCENE.instantiate()
	player.character_id = character_id
	player.position = map.spawn_position()
	add_child(player)
	player.player_died.connect(func() -> void: _revive_timer = player_revive_sec)

	camera.set_bounds(map.bounds_px())
	camera.follow(player)
	var overlay := get_node_or_null("DebugOverlay")
	if overlay:
		overlay.player = player


func spawn_enemy(cell: Vector2i) -> EnemyController:
	var e: EnemyController = ENEMY_SCENE.instantiate()
	e.position = map.cell_feet(cell)
	add_child(e)
	enemies.append(e)
	e.died.connect(func(dead: EnemyController) -> void:
		enemies.erase(dead)
		_respawns.append([enemy_respawn_sec, cell]))
	return e


func _physics_process(delta: float) -> void:
	check_fall()
	if _revive_timer >= 0.0:
		_revive_timer -= delta
		if _revive_timer < 0.0:
			player.restore_full()
			respawn()
	for r in _respawns.duplicate():
		r[0] -= delta
		if r[0] <= 0.0:
			_respawns.erase(r)
			spawn_enemy(r[1])


## Rơi khỏi bản đồ thì về điểm xuất phát. Trả về true nếu vừa hồi sinh.
func check_fall() -> bool:
	if player == null:
		return false
	if player.global_position.y > map.bounds_px().end.y + kill_margin:
		respawn()
		return true
	return false


func respawn() -> void:
	player.global_position = map.spawn_position()
	player.velocity = Vector2.ZERO
	camera.follow(player)
