extends Node

# Singleton that tracks all active interactions and provides context-aware queries

var _interactions_by_id: Dictionary[String, Interaction] = {}
var _interactions_by_participant: Dictionary[String, Array] = {}
var _contexts_by_host: Dictionary[String, Array] = {}
var _interaction_contexts: Dictionary[String, InteractionContext] = {}  # interaction_id -> context

func _ready():
	# Listen for interaction lifecycle events
	EventBus.event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.INTERACTION_ENDED):
				var ended_event = event as InteractionEvents.InteractionEndedEvent
				_on_interaction_ended(ended_event.interaction_id)
	)

func register_interaction(interaction: Interaction, context: InteractionContext) -> void:
	if not interaction or not context:
		push_error("InteractionRegistry: Cannot register null interaction or context")
		return
		
	if interaction.participants.is_empty():
		push_error("InteractionRegistry: Cannot register interaction with no participants")
		return
		
	# Check for duplicate registration
	if _interactions_by_id.has(interaction.id):
		push_warning("InteractionRegistry: Interaction %s already registered" % interaction.id)
		return
		
	_interactions_by_id[interaction.id] = interaction
	_interaction_contexts[interaction.id] = context
	
	# Update context
	context.interaction = interaction
	context.is_active = true
	
	# Track by host if available
	if context.host:
		var host_id = str(context.host.get_instance_id())
		if not _contexts_by_host.has(host_id):
			_contexts_by_host[host_id] = []
		_contexts_by_host[host_id].append(context)
	
	# Track by participants
	for participant in interaction.participants:
		var participant_id = participant.npc_id
		if not _interactions_by_participant.has(participant_id):
			_interactions_by_participant[participant_id] = []
		_interactions_by_participant[participant_id].append(interaction)

func unregister_interaction(interaction_id: String) -> void:
	if not _interactions_by_id.has(interaction_id):
		push_warning("InteractionRegistry: Attempted to unregister non-existent interaction %s" % interaction_id)
		return
	_on_interaction_ended(interaction_id)

func _on_interaction_ended(interaction_id: String) -> void:
	var interaction = _interactions_by_id.get(interaction_id)
	var context = _interaction_contexts.get(interaction_id)
	if not interaction or not context:
		return
		
	_interactions_by_id.erase(interaction_id)
	_interaction_contexts.erase(interaction_id)
	context.is_active = false
	
	# Remove from host tracking
	if context.host:
		var host_id = str(context.host.get_instance_id())
		if _contexts_by_host.has(host_id):
			_contexts_by_host[host_id].erase(context)
			if _contexts_by_host[host_id].is_empty():
				_contexts_by_host.erase(host_id)
	
	# Remove from participant tracking
	for participant in interaction.participants:
		var participant_id = participant.npc_id
		if _interactions_by_participant.has(participant_id):
			_interactions_by_participant[participant_id].erase(interaction)
			if _interactions_by_participant[participant_id].is_empty():
				_interactions_by_participant.erase(participant_id)

func get_contexts_for(host: GamepieceController) -> Array[InteractionContext]:
	var host_id = str(host.get_instance_id())
	var contexts: Array[InteractionContext] = []
	if _contexts_by_host.has(host_id):
		contexts.assign(_contexts_by_host[host_id])
	return contexts

func get_participant_interactions(entity: NpcController, type: String = "") -> Array[Interaction]:
	var all_interactions: Array[Interaction] = []
	if _interactions_by_participant.has(entity.npc_id):
		all_interactions.assign(_interactions_by_participant[entity.npc_id])
	
	if type.is_empty():
		return all_interactions
	
	var filtered: Array[Interaction] = []
	for interaction in all_interactions:
		if interaction.name == type:
			filtered.append(interaction)
	return filtered

func is_participating_in(entity: NpcController, interaction_type: String) -> bool:
	var interactions = _interactions_by_participant.get(entity.npc_id, [])
	for interaction in interactions:
		if interaction.name == interaction_type:
			return true
	return false

func get_interaction_between(a: NpcController, b: NpcController, type: String = "") -> Interaction:
	var a_interactions = _interactions_by_participant.get(a.npc_id, [])
	var b_interactions = _interactions_by_participant.get(b.npc_id, [])
	
	# Find intersection
	for interaction in a_interactions:
		if interaction in b_interactions:
			if type.is_empty() or interaction.name == type:
				return interaction
	
	return null
