class_name IdGenerator

static func generate_uuid() -> String:
	var uuid_bytes = []
	uuid_bytes.resize(16)
	randomize()
	for i in range(16):
		uuid_bytes[i] = randi() % 256
	
	# Set version to 4
	uuid_bytes[6] = (uuid_bytes[6] & 0x0f) | 0x40
	# Set variant to 1
	uuid_bytes[8] = (uuid_bytes[8] & 0x3f) | 0x80
	
	var uuid_str = ""
	for i in range(16):
		uuid_str += "%02x" % uuid_bytes[i]
		if i in [3, 5, 7, 9]:
			uuid_str += "-"
			
	return uuid_str

static func generate_conversation_id() -> String:
	return "conv_" + generate_uuid()

static func generate_interaction_id() -> String:
	return "interaction_" + generate_uuid()

static func generate_bid_id() -> String:
	return "bid_" + generate_uuid()

static func generate_ui_element_id() -> String:
	return "ui_elem_" + generate_uuid()

static func generate_interaction_panel_id(interaction_id: String) -> String:
	return "interaction_panel_" + interaction_id

static func generate_entity_id() -> String:
	return "entity_" + generate_uuid()
