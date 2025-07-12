extends Node

## Central registry for UI behaviors and state tracking.
## 
## This singleton manages:
## - UI behavior registration and triggering (hover, click, focus)
## - UI state tracking (what's hovered, focused, which windows are open)
## - Mapping between game events and UI behaviors
##
## Note: UI creation and display is handled by UIElementProvider, not this class.

## Simple info about a UI element
class UIElementInfo:
	var id: String
	var element_type: Globals.UIElementType
	var owner_gamepiece: Gamepiece
	
	func _init(p_id: String, p_type: Globals.UIElementType, p_owner: Gamepiece):
		id = p_id
		element_type = p_type
		owner_gamepiece = p_owner

# Behavior registrations - maps trigger conditions to behaviors
var _behavior_registry: BehaviorRegistry

# UI state tracking - what's currently happening in the UI
var _ui_state_tracker: UIStateTracker


# Registry of UI elements by ID
var _ui_elements: Dictionary = {}  # id -> UIElementInfo

# Active floating windows indexed by their UI element ID
var _floating_windows: Dictionary = {}  # ui_element_id -> FloatingWindow

# Initialization
func _ready() -> void:
	_behavior_registry = BehaviorRegistry.new()
	_ui_state_tracker = UIStateTracker.new()
	
	# Register all behaviors from configuration
	_register_configured_behaviors()
	
	
	# Listen for game events
	EventBus.event_dispatched.connect(_on_event)

func _on_event(event: Event) -> void:
	match event.event_type:
		Event.Type.GAMEPIECE_CLICKED:
			_handle_gamepiece_event(event, BehaviorRegistry.EventType.CLICK)
		Event.Type.GAMEPIECE_HOVER_STARTED:
			_handle_gamepiece_event(event, BehaviorRegistry.EventType.HOVER_START)
		Event.Type.GAMEPIECE_HOVER_ENDED:
			_handle_gamepiece_event(event, BehaviorRegistry.EventType.HOVER_END)
		Event.Type.FOCUSED_GAMEPIECE_CHANGED:
			_handle_focus_changed(event)

## Register a behavior for a specific trigger condition
func register_behavior(trigger: UIBehaviorTrigger, behavior: BaseUIBehavior) -> void:
	_behavior_registry.register(trigger, behavior)




func _on_floating_window_closed(ui_id: String) -> void:
	_floating_windows.erase(ui_id)
	unregister_ui_element(ui_id)

## Get the UI state tracker for querying current UI state
func get_state_tracker() -> UIStateTracker:
	return _ui_state_tracker

## Register a UI element 
func register_ui_element(element_type: Globals.UIElementType, owner_gamepiece: Gamepiece) -> String:
	var id = IdGenerator.generate_ui_element_id()
	var info = UIElementInfo.new(id, element_type, owner_gamepiece)
	_ui_elements[id] = info
	return id

## Get UI element info by ID
func get_ui_element(id: String) -> UIElementInfo:
	return _ui_elements.get(id)

## Unregister a UI element
func unregister_ui_element(id: String) -> void:
	_ui_elements.erase(id)

# Register all behaviors from UIBehaviorConfig
func _register_configured_behaviors() -> void:
	var all_behaviors = UIBehaviorConfig.get_all_behaviors()
	
	for triggered_behavior in all_behaviors:
		# Create the behavior instance
		var behavior_instance = triggered_behavior.create_behavior()
		if not behavior_instance:
			push_warning("Failed to create behavior: %s" % triggered_behavior.behavior_class)
			continue
		
		# Register the behavior with its trigger
		register_behavior(triggered_behavior.trigger, behavior_instance)


# Handle gamepiece events (click, hover)
func _handle_gamepiece_event(event: Event, event_type: BehaviorRegistry.EventType) -> void:
	var gamepiece: Gamepiece = null
	var ui_element_id: String = ""
	
	# Get gamepiece and ui_element_id based on event type
	match event.event_type:
		Event.Type.GAMEPIECE_CLICKED:
			var click_event = event as GamepieceEvents.ClickedEvent
			gamepiece = click_event.gamepiece
			ui_element_id = click_event.ui_element_id
		Event.Type.GAMEPIECE_HOVER_STARTED:
			var hover_event = event as GamepieceEvents.HoverStartedEvent
			gamepiece = hover_event.gamepiece
			ui_element_id = hover_event.ui_element_id
		Event.Type.GAMEPIECE_HOVER_ENDED:
			var hover_event = event as GamepieceEvents.HoverEndedEvent
			gamepiece = hover_event.gamepiece
			ui_element_id = hover_event.ui_element_id
		_:
			return
	
	if not gamepiece:
		return
	
	# Get UI-relevant info from the controller
	var controller = gamepiece.get_controller()
	if not controller:
		return
	
	var controller_info = controller.get_ui_info()
	
	# Add UI element info if available
	if ui_element_id:
		controller_info[Globals.UIInfoFields.UI_ELEMENT_ID] = ui_element_id
		# Also add element type info if we have it
		var element_info = get_ui_element(ui_element_id)
		if element_info:
			controller_info[Globals.UIInfoFields.UI_ELEMENT_TYPE] = element_info.element_type
	
	# Find and execute matching behaviors
	var behaviors = _behavior_registry.find_matching_behaviors(controller_info, event_type)
	
	for behavior in behaviors:
		# Call appropriate behavior method based on event type
		match event_type:
			BehaviorRegistry.EventType.CLICK:
				behavior.on_click(gamepiece, _ui_state_tracker)
			BehaviorRegistry.EventType.HOVER_START:
				_ui_state_tracker.mark_hovered(gamepiece)
				behavior.on_hover_start(gamepiece, _ui_state_tracker)
			BehaviorRegistry.EventType.HOVER_END:
				_ui_state_tracker.unmark_hovered(gamepiece)
				behavior.on_hover_end(gamepiece, _ui_state_tracker)

# Handle focus change events
func _handle_focus_changed(event: Event) -> void:
	var focused_event = event as GamepieceEvents.FocusedEvent
	if not focused_event:
		return
		
	var old_focused = _ui_state_tracker.get_focused_entity()
	var new_focused = focused_event.gamepiece
	
	# Update tracker
	_ui_state_tracker.set_focused_entity(new_focused)
	
	# Handle unfocus behaviors
	if old_focused and old_focused != new_focused:
		var controller = old_focused.get_controller()
		if controller:
			var controller_info = controller.get_ui_info()
			var behaviors = _behavior_registry.find_matching_behaviors(controller_info, BehaviorRegistry.EventType.FOCUS)
			for behavior in behaviors:
				behavior.on_unfocus(old_focused, _ui_state_tracker)
	
	# Handle focus behaviors
	if new_focused:
		var controller = new_focused.get_controller()
		if controller:
			var controller_info = controller.get_ui_info()
			var behaviors = _behavior_registry.find_matching_behaviors(controller_info, BehaviorRegistry.EventType.FOCUS)
			for behavior in behaviors:
				behavior.on_focus(new_focused, _ui_state_tracker)




## Registry that maps triggers to behaviors
class BehaviorRegistry extends RefCounted:
	enum EventType { CLICK, HOVER_START, HOVER_END, FOCUS }
	
	# Storage: Array of {trigger, behavior} pairs
	var _registrations: Array = []
	
	## Register a behavior for a trigger condition
	func register(trigger: UIBehaviorTrigger, behavior: BaseUIBehavior) -> void:
		_registrations.append({
			"trigger": trigger,
			"behavior": behavior
		})
	
	## Find all behaviors matching the controller info and event
	func find_matching_behaviors(controller_info: Dictionary, event_type: EventType) -> Array[BaseUIBehavior]:
		var matching: Array[BaseUIBehavior] = []
		
		# Convert EventType to string for trigger matching
		var event_string = _event_type_to_string(event_type)
		
		for registration in _registrations:
			var trigger = registration.trigger as UIBehaviorTrigger
			if trigger.matches(controller_info, event_string):
				matching.append(registration.behavior)
		
		return matching
	
	func _event_type_to_string(event_type: EventType) -> String:
		match event_type:
			EventType.CLICK: return "click"
			EventType.HOVER_START, EventType.HOVER_END: return "hover"
			EventType.FOCUS: return "focus"
			_: return ""


## Tracks current UI state (what's hovered, focused, selected, etc)
class UIStateTracker extends RefCounted:
	signal entity_focused(entity: Gamepiece)
	signal entity_unfocused(entity: Gamepiece)
	signal interaction_selected(interaction_id: String)
	signal interaction_deselected(interaction_id: String)
	signal interaction_highlighted(interaction_id: String)
	signal interaction_unhighlighted(interaction_id: String)
	
	var _focused_entity: Gamepiece = null
	var _hovered_entities: Dictionary = {}  # instance_id -> entity
	var _selected_interactions: Dictionary = {}  # interaction_id -> true
	var _highlighted_interactions: Dictionary = {}  # interaction_id -> true
	var _open_windows: Dictionary = {}  # window_id -> window
	
	## Mark entity as hovered
	func mark_hovered(entity: Gamepiece) -> void:
		_hovered_entities[entity.get_instance_id()] = entity
	
	## Unmark entity as hovered
	func unmark_hovered(entity: Gamepiece) -> void:
		_hovered_entities.erase(entity.get_instance_id())
	
	## Check if entity is hovered
	func is_hovered(entity: Gamepiece) -> bool:
		return _hovered_entities.has(entity.get_instance_id())
	
	## Set focused entity
	func set_focused_entity(entity: Gamepiece) -> void:
		if _focused_entity != entity:
			var old_entity = _focused_entity
			_focused_entity = entity
			
			if old_entity:
				entity_unfocused.emit(old_entity)
			if entity:
				entity_focused.emit(entity)
	
	## Get focused entity
	func get_focused_entity() -> Gamepiece:
		return _focused_entity
	
	## Mark interaction as selected
	func select_interaction(interaction_id: String) -> void:
		if not _selected_interactions.has(interaction_id):
			_selected_interactions[interaction_id] = true
			interaction_selected.emit(interaction_id)
	
	## Unmark interaction as selected
	func deselect_interaction(interaction_id: String) -> void:
		if _selected_interactions.has(interaction_id):
			_selected_interactions.erase(interaction_id)
			interaction_deselected.emit(interaction_id)
	
	## Check if interaction is selected
	func is_interaction_selected(interaction_id: String) -> bool:
		return _selected_interactions.has(interaction_id)
	
	## Mark interaction as highlighted
	func highlight_interaction(interaction_id: String) -> void:
		if not _highlighted_interactions.has(interaction_id):
			_highlighted_interactions[interaction_id] = true
			interaction_highlighted.emit(interaction_id)
	
	## Unmark interaction as highlighted
	func unhighlight_interaction(interaction_id: String) -> void:
		if _highlighted_interactions.has(interaction_id):
			_highlighted_interactions.erase(interaction_id)
			interaction_unhighlighted.emit(interaction_id)
	
	## Check if interaction is highlighted
	func is_interaction_highlighted(interaction_id: String) -> bool:
		return _highlighted_interactions.has(interaction_id)
	
	## Track a window
	func track_window(window_id: String, window: Control) -> void:
		_open_windows[window_id] = window
		# Auto-cleanup when window is freed
		if not window.tree_exited.is_connected(_on_window_freed.bind(window_id)):
			window.tree_exited.connect(_on_window_freed.bind(window_id))
	
	func _on_window_freed(window_id: String) -> void:
		_open_windows.erase(window_id)
	
	## Get tracked window
	func get_window(window_id: String) -> Control:
		return _open_windows.get(window_id)
	
	## Check if window exists
	func has_window(window_id: String) -> bool:
		return _open_windows.has(window_id)


## Interface for providing panels to the UI system
class PanelProvider extends RefCounted:
	func get_compatible_panels(entity: GamepieceController) -> Array[PanelInfo]:
		return []


## Information about a UI panel
class PanelInfo extends RefCounted:
	var scene_path: String
	var priority: int = 10
	var name: String
	
	func _init(path: String = "", prio: int = 10, panel_name: String = "") -> void:
		scene_path = path
		priority = prio
		name = panel_name
