class_name ShowTooltipBehavior extends BaseUIBehavior

## Behavior that displays tooltips with configurable text.
## The tooltip text can include placeholders that are filled from controller info.

var tooltip_text: String = ""
var _tooltip_scene = preload("res://src/ui/tooltip.tscn")
var _tooltip_instance: Tooltip

func _on_configured() -> void:
	tooltip_text = config.get("tooltip_text", "")

func on_hover_start(gamepiece: Gamepiece) -> void:
	var controller = _get_controller(gamepiece)
	if not controller:
		return
	
	# Get controller info for text substitution
	var controller_info = controller.get_ui_info()
	
	# Format the tooltip text with available data
	var formatted_text = _format_tooltip_text(tooltip_text, controller_info)
	
	# Create and show tooltip
	if not _tooltip_instance:
		_tooltip_instance = _tooltip_scene.instantiate()
		gamepiece.get_tree().root.add_child(_tooltip_instance)
	
	_tooltip_instance.show_tooltip(formatted_text)

func on_hover_end(gamepiece: Gamepiece) -> void:
	if _tooltip_instance:
		_tooltip_instance.hide_tooltip()

func on_click(gamepiece: Gamepiece) -> void:
	# Hide tooltip on click to avoid interference
	if _tooltip_instance:
		_tooltip_instance.hide_tooltip()

func _format_tooltip_text(text: String, info: Dictionary) -> String:
	var result = text
	
	# Replace placeholders with actual values
	if "{item_name}" in result and info.has(Globals.UIInfoFields.INTERACTING_WITH):
		result = result.replace("{item_name}", info[Globals.UIInfoFields.INTERACTING_WITH])
	
	# NPC name is already in the controller info
	if "{npc_name}" in result:
		var display_name = info.get("display_name", "Unknown")
		result = result.replace("{npc_name}", display_name)
	
	return result