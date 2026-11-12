class_name TouchControls
extends CanvasLayer
## Lớp điều khiển cảm ứng cho gameplay: joystick trái, cụm nút phải, hai nút đổi nhân vật.
## Chỉ hiện trên thiết bị có màn hình cảm ứng, trừ khi bật force_visible (để test trên PC).
## Vùng chạm tối thiểu 128 px ở nền 1920x1080 (UI_UX_SPEC). Safe area/tai thỏ: làm ở M7.

@export var force_visible := false

const MIN_TOUCH := 128.0
const MARGIN := 64.0

var joystick: VirtualJoystick
var buttons: Dictionary = {}  # action -> TouchButton
## Đội đang chơi (màn chơi gán): để nút kỹ năng hiện hồi chiêu / EN / UG / lượt né của người trên sân.
var party: PartyManager

## Nút → khóa kỹ năng trong SkillRunner.
const SKILL_ACTIONS := {&"skill": "skill", &"weapon": "weapon", &"ultimate": "ultimate", &"dodge": "dodge"}


func _ready() -> void:
	layer = 50
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	joystick = VirtualJoystick.new()
	joystick.custom_minimum_size = Vector2(360, 360)
	_place(joystick, Vector2(360, 360), Vector2(0.0, 1.0), Vector2(MARGIN, -MARGIN - 360))
	root.add_child(joystick)

	# Cụm bên phải, neo góc dưới-phải; offset là khoảng cách tới góc đó.
	_add_button(root, &"attack", "J", 192.0, Vector2(MARGIN + 0, MARGIN + 0))
	_add_button(root, &"jump", "↑", 160.0, Vector2(MARGIN + 224, MARGIN + 32))
	_add_button(root, &"dodge", "L", 144.0, Vector2(MARGIN + 16, MARGIN + 224))
	_add_button(root, &"skill", "U", 144.0, Vector2(MARGIN + 192, MARGIN + 224))
	_add_button(root, &"weapon", "I", 144.0, Vector2(MARGIN + 400, MARGIN + 160))
	_add_button(root, &"ultimate", "O", 144.0, Vector2(MARGIN + 384, MARGIN + 336))

	# Hai nút chuyển nhân vật, góc trên-phải.
	for i in 2:
		var action := StringName("switch_%d" % (i + 1))
		var b := _make_button(action, str(i + 1), MIN_TOUCH)
		_place(b, Vector2(MIN_TOUCH, MIN_TOUCH), Vector2(1.0, 0.0),
				Vector2(-MARGIN - MIN_TOUCH - i * (MIN_TOUCH + 24), MARGIN))
		root.add_child(b)
		buttons[action] = b

	visible = force_visible or DisplayServer.is_touchscreen_available()


func _process(_delta: float) -> void:
	if not visible or party == null or not is_instance_valid(party):
		return
	var p := party.active_controller()
	for action: StringName in SKILL_ACTIONS:
		if buttons.has(action):
			(buttons[action] as TouchButton).set_state(button_state(action, p))


## Trạng thái hiển thị của một nút theo nhân vật trên sân: {cooldown_ratio, overlay_text, charge_ratio, dimmed}.
## Tách riêng (static) để test không cần màn hình cảm ứng.
static func button_state(action: StringName, p: PlayerController) -> Dictionary:
	var out := {"cooldown_ratio": 0.0, "overlay_text": "", "charge_ratio": -1.0, "dimmed": false}
	if p == null or not is_instance_valid(p) or p.combatant == null or p.combatant.resources == null:
		return out
	var key: String = SKILL_ACTIONS.get(action, "")
	var res := p.combatant.resources
	if action == &"dodge":
		out["overlay_text"] = str(res.dodge_charges)
		out["dimmed"] = res.dodge_charges <= 0 or not p.runner.has_skill(key)
		return out
	var s: SkillDef = p.runner.skills.get(key)
	if s == null:
		out["dimmed"] = true                      # nhân vật chưa có kỹ năng này (Kael, Lyra ngoài slice)
		return out
	if action == &"ultimate":
		out["charge_ratio"] = clampf(res.ug / res.rules.ug_max, 0.0, 1.0)
		out["dimmed"] = not res.is_ultimate_ready()
	var cds := p.combatant.cooldowns
	var cd_key := StringName(s.cooldown_key())
	if s.cooldown_sec > 0.0 and cds.has(cd_key) and not cds.is_ready(cd_key):
		var total := cds.duration_of(cd_key)
		out["cooldown_ratio"] = clampf(cds.remaining(cd_key) / total, 0.0, 1.0) if total > 0.0 else 0.0
		out["overlay_text"] = "%.0f" % ceilf(cds.remaining(cd_key))
	if s.en_cost > 0.0 and not res.can_spend_en(s.en_cost):
		out["dimmed"] = true
	return out


func _add_button(root: Control, action: StringName, text: String, diameter: float, from_corner: Vector2) -> void:
	var b := _make_button(action, text, diameter)
	_place(b, Vector2(diameter, diameter), Vector2(1.0, 1.0),
			Vector2(-from_corner.x - diameter, -from_corner.y - diameter))
	root.add_child(b)
	buttons[action] = b


func _make_button(action: StringName, text: String, diameter: float) -> TouchButton:
	var b := TouchButton.new()
	b.action = action
	b.label_text = text
	b.custom_minimum_size = Vector2(diameter, diameter)
	return b


## Neo vào một góc (anchor 0/1) và đặt vị trí/kích thước theo offset từ góc đó.
func _place(c: Control, c_size: Vector2, anchor: Vector2, offset: Vector2) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = offset.x
	c.offset_top = offset.y
	c.offset_right = offset.x + c_size.x
	c.offset_bottom = offset.y + c_size.y
