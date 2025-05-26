class_name ConsumableComponent extends ItemComponent

const INTERACTION_NAME: = "consume"

# Dictionary mapping need enum to total need delta from consuming the item
@export var need_deltas: Dictionary[Needs.Need, float] = {}
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
	for need in need_deltas:
		need_modifying.need_rates[need] = need_deltas[need] / consumption_time

	var description = "Consume this item (%.1fs left). Effects per second: %s" % [
		consumption_time,
		need_modifying.get_effects_description()
	]
	
	var interaction = Interaction.new(
		INTERACTION_NAME,
		description,
		need_modifying.get_filled_needs(),
		need_modifying.get_drained_needs()
	)
	interactions[interaction.name] = interaction
	interaction.start_request.connect(_handle_consume_start_request)
	interaction.cancel_request.connect(_handle_consume_cancel_request)


func _update_interaction_description() -> void:
	var time_left = consumption_time * (percent_left / 100.0)
	interactions[INTERACTION_NAME].description = "Consume this item (%.1fs left). Effects per second: %s" % [
		time_left,
		need_modifying.get_effects_description()
	]

func _process(delta_t: float) -> void:
	if current_npc:
		var old_percent = percent_left
		percent_left = clampf(percent_left - 100.0 * delta_t / consumption_time, 0, 100.0)
		if old_percent != percent_left:
			_update_interaction_description()
		if percent_left <= 0.0:
			_finish_interaction()


func _finish_interaction() -> void:
	need_modifying._finish_interaction()
	interaction_finished.emit(INTERACTION_NAME, {})
	current_npc = null
	
	if percent_left <= 0.0:
		FieldEvents.dispatch(
			GamepieceEvents.create_destroyed(item_controller._gamepiece)
		)


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
