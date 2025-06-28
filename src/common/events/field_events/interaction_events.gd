class_name InteractionEvents

# Base class for all interaction-related events
class InteractionEvent extends Event:
	var interaction_id: String
	var interaction_type: String  # "conversation", "sit", "consume", etc.
	var participants: Array[NpcController]
	
	func _init(event_type: Event.Type, id: String, type: String, npcs: Array[NpcController]):
		super._init(event_type)
		interaction_id = id
		interaction_type = type
		participants = npcs

# Dispatched when any interaction starts
class InteractionStartedEvent extends InteractionEvent:
	func _init(id: String, type: String, npcs: Array[NpcController]):
		super._init(Event.Type.INTERACTION_STARTED, id, type, npcs)

# Dispatched when any interaction ends
class InteractionEndedEvent extends InteractionEvent:
	func _init(id: String, type: String, npcs: Array[NpcController]):
		super._init(Event.Type.INTERACTION_ENDED, id, type, npcs)

# Dispatched when a participant joins a multi-party interaction
class InteractionParticipantJoinedEvent extends InteractionEvent:
	var joined_participant: NpcController
	
	func _init(id: String, type: String, npcs: Array[NpcController], joined: NpcController):
		super._init(Event.Type.INTERACTION_PARTICIPANT_JOINED, id, type, npcs)
		joined_participant = joined

# Dispatched when a participant leaves a multi-party interaction
class InteractionParticipantLeftEvent extends InteractionEvent:
	var left_participant: NpcController
	
	func _init(id: String, type: String, npcs: Array[NpcController], left: NpcController):
		super._init(Event.Type.INTERACTION_PARTICIPANT_LEFT, id, type, npcs)
		left_participant = left

# Factory methods following project patterns
static func create_interaction_started(id: String, type: String, participants: Array[NpcController]) -> InteractionStartedEvent:
	return InteractionStartedEvent.new(id, type, participants)

static func create_interaction_ended(id: String, type: String, participants: Array[NpcController]) -> InteractionEndedEvent:
	return InteractionEndedEvent.new(id, type, participants)

static func create_interaction_participant_joined(id: String, type: String, participants: Array[NpcController], joined: NpcController) -> InteractionParticipantJoinedEvent:
	return InteractionParticipantJoinedEvent.new(id, type, participants, joined)

static func create_interaction_participant_left(id: String, type: String, participants: Array[NpcController], left: NpcController) -> InteractionParticipantLeftEvent:
	return InteractionParticipantLeftEvent.new(id, type, participants, left)