class_name ConversationMessage extends PanelContainer

## A single message in a conversation panel.
## Displays speaker name, message content, and timestamp.

@onready var speaker_label: Label = $VBox/Header/SpeakerLabel
@onready var timestamp_label: Label = $VBox/Header/TimestampLabel
@onready var content_label: RichTextLabel = $VBox/ContentLabel

func _ready() -> void:
	# Style the message bubble
	add_theme_stylebox_override("panel", _create_message_style())

func set_message(speaker: String, content: String, timestamp: float) -> void:
	speaker_label.text = speaker
	content_label.text = content
	
	# Format timestamp as MM:SS
	var minutes = int(timestamp) / 60
	var seconds = int(timestamp) % 60
	timestamp_label.text = "%02d:%02d" % [minutes, seconds]

func _create_message_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style