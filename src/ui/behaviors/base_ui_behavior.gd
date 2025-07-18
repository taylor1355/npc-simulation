class_name BaseUIBehavior extends Resource

## Base class for all UI behaviors.
## Behaviors encapsulate UI responses to game events (hover, click, focus).

# Configuration dictionary passed during initialization
var config: Dictionary = {}

# Called when behavior is activated
func on_hover_start(gamepiece: Gamepiece) -> void:
	pass

func on_hover_end(gamepiece: Gamepiece) -> void:
	pass

func on_click(gamepiece: Gamepiece) -> void:
	pass

func on_focus(gamepiece: Gamepiece) -> void:
	pass

func on_unfocus(gamepiece: Gamepiece) -> void:
	pass

# Interaction lifecycle methods
func on_interaction_started(interaction_id: String) -> void:
	pass

func on_interaction_ended(interaction_id: String) -> void:
	pass

# Initialize with configuration
func configure(cfg: Dictionary) -> void:
	config = cfg
	_on_configured()

# Override this to handle configuration
func _on_configured() -> void:
	pass

# Helper to get controller from gamepiece
func _get_controller(gamepiece: Gamepiece) -> GamepieceController:
	return gamepiece.get_controller() if gamepiece.has_method("get_controller") else null