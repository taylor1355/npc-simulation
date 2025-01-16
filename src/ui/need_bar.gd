@tool
extends HBoxContainer

@export var need_id: String = ""

@export var label_text: String = "":
	set = set_label_text

var accumulated_delta: float = 0.0
const UPDATE_THRESHOLD: float = 1.0

func _ready():
	set_label_text(label_text)
	$ProgressBar.value = 0
	$ProgressBar.mouse_filter = MOUSE_FILTER_IGNORE
	
	if not Engine.is_editor_hint():
		FieldEvents.event_dispatched.connect(
			func(event: Event):
				if event.is_type(Event.Type.NPC_NEED_CHANGED):
					_on_npc_need_changed(event as NpcEvents.NeedChangedEvent)
		)

func set_label_text(value: String) -> void:
	label_text = value
	$RichTextLabel.text = value

func _on_npc_need_changed(event: NpcEvents.NeedChangedEvent) -> void:
	if event.npc == Globals.focused_gamepiece and event.need_id == need_id:
		var delta = event.new_value - $ProgressBar.value
		accumulated_delta += delta
		
		if abs(accumulated_delta) >= UPDATE_THRESHOLD:
			$ProgressBar.value += accumulated_delta
			accumulated_delta = 0.0
