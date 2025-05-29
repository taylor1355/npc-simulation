## Utility class for formatting NPC events into text observations
## and defining available actions for the NPC backend.
class_name EventFormatter
extends Node

## Formats a list of NPC events into a text observation
func format_events_as_observation(events: Array[NpcEvent], npc_position: Vector2i, max_need_value: float) -> String:
	var observation_text = "# Current Status\n\n"
	
	# Add NPC position
	observation_text += "## Position\n"
	observation_text += "You are at position (%d,%d).\n\n" % [npc_position.x, npc_position.y]
	
	# Process events to extract needed information
	var needs = {}
	var seen_items = []
	var current_interaction = null
	var controller_state = {}
	
	for event in events:
		match event.type:
			NpcEvent.Type.OBSERVATION:
				needs = event.payload.needs
				seen_items = event.payload.seen_items
				current_interaction = event.payload.current_interaction
				controller_state = event.payload.get("controller_state", {})
	
	# Format needs as percentages
	if not needs.is_empty():
		observation_text += "## Needs\n"
		for need_id in needs:
			var percentage = (needs[need_id] / max_need_value) * 100
			observation_text += "- %s: %.0f%%\n" % [need_id.capitalize(), percentage]
		observation_text += "\n"
	
	# Format current interaction
	if current_interaction:
		observation_text += "## Current Interaction\n"
		observation_text += "You are currently %s.\n\n" % current_interaction.name
	
	# Format controller state
	if not controller_state.is_empty():
		observation_text += "## Controller State\n"
		observation_text += "- State: %s\n" % controller_state.get("state_enum", "UNKNOWN")
		var context_data = controller_state.get("context_data", {})
		if not context_data.is_empty():
			for key in context_data:
				var value = context_data[key]
				if value is Dictionary and value.has("x") and value.has("y"):
					observation_text += "- %s: (%d,%d)\n" % [key.capitalize(), value.x, value.y]
				else:
					observation_text += "- %s: %s\n" % [key.capitalize(), str(value)]
		observation_text += "\n"
	
	# Format environment and visible items
	observation_text += "# Environment\n\n"
	
	if not seen_items.is_empty():
		observation_text += "## Visible Items\n\n"
		
		for item in seen_items:
			observation_text += "### %s (at position (%d,%d))\n" % [
				item.name, 
				item.cell.x, 
				item.cell.y
			]
			
			if not item.interactions.is_empty():
				observation_text += "Interactions:\n"
				
				for interaction_name in item.interactions:
					var interaction = item.interactions[interaction_name]
					observation_text += "- **%s**: %s" % [interaction.name, interaction.description]
					
					# Add needs affected with sign only
					var effects = []
					
					if not interaction.needs_filled.is_empty():
						for need in interaction.needs_filled:
							effects.append("%s (+)" % Needs.get_display_name(need).capitalize())
					
					if not interaction.needs_drained.is_empty():
						for need in interaction.needs_drained:
							effects.append("%s (-)" % Needs.get_display_name(need).capitalize())
					
					if not effects.is_empty():
						observation_text += " Effects: %s" % ", ".join(effects)
					
					observation_text += "\n"
			
			observation_text += "\n"
	
	return observation_text

## Returns a list of available actions for the NPC backend
## Format: Array of action objects with {name, description, parameters} fields
## - name: string identifier for the action
## - description: human-readable description
## - parameters: dictionary of parameter descriptions
func get_available_actions() -> Array[Dictionary]:
	return Action.get_all_action_descriptions()
