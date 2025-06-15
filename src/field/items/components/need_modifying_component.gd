class_name NeedModifyingComponent extends ItemComponent

const INTERACTION_NAME: = "modify_needs"

func _init():
	PROPERTY_SPECS["need_rates"] = PropertySpec.new(
		"need_rates", 
		TypeConverters.PropertyType.NEED_DICT, 
		{}, 
		"Mapping from needs to rates of change (units per second)"
	)
	PROPERTY_SPECS["update_threshold"] = PropertySpec.new(
		"update_threshold", 
		TypeConverters.PropertyType.FLOAT, 
		1.0, 
		"Threshold at which accumulated changes are applied"
	)

# Mapping from needs to rates of change (units per second)
var need_rates: Dictionary[Needs.Need, float] = {}
# Threshold at which accumulated changes are applied
var update_threshold: float = 1.0

var current_npc: NpcController = null
var accumulated_deltas: Dictionary[Needs.Need, float] = {}

var item_controller: ItemController

func get_effects_description() -> String:
	var effects = []
	for need in need_rates:
		var rate = need_rates[need]
		if rate != 0:
			var need_name = Needs.get_display_name(need)
			effects.append("%s: %+.1f/s" % [need_name, rate])
	return ", ".join(effects)

func _filter_needs(condition: Callable) -> Array[Needs.Need]:
	var filtered_needs: Array[Needs.Need] = []
	for need in need_rates.keys():
		if condition.call(need_rates[need]):
			filtered_needs.append(need)
	return filtered_needs

func get_filled_needs() -> Array[Needs.Need]:
	return _filter_needs(func(rate): return rate > 0)

func get_drained_needs() -> Array[Needs.Need]:
	return _filter_needs(func(rate): return rate < 0)

func _ready() -> void:
	super._ready()

	item_controller = get_parent() as ItemController

	# NeedModifyingComponent no longer creates its own interaction
	# It is used by other components (like ConsumableComponent and SittableComponent)
	# that handle the interaction lifecycle


func _process(delta_t: float) -> void:
	if current_npc:
		for need in need_rates.keys():
			if not accumulated_deltas.has(need):
				accumulated_deltas[need] = 0.0
			accumulated_deltas[need] += need_rates[need] * delta_t
			
			if abs(accumulated_deltas[need]) >= update_threshold:
				current_npc.needs_manager.update_need(need, accumulated_deltas[need])
				accumulated_deltas[need] = 0.0


func _finish_interaction() -> void:
	current_npc = null
	accumulated_deltas.clear()
	interaction_finished.emit(INTERACTION_NAME, {})


func _handle_modify_start_request(request: InteractionBid) -> void:
	current_npc = request.bidder
	accumulated_deltas.clear()


func _handle_modify_cancel_request(request: InteractionBid) -> void:
	if current_npc and current_npc == request.bidder:
		_finish_interaction()
