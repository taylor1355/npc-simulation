class_name Tooltip extends PanelContainer

## Simple tooltip UI that follows the mouse and displays text.
## Managed by ShowTooltipBehavior.

@onready var label: Label = $Label

var _offset: Vector2 = Vector2(10, 10)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	
	# Create label if not in scene
	if not label:
		label = Label.new()
		label.name = "Label"
		add_child(label)
	
	# Basic styling
	add_theme_stylebox_override("panel", _create_tooltip_style())

func show_tooltip(text: String) -> void:
	label.text = text
	visible = true
	_update_position()

func hide_tooltip() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and visible:
		_update_position()

func _update_position() -> void:
	var mouse_pos = get_global_mouse_position()
	global_position = mouse_pos + _offset
	
	# Keep tooltip on screen
	var viewport_size = get_viewport_rect().size
	if global_position.x + size.x > viewport_size.x:
		global_position.x = mouse_pos.x - size.x - _offset.x
	if global_position.y + size.y > viewport_size.y:
		global_position.y = mouse_pos.y - size.y - _offset.y

func _create_tooltip_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style