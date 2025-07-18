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
	print("[DEBUG] ControllerInteractingState: _try_cancel_interaction called for NPC %s" % controller.npc_id)
	if not interaction or not context:
		print("[DEBUG] No interaction or context to cancel")
		return
	
	print("[DEBUG] Delegating cancellation to context for interaction: %s" % interaction.name)
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

func exit() -> void:
	if EventBus.event_dispatched.is_connected(_on_event_dispatched):
		EventBus.event_dispatched.disconnect(_on_event_dispatched)
	super.exit()

func _handle_act_in_interaction(parameters: Dictionary) -> void:
	if not interaction:
		return
		
	interaction.handle_act_in_interaction(controller, parameters)

func _on_event_dispatched(event: Event) -> void:
	# Handle interaction observations
	if event.is_type(Event.Type.NPC_INTERACTION_OBSERVATION):
		var observation_event = event as NpcEvents.InteractionObservationEvent
		if observation_event.npc != controller._gamepiece:
			return
		
		var interaction_observation_event = NpcEvent.create_interaction_observation_event(
			observation_event.observation
		)
		controller.event_log.append(interaction_observation_event)
		
		# Immediately process streaming observations for real-time conversation flow
		controller.npc_client.process_observation(controller.npc_id, [interaction_observation_event])
	
	# Handle interaction ended events
	elif event.is_type(Event.Type.INTERACTION_ENDED):
		var ended_event = event as InteractionEvents.InteractionEndedEvent
		if interaction and ended_event.interaction_id == interaction.id:
			# Our interaction has ended - clean up and transition to idle
			# Don't call on_interaction_finished as that would call _on_end again
			controller.current_interaction = null
			controller.current_request = null
			controller.state_machine.change_state(ControllerIdleState.new(controller))

func get_context_data() -> Dictionary:
	if not context or not interaction:
		return {}
	
	var duration = Time.get_unix_time_from_system() - started_at
	return context.get_context_data(interaction, duration)

func get_state_emoji() -> String:
	return interaction.get_interaction_emoji()

func get_state_description(include_links: bool = false) -> String:
	if not interaction or not context:
		return ""
		
	var interaction_name = interaction.name.capitalize()
	
	# Make interaction name a link if requested and UI exists
	if include_links and UIElementProvider.has_ui_for_interaction(interaction.name):
		var link = UILink.interaction(interaction.id, interaction_name)
		interaction_name = link.to_bbcode()
	
	# For multi-party interactions, show participant names instead of redundant interaction name
	if interaction.participants.size() > 1:
		var other_participants = interaction.participants.filter(func(p): return p != controller)
		if other_participants.size() > 0:
			if other_participants.size() == 1:
				var participant = other_participants[0]
				var name_text = participant.get_display_name()
				if include_links:
					var link = UILink.entity(participant.get_entity_id(), name_text)
					name_text = link.to_bbcode()
				return "%s with %s" % [interaction_name, name_text]
			else:
				return "%s with %d others" % [interaction_name, other_participants.size()]
	
	# For single-party interactions with items
	if context.host:
		var host_name = context.host.get_display_name()
		if include_links:
			var link = UILink.entity(context.host.get_entity_id(), host_name)
			host_name = link.to_bbcode()
		return "%s with %s" % [interaction_name, host_name]
	else:
		return "%s with Unknown" % interaction_name

# Override bid handling to properly manage interaction transitions
func on_interaction_bid(bid: MultiPartyBid) -> void:
	# If this is a conversation bid, we should consider leaving our current interaction
	if bid.interaction_name == "conversation":
		# Always reject if already in any interaction to prevent overlapping
		if interaction:
			bid.add_participant_response(controller, false, "Already busy with %s" % interaction.name)
			return
		
		# Only accept if we're completely free
		if randf() < 0.8:  # High probability to join conversations
			bid.add_participant_response(controller, true)
		else:
			bid.add_participant_response(controller, false, "Not interested right now")
	else:
		# For other interaction types, reject while already interacting
		bid.add_participant_response(controller, false, "Currently busy")
