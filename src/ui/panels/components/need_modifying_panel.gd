extends GamepiecePanel

@onready var info_text: RichTextLabel = $MarginContainer/InfoText

func is_compatible_with(controller: GamepieceController) -> bool:
	if not controller is ItemController:
		return false
	return _get_need_modifying_component(controller) != null

func _show_default_text() -> void:
	info_text.text = "Select an item to view need modification info."

func _show_invalid_text() -> void:
	info_text.text = "This item does not modify needs."

func _get_need_modifying_component(controller: GamepieceController) -> NeedModifyingComponent:
	if not controller or not controller is ItemController:
		return null
	var item_controller := controller as ItemController
	var component = item_controller.get_component(NeedModifyingComponent)
	return component as NeedModifyingComponent if component else null

func _update_display() -> void:
	var need_modifying = _get_need_modifying_component(current_controller)
	if not need_modifying:
		return
		
	var text = "[b]Need Modification Info[/b]\n"
	text += "Update Threshold: %.1f\n" % need_modifying.update_threshold
	
	text += "\nModification Rates (per second):\n"
	for need_id in need_modifying.need_rates:
		var rate = need_modifying.need_rates[need_id]
		text += "- %s: %+.1f\n" % [need_id.capitalize(), rate]
		
	if need_modifying.current_npc:
		text += "\nCurrently affecting: " + need_modifying.current_npc._gamepiece.name
		text += "\nAccumulated Changes:\n"
		for need_id in need_modifying.accumulated_deltas:
			var delta = need_modifying.accumulated_deltas[need_id]
			text += "- %s: %+.1f\n" % [need_id.capitalize(), delta]
		
	info_text.text = text
