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

### 5. Physics Layer Constants  
**Impact**: Low | **Effort**: Low | **Leverage**: 🔥

**Problem**: Physics layer masks hardcoded in multiple places.

### 6. Vision Manager Initialization Issue
**Impact**: Low | **Effort**: High | **Leverage**: 🔥

**Problem**: TODO about `get_overlapping_areas()` timing issue with physics initialization.

### 7. NPC and Item Interaction Handling Inconsistency
**Impact**: High | **Effort**: High | **Leverage**: 🔥🔥

**Problem**: NPCs and Items handle interactions differently, creating complexity and duplication:
- Items use `handle_interaction_bid()` method
- NPCs don't have this method, requiring special handling in RequestingState
- `_on_interaction_finished` signal connection differs between items and NPCs
- Vision system treats NPCs and items differently (separate arrays)
- Parameters like "item_name" assume only items can be interaction targets

**Current Issues**:
```gdscript
# RequestingState has to check target type
if target_controller is ItemController:
    target_controller.interaction_finished.connect(...)
else:
    # Different handling for NPCs
    interaction_obj.interaction_ended.connect(...)

# Vision observation separates entities unnecessarily
{
    "visible_items": [...],
    "visible_npcs": [...]  # Should be unified as "visible_entities"
}
```

**Solution**: Unify interaction handling at GamepieceController level:
- Move `handle_interaction_bid()` to GamepieceController base class
- Standardize interaction lifecycle signals
- Treat all entities uniformly in vision and interaction systems
- Use generic "target" terminology instead of "item" specific naming

**Benefits**: Simpler code, true entity polymorphism, easier to add new entity types

## Implementation Priority

### Phase 1: Critical Issues
1. **Debug Logging Standardization** - Major maintainability improvement

### Phase 2: Type Safety & Patterns
2. **Variant Usage Investigation** - Better type contracts
3. **Event Handling Consolidation** - Reduce boilerplate

### Phase 3: Large Refactoring
4. **Terminology Taxonomy** - Major naming clarity project
5. **NPC and Item Interaction Unification** - Major architectural improvement
6. **Physics Layer Constants** - Minor cleanup
7. **Vision Manager Initialization** - Physics timing issues
8. **Need Effect Data Flow** - Centralize need logic (see below)

## Risk Assessment

**Low Risk**: Constants
**Medium Risk**: Logging changes, struct classes, pattern consolidation  
**High Risk**: Terminology changes (affects many interfaces)

## Success Metrics

- **Code Clarity**: Clear separation between components and systems
- **Type Safety**: Replace generic Variants with explicit contracts where appropriate
- **Maintainability**: Centralized logging, consistent patterns
- **Developer Experience**: Clear naming, better IDE support
- **System Reliability**: Clearer component interfaces and event handling

### 8. Need Effect Data Flow Complexity
**Impact**: High | **Effort**: High | **Leverage**: 🔥🔥

**Problem**: Need effect information is scattered across multiple layers with complex data transformations:

**Current Data Flow**:
```
ConsumableComponent.need_deltas → NeedModifyingComponent.need_rates → 
Interaction.needs_filled/drained → Interaction.to_dict() → 
VisionObservation → MockNpcBackend
```

**Issues**:
- Components store need effects in different formats (deltas vs rates)
- Interaction creation is inefficient (creates temporary objects for data extraction)
- Need logic spread across multiple files instead of centralized in needs.gd/needs_manager.gd
- Backend only sees binary filled/drained, not actual rates
- Interaction factories are created repeatedly instead of being cached
- ItemController.get_available_interactions() creates temporary interactions just to get their data

**Long-term Solution**: 
Centralize need effect evaluation in Needs class, make components expose need effects directly without going through interaction creation. This would eliminate the complex data transformation chain and improve performance.

**Partial Fix Applied**:
- Added caching to EntityComponent base class to prevent repeated factory creation
- Components now override `_create_interaction_factories()` instead of `get_interaction_factories()`
- This reduces ConsumableComponent factory spam from hundreds to once per component
- Still need to address temporary interaction creation for data extraction

### 9. Debug Print Statements Cleanup
**Impact**: Low | **Effort**: Low | **Leverage**: 🔥🔥

**Problem**: Debug print statements scattered throughout codebase:
- `npc_controller.gd` line 196: prints component interaction completion
- Various other debug prints that should use proper logging
- No centralized control over debug output

**Solution**: Remove or convert to proper logging system (see Debug Logging Standardization)

### 10. Game Clock System
**Impact**: Medium | **Effort**: Medium | **Leverage**: 🔥🔥

**Problem**: Using `OS.get_ticks_msec()` for timestamps prevents proper game pause/speed control:
- `conversation_interaction.gd` uses system time for message timestamps
- Cannot pause or speed up game time
- Makes replays and save/load more complex

**Solution**: Implement centralized game clock that supports:
- Pause functionality
- Speed multipliers
- Consistent time across all systems
- Proper serialization for save/load

### 11. Vision Observation Entity Separation
**Impact**: Medium | **Effort**: Medium | **Leverage**: 🔥🔥

**Problem**: VisionObservation separates items and NPCs into different arrays:
```gdscript
{
    "visible_items": [...],
    "visible_npcs": [...]
}
```

**Issues**:
- Requires special handling for each entity type
- Duplicates logic for similar operations
- Makes it harder to add new entity types

**Solution**: Unify into single array with type field:
```gdscript
{
    "visible_entities": [
        {"type": "item", "name": "Chair", ...},
        {"type": "npc", "name": "Alice", ...}
    ]
}
```

### 12. Conversation State Validation
**Impact**: Medium | **Effort**: Low | **Leverage**: 🔥🔥

**Problem**: No validation to ensure conversation constraints:
- NPCs can potentially move while in conversations
- No check to prevent joining multiple conversations
- State consistency not enforced

**Solution**: Add validation checks in:
- Movement system to check conversation state
- Conversation join logic to check existing conversations
- State machine transitions

### 13. Gamepiece Identification System
**Impact**: High | **Effort**: Medium | **Leverage**: 🔥🔥🔥

**Problem**: Gamepieces currently use `display_name` for both UI display and identification, which creates ambiguity:

**Current Issues**:
- Multiple items can have the same display_name (e.g., multiple "Chair" items)
- Code uses display_name for finding specific items (_find_item_by_name)
- No unique identifier for gamepieces beyond instance_id
- Confusion between node name and display_name properties

**Example Problem**:
```gdscript
# Multiple chairs with same name
func _find_item_by_name(item_name: String) -> ItemController:
    for item in seen_items:
        if item._gamepiece.display_name == item_name:  # Returns first match only!
            return item
```

**Proposed Solution**:
```gdscript
class_name Gamepiece extends Node2D

## Unique identifier for this gamepiece instance
@export var gamepiece_id: String = ""  # Auto-generated if empty

## Display name shown in UI. May not be unique.
@export var display_name: String = ""

func _ready():
    if gamepiece_id.is_empty():
        gamepiece_id = IdGenerator.generate_id("gamepiece")
```

**Benefits**:
- Clear separation between identification (gamepiece_id) and display (display_name)
- Ability to have multiple items with same display name
- Unambiguous references in code
- Better support for save/load systems in the future

### 14. Interaction Base Class Responsibilities
**Impact**: Medium | **Effort**: Medium | **Leverage**: 🔥🔥

**Problem**: The Interaction base class contains logic that should be in subclasses:
- `get_interaction_emoji()` has hardcoded interaction names in a match statement
- Base class knows about specific interaction types (consume, sit, conversation)
- Creates tight coupling between base and specific implementations

**Current Issue**:
```gdscript
# Base class shouldn't know about specific interaction types
func get_interaction_emoji() -> String:
    match name:
        "consume":
            return "🍽️"
        "sit":
            return "🪑"
        _:
            return "🔧"
```

**Solution**: Make Interaction more abstract:
- Move emoji logic to specific interaction subclasses
- Create proper subclasses for consume/sit interactions instead of using base class
- Base class should only contain truly generic interaction logic
- Consider making base class abstract (if Godot 4.x supports it)

**Benefits**: Better separation of concerns, easier to add new interaction types, more maintainable

## Conclusion

The highest-leverage improvements now focus on code quality and maintainability. With the interaction system recently refactored, priorities shift to establishing consistent patterns (logging, event handling) and improving type safety. The terminology overloading remains a significant issue affecting developer productivity.

Key insight: Establishing consistent patterns and clear contracts will provide the foundation for sustainable growth of the codebase.
