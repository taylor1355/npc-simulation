extends Node2D

var visual_handlers: Dictionary = {}  # interaction_id -> handler instance
var handler_registry: Dictionary = {
	"conversation": preload("res://src/field/interaction_visuals/handlers/conversation_visual_handler.gd")
	# Easy to add more interaction types here
}

func _ready() -> void:
	if not Engine.is_editor_hint():
		EventBus.event_dispatched.connect(_on_event_dispatched)

func _on_event_dispatched(event: Event) -> void:
	match event.event_type:
		Event.Type.INTERACTION_STARTED:
			_handle_interaction_started(event as InteractionEvents.InteractionStartedEvent)
		Event.Type.INTERACTION_ENDED:
			_handle_interaction_ended(event as InteractionEvents.InteractionEndedEvent)
		Event.Type.INTERACTION_PARTICIPANT_JOINED:
			_handle_participant_joined(event as InteractionEvents.InteractionParticipantJoinedEvent)
		Event.Type.INTERACTION_PARTICIPANT_LEFT:
			_handle_participant_left(event as InteractionEvents.InteractionParticipantLeftEvent)

func _handle_interaction_started(event: InteractionEvents.InteractionStartedEvent) -> void:
	# Check if we have a visual handler for this interaction type
	var HandlerClass = handler_registry.get(event.interaction_type)
	if HandlerClass:
		var handler = HandlerClass.new()
		handler.setup(event.interaction_id, event.participants)
		add_child(handler)
		visual_handlers[event.interaction_id] = handler

func _handle_interaction_ended(event: InteractionEvents.InteractionEndedEvent) -> void:
	var handler = visual_handlers.get(event.interaction_id)
	if handler:
		visual_handlers.erase(event.interaction_id)
		handler.queue_free()

func _handle_participant_joined(event: InteractionEvents.InteractionParticipantJoinedEvent) -> void:
	var handler = visual_handlers.get(event.interaction_id)
	if handler:
		handler.add_participant(event.joined_participant)

func _handle_participant_left(event: InteractionEvents.InteractionParticipantLeftEvent) -> void:
	var handler = visual_handlers.get(event.interaction_id)
	if handler:
		handler.remove_participant(event.left_participant)