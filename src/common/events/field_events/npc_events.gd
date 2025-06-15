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

## Static factory methods
static func create_need_changed(piece: Gamepiece, need: String, value: float) -> NeedChangedEvent:
	return NeedChangedEvent.new(piece, need, value)

static func create_interaction_observation(piece: Gamepiece, observation: Dictionary) -> InteractionObservationEvent:
	return InteractionObservationEvent.new(piece, observation)
