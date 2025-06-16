class_name NpcEvents extends RefCounted

## Collection of NPC-related event classes

class NeedChangedEvent extends Event:
	var npc: Gamepiece
	var need_id: String
	var new_value: float
	
	func _init(piece: Gamepiece, need: String, value: float) -> void:
		super(Type.NPC_NEED_CHANGED)
		npc = piece
		need_id = need
		new_value = value

class InteractionObservationEvent extends Event:
	var npc: Gamepiece
	var observation: Dictionary
	
	func _init(piece: Gamepiece, obs: Dictionary) -> void:
		super(Type.NPC_INTERACTION_OBSERVATION)
		npc = piece
		observation = obs

class StateChangedEvent extends Event:
	var npc: Gamepiece
	var old_state_name: String
	var new_state_name: String
	var new_state: BaseControllerState
	
	func _init(piece: Gamepiece, old_name: String, new_name: String, state: BaseControllerState) -> void:
		super(Type.NPC_STATE_CHANGED)
		npc = piece
		old_state_name = old_name
		new_state_name = new_name
		new_state = state

## Static factory methods
static func create_need_changed(piece: Gamepiece, need: String, value: float) -> NeedChangedEvent:
	return NeedChangedEvent.new(piece, need, value)

static func create_interaction_observation(piece: Gamepiece, observation: Dictionary) -> InteractionObservationEvent:
	return InteractionObservationEvent.new(piece, observation)

static func create_state_changed(piece: Gamepiece, old_name: String, new_name: String, state: BaseControllerState) -> StateChangedEvent:
	return StateChangedEvent.new(piece, old_name, new_name, state)
