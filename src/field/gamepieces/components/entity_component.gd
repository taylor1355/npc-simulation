class_name EntityComponent extends GamepieceComponent

var interactions: Dictionary[String, Interaction] = {}

signal interaction_finished(interaction_name: String, payload: Dictionary[String, Variant])

# Override this in child classes to define properties and their types
# Example: { "consumption_time": PropertySpec.new("consumption_time", TypeConverters.PropertyType.FLOAT, 1.0) }
var PROPERTY_SPECS: Dictionary[String, PropertySpec] = {}

# Raw values received from controller before type conversion
var _pending_property_values: Dictionary[String, Variant] = {}

# Processed property values after type conversion
var _processed_properties: Dictionary[String, Variant] = {}

# Cached interaction factories
var _cached_interaction_factories: Array[InteractionFactory] = []
var _factories_initialized: bool = false

# Get the appropriate controller based on the parent type
func get_entity_controller() -> GamepieceController:
	return controller

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		_auto_process_properties()
		_component_ready()

# Override this instead of _ready() in child components
func _component_ready() -> void:
	pass

# Called by controller to configure all properties at once
func configure_properties(properties: Dictionary) -> void:
	for prop_name in properties:
		if not PROPERTY_SPECS.has(prop_name):
			push_warning("Component '%s': Unknown property '%s'. Available properties: %s" % [
				get_script().get_global_name(), 
				prop_name, 
				PROPERTY_SPECS.keys()
			])
			continue
		
		var spec := PROPERTY_SPECS[prop_name]
		var raw_value = properties[prop_name]
		
		# Convert using the property spec
		var converted_value = spec.convert_value(raw_value)
		
		# Set the property directly on the component
		set(prop_name, converted_value)

# Called by controller via set() to store raw property values
func _set(property_name: StringName, value: Variant) -> bool:
	var prop_name_str = str(property_name)
	if PROPERTY_SPECS.has(prop_name_str):
		_pending_property_values[prop_name_str] = value
		return true
	return false

# Called when accessing properties - return from processed properties
func _get(property_name: StringName) -> Variant:
	var prop_name_str = str(property_name)
	if _processed_properties.has(prop_name_str):
		return _processed_properties[prop_name_str]
	return null

# Process all configured properties automatically using their specifications
func _auto_process_properties() -> void:
	for prop_name in PROPERTY_SPECS:
		var spec := PROPERTY_SPECS[prop_name]
		var raw_value = _pending_property_values.get(prop_name, spec.default_value)
		_processed_properties[prop_name] = spec.convert_value(raw_value)

# Helper method to register a property specification
func _register_property(prop_name: String, property_type: TypeConverters.PropertyType, default_value: Variant = null, description: String = "") -> PropertySpec:
	var spec = PropertySpec.new(prop_name, property_type, default_value, description)
	PROPERTY_SPECS[prop_name] = spec
	return spec

# Helper method for manual property processing if needed
func _process_config_property(property_name: String, property_type: TypeConverters.PropertyType, default_value: Variant = null) -> Variant:
	var raw_value = _pending_property_values.get(property_name, null)
	return TypeConverters.convert(raw_value, property_type, default_value)

func _setup() -> void:
	pass

# Public method that handles caching automatically
func get_interaction_factories() -> Array[InteractionFactory]:
	if not _factories_initialized:
		_cached_interaction_factories = _create_interaction_factories()
		_factories_initialized = true
	return _cached_interaction_factories

# Override this in child components to create interaction factories
# This will only be called once per component instance
func _create_interaction_factories() -> Array[InteractionFactory]:
	return []