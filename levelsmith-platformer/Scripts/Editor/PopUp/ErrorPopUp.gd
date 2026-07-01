extends Control

@export var title : Label;
@export var bodyText : RichTextLabel;
@export var separator : HSeparator;

@export var closeButton: Button;
@export var resetButton: Button

# Callback function, used for assigning a function to the reset button.
var resetCallback : Callable = Callable();


## Runs when the node is first created
func _ready() -> void:
	if (closeButton):
		closeButton.pressed.connect(close_popup);
		
	if (resetButton):
		resetButton.pressed.connect(_on_confirm_pressed);

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
	
func _on_confirm_pressed() -> void:
	print("confirmed")
	if (resetCallback.is_valid()):
		resetCallback.call();

	close_popup();

func set_confirm_callback(callback: Callable) -> void:
	resetCallback = callback;
