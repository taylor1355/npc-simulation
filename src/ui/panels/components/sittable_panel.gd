extends GamepiecePanel

@onready var info_text: RichTextLabel = $MarginContainer/InfoText

func is_compatible_with(controller: GamepieceController) -> bool:
	if not controller is ItemController:
		return false
	return _get_sittable_component(controller) != null

func _show_default_text() -> void:
	info_text.text = "Select an item to view sittable info."

func _show_invalid_text() -> void:
	info_text.text = "This item is not sittable."

func _get_sittable_component(controller: GamepieceController) -> SittableComponent:
	if not controller or not controller is ItemController:
		return null
	var item_controller := controller as ItemController
	var component = item_controller.get_component(SittableComponent)
	return component as SittableComponent if component else null

func _update_display() -> void:
	var sittable = _get_sittable_component(current_controller)
	if not sittable:
		return
		
	var text = "[b]Sittable Info[/b]\n"
	
	text += "Occupied by: "
	if sittable.current_npc:
		text += sittable.current_npc._gamepiece.name
 
	var energy_rate = sittable.need_modifier.need_rates[Needs.get_display_name(Needs.Need.ENERGY)]
	text += "\nEnergy regeneration rate: +%.1f per second" % energy_rate
		
	if sittable._is_exiting:
		text += "\n[Currently handling exit]"
		
	info_text.text = text
