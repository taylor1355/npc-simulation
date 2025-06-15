class_name GamepieceComponent extends Node2D

var controller: GamepieceController

# Returns a human-readable name for the component type
func get_component_name() -> String:
	var script_path = get_script().resource_path
	var file_name = script_path.get_file().get_basename()
	# Convert snake_case to readable format
	var words = file_name.split("_")
	var readable_name = ""
	for word in words:
		if word == "component":
			continue
		readable_name += word.capitalize() + " "
	return readable_name.strip_edges()

func _ready() -> void:
	if not Engine.is_editor_hint():
		# Find the first GamepieceController ancestor
		var parent = get_parent()
		while parent and not parent is GamepieceController:
			parent = parent.get_parent()
		
		controller = parent as GamepieceController
		assert(controller, "GamepieceComponent must have a GamepieceController as ancestor")
		_setup()

# Virtual method for additional setup
func _setup() -> void:
	pass
