@tool
class_name ItemComponentConfig
extends Resource

@export var component_script: Script
@export var properties: Dictionary

func _init():
    component_script = null
    properties = {}

func _validate_properties() -> bool:
    if not component_script:
        push_error("Component script not set")
        return false
    return true

# Called when the resource is loaded
func _validate() -> bool:
    return _validate_properties()
