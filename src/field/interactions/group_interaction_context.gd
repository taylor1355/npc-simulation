class_name GroupInteractionContext extends InteractionContext

# Context for multi-party interactions (conversations, group activities)
var interaction: Interaction

func _init(_interaction: Interaction):
	interaction = _interaction

func get_display_name() -> String:
	if interaction:
		return "%s (%d participants)" % [interaction.name.capitalize(), interaction.participants.size()]
	return "Unknown Group"

func get_position() -> Vector2i:
	# By default, use the centroid of all participants
	var centroid = Vector2i.ZERO
	if not interaction or interaction.participants.size() == 0:
		return centroid # No participants, return zero vector
	for participant in interaction.participants:
		centroid += participant.get_position()
	return centroid / interaction.participants.size()

func get_entity_type() -> String:
	return "group"

func handle_cancellation(_interaction_ref: Interaction, controller: NpcController) -> void:
	if not interaction:
		push_warning("No interaction for cancellation")
		return
	
	# For streaming interactions, use direct participant removal
	if interaction is StreamingInteraction:
		var streaming = interaction as StreamingInteraction
		streaming.remove_participant(controller)
		
		# Log cancellation
		controller.event_log.append(NpcEvent.create_interaction_update_event(
			controller.current_request,
			NpcEvent.Type.INTERACTION_CANCELED
		))
		
		# Clear state and return to idle
		controller.current_request = null
		controller.current_interaction = null
		controller.state_machine.change_state(ControllerIdleState.new(controller))
	else:
		push_warning("Cannot cancel non-streaming multi-party interaction")

func get_context_data(interaction_ref: Interaction, duration: float) -> Dictionary:
	var context = super.get_context_data(interaction_ref, duration)
	
	if interaction:
		context["interaction_type"] = "multi_party"
		context["participant_count"] = interaction.participants.size()
		context["participant_names"] = interaction.participants.map(func(p): return p.get_display_name())
	
	return context

func is_valid_for_interaction(interaction_ref: Interaction) -> bool:
	return interaction != null and interaction_ref != null and interaction_ref.max_participants > 1

func setup_completion_signals(controller: NpcController, _interaction_ref: Interaction) -> void:
	if interaction:
		# For multi-party interactions, the interaction itself handles completion
		# Check if the interaction has an interaction_ended signal
		if interaction.has_signal("interaction_ended"):
			interaction.interaction_ended.connect(
				func(name, initiator, payload): controller._on_interaction_finished(name, initiator, payload),
				Node.CONNECT_ONE_SHOT
			)
