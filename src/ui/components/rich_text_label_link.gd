class_name RichTextLabelLink extends RichTextLabel

## RichTextLabel that supports clickable links via UILink.
## Links are executed directly when clicked.

func _ready() -> void:
	# Enable BBCode
	bbcode_enabled = true
	
	# Connect link handling
	meta_clicked.connect(_on_meta_clicked)
	meta_hover_started.connect(_on_meta_hover_started) 
	meta_hover_ended.connect(_on_meta_hover_ended)

func _on_meta_clicked(meta: Variant) -> void:
	var link_ref = str(meta)
	
	# Parse and execute link
	var link = UILink.parse(link_ref)
	if not link:
		push_warning("Invalid link reference: " + link_ref)
		return
	
	link.execute()

func _on_meta_hover_started(meta: Variant) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	
	# Trigger highlighting based on link type
	var link_ref = str(meta)
	var link = UILink.parse(link_ref)
	if not link:
		return
	
	match link.target_type:
		UILink.TargetType.ENTITY:
			HighlightManager.highlight(link.target_id, "ui_link", Color.YELLOW, HighlightManager.Priority.SELECTION)
		UILink.TargetType.INTERACTION:
			HighlightManager.highlight_interaction(link.target_id, "ui_link", Color.YELLOW, HighlightManager.Priority.SELECTION)

func _on_meta_hover_ended(meta: Variant) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	# Remove highlighting
	var link_ref = str(meta)
	var link = UILink.parse(link_ref)
	if not link:
		return
		
	match link.target_type:
		UILink.TargetType.ENTITY:
			HighlightManager.unhighlight(link.target_id, "ui_link")
		UILink.TargetType.INTERACTION:
			HighlightManager.unhighlight_interaction(link.target_id, "ui_link")

## Helper to add a UILink to the text
func add_link(link: UILink) -> void:
	append_text(link.to_bbcode())