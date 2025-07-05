extends RefCounted

class_name ConversationUtils

# Conversation state tracking
class ConversationState:
	var sent_greeting: bool = false
	var sent_farewell: bool = false
	var farewell_sent_at: float = 0.0
	var last_message_attempt_time: float = 0.0
	var pending_message: String = ""
	var conversation_turn_count: int = 0
	
	func _init():
		pass
	
	func reset() -> void:
		sent_greeting = false
		sent_farewell = false
		farewell_sent_at = 0.0
		last_message_attempt_time = 0.0
		pending_message = ""
		conversation_turn_count = 0

# Constants for conversation timing
const FAREWELL_DELAY: float = 1.5  # Wait time after farewell before leaving
const MESSAGE_RETRY_DELAY: float = 3.5  # Wait time before retrying blocked messages
const MIN_CONVERSATION_COOLDOWN: float = 5.0  # Minimum time between conversations

static func should_end_conversation_based_on_history(total_messages: int) -> bool:
	"""Decide if conversation should end based on total message count"""
	var end_probability = min(0.8, float(total_messages / 2) * 0.25)
	return randf() < end_probability

static func can_send_message(state: ConversationState, current_time: float) -> bool:
	"""Check if enough time has passed to send another message"""
	if state.pending_message.is_empty():
		return true
	
	var time_since_attempt = current_time - state.last_message_attempt_time
	return time_since_attempt >= MESSAGE_RETRY_DELAY

static func should_leave_after_farewell(state: ConversationState, current_time: float) -> bool:
	"""Check if enough time has passed after farewell to leave conversation"""
	if not state.sent_farewell:
		return false
	
	var time_since_farewell = current_time - state.farewell_sent_at
	return time_since_farewell >= FAREWELL_DELAY

static func was_message_sent_successfully(state: ConversationState, agent_id: String, conversation_history: Array) -> bool:
	"""Check if pending message appears in conversation history"""
	if state.pending_message.is_empty():
		return true
	
	for msg in conversation_history:
		if msg.get("speaker") == agent_id and msg.get("message") == state.pending_message:
			return true
	
	return false

static func get_next_message(state: ConversationState, agent_id: String, conversation_obs: ConversationObservation) -> Dictionary:
	"""Determine what message to send next and update state accordingly"""
	var result = {
		"message": "",
		"should_send": false
	}
	
	var current_time = Time.get_unix_time_from_system()
	
	# Check if we're still waiting after farewell
	if should_leave_after_farewell(state, current_time):
		return result  # Don't send anything, time to leave
	
	# Check if we need to wait before retrying a message
	if not can_send_message(state, current_time):
		return result  # Still waiting to retry
	
	# If we have a pending message, check if it was sent
	if not state.pending_message.is_empty():
		if was_message_sent_successfully(state, agent_id, conversation_obs.conversation_history):
			# Message was sent successfully, clear pending
			state.pending_message = ""
			state.conversation_turn_count += 1
		else:
			# Message wasn't sent yet, retry it
			result.message = state.pending_message
			result.should_send = true
			state.last_message_attempt_time = current_time
			return result
	
	# Determine new message to send
	if not state.sent_greeting:
		# Send greeting
		result.message = ConversationPhrases.get_random_greeting()
		state.sent_greeting = true
		result.should_send = true
	else:
		# Check if we should end conversation
		var total_messages = conversation_obs.conversation_history.size()
		if should_end_conversation_based_on_history(total_messages):
			result.message = ConversationPhrases.get_random_farewell()
			state.sent_farewell = true
			state.farewell_sent_at = current_time
			result.should_send = true
		else:
			result.message = ConversationPhrases.get_random_response()
			result.should_send = true
	
	# Store as pending and record attempt time
	if result.should_send:
		state.pending_message = result.message
		state.last_message_attempt_time = current_time
	
	return result

static func should_start_conversation(agent_id: String, nearby_npcs: Array, last_conversation_time: float) -> Dictionary:
	"""Decide if agent should start a conversation with a nearby NPC"""
	var result = {
		"should_start": false,
		"target": null
	}
	
	if nearby_npcs.is_empty():
		return result
	
	# Check cooldown
	var current_time = Time.get_unix_time_from_system()
	var time_since_conversation = current_time - last_conversation_time
	if time_since_conversation < MIN_CONVERSATION_COOLDOWN:
		return result
	
	# Random chance to start conversation
	if randf() < 0.2:
		result.should_start = true
		result.target = nearby_npcs.pick_random()
	
	return result