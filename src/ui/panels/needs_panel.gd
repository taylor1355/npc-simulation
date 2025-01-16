extends GamepiecePanel

@onready var needs_container: VBoxContainer = $MarginContainer/NeedsContainer

func is_compatible_with(controller: GamepieceController) -> bool:
	return controller is NpcController

func _show_default_text() -> void:
	for child in needs_container.get_children():
		child.queue_free()
	
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = "Select an NPC to view their needs."
	needs_container.add_child(label)

func _show_invalid_text() -> void:
	for child in needs_container.get_children():
		child.queue_free()
	
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = "Not an NPC."
	needs_container.add_child(label)

func _get_npc_controller(controller: GamepieceController) -> NpcController:
	return controller as NpcController if controller else null

func _update_display() -> void:
	for child in needs_container.get_children():
		child.queue_free()
		
	var npc_controller = _get_npc_controller(current_controller)
	if not npc_controller:
		return
		
	for need_id in npc_controller.NEED_IDS:
		var need_bar = preload("res://src/ui/need_bar.tscn").instantiate()
		need_bar.need_id = need_id
		need_bar.label_text = need_id.capitalize()
		needs_container.add_child(need_bar)

		# Set initial value directly
		if npc_controller.needs.has(need_id):
			need_bar.get_node("ProgressBar").value = npc_controller.needs[need_id]
