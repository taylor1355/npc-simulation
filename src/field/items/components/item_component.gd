class_name ItemComponent extends GamepieceComponent

var interactions: Dictionary = {}

signal interaction_finished(interaction_name, payload)

func _setup() -> void:
	pass
