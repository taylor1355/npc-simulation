extends TabContainer

# All possible panel scenes with their priorities (lower priority = earlier in tabs)
const PANEL_SCENES = {
	# Info panels (priority 0)
	"res://src/ui/panels/npc_info_panel.tscn": 0,
	"res://src/ui/panels/item_info_panel.tscn": 0,
	
	# NPC panels (priority 1)
	"res://src/ui/panels/needs_panel.tscn": 1,
	"res://src/ui/panels/working_memory_panel.tscn": 1,
	
	# Component panels (priority 1)
	"res://src/ui/panels/components/consumable_panel.tscn": 1,
	"res://src/ui/panels/components/need_modifying_panel.tscn": 1,
	"res://src/ui/panels/components/sittable_panel.tscn": 1,
}

func _ready() -> void:
	clip_tabs = false # Show all tabs without scrolling
	tab_changed.connect(_on_tab_changed)
	visibility_changed.connect(_on_visibility_changed)
	
	# Listen for focus changes to update panels
	EventBus.event_dispatched.connect(
		func(event: Event):
			if event.event_type == Event.Type.FOCUSED_GAMEPIECE_CHANGED:
				_on_focused_gamepiece_changed(event)
	)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()

func _on_tab_changed(tab: int) -> void:
	# Deactivate all panels
	for i in get_tab_count():
		if i != tab:
			var panel := get_child(i) as GamepiecePanel
			if panel:
				panel.deactivate()
	
	# Activate current panel if visible
	if is_visible_in_tree():
		var panel := get_child(tab) as GamepiecePanel
		if panel:
			panel.activate()

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		var panel := get_child(current_tab) as GamepiecePanel
		if panel:
			panel.activate()
	else:
		for i in get_tab_count():
			var panel := get_child(i) as GamepiecePanel
			if panel:
				panel.deactivate()

func _on_focused_gamepiece_changed(event: GamepieceEvents.FocusedEvent) -> void:
	# Remove all existing tabs
	for child in get_children():
		remove_child(child)
		child.queue_free()
		
	if not event.gamepiece:
		hide()
		return
		
	var controller = event.gamepiece.get_controller()
	if not controller:
		hide()
		return
		
	show()
		
	# Create compatible panels and sort by priority
	var panels = []
	for scene_path in PANEL_SCENES:
		var panel = load(scene_path).instantiate()
		if panel.is_compatible_with(controller):
			panels.append({
				"panel": panel,
				"priority": PANEL_SCENES[scene_path],
				"name": panel.name.trim_suffix("Panel")
			})
		else:
			panel.free()
	
	# Sort panels by priority then name
	panels.sort_custom(
		func(a, b):
			if a.priority != b.priority:
				return a.priority < b.priority
			return a.name < b.name
	)
	
	# Add sorted panels
	for i in panels.size():
		var panel_data = panels[i]
		add_child(panel_data.panel)
		set_tab_title(i, panel_data.name)
		# Pass focus event to new panel
		panel_data.panel._on_focused_gamepiece_changed(event)
