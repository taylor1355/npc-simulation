extends EntityPanel

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
		
	for need_id in Needs.NEED_NAMES:
		var need_bar = preload("res://src/ui/need_bar.tscn").instantiate()
		need_bar.need_id = need_id
		need_bar.label_text = need_id.capitalize()
		needs_container.add_child(need_bar)

		# Set initial value directly
		var needs_dict = npc_controller.needs_manager.get_all_needs()
		if needs_dict.has(need_id):
			need_bar.get_node("ProgressBar").value = needs_dict[need_id]
