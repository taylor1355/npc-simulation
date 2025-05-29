class_name ConsumableComponent extends ItemComponent

const INTERACTION_NAME: = "consume"

# Properties that will be set by ItemController
@export var consumption_time: float = 1.0
@export var need_deltas_config: Dictionary = {}

# Internally used, enum-keyed dictionary, processed in _ready.
var need_deltas: Dictionary[Needs.Need, float] = {}

var percent_left: float = 100.0
var current_npc: NpcController = null

var item_controller: ItemController
var need_modifying: NeedModifyingComponent


func _ready() -> void:
	super._ready()

	item_controller = get_parent() as ItemController
	
	if not need_deltas_config.is_empty():
		var first_key = need_deltas_config.keys()[0]
		if first_key is String:
			# Convert untyped Dictionary to typed Dictionary[String, float]
			var typed_dict: Dictionary[String, float] = {}
			for key in need_deltas_config:
				if key is String and (need_deltas_config[key] is float or need_deltas_config[key] is int):
					typed_dict[key] = float(need_deltas_config[key])
				else:
					push_warning("Invalid need_deltas_config entry: %s = %s" % [key, need_deltas_config[key]])
			need_deltas = Needs.deserialize_need_dict(typed_dict)
		elif first_key is Needs.Need: # Already enum-keyed
			need_deltas = need_deltas_config as Dictionary[Needs.Need, float]
	
	need_modifying = NeedModifyingComponent.new()
	add_child(need_modifying)
	
	for need_enum_key in need_deltas:
		if consumption_time > 0.0:
			need_modifying.need_rates[need_enum_key] = need_deltas[need_enum_key] / consumption_time
		else:
			need_modifying.need_rates[need_enum_key] = 0.0
			push_warning("ConsumableComponent: consumption_time is <= 0 for item. Need rates will be zero for need '%s'." % Needs.get_display_name(need_enum_key))
				
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
	
	# Rotate NPC to face the item being consumed
	var direction_vec = Vector2(item_controller._gamepiece.cell - current_npc._gamepiece.cell)
	current_npc._gamepiece.direction = direction_vec.normalized()
	
	need_modifying._handle_modify_start_request(request)


func _handle_consume_cancel_request(request: InteractionRequest) -> void:
	if current_npc and current_npc == request.npc_controller:
		request.accept()
		_finish_interaction()
	else:
		request.reject("Not consuming")
