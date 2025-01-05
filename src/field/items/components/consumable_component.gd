class_name ConsumableComponent extends ItemComponent

const INTERACTION_NAME: = "consume"

# Dictionary mapping need_id to need delta from consuming the item
@export var need_deltas: Dictionary = {}
# Time it takes to fully consume the item
@export var consumption_time: float = 1.0

var percent_left: float = 100.0
var current_npc: NpcController = null

var item_controller: ItemController
var need_modifying: NeedModifyingComponent

func _ready() -> void:
	super._ready()

	item_controller = get_parent() as ItemController
	
	# Create the need modifying component
	need_modifying = NeedModifyingComponent.new()
	add_child(need_modifying)
	
	# Configure rates based on total deltas and consumption time
	for need_id in need_deltas:
		need_modifying.need_rates[need_id] = need_deltas[need_id] / consumption_time

	var interaction = Interaction.new(INTERACTION_NAME, "Consume this item.")
	interactions[interaction.name] = interaction
	interaction.start_request.connect(_handle_consume_start_request)
	interaction.cancel_request.connect(_handle_consume_cancel_request)


func _process(delta_t: float) -> void:
	if current_npc:
		# TODO: give some visual indicator of how much of the consumable is left
		percent_left = clampf(percent_left - 100.0 * delta_t / consumption_time, 0, 100.0)
		if percent_left <= 0.0:
			_finish_interaction()


func _finish_interaction() -> void:
	if percent_left <= 0.0:
		FieldEvents.dispatch(
			GamepieceEvents.create_destroyed(item_controller._gamepiece)
		)
	need_modifying._finish_interaction()
	interaction_finished.emit(INTERACTION_NAME, {})


func _handle_consume_start_request(request: InteractionRequest) -> void:
	if current_npc:
		request.reject("Already consuming")
		return

	request.accept()
	current_npc = request.npc_controller
	
	# Face NPC towards the consumable item
	var direction_vec = Vector2(item_controller._gamepiece.cell - current_npc._gamepiece.cell)
	current_npc._gamepiece.direction = direction_vec.normalized()
	
	need_modifying._handle_modify_start_request(request)


func _handle_consume_cancel_request(request: InteractionRequest) -> void:
	if current_npc and current_npc == request.npc_controller:
		request.accept()
		_finish_interaction()
	else:
		request.reject("Not consuming")
