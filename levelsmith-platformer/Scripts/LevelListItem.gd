extends Node

# Exported references to the level thumbnail, title, author, size, and button.
@export var levelThumbnail : TextureRect;
@export var thumbnailContainer : PanelContainer;
@export var levelTitle : Label;
@export var levelAuthor : Label;
@export var levelEdited : Label;
@export var levelSize : Label;
@export var levelValid : Label;
@export var levelButton : Button;

# The level path. Used when emitting signal.
var levelPath : String;

# Signal for double clicking main button
signal level_double_clicked(path: String)


# An enum for the base color of the button.
enum ButtonColor {
	WHITE = 0,
	BLUE = 1
}

var buttonColor: ButtonColor = ButtonColor.WHITE;

var white : Color = Color("ffffff");
var blue : Color = Color("081e45");

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Author name is slight smaller
	levelAuthor.add_theme_font_size_override("font_size", 22);

	
	# Slightly smaller and opacitic (?).
	levelSize.add_theme_font_size_override("font_size", 20);
	levelSize.modulate.a = 183.0/255.0;
	levelValid.add_theme_font_size_override("font_size", 20);
	levelValid.modulate.a = 183.0/255.0;
		
	# Signals
	levelButton.mouse_entered.connect(_on_mouse_enter);
	levelButton.mouse_exited.connect(_on_mouse_exit);
	levelButton.gui_input.connect(_on_level_button_input);


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass;
	
## Sets all font colors to the correct one based on the button color.
func apply_colors() -> void:
	if buttonColor == ButtonColor.WHITE:
		levelButton.theme_type_variation = "LevelItemWhite";
		levelTitle.add_theme_color_override("font_color", blue);
		levelAuthor.add_theme_color_override("font_color", blue);
		levelEdited.add_theme_color_override("font_color", blue);
		levelSize.add_theme_color_override("font_color", blue);
		levelValid.add_theme_color_override("font_color", blue);
	else:
		levelButton.theme_type_variation = "LevelItemBlue";
		levelTitle.add_theme_color_override("font_color", white);
		levelAuthor.add_theme_color_override("font_color", white);
		levelEdited.add_theme_color_override("font_color", blue);
		levelSize.add_theme_color_override("font_color", white);
		levelSize.add_theme_color_override("font_color", blue);

## When the main button is double clicked, emit signal
## event: The input event triggering this code.
func _on_level_button_input(event):
	# If the event is a double click, left mouse button, emit signal
	if (event is InputEventMouseButton
	&& event.button_index == MOUSE_BUTTON_LEFT
	&& event.double_click
	&& event.pressed):
		level_double_clicked.emit(levelPath);


## Set the color of the text inside the button to be the opposite color.
func _on_mouse_enter() -> void:
	if (buttonColor == ButtonColor.WHITE):
		levelTitle.add_theme_color_override("font_color", white);
		levelAuthor.add_theme_color_override("font_color", white);
		levelEdited.add_theme_color_override("font_color", white);
		levelSize.add_theme_color_override("font_color", white);
		levelValid.add_theme_color_override("font_color", white);

	else:
		levelTitle.add_theme_color_override("font_color", blue);
		levelAuthor.add_theme_color_override("font_color", blue);
		levelEdited.add_theme_color_override("font_color", blue);
		levelSize.add_theme_color_override("font_color", blue);
		levelValid.add_theme_color_override("font_color", blue);

## Set the colors of the text inside the button to their normal colors.
func _on_mouse_exit() -> void:
	apply_colors();
