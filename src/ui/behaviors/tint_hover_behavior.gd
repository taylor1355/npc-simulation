class_name TintHoverBehavior extends BaseUIBehavior

## A UI behavior that applies a tint to sprites when hovering over gamepieces.
## 
## This behavior responds to hover events by modulating the sprite color of the
## hovered gamepiece. Uses SpriteColorManager to coordinate with other color modifications.

# Configuration
var hover_tint: Color = Color(1.2, 1.2, 1.2, 1.0)  # Slight brightening

# Source ID for color manager
const SOURCE_ID = "hover_tint"

func _on_configured() -> void:
	hover_tint = config.get("hover_tint", Color(1.2, 1.2, 1.2, 1.0))

func on_hover_start(gamepiece: Gamepiece, tracker: UIRegistry.UIStateTracker) -> void:
	SpriteColorManager.apply_color(gamepiece, SOURCE_ID, hover_tint)

func on_hover_end(gamepiece: Gamepiece, tracker: UIRegistry.UIStateTracker) -> void:
	SpriteColorManager.remove_color(gamepiece, SOURCE_ID)

