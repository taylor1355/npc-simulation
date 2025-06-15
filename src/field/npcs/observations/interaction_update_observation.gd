class_name InteractionUpdateObservation extends Observation

var interaction_name: String
var update_type: NpcEvent.Type

func _init(interaction_name: String, update_type: NpcEvent.Type):
	self.interaction_name = interaction_name
	self.update_type = update_type

func get_type() -> String:
	return "interaction_update"

func get_data() -> Dictionary:
	return {
		"interaction_name": interaction_name,
		"update_type": update_type
	}

func format_for_npc() -> String:
	var status = ""
	match update_type:
		NpcEvent.Type.INTERACTION_STARTED:
			status = "started"
		NpcEvent.Type.INTERACTION_CANCELED:
			status = "canceled"
		NpcEvent.Type.INTERACTION_FINISHED:
			status = "finished"
		_:
			status = "updated"
	
	return "Interaction %s: %s" % [status, interaction_name]