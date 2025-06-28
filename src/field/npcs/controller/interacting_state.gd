extends BaseControllerState

class_name ControllerInteractingState

var interaction: Interaction
var context: InteractionContext
var started_at: float

func _init(controller_ref: NpcController, _interaction: Interaction, _context: InteractionContext) -> void:
	super(controller_ref)
	interaction = _interaction
	context = _context

func enter(action_name: String = "", parameters: Dictionary = {}) -> void:
	super.enter(action_name, parameters)
	# interaction and context must be set
	assert(interaction != null, "InteractingState requires interaction to be set")
	assert(context != null, "InteractingState requires context to be set")
	started_at = Time.get_unix_time_from_system()
	
	# Listen for interaction observations directed at this NPC
	EventBus.event_dispatched.connect(_on_event_dispatched)

func handle_action(action_name: String, parameters: Dictionary) -> bool:
	match action_name:
		"cancel_interaction":
			_try_cancel_interaction()
			return true
		"continue":
			return true
		"act_in_interaction":
			_handle_act_in_interaction(parameters)
			return true
		_:
			return super.handle_action(action_name, parameters)

func _try_cancel_interaction() -> void:
	if not interaction or not context:
		return
	
	# Delegate cancellation to the context
	context.handle_cancellation(interaction, controller)

func on_interaction_finished(interaction_name: String, npc: NpcController, payload: Dictionary) -> void:
	# Log interaction finished event
	controller.event_log.append(NpcEvent.create_interaction_update_event(
		controller.current_request,
		NpcEvent.Type.INTERACTION_FINISHED
	))
	
	interaction._on_end(payload)
	
	# Clear interaction state
	controller.current_interaction = null # NpcController manages this
	controller.current_request = null # NpcController manages this
	
	# Return to idle
	controller.state_machine.change_state(ControllerIdleState.new(controller))
	
	# Trigger new decision (IdleState.enter will handle this)
	# controller.decide_behavior() # Removed as IdleState.enter will trigger it

func exit() -> void:
	if EventBus.event_dispatched.is_connected(_on_event_dispatched):
		EventBus.event_dispatched.disconnect(_on_event_dispatched)
	super.exit()

func _handle_act_in_interaction(parameters: Dictionary) -> void:
	if not interaction:
		return
		
	interaction.handle_act_in_interaction(controller, parameters)

func _on_event_dispatched(event: Event) -> void:
	if not event.is_type(Event.Type.NPC_INTERACTION_OBSERVATION):
		return
		
	var observation_event = event as NpcEvents.InteractionObservationEvent
	if observation_event.npc != controller._gamepiece:
		return
		
	var interaction_observation_event = NpcEvent.create_interaction_observation_event(
		observation_event.observation.get("interaction_name", ""),
		observation_event.observation
	)
	controller.event_log.append(interaction_observation_event)

func get_context_data() -> Dictionary:
	if not context or not interaction:
		return {}
	
	var duration = Time.get_unix_time_from_system() - started_at
	return context.get_context_data(interaction, duration)

func get_state_emoji() -> String:
	return interaction.get_interaction_emoji()

func get_state_description() -> String:
	if interaction and context:
		return "%s with %s" % [interaction.name.capitalize(), context.get_display_name()]
	return ""
