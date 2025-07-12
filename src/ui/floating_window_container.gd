extends Control

## Container for floating windows within the UI CanvasLayer.
## This ensures floating windows stay in screen space while the camera moves.
##
## SETUP INSTRUCTIONS:
## 1. In the UI scene (src/ui/ui.tscn), add a Control node as a child of CanvasLayer
## 2. Rename it to "FloatingWindowContainer"
## 3. Attach this script to it
## 4. In the node's Groups tab, add it to the "floating_window_container" group
## 5. Set Mouse Filter to "Ignore" so it doesn't block input

signal window_added(window: Control)
signal window_removed(window: Control)

func _ready() -> void:
	# Make this container fill the screen but not block input
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Register self with a group for easy access
	add_to_group("floating_window_container")

## Add a floating window to this container
func add_floating_window(window: Control) -> void:
	add_child(window)
	window_added.emit(window)

## Remove a floating window from this container
func remove_floating_window(window: Control) -> void:
	if window.get_parent() == self:
		remove_child(window)
		window_removed.emit(window)

## Get all floating windows
func get_floating_windows() -> Array[Control]:
	var windows: Array[Control] = []
	for child in get_children():
		windows.append(child)
	return windows