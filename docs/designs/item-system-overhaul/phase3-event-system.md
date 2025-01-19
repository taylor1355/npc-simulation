# Phase 3: Event System

## Objective
Improve the event system to provide type safety, validation, and clear error reporting for item-related events.

## Components

### 1. Event Definitions

#### Implementation
```gdscript
# event.gd
class_name Event

# Item Events
const ITEM_CONSUMED = "item_consumed"
const ITEM_INTERACTION_STARTED = "item_interaction_started"
const ITEM_INTERACTION_COMPLETED = "item_interaction_completed"
const NEED_MODIFIED = "need_modified"

# Event Creation Methods
static func create_item_consumed(item: Node, consumer: Node) -> Dictionary:
    return {
        "type": ITEM_CONSUMED,
        "item": item,
        "consumer": consumer
    }

static func create_need_modified(target: Node, need_type: String, delta: float) -> Dictionary:
    return {
        "type": NEED_MODIFIED,
        "target": target,
        "need_type": need_type,
        "delta": delta
    }
```

#### Testing Steps
1. Event Creation
   ```gdscript
   # Create test event
   var event = Event.create_item_consumed(test_item, test_consumer)
   
   # Set breakpoint after creation
   # Verify dictionary structure:
   # - Has all required keys
   # - Values are correct types
   ```

2. Event Usage
   ```gdscript
   # Test in component
   func _on_interaction_completed(interactor: Node) -> void:
       # Set breakpoint here
       var event = Event.create_item_consumed(
           item_controller.get_parent(),
           interactor
       )
       EventBus.emit_event(event)
   ```

### 2. Event Validation

#### Implementation
```gdscript
# event_bus.gd
class_name EventBus

static func emit_event(event: Dictionary) -> void:
    # Validate event structure
    if not _validate_event(event):
        return
        
    # Emit validated event
    emit_signal(event.type, event)

static func _validate_event(event: Dictionary) -> bool:
    if not event.has("type"):
        push_error("Event missing type")
        return false
        
    # Type-specific validation
    match event.type:
        Event.ITEM_CONSUMED:
            return _validate_item_consumed(event)
        Event.NEED_MODIFIED:
            return _validate_need_modified(event)
        _:
            push_error("Unknown event type: %s" % event.type)
            return false

static func _validate_item_consumed(event: Dictionary) -> bool:
    # Required fields
    var required = ["item", "consumer"]
    for field in required:
        if not event.has(field):
            push_error("Item consumed event missing: %s" % field)
            return false
        if not event[field] is Node:
            push_error("Item consumed event %s must be Node" % field)
            return false
    return true

static func _validate_need_modified(event: Dictionary) -> bool:
    # Required fields with types
    var required = {
        "target": Node,
        "need_type": String,
        "delta": float
    }
    for field in required:
        if not event.has(field):
            push_error("Need modified event missing: %s" % field)
            return false
        if not event[field] is required[field]:
            push_error("Need modified event %s must be %s" % [field, required[field]])
            return false
    return true
```

#### Testing Steps
1. Basic Validation
   ```gdscript
   # Test missing type
   var invalid_event = {}
   EventBus.emit_event(invalid_event)
   # Verify error message
   
   # Test unknown type
   var bad_type_event = {"type": "invalid_type"}
   EventBus.emit_event(bad_type_event)
   # Verify error message
   ```

2. Type-Specific Validation
   ```gdscript
   # Test item consumed validation
   var incomplete_event = {
       "type": Event.ITEM_CONSUMED,
       "item": test_item
       # Missing consumer
   }
   EventBus.emit_event(incomplete_event)
   # Verify error message
   
   # Test need modified validation
   var wrong_type_event = {
       "type": Event.NEED_MODIFIED,
       "target": test_target,
       "need_type": "hunger",
       "delta": "not a float"  # Wrong type
   }
   EventBus.emit_event(wrong_type_event)
   # Verify error message
   ```

### 3. Component Integration

#### Implementation
```gdscript
# consumable_component.gd
class_name ConsumableComponent
extends ItemComponent

func _on_interaction_completed(interactor: Node) -> void:
    if interactor.has_method("modify_needs"):
        # Create and emit need modification event
        var need_event = Event.create_need_modified(
            interactor,
            "hunger",
            need_deltas.get("hunger", 0.0)
        )
        EventBus.emit_event(need_event)
        
        # Create and emit consumption event
        var consume_event = Event.create_item_consumed(
            item_controller.get_parent(),
            interactor
        )
        EventBus.emit_event(consume_event)
```

#### Testing Steps
1. Event Flow
   ```gdscript
   # Create test scene
   var item = create_test_item()
   var interactor = create_test_interactor()
   
   # Set breakpoints at:
   # 1. Event creation
   # 2. Validation
   # 3. Event emission
   # 4. Handler execution
   ```

2. Error Recovery
   ```gdscript
   # Test with invalid need_deltas
   need_deltas = {"hunger": "invalid"}
   # Verify error handling
   # Confirm component stays in valid state
   ```

## Integration Testing

### Test Scene Setup
1. Create test scene with:
   - Multiple items
   - Event listeners
   - Test interactor

### Event Sequences
1. Normal Flow
   ```gdscript
   # Test complete interaction sequence
   # Verify events emitted in correct order
   # Check all handlers called
   ```

2. Error Cases
   ```gdscript
   # Test invalid events
   # Verify error handling
   # Check system recovery
   ```

### Performance Testing
1. Event Emission
   - Measure validation time
   - Check memory usage
   - Monitor event queue

## Success Criteria

### Technical
- [ ] Events properly validated
- [ ] Type safety enforced
- [ ] Clear error messages
- [ ] Efficient validation

### Functional
- [ ] Events flow correctly
- [ ] Components respond properly
- [ ] System recovers from errors
- [ ] State remains consistent

## Next Steps

1. Documentation
   - Document event types
   - Add validation rules
   - Update error messages

2. Cleanup
   - Remove old event code
   - Standardize validation
   - Optimize performance

3. Phase 4 Preparation
   - Plan item migration
   - Identify conversion needs
   - Draft update strategy
