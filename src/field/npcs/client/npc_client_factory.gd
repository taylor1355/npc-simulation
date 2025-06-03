class_name NpcClientFactory
extends RefCounted

enum BackendType {
	MOCK,
	MCP
}

static var current_backend: BackendType = BackendType.MOCK
static var _instance_cache: NpcClientBase = null

static func create_client() -> NpcClientBase:
	match current_backend:
		BackendType.MOCK:
			return MockNpcClient.new()
		BackendType.MCP:
			return McpNpcClient.new()
		_:
			push_error("Unknown backend type: %s" % current_backend)
			return MockNpcClient.new()

static func get_shared_client() -> NpcClientBase:
	if not _instance_cache or not is_instance_valid(_instance_cache):
		_instance_cache = create_client()
	return _instance_cache

static func switch_backend(type: BackendType) -> void:
	if current_backend != type:
		current_backend = type
		# Clear cached instance
		if _instance_cache and is_instance_valid(_instance_cache):
			_instance_cache.queue_free()
			_instance_cache = null
		# Notify system of backend switch
		EventBus.dispatch(SystemEvents.BackendSwitchedEvent.new(type))

static func get_backend_name(type: BackendType) -> String:
	match type:
		BackendType.MOCK:
			return "mock"
		BackendType.MCP:
			return "mcp"
		_:
			return "unknown"
