extends Control

@export var title : Label;
@export var bodyText : RichTextLabel;
@export var separator : HSeparator;
@export var separator2 : HSeparator;

@export var closeButton: Button;
@export var resetButton: Button;

@export var panelContainer2: PanelContainer;

# Callback function, used for assigning a function to the reset button.
var resetCallback : Callable = Callable();

## Runs when the node is first created
func _ready() -> void:
	if (closeButton):
		closeButton.pressed.connect(close_popup);
		
	if (resetButton):
		resetButton.pressed.connect(_on_reset_pressed);

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
	
## When the reset button is pressed, execute the callback.
func _on_reset_pressed() -> void:
	if (resetCallback.is_valid()):
		resetCallback.call();

	close_popup();

## Set the callback to the given callable function.
## callback: Given callback function from another script.
func set_reset_callback(callback: Callable) -> void:
	resetCallback = callback;
	
## Sets the color of the Panel Container with body text
## color: New background color for panel 
## borderColor: New Border color for panel 
func set_panel_color(color: Color, borderColor: Color) -> void:
	var style := panelContainer2.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = color
	style.border_color = borderColor
	panelContainer2.add_theme_stylebox_override("panel", style)
	
