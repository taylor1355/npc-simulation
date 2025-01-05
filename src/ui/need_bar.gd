@tool
extends HBoxContainer

@export var need_id: String = ""

@export var label_text: String = "":
	set = set_label_text

func _ready():
	set_label_text(label_text)

	if not Engine.is_editor_hint():
		FieldEvents.event_dispatched.connect(
			func(event: Event):
				if event.is_type(Event.Type.NPC_NEED_CHANGED):
					_on_npc_need_changed(event as NpcEvents.NeedChangedEvent)
		)


func set_label_text(value: String) -> void:
	label_text = value
	$RichTextLabel.text = "[right]" + value + "[/right]"


func _on_npc_need_changed(event: NpcEvents.NeedChangedEvent) -> void:
	if event.npc == Globals.focused_gamepiece and event.need_id == need_id:
		$ProgressBar.value = event.new_value
