# Documentation Style Guide

## Core Principles

1. Every word must be useful
   - Remove fluff and redundant explanations
   - Focus on what developers need to know
   - Be specific and concrete

2. Use diagrams for structure
   ```
   System
   ├── Component A (file.gd) - purpose
   ├── Component B (file.tscn) - purpose
   └── Component C (file.gd) - purpose
   ```

3. Focus on function level
   - Describe what components do
   - Avoid copying implementation code
   - Show key configurations and parameters

4. Include critical details
   - Document exact values (e.g., collision layers)
   - Specify timing and thresholds
   - Note requirements and dependencies
   - Reference source files (e.g., Component (component.gd))

## Document Structure

1. Overview
   - Brief system purpose
   - Core components
   - Key relationships

2. Components
   - Clear purpose
   - Important properties
   - Critical functions
   - Integration points

3. Setup Requirements
   - Required nodes
   - Configuration values
   - Common patterns

## Common Mistakes

1. Code Dumps
   - ❌ Copying implementation code
   - ✅ Describing function purpose and parameters

2. Abstraction Level
   - ❌ Too high: "Manages state changes"
   - ✅ Specific: "Tracks energy (0-100) with 5s decay"

3. Missing Context
   - ❌ Listing properties without purpose
   - ✅ Explaining why and how properties are used

4. Redundant Information
   - ❌ Repeating obvious details
   - ✅ Focusing on non-obvious requirements

## Examples

### Good Component Description
```
ConsumableComponent
- Configures need_deltas and consumption_time
- Creates NeedModifyingComponent with rates = deltas/time
- Tracks percent_left, destroys at 0%
```

### Good Setup Description
```
Required Nodes:
- AnimationPlayer with idle animation
- Sprite with proper texture/frames
- ClickArea for interaction detection
- CollisionArea for movement blocking
```

### Good Integration Description
```
Physics Layers:
- Gamepiece (0x1): Entity collision
- Terrain (0x2): Static obstacles
- Click (0x4): Interaction detection
```

## Additional Guidelines

1. Visual Hierarchy
   - Use headings to organize content
   - Keep sections focused and atomic
   - Order from most to least important

2. Technical Accuracy
   - Verify values and parameters
   - Test setup instructions
   - Keep up with code changes

3. Cross-References
   - Link related systems
   - Note dependencies
   - Show integration examples

4. Maintenance
   - Remove outdated information
   - Update for new features
   - Fix unclear sections
