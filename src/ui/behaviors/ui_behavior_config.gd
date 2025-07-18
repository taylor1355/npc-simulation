class_name UIBehaviorConfig extends Resource

## Centralized configuration for UI behaviors associated with game states and interactions.
## This resource defines all the mappings between game state and UI responses in one place.

# A behavior paired with its trigger condition
class TriggeredBehavior:
	var trigger: UIBehaviorTrigger
	var behavior_class: GDScript
	var behavior_config: Dictionary
	
	func _init(t: UIBehaviorTrigger, cls: GDScript, cfg: Dictionary = {}):
		trigger = t
		behavior_class = cls
		behavior_config = cfg
	
	## Create an instance of the behavior
	func create_behavior() -> BaseUIBehavior:
		var instance = behavior_class.new() as BaseUIBehavior
		if instance:
			instance.configure(behavior_config)
		return instance

# Default behaviors for all entities
static func get_default_behaviors() -> Array[TriggeredBehavior]:
	return [
		# Hover behavior for all entities - highlights the entity itself
		TriggeredBehavior.new(
			UIBehaviorTrigger.for_event("hover"),
			HighlightOnHoverBehavior,
			{
				"highlight_target": "self",
				"highlight_color": Color(1.2, 1.2, 1.2),
				"highlight_priority": HighlightManager.Priority.HOVER
			}
		),
		
		# Click behavior for gamepieces
		TriggeredBehavior.new(
			UIBehaviorTrigger.for_event("click"),
			SelectBehavior,
			{}
		)
	]

# State-specific behaviors
static func get_state_behaviors() -> Array[TriggeredBehavior]:
	return [
		# Conversation state emoji click
		TriggeredBehavior.new(
			UIBehaviorTrigger.for_event("click")
				.with_entity("npc")
				.with_state("interacting")
				.with_interaction("conversation")
				.with_ui_element_type(Globals.UIElementType.NAMEPLATE_EMOJI),
			OpenPanelBehavior,
			{
				"interaction_type": "conversation"
			}
		),
		
		# Conversation state emoji hover - highlight all participants
		TriggeredBehavior.new(
			UIBehaviorTrigger.for_event("hover")
				.with_entity("npc")
				.with_state("interacting")
				.with_interaction("conversation")
				.with_ui_element_type(Globals.UIElementType.NAMEPLATE_EMOJI),
			HighlightOnHoverBehavior,
			{
				"highlight_target": "interaction",
				"highlight_color": Color(1.0, 1.0, 0.5, 0.8),
				"highlight_priority": HighlightManager.Priority.INTERACTION_TARGET
			}
		),
		
		# Eating state tooltip on hover
		TriggeredBehavior.new(
			UIBehaviorTrigger.for_event("hover")
				.with_entity("npc")
				.with_state("interacting")
				.with_interaction("eat"),
			ShowTooltipBehavior,
			{
				"tooltip_text": "Eating {item_name}"
			}
		)
	]

# Item-specific behaviors
static func get_item_behaviors() -> Array[TriggeredBehavior]:
	return [
		# Consumable items during interaction
		TriggeredBehavior.new(
			UIBehaviorTrigger.for_event("hover")
				.with_entity("item")
				.with_components(["consumable"])
				.with_active_interaction(),
			PulseBehavior,
			{
				"pulse_color": Color(1.0, 0.8, 0.8, 1.0),
				"pulse_rate": 2.0
			}
		)
	]

# Interaction-specific behaviors
static func get_interaction_behaviors() -> Array[TriggeredBehavior]:
	return [
		# Multi-party interaction lines (conversations, etc.)
		# Start drawing lines when conversation starts
		TriggeredBehavior.new(
			UIBehaviorTrigger.for_event("interaction_started")
				.with_interaction("conversation"),
			MultiPartyInteractionBehavior,
			{}
		),
		# Stop drawing lines when conversation ends
		TriggeredBehavior.new(
			UIBehaviorTrigger.for_event("interaction_ended")
				.with_interaction("conversation"),
			MultiPartyInteractionBehavior,
			{}
		)
	]

# Get all behavior configurations
static func get_all_behaviors() -> Array[TriggeredBehavior]:
	var behaviors: Array[TriggeredBehavior] = []
	behaviors.append_array(get_default_behaviors())
	behaviors.append_array(get_state_behaviors())
	behaviors.append_array(get_item_behaviors())
	behaviors.append_array(get_interaction_behaviors())
	return behaviors

# Find matching behaviors for a given state and event
static func find_matching_behaviors(controller_info: Dictionary, event_type: String) -> Array[TriggeredBehavior]:
	var matching: Array[TriggeredBehavior] = []
	var all_behaviors = get_all_behaviors()
	
	for entry in all_behaviors:
		if entry.trigger.matches(controller_info, event_type):
			matching.append(entry)
	
	return matching
