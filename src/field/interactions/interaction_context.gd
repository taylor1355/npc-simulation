class_name InteractionContext extends RefCounted

## Unified context for all interaction types (single-party and multi-party)

## Core properties
var interaction: Interaction  # null if not started yet
var host: GamepieceController  # Who hosts this (item, npc, etc)
var context_type: ContextType  # ENTITY or GROUP
var is_active: bool = false  # Is there an active interaction?

enum ContextType { ENTITY, GROUP }

func _init(_host: GamepieceController, _type: ContextType):
	host = _host
	context_type = _type

## Get a display-friendly name for this context
func get_display_name() -> String:
	if interaction and interaction.participants.size() > 1:
		return "%s (%d participants)" % [interaction.name.capitalize(), interaction.participants.size()]
	elif host:
		return host.get_display_name()
	return "Unknown"

## Get the position of this context (entity position or group centroid)
func get_position() -> Vector2i:
	if context_type == ContextType.GROUP and interaction:
		# Calculate centroid for group interactions
		var sum := Vector2.ZERO  # Use Vector2 for floating point precision
		for p in interaction.participants:
			sum += Vector2(p.get_cell_position())
		return Vector2i(sum / interaction.participants.size())  # Convert back after division
	elif host:
		return host.get_cell_position()
	return Vector2i.ZERO

## Get the entity type for this context
func get_entity_type() -> String:
	if context_type == ContextType.GROUP:
		return "group"
	elif host:
		return host.get_entity_type()
	return "unknown"

## Handle interaction cancellation in context-appropriate way
func handle_cancellation(_interaction_ref: Interaction, controller: NpcController) -> void:
	if not interaction:
		return
		
	if context_type == ContextType.ENTITY:
		# Use bid system for single-party
		_handle_entity_cancellation(controller)
	else:
		# Direct removal for multi-party
		interaction.remove_participant(controller)

func _handle_entity_cancellation(controller: NpcController) -> void:
	if not host:
		push_warning("No host for entity cancellation")
		return
	
	var request = _create_cancellation_bid(controller)
	
	# Log the cancel request
	controller.event_log.append(NpcEvent.create_interaction_request_event(request))
	
	_setup_cancellation_handlers(request, controller)
	
	# Submit the cancellation request
	host.handle_interaction_bid(request)

func _create_cancellation_bid(controller: NpcController) -> InteractionBid:
	return InteractionBid.new(
		interaction.name,
		InteractionBid.BidType.CANCEL,
		controller,
		host
	)

func _setup_cancellation_handlers(request: InteractionBid, controller: NpcController) -> void:
	request.accepted.connect(_on_cancellation_accepted.bind(request, controller))
	request.rejected.connect(_on_cancellation_rejected.bind(controller))

func _on_cancellation_accepted(request: InteractionBid, controller: NpcController) -> void:
	print("[DEBUG] Cancel bid accepted for NPC %s" % controller.npc_id)
	controller.event_log.append(NpcEvent.create_interaction_update_event(
		request,
		NpcEvent.Type.INTERACTION_CANCELED
	))
	controller.current_request = null
	controller.current_interaction = null
	print("[DEBUG] Changing NPC %s state to idle" % controller.npc_id)
	controller.state_machine.change_state(ControllerIdleState.new(controller))

func _on_cancellation_rejected(reason: String, controller: NpcController) -> void:
	controller.event_log.append(NpcEvent.create_interaction_rejected_event(controller.current_request, reason))

## Check if an interaction can be started in this context
func can_start_interaction(requester: NpcController, factory: InteractionFactory) -> bool:
	# Check if we already have an active interaction of this type
	if is_active and interaction and interaction.name == factory.get_interaction_name():
		return false  # Can't start duplicate
	
	# Check global registry for any active interactions of this type
	if requester and InteractionRegistry.is_participating_in(requester, factory.get_interaction_name()):
		return false  # Already in an interaction of this type
	
	# Let factory do additional validation
	return factory.can_create_for(requester if requester else host)

## Get context data for backend observations
func get_context_data(interaction_ref: Interaction, duration: float) -> Dictionary:
	var context = {
		"interaction_name": interaction_ref.name,
		"duration": duration
	}
	
	if context_type == ContextType.ENTITY and host:
		context["entity_name"] = host.get_display_name()
		context["entity_type"] = host.get_entity_type()
		
		var position = host.get_cell_position()
		if position != null:
			context["entity_position"] = {
				"x": position.x,
				"y": position.y
			}
	elif context_type == ContextType.GROUP and interaction:
		context["interaction_type"] = "multi_party"
		context["participant_count"] = interaction.participants.size()
		context["participant_names"] = interaction.participants.map(func(p): return p.get_display_name())
	
	return context

## Check whether this context can be used for the given interaction
func is_valid_for_interaction(interaction_ref: Interaction) -> bool:
	if context_type == ContextType.ENTITY:
		return host != null and interaction_ref.max_participants == 1
	else:
		return interaction_ref != null and interaction_ref.max_participants > 1

## Set up appropriate completion signals based on context type
func setup_completion_signals(controller: NpcController, interaction_ref: Interaction) -> void:
	if context_type == ContextType.ENTITY and host:
		host.interaction_finished.connect(
			controller._on_interaction_finished,
			Node.CONNECT_ONE_SHOT
		)
	elif context_type == ContextType.GROUP and interaction_ref:
		# For multi-party interactions, the interaction itself handles completion
		# Check if the interaction has an interaction_ended signal
		if interaction_ref.has_signal("interaction_ended"):
			interaction_ref.interaction_ended.connect(
				func(name, initiator, payload): controller._on_interaction_finished(name, initiator, payload),
				Node.CONNECT_ONE_SHOT
			)
