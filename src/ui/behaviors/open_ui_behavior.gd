class_name OpenUIBehavior extends BaseUIBehavior

## Behavior that opens UI elements (panels, windows, etc.) for specific interactions.
## Configured with ui_type to determine what kind of UI to open.

var ui_element_type: String = ""  # "conversation", "inventory", etc.
var focus_entity_on_open: bool = true  # Whether to focus the entity when opening interaction UI

func _on_configured() -> void:
	ui_element_type = config.get("ui_element_type", "")
	focus_entity_on_open = config.get("focus_entity_on_open", true)

func on_click(gamepiece: Gamepiece) -> void:
	var controller = _get_controller(gamepiece)
	if not controller:
		return
	
	# For now, only handle NPCs with active interactions
	if controller is NpcController:
		var npc = controller as NpcController
		if npc.current_interaction:
			_open_panel_for_interaction(npc, npc.current_interaction)

func _open_panel_for_interaction(npc: NpcController, interaction: Interaction) -> void:
	# Use UIElementProvider to display the interaction panel
	UIElementProvider.display_interaction_panel(interaction)
	
	# Also focus the entity to show its info in tabs
	if focus_entity_on_open:
		var event = GamepieceEvents.create_focused(npc.get_parent() as Gamepiece)
		EventBus.dispatch(event)