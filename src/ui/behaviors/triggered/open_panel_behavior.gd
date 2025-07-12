class_name OpenPanelBehavior extends BaseUIBehavior

## Opens a panel for an interaction when triggered
##
## Generic behavior that can be configured to open panels for different
## interaction types. The interaction_type parameter determines which
## panel to open.

var interaction_type: String = ""

func _on_configured() -> void:
	interaction_type = config.get("interaction_type", "")
	if interaction_type.is_empty():
		push_error("OpenPanelBehavior requires 'interaction_type' parameter")

func on_click(gamepiece: Gamepiece, tracker: UIRegistry.UIStateTracker) -> void:
	var controller = gamepiece.get_controller()
	if not controller:
		return
	
	# Get current interaction from controller
	var interaction = controller.get_current_interaction()
	
	if not interaction or interaction.name != interaction_type:
		return
	
	# Use UIElementProvider to display the interaction panel
	UIElementProvider.display_interaction_panel(interaction)
