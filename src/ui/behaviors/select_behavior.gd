class_name SelectBehavior extends BaseUIBehavior

## Behavior that handles entity selection by changing focus.

func on_click(gamepiece: Gamepiece) -> void:
	print("[SelectBehavior] Dispatching focus event for: ", gamepiece.display_name)
	var event = GamepieceEvents.create_focused(gamepiece)
	EventBus.dispatch(event)
