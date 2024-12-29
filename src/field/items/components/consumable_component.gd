class_name ConsumableComponent extends ItemComponent

const INTERACTION_NAME: = "consume"

@export var need_deltas: Dictionary = {}
@export var consumption_time: float = 1.0

var percent_left: float = 100.0
var current_npc: NpcController = null

var item_controller: ItemController

func _ready() -> void:
	super._ready()

	item_controller = get_parent() as ItemController

	var interaction = Interaction.new(INTERACTION_NAME, "Consume this item.")
	interactions[interaction.name] = interaction
	interaction.start_request.connect(_handle_consume_start_request)
	interaction.cancel_request.connect(_handle_consume_cancel_request)


# TODO: use a timer instead. No need to update every frame
func _process(delta_t: float) -> void:
	if current_npc:
		for need_id in need_deltas.keys():
			current_npc.update_need(need_id, need_deltas[need_id] * delta_t)
	
		# TODO: give some visual indicator of how much of the consumable is left
		percent_left = clampf(percent_left - 100.0 * delta_t / consumption_time, 0, 100.0)
		if percent_left <= 0.0:
			_finish_interaction()


func _finish_interaction() -> void:
	# current_npc = null
	if percent_left <= 0.0:
		FieldEvents.gamepiece_destroyed.emit(item_controller._gamepiece)
	interaction_finished.emit(INTERACTION_NAME, {})


func _handle_consume_start_request(request: InteractionRequest) -> void:
	if current_npc:
		request.reject("Already consuming")
		return

	# TODO: reject if npc is not adjacent to item

	request.accept()
	current_npc = request.npc_controller


func _handle_consume_cancel_request(request: InteractionRequest) -> void:
	if current_npc and current_npc == request.npc_controller:
		request.accept()
		_finish_interaction()
	else:
		request.reject("Not consuming")
