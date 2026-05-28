extends HBoxContainer

@onready var editorManager : Node2D = get_parent().get_parent().get_parent();

var objectButtons: Array[Control] = [];

# NOTE: These get_child calls will have to change once all buttons are in
func _ready() -> void:
	objectButtons.resize(3);
	objectButtons[0] = get_child(6);
	objectButtons[1] = get_child(7);
	objectButtons[2] = get_child(8);

## Set objects to be transparent when the cursor is selected
## selected: True if the cursor is selected
func cursorSelected(selected: bool) -> void:
	if !selected:
		for objectButton in objectButtons:
			objectButton.modulate = Color(1, 1, 1, 0.5);
	else:
		for objectButton in objectButtons:
			objectButton.modulate = Color(1, 1, 1, 1);

# Tile Buttons
func _on_solid_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.SOLID);

<<<<<<< HEAD
func _on_death_tile_button_pressed() -> void:
	editorManager.change_tile(Global.TileType.DEATH);

func _on_oneway_tile_button_pressed() -> void:
	editorManager.change_tile(Global.TileType.ONEWAY);
=======
func _on_bounce_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.BOUNCE);
>>>>>>> origin/main

func _on_ice_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.ICE);

func _on_sticky_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.STICKY);

<<<<<<< HEAD
func _on_bounce_tile_button_pressed() -> void:
	editorManager.change_tile(Global.TileType.BOUNCE);

# Object Buttons
func _on_slope_object_button_pressed() -> void:
	editorManager.change_tile(Global.ObjectType.SLOPE);
	
func _on_spawn_object_button_pressed() -> void:
	editorManager.change_tile(Global.ObjectType.SPAWN);

func _on_moving_object_button_pressed() -> void:
	editorManager.change_tile(Global.ObjectType.MOVING);
=======
func _on_slope_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.SLOPE);

func _on_oneway_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.ONEWAY);

func _on_death_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.DEATH);
>>>>>>> origin/main
