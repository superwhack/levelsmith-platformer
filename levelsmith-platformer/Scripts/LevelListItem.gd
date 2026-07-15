extends Node

# Exported references to the level thumbnail, title, author, size, and button.
@export var levelTitle : Label;
@export var levelDate : Label;
@export var levelTime : Label;
@export var levelButton : Button;
@export var levelErrorIcon : TextureRect;
@export var levelFavoriteIcon : TextureRect;

# We need to store metadata in button to retrieve when hovering/selecting
var author : String = "";
var dateCreated : String = "";
var dateModified : String = "";
var dimensions : String = "";
var objectCount : String = "";
var version : String = "";
var favorited : bool = false;
var validated : bool = false;
var thumbnail : Texture2D;

# The level path. Used when emitting signal.
var levelPath : String;

# Signal for double clicking main button, for hovering level button
signal level_double_clicked(path: String);
signal level_hovered(item: Control);
signal level_pressed(item: Control);
signal level_deselected(item: Control);


# An enum for the base color of the button.
enum ButtonColor {
	WHITE = 0,
	BLUE = 1
}

var buttonColor: ButtonColor = ButtonColor.WHITE;

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Signals
	#levelButton.mouse_entered.connect(_on_mouse_enter);
	#levelButton.mouse_exited.connect(_on_mouse_exit);
	levelButton.mouse_entered.connect(_on_mouse_entered);
	levelButton.pressed.connect(_on_button_pressed);
	levelButton.gui_input.connect(_on_level_button_input);
	levelButton.gui_input.connect(_on_gui_input);
	
## Sets all font colors to the correct one based on the button color.
#func apply_colors() -> void:
	#if buttonColor == ButtonColor.WHITE:
		#levelButton.theme_type_variation = "LevelItemWhite";
		#levelTitle.add_theme_color_override("font_color", blue);
		#levelAuthor.add_theme_color_override("font_color", blue);
		#levelEdited.add_theme_color_override("font_color", blue);
		#levelSize.add_theme_color_override("font_color", blue);
		#levelValid.add_theme_color_override("font_color", blue);
	#else:
		#levelButton.theme_type_variation = "LevelItemBlue";
		#levelTitle.add_theme_color_override("font_color", white);
		#levelAuthor.add_theme_color_override("font_color", white);
		#levelEdited.add_theme_color_override("font_color", blue);
		#levelSize.add_theme_color_override("font_color", white);
		#levelSize.add_theme_color_override("font_color", blue);

## When the main button is double clicked, emit signal
## event: The input event triggering this code.
func _on_level_button_input(event: InputEvent):
	# If the event is a double click, left mouse button, emit signal
	if (event is InputEventMouseButton
	&& event.button_index == MOUSE_BUTTON_LEFT
	&& event.double_click
	&& event.pressed):
		level_double_clicked.emit(levelPath);


## On a specific GUI input on the button.
## event: The event the GUI is capturing.
func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton 
	&& event.button_index == MOUSE_BUTTON_RIGHT 
	&& event.pressed):
		print("INPUT")
		levelButton.button_pressed = false;
		level_deselected.emit(self);

## When the button is being hovered, emit a signal. Used for main menu metadata.
func _on_mouse_entered() -> void:
	level_hovered.emit(self);

## When the button is toggled, emit a signal. Used for main menu level selection.
## buttonPressed: 
func _on_button_pressed() -> void:
	level_pressed.emit(self);

## Set the color of the text inside the button to be the opposite color.
#func _on_mouse_enter() -> void:
	#if (buttonColor == ButtonColor.WHITE):
		#levelTitle.add_theme_color_override("font_color", white);
		#levelAuthor.add_theme_color_override("font_color", white);
		#levelEdited.add_theme_color_override("font_color", white);
		#levelSize.add_theme_color_override("font_color", white);
		#levelValid.add_theme_color_override("font_color", white);
#
	#else:
		#levelTitle.add_theme_color_override("font_color", blue);
		#levelAuthor.add_theme_color_override("font_color", blue);
		#levelEdited.add_theme_color_override("font_color", blue);
		#levelSize.add_theme_color_override("font_color", blue);
		#levelValid.add_theme_color_override("font_color", blue);

## Set the colors of the text inside the button to their normal colors.
#func _on_mouse_exit() -> void:
	#apply_colors();
