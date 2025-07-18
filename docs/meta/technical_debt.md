# Technical Debt Analysis

## High Leverage Issues (Quick Wins)

### 1. Debug Logging Cleanup and Standardization
**Impact**: High | **Effort**: Medium | **Leverage**: 🔥🔥🔥🔥🔥

**Problem**: Inconsistent logging patterns throughout codebase with no centralized control:
- MCP client has 13 debug prints with conditional `debug_mode` flag
- Different systems use mix of `print()`, `printerr()`, `push_error()`, `push_warning()`, `error.emit()`
- No consistent debug levels or global toggles
- State machine and interaction logging scattered without control

**Current Issues**:
```gdscript
# mcp_npc_client.gd (13 instances)
if debug_mode:
    print("Sending request to %s: %s" % [endpoint, JSON.stringify(data)])

# Various validation code
push_error("Invalid property type")  # type_converters.gd
push_warning("Property not found")   # type_converters.gd

# Debug prints without control
print("Component interaction '%s' completed" % interaction_name)  # npc_controller.gd:239
print("State transition")  # interacting_state.gd:38,41,44
```

**Solution**: Create centralized logging system:
```gdscript
# src/common/debug/logger.gd
class_name Logger
extends RefCounted

enum Level { DEBUG, INFO, WARN, ERROR }

static var enabled: bool = true
static var min_level: Level = Level.INFO
static var context_filters: Array[String] = []  # Only show specific contexts

static func debug(msg: String, context: String = "") -> void:
    _log(Level.DEBUG, msg, context)

static func error(msg: String, context: String = "") -> void:
    _log(Level.ERROR, msg, context)
```

**Cleanup Priority**:
1. MCP client (13 debug prints)
2. Interacting state (3 debug prints)
3. NPC controller state logging
4. Component validation (convert push_error/warning)


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

**Implementation Considerations**:
- Start with the highest-impact areas first (Action parameters, NpcEvent payloads)
- Consider using a factory pattern for creating typed parameters from dictionaries during migration
- Maintain backward compatibility during transition by supporting both dictionary and typed versions
- Focus on external APIs first (what backends see) before internal usage

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
- ✅ **Action class now uses `entity_name` instead of `item_name`**
- ✅ **VisionObservation class updated to use unified `visible_entities` array**

**Remaining Issues**:
- **Vision Manager Still Separated**: `VisionManager` maintains separate `seen_npcs` and `seen_items` dictionaries
- **Separate Vision Methods**: Still has `get_items_by_distance()` and `get_npcs_by_distance()` instead of unified method
- **NPC Single-Party Limitations**: NPCs still reject single-party interactions ("NPCs currently only support multi-party interactions")
- **Data Collection Separation**: `npc_controller.gd` still collects item and NPC data separately before combining

**Current Issues**:
```gdscript
# VisionManager still tracks entities separately
var seen_items: Dictionary = {}  # item_name -> BaseItem
var seen_npcs: Dictionary = {}    # npc_id -> NPC

# Separate methods for getting entities
func get_items_by_distance() -> Array[BaseItem]
func get_npcs_by_distance() -> Array[NPC]

# NPCs can't be single-party interaction targets (npc_controller.gd:452)
if not request is MultiPartyBid:
    request.reject("NPCs currently only support multi-party interactions")
```

**Remaining Solution**:
- Refactor VisionManager to track all entities in single dictionary
- Create unified `get_entities_by_distance()` method
- Enable NPCs as single-party interaction targets
- Update data collection in npc_controller to handle entities uniformly

**Benefits**: Complete entity polymorphism, easier to add new entity types, cleaner API contracts

## Implementation Priority

### Phase 1: Critical Issues (Business Model Blockers)
1. **Mock Backend Client Architecture Duplication** (#20) - Blocks distributed compute business model
2. **ID-First Architecture Completion** (#12) - Blocks multiplayer and distributed compute features
3. **Debug Logging Standardization** (#1) - Major maintainability improvement

### Phase 2: Type Safety & Patterns
4. **Variant Usage Struct Classes** (#2) - Better type contracts
5. **Event Handling Consolidation** (#4) - Reduce boilerplate
6. **Fragile Initialization Dependencies** (#18) - System reliability
7. **Complete UI System Migration** (#21) - Remove duplicates

### Phase 3: Architecture Improvements
8. **Terminology Taxonomy** (#3) - Major naming clarity project
9. **Complete Entity Polymorphism** (#7) - Vision system unification
10. **Interaction Bid Simplification** (#17) - Reduce complexity
11. **Need Effect Data Flow** (#9) - Centralize need logic

### Phase 4: Polish & Minor Issues
12. **Game Clock Usage** (#11) - Update timestamp usage
13. **Z-Index Management** (#18) - Centralized layer system
14. **Conversation Visual Feedback** (#22) - Better UX
15. **Physics Layer Constants** (#5) - Minor cleanup

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

### 11. Game Clock System Partially Implemented
**Impact**: Medium | **Effort**: Low | **Leverage**: 🔥🔥

**Problem**: SimulationTime system exists but not fully utilized:
- ✅ `SimulationTime` singleton implemented with proper game time, pause, and speed control
- ❌ `conversation_interaction.gd` still uses `Time.get_unix_time_from_system()` for timestamps (lines 33, 94, 101, 132)
- ❌ Message timestamps not using simulation time

**Current Issue**:
```gdscript
# conversation_interaction.gd still uses OS time
var timestamp := Time.get_unix_time_from_system()  # Should use SimulationTime
```

**Solution**: Update remaining timestamp usage to use SimulationTime:
```gdscript
# Replace with:
var timestamp := SimulationTime.get_unix_timestamp()
# or for relative time:
var elapsed := SimulationTime.get_elapsed_seconds()
```

**Benefits**: Proper pause support, deterministic replays, consistent time across systems


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

### 12. ID-First Architecture (Partially Resolved)
**Impact**: Very High | **Effort**: High | **Leverage**: 🔥🔥🔥🔥🔥

**Progress**: ✅ **Entity ID system implemented** (January 2025)
- Added `entity_id` property to Gamepiece base class with auto-generation
- Made `npc_id` a property that returns `gamepiece.entity_id` for consistency
- Replaced SpriteColorManager with HighlightManager using entity IDs
- UIRegistry tracks UI elements by owner entity ID

**Remaining Problem**: The codebase still passes object references directly instead of using IDs with registry lookups. This blocks critical features for multiplayer and distributed compute.

**Current Architecture Limitations**:
- Systems pass object references, creating tight coupling and memory leak risks
- No central registry for entity lookups, making network synchronization impossible
- O(n) searches using non-unique display names instead of O(1) ID lookups
- Cannot serialize game state efficiently for save/load or network transmission
- Incompatible with SpacetimeDB's ID-based architecture for multiplayer

**Business Impact**: 
This blocks the core distributed compute model where players contribute MCP servers:
- Cannot transfer NPC control between servers without stable IDs
- Cannot track which player server processed each decision for rewards
- Cannot scale to 100-1000 NPCs across distributed compute nodes

**Proposed ID-First Architecture**:
```gdscript
# Central registry for all game entities
class_name EntityRegistry extends Node
var _entities: Dictionary[String, EntityRecord] = {}

# Systems use IDs instead of references
UIRegistry.set_selection(entity_id)  # Not gamepiece reference
InteractionRegistry.start_interaction(initiator_id, target_id)
EventBus.dispatch_entity_moved(entity_id, new_position)

# Network-ready from day one
send_to_server({"entity": entity_id, "action": "move", "target": cell})
```

**Benefits for Multiplayer & Distributed Compute**:
- **Network Efficiency**: Send IDs instead of serializing objects (90%+ bandwidth reduction)
- **State Synchronization**: All clients reference same entities by ID
- **Distributed Authority**: Track which MCP server controls each entity
- **Save/Load**: Simple ID-based serialization instead of complex object graphs
- **Memory Safety**: Weak references prevent leaks, systems handle missing entities gracefully

**Recommended Approach**:
1. Implement EntityRegistry alongside existing systems
2. Migrate subsystems incrementally (UI → Events → Interactions)
3. Extend pattern to other systems (interactions, UI elements, etc.)
4. Add network message schemas using IDs
5. Implement authority tracking for distributed compute

**Code Locations Needing EntityRegistry**:
- `UILink._find_gamepiece_by_entity_id()` - O(n) search through all gamepieces
- `OpenLinkBehavior._find_gamepiece_by_entity_id()` - Duplicate O(n) search
- Vision system entity lookups
- NPC target finding by name

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

### 21. New UI System Technical Debt
**Impact**: Medium | **Effort**: Medium | **Leverage**: 🔥🔥🔥

**Problem**: The new UI system has incomplete migrations and missing features:

**Issues Found**:
- **Duplicate Behavior Classes**: `OpenUIBehavior` (old) and `OpenPanelBehavior` (new) coexist
- **Missing Implementations**: Tooltip system placeholder, resize handles not implemented
- **No Z-Layer Management**: Hardcoded z-index values (floating windows = 10)
- **Object References**: UI system passes object references instead of IDs
- **Missing Documentation**: Some referenced UI docs don't exist (ui/panels.md still needs creation)

**Current State**:
```gdscript
# Duplicate behavior classes
OpenUIBehavior  # Hardcoded for NPCs
OpenPanelBehavior  # Generic configuration-based

# Placeholder implementation
func display_tooltip(text: String, position: Vector2) -> void:
    # TODO: Implement tooltip display
    pass
```

**Solution**: Complete migration to new behavior system, implement missing features, create documentation

### 22. Conversation Visual Feedback
**Impact**: Low | **Effort**: Low | **Leverage**: 🔥🔥

**Problem**: Limited visual feedback during interactions:
- Conversation emoji only shown in nameplate, not floating above NPCs
- No visual handlers for consume/sit interactions
- No generic emoji display system for interactions

**Solution**: Create generic emoji visual handler that shows interaction emojis above participants

### 23. Component Property Validation Timing
**Impact**: Medium | **Effort**: Low | **Leverage**: 🔥🔥

**Problem**: PropertySpec validation happens at configuration time, but no runtime validation:
- Components can have properties modified after initialization
- No validation when properties change at runtime
- Type safety only enforced during initial setup

**Solution**: Add property setters with validation, ensure type safety throughout component lifecycle

### 24. Interaction Line Rendering Performance
**Impact**: Medium | **Effort**: Medium | **Leverage**: 🔥🔥

**Problem**: InteractionLineManager draws all interaction lines every frame without culling:
- Lines are drawn even when completely off-screen
- No spatial partitioning or visibility checks
- Could become performance issue with many simultaneous interactions

**Implementation Complexity**: 
- Need to check if line endpoints are within viewport bounds
- Account for line segments that cross viewport even if endpoints are outside
- Consider expanded bounds for smooth entry/exit transitions
- Balance culling accuracy vs computation cost

**Proposed Solution**:
```gdscript
func _should_draw_line(points: PackedVector2Array) -> bool:
    var viewport_rect = get_viewport_rect()
    # Expand rect slightly for smooth transitions
    viewport_rect = viewport_rect.grow(100)
    
    # Check if any point is visible
    for point in points:
        if viewport_rect.has_point(to_local(point)):
            return true
    
    # Check if line crosses viewport (more complex)
    return _line_intersects_rect(points, viewport_rect)
```

**Benefits**: Better performance with many NPCs, scalable to larger simulations

## Conclusion

The highest-leverage improvements now focus on completing partially implemented systems and establishing consistent patterns. With the interaction system refactored and new UI architecture in place, priorities shift to:

1. **Completing the ID-First Architecture** with EntityRegistry (blocks distributed compute business model)
2. **Standardizing Debug Logging** (major maintainability improvement)
3. **Finishing UI System Migration** (remove duplicates, implement missing features)
4. **Improving Type Safety** with struct-like classes for Variants

Key insight: Many systems have solid foundations but need completion. Focus on finishing what's started before adding new complexity.

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

### 18. Z-Index Management and Layer Organization
**Impact**: Low | **Effort**: Low | **Leverage**: 🔥

**Problem**: Z-index handling is disorganized across the codebase with no clear layering strategy:

**Current Issues**:
- Hardcoded z-index values scattered throughout different scenes and scripts
- No documentation of which z-index ranges are used for what purposes
- Risk of z-fighting and incorrect draw order as new UI elements are added
- Difficulty debugging visual layering issues

**Examples**:
- Nameplates, interaction visuals, UI panels all compete for z-ordering
- No clear separation between world-space UI and screen-space UI
- Tooltips and context menus can appear behind other elements

**Proposed Solution**: Create centralized z-index constants:
```gdscript
# src/common/z_layers.gd
class_name ZLayers

# World space layers
const GROUND = 0
const ITEMS = 10
const NPCS = 20
const INTERACTION_VISUALS = 30
const NAMEPLATES = 40

# UI space layers  
const PANELS = 100
const TOOLTIPS = 200
const MODALS = 300
```

**Benefits**: Clear layer organization, easier debugging, consistent visual hierarchy

### 19. UI Panel Architecture Inflexibility
**Impact**: Medium | **Effort**: High | **Leverage**: 🔥🔥

**Problem**: GamepiecePanel extends Panel, preventing flexible UI arrangements:

**Current Limitations**:
- Panels must be Panel nodes, can't be VBoxContainer, TabContainer children, etc.
- ConversationPanel had to duplicate GamepiecePanel functionality to work as VBoxContainer
- Cannot create panels that work as:
  - Free-floating windows
  - Tab panel content
  - Sub-elements within compound UI structures
  - Dockable panels

**Future Vision**: Panels should be composable UI elements that can exist in multiple contexts:
- As standalone floating windows (for modding/customization)
- As tabs within tab containers
- As sub-panels within larger UI structures
- As dockable elements in customizable layouts

**Proposed Solution**: Create a component-based panel system:
```gdscript
# GamepiecePanelBehavior as a component rather than base class
class_name GamepiecePanelBehavior extends Node

# Can be added to any Control-derived node
@export var update_interval: float = 1.0/30.0
var current_controller: GamepieceController = null

# Panel content as separate scene that can be instantiated into any container
class_name ConversationPanelContent extends Control
```

**Benefits**: Flexible UI arrangements, better modding support, cleaner architecture

### 20. Mock Backend Client Architecture Duplication
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
