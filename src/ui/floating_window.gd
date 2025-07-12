class_name FloatingWindow extends PanelContainer

## A draggable, resizable window that floats above the game.
## Used for conversations, inventories, and other UI that shouldn't be in tabs.

signal close_requested()

@onready var title_bar: Panel = $VBox/TitleBar
@onready var title_label: Label = $VBox/TitleBar/HBox/TitleLabel
@onready var close_button: Button = $VBox/TitleBar/HBox/CloseButton
@onready var content_container: MarginContainer = $VBox/ContentContainer

var _is_dragging: bool = false
var _drag_offset: Vector2
var _is_resizing: bool = false
var _resize_start_size: Vector2
var _resize_start_pos: Vector2

var min_size: Vector2 = Vector2(200, 150)
var _pending_title: String = ""

func _ready() -> void:
	# Setup close button
	close_button.pressed.connect(_on_close_pressed)
	
	# Setup dragging
	title_bar.gui_input.connect(_on_title_bar_input)
	
	# Make sure we're on top
	z_index = 10
	
	# Default styling
	add_theme_stylebox_override("panel", _create_window_style())
	
	# Apply pending title if any
	if _pending_title:
		title_label.text = _pending_title
		_pending_title = ""
	
	# Apply pending content if any
	if _pending_content:
		set_content(_pending_content)
		_pending_content = null
	
func set_window_title(title: String) -> void:
	if title_label:
		title_label.text = title
	else:
		_pending_title = title

var _pending_content: Control = null

func set_content(content: Control) -> void:
	if content_container:
		# Clear existing content
		for child in content_container.get_children():
			child.queue_free()
		
		# Add new content
		if content:
			content_container.add_child(content)
	else:
		_pending_content = content

func _on_title_bar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				_drag_offset = event.position
			else:
				_is_dragging = false
	
	elif event is InputEventMouseMotion and _is_dragging:
		var new_position = global_position + event.position - _drag_offset
		# Constrain window position to prevent title bar from going off-screen
		var viewport_size = get_viewport().get_visible_rect().size
		var title_bar_height = title_bar.size.y if title_bar else 30.0  # Fallback height
		
		# Ensure title bar stays on screen
		new_position.x = clamp(new_position.x, -size.x + 100, viewport_size.x - 100)  # Allow some overlap but keep grabbable
		new_position.y = clamp(new_position.y, 0, viewport_size.y - title_bar_height)  # Keep title bar visible
		
		global_position = new_position

func _on_close_pressed() -> void:
	close_requested.emit()
	queue_free()

func _create_window_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
	style.border_color = Color(0.3, 0.3, 0.3, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func configure(config: Dictionary) -> void:
	if config.has("start_position"):
		position = config.start_position
	if config.has("start_size"):
		size = config.start_size
	if config.has("resizable"):
		# TODO: Add resize handles if resizable
		pass
	if config.has("show_close_button"):
		close_button.visible = config.show_close_button
