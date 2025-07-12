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

func _on_meta_hover_ended(meta: Variant) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

## Helper to add a UILink to the text
func add_link(link: UILink) -> void:
	append_text(link.to_bbcode())