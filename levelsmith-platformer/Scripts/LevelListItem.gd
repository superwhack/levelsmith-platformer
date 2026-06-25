extends Node

# Exported references to the level thumbnail, title, and size.
@export var levelThumbnail : TextureRect;
@export var thumbnailContainer : PanelContainer;
@export var levelTitle : Label;
@export var levelAuthor : Label;
@export var levelSize : Label;
@export var levelButton : Button;


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

	
	# Level size is slightly smaller and opacitic.
	levelSize.add_theme_font_size_override("font_size", 20);
	levelSize.modulate.a = 183.0/255.0;
	
	apply_colors();
	# Connect necessary signals for swapping text colors
	#levelButton.button_down.connect(_on_level_button_change);
	#levelButton.button_up.connect(_on_level_button_change);
	levelButton.mouse_entered.connect(_on_mouse_enter)
	levelButton.mouse_exited.connect(_on_mouse_exit)


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
## Sets all font colors to the correct one based on the button color.
func apply_colors() -> void:
	if buttonColor == ButtonColor.WHITE:
		levelButton.theme_type_variation = "LevelItemWhite";
		levelTitle.add_theme_color_override("font_color", blue);
		levelAuthor.add_theme_color_override("font_color", blue);
		levelSize.add_theme_color_override("font_color", blue);
	else:
		levelButton.theme_type_variation = "LevelItemBlue";
		levelTitle.add_theme_color_override("font_color", white);
		levelAuthor.add_theme_color_override("font_color", white);
		levelSize.add_theme_color_override("font_color", white);
		thumbnailContainer.add

## When the button is down/up, set the color of the text to the opposite
func _on_level_button_change() -> void:
	apply_colors();

## Set the color of the text inside the button to be the opposite color.
func _on_mouse_enter() -> void:
	if (buttonColor == ButtonColor.WHITE):
		levelTitle.add_theme_color_override("font_color", white);
		levelAuthor.add_theme_color_override("font_color", white);
		levelSize.add_theme_color_override("font_color", white);
	else:
		levelTitle.add_theme_color_override("font_color", blue);
		levelAuthor.add_theme_color_override("font_color", blue);
		levelSize.add_theme_color_override("font_color", blue);

## Set the colors of the text inside the button to their normal colors.
func _on_mouse_exit() -> void:
	apply_colors();
