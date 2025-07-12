class_name NpcNameplate
extends Node2D

@onready var name_label: Label = $NameLabel
@onready var emoji_label: Label = $EmojiLabel

var name_area: Area2D
var emoji_area: Area2D

var _controller: NpcController
var _emoji_hover_tween: Tween
var _is_emoji_hovered: bool = false
var _emoji_ui_element_id: String = ""
var _name_ui_element_id: String = ""

func _ready() -> void:
	# Get the controller via the gamepiece owner
	if owner is Gamepiece:
		var gamepiece = owner as Gamepiece
		_controller = gamepiece.get_controller() as NpcController
		if not _controller:
			push_error("NpcNameplate requires an NpcController")
			return
	else:
		push_error("NpcNameplate must be part of a Gamepiece scene")
		return
	
	# Wait for controller to be ready if needed
	if not _controller.is_node_ready():
		await _controller.ready
	
	# Set Control nodes to ignore mouse so Area2D can detect it
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emoji_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Also ignore mouse on the background if it exists
	var background = get_node_or_null("Background")
	if background and background is Control:
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Connect to display name updates
	_connect_to_controller()
	
	# Setup UI elements
	_setup_ui_elements()
	
	# Listen for state changes via EventBus
	EventBus.event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.NPC_STATE_CHANGED):
				var state_event = event as NpcEvents.StateChangedEvent
				# Only update if this event is for our NPC
				if state_event.npc == owner:
					_update_state_emoji_from_state(state_event.new_state)
	)

func _connect_to_controller() -> void:
	# Wait a frame for display name to be set
	await get_tree().process_frame
	
	# Set initial name
	var display_name = _controller.get_display_name()
	name_label.text = display_name
	
	# Set initial emoji if state machine is ready
	if _controller.state_machine and _controller.state_machine.current_state:
		_update_state_emoji_from_state(_controller.state_machine.current_state)

func _update_state_emoji_from_state(state: BaseControllerState) -> void:
	if state:
		emoji_label.text = state.get_state_emoji()

func _setup_ui_elements() -> void:
	if not owner is Gamepiece:
		return
		
	var gamepiece = owner as Gamepiece
	
	# Create and setup name click area
	name_area = _create_click_area(name_label, "Name")
	_name_ui_element_id = UIRegistry.register_ui_element(Globals.UIElementType.NAMEPLATE_LABEL, gamepiece)
	_connect_click_area(name_area, _name_ui_element_id, _on_name_hover)
	
	# Create and setup emoji click area  
	emoji_area = _create_click_area(emoji_label, "Emoji")
	_emoji_ui_element_id = UIRegistry.register_ui_element(Globals.UIElementType.NAMEPLATE_EMOJI, gamepiece)
	_connect_click_area(emoji_area, _emoji_ui_element_id, _on_emoji_hover)

func _create_click_area(target: Control, suffix: String) -> Area2D:
	var area = Area2D.new()
	area.name = suffix + "Area"
	# Follow the established pattern: clickable layer (3), no collision detection
	area.collision_layer = 4  # 0x4 = layer 3 "clickable"
	area.collision_mask = 0   # Don't detect collisions
	area.monitoring = false   # Not monitoring other areas
	area.input_pickable = true  # Enable mouse input detection
	add_child(area)
	
	var collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	area.add_child(collision)
	
	# Update collision size when label changes
	var update_collision = func():
		var shape = collision.shape as RectangleShape2D
		shape.size = target.size
		# Area2D is child of nameplate, so we need relative position to the label
		area.position = target.position
		collision.position = target.size / 2
	
	target.resized.connect(update_collision)
	update_collision.call()
	
	return area

func _connect_click_area(area: Area2D, ui_element_id: String, hover_callback: Callable) -> void:
	# Click handling
	area.input_event.connect(func(_viewport: Node, event: InputEvent, _shape_idx: int):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if owner is Gamepiece:
				var click_event = GamepieceEvents.create_clicked(owner as Gamepiece, ui_element_id)
				EventBus.dispatch(click_event)
	)
	
	# Hover handling
	area.mouse_entered.connect(func(): hover_callback.call(true))
	area.mouse_exited.connect(func(): hover_callback.call(false))


func _on_name_hover(is_hovering: bool) -> void:
	# Emit through UIRegistry
	if owner is Gamepiece:
		var gamepiece = owner as Gamepiece
		if is_hovering:
			var hover_event = GamepieceEvents.create_hover_started(gamepiece, _name_ui_element_id)
			EventBus.dispatch(hover_event)
		else:
			var hover_event = GamepieceEvents.create_hover_ended(gamepiece, _name_ui_element_id)
			EventBus.dispatch(hover_event)

func _on_emoji_hover(is_hovering: bool) -> void:
	_is_emoji_hovered = is_hovering
	
	# Emit through UIRegistry
	if owner is Gamepiece:
		var gamepiece = owner as Gamepiece
		if is_hovering:
			var hover_event = GamepieceEvents.create_hover_started(gamepiece, _emoji_ui_element_id)
			EventBus.dispatch(hover_event)
		else:
			var hover_event = GamepieceEvents.create_hover_ended(gamepiece, _emoji_ui_element_id)
			EventBus.dispatch(hover_event)
	
	# Visual feedback
	if _emoji_hover_tween:
		_emoji_hover_tween.kill()
	
	_emoji_hover_tween = create_tween()
	if is_hovering:
		_emoji_hover_tween.tween_property(emoji_label, "scale", Vector2(1.1, 1.1), 0.1)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		_emoji_hover_tween.tween_property(emoji_label, "scale", Vector2.ONE, 0.1)
		# Only reset cursor if we're not hovering anything
		if not _is_emoji_hovered:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _exit_tree() -> void:
	# Unregister UI elements
	if _emoji_ui_element_id:
		UIRegistry.unregister_ui_element(_emoji_ui_element_id)
	if _name_ui_element_id:
		UIRegistry.unregister_ui_element(_name_ui_element_id)
