## Utility class for formatting NPC events into text observations
## and defining available actions for the NPC backend.
class_name EventFormatter
extends Node

## Formats a list of NPC events into a text observation
func format_events_as_observation(events: Array[NpcEvent], npc_position: Vector2i, max_need_value: float) -> String:
	var parts = ["# Current Status\n"]
	
	# Add initial position header
	parts.append("## Position")
	parts.append("You are at position (%d,%d).\n" % [npc_position.x, npc_position.y])
	
	# Process events and format observations
	for event in events:
		if event.payload is Observation:
			var formatted = event.payload.format_for_npc()
			if not formatted.is_empty():
				parts.append(formatted)
		else:
			# TODO: Remove this fallback once all events use Observation objects
			push_warning("Event type %s still using Dictionary payload" % NpcEvent.Type.keys()[event.type])
	
	# Add environment header if we haven't already
	parts.append("# Environment\n")
	
	return "\n".join(parts)

## Returns a list of available actions for the NPC backend
## Format: Array of action objects with {name, description, parameters} fields
## - name: string identifier for the action
## - description: human-readable description
## - parameters: dictionary of parameter descriptions
func get_available_actions() -> Array[Dictionary]:
	return Action.get_all_action_descriptions()
