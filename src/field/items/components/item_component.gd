class_name ItemComponent extends EntityComponent

# Item-specific helper to get the ItemController
func get_item_controller() -> ItemController:
	return controller as ItemController
