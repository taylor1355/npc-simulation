class_name CompositeObservation extends Observation

var observations: Array[Observation]

func _init(observations: Array[Observation] = []):
	self.observations = observations

func add_observation(observation: Observation) -> void:
	observations.append(observation)

func find_observation(observation_type: GDScript) -> Observation:
	# Find the last observation of the given type
	for i in range(observations.size() - 1, -1, -1):
		if observations[i].get_script() == observation_type:
			return observations[i]
	return null

func get_type() -> String:
	return "composite"

func get_data() -> Dictionary:
	var data = {}
	for obs in observations:
		data[obs.get_type()] = obs.get_data()
	return data

func format_for_npc() -> String:
	var parts = []
	for obs in observations:
		var formatted = obs.format_for_npc()
		if not formatted.is_empty():
			parts.append(formatted)
	return "\n".join(parts)