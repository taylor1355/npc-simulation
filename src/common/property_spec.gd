class_name PropertySpec extends RefCounted

# Property specification class for type-safe property configuration
# Used by components, interactions, and other systems that need configurable properties

var name: String
var property_type: TypeConverters.PropertyType
var default_value: Variant
var description: String

func _init(prop_name: String, prop_type: TypeConverters.PropertyType, default_val: Variant = null, desc: String = ""):
	name = prop_name
	property_type = prop_type
	default_value = default_val
	description = desc

# Convert a raw value using this property's specification
func convert_value(raw_value: Variant) -> Variant:
	return TypeConverters.convert(raw_value, property_type, default_value)

# Validate that a raw value can be converted
func can_convert(raw_value: Variant) -> bool:
	var converted = TypeConverters.convert(raw_value, property_type, null)
	return converted != null

# Convert to dictionary for serialization
func to_dict() -> Dictionary:
	return {
		"type": TypeConverters.property_type_to_string(property_type),
		"default": default_value,
		"description": description
	}

# Helper method to create property specs for common types
static func float_property(name: String, default_val: float = 0.0, description: String = "") -> PropertySpec:
	return PropertySpec.new(name, TypeConverters.PropertyType.FLOAT, default_val, description)

static func int_property(name: String, default_val: int = 0, description: String = "") -> PropertySpec:
	return PropertySpec.new(name, TypeConverters.PropertyType.INT, default_val, description)

static func string_property(name: String, default_val: String = "", description: String = "") -> PropertySpec:
	return PropertySpec.new(name, TypeConverters.PropertyType.STRING, default_val, description)

static func bool_property(name: String, default_val: bool = false, description: String = "") -> PropertySpec:
	return PropertySpec.new(name, TypeConverters.PropertyType.BOOL, default_val, description)

# Validate a dictionary of raw values against a dictionary of PropertySpecs
static func validate_properties(raw_values: Dictionary, property_specs: Dictionary[String, PropertySpec]) -> Dictionary:
	var validated = {}
	var errors = []
	
	for prop_name in property_specs:
		var spec = property_specs[prop_name]
		var raw_value = raw_values.get(prop_name, spec.default_value)
		
		if spec.can_convert(raw_value):
			validated[prop_name] = spec.convert_value(raw_value)
		else:
			errors.append("Invalid value for property '%s': %s" % [prop_name, raw_value])
	
	if not errors.is_empty():
		push_error("Property validation failed: " + ", ".join(errors))
		return {}
	
	return validated