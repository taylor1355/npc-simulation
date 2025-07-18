class_name UIBehaviorTrigger extends Resource

## Encapsulates the matching logic for UI behavior triggers.
## 
## This class is responsible for determining if a given game state
## matches the conditions that should activate a UI behavior.

# Required criteria (must be set)
@export var event_type: String = ""  # "hover", "click", "interaction_started", "interaction_ended", etc.

# Optional criteria (empty string means "any")
@export var entity_type: String = ""  # "npc", "item", or empty for any
@export var state_name: String = ""
@export var interaction_name: String = ""
@export var ui_element_type: Globals.UIElementType = -1  # -1 means "any"

# Optional array criteria (empty array means "any")
@export var required_components: Array[String] = []

# Optional boolean criteria
@export var requires_active_interaction: bool = false

## Create a trigger for a specific event type
static func for_event(event: String) -> UIBehaviorTrigger:
	var trigger = UIBehaviorTrigger.new()
	trigger.event_type = event
	return trigger

## Fluent interface for building triggers
func with_entity(type: String) -> UIBehaviorTrigger:
	entity_type = type
	return self

func with_state(name: String) -> UIBehaviorTrigger:
	state_name = name
	return self

func with_interaction(name: String) -> UIBehaviorTrigger:
	interaction_name = name
	return self

func with_ui_element_type(element_type: Globals.UIElementType) -> UIBehaviorTrigger:
	ui_element_type = element_type
	return self

func with_components(components: Array[String]) -> UIBehaviorTrigger:
	required_components = components
	return self

func with_active_interaction() -> UIBehaviorTrigger:
	requires_active_interaction = true
	return self

## Check if this trigger matches the given conditions
func matches(controller_info: Dictionary, event: String) -> bool:
	# Event type is required and must match
	if event_type != event:
		return false
	
	# Check all string criteria
	if not _matches_string_field(entity_type, controller_info, Globals.UIInfoFields.ENTITY_TYPE):
		return false
	
	if not _matches_string_field(state_name, controller_info, Globals.UIInfoFields.STATE_NAME):
		return false
	
	if not _matches_string_field(interaction_name, controller_info, Globals.UIInfoFields.INTERACTION_NAME):
		return false
	
	# Check UI element type matching
	if ui_element_type != -1:  # -1 means "any"
		var actual_type = controller_info.get(Globals.UIInfoFields.UI_ELEMENT_TYPE, -1)
		if actual_type != ui_element_type:
			return false
	
	# Check component requirements
	if not _has_required_components(controller_info):
		return false
	
	# Check interaction active requirement
	if requires_active_interaction:
		var is_active = controller_info.get(Globals.UIInfoFields.INTERACTION_ACTIVE, false)
		if not is_active:
			return false
	
	return true

## Check if a string field matches (empty string means any value is accepted)
func _matches_string_field(expected: String, info: Dictionary, field_name: String) -> bool:
	if expected.is_empty():
		return true
	
	var actual = info.get(field_name, "")
	return actual == expected

## Check if all required components are present
func _has_required_components(info: Dictionary) -> bool:
	if required_components.is_empty():
		return true
	
	var available_components = info.get(Globals.UIInfoFields.COMPONENT_TYPES, [])
	for component in required_components:
		if not component in available_components:
			return false
	
	return true