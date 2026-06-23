extends Panel

@export var title : Label;
@export var bodyText : RichTextLabel;

@export var closeButton: Button;

## Runs when the node is first created
func _ready() -> void:
	closeButton.pressed.connect(close_popup);

## Replaces the title of the popup
## text: The replacement text
func set_title(text: String) -> void:
	title.text = text;

## Replaces the body text of the popup
## text: The replacement text
func set_body_text(text: String) -> void:
	bodyText.text = text;

## Closes popup/clears from stack
func close_popup() -> void:
	queue_free();
	# Additional functionality can be added below
