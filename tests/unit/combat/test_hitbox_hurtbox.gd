extends GdUnitTestSuite
## Test M3-2: Hitbox/Hurtbox (một lần trúng mỗi hit_id, phe, bất tử) và track AnimationPlayer theo frame.

const T := PhysicsLayers.Team


func _hitbox(team := T.PLAYER, parent: Node = null) -> Hitbox:
	var hb := Hitbox.new()
	hb.team = team
	hb.atk_ratio = 0.7
	hb.skill_id = "char_fire_01.normal"
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(120, 80)
	shape.shape = rect
	hb.add_child(shape)
	if parent:
		parent.add_child(hb)
	else:
		add_child(auto_free(hb))
	return hb


func _hurtbox(team := T.ENEMY) -> Hurtbox:
	var hu := Hurtbox.new()
	hu.team = team
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(80, 200)
	shape.shape = rect
	hu.add_child(shape)
	# Mỗi Hurtbox có node chủ riêng (như quái/nhân vật), khác chủ của Hitbox.
	var holder: Node2D = auto_free(Node2D.new())
	add_child(holder)
	holder.add_child(hu)
	return hu


# ---------- Lớp va chạm ----------

func test_layers_pair_teams_correctly() -> void:
	var p_hit := _hitbox(T.PLAYER)
	var e_hurt := _hurtbox(T.ENEMY)
	var p_hurt := _hurtbox(T.PLAYER)
	# Hitbox người chơi chỉ "thấy" Hurtbox quái.
	assert_int(p_hit.collision_mask & e_hurt.collision_layer).is_not_equal(0)
	assert_int(p_hit.collision_mask & p_hurt.collision_layer).is_equal(0)
	assert_bool(p_hit.monitoring).is_true()
	assert_bool(e_hurt.monitorable).is_true()
	assert_int(PhysicsLayers.bit(PhysicsLayers.ENEMY_HURTBOX)).is_equal(64)


# ---------- Một lần trúng mỗi hit_id ----------

func test_one_hit_per_activation() -> void:
	var hb := _hitbox()
	var hu := _hurtbox()
	var received: Array[HitInfo] = []
	hu.hit_received.connect(func(h: HitInfo) -> void: received.append(h))
	hb.activate()
	assert_bool(hb.try_hit(hu)).is_true()
	assert_bool(hb.try_hit(hu)).is_false()
	assert_bool(hb.try_hit(hu)).is_false()
	assert_int(received.size()).is_equal(1)


func test_new_activation_hits_again_keep_id_does_not() -> void:
	var hb := _hitbox()
	var hu := _hurtbox()
	hb.activate()
	var first := hb.hit_id
	assert_bool(hb.try_hit(hu)).is_true()
	hb.deactivate()
	hb.activate(true)  # nhịp sau của cùng đòn
	assert_int(hb.hit_id).is_equal(first)
	assert_bool(hb.try_hit(hu)).is_false()
	hb.deactivate()
	hb.activate()      # đòn mới
	assert_int(hb.hit_id).is_not_equal(first)
	assert_bool(hb.try_hit(hu)).is_true()


func test_hit_ids_unique_across_hitboxes() -> void:
	var a := _hitbox()
	var b := _hitbox()
	a.activate()
	b.activate()
	assert_int(a.hit_id).is_not_equal(b.hit_id)
	var hu := _hurtbox()
	assert_bool(a.try_hit(hu)).is_true()
	assert_bool(b.try_hit(hu)).is_true()  # hai đòn khác nhau đều trúng


func test_inactive_hitbox_never_hits() -> void:
	var hb := _hitbox()
	var hu := _hurtbox()
	assert_bool(hb.try_hit(hu)).is_false()
	hb.activate()
	hb.deactivate()
	assert_bool(hb.try_hit(hu)).is_false()


func test_same_team_and_self_ignored() -> void:
	var hb := _hitbox(T.PLAYER)
	hb.activate()
	assert_bool(hb.try_hit(_hurtbox(T.PLAYER))).is_false()
	# Hitbox quái đánh Hurtbox của chính nó
	var owner_node: Node2D = auto_free(Node2D.new())
	add_child(owner_node)
	var ehb := _hitbox(T.ENEMY, owner_node)
	var ehu := Hurtbox.new()
	ehu.team = T.PLAYER  # khác phe nhưng cùng chủ
	owner_node.add_child(ehu)
	ehb.activate()
	assert_bool(ehb.try_hit(ehu)).is_false()


# ---------- Bất tử / né ----------

func test_invulnerable_evades_whole_swing() -> void:
	var hb := _hitbox()
	var hu := _hurtbox()
	var evaded := [0]
	var received := [0]
	hu.hit_evaded.connect(func(_h: HitInfo) -> void: evaded[0] += 1)
	hu.hit_received.connect(func(_h: HitInfo) -> void: received[0] += 1)
	hu.invulnerable = true
	hb.activate()
	assert_bool(hb.try_hit(hu)).is_false()
	hu.invulnerable = false
	# Hết bất tử giữa chừng: chính lần chém đó vẫn không trúng.
	assert_bool(hb.try_hit(hu)).is_false()
	assert_int(evaded[0]).is_equal(1)
	assert_int(received[0]).is_equal(0)
	hb.activate()
	assert_bool(hb.try_hit(hu)).is_true()


func test_old_hit_ids_are_forgotten() -> void:
	var hb := _hitbox()
	var hu := _hurtbox()
	var now := [10.0]
	hu.clock = func() -> float: return now[0]
	hu.memory_sec = 3.0
	hb.activate()
	hb.try_hit(hu)
	var id := hb.hit_id
	assert_bool(hu.has_seen(id)).is_true()
	now[0] += 2.9
	var mid := _hitbox()
	mid.activate()
	mid.try_hit(hu)
	assert_bool(hu.has_seen(id)).override_failure_message("chưa quá 3 s: còn nhớ").is_true()
	now[0] += 0.2
	var other := _hitbox()
	other.activate()
	other.try_hit(hu)  # receive() dọn bộ nhớ cũ
	assert_bool(hu.has_seen(id)).is_false()


# ---------- HitInfo ----------

func test_hit_info_fields() -> void:
	var attacker := auto_free(PlayerControllerStub.new()) as PlayerControllerStub
	add_child(attacker)
	attacker.facing = -1
	var hb := _hitbox(T.PLAYER, attacker)
	hb.sc_multiplier = 1.5
	hb.knockback_px = 120.0
	hb.activate()
	var got: Array[HitInfo] = []
	var hu := _hurtbox()
	hu.hit_received.connect(func(h: HitInfo) -> void: got.append(h))
	hb.try_hit(hu)
	var h := got[0]
	assert_int(h.hit_id).is_equal(hb.hit_id)
	assert_object(h.attacker).is_same(attacker)
	assert_str(h.skill_id).is_equal("char_fire_01.normal")
	assert_float(h.atk_ratio).is_equal(0.7)
	assert_float(h.sc_ratio).is_equal_approx(1.05, 0.0001)
	assert_vector(h.knockback_dir).is_equal(Vector2.LEFT)
	assert_float(h.knockback_px).is_equal(120.0)


# ---------- Track theo frame ----------

func test_window_from_frames() -> void:
	var w := HitboxTrack.window_from_frames(3, 4, 24.0)
	assert_float(w.start_sec).is_equal_approx(0.125, 0.0001)
	assert_float(w.end_sec).is_equal_approx(5.0 / 24.0, 0.0001)


func test_track_rejects_bad_windows() -> void:
	var anim := Animation.new()
	anim.length = 0.5
	var errors := PackedStringArray()
	var t := HitboxTrack.add(anim, ^"Hitbox", [
		HitboxTrack.HitWindow.new(0.1, 0.2),
		HitboxTrack.HitWindow.new(0.15, 0.25),  # chồng cửa sổ trước
		HitboxTrack.HitWindow.new(0.3, 0.3),    # rỗng
		HitboxTrack.HitWindow.new(0.4, 0.6),    # vượt độ dài
	], errors)
	assert_int(errors.size()).is_equal(3)
	assert_array(HitboxTrack.read_windows(anim, t)).contains_exactly([Vector2(0.1, 0.2)])


func test_animation_player_drives_hitbox_by_frames() -> void:
	var root: Node2D = auto_free(Node2D.new())
	add_child(root)
	var hb := _hitbox(T.PLAYER, root)
	hb.name = "Hitbox"
	var player := AnimationPlayer.new()
	root.add_child(player)
	player.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var anim := Animation.new()
	anim.length = 8.0 / 24.0  # 8 frame ở 24 fps
	# Khởi động 0-2, hiệu lực 3-4, hồi phục 5-7.
	HitboxTrack.add(anim, ^"Hitbox", [HitboxTrack.window_from_frames(3, 4, 24.0)])
	var lib := AnimationLibrary.new()
	lib.add_animation(&"attack_1", anim)
	player.add_animation_library(&"", lib)

	player.play(&"attack_1")
	player.advance(0.0)
	player.advance(2.5 / 24.0)  # giữa frame 2
	assert_bool(hb.active).override_failure_message("khởi động: chưa được bật").is_false()
	player.advance(1.0 / 24.0)  # frame 3
	assert_bool(hb.active).override_failure_message("frame 3: phải bật").is_true()
	var id := hb.hit_id
	player.advance(1.0 / 24.0)  # frame 4
	assert_bool(hb.active).is_true()
	assert_int(hb.hit_id).is_equal(id)
	player.advance(1.0 / 24.0)  # frame 5: hồi phục
	assert_bool(hb.active).override_failure_message("hồi phục: phải tắt").is_false()


func test_multi_window_gives_new_hit_ids() -> void:
	var root: Node2D = auto_free(Node2D.new())
	add_child(root)
	var hb := _hitbox(T.PLAYER, root)
	hb.name = "Hitbox"
	var player := AnimationPlayer.new()
	root.add_child(player)
	player.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var anim := Animation.new()
	anim.length = 0.6
	# Kiểu đòn nhiều nhịp (vd 30% ATK mỗi 150 ms): mỗi nhịp một hit_id.
	HitboxTrack.add(anim, ^"Hitbox", [HitboxTrack.HitWindow.new(0.0, 0.1), HitboxTrack.HitWindow.new(0.15, 0.25),
			HitboxTrack.HitWindow.new(0.3, 0.4)])
	var lib := AnimationLibrary.new()
	lib.add_animation(&"multi", anim)
	player.add_animation_library(&"", lib)
	var hu := _hurtbox()
	var hits := [0]
	hu.hit_received.connect(func(_h: HitInfo) -> void: hits[0] += 1)
	player.play(&"multi")
	var ids := {}
	var t := 0.0
	player.advance(0.0)
	while t < 0.5:
		if hb.active:
			ids[hb.hit_id] = true
			hb.try_hit(hu)
		player.advance(0.025)
		t += 0.025
	assert_int(ids.size()).is_equal(3)
	assert_int(hits[0]).is_equal(3)


# ---------- Vật lý thật ----------

func test_real_overlap_hits_once_per_activation() -> void:
	var hb := _hitbox(T.PLAYER)
	var hu := _hurtbox(T.ENEMY)
	hb.global_position = Vector2(500, 500)
	hu.global_position = Vector2(530, 500)
	var hits := [0]
	hu.hit_received.connect(func(_h: HitInfo) -> void: hits[0] += 1)
	for i in 3:
		await get_tree().physics_frame
	assert_int(hits[0]).override_failure_message("chưa bật thì không trúng").is_equal(0)
	hb.activate()
	for i in 6:
		await get_tree().physics_frame
	assert_int(hits[0]).override_failure_message("bật nhiều frame vẫn chỉ 1 lần").is_equal(1)
	hb.deactivate()
	await get_tree().physics_frame
	hb.activate()
	for i in 6:
		await get_tree().physics_frame
	assert_int(hits[0]).is_equal(2)


func test_real_overlap_misses_out_of_range() -> void:
	var hb := _hitbox(T.PLAYER)
	var hu := _hurtbox(T.ENEMY)
	hb.global_position = Vector2(500, 500)
	hu.global_position = Vector2(800, 500)  # xa hơn tầm 120 px
	var hits := [0]
	hu.hit_received.connect(func(_h: HitInfo) -> void: hits[0] += 1)
	hb.activate()
	for i in 6:
		await get_tree().physics_frame
	assert_int(hits[0]).is_equal(0)


## Node giả có thuộc tính `facing` như PlayerController.
class PlayerControllerStub:
	extends Node2D
	var facing := 1
