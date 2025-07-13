# Event Coalescing for High-Frequency UI Events

## Problem

Mouse hover events fire continuously as the cursor moves, potentially causing performance issues:
- Every pixel of mouse movement generates a new event
- UI system processes each event individually
- Behavior lookups and state changes happen for every event
- Can cause UI state thrashing with rapid mouse movements

## Proposed Solution

Implement event coalescing/batching for rapid mouse events to reduce processing overhead.

### Design

```gdscript
# Add to UIRegistry
var _pending_hover_events: Dictionary = {}  # gamepiece_id -> latest event
var _coalesce_timer: float = 0.0
const COALESCE_WINDOW: float = 1.0/60.0  # One frame at 60fps

func _on_event(event: Event) -> void:
    match event.event_type:
        Event.Type.GAMEPIECE_HOVER_STARTED, Event.Type.GAMEPIECE_HOVER_ENDED:
            _queue_hover_event(event)
        Event.Type.GAMEPIECE_CLICKED:
            _handle_gamepiece_event(event, BehaviorRegistry.EventType.CLICK)  # Immediate
        # ... other events

func _queue_hover_event(event: Event) -> void:
    var gamepiece_id = _get_gamepiece_id_from_event(event)
    _pending_hover_events[gamepiece_id] = event
    
    # Start coalescing timer if not running
    if _coalesce_timer <= 0:
        _coalesce_timer = COALESCE_WINDOW

func _process(delta: float) -> void:
    if _coalesce_timer > 0:
        _coalesce_timer -= delta
        if _coalesce_timer <= 0:
            _process_pending_hover_events()

func _process_pending_hover_events() -> void:
    for event in _pending_hover_events.values():
        var event_type = BehaviorRegistry.EventType.HOVER_START if event.is_hover_start else BehaviorRegistry.EventType.HOVER_END
        _handle_gamepiece_event(event, event_type)
    _pending_hover_events.clear()
```

### Benefits

1. **Performance**: Reduces behavior lookups from hundreds per second to 60 per second max
2. **Stability**: Prevents UI state thrashing from rapid mouse movements
3. **Scalability**: Better performance with many interactive elements
4. **Configurable**: Can adjust coalesce window based on performance needs

### Considerations

- Click events remain immediate (no coalescing) for responsiveness
- Focus events also remain immediate
- Only hover events are coalesced
- May introduce slight visual delay (16ms max at 60fps)

### Alternative Approaches

1. **Frame-based batching**: Process all events at end of frame
2. **Spatial coalescing**: Only process if mouse moved more than N pixels
3. **Time-based throttling**: Limit events to N per second per entity

## Implementation Priority

Should wait until performance profiling indicates this is actually a bottleneck. Premature optimization may add complexity without measurable benefit.

## Testing Plan

1. Create stress test scene with 100+ hoverable elements
2. Profile with and without coalescing
3. Verify hover behaviors still work correctly
4. Test edge cases (rapid enter/exit, multiple elements)