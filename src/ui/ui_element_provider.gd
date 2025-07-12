extends Node

## Singleton that manages UI display for all game elements.
## Provides a unified API for creating and displaying UI elements (tabs, floating windows, tooltips).
## Registered as an autoload singleton in Project Settings.

# Configuration classes for type safety
class UIElementConfig:
	var scene_path: String
	
	func _init(path: String):
		scene_path = path

class TabPanelConfig extends UIElementConfig:
	var priority: int = 10
	var display_name: String = ""
	
	func _init(path: String, prio: int = 10, name: String = ""):
		super(path)
		priority = prio
		display_name = name

class FloatingWindowConfig extends UIElementConfig:
	var title: String = ""
	var default_size: Vector2 = Vector2(400, 300)
	var can_close: bool = true
	var resizable: bool = true
	
	func _init(path: String, window_title: String = ""):
		super(path)
		title = window_title if window_title else path.get_file().get_basename()

class TooltipConfig extends UIElementConfig:
	var offset: Vector2 = Vector2(10, 10)
	var follow_mouse: bool = true
	var max_width: int = 300
	
	func _init(path: String = ""):
		super(path)

# Entity panels - can have multiple per entity type
var _entity_panels: Dictionary = {}  # entity_type -> Array[TabPanelConfig]

# Interaction panels - one per interaction type  
var _interaction_panels: Dictionary = {}  # interaction_type -> FloatingWindowConfig

# Component panels - shown in tabs for entities with components
var _component_panels: Dictionary = {}  # component_type -> TabPanelConfig

# Tooltip configuration
var _tooltip_config: TooltipConfig = TooltipConfig.new()

func _ready() -> void:
	_register_default_ui()

func _register_default_ui() -> void:
	# Entity panels (shown in tabs)
	_entity_panels["npc"] = [
		TabPanelConfig.new("res://src/ui/panels/npc_info_panel.tscn", 0, "Info"),
		TabPanelConfig.new("res://src/ui/panels/needs_panel.tscn", 1, "Needs"),
		TabPanelConfig.new("res://src/ui/panels/working_memory_panel.tscn", 1, "Memory")
	]
	
	_entity_panels["item"] = [
		TabPanelConfig.new("res://src/ui/panels/item_info_panel.tscn", 0, "Info")
		# Component panels added dynamically
	]
	
	# Interaction panels (floating windows)
	var conv_config = FloatingWindowConfig.new(
		"res://src/ui/panels/conversation_panel.tscn",
		"Conversation"
	)
	conv_config.default_size = Vector2(350, 400)
	_interaction_panels["conversation"] = conv_config
	
	# Component panels (shown in tabs)
	_component_panels["consumable"] = TabPanelConfig.new(
		"res://src/ui/panels/components/consumable_panel.tscn", 1, "Consumable"
	)
	_component_panels["need_modifying"] = TabPanelConfig.new(
		"res://src/ui/panels/components/need_modifying_panel.tscn", 1, "Effects"
	)
	_component_panels["sittable"] = TabPanelConfig.new(
		"res://src/ui/panels/components/sittable_panel.tscn", 1, "Sittable"
	)

# Display entity panels in tabs - called by TabContainer
func display_entity_panels(controller: GamepieceController) -> Array:
	var panels_data = []
	
	# Get entity-specific panels
	panels_data.append_array(_get_entity_panels(controller))
	
	# Get component panels
	panels_data.append_array(_get_component_panels(controller))
	
	return panels_data

func _get_entity_panels(controller: GamepieceController) -> Array:
	var panels = []
	var entity_type = controller.get_entity_type()
	var configs = _entity_panels.get(entity_type, [])
	
	for config in configs:
		var panel_data = _create_panel_data(config)
		if panel_data:
			panels.append(panel_data)
	
	return panels

func _get_component_panels(controller: GamepieceController) -> Array:
	var panels = []
	
	if not controller.has_method("get_components"):
		return panels
		
	for component in controller.components:
		if not component is EntityComponent:
			continue
			
		var component_name = component.get_component_name()
		var config = _component_panels.get(component_name)
		if config:
			var panel_data = _create_panel_data(config)
			if panel_data:
				panels.append(panel_data)
	
	return panels

func _create_panel_data(config: TabPanelConfig) -> Dictionary:
	var panel = _create_panel_from_config(config)
	if not panel:
		return {}
		
	return {
		"panel": panel,
		"priority": config.priority,
		"name": config.display_name if config.display_name else panel.name.trim_suffix("Panel")
	}

# Display interaction panel as floating window - called by UILink, OpenPanelBehavior
func display_interaction_panel(interaction: Interaction) -> void:
	# Check if already displayed using UIRegistry tracking
	var window_id = IdGenerator.generate_interaction_panel_id(interaction.id)
	if UIRegistry.get_state_tracker().has_window(window_id):
		# Focus existing window
		var window = UIRegistry.get_state_tracker().get_window(window_id)
		if window and is_instance_valid(window):
			window.move_to_front()
			return
	
	var config = _interaction_panels.get(interaction.name)
	if not config:
		return  # No UI for this interaction type
	
	# Create panel
	var panel = _create_interaction_panel(interaction, config)
	if not panel:
		return
		
	# Find the floating window container
	var container = get_tree().get_first_node_in_group("floating_window_container")
	if not container or not container.has_method("add_floating_window"):
		push_error("Floating window container not found. Make sure FloatingWindowContainer is added to the UI scene.")
		return
	
	# Create floating window
	var window = preload("res://src/ui/floating_window.tscn").instantiate() as FloatingWindow
	
	# Configure window before adding to tree
	window.set_window_title(config.title)
	window.set_content(panel)
	window.size = config.default_size
	
	# Add to container
	container.add_floating_window(window)
	
	# Register with state tracker for tracking only
	UIRegistry.get_state_tracker().track_window(window_id, window)
	
	# Handle historical state updates
	panel.became_historical.connect(func():
		# Update window title when interaction becomes historical
		if is_instance_valid(window):
			window.set_window_title(config.title + " (Historical)")
	)

# Display tooltip - called by UI elements for hover text
func display_tooltip(text: String, position: Vector2) -> void:
	# NOTE: Tooltip implementation will be added when tooltip scene exists
	# For now, this is a placeholder for future tooltip support
	push_warning("Tooltip display not yet implemented - tooltip scene doesn't exist")

# Query methods for other systems
func has_ui_for_interaction(interaction_name: String) -> bool:
	return _interaction_panels.has(interaction_name)

func has_panel_for_component(component_name: String) -> bool:
	return _component_panels.has(component_name)

func has_panel_for_entity(entity_type: String) -> bool:
	return _entity_panels.has(entity_type) and not _entity_panels[entity_type].is_empty()

# Public API for extensibility
func register_entity_panels(entity_type: String, configs: Array) -> void:
	_entity_panels[entity_type] = configs

func register_interaction_panel(type: String, config: FloatingWindowConfig) -> void:
	_interaction_panels[type] = config

func register_component_panel(type: String, config: TabPanelConfig) -> void:
	_component_panels[type] = config

func configure_tooltips(config: TooltipConfig) -> void:
	_tooltip_config = config

# Helper methods
func _create_panel_from_config(config: UIElementConfig) -> Control:
	var scene = load(config.scene_path)
	if not scene:
		push_error("Failed to load panel scene: " + config.scene_path)
		return null
	
	var panel = scene.instantiate()
	if not panel:
		push_error("Failed to instantiate panel from: " + config.scene_path)
		return null
		
	return panel

func _create_interaction_panel(interaction: Interaction, config: FloatingWindowConfig) -> InteractionPanel:
	var panel = _create_panel_from_config(config)
	if not panel:
		return null
		
	var interaction_panel = panel as InteractionPanel
	if not interaction_panel:
		push_error("Interaction panel must extend InteractionPanel: " + config.scene_path)
		panel.queue_free()
		return null
	
	# Set the interaction ID - panel will look up the interaction from registry
	interaction_panel.set_interaction_id(interaction.id)
	
	return interaction_panel
