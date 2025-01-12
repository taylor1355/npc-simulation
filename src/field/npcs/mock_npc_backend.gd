## Mock implementation of the NPC agent backend service. This simulates the server-side
## logic that would normally run remotely. Uses "agent" terminology to match the real backend.
class_name MockNpcBackend
extends Node

# Backend state
var agents: Dictionary = {}  # Dictionary of agent_id -> agent state

func create_agent(agent_id: String, config: Dictionary) -> Dictionary:
	"""Create a new agent
	
	Args:
		agent_id: Unique identifier for the agent
		config: Configuration object containing:
			- traits: list[str], Basic personality traits
			- initial_working_memory: str, Initial working memory state
			- initial_long_term_memories: list[str], Initial long-term memories
	"""
	agents[agent_id] = {
		"traits": config.get("traits", []),
		"working_memory": config.get("initial_working_memory", ""),
		"long_term_memories": config.get("initial_long_term_memories", [])
	}
	
	return {
		"status": "created",
		"agent_id": agent_id
	}

func process_observation(agent_id: String, observation: String, available_actions: Array) -> Dictionary:
	"""Process observation and return chosen action for an agent
	
	Args:
		agent_id: Agent to process observation for
		observation: Current state/situation in natural language
		available_actions: List of possible actions, each containing:
			- name: str, Action identifier
			- description: str, Human readable description
			- parameters: dict, Required parameters and their descriptions
	"""
	if not agents.has(agent_id):
		return {
			"status": "error",
			"message": "Agent %s not found" % agent_id
		}
	
	# Update agent's working memory
	var working_memory = agents[agent_id]["working_memory"]
	var observations = working_memory.split("\n", false)
	observations.append("Observed: " + observation)
	
	# Keep only the last few observations
	var max_observations = 5
	if observations.size() > max_observations:
		observations = observations.slice(-max_observations)
	agents[agent_id]["working_memory"] = "\n".join(observations)
	
	# Mock decision making - choose random action
	var chosen_action = available_actions[randi() % available_actions.size()]
	
	return {
		"action": chosen_action["name"],
		"parameters": chosen_action.get("parameters", {})
	}

func cleanup_agent(agent_id: String) -> Dictionary:
	"""Gracefully cleanup and remove an agent from the system
	
	Args:
		agent_id: Agent to remove
	"""
	if agents.has(agent_id):
		agents.erase(agent_id)
		
	return {
		"status": "removed",
		"agent_id": agent_id
	}

func get_agent_info(agent_id: String) -> Dictionary:
	"""Get basic information about an agent in the system"""
	if not agents.has(agent_id):
		return {
			"status": "error",
			"message": "Agent %s not found" % agent_id
		}
		
	var agent = agents[agent_id]
	return {
		"status": "active",
		"traits": agent["traits"],
		"working_memory": agent["working_memory"]
	}
