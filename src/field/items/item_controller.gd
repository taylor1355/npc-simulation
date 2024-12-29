class_name ItemController extends GamepieceController

const GROUP_NAME: = "_NPC_CONTROLLER_GROUP"

var components: Array = []
var interactions: Dictionary = {}
var current_interaction: Interaction = null
var interacting_npc: NpcController = null
var interaction_time: float = 0.0

signal interaction_finished(interaction_name: String, npc: NpcController, payload: Dictionary)

func _ready() -> void:
	super._ready()

	if not Engine.is_editor_hint():
		add_to_group(GROUP_NAME)

		for child in get_children():
			if child is ItemComponent:
				components.append(child)
				child.interaction_finished.connect(_on_interaction_finished)

				var expected_num_interactions = len(interactions) + len(child.interactions)
				interactions.merge(child.interactions)
				if expected_num_interactions != len(interactions):
					print("Duplicate interactions found in ItemController: ", child)


func _process(delta):
	if current_interaction:
		interaction_time += delta


func request_interaction(request: InteractionRequest):
	request = request as InteractionRequest
	if current_interaction == null:
		request.item_controller = self

		var interaction = interactions.get(request.interaction_name, null)
		if not interaction:
			request.reject("Interaction not found")
			return

		if request.request_type == "start":
			interaction.start_request.emit(request)
		elif request.request_type == "cancel":
			interaction.cancel_request.emit(request)
		else:
			request.reject("Invalid request type")
			return

		# may need to defer the status check, so that the request handler can have time to finish
		if request.status == "accepted":
			current_interaction = interaction
			interacting_npc = request.npc_controller
			interaction_time = 0.0
	else:
		request.reject("An interaction is already in progress")
		

func _on_interaction_finished(interaction_name, payload):
	interaction_finished.emit(interaction_name, interacting_npc, payload)
	current_interaction = null
	interacting_npc = null
	interaction_time = 0.0
