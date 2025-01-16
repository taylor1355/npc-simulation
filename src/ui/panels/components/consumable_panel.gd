extends GamepiecePanel

@onready var info_text: RichTextLabel = $MarginContainer/InfoText

func is_compatible_with(controller: GamepieceController) -> bool:
	if not controller is ItemController:
		return false
	return _get_consumable_component(controller) != null

func _show_default_text() -> void:
	info_text.text = "Select an item to view consumable info."

func _show_invalid_text() -> void:
	info_text.text = "This item is not consumable."

func _get_consumable_component(controller: GamepieceController) -> ConsumableComponent:
	if not controller or not controller is ItemController:
		return null
	var item_controller := controller as ItemController
	var component = item_controller.get_component(ConsumableComponent)
	return component as ConsumableComponent if component else null

func _update_display() -> void:
	var consumable = _get_consumable_component(current_controller)
	if not consumable:
		return
		
	var text = "[b]Consumable Info[/b]\n"
	text += "Percent Left: %.1f%%\n" % consumable.percent_left
	text += "Consumption Time: %.1f seconds\n" % consumable.consumption_time
	
	text += "\nNeed Changes When Consumed:\n"
	for need_id in consumable.need_deltas:
		var delta = consumable.need_deltas[need_id]
		text += "- %s: %+.1f\n" % [need_id.capitalize(), delta]
		
	if consumable.current_npc:
		text += "\nCurrently being consumed by: " + consumable.current_npc._gamepiece.name
		
	info_text.text = text
