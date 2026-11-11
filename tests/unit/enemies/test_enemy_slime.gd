extends GdUnitTestSuite
## Test M3-6: quái thường (slime) — tuần tra, phát hiện, đánh có báo hiệu, khựng, sức choáng, chết;
## người chơi trúng đòn (khựng, đẩy lùi, kháng khựng, né, né hoàn hảo, gục và đứng dậy).

const STAGE_SCENE := preload("res://scenes/stages/test_stage.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy_slime.tscn")
const S := EnemyController.State

var _stage: Node2D
var _player: PlayerController
var _enemy: EnemyController
var _player_hits: Array[int] = []


func before_test() -> void:
	_player_hits.clear()


func _setup(player_x: float, enemy_x: float) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.spawn_enemies = false
	add_child(_stage)
	_player = _stage.player
	_player.use_player_input = false
	_player.combatant.rng = RandomSource.Fixed.new(0.99)
	_player.global_position = Vector2(player_x, 896)
	_player.combatant.damaged.connect(func(r: DamageCalculator.Result, _h: HitInfo) -> void: _player_hits.append(r.amount))
	_enemy = ENEMY_SCENE.instantiate()
	_enemy.position = Vector2(enemy_x, 896)
	_stage.add_child(_enemy)
	_enemy.combatant.rng = RandomSource.Fixed.new(0.99)
	await _frames(5)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _buf() -> float:
	return _player.config.jump_buffer_time


func _wait_state(st: int, max_frames := 240) -> bool:
	for i in max_frames:
		if _enemy.state == st:
			return true
		await get_tree().physics_frame
	return false


# ---------- Dữ liệu ----------

func test_slime_data() -> void:
	var d: EnemyDef = load("res://data/enemies/enemy_slime_01.tres")
	assert_float(d.stats.max_hp).is_equal(6000.0)
	assert_float(d.sc_max).is_equal(300.0)
	assert_array(d.attack.validate()).is_empty()
	assert_float(d.attack.startup_ms).is_greater_equal(400.0)  # báo hiệu đủ đọc (README 15.7)


# ---------- AI ----------

func test_patrols_when_player_far() -> void:
	await _setup(200.0, 3000.0)  # cách 2800 px > 700
	var xs: Array[float] = []
	for i in 240:
		await get_tree().physics_frame
		xs.append(_enemy.global_position.x)
	assert_int(_enemy.state).is_equal(S.PATROL)
	assert_float(xs.max() - xs.min()).is_greater(50.0)                      # có đi lại
	assert_float(absf(xs.max() - 3000.0)).is_less_equal(205.0)              # trong ± 200 px
	assert_float(absf(xs.min() - 3000.0)).is_less_equal(205.0)


func test_detects_and_chases() -> void:
	await _setup(500.0, 1100.0)  # cách 600 px < 700
	assert_bool(await _wait_state(S.CHASE, 30)).is_true()
	var x0 := _enemy.global_position.x
	await _frames(30)
	assert_float(_enemy.global_position.x).is_less(x0 - 30.0)               # tiến về phía người chơi
	assert_int(_enemy.facing).is_equal(-1)


func test_attack_telegraphs_then_hurts_player() -> void:
	await _setup(500.0, 640.0)
	var telegraph_frames := 0
	for i in 120:
		await get_tree().physics_frame
		if _enemy.is_telegraphing():
			telegraph_frames += 1
		if not _player_hits.is_empty():
			break
	assert_int(telegraph_frames).is_greater_equal(24)                       # ≥ 0.4 s báo hiệu
	assert_array(_player_hits).contains_exactly([200])                      # 400 × 100% × 500/(500+500)
	assert_str(String(_player.current_state())).is_equal("hurt")
	var x_hit := _player.global_position.x
	await _frames(10)
	assert_float(_player.global_position.x).is_less(x_hit - 60.0)            # bị đẩy lùi (về bên trái)
	await _frames(20)
	assert_str(String(_player.current_state())).is_not_equal("hurt")        # hết khựng 0.3 s


func test_super_armor_skill_ignores_stagger() -> void:
	await _setup(500.0, 640.0)
	# Vòng lửa của kỹ năng sẽ làm slime khựng và ngắt đòn → cho slime không khựng để đòn cắn tới được.
	_enemy.def = _enemy.def.duplicate()
	_enemy.def.stagger_sec = 0.0
	_player.combatant.resources.add_en(100.0)
	for i in 60:
		if _enemy.runner.is_running() and _enemy.runner.elapsed_ms >= 300.0:
			break
		await get_tree().physics_frame
	_player.intent.press(PlayerIntent.SKILL, _buf())  # Liệt Diễm Luân: kháng khựng
	for i in 40:
		await get_tree().physics_frame
		if not _player_hits.is_empty():
			break
	assert_array(_player_hits).is_not_empty()                               # vẫn mất máu
	assert_str(String(_player.current_state())).is_equal("attack")          # không bị khựng


func test_dodge_avoids_hit() -> void:
	await _setup(500.0, 640.0)
	for i in 60:
		if _enemy.runner.is_running() and _enemy.runner.elapsed_ms >= 440.0:
			break
		await get_tree().physics_frame
	_player.intent.move_x = 0.0
	_player.intent.press(PlayerIntent.DODGE, _buf())
	await _frames(30)
	assert_array(_player_hits).is_empty()


func test_perfect_dodge_against_real_enemy() -> void:
	await _setup(500.0, 640.0)
	var perfect := [0]
	_player.perfect_dodged.connect(func(_h: HitInfo) -> void: perfect[0] += 1)
	# Né sao cho đòn (ở 500 ms) tới khi cú né đã chạy ~60-100 ms (trong 40-190 ms).
	for i in 60:
		if _enemy.runner.is_running() and _enemy.runner.elapsed_ms >= 420.0:
			break
		await get_tree().physics_frame
	_player.intent.press(PlayerIntent.DODGE, _buf())
	await _frames(20)
	assert_int(perfect[0]).is_equal(1)
	assert_bool(_enemy.combatant.statuses.has("slow")).is_true()
	assert_bool(_player.combatant.statuses.has("hot_breath")).is_true()
	assert_array(_player_hits).is_empty()


# ---------- Khựng / Choáng ----------

func test_hit_during_windup_staggers_and_cancels() -> void:
	await _setup(500.0, 620.0)
	for i in 60:
		if _enemy.is_telegraphing() and _enemy.runner.elapsed_ms >= 100.0:
			break
		await get_tree().physics_frame
	_player.facing = 1
	_player.intent.tap_attack(_buf())
	assert_bool(await _wait_state(S.STAGGER, 20)).is_true()
	assert_bool(_enemy.runner.is_running()).is_false()                      # đòn bị ngắt
	await _frames(30)
	assert_array(_player_hits).is_empty()


func test_sc_full_stuns_then_resists() -> void:
	await _setup(200.0, 2000.0)
	var stunned := []
	var bus := get_tree().root.get_node("EventBus")
	var cb := func(e: Node, _by: Object) -> void: stunned.append(e)
	bus.enemy_stunned.connect(cb)
	_enemy._add_sc(310.0)
	bus.enemy_stunned.disconnect(cb)
	assert_int(_enemy.state).is_equal(S.STUNNED)
	assert_bool(_enemy.combatant.statuses.has("stun")).is_true()
	assert_array(stunned).contains_exactly([_enemy])
	assert_float(_enemy.sc).is_equal(0.0)
	_enemy._add_sc(310.0)                                                   # đang Choáng: không tích
	assert_float(_enemy.sc).is_equal(0.0)
	await _frames(130)                                                      # > 2.0 s
	assert_int(_enemy.state).is_not_equal(S.STUNNED)
	assert_bool(_enemy.combatant.statuses.is_resisting("stun")).is_true()   # kháng 8 s
	_enemy._add_sc(310.0)
	assert_float(_enemy.sc).is_equal(0.0)


func test_combo_builds_sc_bar() -> void:
	await _setup(500.0, 640.0)
	_enemy.def = _enemy.def.duplicate()
	_enemy.def.attack_cooldown_sec = 99.0  # không đánh lại, để đo SC
	_enemy._attack_cd = 99.0
	_player.facing = 1
	_player.intent.tap_attack(_buf())
	for i in 40:
		await get_tree().physics_frame
		if _enemy.sc > 0.0:
			break
	assert_float(_enemy.sc).is_equal_approx(70.0, 0.01)                     # đòn 70% → 70 SC


func test_sc_decays_after_idle() -> void:
	await _setup(200.0, 2000.0)
	_enemy._add_sc(200.0)
	await _frames(100)                                                      # 1.67 s: chưa giảm
	assert_float(_enemy.sc).is_equal(200.0)
	await _frames(60)                                                       # thêm 1 s: giảm ~40×(1.67-... )
	assert_float(_enemy.sc).is_less(200.0)


# ---------- Chết ----------

func test_death_emits_and_frees() -> void:
	await _setup(500.0, 620.0)
	var defeated := []
	var bus := get_tree().root.get_node("EventBus")
	var cb := func(e: Node, _by: Object) -> void: defeated.append(e)
	bus.enemy_defeated.connect(cb)
	_enemy.combatant.resources.hp = 100.0
	_player.facing = 1
	_player.intent.tap_attack(_buf())
	assert_bool(await _wait_state(S.DEAD, 40)).is_true()
	bus.enemy_defeated.disconnect(cb)
	assert_int(defeated.size()).is_equal(1)
	var ref: WeakRef = weakref(_enemy)
	await _frames(45)                                                       # mờ dần 0.6 s rồi biến mất
	assert_object(ref.get_ref()).is_null()


func test_killing_burning_enemy_cuts_weapon_cooldown() -> void:
	await _setup(500.0, 620.0)
	_player.combatant.cooldowns.trigger(&"weapon")
	_enemy.combatant.statuses.apply("burn", 6.0, -1.0, _player.combatant)
	_enemy.combatant.resources.hp = 100.0
	var before := _player.combatant.cooldowns.remaining(&"weapon")
	_player.facing = 1
	_player.intent.tap_attack(_buf())
	await _wait_state(S.DEAD, 40)
	var after := _player.combatant.cooldowns.remaining(&"weapon")
	assert_float(before - after).is_greater(1.9)                            # −2.0 s


# ---------- Người chơi gục ----------

func test_player_down_then_revives_in_test_stage() -> void:
	await _setup(500.0, 3000.0)
	_player.combatant.resources.take_damage(999999.0)
	await _frames(2)
	assert_str(String(_player.current_state())).is_equal("down")
	_player.intent.tap_attack(_buf())
	await _frames(5)
	assert_str(String(_player.current_state())).is_equal("down")            # gục: không điều khiển
	await _frames(100)                                                      # > 1.5 s
	assert_bool(_player.combatant.resources.is_dead()).is_false()
	assert_float(_player.combatant.resources.hp).is_equal(_player.combatant.resources.max_hp)
	assert_str(String(_player.current_state())).is_not_equal("down")
