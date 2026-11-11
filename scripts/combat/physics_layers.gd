class_name PhysicsLayers
extends RefCounted
## Số thứ tự lớp va chạm 2D (1..32) dùng chung toàn dự án.
## Ghi bằng hằng số để không phụ thuộc tên lớp trong project.godot.

const WORLD := 1
const PLAYER_BODY := 2
const ENEMY_BODY := 3
const PLAYER_HITBOX := 4
const ENEMY_HITBOX := 5
const PLAYER_HURTBOX := 6
const ENEMY_HURTBOX := 7

enum Team { PLAYER, ENEMY }


## Bit của một lớp (dùng cho collision_layer / collision_mask).
static func bit(layer: int) -> int:
	return 1 << (layer - 1)


static func hitbox_layer(team: Team) -> int:
	return bit(PLAYER_HITBOX if team == Team.PLAYER else ENEMY_HITBOX)


## Hitbox của phe này tìm Hurtbox của phe kia.
static func hitbox_mask(team: Team) -> int:
	return bit(ENEMY_HURTBOX if team == Team.PLAYER else PLAYER_HURTBOX)


static func hurtbox_layer(team: Team) -> int:
	return bit(PLAYER_HURTBOX if team == Team.PLAYER else ENEMY_HURTBOX)
