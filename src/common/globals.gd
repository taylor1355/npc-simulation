extends Node

var focused_gamepiece: Gamepiece = null

func _ready() -> void:
	FieldEvents.focused_gamepiece_changed.connect(_on_focused_gamepiece_changed)

func _on_focused_gamepiece_changed(gamepiece: Gamepiece) -> void:
	focused_gamepiece = gamepiece