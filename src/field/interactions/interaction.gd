class_name Interaction extends RefCounted

const BidType = preload("res://src/field/interactions/interaction_bid.gd").BidType

var name: String
var description: String
var needs_filled: Array[Needs.Need]  # Needs this interaction will increase
var needs_drained: Array[Needs.Need] # Needs this interaction will decrease
var need_rates: Dictionary[Needs.Need, float] = {}  # Need change rates per second
var duration: float = 0.0
var requires_adjacency: bool = true

# Participant management (single-party by default)
var participants: Array[NpcController] = []
var max_participants: int = 1  # Single-party by default
var min_participants: int = 1

# Parameters for act_in_interaction actions (empty by default for simple interactions)
var act_in_interaction_parameters: Dictionary[String, PropertySpec] = {}

signal act_in_interaction_received(participant: NpcController, validated_parameters: Dictionary)


func _init(_name: String, _description: String, _requires_adjacency: bool = true):
	name = _name
	description = _description
	requires_adjacency = _requires_adjacency

# Participant management
func can_add_participant(npc: NpcController) -> bool:
	return participants.size() < max_participants and npc not in participants

func add_participant(npc: NpcController) -> bool:
	if not can_add_participant(npc):
		return false
	
	participants.append(npc)
	_on_participant_joined(npc)
	return true

func remove_participant(npc: NpcController) -> bool:
	if not (npc in participants and participants.size() > min_participants):
		return false
	
	participants.erase(npc)
	_on_participant_left(npc)
	return true

# Lifecycle hooks for subclasses
var on_start_handler: Callable
var on_end_handler: Callable
var on_participant_joined_handler: Callable
var on_participant_left_handler: Callable

func _on_start(context: Dictionary) -> void:
	if on_start_handler.is_valid():
		on_start_handler.call(self, context)

func _on_end(context: Dictionary) -> void:
	if on_end_handler.is_valid():
		on_end_handler.call(self, context)

func _on_participant_joined(participant: NpcController) -> void:
	if on_participant_joined_handler.is_valid():
		on_participant_joined_handler.call(self, participant)

func _on_participant_left(participant: NpcController) -> void:
	if on_participant_left_handler.is_valid():
		on_participant_left_handler.call(self, participant)

func act_in_interaction(participant: NpcController, raw_parameters: Dictionary) -> bool:
	if participant not in participants:
		return false
	
	# Validate parameters using PropertySpec
	var validated_parameters = PropertySpec.validate_properties(raw_parameters, act_in_interaction_parameters)
	if validated_parameters.is_empty() and not act_in_interaction_parameters.is_empty():
		return false
	
	act_in_interaction_received.emit(participant, validated_parameters)
	return true

# Infrastructure for subclasses to send observations
func send_observation_to_participant(participant: NpcController, observation: Dictionary) -> void:
	if participant not in participants:
		return
	
	# Add common interaction info to observation
	observation["interaction_name"] = name
	observation["participants"] = participants.map(func(p): return p.npc_id)
	
	# This could trigger events or call methods on the participant
	# For now, we'll emit a signal that controllers can listen to
	EventBus.dispatch(NpcEvents.create_interaction_observation(participant._gamepiece, observation))

# Default noop implementation for act_in_interaction actions
# Streaming interactions can override this to handle action parameters
func handle_act_in_interaction(participant: NpcController, parameters: Dictionary) -> void:
	pass

func can_start_with(npc: NpcController, item: ItemController) -> bool:
	# Basic validation - can be overridden by specific interaction types
	if requires_adjacency:
		var npc_cell = npc._gamepiece.cell
		var item_cell = item._gamepiece.cell
		var distance = abs(npc_cell.x - item_cell.x) + abs(npc_cell.y - item_cell.y)
		return distance <= 1
	return true

# Serialization method for backend communication
## Converts this interaction to a dictionary for serialization
## Note: needs_filled and needs_drained are converted from enums to strings
func to_dict() -> Dictionary[String, Variant]:
	var action_params = {}
	for param_name in act_in_interaction_parameters:
		var spec = act_in_interaction_parameters[param_name] as PropertySpec
		action_params[param_name] = spec.to_dict()
	
	var rates_dict = {}
	for need in need_rates:
		rates_dict[Needs.get_display_name(need)] = need_rates[need]
	
	return {
		"name": name,
		"description": description,
		"needs_filled": needs_filled.map(func(need: Needs.Need) -> String: return Needs.get_display_name(need)),
		"needs_drained": needs_drained.map(func(need: Needs.Need) -> String: return Needs.get_display_name(need)),
		"need_rates": rates_dict,
		"act_in_interaction_parameters": action_params
	}
