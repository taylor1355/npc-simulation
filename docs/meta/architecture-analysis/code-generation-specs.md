# Code Generation Specifications

## Overview

This document specifies code generation tools that will dramatically reduce development time by automating the creation of boilerplate code. The patterns in this codebase are extremely consistent, making it ideal for code generation.

## 1. Component Generator

### Purpose
Generate complete component implementations from simple schema definitions, eliminating 80% of boilerplate code.

### Input Schema (YAML)
```yaml
component:
  name: Cookable
  type: item  # or 'npc'
  description: "Allows items to be cooked"
  
properties:
  - name: cooking_time
    type: float
    default: 5.0
    description: "Time required to cook"
    
  - name: cooked_item_config
    type: resource
    resource_type: ItemConfig
    description: "Item to spawn when cooked"
    
  - name: burn_time
    type: float
    default: 10.0
    description: "Time before item burns"
    
  - name: cooking_effects
    type: dictionary
    subtype: {need: string, rate: float}
    description: "Need modifications while cooking"

interactions:
  - name: cook
    description: "Cook this item"
    emoji: "🍳"
    type: streaming  # or 'instant'
    multi_party: false
    
events:
  - cooking_started
  - cooking_completed
  - item_burned
```

### Generated Files

#### 1. Component Class (`cookable_component.gd`)
```gdscript
@tool
extends ItemComponent

signal cooking_started()
signal cooking_completed()
signal item_burned()

var cooking_time: float = 5.0
var cooked_item_config: ItemConfig = null
var burn_time: float = 10.0
var cooking_effects: Dictionary = {}

func _init():
    PROPERTY_SPECS["cooking_time"] = PropertySpec.new(
        "cooking_time",
        TypeConverters.PropertyType.FLOAT,
        5.0,
        "Time required to cook"
    )
    
    PROPERTY_SPECS["cooked_item_config"] = PropertySpec.new(
        "cooked_item_config",
        TypeConverters.PropertyType.RESOURCE,
        null,
        "Item to spawn when cooked"
    )
    
    PROPERTY_SPECS["burn_time"] = PropertySpec.new(
        "burn_time",
        TypeConverters.PropertyType.FLOAT,
        10.0,
        "Time before item burns"
    )
    
    PROPERTY_SPECS["cooking_effects"] = PropertySpec.new(
        "cooking_effects",
        TypeConverters.PropertyType.DICTIONARY,
        {},
        "Need modifications while cooking"
    )

func _create_interaction_factories() -> Array[InteractionFactory]:
    return [CookInteractionFactory.new(self)]

func _on_cook_start(interaction: Interaction) -> void:
    cooking_started.emit()

func _on_cook_end(interaction: Interaction) -> void:
    cooking_completed.emit()

func _on_cook_update(interaction: Interaction, delta: float) -> void:
    # Generated update logic
    pass

# Inner factory class
class CookInteractionFactory extends InteractionFactory:
    var _component: CookableComponent
    
    func _init(component: CookableComponent):
        _component = component
    
    func get_interaction_name() -> String:
        return "cook"
    
    func get_interaction_description() -> String:
        return "Cook this item"
    
    func create_interaction(context: InteractionContext) -> Interaction:
        var interaction = CookInteraction.new()
        interaction.name = get_interaction_name()
        interaction.description = get_interaction_description()
        interaction.component = _component
        interaction.context = context
        return interaction
```

#### 2. Interaction Class (`cook_interaction.gd`)
```gdscript
extends StreamingInteraction

var component: CookableComponent
var _elapsed_time: float = 0.0

func get_interaction_emoji() -> String:
    return "🍳"

func _on_start() -> void:
    if component and component.has_method("_on_cook_start"):
        component._on_cook_start(self)
    super._on_start()

func _on_end() -> void:
    if component and component.has_method("_on_cook_end"):
        component._on_cook_end(self)
    super._on_end()

func _on_update(delta: float) -> void:
    _elapsed_time += delta
    
    if component:
        component._on_cook_update(self, delta)
        
        if _elapsed_time >= component.cooking_time:
            if _elapsed_time >= component.burn_time:
                component.item_burned.emit()
            else:
                component.cooking_completed.emit()
            
            finish()
    
    super._on_update(delta)
```

#### 3. Component Config Resource (`cookable_component_config.gd`)
```gdscript
@tool
extends ItemComponentConfig

func _init():
    component_script = preload("res://src/field/items/components/cookable_component.gd")

func get_component_name() -> String:
    return "Cookable"

func get_component_description() -> String:
    return "Allows items to be cooked"
```

#### 4. Test Scene (`test_cookable_component.tscn`)
- Pre-configured scene with item containing the component
- Test harness for validating interactions
- Debug UI for monitoring component state

### CLI Usage
```bash
# Generate component from schema
godot-codegen component cookable.yaml

# Generate with custom output directory
godot-codegen component cookable.yaml --output src/field/items/components/

# Generate only specific files
godot-codegen component cookable.yaml --only component,interaction

# Update existing component (preserves custom code)
godot-codegen component cookable.yaml --update
```

## 2. Interaction Scaffolder

### Purpose
Add new interactions to existing components without modifying core files.

### Input
```bash
godot-codegen add-interaction consumable "brew" \
    --description "Brew this item into a potion" \
    --emoji "🧪" \
    --streaming \
    --duration-property "brew_time"
```

### Generated Changes
1. Updates component class with new factory
2. Creates interaction class
3. Adds callback methods
4. Updates any existing tests

## 3. UI Panel Generator

### Purpose
Generate complete UI panels for displaying entity information.

### Input Schema
```yaml
panel:
  name: CookingPanel
  type: entity  # or 'interaction', 'system'
  entity_type: CookableComponent
  
display_fields:
  - property: cooking_time
    label: "Cook Time"
    format: "%.1f seconds"
    
  - property: burn_time
    label: "Burn Time"  
    format: "%.1f seconds"
    
  - computed: time_remaining
    label: "Time Remaining"
    update_rate: 0.1
    
events_handled:
  - type: cooking_started
    handler: "_on_cooking_started"
  - type: cooking_completed
    handler: "_on_cooking_completed"
```

### Generated Panel Class
Complete panel implementation with:
- Proper inheritance from EntityPanel
- Event handling with type checking
- Update timers for computed fields
- Null-safety checks
- Label and value display management

## 4. Event Type Generator

### Purpose
Generate strongly-typed event classes with proper serialization.

### Input Schema
```yaml
event_category: CookingEvents
events:
  - name: CookingStarted
    properties:
      - name: item_id
        type: string
      - name: cook_time
        type: float
      - name: recipe
        type: string
        optional: true
        
  - name: CookingCompleted
    properties:
      - name: item_id
        type: string
      - name: result_item_id
        type: string
      - name: quality
        type: float
        default: 1.0
```

### Generated Event Classes
```gdscript
class_name CookingEvents

static func cooking_started(item_id: String, cook_time: float, recipe: String = "") -> CookingStartedEvent:
    var event = CookingStartedEvent.new()
    event.item_id = item_id
    event.cook_time = cook_time
    event.recipe = recipe
    return event

class CookingStartedEvent extends Event:
    var item_id: String
    var cook_time: float
    var recipe: String = ""
    
    func _init():
        super._init(Event.Type.COOKING_STARTED)
    
    func to_dict() -> Dictionary:
        return {
            "item_id": item_id,
            "cook_time": cook_time,
            "recipe": recipe
        }
```

## 5. Mock Backend State Generator

### Purpose
Generate mock backend states for testing NPC behaviors.

### Input Schema
```yaml
state:
  name: HungryState
  base: NPCState
  
entry_conditions:
  - condition: needs.hunger < 30
    priority: high
    
exit_conditions:
  - condition: needs.hunger > 80
  - condition: timeout > 300
  
behaviors:
  - find_food:
      search_radius: 10
      preferred_items: ["Apple", "Bread", "Soup"]
      
  - move_to_food:
      speed_multiplier: 1.2
      
  - consume_food:
      consumption_time: 3.0
```

## Implementation Strategy

### Phase 1: Core Generator Framework
1. Create shared template engine
2. Implement YAML/JSON schema parser
3. Build file generation system with proper paths
4. Add update/merge capabilities for existing files

### Phase 2: Component Generator
1. Implement full component generation
2. Add validation for schema correctness
3. Create interactive mode for guided generation
4. Build library of component templates

### Phase 3: Other Generators
1. Implement remaining generators
2. Create VS Code extension for schema validation
3. Add Godot editor plugin for in-editor generation
4. Build component library browser

## Benefits

1. **Development Speed**: 70-80% reduction in time to add new features
2. **Consistency**: All generated code follows exact patterns
3. **Documentation**: Schema serves as documentation
4. **Onboarding**: New developers productive immediately
5. **Refactoring**: Update templates to refactor entire codebase

## Success Metrics

- Time to create new component: 20 minutes → 2 minutes
- Lines of boilerplate per component: ~200 → 0
- Consistency errors: Common → None
- Documentation completeness: 100% for generated code
- Test coverage: 100% for generated code