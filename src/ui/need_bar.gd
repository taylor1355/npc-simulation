@tool
extends HBoxContainer

@export var need_id: String = ""

@export var label_text: String = "":
	set = set_label_text

func _ready():
	set_label_text(label_text)

	if not Engine.is_editor_hint():
		FieldEvents.npc_need_changed.connect(self._on_npc_need_changed)


func set_label_text(value: String) -> void:
	label_text = value
	$RichTextLabel.text = "[right]" + value + "[/right]"


func _on_npc_need_changed(gamepiece: Gamepiece, changed_need_id: String, new_value: float) -> void:
	if gamepiece == Globals.focused_gamepiece and changed_need_id == need_id:
		$ProgressBar.value = new_value
