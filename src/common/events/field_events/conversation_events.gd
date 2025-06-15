class_name ConversationEvents

# Conversation protocol events - similar to network packets

# Base conversation event with common fields
class ConversationEvent extends Event:
	var conversation_id: String
	var participants: Array[NpcController] = []
	
	func _init(event_type: Event.Type, conv_id: String, npcs: Array[NpcController]):
		super._init(event_type)
		conversation_id = conv_id
		participants = npcs

# Invitation to start a conversation
class InviteEvent extends ConversationEvent:
	var initiator: NpcController
	var invitees: Array[NpcController] = []
	var topic: String = ""
	
	func _init(conv_id: String, from_npc: NpcController, to_npcs: Array[NpcController], conv_topic: String = ""):
		super._init(Event.Type.CONVERSATION_INVITE, conv_id, [from_npc] + to_npcs)
		initiator = from_npc
		invitees = to_npcs
		topic = conv_topic

# Response to conversation invitation
class ResponseEvent extends ConversationEvent:
	var responder: NpcController
	var accepted: bool
	var reason: String = ""
	
	func _init(conv_id: String, from_npc: NpcController, is_accepted: bool, rejection_reason: String = ""):
		super._init(Event.Type.CONVERSATION_RESPONSE, conv_id, [from_npc])
		responder = from_npc
		accepted = is_accepted
		reason = rejection_reason

# Conversation has started with all participants
class StartedEvent extends ConversationEvent:
	var location: Vector2i
	
	func _init(conv_id: String, npcs: Array[NpcController], at_location: Vector2i):
		super._init(Event.Type.CONVERSATION_STARTED, conv_id, npcs)
		location = at_location

# Message sent during conversation
class MessageEvent extends ConversationEvent:
	var speaker: NpcController
	var message: String
	var emote: String = ""
	
	func _init(conv_id: String, from_npc: NpcController, text: String, emotion: String = ""):
		super._init(Event.Type.CONVERSATION_MESSAGE, conv_id, [from_npc])
		speaker = from_npc
		message = text
		emote = emotion

# NPC leaving conversation
class LeaveEvent extends ConversationEvent:
	var leaver: NpcController
	var reason: String = ""
	
	func _init(conv_id: String, npc: NpcController, leave_reason: String = ""):
		super._init(Event.Type.CONVERSATION_LEAVE, conv_id, [npc])
		leaver = npc
		reason = leave_reason

# Conversation ended
class EndedEvent extends ConversationEvent:
	var reason: String
	
	func _init(conv_id: String, npcs: Array[NpcController], end_reason: String):
		super._init(Event.Type.CONVERSATION_ENDED, conv_id, npcs)
		reason = end_reason

# Factory methods
static func create_invite(initiator: NpcController, invitees: Array[NpcController], topic: String = "") -> InviteEvent:
	var conv_id = str(Time.get_unix_time_from_system()) + "_" + str(initiator.get_instance_id())
	return InviteEvent.new(conv_id, initiator, invitees, topic)

static func create_response(conversation_id: String, responder: NpcController, accepted: bool, reason: String = "") -> ResponseEvent:
	return ResponseEvent.new(conversation_id, responder, accepted, reason)

static func create_started(conversation_id: String, participants: Array[NpcController], location: Vector2i) -> StartedEvent:
	return StartedEvent.new(conversation_id, participants, location)

static func create_message(conversation_id: String, speaker: NpcController, message: String, emote: String = "") -> MessageEvent:
	return MessageEvent.new(conversation_id, speaker, message, emote)

static func create_leave(conversation_id: String, leaver: NpcController, reason: String = "") -> LeaveEvent:
	return LeaveEvent.new(conversation_id, leaver, reason)

static func create_ended(conversation_id: String, participants: Array[NpcController], reason: String) -> EndedEvent:
	return EndedEvent.new(conversation_id, participants, reason)