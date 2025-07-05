class_name TypeConverters
extends RefCounted

# Supported property types
enum PropertyType {
	FLOAT,
	INT,
	STRING,
	BOOL,
	NEED_DICT,
	TYPED_FLOAT_DICT,
	VARIANT
}

# Registry of type converters
static var converters: Dictionary[PropertyType, Callable] = {}

# Initialize built-in converters
static func _static_init():
	converters[PropertyType.FLOAT] = _convert_to_float
	converters[PropertyType.INT] = _convert_to_int
	converters[PropertyType.STRING] = _convert_to_string
	converters[PropertyType.BOOL] = _convert_to_bool
	converters[PropertyType.NEED_DICT] = _convert_to_need_dict
	converters[PropertyType.TYPED_FLOAT_DICT] = _convert_to_typed_float_dict
	converters[PropertyType.VARIANT] = func(v): return v  # Pass-through for variant

# Register a custom type converter
static func register_converter(property_type: PropertyType, converter: Callable):
	converters[property_type] = converter

# Convert a value to the specified type
static func convert(value: Variant, property_type: PropertyType, default_value: Variant = null) -> Variant:
	if value == null:
		return default_value
	
	if not converters.has(property_type):
		push_error("TypeConverters: Unknown type '%s'" % property_type)
		return default_value
	
	var result = converters[property_type].call(value)
	if result == null:
		push_warning("TypeConverters: Failed to convert value to type '%s'. Using default." % property_type)
		return default_value
	
	return result

# Use Godot's built-in conversion where possible
static func _convert_to_float(value: Variant) -> float:
	match typeof(value):
		TYPE_FLOAT:
			return value as float
		TYPE_INT:
			return float(value)
		TYPE_STRING:
			var str_value = value as String
			if str_value.is_valid_float():
				return str_value.to_float()
			else:
				push_warning("Invalid float string: %s" % str_value)
				return 0.0
		_:
			push_warning("Cannot convert %s to float" % value)
			return 0.0

static func _convert_to_int(value: Variant) -> int:
	match typeof(value):
		TYPE_INT:
			return value as int
		TYPE_FLOAT:
			return int(value)
		TYPE_STRING:
			var str_value = value as String
			if str_value.is_valid_int():
				return str_value.to_int()
			else:
				push_warning("Invalid int string: %s" % str_value)
				return 0
		_:
			push_warning("Cannot convert %s to int" % value)
			return 0

static func _convert_to_string(value: Variant) -> String:
	return str(value)

static func _convert_to_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value as bool
		TYPE_INT:
			return (value as int) != 0
		TYPE_FLOAT:
			return (value as float) != 0.0
		TYPE_STRING:
			var str_value = (value as String).to_lower()
			return str_value in ["true", "1", "yes", "on"]
		_:
			return bool(value)

# Generic typed dictionary converter
static func convert_to_typed_dict(value: Variant, key_converter: Callable, value_converter: Callable) -> Dictionary:
	if not value is Dictionary:
		push_warning("Cannot convert non-dictionary to typed dict")
		return {}
	
	var result = {}
	for k in value:
		var converted_key = key_converter.call(k)
		var converted_value = value_converter.call(value[k])
		
		if converted_key != null and converted_value != null:
			result[converted_key] = converted_value
		else:
			push_warning("Skipping invalid typed_dict entry: %s = %s" % [k, value[k]])
	
	return result

# Specialized converter for need dictionaries
static func _convert_to_need_dict(value: Variant) -> Dictionary[Needs.Need, float]:
	if not value is Dictionary:
		push_warning("Cannot convert non-dictionary to need_dict")
		return {} as Dictionary[Needs.Need, float]
	
	if value.is_empty():
		return {} as Dictionary[Needs.Need, float]
	
	var first_key = value.keys()[0]
	
	# Already enum-keyed
	if first_key is Needs.Need:
		return value as Dictionary[Needs.Need, float]
	
	# String-keyed, needs conversion
	if first_key is String:
		# Create a properly typed dictionary manually to avoid casting issues
		var typed_dict: Dictionary[String, float] = {}
		for k in value:
			var str_key = _convert_to_string(k)
			var float_val = _convert_to_float(value[k])
			if str_key != null and float_val != null:
				typed_dict[str_key] = float_val
			else:
				push_warning("Skipping invalid need_dict entry: %s = %s" % [k, value[k]])
		return Needs.deserialize_need_dict(typed_dict)
	
	push_warning("Invalid need_dict format")
	return {} as Dictionary[Needs.Need, float]

static func _convert_to_typed_float_dict(value: Variant) -> Dictionary[String, float]:
	if not value is Dictionary:
		push_warning("Cannot convert non-dictionary to typed float dict")
		return {} as Dictionary[String, float]
	
	# Create a properly typed dictionary manually to avoid casting issues
	var typed_dict: Dictionary[String, float] = {}
	for k in value:
		var str_key = _convert_to_string(k)
		var float_val = _convert_to_float(value[k])
		if str_key != null and float_val != null:
			typed_dict[str_key] = float_val
		else:
			push_warning("Skipping invalid typed_float_dict entry: %s = %s" % [k, value[k]])
	
	return typed_dict

# Convert PropertyType enum to string
static func property_type_to_string(property_type: PropertyType) -> String:
	match property_type:
		PropertyType.FLOAT:
			return "float"
		PropertyType.INT:
			return "int"
		PropertyType.STRING:
			return "string"
		PropertyType.BOOL:
			return "bool"
		PropertyType.NEED_DICT:
			return "need_dict"
		PropertyType.TYPED_FLOAT_DICT:
			return "typed_float_dict"
		PropertyType.VARIANT:
			return "variant"
		_:
			return "unknown"
