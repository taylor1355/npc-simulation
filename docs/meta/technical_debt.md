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

### 7. Complete Entity Polymorphism (Remaining Vision & Terminology)
**Impact**: Medium | **Effort**: Medium | **Leverage**: 🔥🔥

**Progress**: ✅ **Interaction system fully unified** (January 2025)
- Moved `handle_interaction_bid()` and `interaction_finished` to `GamepieceController` base class
- Created single `InteractionContext` class handling both entity and group interactions
- Added `InteractionRegistry` singleton for global interaction tracking
- Eliminated duplicate conversation bug through context-based duplicate prevention
- Removed temporary interaction object creation during discovery
- Standardized interaction lifecycle signals

**Remaining Issues**:
- **Vision System Separation**: Still separates NPCs and Items into different arrays instead of unified entity list
- **Parameter Terminology**: Still uses "item_name" parameters instead of generic "entity_name" 
- **NPC Single-Party Limitations**: NPCs reject single-party interactions ("NPCs currently only support multi-party interactions")
- **Scattered Item-Specific Terminology**: References to "items" throughout codebase that should be generic "entities"

**Current Issues**:
```gdscript
# Vision observation still separates entities unnecessarily
{
    "visible_items": [...],
    "visible_npcs": [...]  # Should be unified as "visible_entities"
}

# Parameters still assume item-centric terminology
{
    "item_name": "Chair"  # Should be "entity_name": "Chair"
}

# NPCs can't be single-party interaction targets
func handle_interaction_bid(request: InteractionBid) -> void:
    if not request is MultiPartyBid:
        request.reject("NPCs currently only support multi-party interactions")
```

**Remaining Solution**:
- Unify vision observations into single `visible_entities` array with type field
- Rename interaction parameters from "item_name" to "entity_name"
- Enable NPCs as single-party interaction targets
- Audit and update item-specific terminology to be entity-generic

**Benefits**: Complete entity polymorphism, easier to add new entity types, cleaner API contracts

## Implementation Priority

### Phase 1: Critical Issues
1. **Mock Backend Client Architecture Duplication** - Enables core business model
2. **Debug Logging Standardization** - Major maintainability improvement

### Phase 2: Type Safety & Patterns
3. **Variant Usage Investigation** - Better type contracts
4. **Event Handling Consolidation** - Reduce boilerplate

### Phase 3: Large Refactoring
5. **Terminology Taxonomy** - Major naming clarity project
6. **NPC and Item Interaction Unification** - Major architectural improvement
7. **Physics Layer Constants** - Minor cleanup
8. **Vision Manager Initialization** - Physics timing issues
9. **Need Effect Data Flow** - Centralize need logic (see below)

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

### 9. Need Effect Data Flow Complexity
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
- Need logic spread across multiple files instead of centralized in needs.gd/needs_manager.gd
- Backend only sees binary filled/drained, not actual rates

**Long-term Solution**: 
Centralize need effect evaluation in Needs class, make components expose need effects directly without going through interaction creation. This would eliminate the complex data transformation chain and improve performance.

**Partial Fixes Applied**:
- ✅ Added caching to EntityComponent base class to prevent repeated factory creation
- ✅ Components now override `_create_interaction_factories()` instead of `get_interaction_factories()`
- ✅ This reduces ConsumableComponent factory spam from hundreds to once per component
- ✅ Eliminated temporary interaction creation via `InteractionFactory.get_metadata()`

### 10. Debug Print Statements Cleanup
**Impact**: Low | **Effort**: Low | **Leverage**: 🔥🔥

**Problem**: Debug print statements scattered throughout codebase:
- `npc_controller.gd` line 196: prints component interaction completion
- Various other debug prints that should use proper logging
- No centralized control over debug output

**Solution**: Remove or convert to proper logging system (see Debug Logging Standardization)

### 11. Game Clock System
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

### 12. Vision Observation Entity Separation
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

### 13. Conversation State Validation
**Impact**: Medium | **Effort**: Low | **Leverage**: 🔥🔥

**Problem**: No validation to ensure conversation constraints:
- NPCs can potentially move while in conversations
- No check to prevent joining multiple conversations
- State consistency not enforced

**Solution**: Add validation checks in:
- Movement system to check conversation state
- Conversation join logic to check existing conversations
- State machine transitions

### 14. Gamepiece Identification System
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

### 15. Interaction Base Class Responsibilities
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

### 16. Interaction Factory Organization
**Impact**: Medium | **Effort**: Low | **Leverage**: 🔥🔥

**Problem**: InteractionFactory classes are currently defined within component files rather than alongside their corresponding Interaction classes:
- Factories are tightly coupled to their interactions but separated in the file structure
- Makes it harder to find the factory for a given interaction
- Components files become cluttered with factory definitions
- Violates single responsibility principle

**Current Organization**:
```
src/field/items/components/consumable_component.gd  # Contains ConsumeInteractionFactory
src/field/items/components/sittable_component.gd    # Contains SitInteractionFactory  
src/field/npcs/components/conversable_component.gd  # Contains ConversationInteractionFactory
src/field/interactions/consume_interaction.gd       # The actual interaction
src/field/interactions/sit_interaction.gd           # The actual interaction
src/field/interactions/conversation_interaction.gd  # The actual interaction
```

**Proposed Organization**:
```
# Option 1: Factories in same file as interactions
src/field/interactions/consume_interaction.gd       # Contains both ConsumeInteraction and ConsumeInteractionFactory
src/field/interactions/sit_interaction.gd           # Contains both SitInteraction and SitInteractionFactory

# Option 2: Separate factory files alongside interactions
src/field/interactions/consume_interaction.gd
src/field/interactions/consume_interaction_factory.gd
src/field/interactions/sit_interaction.gd
src/field/interactions/sit_interaction_factory.gd
```

**Benefits**: 
- Better code organization and discoverability
- Components focus on configuration, not factory logic
- Easier to maintain interaction-factory pairs
- Clearer separation of concerns

### 18. Fragile Initialization Dependencies
**Impact**: High | **Effort**: Medium | **Leverage**: 🔥🔥🔥

**Problem**: Multiple systems rely on specific initialization timing in _ready() functions, creating fragile dependencies that can permanently break systems:

**Known Issues**:
- VisionManager expects parent gamepiece metadata to be set in _ready()
- If timing fails, VisionManager remains permanently broken
- Similar patterns exist in other systems that assume certain initialization order
- No recovery mechanism if initialization fails

**Example**:
```gdscript
# Current fragile pattern in VisionManager
func _ready():
    parent_gamepiece = get_gamepiece(self)  # May return null if metadata not set yet
    if not parent_gamepiece:
        push_error("VisionManager failed to find parent gamepiece")
        return  # Permanently broken, no recovery possible
```

**Solution**: Use lazy-loaded properties that attempt initialization on first access:
```gdscript
# Lazy loading property pattern
var _parent_gamepiece: Gamepiece = null  # Private cached value

## Lazy-loaded parent gamepiece property
var parent_gamepiece: Gamepiece:
    get:
        if not _parent_gamepiece:
            _parent_gamepiece = get_gamepiece(self)
            if not _parent_gamepiece:
                push_error("VisionManager failed to find parent gamepiece")
        return _parent_gamepiece
```

**Benefits**:
- Defers initialization until actually needed
- Automatically retries on each access if previous attempts failed
- No extra initialization state to manage
- Clean property access syntax
- Can still detect and log errors when they occur

## Conclusion

The highest-leverage improvements now focus on code quality and maintainability. With the interaction system recently refactored, priorities shift to establishing consistent patterns (logging, event handling) and improving type safety. The terminology overloading remains a significant issue affecting developer productivity.

Key insight: Establishing consistent patterns and clear contracts will provide the foundation for sustainable growth of the codebase.

### 17. Interaction Bid System Architecture Complexity
**Impact**: High | **Effort**: High | **Leverage**: 🔥🔥🔥🔥

**Problem**: The current bid system has differential handling between single-party and multi-party bids, creating bugs and unnecessary complexity:

**Current Issues**:
- Single-party bids have no timeout mechanism (unlike MultiPartyBid's 5-second timeout)
- Different code paths for handling single vs multi-party interactions
- NPCs get stuck in REQUESTING state when targets are destroyed or don't respond
- Bid system adds an extra layer of abstraction that may be redundant
- Separate bid classes (InteractionBid, MultiPartyBid) with different behaviors and lifecycles

**Recent Bug Examples**:
```gdscript
# NPC stuck in requesting state after target item consumed
[NPC 82208360471] Action 'interact_with' in state IDLE
[NPC 82208360471] State changed from idle to requesting
# ... stays in requesting state indefinitely sending 'continue' actions

# NPCs responding to bids while already interacting  
[NPC 81705043961] Action 'respond_to_interaction_bid' in state INTERACTING
```

**Architectural Observation**:
The bid system essentially manages a temporary pre-interaction state that tracks:
- Who wants to interact
- What interaction they want
- Who has accepted/rejected
- Timeout handling

These responsibilities could potentially be absorbed by existing subsystems (interactions, contexts, or enhanced participant tracking), eliminating an entire abstraction layer.

**Key Insight**: 
Interactions and contexts already manage participant state and lifecycle. The bid system may be a vestigial abstraction that creates more complexity than it solves. The invitation/acceptance protocol it implements could be handled more directly by the systems that already manage the actual interactions.

**Benefits of Simplification**:
- Single code path for all interaction types
- Unified timeout handling
- Simpler state machine
- Fewer abstraction layers to understand
- Reduced bugs from differential handling

### 18. Mock Backend Client Architecture Duplication
**Impact**: High | **Effort**: Medium | **Leverage**: 🔥🔥🔥🔥🔥

**Problem**: The mock backend currently implements a completely separate client architecture from the MCP server client, blocking the core business model feature of distributed compute through player-spawned MCP servers.

**Business Model Impact**: 
The distributed compute model is central to the platform's revenue strategy and scaling goals:
- **Revenue Stream**: Players contribute compute via client-spawned MCP servers, earning tokens proportionally
- **Scaling Target**: 100-1000+ NPCs per world through distributed player compute contributions  
- **Player Economy**: Platform takes transaction fees on player-to-player compute trades
- **Technical Foundation**: "Player-contributed compute through automatically spawned MCP servers" is a key architectural feature

**Current Architecture Issues**:
- **MCP Backend**: Uses three-layer architecture (McpNpcClient → McpSdkClient → McpServiceProxy)
- **Mock Backend**: Uses direct instantiation of MockNpcBackend with simple method calls
- Both implement NpcClientBase but with entirely different communication patterns
- Mock backend bypasses the structured observation/action flow used by MCP
- **Critical Gap**: No development/testing path from mock backend to player-spawned MCP servers

**Blocking Business Features**:
- Cannot test distributed compute spawning functionality during development
- No migration path from development (mock) to production (player-spawned MCP servers)
- Cannot validate the player compute contribution and token allocation systems
- Different code paths prevent testing of the full MCP communication pipeline

**Proposed Solution**: Refactor mock backend to use MCP server architecture:
```gdscript
# Create MockMcpServer that implements MCP protocol
class_name MockMcpServer extends RefCounted

# Encapsulates current MockNpcBackend logic
var _backend: MockNpcBackend

func call_tool(tool_name: String, arguments: Dictionary) -> Dictionary:
    match tool_name:
        "create_agent":
            return _backend.create_agent(arguments)
        "process_observation":
            return _backend.process_observation(arguments)
        # etc.
```

**Benefits**:
- **Enables Core Business Model**: Provides development/testing foundation for player-spawned MCP servers
- **Single Client Architecture**: Unified codebase for both mock and distributed compute backends
- **Business Model Validation**: Enables testing of compute contribution, token allocation, and player economy systems
- **Production Parity**: Mock backend tests the full communication pipeline used in production
- **Easier Runtime Switching**: Seamless transition between local mock and distributed player compute
- **Reduced Maintenance**: Single client architecture eliminates code duplication

**Implementation Priority**: 
This should be elevated to **Phase 1: Critical Issues** as it's blocking core business model development and testing.
