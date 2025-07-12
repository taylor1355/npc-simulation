class_name HighlightTargetBehavior extends BaseUIBehavior

## Behavior that highlights an interaction's participants and visuals.
## Works for both hover (continuous highlight) and click (brief flash).

var highlight_color: Color = Color.YELLOW
var flash_duration: float = 2.0  # Only used for click events

func _on_configured() -> void:
	highlight_color = config.get("highlight_color", Color.YELLOW)
	flash_duration = config.get("flash_duration", 2.0)

func on_click(gamepiece: Gamepiece, tracker: UIRegistry.UIStateTracker) -> void:
	var controller = _get_controller(gamepiece)
	if not controller:
		return
	
	# For NPCs, highlight their interaction target
	if controller is NpcController:
		var npc = controller as NpcController
		if npc.current_interaction:
			# Highlight the interaction in the UI state tracker
			tracker.highlight_interaction(npc.current_interaction.id)
			
			# Set a timer to unhighlight after flash_duration
			if flash_duration > 0:
				var timer = gamepiece.get_tree().create_timer(flash_duration)
				timer.timeout.connect(func(): tracker.unhighlight_interaction(npc.current_interaction.id))

func on_hover_start(gamepiece: Gamepiece, tracker: UIRegistry.UIStateTracker) -> void:
	var controller = _get_controller(gamepiece)
	if not controller:
		return
	
	# For NPCs, highlight their interaction
	if controller is NpcController:
		var npc = controller as NpcController
		if npc.current_interaction:
			tracker.highlight_interaction(npc.current_interaction.id)

func on_hover_end(gamepiece: Gamepiece, tracker: UIRegistry.UIStateTracker) -> void:
	var controller = _get_controller(gamepiece)
	if not controller:
		return
	
	# For NPCs, unhighlight their interaction
	if controller is NpcController:
		var npc = controller as NpcController
		if npc.current_interaction:
			tracker.unhighlight_interaction(npc.current_interaction.id)
