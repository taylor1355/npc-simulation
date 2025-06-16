# UI Redesign Proposal for NPC Simulation

## Executive Summary

This document proposes a comprehensive UI redesign that better exposes the game's systems while maintaining simplicity and clarity. The design draws inspiration from Stardew Valley's clarity, The Sims' information density, and MMORPG's social interaction systems.

## Current Implementation Analysis

### Existing UI Structure

The current UI uses a tabbed panel system (TabContainer) that appears when a gamepiece is selected:

1. **Tab System**
   - Dynamically creates tabs based on the selected entity
   - Tabs sorted by priority (0 = info panels, 1 = detail panels)
   - Current panels:
     - NPC Info (name, traits)
     - Item Info (item details)
     - Needs (4 progress bars)
     - Working Memory (text display)
     - Component panels (Consumable, Sittable, etc.)

2. **Visual Elements**
   - No overhead displays on NPCs/items
   - Selection only indicated by camera focus
   - No visual indicators for interactions or conversations
   - Panels appear in bottom-right corner

3. **Controls**
   - Click to select gamepiece
   - Right-click drag to pan camera
   - Mouse wheel to zoom
   - 'A' to anchor camera
   - Backtick for debug console

4. **Debug Console**
   - Minimalist design (Sims-inspired)
   - Slides down from top
   - Commands: help, clear, backend, quit
   - No NPC control commands
   - Loses focus after command entry (known bug)

## Current Systems to Expose

1. **NPC State & Needs** - Hunger, Hygiene, Fun, Energy
2. **Interactions** - Item interactions (sit, consume) and NPC interactions (conversations)
3. **Movement & Pathfinding** - Current destination, movement state
4. **Working Memory** - NPC observations and decision-making
5. **Conversations** - Multi-party dialogue system
6. **Debug Console** - Backend switching and command interface

## Design Principles

- **Glanceable Information**: Critical info visible without clicking
- **Progressive Disclosure**: Details available on demand
- **Visual Hierarchy**: Most important info most prominent
- **Contextual Relevance**: Show what matters when it matters

## Key Issues with Current UI

1. **Discoverability**: No visual indicators for active interactions or conversations
2. **Context Loss**: Can't see NPC states without selecting them
3. **Conversation Invisibility**: Multi-party conversations have no visual representation
4. **Limited Overview**: No way to see all NPCs' status at once
5. **Interaction Feedback**: No preview of available interactions before clicking

## Proposed UI Layout

### 1. Main Game View Overlays

#### A. NPC Overhead Display
Simple nameplates above each NPC:
```
┌─────────────────┐
│ Alice      [💬] │  <- State icon
└─────────────────┘
```

- **States**: Each controller state defines its emoji
  - 🚶 Moving (MovingState)
  - 💬 Conversing (InteractingState with conversation)
  - 🪑 Sitting (InteractingState with sit interaction)
  - 🍽️ Consuming (InteractingState with consume interaction)
  - 💤 Idle (IdleState)
  - 🤔 Requesting (RequestingState)
  - 🎲 Wandering (WanderingState)
- **Implementation**: `BaseControllerState.get_state_emoji()` overridden by each state

#### B. Conversation Visualization
When NPCs are conversing:
- **Dotted line** connecting participants (subtle, not distracting)
- **Group bubble icon** (💬) appears centered above the group
- **Click target**: The group bubble opens conversation window
- **Animation**: Gentle pulse on new messages

### 2. Enhanced Tab Panel System (Right Side - Current Location)

Enhance the existing TabContainer with better visual design:

```
┌─────────────────────────────────────┐
│ Overview │ Needs │ Memory │         │  <- Enhanced tabs
├─────────────────────────────────────┤
│ Alice                               │
│ Currently: In Conversation          │
│                                     │
│ [Placeholder] ┌──────────────────┐  │
│  Portrait     │ Hunger    72%    │  │
│               │ Hygiene   45%    │  │
│               │ Fun       61%    │  │
│               │ Energy    89%    │  │
│               └──────────────────┘  │
│                                     │
│ Current Activity:                   │
│ 💬 Conversation with Bob, Charlie   │
│ [View Conversation]                 │
│                                     │
│ Traits: Friendly, Outgoing          │
└─────────────────────────────────────┘
```

**Tab Improvements**:
- **Overview Tab**: Combines current NPC Info and status
- **Visual Polish**: Better spacing, icons, and typography
- **Action Buttons**: Direct interaction controls
- **Keep existing dynamic tab creation** for components

### 3. Conversation Window (Floating Panel)

Lightweight conversation viewer that can be opened multiple ways:
- Click conversation bubble above NPC group
- Click "View Details" in Overview tab
- New conversation notification

```
┌─────────────────────────────────────┐
│ 💬 Conversation                  [X] │
├─────────────────────────────────────┤
│ Alice, Bob, Charlie                 │
├─────────────────────────────────────┤
│ [Alice]    Hi everyone!         2:34│
│ [Bob]      Hey Alice!           2:31│
│ [Charlie]  Good to see you both 2:28│
│ [Alice]    Want to grab lunch?  2:15│
│                                     │
└─────────────────────────────────────┘
```

**Features**:
- **Floating**: Can be moved around
- **Timestamps**: Game time display
- **Multiple windows**: Track several conversations
- **Smart positioning**: Opens near conversation group

### 4. Interaction Preview

When hovering over items or NPCs:

```
┌─────────────────┐
│ Wooden Chair    │
│ ─────────────── │
│ Available:      │
│ • Sit (+Fun)    │
│ • Push          │
└─────────────────┘
```

### 5. Population Overview (Top-Left Corner)

Simple NPC list:

```
┌─ NPCs (3) ────────────[▼]─┐
│ Alice    💬                │
│ Bob      💬                │
│ Charlie  🪑                │
└───────────────────────────┘
```

**Features**:
- Shows current state emoji
- Click name to focus NPC
- Collapsible to save space

### 6. Enhanced Debug Console

Improve the existing console with:
- **Fix focus bug**: Maintain input focus after command
- **Namespaced commands**: Use `help [namespace]` pattern
  - `help` - Show command namespaces
  - `help npc` - Show NPC-specific commands
- **NPC commands**:
  - `npc.list` - List all NPCs
  - `npc.select [name]` - Select and focus NPC
  - `npc.converse [npc1] [npc2]` - Start conversation
  - `npc.needs [name]` - Show NPC needs

## Visual Design Elements

### Color Coding
- **Needs**: Use intuitive colors
  - Hunger: Orange/Red gradient
  - Hygiene: Blue/Teal
  - Fun: Yellow/Green
  - Energy: Purple/Pink

### State Icons
- 🚶 Moving
- 💬 Conversing
- 🪑 Sitting
- 🍽️ Consuming
- 💭 Thinking/Deciding
- 😴 Idle

### Animation & Feedback
- **Gentle pulse** on state changes
- **Smooth transitions** for UI elements
- **Toast notifications** for selected entity events only

## Interaction Patterns

### Starting Conversations
1. **Console Command**: `npc.converse Alice Bob`
2. **Future**: Context menu when right-clicking NPCs

### Viewing Conversations
1. **Visual Indicator**: Click floating 💬 bubble above conversing group
2. **Panel Button**: "View Conversation" in Overview tab when NPC is conversing
3. **Population Panel**: Click NPC name to focus, then view conversation

### Information Management
- **Focus-based**: Only show notifications for selected entity
- **On-demand details**: Click to see more information

## Implementation Phases

### Phase 1: State Emoji System
1. Add `get_state_emoji()` method to BaseControllerState
   - Virtual method returning String
   - Default implementation returns "❓"
2. Implement emoji for each state:
   - `ControllerIdleState`: Return "💤"
   - `ControllerMovingState`: Return "🚶"
   - `ControllerRequestingState`: Return "🤔"
   - `ControllerInteractingState`: Check interaction type and return appropriate emoji
   - `ControllerWanderingState`: Return "🎲"
   - `ControllerWaitingState`: Return "⏳"
3. Add `get_interaction_emoji()` to Interaction base class
   - Virtual method returning String based on interaction name
4. Override in specific interactions:
   - `ConversationInteraction`: Return "💬"
   - Consumable interactions: Return "🍽️"
   - Sittable interactions: Return "🪑"

### Phase 2: Basic Nameplate Scene
1. Create NpcNameplate.tscn:
   - Root: Control node with anchor at center-bottom
   - Child: Panel with centered Container
   - Grandchild: HBoxContainer with name Label and emoji Label
2. Position nameplate above NPC sprite:
   - Set position to Vector2(0, -40) relative to NPC
   - Use z_index to ensure nameplate draws above NPC
3. Update nameplate text with NPC name from `controller.get_display_name()`
4. Add to NPC scene (npc.tscn) as child of the NPC node

### Phase 3: Nameplate State Integration
1. Connect nameplate to state machine signals:
   - Listen for `state_machine.state_changed` signal
   - Store reference to nameplate in NpcController
2. Update emoji when state changes:
   - Call `current_state.get_state_emoji()` on state change
   - Update emoji Label text
3. Handle InteractingState special case:
   - In `ControllerInteractingState.get_state_emoji()`:
   - Return `interaction.get_interaction_emoji()` if interaction exists
   - Fall back to default "🔧" if no emoji defined
4. Test with existing interactions (consume apple, sit on chair)

### Phase 4: Conversation Visual Indicator
1. Create ConversationIndicator.tscn:
   - Root: Node2D
   - Child: Line2D with dotted texture
   - Configure: Default color, width, texture mode
2. Add to Field node when conversation starts:
   - Listen for INTERACTION_STARTED events
   - Check if interaction is ConversationInteraction
   - Instantiate indicator and add as child
3. Connect participant positions:
   - Update Line2D points array each frame
   - Get positions from participant GamepieceControllers
4. Remove when conversation ends:
   - Listen for INTERACTION_FINISHED events
   - Free the indicator node

### Phase 5: Conversation Group Bubble
1. Add centered 💬 sprite above conversation groups:
   - Create ConversationBubble.tscn with Sprite2D
   - Calculate center position from all participants
   - Position above highest participant
2. Make it clickable:
   - Add Area2D with CollisionShape2D
   - Set collision layer to Click layer (0x4)
3. Connect click to show conversation details:
   - Store conversation_id in bubble
   - Emit custom signal when clicked
4. Position updates as NPCs move:
   - Update position in _process()
   - Recalculate center from participant positions

### Phase 6: Debug Console Focus Fix
1. Modify _on_input_submitted to refocus input:
   - Add `input_field.grab_focus()` at end of method
   - Use `call_deferred` if immediate focus fails
2. Test with existing commands (help, clear, backend, quit)
3. Ensure focus persists after command execution:
   - Test with different command types
   - Verify input field remains active

### Phase 7: Console Command Namespacing
1. Refactor command registration to support namespaces:
   - Change commands Dictionary to nested structure
   - Support "namespace.command" format
2. Update help command to show namespaces:
   - List available namespaces when no args
   - Show namespace commands with `help [namespace]`
3. Implement namespace parsing in _process_command:
   - Split command by "." to get namespace and command
   - Route to appropriate handler
4. Update existing commands:
   - Keep current commands at root level for compatibility
   - Add new namespaced versions

### Phase 8: NPC Console Commands
1. Add npc.list command:
   - Get NPCs via `get_tree().get_nodes_in_group(NpcController.GROUP_NAME)`
   - Format list with names and current states
2. Add npc.select command:
   - Find NPC by name
   - Emit GAMEPIECE_CLICKED event to focus
   - Use existing camera anchor functionality
3. Add npc.converse command:
   - Parse NPC names from args
   - Create conversation interaction via controllers
   - Use existing interaction bid system
4. Add npc.needs command:
   - Find NPC by name
   - Access needs via controller.get_needs()
   - Format output with current values

### Phase 9: Enhanced Overview Tab
1. Create new OverviewPanel.gd extending GamepiecePanel:
   - Override is_compatible_with for NpcController
   - Set tab_priority = 0 for first position
2. Add placeholder portrait image:
   - Use TextureRect with default texture
   - Size: 64x64 pixels
3. Combine NPC info with current activity:
   - Show name, state emoji, current activity
   - Get state from controller.state_machine.get_state_info()
4. Add "View Conversation" button:
   - Show only when state is INTERACTING with conversation
   - Connect to signal that opens conversation window

### Phase 10: Conversation Window Scene
1. Create ConversationWindow.tscn:
   - Root: Panel with drag handle
   - Children: VBoxContainer with title, participants, messages
   - Add close button (X) in top-right
2. Add participant list and message display:
   - Label showing comma-separated participant names
   - RichTextLabel for message history
   - Format: "[Name] message text"
3. Implement floating window behavior:
   - Draggable via title bar
   - Resizable with minimum size
   - Always on top (z_index)
4. Connect to conversation events:
   - Store conversation_id
   - Listen for ConversationObservation events
   - Update display when new messages arrive

### Phase 11: Conversation Event Integration
1. Listen for ConversationObservation events:
   - Connect to EventBus.event_dispatched
   - Filter for NPC_INTERACTION_OBSERVATION type
   - Check observation.conversation_id matches window
2. Update conversation window with new messages:
   - Parse conversation_history from observation
   - Append new messages to RichTextLabel
   - Auto-scroll to bottom
3. Handle participant join/leave:
   - Update participant list from observation
   - Show system messages for joins/leaves
4. Add close button functionality:
   - Free window on close
   - Remove from active windows list

### Phase 12: Population Panel
1. Create PopulationPanel.tscn:
   - Root: Panel anchored to top-left
   - Header: HBoxContainer with title and collapse button
   - Body: ScrollContainer with VBoxContainer for NPC list
2. List all NPCs with state emojis:
   - Get NPCs from GROUP_NAME
   - Create Label for each: "Name 🚶"
   - Update on state changes via signals
3. Add click-to-focus functionality:
   - Make each label a Button
   - Emit GAMEPIECE_CLICKED on press
   - Highlight currently selected NPC
4. Implement collapse/expand:
   - Toggle body visibility
   - Rotate collapse arrow icon
   - Save state in user preferences

### Phase 13: Notification System
1. Create toast notification scene:
   - Root: Panel with MarginContainer
   - Child: Label for notification text
   - Position: Top-right corner
2. Show only for selected entity events:
   - Track currently selected gamepiece
   - Filter events by gamepiece reference
   - Important events: conversation start, need critical
3. Add conversation start notifications:
   - "Alice started a conversation"
   - Include participant names
   - Add click to open conversation window
4. Implement fade in/out animations:
   - Use Tween for opacity
   - Auto-dismiss after 3 seconds
   - Stack multiple notifications vertically

### Phase 14: UI Polish
1. Improve panel styling:
   - Consistent StyleBoxFlat for all panels
   - Unified color scheme from debug console
   - Proper margins and padding
2. Add subtle animations:
   - Smooth panel transitions
   - Button hover effects
   - State emoji changes with brief scale effect
3. Ensure consistent spacing:
   - 8px margins throughout
   - Consistent font sizes
   - Aligned elements in all panels
4. Test all UI elements together:
   - Multiple conversation windows
   - All panels visible simultaneously
   - Performance with 10+ NPCs

## Technical Implementation Details

### State Machine Integration
- States are managed by `ControllerStateMachine` which emits `state_changed` signals
- Each state extends `BaseControllerState` with virtual methods for customization
- The `get_state_info()` method returns state name, enum, and context data
- States handle their own transitions through the `change_state()` method

### Event System Usage
- All UI updates should connect to `EventBus.event_dispatched`
- Key event types for UI:
  - `GAMEPIECE_CLICKED` - Selection changes
  - `INTERACTION_STARTED` - Interaction begins
  - `INTERACTION_FINISHED` - Interaction ends
  - `NPC_INTERACTION_OBSERVATION` - Conversation updates
- Events contain typed data accessible through casting

### Controller Access Patterns
- NPCs are in group `NpcController.GROUP_NAME` for easy access
- Controllers expose public getters: `get_display_name()`, `get_cell_position()`, `get_entity_type()`
- State information via `controller.state_machine.get_state_info()`
- Needs accessible through `controller.get_needs()`

### Interaction System Details
- Interactions extend `Interaction` base class
- Multi-party interactions use `StreamingInteraction` for observations
- Conversation system sends observations with message history
- Interaction factories determine single vs multi-party support

## Technical Considerations

### Architecture Changes
1. **New Scene Structure**:
   - `NpcNameplate.tscn` - Overhead display component
   - `ConversationIndicator.tscn` - Visual conversation links
   - `ConversationWindow.tscn` - Floating chat panel
   - `PopulationPanel.tscn` - NPC overview widget

2. **Event Integration**:
   - Listen for conversation start/end events
   - Update nameplates on state changes
   - Show notifications for selected entity only

3. **Data Flow**:
   - Nameplates read state from controller
   - Conversation windows subscribe to ConversationObservation events
   - Population panel tracks all NPCs via GROUP_NAME

## Design Rationale

### Why These Changes?

1. **Nameplates**: The #1 issue is not knowing what NPCs are doing without clicking
2. **Conversation Visualization**: Multi-party interactions are the newest feature but completely invisible
3. **Enhanced Tabs**: Current panels work well, just need visual polish
4. **Population Overview**: Scales better than clicking each NPC individually

## Conversation System Deep Dive

### Visual Language
- **Conversation State**: NPCs show 💬 emoji when conversing
- **Group Formation**: Dotted line connects all participants
- **Group Indicator**: Centered 💬 bubble above conversation group

### Conversation Window Details
```
┌─ Conversation ──────────────────────┐
│ Alice, Bob, Charlie              [X]│
├─────────────────────────────────────┤
│ Alice: Hey everyone!                │
│ Bob: Hey Alice, how's it going?     │
│ Charlie: Good to see you both!      │
│ Alice: Want to grab lunch?          │
│                                     │
└─────────────────────────────────────┘
```

**Features**:
- **Simple message list**: Name prefix for clarity
- **Auto-scroll**: Follows new messages
- **Persistence**: Windows stay open when deselecting NPCs

### Conversation Lifecycle UI
1. **Starting**: 
   - NPCs change to 💬 state
   - Lines connect participants

2. **Active**:
   - Lines between all participants
   - 💬 emoji on nameplates
   - Clickable group bubble

3. **Ending**:
   - Lines removed
   - NPCs return to previous state
   - Window shows "[Alice left the conversation]"

### Inspiration Analysis

From **The Sims**:
- Overhead thought bubbles → State icons
- Needs panel → Combined need indicator
- Social interactions → Conversation groups

From **Stardew Valley**:
- Clean, minimal UI → Simple nameplates
- Context-sensitive actions → Interaction previews
- Character portraits → Enhanced overview tab

From **MMORPGs**:
- Nameplate system → NPC overhead displays
- Party frames → Population overview
- Chat windows → Conversation panels
- Target frames → Selection panel

## Implementation Notes

### Gotchas and Considerations
1. **Z-ordering**: Nameplates need proper z_index to appear above NPCs but below UI
2. **Performance**: Update nameplate emojis via signals, not every frame
3. **Memory**: Properly free conversation windows and indicators when done
4. **Threading**: Use `call_deferred` for cross-thread UI updates
5. **Focus**: Input focus management is tricky - test thoroughly

### Testing Each Phase
- Phase 1: Verify emoji methods return expected values for all states
- Phase 2-3: Check nameplates update correctly during state transitions
- Phase 4-5: Test conversation visuals with multiple participants
- Phase 6-8: Ensure console commands work reliably
- Phase 9-11: Verify conversation windows update in real-time
- Phase 12-13: Test with many NPCs for performance
- Phase 14: Polish should not break functionality

### Debug Helpers
- Add debug prints in state transitions during development
- Use Godot's remote debugger to inspect live UI scenes
- Test with mock backend for predictable behavior
- Create test scene with pre-configured conversations

## Conclusion

This MVP redesign focuses on making the invisible visible - particularly NPC states and conversations. The 14-phase approach breaks implementation into small, testable chunks that can be completed incrementally. Each phase delivers visible value while building toward the complete system.

Key principles:
- **Simplicity over complexity**: Basic nameplates, no need bars
- **Essential features only**: Focus on state visibility and conversations
- **Incremental delivery**: Each phase is independently valuable
- **Respect existing architecture**: Build on current systems, don't replace