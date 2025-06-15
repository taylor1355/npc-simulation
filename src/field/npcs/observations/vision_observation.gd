class_name VisionObservation extends Observation

# TODO: Refactor to treat NPCs and Items uniformly as entities
# This violates single responsibility principle - VisionObservation shouldn't need to know
# about the differences between NPCs and Items. Both should implement a common interface
# (possibly at GamepieceController level) that provides interaction data in a uniform way.
# This would allow us to process all visible entities interchangeably.
var visible_entities: Array[Dictionary]

func _init(entities: Array[Dictionary]):
	self.visible_entities = entities

func get_type() -> String:
	return "vision"

func get_data() -> Dictionary:
	return {
		"visible_entities": visible_entities
	}

func format_for_npc() -> String:
	if visible_entities.is_empty():
		return "You don't see any items nearby."
	
	var parts = ["## Visible Items\n"]
	
	for item in visible_entities:
		parts.append("### %s (at position (%d,%d))" % [
			item.name, 
			item.cell.x, 
			item.cell.y
		])
		
		if not item.interactions.is_empty():
			parts.append("Interactions:")
			
			for interaction_name: String in item.interactions:
				var interaction: Dictionary = item.interactions[interaction_name]
				var line = "- **%s**: %s" % [interaction.name, interaction.description]
				
				# Add needs affected with sign only
				var effects: Array[String] = []
				
				if not interaction.needs_filled.is_empty():
					for need: String in interaction.needs_filled:
						effects.append("%s (+)" % need.capitalize())
				
				if not interaction.needs_drained.is_empty():
					for need: String in interaction.needs_drained:
						effects.append("%s (-)" % need.capitalize())
				
				if not effects.is_empty():
					line += " Effects: %s" % ", ".join(effects)
				
				parts.append(line)
		
		parts.append("")
	
	return "\n".join(parts)