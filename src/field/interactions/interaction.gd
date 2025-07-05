class_name Interaction extends RefCounted

const BidType = preload("res://src/field/interactions/interaction_bid.gd").BidType

var id: String
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
signal participant_should_transition(participant: NpcController, interaction: Interaction)
signal interaction_ended(interaction_name: String, initiator: NpcController, payload: Dictionary)


func _init(_name: String, _description: String, _requires_adjacency: bool = true):
	name = _name
	description = _description
	requires_adjacency = _requires_adjacency
	id = IdGenerator.generate_interaction_id()

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
	if npc not in participants:
		return false
	
	participants.erase(npc)
	_on_participant_left(npc)
	
	# If we're below minimum participants, end the interaction gracefully
	if participants.size() < min_participants:
		_end_interaction_due_to_insufficient_participants()
	
	return true

# Helper method to end interaction when participants drop below minimum
func _end_interaction_due_to_insufficient_participants() -> void:
	# End the interaction - controllers will handle their own state transitions
	# through the normal event system when they receive INTERACTION_ENDED
	_on_end({"reason": "insufficient_participants", "remaining_participants": participants.size()})

# Lifecycle methods - subclasses override these and call super last
func _on_start(context: Dictionary) -> void:
	# Subclasses do their setup first, then call super to dispatch event
	var event = InteractionEvents.create_interaction_started(
		id, name, participants
	)
	EventBus.dispatch(event)

func _on_end(context: Dictionary) -> void:
	# Subclasses do their cleanup first, then call super to dispatch event
	var event = InteractionEvents.create_interaction_ended(
		id, name, participants
	)
	EventBus.dispatch(event)

func _on_participant_joined(participant: NpcController) -> void:
	# Signal participant to transition to InteractingState first
	participant_should_transition.emit(participant, self)
	
	# Then dispatch the event (subclasses handle the join before calling super)
	var event = InteractionEvents.create_interaction_participant_joined(
		id, name, participants, participant
	)
	EventBus.dispatch(event)

func _on_participant_left(participant: NpcController) -> void:
	# Subclasses handle the leave first, then call super to dispatch event
	var event = InteractionEvents.create_interaction_participant_left(
		id, name, participants, participant
	)
	EventBus.dispatch(event)

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
func send_observation_to_participant(participant: NpcController, observation: Observation) -> void:
	if participant not in participants:
		return
	
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

# Override in subclasses to provide interaction-specific emoji
func get_interaction_emoji() -> String:
	return "🔧"  # Default emoji

# Factory method to create appropriate context for this interaction
func create_context(target_controller: GamepieceController = null) -> InteractionContext:
	var context_type = InteractionContext.ContextType.GROUP if max_participants > 1 else InteractionContext.ContextType.ENTITY
	var host = target_controller if target_controller else (participants[0] if participants.size() > 0 else null)
	
	if not host and context_type == InteractionContext.ContextType.ENTITY:
		push_error("Entity interaction requires a host controller")
		return null
	
	var context = InteractionContext.new(host, context_type)
	if context_type == InteractionContext.ContextType.GROUP:
		context.interaction = self
	return context
