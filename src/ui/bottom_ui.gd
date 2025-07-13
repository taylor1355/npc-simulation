class_name BottomUI
extends PanelContainer

## Unified bottom UI container that holds both the tab panels and status bar.
## Provides a cohesive, professional UI layout.

@onready var tab_container: TabContainer = $VBoxContainer/TabSection/TabContainer
@onready var status_display: Label = $VBoxContainer/StatusSection/MarginContainer/StatusLabel

var _current_cell: Vector2i = Vector2i.ZERO
const TIME_UPDATE_ID: String = "bottom_ui_status"
const UPDATE_INTERVAL: float = 0.1  # 10 updates per second

func _ready() -> void:
	# Set up time updates
	if SimulationTime:
		SimulationTime.subscribe_to_updates(TIME_UPDATE_ID, UPDATE_INTERVAL)
		SimulationTime.time_update_for_subscriber.connect(_on_time_update)
		_update_status_display()
	
	# Connect to coordinate updates
	EventBus.cell_highlighted.connect(_on_cell_highlighted)
	_update_status_display()
	
	# Let TabContainer initialize itself
	if tab_container.has_method("_ready"):
		tab_container._ready()

func _exit_tree() -> void:
	if SimulationTime:
		SimulationTime.unsubscribe_from_updates(TIME_UPDATE_ID)

func _on_time_update(subscriber_id: String, _time_dict: Dictionary) -> void:
	if subscriber_id == TIME_UPDATE_ID:
		_update_status_display()

func _on_cell_highlighted(event: CellEvent) -> void:
	_current_cell = event.cell
	_update_status_display()

func _update_status_display() -> void:
	if SimulationTime:
		# Get time and date separately for better formatting
		var time_str = SimulationTime.format_time(false, false, false, "", true, true)  # Just time with AM/PM
		var date_str = SimulationTime.format_time(true, true, false, "", false, false)  # Just date, no time
		# Compose with bullet separators - date first, then time, then position
		status_display.text = "%s  •  %s  •  Pos (x,y): %d, %d" % [
			date_str, time_str, _current_cell.x, _current_cell.y
		]

## Get the tab container for external access
func get_tab_container() -> TabContainer:
	return tab_container