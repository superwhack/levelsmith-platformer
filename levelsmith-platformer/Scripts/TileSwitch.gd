extends HBoxContainer

@onready var editorManager : Node2D = get_parent().get_parent();

@export var movingButton : TextureButton;
@export var slopeButton : TextureButton;

## Set objects to be transparent when the cursor is selected
## selected: True if the cursor is selected
func cursorSelected(selected: bool) -> void:
	if !selected:
		movingButton.modulate = Color(1, 1, 1, 0.5);
		slopeButton.modulate = Color(1, 1, 1, 0.5);
	else:
		movingButton.modulate = Color(1, 1, 1, 1);
		slopeButton.modulate = Color(1, 1, 1, 1);

# Tile Buttons
func _on_solid_tile_button_pressed() -> void:
	editorManager.change_tile(Global.TileType.SOLID);

func _on_death_tile_button_pressed() -> void:
	editorManager.change_tile(Global.TileType.DEATH);

func _on_oneway_tile_button_pressed() -> void:
	editorManager.change_tile(Global.TileType.ONEWAY);

func _on_ice_tile_button_pressed() -> void:
	editorManager.change_tile(Global.TileType.ICE);

func _on_sticky_tile_button_pressed() -> void:
	editorManager.change_tile(Global.TileType.STICKY);

func _on_bounce_tile_button_pressed() -> void:
	editorManager.change_tile(Global.TileType.BOUNCE);

# Object Buttons
func _on_slope_object_button_pressed() -> void:
	editorManager.change_tile(Global.ObjectType.SLOPE);

func _on_moving_object_button_pressed() -> void:
	editorManager.change_tile(Global.ObjectType.MOVING);
