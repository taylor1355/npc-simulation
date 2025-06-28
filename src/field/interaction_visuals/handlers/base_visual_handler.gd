class_name BaseVisualHandler extends Node2D

var interaction_id: String
var participants: Array[NpcController]

# Called when the handler is created
func setup(id: String, npcs: Array[NpcController]) -> void:
	interaction_id = id
	participants = npcs
	_on_setup()

# Override in subclasses to handle setup
func _on_setup() -> void:
	pass

# Called when a participant joins
func add_participant(npc: NpcController) -> void:
	if npc not in participants:
		participants.append(npc)
		_on_participant_added(npc)

# Called when a participant leaves
func remove_participant(npc: NpcController) -> void:
	participants.erase(npc)
	_on_participant_removed(npc)

# Override in subclasses to handle participant changes
func _on_participant_added(npc: NpcController) -> void:
	pass

func _on_participant_removed(npc: NpcController) -> void:
	pass