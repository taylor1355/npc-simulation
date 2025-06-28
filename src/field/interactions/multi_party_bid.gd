class_name MultiPartyBid extends InteractionBid

# Multi-party specific properties
var invited_participants: Array[NpcController] = [] # NPCs invited to join
var accepted_participants: Array[NpcController] = [] # NPCs who accepted
var rejected_participants: Array[NpcController] = [] # NPCs who rejected
var responses: Dictionary = {} # npc_id -> {accepted: bool, reason: String}
var response_timeout: float = 5.0
var timeout_timer: float = 0.0

# The host is the bidder (inherited from InteractionBid)
# All participants includes host + invited_participants

signal all_participants_accepted()
signal participant_rejected(participant: NpcController, reason: String)
signal timed_out()

func _init(_interaction: Interaction, _bid_type: BidType, _host: NpcController, _invited: Array[NpcController] = []):
	# For multi-party interactions, use the host as the "target" since there's no single target
	super._init(_interaction.name, _bid_type, _host, _host)
	interaction = _interaction
	invited_participants = _invited

func get_all_participants() -> Array[NpcController]:
	var all = [bidder] # Host is always a participant
	all.append_array(invited_participants)
	return all

func add_participant_response(participant: NpcController, bid_accepted: bool, reason: String = "") -> void:
	if participant == bidder:
		push_error("Host cannot respond to their own bid")
		return
		
	if participant not in invited_participants:
		push_error("NPC not invited to this interaction")
		return
	
	responses[participant.npc_id] = {
		"accepted": bid_accepted,
		"reason": reason
	}
	
	if bid_accepted:
		accepted_participants.append(participant)
	else:
		rejected_participants.append(participant)
		participant_rejected.emit(participant, reason)
		# If anyone rejects, the whole bid is rejected
		reject("Participant %s rejected: %s" % [participant.npc_id, reason])
		return
	
	# Check if all have responded
	if accepted_participants.size() == invited_participants.size():
		# Everyone accepted!
		all_participants_accepted.emit()
		accept()

func has_participant_responded(participant: NpcController) -> bool:
	return participant.npc_id in responses

func get_pending_participants() -> Array[NpcController]:
	var pending: Array[NpcController] = []
	for participant in invited_participants:
		if not has_participant_responded(participant):
			pending.append(participant)
	return pending

func update_timeout(delta: float) -> void:
	if status != BidStatus.PENDING:
		return
		
	timeout_timer += delta
	if timeout_timer >= response_timeout:
		timed_out.emit()
		reject("Timed out waiting for responses")

# Override accept to ensure all participants are ready
func accept():
	if accepted_participants.size() != invited_participants.size():
		push_error("Cannot accept multi-party bid without all participants")
		return
	
	super.accept()
	
	# Connect each participant (including host) to the interaction's transition signal
	# This allows them to transition to InteractingState when added to the interaction
	var all_participants = [bidder] + accepted_participants
	for participant in all_participants:
		interaction.participant_should_transition.connect(
			participant.state_machine.current_state.on_interaction_transition_requested,
			Node.CONNECT_ONE_SHOT
		)
	
	# Add all participants to the interaction (including host/bidder)
	# First add the bidder (host) who initiated the interaction
	if interaction.can_add_participant(bidder):
		interaction.add_participant(bidder)
	
	# Then add all accepting participants
	for participant in accepted_participants:
		if interaction.can_add_participant(participant):
			interaction.add_participant(participant)

func get_status_text() -> String:
	return "Responses: %d/%d accepted" % [accepted_participants.size(), invited_participants.size()]