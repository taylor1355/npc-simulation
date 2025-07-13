# Remaining Features Roadmap: NPC Simulation

## Overview

This document consolidates all unimplemented features from previous design documents into a unified development roadmap. Features are organized by impact and implementation complexity, with detailed technical guidance for each phase.

## Current State Summary

The project has successfully implemented:
- ✅ NPC nameplate system with state emojis
- ✅ Generic interaction visual system with conversation lines
- ✅ Floating window system for conversation panels
- ✅ Comprehensive UI behavior framework
- ✅ UIElementProvider for centralized UI creation
- ✅ SimulationTime singleton for deterministic time
- ✅ StatusBar UI with time and coordinate display
- ✅ Unified BottomUI combining tabs and status

## Development Phases

### Phase 0: UI Link Enhancement & Entity Highlighting 🔗
**Goal**: Extend UILink hover highlighting to all entity references and ensure consistent link creation throughout UI  
**Priority**: HIGH | **Effort**: Low-Medium | **Impact**: High

#### 0.1 UILink Hover Highlighting
**Priority**: HIGH | **Effort**: Low | **Impact**: High

Currently, hovering over an NPC's status emoji highlights conversation participants and the line between them. This same highlighting behavior should be triggered when hovering over any UILink that references an interaction.

**Current State**:
- ✅ ConversationVisualHandler highlights participants when hovering status emoji
- ✅ UILink system exists for creating entity and interaction links
- ✅ SpriteColorManager and UIStateTracker handle highlighting
- ❌ UILinks don't trigger highlighting on hover

**Implementation**:

```gdscript
# Extend OpenLinkBehavior to support highlighting
func _on_link_hover_started(link_url: String) -> void:
    var link = UILink.from_url(link_url)
    if link.target_type == UILink.TargetType.INTERACTION:
        UIStateTracker.highlight_interaction(link.target_id)
    elif link.target_type == UILink.TargetType.ENTITY:
        UIStateTracker.highlight_entity(link.target_id)

func _on_link_hover_ended(link_url: String) -> void:
    var link = UILink.from_url(link_url)
    if link.target_type == UILink.TargetType.INTERACTION:
        UIStateTracker.unhighlight_interaction(link.target_id)
    elif link.target_type == UILink.TargetType.ENTITY:
        UIStateTracker.unhighlight_entity(link.target_id)
```

**Required Changes**:
1. Add hover signal handling to RichTextLabel meta events
2. Extend OpenLinkBehavior to emit hover start/end events
3. Connect hover events to UIStateTracker highlighting system
4. Ensure ConversationVisualHandler responds to UIStateTracker signals

#### 0.2 Entity Highlighting System
**Priority**: HIGH | **Effort**: Low | **Impact**: High

Extend the existing highlighting system to support individual entities, not just interactions.

**Implementation**:

```gdscript
# Add to UIStateTracker
signal entity_highlighted(entity_id: String)
signal entity_unhighlighted(entity_id: String)

func highlight_entity(entity_id: String) -> void:
    if _highlighted_entity_id == entity_id:
        return
    
    unhighlight_entity()  # Clear previous
    _highlighted_entity_id = entity_id
    entity_highlighted.emit(entity_id)

# Create EntityHighlightHandler
class_name EntityHighlightHandler extends Node

func _ready() -> void:
    UIStateTracker.entity_highlighted.connect(_on_entity_highlighted)
    UIStateTracker.entity_unhighlighted.connect(_on_entity_unhighlighted)

func _on_entity_highlighted(entity_id: String) -> void:
    var entity = EntityRegistry.get_entity(entity_id)
    if entity and entity.has_node("Sprite2D"):
        SpriteColorManager.add_color_effect(
            entity_id, 
            "highlight",
            Color.YELLOW,
            0.3
        )
```

**Benefits**:
- Consistent highlighting behavior across all UI elements
- Better visual feedback for entity references
- Improved user understanding of relationships

#### 0.3 Comprehensive UILink Creation
**Priority**: MEDIUM | **Effort**: Medium | **Impact**: High

Many places in the UI show entity names as plain text instead of clickable links. This inconsistency makes the UI less interactive and harder to navigate.

**Current Issues**:
```gdscript
# interacting_state.gd - Plain text names
return "%s with %s" % [interaction_name, names[0]]
return "%s with %d others" % [interaction_name, names.size()]

# conversation messages - Speaker names not linked
var speaker_text = "[b]%s[/b]: " % speaker_name

# requesting state - Target names not linked
"Requesting %s with %s" % [interaction_name, target.get_display_name()]
```

**Implementation Plan**:

1. **InteractingState Status Text**:
```gdscript
# Replace plain names with UILinks
if names.size() == 1:
    var participant = context.get_participants()[0]
    return "%s with %s" % [
        interaction_name, 
        UILink.entity(participant.get_entity_id(), names[0])
    ]
```

2. **Conversation Messages**:
```gdscript
# Make speaker names clickable
var speaker_link = UILink.entity(speaker_id, speaker_name)
var speaker_text = "[b]%s[/b]: " % speaker_link
```

3. **Create UILink Usage Guidelines**:
```gdscript
# Document when to create UILinks
# ALWAYS create links for:
# - NPC names in any context
# - Item names when referenced
# - Interaction participants
# - Any entity reference that users might want to inspect
```

**Locations Needing Updates**:
1. `interacting_state.gd`: get_activity_description()
2. `conversation_interaction.gd`: Message formatting
3. `requesting_state.gd`: Status descriptions
4. `npc_info_tab.gd`: Any entity references
5. `working_memory_panel.gd`: Memory entries referencing entities
6. `event_formatter.gd`: Event descriptions with entity names

**Testing Requirements**:
- All entity names in UI should be hoverable
- Hovering highlights the entity in the game world
- Clicking focuses the camera on the entity
- Links work correctly in all UI contexts (panels, tooltips, status text)

### Phase 0: Critical Infrastructure - Entity Registry 🚨
**Goal**: Prevent "freed instance" crashes and establish safe entity reference patterns  
**Priority**: CRITICAL | **Effort**: Low-Medium | **Impact**: Very High

#### 0.1 Core Entity Registry Implementation
**Priority**: CRITICAL | **Effort**: Low | **Impact**: Very High

The system currently suffers from crashes when NPCs interact with freed entities (e.g., two NPCs trying to consume the same apple). This must be fixed immediately.

**Core Implementation**:

```gdscript
# src/common/entity_registry.gd
extends Node

var _entities: Dictionary = {}  # entity_id -> GamepieceController

func _ready():
    # Listen for entity lifecycle events
    EventBus.gamepiece_destroyed.connect(_on_gamepiece_destroyed)

func register(controller: GamepieceController) -> void:
    var entity_id = controller.get_entity_id()
    _entities[entity_id] = controller
    
    # Backup cleanup in case event doesn't fire
    if not controller.tree_exited.is_connected(_on_entity_freed.bind(entity_id)):
        controller.tree_exited.connect(_on_entity_freed.bind(entity_id), CONNECT_ONE_SHOT)

func unregister(entity_id: String) -> void:
    _entities.erase(entity_id)

func get_entity(entity_id: String) -> GamepieceController:
    return _entities.get(entity_id)

func entity_exists(entity_id: String) -> bool:
    return _entities.has(entity_id)

func _on_gamepiece_destroyed(event: GamepieceEvents.DestroyedEvent):
    unregister(event.gamepiece.entity_id)

func _on_entity_freed(entity_id: String):
    unregister(entity_id)
```

**Integration in GamepieceController**:
```gdscript
# In GamepieceController._ready()
func _ready():
    super._ready()
    EntityRegistry.register(self)
```

#### 0.2 Fix Critical Crash in RequestingState
**Priority**: CRITICAL | **Effort**: Low | **Impact**: Very High

Fix the immediate bug causing crashes:

```gdscript
# In requesting_state.gd
func get_context_data() -> Dictionary:
    var context = {
        "request_type": _active_request.request_type,
        "target_id": _active_request.target_id,
    }
    
    # Check if target still exists before accessing
    var target = EntityRegistry.get_entity(_active_request.target_id)
    if target and target is ItemController:
        context["target_position"] = {
            "x": target._gamepiece.cell.x,
            "y": target._gamepiece.cell.y
        }
    
    return context
```

#### 0.3 Refactor Core Systems to Use Entity IDs
**Priority**: CRITICAL | **Effort**: Medium | **Impact**: Very High

Update critical systems that store entity references:

**InteractionContext refactoring**:
```gdscript
# ENTITY_REGISTRY_TODO: CRITICAL - Replace host reference with host_id
var host_id: String = ""

func get_host() -> GamepieceController:
    return EntityRegistry.get_entity(host_id)
```

**Interaction participants refactoring**:
```gdscript
# ENTITY_REGISTRY_TODO: CRITICAL - Store participant IDs instead of references
var participant_ids: Array[String] = []

func get_valid_participants() -> Array[NpcController]:
    var valid_participants: Array[NpcController] = []
    for id in participant_ids:
        var npc = EntityRegistry.get_entity(id)
        if npc:
            valid_participants.append(npc)
    return valid_participants
```

#### 0.4 High Priority System Updates
**Priority**: HIGH | **Effort**: Medium | **Impact**: High

Update systems that can cause bugs with stale references:

1. **EntityPanel UI tracking**
2. **VisionManager entity tracking**
3. **InteractionBid bidder/target references**
4. **MultiPartyBid participant arrays**

### Phase 1: Backend Component Architecture 🏗️
**Goal**: Enable per-NPC backend management and player control  
**Priority**: Very High | **Effort**: Medium | **Impact**: Very High

#### 1.1 Backend Component System
**Priority**: Very High | **Effort**: Medium | **Impact**: Very High

Replace the global backend singleton with a component-based approach where each NPC manages its own backend.

**Core Implementation**:

```gdscript
class_name BackendComponent extends NpcComponent

var backend_type: NpcClientFactory.BackendType
var backend_client: NpcClientBase
var npc_data: Dictionary = {}  # Preserves data across switches

@export var initial_backend: NpcClientFactory.BackendType = NpcClientFactory.BackendType.MOCK

func _component_ready() -> void:
    # Create initial backend
    _create_backend(initial_backend)
    
    # Listen for backend switch events
    EventBus.event_dispatched.connect(_on_event)

func switch_backend(new_type: NpcClientFactory.BackendType) -> void:
    # Preserve NPC data
    if backend_client:
        npc_data = backend_client.get_npc_info(get_npc_controller().id)
        backend_client.cleanup_npc(get_npc_controller().id)
    
    # Create new backend
    _create_backend(new_type)
    
    # Restore NPC data
    if backend_client and not npc_data.is_empty():
        backend_client.restore_npc_data(get_npc_controller().id, npc_data)
```

**NpcController Integration**:
```gdscript
# In NpcController
@export var backend_component: BackendComponent

func _ready() -> void:
    # Create BackendComponent if not present (backward compatibility)
    if not backend_component:
        backend_component = BackendComponent.new()
        add_child(backend_component)
    
    # Use component's backend instead of global
    # OLD: if Globals.npc_client:
    # NEW: if backend_component.backend_client:
```

**Benefits**:
- Each NPC has its own backend instance
- Clean backend switching with data preservation
- Different NPCs can use different backends simultaneously
- Enables A/B testing of backend implementations
- Component lifecycle handles cleanup automatically

#### 1.2 Player Control Backend
**Priority**: High | **Effort**: Low | **Impact**: High

Implement player control through the backend abstraction.

**PlayerBackend Implementation**:

```gdscript
class_name PlayerBackend extends NpcClientBase

var current_npc_id: String
var input_enabled: bool = true

func _ready() -> void:
    set_process_input(true)

func create_npc(npc_id: String, traits: Array[String], working_memory: String = "", 
                long_term_memories: Array[String] = []) -> void:
    current_npc_id = npc_id
    # Store basic NPC data
    _npc_data[npc_id] = {
        "traits": traits,
        "working_memory": working_memory,
        "memories": long_term_memories
    }

func process_observation(npc_id: String, events: Array[NpcEvent]) -> void:
    # Player backend doesn't need to process observations
    # Actions come from input instead
    pass

func _input(event: InputEvent) -> void:
    if not input_enabled or current_npc_id.is_empty():
        return
    
    # Movement input
    if event.is_action_pressed("player_move_up"):
        _emit_move_action(Vector2i(0, -1))
    elif event.is_action_pressed("player_move_down"):
        _emit_move_action(Vector2i(0, 1))
    elif event.is_action_pressed("player_move_left"):
        _emit_move_action(Vector2i(-1, 0))
    elif event.is_action_pressed("player_move_right"):
        _emit_move_action(Vector2i(1, 0))
    
    # Interaction input
    elif event.is_action_pressed("player_interact"):
        _emit_interact_action()
    elif event.is_action_pressed("player_cancel"):
        _emit_cancel_action()
```

**Input Actions** (add to Project Settings):
- `player_move_up`: W, Up Arrow
- `player_move_down`: S, Down Arrow
- `player_move_left`: A, Left Arrow
- `player_move_right`: D, Right Arrow
- `player_interact`: E, Space
- `player_cancel`: Q, Escape

#### 1.3 Possessed Component
**Priority**: Medium | **Effort**: Low | **Impact**: High

Manage possession state and visual indicators.

```gdscript
class_name PossessedComponent extends NpcComponent

@export var possession_indicator: PackedScene  # Visual indicator scene
var is_possessed: bool = false
var indicator_instance: Node2D

func possess() -> void:
    if is_possessed:
        return
    
    is_possessed = true
    
    # Switch to player backend
    var backend = get_npc_controller().backend_component
    backend.switch_backend(NpcClientFactory.BackendType.PLAYER)
    
    # Add visual indicator
    if possession_indicator:
        indicator_instance = possession_indicator.instantiate()
        get_npc_controller().add_child(indicator_instance)
    
    # Emit event
    EventBus.dispatch(NpcEvents.create_possessed(get_npc_controller()._gamepiece))

func unpossess() -> void:
    if not is_possessed:
        return
    
    is_possessed = false
    
    # Switch back to previous backend (usually MOCK)
    var backend = get_npc_controller().backend_component
    backend.switch_backend(NpcClientFactory.BackendType.MOCK)
    
    # Remove visual indicator
    if indicator_instance:
        indicator_instance.queue_free()
    
    # Emit event
    EventBus.dispatch(NpcEvents.create_unpossessed(get_npc_controller()._gamepiece))
```

### Phase 2: Developer Experience Improvements 🛠️
**Goal**: Make development and debugging significantly easier  
**Priority**: High | **Effort**: Low-Medium | **Impact**: Very High

#### 2.1 Simplified Debug Console Commands
**Priority**: High | **Effort**: Low | **Impact**: High

Design a simple, readable command language that covers the core debugging needs without unnecessary complexity.

**Core Commands**:

1. **Entity Listing & Selection**:
```bash
# List entities
list                    # List all entities, grouped by type
list npc                # List only NPCs
list item               # List only items

# Select by ID or name (auto-detect)
select alice            # Selects NPC with name "Alice" 
select npc_abc123       # Selects by ID
select *                # Select all entities

# Select with filters (extensible syntax)
select npc need.hunger<30     # NPCs with hunger below 30
select npc state=idle         # NPCs in idle state
select item type=consumable   # Items with consumable component
```

2. **Property Inspection**:
```bash
# View properties (after selection)
info                    # Show detailed info about selected entity
get need.*              # Show all needs for selected NPC(s)
get need.hunger         # Show specific need value
get state               # Show current state and activity
get position            # Show grid position
```

3. **Property Modification**:
```bash
# Set properties on selected entities
set need.hunger 100          # Set hunger to 100
set position 10,15           # Teleport to grid position
set need.energy 100 need.hygiene 50  # Set multiple needs at once
fill need.*                  # Set all needs to 100
```

4. **Entity Management**:
```bash
# Spawn and delete
spawn npc 10,15         # Spawn NPC at position
spawn apple 5,10        # Spawn item at position
delete                  # Delete selected entity
```

5. **Camera & Control**:
```bash
# Camera control
anchor                  # Anchor camera to selected entity (Space key)
pan 10,15              # Pan camera to grid position
zoom in                # Zoom camera in
zoom out               # Zoom camera out

# Possession for testing (uses new PossessedComponent)
possess                 # Take control of selected NPC
unpossess              # Return control to AI

# Backend management (uses new BackendComponent)
backend                 # Show current backend for selected NPC
backend mock            # Switch selected NPC to mock backend
backend mcp             # Switch selected NPC to MCP backend
backend player          # Switch selected NPC to player backend
```

**Implementation Strategy**:

```gdscript
# Simple command parser
class_name SimpleCommandParser

var selected_entities: Array = []

func parse_command(input: String) -> void:
    var parts = input.split(" ")
    var cmd = parts[0]
    var args = parts.slice(1)
    
    match cmd:
        "list":
            _cmd_list(args)
        "select":
            _cmd_select(args)
        "info":
            _cmd_info()
        "set":
            _cmd_set(args)
        "spawn":
            _cmd_spawn(args)
        "possess":
            _cmd_possess()
        # etc...
```

#### 2.2 Console Command Focus Fix
**Priority**: High | **Effort**: Low | **Impact**: High

Fix the focus bug where input field loses focus after command execution:

```gdscript
func _on_input_submitted(text: String) -> void:
    # ... existing command processing ...
    
    # Fix: Maintain focus after command
    input_field.clear()
    input_field.call_deferred("grab_focus")
```

#### 2.3 Centralized Logging System
**Priority**: High | **Effort**: Medium | **Impact**: Very High

Replace 64+ inconsistent logging patterns with a unified system that supports filtering, levels, and runtime control.

**Logger API Design**:
```gdscript
# src/common/debug/logger.gd
class_name Logger

enum Level {
    DEBUG,
    INFO,
    WARN,
    ERROR
}

static var _instance: Logger
static var _min_level: Level = Level.INFO
static var _context_filters: Array[String] = []
static var _enable_timestamps: bool = true

static func debug(message: String, context: String = "") -> void:
    _log(Level.DEBUG, message, context)

static func info(message: String, context: String = "") -> void:
    _log(Level.INFO, message, context)

static func warn(message: String, context: String = "") -> void:
    _log(Level.WARN, message, context)

static func error(message: String, context: String = "") -> void:
    _log(Level.ERROR, message, context)
```

**Console Integration**:
```bash
# Debug console commands for logging control
log level debug|info|warn|error
log filter <context>
log clear
log show                        # Show current settings
```

### Phase 3: UI Visibility Enhancements 👁️
**Goal**: Make the simulation state visible and understandable without clicking individual entities  
**Priority**: High | **Effort**: Medium | **Impact**: High

#### 3.1 Population Overview Panel
**Priority**: High | **Effort**: Medium | **Impact**: High

Create a collapsible panel in the top-left corner showing all NPCs at a glance:

```
┌─ NPCs (3) ────────────[▼]─┐
│ Alice    💬  H:72 E:89    │
│ Bob      💬  H:45 E:67    │
│ Charlie  🪑  H:90 E:23    │
└───────────────────────────┘
```

**Features**:
- Shows name, state emoji, critical needs (if <30%)
- Click name to focus/select NPC
- Hover for tooltip with full needs
- Collapsible to save screen space
- Sort options (name, state, lowest need)

#### 3.2 Enhanced Overview Tab
**Priority**: Medium | **Effort**: Low | **Impact**: Medium

Improve the existing NPC Info panel to show more contextual information.

#### 3.3 Interaction Preview System
**Priority**: Low | **Effort**: Medium | **Impact**: Medium

Show available interactions when hovering over entities.

### Phase 4: Time System Integration ⏱️
**Goal**: Integrate SimulationTime with game systems  
**Priority**: Medium | **Effort**: Low | **Impact**: Medium

#### 4.1 NPC Decision Timing Integration
**Priority**: Medium | **Effort**: Low | **Impact**: Medium

Update NPC decision cycles to use SimulationTime instead of process time:

```gdscript
# In NpcController
var last_decision_time: float = 0.0

func _ready() -> void:
    # Subscribe to time updates for decision making
    if SimulationTime:
        SimulationTime.subscribe_to_updates("npc_decision_" + id, decision_interval)
        SimulationTime.time_update_for_subscriber.connect(_on_decision_time)

func _on_decision_time(subscriber_id: String, _time_dict: Dictionary) -> void:
    if subscriber_id == "npc_decision_" + id:
        _make_decision()
```

#### 4.2 Need Decay Integration
**Priority**: Medium | **Effort**: Low | **Impact**: Medium

Update need decay to use simulation time for consistent gameplay:

```gdscript
# In NeedsManager
func _ready() -> void:
    # Subscribe to minute updates for need decay
    if SimulationTime:
        SimulationTime.subscribe_to_updates("need_decay", 60.0)  # Every game minute
        SimulationTime.time_update_for_subscriber.connect(_on_decay_time)

func _on_decay_time(subscriber_id: String, time_dict: Dictionary) -> void:
    if subscriber_id == "need_decay":
        var elapsed_minutes = SimulationTime.get_total_minutes() - last_decay_time
        _apply_decay(elapsed_minutes)
```

### Phase 5: System Improvements 🔧
**Goal**: Improve development workflow and debugging capabilities  
**Priority**: Medium | **Effort**: Medium-High | **Impact**: Medium

#### 5.1 Save/Load System
**Priority**: Medium | **Effort**: High | **Impact**: Medium

Implement game state persistence for testing and player convenience.

#### 5.2 Performance Monitoring Dashboard
**Priority**: Low | **Effort**: Low | **Impact**: Medium

Add performance metrics panel for optimization work.

### Phase 6: UI Polish and Completeness 💅
**Goal**: Final polish pass on UI elements  
**Priority**: Low | **Effort**: Low | **Impact**: Low

#### 6.1 Visual Polish
- Need bars with gradient colors
- Smooth animations for state changes
- Consistent spacing (8px margins throughout)
- Toast notifications for important events

#### 6.2 Z-Index Fixes
- Ensure nameplates render correctly
- Fix any remaining layering issues

## Entity Registry Migration Details

### Migration Strategy

#### Phase 1: Critical Fixes (Immediate)
1. ✅ Create EntityRegistry singleton
2. ✅ Register all entities on creation
3. ✅ Fix ControllerRequestingState crash
4. Test with concurrent apple consumption scenario

#### Phase 2: Core Systems (1-2 days)
1. InteractionContext host tracking
2. Interaction participant arrays
3. Basic registry usage patterns
4. Validate interaction participants before use

#### Phase 3: UI Integration (2-3 days)
1. EntityPanel controller tracking
2. UI registry alignment
3. Panel lifecycle management
4. Handle focused entity destruction gracefully

#### Phase 4: Complete Migration (1 week)
1. Vision system refactoring
2. Bid system updates
3. Mock backend alignment
4. Documentation updates

### Testing Requirements

Each refactored area needs tests for:
1. Entity destruction during active references
2. Multiple entities referencing the same target
3. Cascading entity destruction
4. UI updates when focused entity is freed

### Code Patterns

**Before**:
```gdscript
var target_controller: GamepieceController = null

func set_target(controller: GamepieceController):
    target_controller = controller

func use_target():
    if target_controller:  # Can crash if freed!
        target_controller.do_something()
```

**After**:
```gdscript
var target_id: String = ""

func set_target(controller: GamepieceController):
    target_id = controller.get_entity_id() if controller else ""

func use_target():
    var target = EntityRegistry.get_entity(target_id)
    if target:  # Safe - returns null if freed
        target.do_something()
```

## Implementation Priority Matrix

```
Impact ↑
CRITICAL│ Entity         │                 │
        │ Registry       │                 │
        │                │                 │
Very    │ Backend        │                 │
High    │ Components     │                 │
        │ Player Control │                 │
        │                │                 │
High    │ Debug Language │ Population Panel│
        │ Logging System │ Overview Tab    │
        │                │                 │
Medium  │ Time           │ Save/Load       │
        │ Integration    │ Interaction     │
        │                │ Preview         │
Low     │                │ UI Polish       │
        │                │ Perf Monitoring │
        └────────────────┴─────────────────┴──────────────→
          Low              Medium             High    Effort
```

## Success Metrics

**Phase 0 (Entity Registry) Complete When**:
- No more "freed instance" crashes
- All critical systems use entity IDs instead of references
- Registry automatically cleans up freed entities
- UI gracefully handles entity destruction
- Test scenario with concurrent consumption passes

**Phase 1 (Backend Components) Complete When**:
- Each NPC has its own BackendComponent
- Backend switching works without data loss
- Player can control any NPC via PlayerBackend
- Different NPCs can use different backends simultaneously
- Possession has visual indicators

**Phase 2 (Developer Experience) Complete When**:
- Query-based debug language fully functional
- Can possess NPCs for testing interactions
- All logging is centralized and filterable
- Console maintains focus properly
- Debugging time reduced by 50%

**Phase 3 (UI Visibility) Complete When**:
- Can see all NPC states without clicking
- Population panel shows real-time updates
- Overview tab provides rich context
- New users understand system in <30 seconds

**Phase 4 (Time Integration) Complete When**:
- NPC decisions use SimulationTime
- Need decay is time-based, not frame-based
- Time can be paused/scaled for testing
- All time-based systems are deterministic

**Phase 5 (System Improvements) Complete When**:
- Can save/load complex scenarios
- Performance bottlenecks are measurable
- Test scenarios are reproducible

**Phase 6 (UI Polish) Complete When**:
- UI has consistent visual language
- All panels resize properly
- No z-ordering issues remain
- Polish matches professional games

## Technical Considerations

### Architecture Patterns
- **Event-Driven**: All features integrate with EventBus
- **Component-Based**: Modular, reusable components
- **Query-Based**: Consistent query language for debug console
- **State Persistence**: Careful serialization of runtime state
- **ID-Based References**: Use entity IDs, not direct references

### Common Pitfalls
- Don't access nodes directly - use events/interfaces
- Don't store entity references - store IDs and lookup
- Avoid circular dependencies between systems
- Profile before optimizing performance
- Test with multiple NPCs (10+) early
- Always check if entity exists before using

### Getting Started

The recommended implementation order:
1. **Entity Registry Core** (Phase 0.1) - Prevents crashes immediately
2. **Fix RequestingState Crash** (Phase 0.2) - Resolves known bug
3. **Backend Component System** (Phase 1.1) - Enables all advanced features
4. **Player Control Backend** (Phase 1.2) - Enables direct testing
5. **Query-Based Debug Language** (Phase 2.1) - Highest impact for development
6. **Population Panel** (Phase 3.1) - Most requested feature
7. **Logging System** (Phase 2.3) - Improves all future work

Each phase builds on previous work and can be implemented incrementally with visible progress at each step.

## Estimated Scope

- **Files to modify**: ~40-50 (including entity registry refactoring)
- **Lines to change**: ~500-800
- **Time estimate**: 
  - Phase 0 (Entity Registry): 3-5 days
  - Phase 1-6: 2-3 weeks
- **Risk**: Medium-High for Phase 0 (touches core systems), Low-Medium for others

## Critical Path

**Must be done in order**:
1. Entity Registry Core → Fix RequestingState → Core System Refactoring
2. Backend Component System → Player Control Backend → Possessed Component

**Can be done in parallel**:
- Debug Console improvements
- UI Visibility enhancements
- Time System integration

The Entity Registry implementation is the highest priority as it fixes critical crashes and establishes patterns for all future development.