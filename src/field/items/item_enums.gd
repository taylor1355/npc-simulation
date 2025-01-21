class_name ItemEnums

enum ItemType {
    APPLE,
    CHAIR,
}

enum ComponentType {
    CONSUMABLE,
    SITTABLE,
    NEED_MODIFYING,
}

# Only paths that need to be referenced outside the scene
const SCENE_PATHS = {
    BASE_ITEM = "res://src/field/items/base_item.tscn",
}

const CONFIG_PATHS = {
    APPLE = "res://src/field/items/configs/apple_config.tres",
    CHAIR = "res://src/field/items/configs/chair_config.tres",
}
