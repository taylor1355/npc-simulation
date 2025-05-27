class_name ItemComponent extends GamepieceComponent

var interactions: Dictionary[String, Interaction] = {}

signal interaction_finished(interaction_name: String, payload: Dictionary[String, Variant])

func _setup() -> void:
	pass
