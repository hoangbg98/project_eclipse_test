extends Node2D
## Màn thử nghiệm M2-3: dựng tile từ bản đồ JSON, đặt nhân vật, camera, hồi sinh khi rơi hố.

const PLAYER_SCENE := preload("res://scenes/player/player_character.tscn")

@export_file("*.json") var map_path := "res://data/stages/test_stage.json"
@export var character_id := "char_fire_01"
## Rơi thấp hơn đáy bản đồ bao nhiêu thì hồi sinh (px).
@export var kill_margin := 400.0

var map: StageMap
var tiles: TileMapLayer
var player: PlayerController

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

	player = PLAYER_SCENE.instantiate()
	player.character_id = character_id
	player.position = map.spawn_position()
	add_child(player)

	camera.set_bounds(map.bounds_px())
	camera.follow(player)
	var overlay := get_node_or_null("DebugOverlay")
	if overlay:
		overlay.player = player


func _physics_process(_delta: float) -> void:
	check_fall()


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
