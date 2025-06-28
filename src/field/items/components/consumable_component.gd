class_name ConsumableComponent extends ItemComponent

const INTERACTION_NAME: = "consume"

func _init():
	PROPERTY_SPECS["consumption_time"] = PropertySpec.new(
		"consumption_time", 
		TypeConverters.PropertyType.FLOAT, 
		1.0, 
		"Time it takes to fully consume the item"
	)
	PROPERTY_SPECS["need_deltas"] = PropertySpec.new(
		"need_deltas", 
		TypeConverters.PropertyType.NEED_DICT, 
		{}, 
		"Dictionary of needs this item satisfies"
	)

var consumption_time: float = 1.0
var need_deltas: Dictionary[Needs.Need, float] = {}

var percent_left: float = 100.0
var current_npc: NpcController = null

var item_controller: ItemController
var need_modifying_component: NeedModifyingComponent
var _interaction: Interaction

# Inner factory class
class ConsumableInteractionFactory extends InteractionFactory:
	var consumable_component: ConsumableComponent

	func get_interaction_name() -> String:
		return "consume"

	func get_interaction_description() -> String:
		var effects_desc = consumable_component.need_modifying_component.get_effects_description()
		var time_left = consumable_component.consumption_time * (consumable_component.percent_left / 100.0)
		return "Consume this item (%.1fs left). Effects per second: %s" % [time_left, effects_desc]

	func create_interaction(context: Dictionary = {}) -> Interaction:
		var interaction = ConsumeInteraction.new(
			get_interaction_name(),
			get_interaction_description(),
			true
		)
		
		# Set which needs this interaction fills/drains and the rates
		for need_enum in consumable_component.need_deltas:
			var delta = consumable_component.need_deltas[need_enum]
			if delta > 0:
				interaction.needs_filled.append(need_enum)
			elif delta < 0:
				interaction.needs_drained.append(need_enum)
			
			# Calculate rate per second
			if consumable_component.consumption_time > 0:
				interaction.need_rates[need_enum] = delta / consumable_component.consumption_time
		
		interaction.consumable_component = consumable_component
		return interaction

func _ready() -> void:
	super._ready()
	item_controller = get_parent() as ItemController
	
	need_modifying_component = NeedModifyingComponent.new()
	add_child(need_modifying_component)
	
	# Calculate need rates for the need modifying component
	for need_enum_key in need_deltas:
		if consumption_time > 0.0:
			need_modifying_component.need_rates[need_enum_key] = need_deltas[need_enum_key] / consumption_time
		else:
			need_modifying_component.need_rates[need_enum_key] = 0.0
			push_warning("ConsumableComponent: consumption_time is <= 0 for item. Need rates will be zero for need '%s'." % Needs.get_display_name(need_enum_key))

func _create_interaction_factories() -> Array[InteractionFactory]:
	var factory = ConsumableInteractionFactory.new()
	factory.consumable_component = self
	return [factory]

func _process(delta_t: float) -> void:
	if current_npc:
		var old_percent = percent_left
		var consumption_rate = 100.0 / consumption_time if consumption_time > 0 else 0
		percent_left = clampf(percent_left - consumption_rate * delta_t, 0, 100.0)
		
		if old_percent != percent_left:
			if _interaction:
				_interaction.description = (get_interaction_factories()[0] as ConsumableInteractionFactory).get_interaction_description()

		if percent_left <= 0.0:
			# When the item is fully consumed, emit the interaction_finished signal
			if _interaction and item_controller.current_interaction == _interaction:
				interaction_finished.emit(INTERACTION_NAME, {})

func _on_consume_start(interaction: Interaction, context: Dictionary) -> void:
	_interaction = interaction
	current_npc = interaction.participants[0]
	var bid = context.get("bid")
	if bid:
		need_modifying_component._handle_modify_start_request(bid)

func _on_consume_end(interaction: Interaction, context: Dictionary) -> void:
	need_modifying_component._finish_interaction()
	current_npc = null
	_interaction = null
	
	if percent_left <= 0.0:
		destroy_item()

func destroy_item() -> void:
	if is_instance_valid(item_controller) and is_instance_valid(item_controller._gamepiece):
		EventBus.dispatch(
			GamepieceEvents.create_destroyed(item_controller._gamepiece)
		)
