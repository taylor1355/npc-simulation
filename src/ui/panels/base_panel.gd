class_name BasePanel extends Panel

## Base class for all UI panels.
## Provides common lifecycle management that all panels share.

# Core lifecycle that all panels share
func activate() -> void:
	set_process(true)
	_on_activated()

func deactivate() -> void:
	set_process(false)
	_on_deactivated()

# Override in subclasses
func _on_activated() -> void:
	pass

func _on_deactivated() -> void:
	pass

func _update_display() -> void:
	pass