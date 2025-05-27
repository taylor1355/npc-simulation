# Technical Debt Analysis

## High Leverage Issues (Quick Wins)

### 1. NPC Controller State Machine Cleanup
**Impact**: High | **Effort**: Medium | **Leverage**: 🔥🔥🔥🔥🔥

**Problem**: Critical architectural issue in `npc_controller.gd` with implicit state tracking and mixed concerns:

**Current State Issues**:
```gdscript
# Scattered implicit state variables:
var movement_locked: bool = false
var is_wandering: bool = false
var current_interaction: Interaction = null
var current_request: InteractionRequest = null
var decision_timer: float = 0.0

# State transitions buried in action handling:
match action_name:
    "move_to":
        is_wandering = false  # Implicit state change
    "interact_with":
        is_wandering = false  # Another implicit state change
    # No clear state validation or transition logic
```

**Root Problems**:
- Controller state (pathing, interaction coordination) mixed with NPC state (motivations, decisions)
- No explicit state enum - states inferred from variable combinations
- State transitions scattered throughout `_on_action_chosen()` method
- No state validation - can end up in invalid states
- Backend gets no explicit controller state information

**Proposed Solution**:
```gdscript
# Explicit controller state machine
enum ControllerState {
    IDLE,           # Ready for new actions
    MOVING,         # Currently pathfinding/moving
    REQUESTING,     # Waiting for interaction acceptance/rejection
    INTERACTING,    # Actively in an interaction
    WANDERING       # Random movement mode
}

class_name NpcControllerState extends RefCounted:
    var state: ControllerState = ControllerState.IDLE
    var movement_locked: bool = false
    var destination: Vector2i
    var current_interaction: Interaction
    var current_request: InteractionRequest
    
    func can_transition_to(new_state: ControllerState) -> bool:
        # Explicit state transition validation
    
    func transition_to(new_state: ControllerState) -> void:
        # Validated state transitions with logging

# Separate high-level NPC state for backend
class_name NpcInternalState extends RefCounted:
    var working_memory: String
    var personality_traits: Array[String]
```

**Benefits**: 
- Clear separation of coordination vs decision-making concerns
- Explicit state tracking enables better debugging and backend integration
- State validation prevents invalid combinations
- Controller state can be serialized and passed to backend
- Cleaner, more maintainable state transitions

### 2. Move InteractionRequest State to Interaction
**Impact**: High | **Effort**: Medium | **Leverage**: 🔥🔥🔥🔥🔥

**Problem**: `InteractionRequest` has accumulated too much responsibility and state that belongs in `Interaction`:

**Current Issues**:
```gdscript
# InteractionRequest has too much state:
var interaction_name: String          # Duplicates Interaction.name
var npc_controller: NpcController     # Runtime state
var item_controller: ItemController   # Runtime state  
var arguments: Dictionary[String, Variant]  # Could be in Interaction
var status: Status                    # Runtime state
# Plus signals for accept/reject

# Usage shows the problem:
request.item_controller = target_item  # Assigning after creation
current_request = request              # Storing for later cleanup
```

**Root Problems**:
- `InteractionRequest` mixing configuration (what) with runtime state (who, when, status)
- Multiple sources of truth for interaction data
- Difficult to reuse interaction logic between different NPCs
- Status tracking scattered between request and interaction

**Proposed Refactor**:
```gdscript
# Minimal InteractionRequest - just a bid
class_name InteractionBid extends RefCounted:
    var interaction: Interaction      # Reference to the actual interaction
    var bidder: NpcController        # Who wants to interact
    var bid_type: BidType            # START or CANCEL
    var status: BidStatus            # PENDING, ACCEPTED, REJECTED
    # Signals stay here as they're about the bid process

# Enhanced Interaction with more state
class_name Interaction extends RefCounted:
    var name: String
    var description: String
    var needs_filled: Array[Needs.Need]
    var needs_drained: Array[Needs.Need]
    var parameters: InteractionParameters  # Typed parameters instead of Dictionary
    var duration: float = 0.0
    var requires_adjacency: bool = true
    # Interaction-specific validation logic
    
    func can_start_with(npc: NpcController, item: ItemController) -> bool:
        # All validation logic here
    
    func start_interaction(npc: NpcController, item: ItemController) -> InteractionSession:
        # Returns active session object for tracking
```

**Benefits**: 
- Clear separation between bidding process and interaction logic
- Easier to test and reuse interactions
- Centralized interaction validation
- Simpler request lifecycle management

### 3. Debug Logging Cleanup and Standardization
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

### 4. Complete FieldEvents -> EventBus Rename  
**Impact**: Medium | **Effort**: Low | **Leverage**: 🔥🔥🔥🔥

**Problem**: `FieldEvents` was intended to be renamed to `EventBus` but was made a subclass as a temporary hack:
```gdscript
# src/common/field_events.gd - Current temporary solution
## Global event bus for field-related events
extends EventBus
```

**Investigation Findings**:
- 43+ references to FieldEvents throughout codebase need updating
- The inheritance pattern works but wasn't the intended final design
- Should be a straightforward rename operation

**Solution**: 
1. Rename `field_events.gd` to `event_bus.gd` 
2. Update all 43+ references from `FieldEvents` to `EventBus`
3. Remove the inheritance and make it the concrete implementation

**Benefits**: Cleaner architecture, removes temporary hack, more intuitive naming

## Medium Leverage Issues

### 5. Variant Usage Investigation and Struct-like Classes
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

# InteractionRequest.arguments - vague purpose
var arguments: Dictionary[String, Variant] = {}
# Currently unused in code - unclear what it's for
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

### 6. Terminology Taxonomy and Naming Clarity
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
InteractionRequest -> InteractionBid   # Bidding metaphor
NpcRequest -> NpcObservationBatch     # Batch of observations
NpcResponse -> NpcDecision            # Backend decision

# Clear action taxonomy
Action -> NpcBehaviorAction           # NPC behavior decisions
# Keep InputMap actions as-is
# Rename interaction capabilities to avoid confusion
```

### 7. Event Handling Pattern Consolidation
**Impact**: Medium | **Effort**: Medium | **Leverage**: 🔥🔥🔥

**Problem**: 15+ instances of repetitive event filtering pattern throughout codebase:

**Current Repetitive Pattern**:
```gdscript
# Found in multiple files (ui panels, vision_manager, npc_controller, etc.):
FieldEvents.event_dispatched.connect(
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
    FieldEvents.event_dispatched.connect(
        func(event: Event):
            if event.is_type(type):
                handler.call(event)
    )

static func subscribe_to_types(types: Array[Event.Type], handler: Callable) -> void:
    FieldEvents.event_dispatched.connect(
        func(event: Event):
            for event_type in types:
                if event.is_type(event_type):
                    handler.call(event)
                    break
    )
```

**Benefits**: Reduced boilerplate, consistent event handling, easier to maintain

## Lower Leverage Issues

### 8. @tool Annotation Audit
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

### 9. Physics Layer Constants  
**Impact**: Low | **Effort**: Low | **Leverage**: 🔥

**Problem**: Physics layer masks hardcoded in multiple places.

### 10. Vision Manager Initialization Issue
**Impact**: Low | **Effort**: High | **Leverage**: 🔥

**Problem**: TODO about `get_overlapping_areas()` timing issue with physics initialization.

## Implementation Priority

### Phase 1: Core Architecture 
1. **NPC Controller State Machine** - Central to system, enables other improvements
2. **InteractionRequest State Move** - Core interaction architecture cleanup
3. **FieldEvents -> EventBus Rename** - Remove temporary hack

### Phase 2: Type Safety & Patterns
4. **Debug Logging Standardization** - Major maintainability improvement  
5. **Variant Usage Investigation** - Better type contracts
6. **Event Handling Consolidation** - Reduce boilerplate

### Phase 3: Large Refactoring
7. **Terminology Taxonomy** - Major naming clarity project
8. **@tool Annotation Audit** - Production safety
9. **Physics Layer Constants** - Minor cleanup

## Risk Assessment

**Low Risk**: FieldEvents rename, @tool cleanup, constants
**Medium Risk**: State machine refactor, logging changes, struct classes, pattern consolidation
**High Risk**: Terminology changes (affects many interfaces), interaction architecture changes

## Success Metrics

- **Architecture Quality**: Explicit state machines with validation
- **Code Clarity**: Clear separation between coordination and decision-making
- **Type Safety**: Replace generic Variants with explicit contracts where appropriate
- **Maintainability**: Centralized logging, consistent patterns
- **Developer Experience**: Clear naming, better IDE support
- **System Reliability**: Validated state transitions, clearer interaction lifecycle

## Conclusion

The code audit revealed that the highest-leverage improvements target core architectural issues: the implicit state machine in NPC controller and the confused responsibility split between InteractionRequest and Interaction. These changes will significantly improve system reliability and maintainability. The terminology overloading is a real problem that affects developer productivity, but should be tackled after the core architectural issues are resolved.

Key insight: Focus on explicit state management and clear responsibility boundaries first, as these provide the foundation for all other improvements and enable better debugging and testing.
