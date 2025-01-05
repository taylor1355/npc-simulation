class_name NeedModifyingComponent extends ItemComponent

const INTERACTION_NAME: = "modify_needs"

# Dictionary mapping need_id to rate of fulfillment (units per second)
@export var need_rates: Dictionary = {}
# Threshold at which accumulated changes are applied
@export var update_threshold: float = 1.0

var current_npc: NpcController = null
var accumulated_deltas: Dictionary = {}

var item_controller: ItemController

func _ready() -> void:
	super._ready()

	item_controller = get_parent() as ItemController

	var interaction = Interaction.new(INTERACTION_NAME, "Modify needs.")
	interactions[interaction.name] = interaction
	interaction.start_request.connect(_handle_modify_start_request)
	interaction.cancel_request.connect(_handle_modify_cancel_request)


func _process(delta_t: float) -> void:
	if current_npc:
		for need_id in need_rates.keys():
			if not accumulated_deltas.has(need_id):
				accumulated_deltas[need_id] = 0.0
			accumulated_deltas[need_id] += need_rates[need_id] * delta_t
			
			if abs(accumulated_deltas[need_id]) >= update_threshold:
				current_npc.update_need(need_id, accumulated_deltas[need_id])
				accumulated_deltas[need_id] = 0.0


func _finish_interaction() -> void:
	current_npc = null
	accumulated_deltas.clear()
	interaction_finished.emit(INTERACTION_NAME, {})


func _handle_modify_start_request(request: InteractionRequest) -> void:
	request.accept()
	current_npc = request.npc_controller
	accumulated_deltas.clear()


func _handle_modify_cancel_request(request: InteractionRequest) -> void:
	if current_npc and current_npc == request.npc_controller:
		request.accept()
		_finish_interaction()
	else:
		request.reject("Not modifying needs")
