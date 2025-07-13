class_name PhysicsLayers

## Centralized physics layer constants for collision detection
##
## This class defines all physics layers used in the game for consistent
## collision detection and interaction across different systems.

## Layer indices (for set_collision_layer_bit)
const GAMEPIECE_LAYER = 0  # Entities that block movement and can be interacted with
const TERRAIN_LAYER = 1    # Static obstacles for pathfinding
const CLICK_LAYER = 2      # Mouse interaction detection areas

## Layer masks (for set_collision_mask and direct collision checks)
const GAMEPIECE_MASK = 0x1  # 1 << GAMEPIECE_LAYER = 1
const TERRAIN_MASK = 0x2    # 1 << TERRAIN_LAYER = 2
const CLICK_MASK = 0x4      # 1 << CLICK_LAYER = 4