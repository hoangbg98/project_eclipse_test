class_name CharacterRuntime
extends RefCounted
## Trạng thái riêng của một thành viên trong đội (ARCHITECTURE mục 6).
## Giữ node PlayerController của nhân vật; khi ở dự bị node bị gỡ khỏi cây (không có trên sân,
## không AI) nhưng HP, EN, UG, hồi chiêu, trạng thái (Nhiệt, buff...) vẫn chạy qua `tick_reserve`.
## SI-CD và cửa sổ Liên kết thêm ở M4-3.

var id := ""
var controller: PlayerController
## Vị trí trong đội (0..2), không đổi khi chuyển.
var party_index := 0


func _init(character_id: String, node: PlayerController, index: int) -> void:
	id = character_id
	controller = node
	party_index = index


func def() -> CharacterDef:
	return controller.character


func element() -> String:
	return controller.character.element if controller.character else ""


func combatant() -> Combatant:
	return controller.combatant


func resources() -> ResourceComponent:
	return controller.combatant.resources


func is_down() -> bool:
	return resources().is_dead()


func is_on_field() -> bool:
	return controller.is_inside_tree()


func tick_reserve(delta: float) -> void:
	controller.tick_reserve(delta)
