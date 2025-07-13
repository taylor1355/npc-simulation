# Incremental Architecture Evolution Plan

## Overview

This document outlines how to incrementally evolve the existing architecture to support rapid system development without requiring a complete rewrite. Each step builds on the current strengths while adding transformative capabilities.

## Current Architecture Strengths to Preserve

1. **Component System** - Already provides good composition
2. **EventBus** - Solid foundation for communication
3. **Type Safety** - PropertySpec pattern is excellent
4. **Clear Separation** - Three-tier NPC architecture is clean

## Evolution Phases

## Phase 1: System Auto-Discovery (1 week)

### Goal
Systems self-register instead of manual wiring.

### Implementation

#### Step 1: Create GameSystem Base Class
```gdscript
# src/common/systems/game_system.gd
@tool
extends Node
class_name GameSystem

# Systems announce themselves
signal system_ready(system: GameSystem)

static var _systems: Dictionary = {}

func _enter_tree():
    if not Engine.is_editor_hint():
        _systems[get_system_name()] = self
        GameSystem.system_ready.emit(self)

# Virtual methods for systems to override
func get_system_name() -> String:
    return get_class()

func get_dependencies() -> Array[String]:
    return []

func get_exposed_methods() -> Dictionary:
    # Auto-discover @exposed methods
    var methods = {}
    for method in get_method_list():
        if method.name.begins_with("exposed_"):
            methods[method.name.trim_prefix("exposed_")] = method.name
    return methods
```

#### Step 2: Create System Registry
```gdscript
# src/common/systems/system_registry.gd
extends Node
class_name SystemRegistry

var _registered_systems: Dictionary = {}
var _system_capabilities: Dictionary = {}

func _ready():
    # Listen for systems
    GameSystem.system_ready.connect(_on_system_ready)
    
func _on_system_ready(system: GameSystem):
    var name = system.get_system_name()
    _registered_systems[name] = system
    
    # Auto-wire capabilities
    _discover_capabilities(system)
    _wire_debug_commands(system)
    _create_ui_panels(system)
    
func get_system(name: String) -> GameSystem:
    return _registered_systems.get(name)
```

#### Step 3: Migrate Existing Systems
```gdscript
# Example: InteractionSystem migration
extends GameSystem  # Instead of Node
class_name InteractionSystem

func get_system_name() -> String:
    return "interaction"

# Exposed methods other systems can call
@exposed
func start_interaction(initiator_id: String, target_id: String, type: String) -> bool:
    # Current implementation
    pass
```

### Benefits
- New systems automatically available
- No manual registration needed
- Clear system boundaries

## Phase 2: Capability Injection (1 week)

### Goal
Systems declare capabilities and get features automatically.

### Implementation

#### Step 1: Define Core Capabilities
```gdscript
# src/common/capabilities/debuggable.gd
extends Resource
class_name Debuggable

@export var debug_fields: Array[String] = []
@export var debug_commands: Dictionary = {}

func inject_into(system: GameSystem) -> void:
    # Add debug panel
    if debug_fields.size() > 0:
        _create_debug_panel(system)
    
    # Wire debug commands
    for cmd_name in debug_commands:
        DebugConsole.register_command(
            "%s_%s" % [system.get_system_name(), cmd_name],
            debug_commands[cmd_name]
        )

# src/common/capabilities/observable.gd
extends Resource
class_name Observable

@export var metrics: Array[String] = []
@export var track_performance: bool = true

func inject_into(system: GameSystem) -> void:
    if track_performance:
        _wrap_process_methods(system)
    
    for metric in metrics:
        MetricsCollector.register_metric(
            "%s.%s" % [system.get_system_name(), metric]
        )
```

#### Step 2: Extend GameSystem for Capabilities
```gdscript
# Add to GameSystem
var _capabilities: Array[Resource] = []

func add_capability(capability: Resource) -> void:
    _capabilities.append(capability)
    if capability.has_method("inject_into"):
        capability.inject_into(self)
```

#### Step 3: Use in Systems
```gdscript
extends GameSystem

func _ready():
    add_capability(Debuggable.new({
        debug_fields = ["current_weather", "temperature"],
        debug_commands = {
            "set_weather": set_weather,
            "randomize": randomize_weather
        }
    }))
    
    add_capability(Observable.new({
        metrics = ["weather_changes", "rain_duration"],
        track_performance = true
    }))
```

## Phase 3: Message-Based Queries (2 weeks)

### Goal
Systems communicate through a unified protocol without direct dependencies.

### Implementation

#### Step 1: Enhance MessageBus
```gdscript
# src/common/message_bus_v2.gd
extends Node
class_name MessageBusV2

# Async query support
func query(address: String, params: Dictionary = {}) -> Variant:
    var parts = address.split(".")
    var system_name = parts[0]
    
    var system = SystemRegistry.get_system(system_name)
    if not system:
        push_error("System not found: " + system_name)
        return null
    
    # Call exposed method
    var method_name = "exposed_" + parts[1]
    if system.has_method(method_name):
        return await system.callv(method_name, params.values())
    
    return null

# Pattern-based subscriptions
var _subscriptions: Dictionary = {}

func subscribe_pattern(pattern: String, callback: Callable) -> void:
    if not _subscriptions.has(pattern):
        _subscriptions[pattern] = []
    _subscriptions[pattern].append(callback)

func publish(address: String, data: Variant) -> void:
    # Match against patterns
    for pattern in _subscriptions:
        if _matches_pattern(address, pattern):
            for callback in _subscriptions[pattern]:
                callback.call(address, data)
```

#### Step 2: Migrate Critical Paths
Start with NPC decision flow:
```gdscript
# Old way
var item = field.get_item_by_name(item_name)
var interaction = item.get_interaction(interaction_name)

# New way  
var interaction = await MessageBus.query("field.get_interaction", {
    "item_name": item_name,
    "interaction_name": interaction_name
})
```

## Phase 4: Reactive State (2 weeks)

### Goal
Declarative state management with automatic propagation.

### Implementation

#### Step 1: Create Reactive Primitives
```gdscript
# src/common/reactive/reactive_value.gd
extends Resource
class_name ReactiveValue

signal value_changed(old_value, new_value)

var _value: Variant
var _watchers: Array[Callable] = []

var value:
    get:
        return _value
    set(new_value):
        if _value != new_value:
            var old = _value
            _value = new_value
            value_changed.emit(old, new_value)
            _notify_watchers(old, new_value)

func watch(callback: Callable) -> void:
    _watchers.append(callback)

func _notify_watchers(old_value, new_value):
    for watcher in _watchers:
        watcher.call(old_value, new_value)
```

#### Step 2: Create State Store
```gdscript
# src/common/state/game_state.gd
extends Node
class_name GameState

# Reactive state
var time = ReactiveValue.new()
var weather = ReactiveValue.new()
var active_interactions = ReactiveArray.new()

# Computed values
var is_night: bool:
    get:
        return time.value.hour >= 18 or time.value.hour < 6

# State queries
func query(path: String) -> Variant:
    var parts = path.split(".")
    var current = self
    
    for part in parts:
        if current.has(part):
            current = current.get(part)
        else:
            return null
    
    return current
```

#### Step 3: Connect Systems to State
```gdscript
# In any system
func _ready():
    # React to state changes
    GameState.weather.watch(_on_weather_changed)
    
    # Computed reactions
    GameState.watch_computed(
        func(): return GameState.is_night and GameState.weather.value == "rainy",
        _on_rainy_night
    )
```

## Phase 5: Schema-Driven Development (3 weeks)

### Goal
Define systems through schemas that generate implementation.

### Implementation

#### Step 1: Schema Parser
```gdscript
# src/common/schema/system_schema.gd
extends Resource
class_name SystemSchema

@export var system_name: String
@export var state_fields: Array[StateFieldDef] = []
@export var capabilities: Array[String] = []
@export var ui_panels: Array[UIPanelDef] = []

func generate_system() -> GameSystem:
    var system = GameSystem.new()
    system.name = system_name
    
    # Generate state
    for field_def in state_fields:
        _add_state_field(system, field_def)
    
    # Add capabilities
    for cap_name in capabilities:
        var cap = load("res://src/common/capabilities/%s.gd" % cap_name).new()
        system.add_capability(cap)
    
    # Generate UI
    for panel_def in ui_panels:
        _generate_ui_panel(system, panel_def)
    
    return system
```

#### Step 2: Schema-Based Systems
```gdscript
# weather_system_schema.tres (Resource file)
extends SystemSchema

system_name = "weather"
state_fields = [
    StateFieldDef.new("current", "enum", ["sunny", "rainy", "cloudy"]),
    StateFieldDef.new("temperature", "float", {"min": -20, "max": 45}),
    StateFieldDef.new("wind_speed", "float", {"min": 0, "max": 50})
]
capabilities = ["debuggable", "observable", "persistent"]
ui_panels = [
    UIPanelDef.new("overview", ["current", "temperature"]),
    UIPanelDef.new("debug", ["all"], true)  # editable
]
```

## Migration Strategy

### Week 1-2: Foundation
1. Implement GameSystem base class
2. Create SystemRegistry
3. Migrate 2-3 existing systems as proof of concept

### Week 3-4: Capabilities
1. Build capability system
2. Create core capabilities (Debuggable, Observable, Persistent)
3. Add capabilities to migrated systems

### Week 5-6: Communication
1. Implement MessageBusV2
2. Add query support
3. Migrate critical communication paths

### Week 7-8: State Management
1. Build reactive primitives
2. Create GameState store
3. Connect existing systems

### Week 9-12: Advanced Features
1. Schema parser
2. UI generation
3. Full system generation from schemas

## Measuring Success

### Development Speed Metrics
- **New System Creation**: 2-3 days → 2-3 hours
- **System Integration**: 10+ touch points → 0 touch points
- **Debug UI Creation**: 1-2 hours → Automatic
- **Cross-System Communication**: Multiple APIs → Single API

### Code Quality Metrics
- **Boilerplate Reduction**: 60-70%
- **System Coupling**: High → Low
- **Test Coverage**: Easier to test isolated systems
- **Discoverability**: Self-documenting systems

## Risks and Mitigations

### Risk: Performance Overhead
**Mitigation**: 
- Profile each addition
- Use lazy initialization
- Cache frequently accessed data
- Make reactive updates opt-in

### Risk: Learning Curve
**Mitigation**:
- Incremental adoption
- Keep old patterns working
- Extensive documentation
- Example systems

### Risk: Over-Engineering
**Mitigation**:
- Start with minimal features
- Only add what provides clear value
- Regular developer feedback
- Focus on actual pain points

## Conclusion

This incremental approach preserves the existing architecture's strengths while adding powerful new capabilities. Each phase delivers immediate value while building toward a system where new features can be added in hours instead of days. The key is maintaining backward compatibility while gradually migrating to more powerful patterns.