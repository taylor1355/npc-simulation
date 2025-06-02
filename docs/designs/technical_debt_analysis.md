# Technical Debt Analysis

## High Leverage Issues (Quick Wins)

### 1. Debug Logging Cleanup and Standardization
**Impact**: High | **Effort**: Medium | **Leverage**: 🔥🔥🔥🔥🔥

**Problem**: 64+ instances of inconsistent logging patterns throughout codebase with no centralized control:
- Mock backend has excessive debug prints (20+ print statements)
- MCP client mixes `print()`, `printerr()`, `error.emit()`
- No consistent debug levels or toggles

**Current Issues**:
```gdscript
# Different patterns throughout:
print("Debug info")           # Plain print
printerr("Error occurred")    # Error print  
error.emit("Error message")   # Signal emission
push_error("Invalid config")  # Engine error
```

**Solution**: Create centralized logging system:
```gdscript
# src/common/debug/logger.gd
class_name Logger
extends RefCounted

enum Level { DEBUG, INFO, WARN, ERROR }

static var debug_enabled: bool = false
static var min_level: Level = Level.INFO

static func debug(msg: String, context: String = "") -> void:
    if debug_enabled and min_level <= Level.DEBUG:
        print("[DEBUG][%s] %s" % [context, msg])

static func error(msg: String, context: String = "") -> void:
    if min_level <= Level.ERROR:
        printerr("[ERROR][%s] %s" % [context, msg])
```

**Cleanup Priority**:
1. Mock backend (remove excessive debugging)
2. MCP client (standardize error reporting)
3. Component validation (consistent error messages)


## Medium Leverage Issues

### 2. Variant Usage Investigation and Struct-like Classes
**Impact**: Medium | **Effort**: Medium | **Leverage**: 🔥🔥🔥

**Problem**: 23+ instances where `Dictionary[String, Variant]` obscures contracts:

**Specific Problematic Cases**:
```gdscript
# Action.parameters - different actions need different data
var parameters: Dictionary[String, Variant]
# Usage shows the issue:
Action.new(Type.MOVE_TO, {"x": x, "y": y})
Action.new(Type.INTERACT_WITH, {"item_name": name, "interaction_name": interaction})

# NpcEvent.payload - different event types need different data  
var payload: Dictionary[String, Variant]
# Usage shows the issue:
{"position": pos, "needs": needs, "seen_items": items}  # OBSERVATION
{"interaction_name": name, "reason": reason}            # REJECTED

# Interaction parameters - loosely typed
var parameters: Dictionary[String, Variant] = {}
# Different interactions need different parameters
```

**Proposed Struct-like Classes**:
```gdscript
# Action parameter classes
class_name MoveActionParams extends RefCounted:
    var target_cell: Vector2i
    var allow_partial: bool = false

class_name InteractActionParams extends RefCounted:
    var item_name: String
    var interaction_name: String
    var timeout: float = 5.0

# Event payload classes  
class_name ObservationPayload extends RefCounted:
    var position: Vector2i
    var seen_items: Array[Dictionary]
    var needs: Dictionary[String, float]
    var movement_locked: bool
    var current_interaction: Interaction

class_name InteractionEventPayload extends RefCounted:
    var interaction_name: String
    var item_name: String
    var reason: String = ""
```

**Benefits**: Self-documenting code, better IDE support, compile-time validation, clearer interfaces

### 3. Terminology Taxonomy and Naming Clarity
**Impact**: High | **Effort**: High | **Leverage**: 🔥🔥🔥

**Problem**: Significant overloading of core terms creates confusion:

**Documented Overloading Issues**:

**"Event" Confusion**:
- `Event` (base class for field events)
- `NpcEvent` (backend lifecycle events) 
- `GamepieceEvents` (static factory for gamepiece events)
- `InputEvent` (Godot UI events)
- Various `*Events` classes in different contexts

**"Request/Response" Confusion**:
- `InteractionRequest` (asking to start/stop interactions)
- `NpcRequest` (contains event data for backend)  
- `NpcResponse` (backend decisions)
- HTTP requests in MCP client
- Generic "request" usage throughout

**"Action" Ambiguity**:
- `Action` (NPC behavior decisions)
- Godot InputMap actions
- Generic "action" meaning operations
- Interaction "actions" (what they do)

**Proposed Systematic Rename**:
```gdscript
# Clear event taxonomy
Event -> FieldEvent                    # Field simulation events
NpcEvent -> NpcLifecycleEvent         # Backend lifecycle tracking
GamepieceEvents -> GamepieceEventFactory  # Factory pattern clearer

# Clear request/response taxonomy  
NpcRequest -> NpcObservationBatch     # Batch of observations
NpcResponse -> NpcDecision            # Backend decision

# Clear action taxonomy
Action -> NpcBehaviorAction           # NPC behavior decisions
# Keep InputMap actions as-is
# Rename interaction capabilities to avoid confusion
```

### 4. Event Handling Pattern Consolidation
**Impact**: Medium | **Effort**: Medium | **Leverage**: 🔥🔥🔥

**Problem**: 15+ instances of repetitive event filtering pattern throughout codebase:

**Current Repetitive Pattern**:
```gdscript
# Found in multiple files (ui panels, vision_manager, npc_controller, etc.):
EventBus.event_dispatched.connect(
    func(event: Event):
        if event.is_type(Event.Type.SOME_TYPE):
            _handle_event(event as SomeEvent)
)
```

**Specific Examples**:
- `working_memory_panel.gd`: 3 different event type checks
- `tab_container.gd`: Event filtering and casting
- `need_bar.gd`: NPC need change filtering
- `npc_controller.gd`: Multiple event type handling
- `vision_manager.gd`: Gamepiece destroyed filtering

**Solution**: Create event subscription utilities:
```gdscript
# src/common/events/event_subscriber.gd
class_name EventSubscriber
extends RefCounted

static func subscribe_to_type(type: Event.Type, handler: Callable) -> void:
    EventBus.event_dispatched.connect(
        func(event: Event):
            if event.is_type(type):
                handler.call(event)
    )

static func subscribe_to_types(types: Array[Event.Type], handler: Callable) -> void:
    EventBus.event_dispatched.connect(
        func(event: Event):
            for event_type in types:
                if event.is_type(event_type):
                    handler.call(event)
                    break
    )
```

**Benefits**: Reduced boilerplate, consistent event handling, easier to maintain

## Lower Leverage Issues

### 5. @tool Annotation Audit
**Impact**: Low | **Effort**: Low | **Leverage**: 🔥🔥

**Problem**: Many files use `@tool` unnecessarily, risking production build issues:

**Files Using @tool**:
- `src/field/items/item_controller.gd`
- `src/field/items/base_item.gd`  
- `src/ui/need_bar.gd`
- Several other files

**Risk**: @tool annotation can cause issues in production builds and makes debugging harder since scripts run in editor context.

**Audit Needed**: Check each @tool usage to determine if it's actually needed for editor functionality (like custom inspectors, gizmos, or editor-only behavior).

**Fix**: Remove @tool annotations where they're not needed for legitimate editor functionality.

### 6. Physics Layer Constants  
**Impact**: Low | **Effort**: Low | **Leverage**: 🔥

**Problem**: Physics layer masks hardcoded in multiple places.

### 7. Vision Manager Initialization Issue
**Impact**: Low | **Effort**: High | **Leverage**: 🔥

**Problem**: TODO about `get_overlapping_areas()` timing issue with physics initialization.

## Implementation Priority

### Phase 1: Core Architecture 
1. **Debug Logging Standardization** - Major maintainability improvement

### Phase 2: Type Safety & Patterns
2. **Variant Usage Investigation** - Better type contracts
3. **Event Handling Consolidation** - Reduce boilerplate

### Phase 3: Large Refactoring
4. **Terminology Taxonomy** - Major naming clarity project
5. **@tool Annotation Audit** - Production safety
6. **Physics Layer Constants** - Minor cleanup
7. **Vision Manager Initialization** - Physics timing issues

## Risk Assessment

**Low Risk**: @tool cleanup, constants
**Medium Risk**: Logging changes, struct classes, pattern consolidation  
**High Risk**: Terminology changes (affects many interfaces)

## Success Metrics

- **Code Clarity**: Clear separation between components and systems
- **Type Safety**: Replace generic Variants with explicit contracts where appropriate
- **Maintainability**: Centralized logging, consistent patterns
- **Developer Experience**: Clear naming, better IDE support
- **System Reliability**: Clearer component interfaces and event handling

## Conclusion

The highest-leverage improvements now focus on code quality and maintainability. With the interaction system recently refactored, priorities shift to establishing consistent patterns (logging, event handling) and improving type safety. The terminology overloading remains a significant issue affecting developer productivity.

Key insight: Establishing consistent patterns and clear contracts will provide the foundation for sustainable growth of the codebase.
