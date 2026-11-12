extends Node2D
## Màn thử nghiệm: dựng tile từ bản đồ JSON, đặt nhân vật, hình nộm (D), quái (E), camera.
## Rơi hố → về điểm xuất phát. Gục → đứng dậy đầy máu sau `player_revive_sec`. Quái chết → hồi sau `enemy_respawn_sec`.
## (Hồi sinh chỉ có ở màn thử nghiệm; trong game thật tắt theo Q6.)

const DUMMY_SCENE := preload("res://scenes/world/training_dummy.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy_slime.tscn")

@export_file("*.json") var map_path := "res://data/stages/test_stage.json"
## Đội 3 người (người đầu tiên vào sân trước). Kael, Lyra mới chỉ di chuyển (đòn: M4-6).
@export var party_ids := PackedStringArray(["char_fire_01", "char_lightning_01", "char_wind_01"])
## Rơi thấp hơn đáy bản đồ bao nhiêu thì hồi sinh (px).
@export var kill_margin := 400.0
@export var player_revive_sec := 1.5
@export var enemy_respawn_sec := 5.0
## Tắt để test tự đặt quái.
@export var spawn_enemies := true

var map: StageMap
var tiles: TileMapLayer
## Nhân vật đang trên sân (đổi theo PartyManager).
var player: PlayerController
var party: PartyManager
var dummies: Array[TrainingDummy] = []
var enemies: Array[EnemyController] = []
var feedback: HitFeedback

var _revive_timer := -1.0
var _respawns: Array = []  # [giây còn lại, ô]
var _member_revives: Array = []  # [giây còn lại, CharacterRuntime]

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

	party = PartyManager.new()
	party.name = "Party"
	add_child(party)
	party.setup(party_ids, self, map.spawn_position())
	party.party_defeated.connect(func() -> void: _revive_timer = player_revive_sec)
	party.member_down.connect(_on_member_down)
	party.switched.connect(func(_from: CharacterRuntime, _to: CharacterRuntime, _mode: String) -> void: _bind_player())

	camera.set_bounds(map.bounds_px())
	feedback = HitFeedback.new()
	feedback.name = "HitFeedback"
	feedback.camera = camera
	add_child(feedback)
	_bind_player()


## Gắn camera, phản hồi đòn, debug vào nhân vật đang trên sân.
func _bind_player() -> void:
	player = party.active_controller()
	camera.follow(player)
	feedback.player = player
	var overlay := get_node_or_null("DebugOverlay")
	if overlay:
		overlay.player = player
		overlay.party = party


## Màn thử nghiệm: thành viên gục ở dự bị cũng tự đứng dậy sau `player_revive_sec`
## (trừ khi cả đội gục: khi đó hồi cả đội cùng lúc).
func _on_member_down(m: CharacterRuntime) -> void:
	_member_revives.append([player_revive_sec, m])


func _tick_member_revives(delta: float) -> void:
	for r in _member_revives.duplicate():
		r[0] -= delta
		if r[0] > 0.0:
			continue
		_member_revives.erase(r)
		var m: CharacterRuntime = r[1]
		if m.is_down() and not party.is_defeated() and not m.is_on_field():
			m.controller.restore_full()


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
	_tick_member_revives(delta)
	if _revive_timer >= 0.0:
		_revive_timer -= delta
		if _revive_timer < 0.0:
			party.restore_all()
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
