extends GamepiecePanel

@onready var info_text: RichTextLabel = $MarginContainer/InfoText

func is_compatible_with(controller: GamepieceController) -> bool:
	return controller is ItemController

func _show_default_text() -> void:
	info_text.text = "Select an item to view its info."

func _show_invalid_text() -> void:
	info_text.text = "Not an item."

func _get_item_controller(controller: GamepieceController) -> ItemController:
	return controller as ItemController if controller else null

var _component_text: String = ""

func _add_component(component: Node, indent: String = "") -> void:
	if component is GamepieceComponent:
		_component_text += indent + "- " + component.get_component_name() + "\n"
		# Check for nested components
		for child in component.get_children():
			if child is GamepieceComponent:
				_add_component(child, indent + "  ")

func _update_display() -> void:
	var item_controller = _get_item_controller(current_controller)
	if not item_controller:
		return
		
	var text = "[b]Name:[/b] " + item_controller.get_display_name() + "\n"
	text += "[b]Components:[/b]\n"
	
	# Reset and build component text
	_component_text = ""
	for component in item_controller.components:
		_add_component(component)
	text += _component_text
		
	if item_controller.current_interaction:
		text += "\nCurrent Interaction: " + item_controller.current_interaction.name
		if item_controller.interacting_npc:
			text += " (with " + item_controller.interacting_npc.get_display_name() + ")"
			text += "\nDuration: %.1f seconds" % item_controller.interaction_time
			
	info_text.text = text
