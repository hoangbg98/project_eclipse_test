class_name HitInfo
extends RefCounted
## Thông tin một lần trúng đòn, Hitbox gửi cho Hurtbox.
## Chưa tính sát thương; DamageCalculator (M3-3) dùng các tỉ lệ này.

## Định danh lần kích hoạt; một Hurtbox chỉ nhận mỗi hit_id một lần.
var hit_id := 0
var team := PhysicsLayers.Team.PLAYER
## Node gây đòn (nhân vật / quái), có thể null.
var attacker: Node
## Khóa kỹ năng, vd "char_fire_01.normal".
var skill_id := ""
## % ATK của đòn (1.0 = 100%).
var atk_ratio := 0.0
## Sức choáng theo % ATK; mặc định bằng atk_ratio (mục 0), kỹ năng nhân hệ số.
var sc_ratio := 0.0
## Vị trí và hướng đẩy (đơn vị, theo hướng mặt người đánh).
var origin := Vector2.ZERO
var knockback_dir := Vector2.RIGHT
var knockback_px := 0.0
## Loại đòn (ResourceComponent.HitKind) để cộng EN/UG cho người đánh.
var hit_kind := 0
var skill_level := 1
## Trạng thái áp lên mục tiêu khi trúng.
var statuses: Array[StatusApplication] = []
## % tăng sát thương riêng của lần đánh này (vd 5 tầng Nhiệt +25%), khóa theo nguồn.
var damage_bonus: Dictionary = {}
## EN cộng thêm cho người đánh (một lần mỗi hit_id).
var extra_en := 0.0
## Mục tiêu đang mang trạng thái này thì thêm % sát thương.
var bonus_vs_status := ""
var bonus_vs_status_ratio := 0.0
## Kéo về `origin` thay vì đẩy theo knockback_dir.
var pull_to_origin := false
## Hệ số thời gian trạng thái khống chế / Chậm khi mục tiêu là boss.
var boss_control_multiplier := 1.0
## Do mục tiêu điền khi nhận: trạng thái đang có TRƯỚC đòn này (vd "đang Cháy").
var target_statuses_before := PackedStringArray()
## Do mục tiêu điền: đòn này làm mục tiêu gục.
var killed_target := false
