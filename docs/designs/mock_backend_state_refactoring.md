# Mock Backend State Management Refactoring

## Problem Statement

The mock backend currently suffers from state synchronization issues that cause NPCs to behave incorrectly:

1. **State Persistence Bug**: When NPCs finish wandering and return to idle in the controller, the mock backend remains in `WanderingState`, causing it to return `continue_action()` instead of initiating new behaviors.

2. **Circular State Dependencies**: The `update_state_from_action()` pattern creates a feedback loop where the agent changes state based on its own decisions, but has no way to detect when those actions complete.

3. **Controller-Backend Coupling**: The mock backend tries to maintain its own state machine that mirrors controller states but lacks sufficient information to stay synchronized.

## Current Architecture Issues

### State Update Flow
```
1. Agent chooses action (e.g., "wander")
2. Agent updates its own state based on action (→ WanderingState)
3. Controller executes action and changes its state
4. Mock backend never learns about controller state changes
5. Mock backend remains in wrong state indefinitely
```

### Root Causes

1. **Self-Referential State Updates**: `agent.update_state_from_action()` changes state based on the agent's own decisions, not observed world state.

2. **Missing Completion Signals**: The mock backend has no way to know when actions like wandering complete.

3. **Dual State Machines**: Both the controller and mock backend maintain separate state machines that can drift out of sync.

## Proposed Solution: Observation-Based State Management

### Core Principle

The mock backend should derive its state from observations rather than trying to predict state changes from actions. The controller already provides its state in the `StatusObservation.controller_state.state_enum` field.

### Implementation

1. **Remove Self-Referential State Updates**

Remove the `agent.update_state_from_action(action)` call from `mock_npc_backend.gd`:

```gdscript
func process_observation(agent_id: String, events: Array[NpcEvent]) -> NpcResponse:
    # ... event processing ...
    
    var action = agent.choose_action(seen_items, needs)
    # REMOVED: agent.update_state_from_action(action)
    
    return NpcResponse.create_success(action.type, action.parameters)
```

2. **Update State from Controller Observations**

Modify the observation processing to sync agent state with controller state:

```gdscript
# In mock_npc_backend.gd, update the OBSERVATION case:
NpcEvent.Type.OBSERVATION:
    if event.payload is CompositeObservation:
        var status_obs = event.payload.find_observation(StatusObservation)
        if status_obs:
            agent.movement_locked = status_obs.movement_locked
            agent.current_observation = status_obs
            
            # Sync agent state with controller state
            var controller_state = status_obs.controller_state.get("state_enum", "")
            _sync_agent_state(agent, controller_state, status_obs)
```

3. **State Synchronization Logic**

Add a helper function to map controller states to agent states:

```gdscript
func _sync_agent_state(agent: Agent, controller_state: String, status_obs: StatusObservation) -> void:
    # Map controller states to agent states
    match controller_state:
        "IDLE":
            if not (agent.current_state is IdleState):
                agent.change_state(IdleState)
        
        "WANDERING":
            if not (agent.current_state is WanderingState):
                agent.change_state(WanderingState)
        
        "MOVING":
            # Moving could be targeted movement or wandering
            if agent.target_position:
                if not (agent.current_state is MovingToTargetState):
                    agent.change_state(MovingToTargetState)
            else:
                # No target = treat as wandering
                if not (agent.current_state is WanderingState):
                    agent.change_state(WanderingState)
        
        "REQUESTING":
            if not (agent.current_state is RequestingInteractionState):
                agent.change_state(RequestingInteractionState)
        
        "INTERACTING":
            if not (agent.current_state is InteractingState):
                agent.change_state(InteractingState)
        
        "WAITING":
            # Waiting maps to idle in the agent
            if not (agent.current_state is IdleState):
                agent.change_state(IdleState)
        
        _:
            # Unknown state - default to idle
            if not (agent.current_state is IdleState):
                push_warning("Unknown controller state: %s" % controller_state)
                agent.change_state(IdleState)
```

4. **Rename and Refactor Action Data Updates**

Replace `update_state_from_action()` with a more focused function:

```gdscript
func update_target_from_action(action: Action) -> void:
    """Update agent's target position when choosing movement actions"""
    match action.type:
        Action.Type.MOVE_TO:
            target_position = Vector2i(
                action.parameters["x"],
                action.parameters["y"]
            )
        Action.Type.WANDER, Action.Type.WAIT:
            # Clear target for non-targeted movements
            target_position = Vector2i()
        _:
            # Other actions don't affect target position
            pass
```

And update the agent to call this when choosing actions:

```gdscript
func choose_action(seen_items: Array, needs: Dictionary) -> Action:
    # ... existing timer updates ...
    
    # Get action from current state
    var action = current_state.update(seen_items, needs)
    
    # Update target position based on action
    update_target_from_action(action)
    
    return action
```

5. **Rename MovingToItemState**

Since the state is now more generic, rename it to `MovingToTargetState` throughout the codebase. This better reflects that it's moving to any specific target position, not just items.

## Benefits

1. **Eliminates Synchronization Issues**: The mock backend's state always matches the controller's observable state.

2. **Simpler Mental Model**: One source of truth (controller state) instead of two parallel state machines.

3. **Preserves Existing Behavior**: All existing state logic remains intact, just the synchronization mechanism changes.

4. **Minimal Code Changes**: Only affects state transition logic, not state behavior.

5. **Clearer Semantics**: Function names now accurately reflect their purpose.

## Special Cases

### Conversation State

Conversations already work well because:
- They're tracked through `current_interaction` in StatusObservation
- InteractingState handles conversation-specific logic
- No changes needed

### Target Position Tracking

The mock backend tracks `target_position` to distinguish between:
- Targeted movement (MOVING state with a target → MovingToTargetState)
- Wandering movement (MOVING state without a target → WanderingState)

This is now handled by the renamed `update_target_from_action()` function.

### Request Handling

Interaction requests are already handled through events (INTERACTION_REQUEST_REJECTED, etc.), so they continue to work as before.

## Implementation Steps

1. Remove the `agent.update_state_from_action(action)` call
2. Rename `update_state_from_action()` to `update_target_from_action()`
3. Rename `MovingToItemState` to `MovingToTargetState`
4. Add the `_sync_agent_state()` helper function
5. Update the observation processing to call `_sync_agent_state()`
6. Move the `update_target_from_action()` call into `choose_action()`
7. Test thoroughly

## Testing Strategy

1. **Wandering Test**: Verify NPCs alternate between wandering and idle correctly
2. **Need-Based Behavior**: Ensure NPCs seek items when needs drop below threshold
3. **Conversation Flow**: Confirm conversations still work properly
4. **State Transitions**: Verify all controller state transitions are reflected in the mock backend
5. **Edge Cases**: Test rapid state changes, interruptions, and error conditions

## Alternative Considerations

We considered making the mock backend completely stateless, but this would require significant refactoring of conversation management and other stateful behaviors. The observation-based approach provides the benefits of state synchronization while preserving the existing architecture's capabilities.

## Future Improvements

1. Consider adding more detailed state information to StatusObservation if needed
2. Add state transition events to make debugging easier
3. Consider unifying some states (e.g., WAITING and IDLE) if they have identical behavior